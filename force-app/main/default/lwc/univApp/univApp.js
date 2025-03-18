import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';

import signaturePanel from 'c/signaturePanel';

import getApp from '@salesforce/apex/UniversalApp.retrieveApp';
import submitSObj from '@salesforce/apex/UniversalApp.submitApp';
import getBoolFieldValue from '@salesforce/apex/UniversalApp.queryForBoolean';
import saveSignature from '@salesforce/apex/SignatureUtils.saveSignature';
import submitChildObjects from '@salesforce/apex/UniversalApp.submitChildObjects';

export default class UnivApp extends NavigationMixin(LightningElement) {
	// # PUBLIC PROPERTIES
	@api recordId;
	@api appDevName;
	@api canShowRestart;

	// # APP DATA
	appData;
	sections = {};
	fieldsetmap = {};
	page;
	sObj = {}; // sObject {attributes:{type:'API_Name__c'}}, Field_1__c: 'value'}
	originalData;
	pageUrl;
	boolResult;
	truePage;
	falsePage;
	boolObject;
	boolField;
	showSaveForLater = false;
	finished; // After submission - set fields to read-only
	_cssLoaded;
	@track files = {};

	// # PAGE DATA
	pageIndex = [];
	pageCurrent = 1;
	// * Field and Value Population per Page
	_pageFields; // [AccountId, Custom__c]
	_hasValueIndex = 0;
	_pageHasValue; // [false, true, ...] looks at sObj.hasOwnProperty('Custom__c')
	_valueIndex = 0;
	_pageValues; // [001abc..., value1, ...]

	// # SIGNATURE DATA
	sigCaptured = false;
	sigURL;
	sigData;

	// # CHILD OBJECT DATA
	childObjects = new Map();

	// # ERROR/SUCCESS MESSAGING
	alert;
	alertType;
	// Alert Messages
	REQUIRED_FIELDS = 'Required fields are missing.';
	POST_FIELDS_JSON_PARSE = 'Please contact your Salesforce Administrator. The JSON ';
	FLOW_SUCCESS = 'Successfully completed the flow.';
	FLOW_SAVED = 'Your progress has been saved.';

	loadingData = true;
	savingData = false;

	// # LIFECYCLE HOOKS

	// * ESTABLISH UNIVERSAL APP DATA
	connectedCallback() {
		this.getApp();
	}

	// * SET PAGE STYLING
	renderedCallback() {
		if (this.appData && !this._cssLoaded && this.appData.CSS__c) {
			this._cssLoaded = true;
			let styleElem = document.createElement('style');
			styleElem.innerHTML = this.appData.CSS__c;
			this.template.querySelector('.rh_style').appendChild(styleElem);
		}
	}

	// # APEX

	// * GET RECORD ID IF PASSED IN A PARAMETER
	// @wire(CurrentPageReference)
	// getStateParameters(currentPageReference) {
	// 	const urlValue = currentPageReference.state.c__recordId;
	// 	if (urlValue) {
	// 		this.recordId = urlValue;
	// 	}

	// 	console.log('recordId', this.recordId);
	// 	//  else {
	// 	// 	this.recordId = null;
	// 	// }
	// }

	getApp() {
		getApp({ appDevName: this.appDevName, recordId: this.recordId })
			.then((result) => {
				if (result.error) {
					this.alert = result.error;
					this.alertType = 'error';
				} else if (result.data) {
					this.originalData = result.data;
					let cloneData = JSON.parse(JSON.stringify(result.data));
					cloneData.sections.forEach((e) => {
						if (this.sections.hasOwnProperty(e.Page__c)) {
							this.sections[e.Page__c].push(e);
							this.sections[e.Page__c].sort((a, b) => a.Order__c - b.Order__c);
						} else {
							this.sections[e.Page__c] = [e];
						}
						this.pageIndex.push(e.Page__c);
					});
					this.pageIndex = [...new Set(this.pageIndex.sort())];
					this.pageIndex.sort(function (a, b) {
						return a - b;
					});
					this.appData = cloneData.application;
					this.boolObject = this.appData.Object_with_Boolean__c;
					this.boolField = this.appData.Boolean_Field__c;
					this.truePage = this.appData.Page_Redirect_if_True__c;
					this.falsePage = this.appData.Page_Redirect_if_False__c;
					this.showSaveForLater = this.appData.isSaveForLater__c;
					this.page = this.sections[this.pageIndex[0]];
					this.fieldsetmap = cloneData.fieldsetmap;
				}
				this.loadingData = false;
			})
			.catch((error) => {
				this.alert = JSON.stringify(error);
				this.alertType = 'error';
				this.loadingData = false;
			});
	}

