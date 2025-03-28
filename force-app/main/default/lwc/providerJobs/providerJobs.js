/**
 * Created by holden on 3/20/25.
 */

import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import ACCOUNT_ID from '@salesforce/schema/User.AccountId';
import getJobs from '@salesforce/apex/ProviderJobsController.getJobs';
import JobModal from 'c/jobModal';
import { refreshApex } from '@salesforce/apex';

const actions = [
	{ label: 'View details', name: 'view' },
	{ label: 'Edit details', name: 'edit' },
];

const columns = [
	{
		label: 'Program',
		type: 'customJobName',
		typeAttributes: {
			jobName: { fieldName: 'Name' },
			programName: { fieldName: 'ProgramName' },
			supervisorName: { fieldName: 'SupervisorName' },
		},
		hideDefaultActions: true,
		wrapText: true,
	},
	{ type: 'action', typeAttributes: { rowActions: actions } },
];

export default class ProviderJobs extends LightningElement {
	columns = columns;
	isLoading = true;
	@api title;
	@api description;
	@api jobDetailsFieldSetName;
	@api jobEditFieldSetName;
	@api headerColor;
	jobs;

	get headerStyle() {
		return this.headerColor ? 'color:' + this.headerColor : 'color:rgb(84, 105, 141)';
	}

	get accountId() {
		return getFieldValue(this.user.data, ACCOUNT_ID);
	}

	@wire(getRecord, { recordId: USER_ID, fields: [ACCOUNT_ID] })
	user;

	@wire(getJobs, { accountId: '$accountId' })
	wiredJobs(result) {
		this.wiredResult = result;
		const { error, data } = { ...result };
		if (data) {
			this.jobs = this.formatJobs(data);
		} else if (error) {
			console.log('WIRED_JOBS_ERROR: ', error);
			this.jobs = null;
		}
		this.isLoading = false;
	}

	formatJobs(jobs) {
		return jobs.map((job) => {
			return {
				...job,
				ProgramName: job.Program__r.Name,
				SupervisorName: job.Launchpad__Contact__r?.Name,
			};
		});
	}

	handleRowAction(evt) {
		const actionName = evt.detail.action.name;
		const row = evt.detail.row;
		switch (actionName) {
			case 'view':
				this.viewDetails(row);
				break;
			case 'edit':
				this.editDetails(row);
				break;
			default:
		}
	}

	viewDetails(row) {
		JobModal.open({
			recordId: row.Id,
			jobName: this.jobs.find((job) => job.Id === row.Id).Name,
			accountId: this.accountId,
			fieldSet: this.jobDetailsFieldSetName,
			isEditMode: false,
			supervisorName: this.jobs.find((job) => job.Id === row.Id).Launchpad__Contact__c
				? this.jobs.find((job) => job.Id === row.Id).Launchpad__Contact__r.Name
				: 'None',
			size: 'full',
		}).catch((e) => {
			console.log('OPEN_VIEW_MODAL_ERROR', e.message);
		});
	}

	async editDetails(row) {
		try {
			await JobModal.open({
				recordId: row.Id,
				jobName: this.jobs.find((job) => job.Id === row.Id).Name,
				accountId: this.accountId,
				fieldSet: this.jobEditFieldSetName,
				currentSupervisorId: this.jobs.find((job) => job.Id === row.Id).Launchpad__Contact__c,
				isEditMode: true,
				supervisorName: this.jobs.find((job) => job.Id === row.Id).Launchpad__Contact__c
					? this.jobs.find((job) => job.Id === row.Id).Launchpad__Contact__r.Name
					: 'None',
				size: 'full',
			});

			await refreshApex(this.wiredResult);
		} catch (e) {
			console.log('OPEN_EDIT_MODAL_ERROR', e.message);
		}
	}
}