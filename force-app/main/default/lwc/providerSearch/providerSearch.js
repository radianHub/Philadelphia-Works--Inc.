import { LightningElement, api } from 'lwc';

export default class ProviderSearch extends LightningElement {
    @api title = 'Browse Programs';
    @api description = 'Find a program that fits your needs.';

    ageOptions = [];
    gradeOptions = [];
    genderOptions = [];

    age;
    grade;
    gender;

    connectedCallback() {
        this.getPicklistValues();
    }

    handleChange(evt) {
        console.log('handleChange', evt.target.value);
    }

    getPicklistValues() {
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
}