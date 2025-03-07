import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import CONTACT_ID from '@salesforce/schema/User.ContactId';
import USER_ID from '@salesforce/user/Id';

import getContactApplications from '@salesforce/apex/CreateApplicationController.getContactApplications';

export default class YouthApplication extends NavigationMixin(LightningElement) {
    @api recordId;
    @api appDevName;
    @api canShowRestart;
    @api headerColor;
    applications;
    contactId;
    isLoading = true;

    // get contactId() {
    //     return getFieldValue(this.user.data, CONTACT_ID);
    // }

    get headerStyle() {
        return this.headerColor ? 'color:' + this.headerColor : 'color:rgb(84, 105, 141)';
    }

    get inProgress() {
        return this.stage === 'In Progress';
    }

    get submitted() {
        return this.hasApplications && !this.inProgress;
    }

    get hasApplications() {
        return this.applications?.length > 0;
    }
    
    get applicationId() {
        return this.hasApplications ? this.applications[0].Id : null;
    }

    get stage() {
        return this.hasApplications ? this.applications[0].Launchpad__Stage__c : null;
    }

    // @wire(getContactApplications, { contactId: '$contactId' })
    // wiredApplication({ error, data }) {
    //     if (error) {
    //         const event = new ShowToastEvent({
    //             title: 'Error',
    //             message: 'There was an error loading your application',
    //             variant: 'error'
    //         })
    //         this.dispatchEvent(event);
    //         console.error('Error loading application', error);
    //         this.isLoading = false;
    //     } else if (data) {
    //         this.applications = data;
    //         this.isLoading = false;
    //     }
    // }
    connectedCallback() {
        if (this.contactId) {
            this.getApplications();
        }
    }

    getApplications() {
        return getContactApplications({ contactId: this.contactId })
        .then((applications) => {
            this.applications = applications;
            this.isLoading = false;
        })
        .catch((error) => {
            const event = new ShowToastEvent({
                    title: 'Error',
                    message: 'There was an error loading your application',
                    variant: 'error'
                })
                this.dispatchEvent(event);
                console.error('Error loading application', error);
                this.isLoading = false;
        });
    }

    @wire(getRecord, { recordId: USER_ID, fields: [CONTACT_ID] })
    wiredUser({ error, data }) {
        if (error) {
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'There was an error loading your user',
                variant: 'error'
            })
            this.dispatchEvent(event);
            console.error('Error loading user', error);
        } else if (data) {
            this.contactId = getFieldValue(data, CONTACT_ID);
            if (this.contactId) {
                this.getApplications();
            } else {
                this.isLoading = false;
            }
        }
    }

    handleNavigateToApply() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Program_Locator__c'
            }
        });
    }
}