import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class ApplicantBulkUpdateModal extends LightningModal {
	@api choiceOptions;
	selectedChoice;
	reason;

	get showReason() {
		return this.selectedChoice === 'Passed';
	}

	handleSave() {
		// TODO: validate form before closing
		const allValid = [
			...this.template.querySelectorAll('lightning-textarea'),
			...this.template.querySelectorAll('lightning-combobox'),
		].reduce((validSoFar, inputCmp) => {
			inputCmp.reportValidity();
			return validSoFar && inputCmp.checkValidity();
		}, true);

		if (allValid) {
			this.close({
				choice: this.selectedChoice,
				reason: this.reason,
			});
		}
	}

	handleCancel() {
		this.close();
	}

	handleChoiceChange(evt) {
		this.selectedChoice = evt.detail.value;
	}

	handleReasonChange(evt) {
		this.reason = evt.detail.value;
	}
}