import { LightningElement, api, wire } from 'lwc';
import searchJobs from '@salesforce/apex/ProviderSearchController.searchJobs';

export default class ProviderSearch extends LightningElement {
    @api title;
    @api description;
    @api headerColor;

    providers = [];
    ageOptions = [];
    gradeOptions = [];
    genderOptions = [];

    zipCode;
    age = [];
    grade = [];
    gender;

    get headerStyle() {
		return this.headerColor ? 'color:' + this.headerColor : 'color:rgb(84, 105, 141)';
	}

    connectedCallback() {
        this.getPicklistValues();
    }

    @wire(searchJobs, { age: '$age' })
    wiredJobs({ error, data }) {
        if (data) {
            console.log('searchJobs data', data);
            this.providers = this.formatProviders(data);
            console.log('providers', this.providers);
        } else if (error) {
            console.error('searchJobs error', error);
        } else {
            console.log('NO DATA!');
        }
    }

    handleChange(evt) {
        console.log('handleChange', evt);
        switch (evt.detail.name) {
            case 'zipCode':
                this.zipCode = evt.detail.value;
                break;
            case 'age':
                this.age = evt.detail.value;
                break;
            case 'grade':
                this.grade = evt.detail.value;
                break;
            case 'gender':
                this.gender = evt.detail.value;
                break;
            default:
                break;
        }
    }

    handleClear(evt) {
        console.log('handleClear', evt);
        this.zipCode = null;
        this.age = [];
        this.grade = [];
        this.gender = null;
    }

    getPicklistValues() {
        // TODO: Get options from Job picklists
        for (let i = 12; i < 24; i++) {
            this.ageOptions.push({ label: `${i}`, value: `${i}` });
        }

        for (let i = 6; i < 12; i++) {
            this.gradeOptions.push({ label: `${i}`, value: `${i}` });
        }

        this.genderOptions.push({
            label: 'Male',
            value: 'Male'
        }, {
            label: 'Female',
            value: 'Female'
        });
    }

    formatProviders(data) {
        return data.map(provider => {
            const locationSource = provider.Job_Site__r ? 'Job_Site__r' : 'Launchpad__Account__r';

            return {
                id: provider.Id,
                title: provider.Name,
                agesServed: provider.Ages_Served__c,
                genderServed: provider.Gender_Served__c,
                gradesServed: provider.Grades_Served__c,
                location: {
                    City: provider[locationSource].BillingCity,
                    State: provider[locationSource].BillingState,
                    Street: provider[locationSource].BillingStreet,
                    PostalCode: provider[locationSource].BillingPostalCode,
                    Country: 'USA',
                }
            }
        });
    }
}