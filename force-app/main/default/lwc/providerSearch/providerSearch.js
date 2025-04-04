import { LightningElement, api, wire, track } from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import searchJobsDynamic from '@salesforce/apex/ProviderSearchController.searchJobsDynamic';
import getJobFieldSetData from '@salesforce/apex/ProviderSearchController.getJobFieldSetMembers';
import getFieldDataByObjectAndFieldNames from '@salesforce/apex/ProviderSearchController.getFieldDataByObjectAndFieldNames';
import getCurrentUsersContactFieldValues from '@salesforce/apex/ProviderSearchController.getCurrentUsersContactFieldValues';
import getContactJobEligibilityMappings from '@salesforce/apex/ProviderSearchController.getContactJobEligibilityMaps';

export default class ProviderSearch extends LightningElement {
	@api title;
	@api description;
	@api searchFiltersFieldSetApiName;
	@api detailsFieldSetApiName;
	@api headerColor;
	@api cardHeaderColor;
	@api cardBodyBgColor;
	@api showApply;
	isGuest = isGuest;
	hasLoaded;
	timeout;
	isLoading = true;

	providers = [];
	mapProviders = [];
	zipCode = null;
	eligibilityCriteriaFieldData = [];
	searchFiltersFieldData = [];
	detailsFieldData = [];
	detailsFieldApiNames = [];
	textFiltersSelected = {};
	picklistFiltersSelected = {};
	contactJobEligibilityMappings = {};
	activeSectionName;

	// Used by cart
	@track _selectedProviders = [];
	get selectedProviders() {
		return this._selectedProviders;
	}
	set selectedProviders(value) {
		// Reorder selections whenever selectedProviders is set
		this._selectedProviders = value.map((val, idx) => {
			val.order = idx + 1;
			return val;
		});
	}

	get selectedProvidersCount() {
		return this.selectedProviders?.length;
	}

	get headerStyle() {
		return this.headerColor ? 'color:' + this.headerColor : 'color:rgb(84, 105, 141)';
	}

	get hasProviders() {
		return this.providers.length > 0;
	}

	get isDisabled() {
		return this.selectedProvidersCount < 3 || this.selectedProvidersCount > 5;
	}

	async connectedCallback() {
		if (!isGuest) {
			await this.getContactJobEligibilityMappings();
			await this.getEligibilitySearchFieldData();
			this.setEligibilitySearchFieldValues();
		}
		if (this.searchFiltersFieldSetApiName) {
			this.getSearchFiltersFieldData();
		}
		if (this.detailsFieldSetApiName) {
			this.getDetailsFieldData();
		}
	}

	async getContactJobEligibilityMappings() {
		try {
			const mappings = await getContactJobEligibilityMappings();
			for (const fieldMapping of mappings) {
				this.contactJobEligibilityMappings[fieldMapping.Contact_Field_API_Name__c] =
					fieldMapping.Job_Field_API_Name__c;
			}
		} catch (e) {
			console.log('GET_CONTACT_JOB_ELIGIBILITY_MAPPINGS_ERROR', e);
		}
	}

	async getEligibilitySearchFieldData() {
		try {
			const fieldNames = Object.keys(this.contactJobEligibilityMappings);
			const fieldData = await getFieldDataByObjectAndFieldNames({ sObjectName: 'Contact', fieldNames });
			this.eligibilityCriteriaFieldData = fieldData.sort((a, b) => {
				if (a.label < b.label) {
					return -1;
				} else if (a.label > b.label) {
					return 1;
				}
				return 0;
			});
		} catch (e) {
			console.log('GET_ELIGIBILITY_SEARCH_FIELD_DATA_ERROR', e);
		}
	}

	async setEligibilitySearchFieldValues() {
		try {
			const fieldNames = Object.keys(this.contactJobEligibilityMappings);
			const fieldValuesContact = await getCurrentUsersContactFieldValues({ fieldNames });
			const eligibilityCriteriaData = [...this.eligibilityCriteriaFieldData];
			if (fieldValuesContact) {
				for (const field of Object.keys(fieldValuesContact)) {
					const fieldValue = fieldValuesContact[field];
					if (Object.keys(this.contactJobEligibilityMappings).includes(field) && fieldValue) {
						const fieldDataIndex = eligibilityCriteriaData.findIndex((data) => data.apiName === field);
						const fieldData = eligibilityCriteriaData[fieldDataIndex];
						fieldData.value = fieldValue;
						eligibilityCriteriaData[fieldDataIndex] = fieldData;
					}
				}
				this.eligibilityCriteriaFieldData = eligibilityCriteriaData;
				this.picklistFiltersSelected = this.getEligibilityCriteriaPicklistFiltersSelected();
			}
		} catch (e) {
			console.log('GET_ELIGIBILITY_SEARCH_FIELD_VALUES_ERROR', e);
		}
	}

