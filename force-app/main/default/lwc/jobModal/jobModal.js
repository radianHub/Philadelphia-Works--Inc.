/**
 * Created by holden on 3/20/25.
 */

import { api } from 'lwc';
import LightningModal from "lightning/modal";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getFieldSetData from '@salesforce/apex/ProviderSearchController.getJobFieldSetMembers';
import getJob from '@salesforce/apex/ProviderJobsController.getJob';
import updateJob from '@salesforce/apex/ProviderJobsController.updateJob';

export default class JobModal extends LightningModal {

    @api recordId;
    @api jobName;
    @api fieldSet;
    @api isEditMode;
    isLoading = true;
    fieldData;
    multiselectFieldValuesMap = {};
    job;

    async connectedCallback() {
        try {
            this.job = await getJob({ jobId: this.recordId, fieldSetName: this.fieldSet });
            let fieldData = await getFieldSetData({ fieldSetName: this.fieldSet })
            if (this.isEditMode) {
                for (const data of fieldData) {
                    if (data.isMultiselect) {
                        let fieldValues = this.job[data.apiName];
                        if (fieldValues) {
                            this.multiselectFieldValuesMap[data.apiName] = fieldValues;
                            fieldValues = fieldValues.split(';');
                            for (const option of data.options) {
                                if (fieldValues.includes(option.value)) {
                                    option.selected = true;
                                }
                            }
                        } else {
                            this.multiselectFieldValuesMap[data.apiName] = "";
                        }
                    }
                }
            } else {
                for (const data of fieldData) {
                    data.label = data.label
                        .replace('Job Order', 'Program')
                        .replace('Job', 'Program');
                    if (data.label === 'Contact') data.label = 'Main Supervisor Name';
                    if (data.type === 'TEXTAREA') data.isTextarea = true;
                    if (data.type === 'REFERENCE' && this.job[data.apiName]) {
                        const lookupReferenceApiName = data.apiName.replace('__c', '__r');
                        data.value = this.job[lookupReferenceApiName].Name;
                    } else {
                        data.value = this.job[data.apiName];
                    }
                }
            }
            this.fieldData = fieldData;
        } catch (e) {
            console.log('JOB_MODAL_CONNECTED_CALLBACK_ERROR', e);
        } finally {
            this.isLoading = false;
        }
    }

    handleMultiselectChange(e) {
        const value = e.detail.value;
        this.multiselectFieldValuesMap[e.target.name] = value.join(';');
    }

    handleChange(e) {
        this.job[e.target.name] = e.detail.value;
    }

    handleClose() {
        this.close();
    }

    handleSave() {
        this.isLoading = true;
        console.log(JSON.stringify(this.multiselectFieldValuesMap))
        const fields = {
            SobjectName: 'Launchpad__Job__c',
            ...this.job
        }
        for (const field of Object.keys(this.multiselectFieldValuesMap)) {
            const fieldValue = this.multiselectFieldValuesMap[field];
            fields[field] = (fieldValue ? fieldValue : null);
        }
        updateJob({ job: fields })
            .then((response) => {
                if (response.hasOwnProperty('success')) {
                    this.showToast('Success!', response.success, 'success');
                    this.close();
                } else {
                    this.showToast('Error', response.error, 'error');
                }
            })
            .catch(e => { console.log('UPDATE_JOB_ERROR', e.message) })
            .finally(() => { this.isLoading = false; });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }

}