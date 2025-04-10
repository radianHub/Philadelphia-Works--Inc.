import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

import APPLICATION_CONTACT from '@salesforce/schema/Launchpad__Applicant_Tracking__c.Launchpad__Participant__r.Name';
import JOB_NAME from '@salesforce/schema/Launchpad__Applicant_Tracking__c.Launchpad__Job_Order__r.Name';
import PLACEMENT_SITE from '@salesforce/schema/Launchpad__Applicant_Tracking__c.C2L_Placement_Site__r.Name';
import PROVIDER_RANK from '@salesforce/schema/Launchpad__Applicant_Tracking__c.Provider_Rank__c';
import STAGE from '@salesforce/schema/Launchpad__Applicant_Tracking__c.Launchpad__Stage__c';
import PROVIDER_CHOICE from '@salesforce/schema/Launchpad__Applicant_Tracking__c.Provider_Choice__c';
import RECORD_TYPE_ID from '@salesforce/schema/Launchpad__Applicant_Tracking__c.RecordTypeId';

import canViewApplication from '@salesforce/apex/ProviderApplicantsController.canViewApplication';

export default class ProviderApplication extends LightningElement {
	@api headerColor;
	recordId;
	applicationId;
	isLoading = true;
	canView;

	providerRankField = PROVIDER_RANK;
	stageField = STAGE;
	providerChoiceField = PROVIDER_CHOICE;

	choiceOptions;

	@wire(CurrentPageReference)
	wiredPageReference(currentPageReference) {
		const recordId = currentPageReference.state.recordId;
		const applicationId = currentPageReference.state.applicationId;
		if (recordId && applicationId) {
			this.checkVisibility(recordId, applicationId);
		}
	}

	// TODO: Implement choice selection
	@wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: PROVIDER_CHOICE })
	wiredChoices({ error, data }) {
		if (data) {
			this.choiceOptions = [...data.values];
		}
	}

	@wire(getRecord, {
		recordId: '$applicationId',
		fields: [APPLICATION_CONTACT, JOB_NAME, PLACEMENT_SITE, STAGE, PROVIDER_CHOICE, RECORD_TYPE_ID],
	})
	wiredApplicant;

	get applicantNameValue() {
		return getFieldValue(this.wiredApplicant.data, APPLICATION_CONTACT);
	}

	get jobNameValue() {
		return getFieldValue(this.wiredApplicant.data, JOB_NAME);
	}

	get choiceValue() {
		return getFieldValue(this.wiredApplicant.data, PROVIDER_CHOICE);
	}

	get recordTypeId() {
		return getFieldValue(this.wiredApplicant.data, RECORD_TYPE_ID);
	}

	get stageValue() {
		return getFieldValue(this.wiredApplicant.data, STAGE);
	}

	get headerStyle() {
		return this.headerColor ? 'color:' + this.headerColor : 'color:rgb(84, 105, 141)';
	}

	checkVisibility(recordId, applicationId) {
		canViewApplication({ applicationId: applicationId })
			.then((result) => {
				this.recordId = recordId;
				this.applicationId = applicationId;
				this.canView = result;
				this.isLoading = false;
			})
			.catch((error) => {
				this.canView = false;
				this.isLoading = false;
				console.error('error', error);
			});
	}
}