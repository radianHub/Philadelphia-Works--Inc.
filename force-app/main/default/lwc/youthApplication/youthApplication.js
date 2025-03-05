import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import STAGE_FIELD from '@salesforce/schema/Launchpad__Applicant_Tracking__c.Launchpad__Stage__c';
import CONTACT_ID from '@salesforce/schema/Launchpad__Applicant_Tracking__c.Launchpad__Participant__c';

export default class YouthApplication extends LightningElement {
    @api recordId;
    @api appDevName;
    @api canShowRestart;
    @api headerColor;

    get isEditing() {
        return this.stage === 'In Progress';
    }

    get contactId() {
        return getFieldValue(this.application.data, CONTACT_ID);
    }

    get headerStyle() {
        return this.headerColor ? 'color:' + this.headerColor : 'color:rgb(84, 105, 141)';
    }

    get stage() {
        return getFieldValue(this.application.data, STAGE_FIELD);
    }

    @wire(getRecord, { recordId: '$recordId', fields: [STAGE_FIELD, CONTACT_ID] })
    application;
}