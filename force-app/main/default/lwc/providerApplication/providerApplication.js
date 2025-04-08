import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

// import getApp from '@salesforce/apex/UniversalApp.retrieveApp';

export default class ProviderApplication extends LightningElement {
	recordId;
	canView;

	@wire(CurrentPageReference)
	wiredPageReference(currentPageReference) {
		const recordId = currentPageReference.state.recordId;
		console.log('recordId', recordId);
		if (recordId) {
			this.recordId = recordId;
			this.canView = true;
			// this.getApplication();
		}
	}

	// TODO: Confirm if provider should be able to view this Contact
	checkVisibility() {}
}