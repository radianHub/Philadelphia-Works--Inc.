import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class DocumentChecklistPreview extends LightningModal {
	@api title;
	@api src;
	@api fileExtension;
	@api documentId;

	get canPreview() {
		const validExtensions = ['jpg', 'jpeg', 'png', 'bmp'];
		return validExtensions.includes(this.fileExtension);
	}

	handleClose() {
		this.close();
	}
}