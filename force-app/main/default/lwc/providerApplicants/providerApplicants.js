import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { refreshApex } from '@salesforce/apex';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

import USER_ID from '@salesforce/user/Id';
import ACCOUNT_ID from '@salesforce/schema/User.AccountId';
import STAGE from '@salesforce/schema/Launchpad__Applicant_Tracking__c.Launchpad__Stage__c';
import PROVIDER_CHOICE from '@salesforce/schema/Launchpad__Applicant_Tracking__c.Provider_Choice__c';

import getApplicants from '@salesforce/apex/ProviderApplicantsController.getApplicants';
import getActiveJobs from '@salesforce/apex/ProviderApplicantsController.getActiveJobs';
import bulkUpdateApplicantStage from '@salesforce/apex/ProviderApplicantsController.bulkUpdateApplicantStage';
import ApplicantModal from 'c/applicantModal';
import ApplicantBulkUpdateModal from 'c/applicantBulkUpdateModal';

const DEFAULT_CHOICE = {
	label: 'All Choices',
	value: 'All',
};
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
			isPriority: { fieldName: 'PriorityPopulation' },
			programName: { fieldName: 'ProgramName' },
			rank: { fieldName: 'ProviderRank' },
			stage: { fieldName: 'Stage' },
		},
		hideDefaultActions: true,
		wrapText: true,
	},
	{ label: 'Provider Choice', fieldName: 'Provider_Choice__c', hideDefaultActions: true, wrapText: true },
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
	wiredResult;
	@track selectedRows = [];

	// filters
	choiceFilterOptions = [DEFAULT_CHOICE];
	choice = DEFAULT_CHOICE.value;
	stageFilterOptions = [DEFAULT_STAGE];
	stage = DEFAULT_STAGE.value;
	programOptions = [DEFAULT_PROGRAM];
	program = DEFAULT_CHOICE.value;
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
	priority = 'All';

	// Provider Choice Options for bulk update modal
	choiceOptions = [];

	get accountId() {
		return getFieldValue(this.user.data, ACCOUNT_ID);
	}

	get headerStyle() {
		return this.headerColor ? 'color:' + this.headerColor : 'color:rgb(84, 105, 141)';
	}

	get hasNoSelections() {
		return this.selectedRows.length === 0;
	}

	@wire(getRecord, { recordId: USER_ID, fields: [ACCOUNT_ID] })
	user;

	@wire(getActiveJobs, { accountId: '$accountId' })
	wiredJobs({ error, data }) {
		if (data) {
			this.programOptions = [
				DEFAULT_PROGRAM,
				...data.map((job) => {
					return {
						label: job.Name,
						value: job.Id,
					};
				}),
			];
		} else if (error) {
			this.programOptions = [DEFAULT_PROGRAM];
		}
	}

	@wire(getApplicants, {
		accountId: '$accountId',
		choice: '$choice',
		jobId: '$program',
		priority: '$priority',
		stage: '$stage',
	})
	wiredApplicants(result) {
		this.wiredResult = result;

		if (result.data) {
			this.applicants = this.formatApplicants(result.data);
			this.recordTypeId = this.applicants[0]?.RecordTypeId;
			this.isLoading = false;
		} else if (result.error) {
			this.applicants = null;
			this.isLoading = false;
		}
	}

	@wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: PROVIDER_CHOICE })
	wiredChoices({ error, data }) {
		if (data) {
			this.choiceOptions = [...data.values];
			this.choiceFilterOptions = [DEFAULT_CHOICE, ...data.values];
		} else if (error) {
			this.choiceFilterOptions = [DEFAULT_CHOICE];
		}
	}

	@wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: STAGE })
	wiredStages({ error, data }) {
		if (data) {
			const stageOptions = [
				...data.values.filter((val) => {
					const filteredStages = ['In Progress', 'Unavailable'];
					return !filteredStages.includes(val.value);
				}),
			];
			this.stageFilterOptions = [DEFAULT_STAGE, ...stageOptions];
		} else if (error) {
			this.stageFilterOptions = [DEFAULT_STAGE];
		}
	}

	handleChoiceChange(evt) {
		this.isLoading = true;
		this.choice = evt.detail.value;
	}

	handleStageChange(evt) {
		this.isLoading = true;
		this.stage = evt.detail.value;
	}

	handleProgramChange(evt) {
		this.isLoading = true;
		this.program = evt.detail.value;
	}

	handlePriorityChange(evt) {
		this.isLoading = true;
		this.priority = evt.detail.value;
	}

	handleClear() {
		this.stage = DEFAULT_STAGE.value;
		this.choice = DEFAULT_CHOICE.value;
		this.program = DEFAULT_PROGRAM.value;
		this.priority = 'All';
	}

	formatApplicants(applicants) {
		return applicants.map((applicant) => {
			return {
				...applicant,
				ParticipantName: applicant.Launchpad__Participant__r.Name,
				ProgramName: applicant.Launchpad__Job_Order__r.Name,
				PriorityPopulation: applicant.Launchpad__Participant__r.Priority_Population__c,
				ProviderRank: applicant.Provider_Rank__c ? `Rank ${applicant.Provider_Rank__c}` : null,
				Stage: applicant.Launchpad__Stage__c ? `Stage: ${applicant.Launchpad__Stage__c}` : null,
			};
		});
	}

	handleRowSelection(evt) {
		this.selectedRows = evt.detail.selectedRows;
	}

	handleRowAction(evt) {
		const actionName = evt.detail.action.name;
		const row = evt.detail.row;
		switch (actionName) {
			case 'view':
				this.viewDetails(row);
				break;
			default:
		}
	}

	async viewDetails(row) {
		const result = await ApplicantModal.open({
			applicationId: row.Id,
			label: row.ParticipantName,
			choice: row.Provider_Choice__c,
			choiceOptions: this.choiceOptions,
			size: 'full',
		});

		if (result) {
			const updateChoiceResult = await this.updateChoice(result);

			if (!updateChoiceResult) {
				return;
			}

			this.viewDetails({
				...row,
				Provider_Choice__c: updateChoiceResult.choice,
			});
		}
	}

	async updateChoice(id) {
		try {
			const result = await ApplicantBulkUpdateModal.open({
				choiceOptions: this.choiceOptions,
				size: 'small',
				description: 'Update all selected applicants to the same choice',
			});

			if (!result) {
				return;
			}

			this.isLoading = true;
			const applicantIds = id ? [id] : this.selectedRows.map((applicant) => applicant.Id);
			const choice = result.choice;
			const passReason = result.reason;

			await bulkUpdateApplicantStage({ applicantIds: applicantIds, choice: choice, passReason: passReason }).then(
				() => {
					this.dispatchEvent(
						new ShowToastEvent({
							title: 'Success',
							message: 'Applicants updated successfully',
							variant: 'success',
						})
					);
				}
			);

			await refreshApex(this.wiredResult);
			await notifyRecordUpdateAvailable(applicantIds.map((appId) => ({ recordId: appId })));
		} catch (error) {
			console.error('Stage update error', error);
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Error updating stage',
					message: 'An error occurred while updating the stage',
					variant: 'error',
				})
			);
			this.isLoading = false;
		}
	}

	handleUpdateChoice() {
		this.updateChoice();
	}
}