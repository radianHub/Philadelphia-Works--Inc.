import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

// * APEX
import getContacts from '@salesforce/apex/ProviderSupervisorsController.getContacts';
// import { refreshApex } from "@salesforce/apex";

// * SCHEMA
import USER_ID from '@salesforce/user/Id';
import ACCOUNT_ID from '@salesforce/schema/User.AccountId';

// * COMPONENTS
import SupervisorModal from 'c/supervisorModal';

// * CONSTANTS

const actions = [{ label: 'View details', name: 'view' }];

const columns = [
	{
		label: 'Supervisors',
		type: 'customSupervisorName',
		typeAttributes: {
			supervisorName: { fieldName: 'SupervisorName' },
			supervisorClearance: { fieldName: 'SupervisorClearance' },
		},
		hideDefaultActions: true,
		wrapText: true,
	},
	{ type: 'action', typeAttributes: { rowActions: actions } },
];

export default class ProviderSupervisors extends LightningElement {
	columns = columns;

	isLoading = false;

	@api title;
	@api description;
	@api supervisorDetailsFieldSetName;
	@api headerColor;

	supervisors;

	// * GETTERS

	get headerStyle() {
		return this.headerColor ? 'color:' + this.headerColor : 'color:rgb(84, 105, 141)';
	}

	get accountId() {
		return getFieldValue(this.user.data, ACCOUNT_ID);
	}

	// * WIRES

	@wire(getRecord, { recordId: USER_ID, fields: [ACCOUNT_ID] })
	user;

	@wire(getContacts, { accountId: '$accountId' })
	wiredSupervisors(result) {
		console.log('List: ' + JSON.stringify(result));
		const { error, data } = { ...result };
		if (data) {
			this.supervisors = this.formatContacts(data);
		} else if (error) {
			console.log('WIRED_SUPERVISORS_ERROR: ', error);
			this.jobs = null;
		}
		this.isLoading = false;
	}

	// * HANDLERS

	formatContacts(contacts) {
		return contacts.map((contact) => {
			return {
				...contact,
				SupervisorName: contact.Name,
				SupervisorClearance: contact.Supervisor_Clearance__c,
			};
		});
	}

	handleRowAction(event) {
		const row = event.detail.row;
		console.log('FieldSet: ' + this.supervisorDetailsFieldSetName);
		SupervisorModal.open({
			recordId: row.Id,
			supervisorName: row.Name,
			fieldSet: this.supervisorDetailsFieldSetName,
			size: 'full',
		}).catch((e) => {
			console.log('OPEN_VIEW_MODAL_ERROR', e.message);
		});
	}
}