	// * SUBMITS THE RECORD AND CALLS A PAGE REDIRECT BASED ON A RETURNED BOOLEAN VALUE
	submitSObj(isSaveForLater) {
		this.savingData = true;

		let urlRecordId;

		if (!isSaveForLater) {
			this.finished = true;
		}

		let filesToInsert = [];

		for (const fieldApiName of Object.keys(this.files)) {
			this.sObj[fieldApiName] = true;
			filesToInsert.push(...this.files[fieldApiName]);
		}

		submitSObj({
			sObj: this.sObj,
			application: this.appDevName,
			filesString: JSON.stringify(filesToInsert),
			isSaveForLater: isSaveForLater
		})
			.then((result) => {
				if (result.data) {
					if (isSaveForLater) {
						this.alert = this.FLOW_SAVED;
					} else {
						this.alert = this.FLOW_SUCCESS;
					}
					this.alertType = 'success';
					urlRecordId = result.data;
					if (this.sigCaptured) {
						saveSignature({ relatedId: urlRecordId, data: [this.sigData] });
					}

					if (this.childObjects.size > 0) {
						let childObjs = [];
						this.childObjects.forEach((value, key) => {
							let obj = {
								objectName: key,
								parentField: value.get('parentField'),
								records: value.get('records'),
							};
							childObjs.push(obj);
						});
						// * SAVE CHILD OBJECTS
						submitChildObjects({ childObjs: childObjs, parentId: result.data })
							.then((childResult) => {})
							.catch((err) => {
								this.alert = JSON.stringify(err);
								this.alertType = 'error';
							});
					}

					if (this.boolField != null && this.boolObject != null) {
						getBoolFieldValue({
							fieldName: this.boolField,
							objName: this.boolObject,
							recordId: urlRecordId,
						})
							.then((result) => {
								this.boolResult = result[this.boolField];
								if (this.boolResult && this.truePage != null) {
									this.appData.vfPageRedirect__c
										? this.lwcRedirect(this.truePage)
										: this.lwcCommPageRedirect(this.truePage);
								} else if (!this.boolResult && this.falsePage != null) {
									this.appData.vfPageRedirect__c
										? this.lwcRedirect(this.falsePage)
										: this.lwcCommPageRedirect(this.falsePage);
								}
							})
							.catch((error) => {
								this.alert = JSON.stringify(error);
								this.alertType = 'error';
							});
					} else if (this.appData.Page_Redirect__c != null) {
						this.appData.vfPageRedirect__c
							? this.lwcRedirect(this.appData.Page_Redirect__c)
							: this.lwcCommPageRedirect(this.appData.Page_Redirect__c);
					}
					this.savingData = false;

					if (!isSaveForLater) {
						window.location.reload();
					}

				} else if (result.error) {
					this.finished = false;
					this.alert = result.error;
					this.alertType = 'error';
					this.savingData = false;
				}
			})
			.catch((error) => {
				this.finished = false;
				this.alert = JSON.stringify(error);
				this.alertType = 'error';
			})
			.finally(() => this.clearPagePopulation());
	}

	// # PRIVATE METHODS

	// * REDIRECTS TO DIFFERENT APP/VF_PAGE
	lwcRedirect(/*recordId, */ vfPage) {
		this.pageUrl = window.location.origin + '/apex/' + vfPage /*+ '?id=' + recordId*/;
		window.location.assign(this.pageUrl);
	}

