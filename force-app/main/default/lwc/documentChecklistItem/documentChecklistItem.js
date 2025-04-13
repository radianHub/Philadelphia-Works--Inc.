import { LightningElement, api } from 'lwc';

import getContentVersionFromDocumentId from '@salesforce/apex/DocumentChecklistController.getContentVersionFromDocumentId';
import template from './documentChecklistItem.html';
import reviewTemplate from './documentChecklistItem_review.html';

export default class DocumentChecklistItem extends LightningElement {
	@api document;
	@api recordId;
	@api checklistName;
	@api lookupField;
	@api reviewMode;
	@api documentStatuses;
	url;
	selectedStatus;
	isSubmitting;
	rejectionReason;

	documentOptions = [
		{
			label: 'Approve',
			value: 'Approved',
		},
		{
			label: 'Reject',
			value: 'Rejected',
		},
	];

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

	get isInReview() {
		return this.document.status === this.documentStatuses.submittedStatus;
	}

	get showRejectionReasonField() {
		return this.selectedStatus === 'Rejected';
	}

	render() {
		if (this.reviewMode) {
			return reviewTemplate;
		}
		return template;
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

	handleDelete() {
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
				let src;
				const communityId = null;

				if (communityId) {
					src = `/sfsites/c/sfc/servlet.shepherd/document/download/${data.ContentDocumentId}`;
				} else {
					src = data.VersionDataUrl;
				}

				this.dispatchEvent(
					new CustomEvent('preview', {
						detail: {
							title: this.document.name,
							src: src,
							fileExtension: data.FileExtension,
						},
					})
				);
			})
			.catch((error) => {
				console.error('getContentVersionFromDocumentId error', error);
			});
	}

	handleApprove() {
		this.dispatchEvent(
			new CustomEvent('approve', {
				detail: {
					documentId: this.document.documentId,
				},
			})
		);
	}

	handleReject() {
		this.dispatchEvent(
			new CustomEvent('reject', {
				detail: {
					documentId: this.document.documentId,
					rejectionReason: this.rejectionReason,
				},
			})
		);
	}

	handleStatusChange(evt) {
		this.selectedStatus = evt.detail.value;
	}

	handleRejectionReasonChange(evt) {
		this.rejectionReason = evt.target.value;
	}

	handleSubmit() {
		this.isSubmitting = true;

		const allValid = [
			...this.template.querySelectorAll('lightning-input'),
			...this.template.querySelectorAll('lightning-radio-group'),
		].reduce((validSoFar, inputCmp) => {
			inputCmp.reportValidity();
			return validSoFar && inputCmp.checkValidity();
		}, true);

		if (allValid) {
			if (this.selectedStatus === 'Approved') {
				this.handleApprove();
			} else if (this.selectedStatus === 'Rejected') {
				this.handleReject();
			}
		}
	}
}