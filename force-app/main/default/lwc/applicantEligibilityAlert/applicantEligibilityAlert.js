import { LightningElement, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import USER_ID from '@salesforce/user/Id';
import CONTACT_ID from '@salesforce/schema/User.ContactId';
import AGE_AT_PROGRAM_START from '@salesforce/schema/Contact.Age_at_Start_of_Program__c';

export default class ApplicantEligibilityAlert extends LightningElement {
	showAlert;
	ageAtProgramStart;

	get contactId() {
		return getFieldValue(this.user.data, CONTACT_ID);
	}

	@wire(getRecord, { recordId: USER_ID, fields: [CONTACT_ID] })
	user;

	@wire(getRecord, { recordId: '$contactId', fields: [AGE_AT_PROGRAM_START] })
	wiredContact({ error, data }) {
		if (data) {
			this.ageAtProgramStart = getFieldValue(data, AGE_AT_PROGRAM_START);
			this.showAlert = this.ageAtProgramStart < 12 || this.ageAtProgramStart > 24;
		} else if (error) {
			console.error('Error fetching contact data:', error);
		}
	}
}