	// * REDIRECTS TO DIFFERENT APP/COMMUNITY_PAGE
	lwcCommPageRedirect(commPage) {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				name: commPage,
			},
		});
	}

	// * PREPARES PROPERTIES FOR UPCOMING VALUES
	clearPagePopulation() {
		this._pageFields = null;
		this._hasValueIndex = 0;
		this._pageHasValue = null;
		this._valueIndex = 0;
		this._pageValues = null;
	}

	// * PREPARES THE UPCOMING PAGE
	async setPage() {
		this.clearPagePopulation();
		this.page = this.sections[this.pageIndex[this.pageCurrent - 1]];

		// Need to manually trigger dynamicRequire event for formula fields
		await Promise.resolve();
		const inputs = this.template.querySelectorAll('lightning-input-field');
		inputs.forEach((el) => {
			if (el.fieldName === 'Applicant_s_Age_at_Start_of_Program__c' && el.value) {
				this.dynamicRequire({ target: el });
			}
		})
	}

	// * POPULATES THE PAGE PROPERTIES
	populateProperties() {
		this._pageFields = this.currentPage.reduce((prev, cur) => {
			if (cur.rows) {
				prev.push(
					...cur.rows.reduce((p, c) => {
						p.push(...c.fields.map((f) => f.api));
						return p;
					}, [])
				);
			}
			return prev;
		}, []);
	}

	// * POPULATES THE PAGE VALUES
	populateValues() {
		this._valueIndex = 0;
		if (!this._pageFields) {
			this.populateFieldNames();
		}
		this._pageValues = this._pageFields.filter((f) => this.sObj.hasOwnProperty(f)).map((e) => this.sObj[e]);
	}

	// * CHECKS FIELD VALIDATION AND SETS THE SOBJ PROPERTY FOR INSERT
	validateFields(alert, alertType) {
		let isValid = [...this.template.querySelectorAll('lightning-input-field')].reduce((validSoFar, inp) => {
			let valid = inp.reportValidity();

			return validSoFar && valid;
		}, true);

		if (!isValid && alert) {
			this.alert = alert;
			this.alertType = alertType;
		}

		return isValid;
	}

	setObjectFields() {
		this.template.querySelectorAll('lightning-input-field').forEach((e) => {
			this.sObj[e.fieldName] = e.value;
		});
	}

	// * DYNAMICALLY RENDERS A FIELD BASED ON ANOTHER FIELDS VALUE
	dynamicRequire(event) {
		const cField = event.target.fieldName;
		const cValue = event.target.value.toString();

		let oIndex;
		let cRequire = {};
		let fieldToRequire = [];
		let fieldToUnrequire = [];
		let fieldIndex = null;
		let fieldSetMap = this.fieldsetmap;
		let keys = Object.keys(fieldSetMap);
		let fieldData;
		let requireFieldMap = new Map();
		let unrequireFieldMap = new Map();

		this.page.forEach((e) => {
			if ('conditionalRequire__c' in e) {
				oIndex = e.Order__c - 1;
				let cJson = JSON.parse(e.conditionalRequire__c);
				cRequire[oIndex] = cJson;
			}
		});

		for (let key in cRequire) {
			if (Object.prototype.hasOwnProperty.call(cRequire, key)) {
				// eslint-disable-next-line no-loop-func
				keys.forEach((fieldSet) => {
					if (fieldSet === this.page[key].Section_Field_Set__c) {
						cRequire[key].Fields.forEach((e) => {
							if (
								cField == e.controllingField &&
								e.controllingValues.includes(cValue) &&
								!e.controllingValues.includes('require')
							) {
								fieldToRequire.push(e.api);
							} else if (
								cField == e.controllingField &&
								e.controllingValues.includes('require') &&
								cValue != ''
							) {
								fieldToRequire.push(e.api);
							}
							if (
								cField == e.controllingField &&
								!e.controllingValues.includes(cValue) &&
								!e.controllingValues.includes('require')
							) {
								fieldToUnrequire.push(e.api);
							} else if (
								cField == e.controllingField &&
								e.controllingValues.includes('require') &&
								cValue == ''
							) {
								fieldToUnrequire.push(e.api);
							}
						});
						fieldSetMap[fieldSet].forEach((section) => {
							if (fieldToRequire.length > 0) {
								fieldToRequire.forEach((actionField) => {
									if (actionField === section.api) {
										fieldIndex = fieldSetMap[fieldSet].indexOf(section);
										fieldData = fieldSetMap[fieldSet][fieldIndex];
										requireFieldMap.set(actionField, fieldData);
									}
								});
							}
							if (fieldToUnrequire.length > 0) {
								fieldToUnrequire.forEach((actionField) => {
									if (actionField === section.api) {
										fieldIndex = fieldSetMap[fieldSet].indexOf(section);
										fieldData = fieldSetMap[fieldSet][fieldIndex];
										unrequireFieldMap.set(actionField, fieldData);
									}
								});
							}
						});
					}
				});
			}
		}

		if (fieldToRequire.length > 0) {
			requireFieldMap.forEach((e) => {
				e.req = true;
			});
		}

		if (fieldToUnrequire.length > 0) {
			unrequireFieldMap.forEach((e) => {
				e.req = false;
			});
		}
	}

	// * DYNAMICALLY RENDERS AN APP SECTION BASED ON A FIELDS VALUE
	dynamicRender(event) {
		const field = event.target.fieldName;
		const value = event.target.value;

		let cRender = [];
		let sectionRender = [];
		let sectionUnrender = [];

		this.page.forEach((e) => {
			if ('conditionalRender__c' in e) {
				let cJson = JSON.parse(e.conditionalRender__c);
				cRender.push(cJson);
			}
		});

		cRender.forEach((e) => {
			e.Fields.forEach((cf) => {
				if (field === cf.controllingField && value === cf.controllingValue) {
					cf.actionSections.forEach((aS) => {
						sectionRender.push(aS);
					});
				}
				if (field === cf.controllingField && value !== cf.controllingValue) {
					cf.actionSections.forEach((aS) => {
						sectionUnrender.push(aS);
					});
				}
			});
		});

		if (sectionRender.length > 0) {
			sectionRender.forEach((s) => {
				this.page.forEach((p) => {
					if (p.DeveloperName === s) {
						p.DisplayByDefault__c = true;
					}
				});
			});
		}
		if (sectionUnrender.length > 0) {
			sectionUnrender.forEach((s) => {
				this.page.forEach((p) => {
					if (p.DeveloperName === s) {
						p.DisplayByDefault__c = false;
					}
				});
			});
		}
	}

	// # HANDLERS

	// * HANDLES A CUSTOM ALERT EVENT
	handleAlert(event) {
		this.alert = event.detail.alert;
		this.alertType = event.detail.alertType;
	}

	// * BUILDS A MAP OF CHILD OBJECT RECORDS
	updateChild(e) {
		const objName = e.detail.objectName;
		const parentField = e.detail.parentField;
		const data = e.detail.records;

		const childDataMap = new Map();
		childDataMap.set('parentField', parentField);
		childDataMap.set('records', data);

		if (data.length > 0) {
			this.childObjects.set(objName, childDataMap);
		} else {
			if (this.childObjects.get(objName)) {
				this.childObjects.remove(objName);
			}
		}
	}

	// * OPENS A SIGNATURE PANEL
	async clickSignatureButton() {
		const r = await signaturePanel.open({
			label: 'Applicant Signature',
			size: 'small',
		});
		if (r) {
			this.sigCaptured = r.signed;
			this.sigURL = r.signatureData.imgURL;
			this.sigData = r.signatureData.imgData;
		}
	}

	// * HANDLES THE DYNAMIC RENDERING AND REQUIRE OF FIELDS
	onChangeHandler(event) {
		this.setPage();
		this.dynamicRender(event);
		this.dynamicRequire(event);
	}

	// * RESETS THE APP
	restart() {
		this.pageCurrent = 1;
		this.setPage();
		this.alert = '';
		this.finished = false;
	}

	// * GOES TO THE PREVIOUS PAGE
	previous() {
		if (!this.finished) {
			this.alert = '';
		}
		this.setObjectFields();
		this.pageCurrent--;
		this.setPage();
	}

	handleSubmit(evt) {
		this.alert = '';

		evt.preventDefault();
		const fields = evt.detail.fields;
		this.template.querySelector('lightning-record-edit-form').submit(fields);
	}

	handleSuccess() {
		this.next();
	}

	handleError() {
		this.alert = 'Please fix all fields with errors.';
		this.alertType = 'error';
	}

	// * GOES TO THE NEXT PAGE
	next() {
		if (!this.finished) {
			this.alert = '';
		}
		this.setObjectFields();

		if (this.validateFields(this.REQUIRED_FIELDS, 'error')) {
			this.pageCurrent++;
			this.setPage();
		} else {
			this.setPage();
		}
	}

	saveForLater() {
		this.finish(true);
	}

	submit() {
		this.finish(false);
	}

	// * SETS THE RECORD ID IF AVAILABLE AND HANDLES THE SUBMISSION OF THE RECORD
	finish(isSaveForLater) {
		this.alert = '';
		this.setObjectFields();
		if (this.validateFields(this.REQUIRED_FIELDS, 'error')) {
			//this.canShowRestart = true;
			if (this.appData.Post_Submit_Fields__c) {
				let fieldsJSON;
				try {
					fieldsJSON = JSON.parse(this.appData.Post_Submit_Fields__c);
					Object.keys(fieldsJSON).forEach((field) => (this.sObj[field] = fieldsJSON[field]));
				} catch (error) {
					this.alert = error.toString();
					this.alertType = 'error';
				}
			}
			if (!this.alert) {
				this.sObj['sobjectType'] = this.appData.Object__c;
				if (this.recordId) {
					this.sObj['Id'] = this.recordId;
				}

				this.submitSObj(isSaveForLater);
			}
		}
	}

	// * ADDES THE UPLOADED FILES TO THE UPLOAD OBJECT BEFORE FORM SUBMISSION
	handleSelectFile(event) {
		const apiName = event.detail.fieldApiName;
		const fieldLabel = event.detail.fieldLabel;
		const files = event.detail.files;

		let fieldFiles = this.files[apiName];

		if (fieldFiles === undefined) {
			this.files[apiName] = [];
		}

		for (const file of files) {
			let reader = new FileReader();
			let base64;
			let filename = fieldLabel + ' - ' + file.name;

			reader.onload = () => {
				base64 = reader.result.split(',')[1];
				let obj = { ...this.files };

				obj[apiName].push({ filename: filename, base64: base64 });
				this.files = obj;
			};
			reader.readAsDataURL(file);
		}
	}

	// * REMOVES PREVIOUSLY SELECTED FILES FROM THE FILES OBJECT
	handleRemoveFile(event) {
		const apiName = event.detail.fieldApiName;
		delete this.files[apiName];
	}

	// # GETTERS/SETTERS

	// * DETERMINES WETHER OR NOT TO SHOW RESTART IF APPLICABLE
	get showRestart() {
		return this.canShowRestart && this.finished;
	}

	// * DISABLES THE FINISH BUTTON IF A SIGNATURE IS PRESENT AND NOT CAPTURED
	get disableFinish() {
		if (this.showSignature) {
			if (!this.finished) {
				return !this.sigCaptured;
			}
			return this.finished;
		}
		return this.finished;
	}

	// * DISABLES THE SIGNATURE BUTTON IF ONE HAS BEEN CAPTURED
	get disableSignature() {
		return this.showSignature && this.sigCaptured;
	}

	// * SHOWS THE SIGNATURE BUTTON
	get showSignature() {
		return this.currentPage.find((sec) => sec.data.Include_Signature__c);
	}

	// * DETERMINES WETHER OR NOT TO SHOW THE PREVIOUS BUTTON
	get showPrevious() {
		return this.pageCurrent > 1;
	}

	// * DETERMINES WETHER OR NOT TO SHOW THE NEXT BUTTON
	get showNext() {
		return this.pageCurrent < this.pageTotal;
	}

	// * DETERMINES WETHER OR NOT TO SHOW THE FINISH BUTTON
	get showFinish() {
		return this.pageTotal === 1 ? true : this.pageCurrent == this.pageTotal && this.pageTotal > 1;
	}

	// * SETS THE ALERT BANNER COLOR
	get alertClass() {
		return (
			'rh_alert-div slds-scoped-notification slds-media slds-media_center slds-m-bottom_small slds-theme_' +
			this.alertType
		);
	}

	// * SETS THE ALERT CONTAINER
	get alertSpan() {
		return 'slds-icon_container slds-icon-utility-' + this.alertType;
	}

	// * SETS THE ALERT ICON
	get alertIcon() {
		return 'utility:' + this.alertType;
	}

	// * RETURNS THE TOTAL NUMBER OF PAGES
	get pageTotal() {
		return this.pageIndex.length;
	}

	// * DETERMINES IF THE APP IS MORE THAN 1 PAGE
	get multiplePages() {
		return this.pageIndex.length > 1;
	}

	// * RETURNS A FIELDS VALUE
	get value() {
		if (!this._pageValues) {
			this.populateValues();
		}
		return this._pageValues[this._valueIndex++];
	}

	// * DETERMINES IF A FIELD HAS A VALUES
	get hasValue() {
		if (!this._pageFields) {
			this.populateProperties();
		}
		// Handle both true and false calls (twice per field)
		return this.sObj.hasOwnProperty(this._pageFields[Math.floor(this._hasValueIndex++ / 2)]);
	}

	// * RETURNS THE CURRENT PAGE
	/**
	 * Current page getter
	 * @yields {Array} - Structured objects for LWC HTML iteration
	 * ________________________________
	 *
	 * data: {section custom meta data},
	 * rows: [{
	 *      id: 123,
	 *      fields : [{
	 *          api: AccountId,
	 *          req: true (Boolean),
	 *          label: Contact,
	 *          type: ID (Schema.DisplayType)
	 *          value: Field Value
	 *      }]
	 * }]
	 */
	get currentPage() {
		let curPage = [];
		if (this.page) {
			curPage = [
				...this.page.map((s) => {
					let sect = { data: s };
					// if (!s.DisplayByDefault__c) {
					// 	sect.display = "display:none";
					// }
					if (s.Section_Field_Set__c) {
						sect.columnClass =
							'field-div slds-col slds-size_1-of-1 slds-medium-size_1-of-' +
							s.Section_Field_Columns__c +
							' ' +
							s.DeveloperName;
						let cols = parseInt(s.Section_Field_Columns__c, 10);
						let directionRows = s.Section_Field_Flow__c == 'Left Right';
						let fieldArray = this.fieldsetmap[s.Section_Field_Set__c];
						let rows = Math.ceil(fieldArray.length / cols);
						let fieldRows = []; // {id:iterRow, fields:[{field}, {from}, {fieldArray}]}
						for (let i = 0; i < rows; i++) {
							// Handle left to right (rows) scenario
							if (directionRows) {
								let startIndex = i * cols;
								let endIndex = (i + 1) * cols;
								fieldRows.push({
									id: i,
									fields: fieldArray.slice(startIndex, endIndex),
								});
								// Handle top down (columns) scenario
							} else {
								let fieldSlice = [];
								for (let j = 0; j < cols; j++) {
									let rcIndex = i + j * rows;
									if (rcIndex < fieldArray.length) {
										fieldSlice.push(fieldArray[rcIndex]);
									}
								}
								fieldRows.push({
									id: i,
									fields: fieldSlice,
								});
							}
						}
						sect.rows = fieldRows;
					}
					return sect;
				}),
			];
		}
		return curPage;
	}

	// * DISPLAYS LOADING SPINNER
	get isLoading() {
		if (this.loadingData || this.savingData) {
			return true;
		}
		return false;
	}
}