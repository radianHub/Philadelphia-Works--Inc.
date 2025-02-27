import { LightningElement, api, wire } from 'lwc';

import getDocumentStatuses from '@salesforce/apex/DocumentChecklistController.getDocumentStatuses';
import getContentVersionFromDocumentId from '@salesforce/apex/DocumentChecklistController.getContentVersionFromDocumentId';

export default class DocumentChecklistItem extends LightningElement {
	@api document;
	@api recordId;
	@api checklistName;
	@api lookupField;
    documentStatuses = {
        approvedStatus: 'Approved',
        rejectedStatus: 'Rejected',
        submittedStatus: 'Submitted',
        defaultStatus: 'Not Started',
    };
    url;

    get statusIconName() {
        switch (this.document.status) {
            case this.documentStatuses.approvedStatus:
                return 'utility:check';
            case this.documentStatuses.rejectedStatus:
                return 'utility:close';
            case this.documentStatuses.submittedStatus:
                return 'utility:search';
            default:
                return 'utility:cancel_file_request';
        }
    }

    get statusIconVariant() {
        switch (this.document.status) {
            case this.documentStatuses.approvedStatus:
                return 'success';
            case this.documentStatuses.rejectedStatus:
                return 'error';
            case this.documentStatuses.submittedStatus:
                return 'warning';
            default:
                return '';
        }
    }

    get statusIconText() {
        return `${this.document.type} Status: ${this.document.status}`;
    }

    get statusBadgeClass() {
        switch (this.document.status) {
            case this.documentStatuses.approvedStatus:
                return 'slds-theme_success slds-var-m-left_large';
            case this.documentStatuses.rejectedStatus:
                return 'slds-theme_error slds-var-m-left_large';
            case this.documentStatuses.submittedStatus:
                return 'slds-theme_warning slds-var-m-left_large';
            default:
                return 'slds-var-m-left_large';
        }
    }

    @wire(getDocumentStatuses, { checklistName: '$checklistName' })
    wiredStatuses({ data, error }) {
        if (data) {
            this.documentStatuses = data;
        } else if (error) {
            console.error('getDocumentStatuses error', error);
        }
    }

	handleUpload() {
		const document = this.document;
		if (!document) return;

		this.dispatchEvent(
			new CustomEvent('upload', {
				detail: {
					title: document.name,
					documentId: document.documentId,
					documentType: document.type,
					description: document.description,
				},
			})
		);
	}

	handleDelete(evt) {
		this.dispatchEvent(
			new CustomEvent('delete', {
				detail: {
					documentId: this.document.documentId,
				},
			})
		);
	}

    handlePreview() {
        getContentVersionFromDocumentId({ documentId: this.document.documentId })
        .then((data) => {
            let url;
            // const communityId = getCommunityId();
            const communityId = null;
            console.log('communityId', communityId);
            console.log('getContentVersionFromDocumentId', data);

            if (communityId) {
                url = `/sfsites/c/sfc/servlet.shepherd/document/download/${data.ContentDocumentId}`;
            } else {
                url = data.VersionDataUrl;
            }
            window.open(url);
        })
        .catch((error) => {
            console.error('getContentVersionFromDocumentId error', error);
        })
    }
}