	async getSearchFiltersFieldData() {
		try {
			const fieldData = await getJobFieldSetData({ fieldSetName: this.searchFiltersFieldSetApiName });
			const eligibilityFields = Object.values(this.contactJobEligibilityMappings);
			this.searchFiltersFieldData = fieldData.filter(
				(data) => data.apiName !== 'Launchpad__Zip__c' && !eligibilityFields.includes(data.apiName)
			);
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
			// Only set providers if user is guest or eligibility criteria (picklistFiltersSelected) has been aggregated
			if (isGuest || Object.keys(this.picklistFiltersSelected)?.length > 0) {
				this.providers = this.formatProviders(data);
				this.mapProviders = this.formatProviders(data, true);
				this.isLoading = false;
			}
		}

		this.hasLoaded = true;
	}

	handleInputChange(evt) {
		if (this.timeout) {
			clearTimeout(this.timeout);
		}

		const name = evt.target.name;
		const value = evt.target.value;
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
		this.picklistFiltersSelected = this.getEligibilityCriteriaPicklistFiltersSelected();

		this.template.querySelectorAll('lightning-input.filter').forEach((input) => {
			input.value = '';
		});
		this.template.querySelectorAll('c-multi-select-combobox.filter').forEach((combobox) => {
			combobox.clear();
		});
	}

	getEligibilityCriteriaPicklistFiltersSelected() {
		const picklistFiltersSelected = {};
		for (const fieldData of this.eligibilityCriteriaFieldData) {
			const searchFilterField = this.contactJobEligibilityMappings[fieldData.apiName];
			picklistFiltersSelected[searchFilterField] = fieldData.value ? [fieldData.value.toString()] : [];
		}
		return picklistFiltersSelected;
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
				isSelected: false,
			};
		});
	}

	formatMultiselectValue(value) {
		return value.replaceAll(';', ', ');
	}

	handleSelectProvider(evt) {
		const providerId = evt.detail.providerId;
		const selectedProviderIdx = this.providers.findIndex((provider) => provider.id === providerId);

		this.selectedProviders = [
			...this.selectedProviders,
			{
				...this.providers[selectedProviderIdx],
				isSelected: true,
			},
		];

		this.providers = [
			...this.providers.slice(0, selectedProviderIdx),
			{
				...this.providers[selectedProviderIdx],
				isSelected: true,
			},
			...this.providers.slice(selectedProviderIdx + 1),
		];
	}

	handleRemoveProvider(evt) {
		const providerId = evt.detail.providerId;
		const selectedProviderIdx = this.providers.findIndex((provider) => provider.id === providerId);

		this.selectedProviders = this.selectedProviders.filter((provider) => provider.id !== providerId);

		this.providers = [
			...this.providers.slice(0, selectedProviderIdx),
			{
				...this.providers[selectedProviderIdx],
				isSelected: false,
			},
			...this.providers.slice(selectedProviderIdx + 1),
		];
	}

	handleMoveUp(evt) {
		const providerId = evt.detail.providerId;
		const selectedProviderIdx = this.selectedProviders.findIndex((provider) => provider.id === providerId);

		// Use splice or slice or move element up one index
		this.selectedProviders = [
			...this.selectedProviders.slice(0, selectedProviderIdx - 1),
			this.selectedProviders[selectedProviderIdx],
			this.selectedProviders[selectedProviderIdx - 1],
			...this.selectedProviders.slice(selectedProviderIdx + 1),
		];
	}

	handleMoveDown(evt) {
		const providerId = evt.detail.providerId;
		const selectedProviderIdx = this.selectedProviders.findIndex((provider) => provider.id === providerId);

		// Use slice to move element down one index
		this.selectedProviders = [
			...this.selectedProviders.slice(0, selectedProviderIdx),
			this.selectedProviders[selectedProviderIdx + 1],
			this.selectedProviders[selectedProviderIdx],
			...this.selectedProviders.slice(selectedProviderIdx + 2),
		];
	}

	handleSectionToggle() {
		this.activeSectionName = this.activeSectionName ? null : 'selections';
	}
}