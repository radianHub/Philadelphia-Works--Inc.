import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import LightningConfirm from 'lightning/confirm';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getChecklist from '@salesforce/apex/DocumentChecklistController.getChecklist';
import deleteDocumentFile from '@salesforce/apex/DocumentChecklistController.deleteDocumentFile';
import DocumentChecklistModal from 'c/documentChecklistModal';

// TODO: Allow user to upload NEW version of an expired or rejected document
export default class DocumentChecklist extends LightningElement {
    @api recordId;
    @api title;
    @api description;
    @api headerColor;
    @api instructionsLink;
    @api checklistName;
    @api lookupField;
    documents = [];
    activeSections = [];
    wiredResult;

    @wire(getChecklist, { checklistName: '$checklistName', recordId: '$recordId', lookupField: '$lookupField' })
    wiredChecklist(result) {
        this.wiredResult = result;

        const { data, error } = result;
        if (data) {
            this.documents = data;
        } else if (error) {
            this.documents = [];
            console.error('getChecklist error', error);
        }
    }

    get headerStyle() {
        return this.headerColor ? 'color:' + this.headerColor : 'color:rgb(84, 105, 141)';
    }

    handleUpload(evt) {
        const document = this.documents.find((doc) => doc.name === evt.detail.title);
        if (!document) return;

        DocumentChecklistModal.open({
            title: evt.detail.title,
            recordId: this.recordId,
            documentId: evt.detail.documentId,
            documentType: document.type,
            lookupField: this.lookupField,
            description: document.description,
            checklistName: this.checklistName,
        }).then((result) => {
            if (result) {
                notifyRecordUpdateAvailable([{ recordId: result }]);
            }
            refreshApex(this.wiredResult);
        });
    }

    async handleDelete(evt) {
        const result = await LightningConfirm.open({
            label: 'Delete Document',
            message: 'Are you sure you want to delete this document? This action cannot be undone.',
            theme: 'error',
        });

        if (result) {
            deleteDocumentFile({ checklistName: this.checklistName, documentId: evt.detail.documentId })
                .then(() => {
                    notifyRecordUpdateAvailable([{ recordId: evt.detail.documentId }]);
                    refreshApex(this.wiredResult);

                    const event = new ShowToastEvent({
                        title: 'Success',
                        message: 'Document deleted successfully',
                        variant: 'success'
                    });
                    this.dispatchEvent(event);
                })
                .catch((error) => {
                    console.error('DocumentChecklist handleDelete error', error);
                    const event = new ShowToastEvent({
                        title: 'Error',
                        message: 'Something went wrong. Please try again.',
                        variant: 'error'
                    });
                    this.dispatchEvent(event);
                });
        }
    }
}