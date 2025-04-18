import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import initializeDocument from '@salesforce/apex/DocumentChecklistController.initializeDocument';
import updateDocumentStatus from '@salesforce/apex/DocumentChecklistController.updateDocumentStatus';

export default class DocumentChecklistModal extends LightningModal {
	_documentId;

	@api recordId;
	@api title;
	@api documentType;
	@api description;
	@api lookupField;
	@api checklistName;
	@api documentOnFile;

	@api get documentId() {
		return this._documentId;
	}
	set documentId(val) {
		this._documentId = val;
	}

	connectedCallback() {
		if (!this.documentId) {
			this.initializeDocument();
		}
	}

	handleUploadFinished() {
		this.updateDocumentStatus('Submitted');

		const event = new ShowToastEvent({
			title: 'Success',
			message: 'Document uploaded successfully',
			variant: 'success',
		});
		this.dispatchEvent(event);
	}

	handleClose() {
		this.close(this.documentId);
	}

	updateDocumentStatus(status) {
		updateDocumentStatus({ checklistName: this.checklistName, documentId: this.documentId, status })
			.then(() => {
				this.close();
			})
			.catch((error) => {
				console.error('DocumentChecklistModal updateDocumentStatus error', error);
			});
	}

	initializeDocument() {
		initializeDocument({
			checklistName: this.checklistName,
			recordId: this.recordId,
			documentType: this.documentType,
			lookupField: this.lookupField,
		})
			.then((result) => {
				this._documentId = result;
			})
			.catch((error) => {
				console.error('DocumentChecklistModal initializeDocument error', error);
			});
	}
}