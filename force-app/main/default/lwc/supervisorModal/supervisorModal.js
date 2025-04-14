import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import getFieldsByObjectAndFieldSet from '@salesforce/apex/ProviderApplicantsController.getFieldsByObjectAndFieldSet';

export default class SupervisorModal extends LightningModal {
	@api recordId;
	@api supervisorName;
	@api fieldSet;
	isLoading = true;

	contactInfo = [];

	async connectedCallback() {
		this.contactInfo = await this.getFieldSet(this.fieldSet);
		console.log('ContactInfo: ' + this.contactInfo);
		this.isLoading = false;
	}

	getFieldSet(fieldSetName) {
		return getFieldsByObjectAndFieldSet({
			objectName: 'Contact',
			fieldSetName: fieldSetName,
		});
	}

	handleClose() {
		this.close();
	}
}