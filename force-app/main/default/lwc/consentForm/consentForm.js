import {api, wire,track, LightningElement } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getApplication from '@salesforce/apex/consentFormGuestController.getCurrentJobApplication';
import updateJobApplications from '@salesforce/apex/consentFormGuestController.updateSingleJobApplication';
import signaturePanel from 'c/signaturePanel';
import saveSignature from '@salesforce/apex/SignatureUtils.saveSignature';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ConsentForm extends LightningElement {

    @track recordId;
    @track successMessage;
    @track errorMessage;

    @track application = {};
    @track updatedApplication = {};

    @track mediaValue;
    @track informationValue;
    @track clearanceValue;
    @track parentValue; 

    @track firstName;
    @track lastName;

    @track alreadySigned = false;

    // # SIGNATURE DATA
	sigCaptured = false;
	sigURL;
	sigData;


    @track options = [
        { label: 'Yes', value: 'Yes'},
        { label: 'No', value: 'No'}
    ];

    @wire(CurrentPageReference)
    currentPageReference;

    connectedCallback() {      
        this.recordId = this.currentPageReference.state.recordId; 
        this.loadApplication();
    }

    async loadApplication() {
        try {
            const result = await getApplication({ appId: this.recordId });
            this.application = result;
            this.updatedApplication = { ...this.application };

            if(this.application.Guardian_Consent_Required__c == false){
                this.alreadySigned = true;
            }

            this.firstName = this.application.Applicant_s_Legal_First_Name__c ;
            this.lastName =  this.application.Applicant_s_Legal_Last_Name__c ;

            if(this.application.Media_Picture_Release__c){
                this.mediaValue = this.application.Media_Picture_Release__c;
            }else{
                this.mediaValue = 'Yes';
            }

            if(this.application.Release_of_Information__c){
                this.informationValue = this.application.Release_of_Information__c;
            }else{
                this.informationValue = 'Yes';
            }

            if(this.application.Consent_to_Request_Clearance__c){
                this.clearanceValue = this.application.Consent_to_Request_Clearance__c;
            }else{
                this.clearanceValue = 'Yes';
            }

            if(this.application.Parent_s_Consent__c){
                this.parentValue = this.application.Parent_s_Consent__c;
            }else{
                this.parentValue = 'Yes';
            }

            
        } catch (error) {
            console.error('Error loading application:', error);
        }

    }
  

    handleChange(event){
        this.value = event.detail.value;
        const { name, value } = event.target;

        switch (name) {
            case 'mediaBox':
                this.updatedApplication.Media_Picture_Release__c = value;
                break;
            case 'infoBox':
                this.updatedApplication.Release_of_Information__c = value;
                break;
            case 'clearanceBox':
                this.updatedApplication.Consent_to_Request_Clearance__c = value;
                break;
            case 'parentBox':
                this.updatedApplication.Parent_s_Consent__c = value;
                break;
            default:
                console.warn(`Unknown combobox name: ${name}`);
        }

    }

    get hideFinish(){
        return !this.sigCaptured;
    }

    async handleSave(){
        try{
            if(this.alreadySigned == false){
                if (this.sigCaptured) {
                    saveSignature({ relatedId: this.recordId, data: [this.sigData] });
                }
                await updateJobApplications({appToUpdate : this.updatedApplication});
                this.showSuccessToast();
                this.alreadySigned = true;
            }else{
                this.showAlreadySignedToast();
            }
            
        }catch(error){
            this.error = error;
            this.errorMessage = 'There was an error saving the Consent Form: ' + error;
            this.showErrorToast();
            console.log('Error: ' + JSON.stringify(this.error));
        }
        
    }

    async clickSignatureButton() {
		const r = await signaturePanel.open({
			label: 'Applicant Signature',
			size: 'small',
		});
		if (r) {
			this.sigCaptured = r.signed;
			this.sigURL = r.signatureData.imgURL;
			this.sigData = r.signatureData.imgData;
		}
	}

    get disableSignature() {
		return this.showSignature && this.sigCaptured;
	}


    showSuccessToast(){
        const evt = new ShowToastEvent({
        title: 'Success',
        message: 'The Consent Form has been successfully saved.',
        variant: 'success',
        mode: 'dismissable'
    });
    this.dispatchEvent(evt);
    }

    showErrorToast(){
        const evt = new ShowToastEvent({
        title: 'Error',
        message: this.errorMessage,
        variant: 'error',
        mode: 'dismissable'
    });
    this.dispatchEvent(evt);
    }

    showAlreadySignedToast(){
        const evt = new ShowToastEvent({
        title: 'Error',
        message: 'The Consent Form has already been submitted for this youth.',
        variant: 'error',
        mode: 'dismissable'
    });
    this.dispatchEvent(evt);
    }

}