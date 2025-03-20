import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import USER_ID from '@salesforce/user/Id';
import ACCOUNT_ID from '@salesforce/schema/User.AccountId';
import STAGE from '@salesforce/schema/Launchpad__Applicant_Tracking__c.Launchpad__Stage__c';

import getApplicants from '@salesforce/apex/ProviderApplicantsController.getApplicants';
import bulkUpdateApplicantStage from '@salesforce/apex/ProviderApplicantsController.bulkUpdateApplicantStage';

const DEFAULT_STAGE = {
	label: 'All Stages',
	value: 'All',
};
const DEFAULT_PROGRAM = {
	label: 'All Programs',
	value: 'All',
};

const actions = [{ label: 'View details', name: 'view' }];

const columns = [
	{
		label: 'Applicant Name',
		type: 'customApplicantName',
		typeAttributes: {
			applicantName: { fieldName: 'ParticipantName' },
			isPriority: { fieldName: 'Priority_Population__c' },
			programName: { fieldName: 'ProgramName' },
			rank: { fieldName: 'Provider_Rank__c' },
		},
		hideDefaultActions: true,
		wrapText: true,
	},
	{ label: 'Stage', fieldName: 'Launchpad__Stage__c', hideDefaultActions: true, wrapText: true },
	{ type: 'action', typeAttributes: { rowActions: actions } },
];

// TODO: Set up field sets for the table and details
export default class ProviderApplicants extends LightningElement {
	@api title;
	@api description;
	@api tableFieldSetApiName;
	@api detailsFieldSetApiName;
	@api headerColor;
	recordTypeId;
	applicants;
	isLoading = true;
	columns = columns;
	actions = actions;
	@track selectedRows = [];

	// filters
	stageOptions = [DEFAULT_STAGE];
	stage;
	programOptions = [DEFAULT_PROGRAM];
	program;
	priorityOptions = [
		{
			label: 'All Applicants',
			value: 'All',
		},
		{
			label: 'Priority Population',
			value: 'Priority',
		},
	];
	priority = 'All Applicants';

	// Bulk Stage Options
	bulkStageOptions = [
		{
			value: 'Provider Selected',
			label: 'Provider Selected',
		},
		{
			value: 'Shortlisted',
			label: 'Shortlisted',
		},
		{
			value: 'Passed',
			label: 'Passed',
		},
	];
	selectedBulkStage;
	passReason;

	get accountId() {
		return getFieldValue(this.user.data, ACCOUNT_ID);
	}

	get headerStyle() {
		return this.headerColor ? 'color:' + this.headerColor : 'color:rgb(84, 105, 141)';
	}

	get hasNoSelections() {
		console.log('length', this.selectedRows.length);
		return this.selectedRows.length === 0;
	}

	@wire(getRecord, { recordId: USER_ID, fields: [ACCOUNT_ID] })
	user;

	@wire(getApplicants, { accountId: '$accountId' })
	wiredApplicants({ error, data }) {
		if (data) {
			this.applicants = this.formatApplicants(data);
			// this.applicants = data;
			this.recordTypeId = this.applicants[0]?.RecordTypeId;

			this.programOptions = [
				DEFAULT_PROGRAM,
				...this.applicants.map((applicant) => {
					return {
						label: applicant.Launchpad__Job_Order__r.Name,
						value: applicant.Launchpad__Job_Order__r.Name,
					};
				}),
			];
			console.log('applicants', this.applicants);
			this.isLoading = false;
		} else if (error) {
			this.applicants = null;
			this.isLoading = false;
		}
	}

	@wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: STAGE })
	wiredStages({ error, data }) {
		if (data) {
			this.stageOptions = [DEFAULT_STAGE, ...data.values.filter(({ value }) => value !== 'In Progress')];
		} else if (error) {
			this.stageOptions = DEFAULT_STAGE;
		}
	}

	handleStageChange(evt) {
		console.log('evt', evt.detail.value);
		this.stage = evt.detail.value;
	}

	handleProgramChange(evt) {
		console.log('evt', evt.detail.value);
		this.program = evt.detail.value;
	}

	handlePriorityChange(evt) {
		console.log('evt', evt.detail.value);
		this.priority = evt.detail.value;
	}

	handleClear() {
		this.stage = DEFAULT_STAGE.value;
		this.program = DEFAULT_PROGRAM.value;
		this.priority = 'All';
	}

	formatApplicants(applicants) {
		return applicants.map((applicant) => {
			return {
				...applicant,
				ParticipantName: applicant.Launchpad__Participant__r.Name,
				ProgramName: applicant.Launchpad__Job_Order__r.Name,
			};
		});
	}

	handleRowSelection(evt) {
		this.selectedRows = evt.detail.selectedRows;
		console.log('selectedRows', JSON.parse(JSON.stringify(this.selectedRows)));
	}

	handleRowAction(evt) {
		const actionName = evt.detail.action.name;
		const row = evt.detail.row;
		switch (actionName) {
			case 'view':
				// this.viewDetails(row);
				// TODO: open modal
				break;
			default:
		}
	}

	handleUpdateStage() {
		try {
			console.log('selectedRows', this.selectedRows);
			const applicantIds = this.selectedRows.map((applicant) => applicant.Id);
			const stage = this.selectedBulkStage;
			const passReason = this.passReason;
			bulkUpdateApplicantStage({ applicantIds, stage, passReason }).then(() => {
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Success',
						message: 'Applicants updated successfully',
						variant: 'success',
					})
				);
			});
		} catch (error) {
			console.error('Stage update error', error);
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Error updating stage',
					message: 'An error occurred while updating the stage',
					variant: 'error',
				})
			);
		}
	}
}