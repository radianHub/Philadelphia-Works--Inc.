import { LightningElement, api, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getFieldsByObjectAndFieldSet from '@salesforce/apex/ProviderApplicantsController.getFieldsByObjectAndFieldSet';
import JOB_NAME from '@salesforce/schema/Launchpad__Applicant_Tracking__c.Launchpad__Job_Order__r.Name';
import PLACEMENT_SITE from '@salesforce/schema/Launchpad__Applicant_Tracking__c.C2L_Placement_Site__r.Name';
import PROVIDER_RANK from '@salesforce/schema/Launchpad__Applicant_Tracking__c.Provider_Rank__c';
import STAGE from '@salesforce/schema/Launchpad__Applicant_Tracking__c.Launchpad__Stage__c';
import APPLICANT_ID from '@salesforce/schema/Launchpad__Applicant_Tracking__c.Launchpad__Participant__c';
import PROVIDER_CHOICE from '@salesforce/schema/Launchpad__Applicant_Tracking__c.Provider_Choice__c';

export default class ApplicantModal extends LightningModal {
    @api applicationId;
    basicInfo;
    guardianInfo;
    emergencyContactInfo;
    demographicInfo;
    householdInfo;
    healthInfo;
    consents;
    release;
    attestations;
    selectedStage;
    stageOptions = [
        {
            label: 'Provider Selected',
            value: 'Provider Selected'
        }, {
            label: 'Shortlisted',
            value: 'Shortlisted'
        }, {
            label: 'Passed',
            value: 'Passed'
        }
    ];
    isSaving;

    jobNameField = JOB_NAME;
    placementSiteField = PLACEMENT_SITE;
    providerRankField = PROVIDER_RANK;
    stageField = STAGE;
    providerChoiceField = PROVIDER_CHOICE;

    async connectedCallback() {
        this.basicInfo = await this.getFieldSet('Basic_Personal_Information');
        this.guardianInfo = await this.getFieldSet('Applicant_s_Guardian_Information');
        this.emergencyContactInfo = await this.getFieldSet('Applicant_s_Emergency_Contact_Info');
        this.demographicInfo = await this.getFieldSet('Demographic_Information');
        this.householdInfo = await this.getFieldSet('Household_Information');
        this.healthInfo = await this.getFieldSet('Health_Information');
        this.attestations = await this.getFieldSet('Self_Attestations');
        this.consents = await this.getFieldSet('Consents');
        this.release = await this.getFieldSet('Release_of_Information');
        console.log('basicInfo', this.basicInfo);
    }

    @wire(getRecord, { recordId: '$applicationId', fields: [JOB_NAME, PLACEMENT_SITE, APPLICANT_ID, STAGE] })
    wiredApplicant;

    get jobNameValue() {
        return getFieldValue(this.wiredApplicant.data, JOB_NAME);
    }

    get placementSiteValue() {
        return getFieldValue(this.wiredApplicant.data, JOB_NAME);
    }

    get applicantId() {
        return getFieldValue(this.wiredApplicant.data, APPLICANT_ID);
    }

    get shouldUpdateStatus() {
        const updatableStages = [
            'Submitted',
            'Passed',
            'Shortlisted',
            'Provider Selected',
            'Matched with Provider',
            'Ready for JEVs Sign-Off'
        ];
        return this.stageValue !== null && updatableStages.includes(this.stageValue);
    }

    get stageValue() {
        return getFieldValue(this.wiredApplicant.data, STAGE);
    }

    getFieldSet(fieldSetName) {
        return getFieldsByObjectAndFieldSet({ objectName: 'Launchpad__Applicant_Tracking__c', fieldSetName: fieldSetName });
    }

    handleClose() {
        this.close();
    }

    handleStageChange(evt) {
        this.selectedStage = evt.detail.value;
    }

    handleSave() {
        this.isSaving = true;

        const allValid = [
            ...this.template.querySelectorAll('lightning-radio-group')
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (allValid) {
                if (this.selectedStatus === 'Approved') {
                    this.handleApprove();
                } else if (this.selectedStatus === 'Rejected') {
                    this.handleReject();
                }
        }
    }

    handleProviderChoiceSubmit(evt) {
        evt.preventDefault();

        const fields = evt.detail.fields;
        if (this.shouldUpdateStatus) {
            fields.Launchpad__Stage__c = this.selectedStage;
        }

        console.log('fields', fields);
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleProviderChoiceSuccess() {
        const event = new ShowToastEvent({
            title: 'Success',
            message: 'Your choice has been saved',
            variant: 'success',
        });
        this.dispatchEvent(event);
    }
}