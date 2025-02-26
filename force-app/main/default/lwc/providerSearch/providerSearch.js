import { LightningElement, api, wire } from 'lwc';
import searchJobsDynamic from '@salesforce/apex/ProviderSearchController.searchJobsDynamic';
import getJobFieldSetData from '@salesforce/apex/ProviderSearchController.getJobFieldSetMembers';

export default class ProviderSearch extends LightningElement {
	@api title;
	@api description;
	@api searchFiltersFieldSetApiName;
	@api detailsFieldSetApiName;
	@api headerColor;
	@api cardHeaderColor;
	@api cardBodyBgColor;
	hasLoaded;
	timeout;
	isLoading = true;

	providers = [];
	mapProviders = [];
	zipCode = null;
	searchFiltersFieldData = [];
	detailsFieldData = [];
	detailsFieldApiNames = [];
	textFiltersSelected = {};
	picklistFiltersSelected = {};

	get headerStyle() {
		return this.headerColor ? 'color:' + this.headerColor : 'color:rgb(84, 105, 141)';
	}

	get hasProviders() {
		return this.providers.length > 0;
	}

	connectedCallback() {
		if (this.searchFiltersFieldSetApiName) {
			this.getSearchFiltersFieldData();
		}
		if (this.detailsFieldSetApiName) {
			this.getDetailsFieldData();
		}
	}

	async getSearchFiltersFieldData() {
		try {
			const fieldData = await getJobFieldSetData({ fieldSetName: this.searchFiltersFieldSetApiName });
			this.searchFiltersFieldData = fieldData.filter((data) => data.apiName !== 'Launchpad__Zip__c');
		} catch (e) {
			console.error('GET_SEARCH_FILTERS_ERROR: ', e);
		}
	}

	async getDetailsFieldData() {
		try {
			const fieldData = await getJobFieldSetData({ fieldSetName: this.detailsFieldSetApiName });
			const alwaysQueriedFields = [
				'Name',
				'Launchpad__Job_Description__c',
				'Launchpad__Account_Address__c',
				'Job_Site_Address__c',
			];
			this.detailsFieldData = fieldData.filter((data) => !alwaysQueriedFields.includes(data.apiName));
			this.detailsFieldApiNames = this.detailsFieldData.map((data) => data.apiName);
		} catch (e) {
			console.error('GET_JOB_DETAILS_ERROR: ', e);
		}
	}

	@wire(searchJobsDynamic, {
		zipCode: '$zipCode',
		fieldsToQuery: '$detailsFieldApiNames',
		textFilters: '$textFiltersSelected',
		picklistFilters: '$picklistFiltersSelected',
	})
	wiredJobs({ error, data }) {
		if (error) {
			console.error('SEARCH_JOBS_WIRE_ERROR: ', error);
		} else if (data) {
			this.providers = this.formatProviders(data);
			this.mapProviders = this.formatProviders(data, true);
			this.isLoading = false;
		}

		this.hasLoaded = true;
	}

	handleInputChange(e) {
		if (this.timeout) {
			clearTimeout(this.timeout);
		}

		const name = e.target.name;
		const value = e.target.value;
		const textFiltersSelected = { ...this.textFiltersSelected };

		// eslint-disable-next-line @lwc/lwc/no-async-operation
        this.timeout = setTimeout(() => {
            switch (name) {
                case 'zipcode':
                    this.zipCode = value;
                    break;
                default:
					textFiltersSelected[name] = value;
					this.textFiltersSelected = textFiltersSelected;
                    break;
            }
        }, 300);
	}

	handleMultiselectChange(e) {
		const picklistFiltersSelected = { ...this.picklistFiltersSelected };
		picklistFiltersSelected[e.target.name] = e.detail.value;
		this.picklistFiltersSelected = picklistFiltersSelected;
	}

	handleClear() {
		this.zipCode = null;
		this.textFiltersSelected = {};
		this.picklistFiltersSelected = {};

		this.template.querySelectorAll('lightning-input').forEach((input) => {
			input.value = '';
		});
		this.template.querySelectorAll('c-multi-select-combobox').forEach((combobox) => {
			combobox.clear();
		});
	}

	formatProviders(data, isMapFormat) {
		return data.map((provider) => {
			const locationSource = provider.Placement_Site__r ? 'Placement_Site__r' : 'Launchpad__Account__r';
			let details = [];

			const address = `${provider[locationSource].BillingStreet}, ${provider[locationSource].BillingCity}, ${provider[locationSource].BillingState} ${provider[locationSource].BillingPostalCode}`;

			if (isMapFormat) {
				if (provider.Launchpad__Account__r.Name) {
					details.push({ label: 'Provider Name', value: provider.Launchpad__Account__r.Name });
				}

				details.push({ label: 'Address', value: address });

				if (provider.Launchpad__Job_Description__c) {
					details.push({ label: 'Description', value: provider.Launchpad__Job_Description__c });
				}
			}

			for (const fieldData of this.detailsFieldData) {
				if (provider[fieldData.apiName]) {
					details.push({
						label: fieldData.label,
						value: this.formatMultiselectValue(provider[fieldData.apiName]),
					});
				}
			}

			return {
				id: provider.Id,
				title: provider.Name,
				subtitle: provider.Launchpad__Account__r.Name,
				richDescription: provider.Launchpad__Job_Description__c,
				address,
				details,
				location: {
					Street: provider[locationSource].BillingStreet,
					City: provider[locationSource].BillingCity,
					State: provider[locationSource].BillingState,
					PostalCode: provider[locationSource].BillingPostalCode,
					Country: 'USA',
				},
			};
		});
	}

	formatMultiselectValue(value) {
		return value.replaceAll(';', ', ');
	}
}