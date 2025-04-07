import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class DocumentChecklistPreview extends LightningModal {
	@api title;
	@api src;
	@api fileExtension;
	@api documentId;

	get showFrame() {
		return this.fileExtension === 'pdf' || this.fileExtension === 'docx' || this.fileExtension === 'doc';
	}

	handleClose() {
		this.close();
	}
}