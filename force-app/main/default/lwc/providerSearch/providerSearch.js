import { LightningElement, api, wire } from 'lwc';
import searchJobs from '@salesforce/apex/ProviderSearchController.searchJobs';

// TODO: Make map modal configurable field set
// TODO: Make card fields configurable via field set
// TODO: Handle zero results found
export default class ProviderSearch extends LightningElement {
    @api title;
    @api description;
    @api headerColor;
    @api cardHeaderColor;
    @api cardBodyColor;

    providers = [];
    ageOptions = [];
    gradeOptions = [];
    genderOptions = [];
    schoolOptions = [];

    zipCode = null;
    age = [];
    grade = [];
    school = [];
    gender = [];

    get headerStyle() {
		return this.headerColor ? 'color:' + this.headerColor : 'color:rgb(84, 105, 141)';
	}

    get cardHeaderStyle() {
        return this.cardHeaderColor ? '--slds-c-card-color-background:' + this.cardHeaderColor : '--slds-c-card-color-background:rgb(180, 188, 201)';
    }

    get cardBodyStyle() {
        return this.cardBodyColor ? 'background-color:' + this.cardBodyColor : 'background-color:rgb(235, 235, 235)';
    }

    connectedCallback() {
        this.getPicklistValues();
    }

    @wire(searchJobs, { zipCode: '$zipCode', age: '$age', grade: '$grade', gender: '$gender', school: '$school' })
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
        switch (evt.target.name) {
            case 'zipcode':
                this.zipCode = evt.detail.value;
                break;
            default:
                break;
        }
    }

    handleMultiselectChange(evt) {
        console.log('handleMultiselectChange', evt);
        switch (evt.detail.name) {
            case 'age':
                this.age = evt.detail.value;
                break;
            case 'grade':
                this.grade = evt.detail.value;
                break;
            case 'gender':
                this.gender = evt.detail.value;
                break;
            case 'school':
                this.school = evt.detail.value;
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
        this.gender = [];
        this.school = [];
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

        this.schoolOptions.push({
            label: 'Test School',
            value: 'Test School'
        });
    }

    formatProviders(data) {
        return data.map(provider => {
            const locationSource = provider.Job_Site__r ? 'Job_Site__r' : 'Launchpad__Account__r';
            let description = `<p><strong>Description:</strong> ${provider.Launchpad__Job_Description__c}</p>`
            let agesServed = '';
            let genderServed = '';
            let gradesServed = '';
            let schoolsServed = '';
            let programType = '';
            let interestAreas = '';

            if (provider.Ages_Served__c) {
                agesServed = this.formatMultiselectValue(provider.Ages_Served__c)
                description += `\n<p><strong>Ages Served:</strong> ${agesServed}</p>`;
            }

            if (provider.Grades_Served__c) {
                gradesServed = this.formatMultiselectValue(provider.Grades_Served__c)
                description += `\n<p><strong>Ages Served:</strong> ${gradesServed}</p>`;
            }

            if (provider.Schools_Served__c) {
                schoolsServed = this.formatMultiselectValue(provider.Schools_Served__c)
                description += `\n<p><strong>Ages Served:</strong> ${schoolsServed}</p>`;
            }

            if (provider.Gender_Served__c) {
                genderServed = this.formatMultiselectValue(provider.Gender_Served__c);
                description += `\n<p><strong>Genders Served:</strong> ${genderServed}</p>`;
            }

            if (provider.Program_Type__c) {
                programType = this.formatMultiselectValue(provider.Program_Type__c)
                description += `\n<p><strong>Program Type:</strong> ${programType}</p>`;
            }

            if (provider.Interest_Areas__c) {
                interestAreas = this.formatMultiselectValue(provider.Interest_Areas__c);
                description += `\n<p><strong>Interest Areas:</strong> ${interestAreas}</p>`;
            }
            
            return {
                id: provider.Id,
                title: provider.Name,
                agesServed,
                genderServed,
                gradesServed,
                schoolsServed,
                programType,
                interestAreas,
                richDescription: provider.Launchpad__Job_Description__c,
                location: {
                    City: provider[locationSource].BillingCity,
                    State: provider[locationSource].BillingState,
                    Street: provider[locationSource].BillingStreet,
                    PostalCode: provider[locationSource].BillingPostalCode,
                    Country: 'USA',
                },
                description
            }
        });
    }

    formatMultiselectValue(value) {
        return value.replaceAll(';', ', ');
    }
}