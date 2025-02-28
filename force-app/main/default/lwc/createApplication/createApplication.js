import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import createApplication from '@salesforce/apex/CreateApplicationController.createApplication';

import CONTACT_ID from '@salesforce/schema/User.ContactId';
import USER_EMAIL from '@salesforce/schema/User.Email';
import USER_ID from '@salesforce/user/Id';

/**
 * Initialize a new application with all the necessary information and navigate to the universal app
 */
export default class CreateApplication extends NavigationMixin(LightningElement) {
    @api jobId;

	@wire(getRecord, { recordId: USER_ID, fields: [CONTACT_ID, USER_EMAIL] })
    user;

    get contactId() {
        return getFieldValue(this.user.data, CONTACT_ID);
    }

    get contactEmail() {
        return getFieldValue(this.user.data, USER_EMAIL);
    }

    createApplication() {
        console.log('this.contactId: ', this.contactId);
        if (!this.contactId) {
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'You must have a contact record to create an application',
                variant: 'error'
            });
            this.dispatchEvent(event);
            return;
        }

        // Create a new application
        createApplication({ jobId: this.jobId, contactId: this.contactId, contactEmail: this.contactEmail })
            .then((response) => {
                console.log('response: ', response);
                this.navigateToUniversalApp(response);
            })
            .catch(error => {
                const event = new ShowToastEvent({
                    title: 'Error',
                    message: 'There was an error creating the application',
                    variant: 'error'
                })
                this.dispatchEvent(event);
                console.error('Error creating application', error);
            });
    }

    navigateToUniversalApp(jobId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: jobId,
                objectApiName: 'Launchpad__Applicant_Tracking__c',
                actionName: 'view'
            }
        });
    }
}