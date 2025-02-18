import { LightningElement, api, wire } from 'lwc';
import searchJobs from '@salesforce/apex/ProviderSearchController.searchJobs';
import getFilterOptions from '@salesforce/apex/ProviderSearchController.getFilterOptions';

// TODO: Make map modal configurable field set
// TODO: Make card fields configurable via field set
// TODO: Make Schools accounts instead of picklist
export default class ProviderSearch extends LightningElement {
    @api title;
    @api description;
    @api headerColor;
    @api cardHeaderColor;
    @api cardBodyBgColor;

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

    connectedCallback() {
    }

    @wire(getFilterOptions)
    wiredOptions({ error, data }) {
        if (data) {
            this.ageOptions = data.ages;
            this.genderOptions = data.genders;
            this.gradeOptions = data.grades;
            this.schoolOptions = data.schools;
        } else if (error) {
            console.error('getFilterOptions error', error);
        } else {
            console.log('NO DATA!');
        }
    }

    @wire(searchJobs, { zipCode: '$zipCode', age: '$age', grade: '$grade', gender: '$gender', school: '$school' })
    wiredJobs({ error, data }) {
        if (data) {
            this.providers = this.formatProviders(data);
        } else if (error) {
            console.error('searchJobs error', error);
        } else {
            console.log('NO DATA!');
        }
    }

    handleChange(evt) {
        switch (evt.target.name) {
            case 'zipcode':
                this.zipCode = evt.detail.value;
                break;
            default:
                break;
        }
    }

    handleMultiselectChange(evt) {
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

    handleClear() {
        this.zipCode = null;
        this.age = [];
        this.grade = [];
        this.gender = [];
        this.school = [];

        this.template.querySelectorAll('c-multi-select-combobox').forEach(combobox => {
            combobox.clear();
        })
    }

    formatProviders(data) {
        return data.map(provider => {
            const locationSource = provider.Placement_Site__r ? 'Placement_Site__r' : 'Launchpad__Account__r';
            let agesServed = '';
            let genderServed = '';
            let gradesServed = '';
            let schoolsServed = '';
            let programType = '';
            let interestAreas = '';
            let details = [];

            details.push({
                label: 'Address',
                value: `${provider[locationSource].BillingStreet}, ${provider[locationSource].BillingCity}, ${provider[locationSource].BillingState} ${provider[locationSource].BillingPostalCode}`
            })

            if (provider.Ages_Served__c) {
                agesServed = this.formatMultiselectValue(provider.Ages_Served__c)
                details.push({
                    label: 'Ages Served',
                    value: agesServed
                })
            }

            if (provider.Grades_Served__c) {
                gradesServed = this.formatMultiselectValue(provider.Grades_Served__c)
                details.push({
                    label: 'Grades Served',
                    value: gradesServed
                })
            }

            if (provider.Schools_Served__c) {
                schoolsServed = this.formatMultiselectValue(provider.Schools_Served__c)
                details.push({
                    label: 'Schools Served',
                    value: schoolsServed
                })
            }

            if (provider.Genders_Served__c) {
                genderServed = this.formatMultiselectValue(provider.Genders_Served__c);
                details.push({
                    label: 'Genders Served',
                    value: genderServed
                })
            }

            if (provider.Program_Type__c) {
                programType = this.formatMultiselectValue(provider.Program_Type__c)
                details.push({
                    label: 'Program Type',
                    value: programType
                })
            }

            if (provider.Interest_Areas__c) {
                interestAreas = this.formatMultiselectValue(provider.Interest_Areas__c);
                details.push({
                    label: 'Interest Areas',
                    value: interestAreas
                })
            }
            
            return {
                id: provider.Id,
                title: provider.Name,
                subtitle: provider.Launchpad__Account__r.Name,
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
                details
            }
        });
    }

    formatMultiselectValue(value) {
        return value.replaceAll(';', ', ');
    }
}