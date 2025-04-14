import { LightningElement, api } from 'lwc';
import ApplicantModal from 'c/applicantModal';

export default class ApplicantTile extends LightningElement {
    @api applicant;

    viewApplication() {
        ApplicantModal.open({
            applicationId: this.applicant.Id,
            size: 'full'
        });
    }

    handleSelect() {
        this.dispatchEvent(new CustomEvent('select', {
            detail: this.applicant
        }));
    }
}