// RadianHub - Developer p.hart
// Apex class for a LWC based universal application dependent on  custom metadata and object field sets

public with sharing class UniversalApp {
	public final static String NOT_FOUND = 'Application \'DeveloperName\' not found in Custom Metadata.';
	public final static String NO_SECTION = 'Application sections were not found in Custom Metadata.';
	public final static String NO_FIELDSETS = 'Field sets were not found for object: {0}.';
	public final static String NULL_FIELDSETS = 'The field set(s) were not found for the following Universal App Sections: {0}.';
	public final static String NULL_FIELDSET = 'The field set {0} was not found on {1}.';

	public static Universal_App__mdt[] apps;
	public static Universal_App_Section__mdt[] sections;

	// Method   - queryApps
	// Descr.   - Segregated (for testing) mdt query which updates the class static variable "apps"
	// Input    - String DeveloperName of CustomMetadata 'Universal App'
	private static void queryApps(String appDevName) {
		apps = [
			SELECT
				Id,
				CSS__c,
				DeveloperName,
				Logo_URL__c,
				MasterLabel,
				Object__c,
				Post_Submit_Fields__c,
				Page_Redirect__c,
				Object_with_Boolean__c,
				Boolean_Field__c,
				Page_Redirect_if_True__c,
				Page_Redirect_if_False__c,
				vfPageRedirect__c,
				isSaveForLater__c
			FROM Universal_App__mdt
			WHERE DeveloperName = :appDevName
		];
	}

	// Method   - querySections
	// Descr.   - Segregated (for testing) mdt query which updates the class static variable "sections"
	// Input    - Id of 'Universal App'
	private static void querySections(String appId) {
		// sections = [
		//  SELECT
		//      Id,
		//      DeveloperName,
		//      MasterLabel,
		//      Order__c,
		//      Page__c,
		//      Section_Body__c,
		//      Section_Field_Set__c,
		//      Section_Field_Columns__c,
		//      Section_Field_Flow__c,
		//      Section_Header__c,
		//      conditionalRequire__c,
		//      conditionalRender__c,
		//      DisplayByDefault__c,
		//      AddChildButtonLabel__c,
		//      ChildFieldSet__c,
		//      ChildObject__c,
		//      ChildObjectRecordLimit__c,
		//      ChildTableTitle__c,
		//      ParentField__c,
		//      isEnableChildRecords__c,
		//      Include_Signature__c
		//  FROM Universal_App_Section__mdt
		//  WHERE Universal_App__c = :appId
		// ];

		sections = Universal_App_Section__mdt.getAll().values();
	}

	/**
	 * @description : QUERIES FOR A LIST OF FIELD SETTINGS TO BE USED AS ALTERNATIVE LABELS.
	 * @author Zachary Csotya | 08/31/2023
	 * @return List<Universal_App_Field_Setting__mdt>
	 **/
	private static List<Universal_App_Field_Setting__mdt> queryFieldSettings() {
		return [
			SELECT
				Id,
				DeveloperName,
				MasterLabel,
				Expected_Field_Label__c,
				Field_Name__c,
				Universal_App_Section__c,
				Type__c,
				Accepted_File_Types__c,
				Allow_Multiple_Files__c,
				Maximum_Number_of_Files__c,
				URL__c,
				Target__c
			FROM Universal_App_Field_Setting__mdt
		];
	}

	/**
	 * @description : Query all fields in a sObject and return the results.
	 * @author Zachary Csotya | 06/28/2022
	 * @param Id rId
	 * @param String objName
	 * @return sObject
	 **/
	public static sObject queryRecord(Id rId, String objName) {
		Map<String, Schema.SObjectField> fields = ((SObject) Type.forName('Schema', objName)?.newInstance())
			?.getSObjectType()
			?.getDescribe()
			?.fields
			?.getMap();

		String expr = ' ';
		SObject obj = null;
		for (Integer i = 0; i < fields.values().size() - 1; i++) {
			expr += fields.values()[i] + ', ';
		}
		expr += fields.values()[fields.values().size() - 1];
		String qry = 'SELECT' + expr + ' FROM ' + objName + ' WHERE Id = ' + '\'' + rId + '\'';
		obj = Database.query(qry);

		return obj;
	}

	/**
	 * @description : Query all fields in a sObject and return the results.
	 * @author Zachary Csotya | 08/02/2022
	 * @param String fieldName
	 * @param String objName
	 * @param String recordId
	 * @return sObject
	 **/
	@AuraEnabled
	public static sObject queryForBoolean(String fieldName, String objName, String recordId) {
		List<SObject> obj = null;
		String qry = 'SELECT ' + fieldName + ' FROM ' + objName + ' WHERE Id = ' + '\'' + recordId + '\'';
		obj = Database.query(qry);

		if (obj.size() == 1) {
			return obj[0];
		} else {
			return null;
		}
	}

	// Method   - retrieveApp
	// Descr.   - Aura enabled (LWC c-univ-app) method for returning map of Universal Application and field sets
	// Input    - String DeveloperName of CustomMetadata 'Universal App'
	// Output   - Map<String, Object> {'data' -> [{api -> fieldAPI__c, options...}, ...], 'error' -> 'String'}
	@AuraEnabled(cacheable=true)
	public static Map<String, Object> retrieveApp(String appDevName, Id recordId) {
		Map<String, Object> ret = new Map<String, Object>();

		try {
			// Query for application, prepopulate in testing
			if (apps == null) {
				queryApps(appDevName);
			}

			if (apps == null || apps.size() != 1) {
				ret.put('error', NOT_FOUND);
			} else {
				Universal_App__mdt application = apps[0];

				// Query for sections, prepopulate in testing
				if (sections == null) {
					querySections(application.Id);
				}

				List<Universal_App_Section__mdt> uasections = Universal_App_Section__mdt.getAll().values();

				if (sections == null || sections.size() == 0) {
					ret.put('error', NO_SECTION);
				} else {
					Map<String, List<Object>> fieldsetmap = new Map<String, List<Object>>();

					Map<String, Schema.FieldSet> objectFieldSetMap = ((SObject) Type.forName(
								'Schema',
								application.Object__c
							)
							?.newInstance())
						?.getSObjectType()
						?.getDescribe()
						?.fieldSets
						?.getMap();

					if (objectFieldSetMap == null) {
						ret.put('error', String.format(NO_FIELDSETS, new List<Object>{ application.Object__c }));
					} else {
						Map<String, Set<String>> mapfieldset = new Map<String, Set<String>>();
						Map<String, Map<String, Universal_App_Field_Setting__mdt>> mapFieldSetting = new Map<String, Map<String, Universal_App_Field_Setting__mdt>>();

						for (Universal_App_Section__mdt section : sections) {
							String sectionFieldSet = section.Section_Field_Set__c;
							if (String.isNotBlank(sectionFieldSet)) {
								for (Universal_App_Field_Setting__mdt fieldSetting : queryFieldSettings()) {
									if (fieldSetting.Universal_App_Section__c == section.Id) {
										if (mapFieldSetting.containsKey(sectionFieldSet)) {
											if (
												!mapFieldSetting.get(sectionFieldSet)
													.containsKey(fieldSetting.Field_Name__c)
											) {
												mapFieldSetting.get(sectionFieldSet)
													.put(fieldSetting.Field_Name__c, fieldSetting);
											}
										} else {
											mapFieldSetting.put(
												sectionFieldSet,
												new Map<String, Universal_App_Field_Setting__mdt>{
													fieldSetting.Field_Name__c => fieldSetting
												}
											);
										}
									}
								}
								if (mapfieldset.containsKey(sectionFieldSet)) {
									mapfieldset.get(sectionFieldSet).add(section.DeveloperName);
								} else {
									mapfieldset.put(sectionFieldSet, new Set<String>{ section.DeveloperName });
								}
							}
						}

						Set<String> nullFieldSets = new Set<String>();
						sObject fieldValues = null;

						if (recordId != null) {
							fieldValues = queryRecord(recordId, application.Object__c);
						}

						for (String fieldSet : mapfieldset.keySet()) {
							Schema.FieldSet objFieldSet = objectFieldSetMap.get(fieldSet);
							if (objFieldSet != null) {
								List<Schema.FieldSetMember> fields = objFieldSet.getFields();
								List<Object> fieldMembers = new List<Object>();
								for (Schema.FieldSetMember member : fields) {
									String altLabel;
									Boolean hasAltLabel = false;
									Boolean isFile = false;
									Boolean allowMultiple = false;
									Integer maxFiles = 1;
									String acceptedFileTypes = '';
									Boolean isLink = false;
									String linkURL = '';
									String linkTarget = '_blank';

									if (mapFieldSetting?.containsKey(fieldSet)) {
										if (mapFieldSetting.get(fieldSet)?.containsKey(member.getFieldPath())) {
											Universal_App_Field_Setting__mdt fieldSetting = mapFieldSetting.get(
													fieldSet
												)
												.get(member.getFieldPath());

											hasAltLabel = true;
											altLabel = fieldSetting.Expected_Field_Label__c;
											isFile = fieldSetting.Type__c == 'File' ? true : false;
											allowMultiple = fieldSetting.Allow_Multiple_Files__c;
											maxFiles = (Integer) fieldSetting.Maximum_Number_of_Files__c;
											isLink = fieldSetting.Type__c == 'Link' ? true : false;
											acceptedFileTypes = fieldsetting.Accepted_File_Types__c;
											linkURL = fieldSetting.URL__c;
											linkTarget = fieldSetting.Target__c;
										}
									}

									Map<String, Object> fieldMember = new Map<String, Object>{
										'api' => member.getFieldPath(),
										'req' => (member.getDBRequired() || member.getRequired()),
										'label' => member.getLabel(),
										'type' => member.getType().name(),
										'hasAltLabel' => hasAltLabel,
										'altLabel' => altLabel,
										'isBool' => member.getType().name() == 'BOOLEAN' ? true : false,
										'isFile' => isFile,
										'allowMultiple' => allowMultiple,
										'maxFiles' => maxFiles,
										'acceptedFileTypes' => acceptedFileTypes,
										'isLink' => isLink,
										'linkURL' => linkURL,
										'linkTarget' => linkTarget
									};

									if (recordId != null) {
										fieldMember.put('value', fieldValues.get(member.getFieldPath()));
									}
									fieldMembers.add(fieldMember);
								}
								fieldsetmap.put(fieldSet, fieldMembers);
							} else {
								nullFieldSets.addAll(new List<String>(mapfieldset.get(fieldSet)));
							}
						}

						if (nullFieldSets.size() > 0) {
							ret.put('error', String.format(NULL_FIELDSETS, new List<Object>{ nullFieldSets }));
						}

						ret.put(
							'data',
							new Map<String, Object>{
								'application' => application,
								'sections' => sections,
								'fieldsetmap' => fieldsetmap
							}
						);
					}
				}
			}
		} catch (Exception e) {
			ret.put('error', e.getTypeName() + ' | ' + e.getMessage() + ' | ' + e.getStackTraceString());
		}

		return ret;
	}

	public static void updateOtherAppsInSameSession(Id appId) {
		Launchpad__Applicant_Tracking__c currentApp = [
			SELECT
				Id,
				Program__c,
				Launchpad__Participant__c,
				Applicant_s_Street_Address__c,
				Applicant_s_Email_Address__c,
				Applicant_City__c,
				Applicant_s_State__c,
				Applicant_s_Zip_Code__c,
				Applicant_s_Phone_Number__c,
				Applicant_s_Date_of_Birth_MM_DD_YYYY__c,
				Applicants_Tax_Id__c,
				Applicant_s_Country_of_Nationality__c,
				Applicant_s_Primary_Language__c,
				Applicant_s_Preferred_Name__c,
				Guardian_Name__c,
				Relationship_to_this_Young_Person__c,
				Guardian_Phone_Number__c,
				Guardian_Email__c,
				Emergency_Contact_First_Name__c,
				Emergency_Contact_Last_Name__c,
				Emergency_Contact_Email__c,
				Emergency_Contact_Phone__c,
				Emergency_Contact_Relationship__c,
				Applicant_s_Sex_Assigned_at_Birth__c,
				Applicant_s_Current_Gender__c,
				Applicant_s_Preferred_Pronoun__c,
				Race_and_or_Ethnicity__c,
				Applicant_s_Last_Completed_Grade__c,
				Applicant_s_Current_Most_Recent_School__c,
				Applicant_s_Current_Employment_Status__c,
				Is_this_Youth_TANF_Eligible__c,
				Current_Living_Situation__c,
				Applicant_s_Internet_Connectivity__c,
				Applicant_Medical_Conditions__c,
				Applicant_Mental_Health_Diagnosis__c,
				Applicant_Mental_Disability_Diagnosis__c,
				Applicant_Deaf_Difficulty_Hearing__c,
				Applicant_Blind_Difficulty_Seeing__c,
				Applicant_Involved_in_Justice_System__c,
				Applicant_Need_Support_Assistance__c,
				Income_Attestation__c,
				Wages_from_Employment__c,
				Income_from_operation_of_a_business__c,
				Interest_in_dividends_from_assets__c,
				Social_Security_or_Other_Payments__c,
				Unemployment_or_disability_payments__c,
				Public_assistance_payments__c,
				Any_other_source_not_named_above__c,
				Explanation_of_Attestations__c,
				Willing_to_accept_an_unselected_program__c,
				Media_Picture_Release__c,
				Parent_s_Consent__c,
				Release_of_Information__c,
				Consent_to_Request_Clearance__c
			FROM Launchpad__Applicant_Tracking__c
			WHERE Id = :appId
			LIMIT 1
		];

		List<Launchpad__Applicant_Tracking__c> relatedApps = [
			SELECT
				Id,
				Program__c,
				Launchpad__Participant__c,
				Applicant_s_Street_Address__c,
				Applicant_s_Email_Address__c,
				Applicant_City__c,
				Applicant_s_State__c,
				Applicant_s_Zip_Code__c,
				Applicant_s_Phone_Number__c,
				Applicant_s_Date_of_Birth_MM_DD_YYYY__c,
				Applicants_Tax_Id__c,
				Applicant_s_Country_of_Nationality__c,
				Applicant_s_Primary_Language__c,
				Applicant_s_Preferred_Name__c,
				Guardian_Name__c,
				Relationship_to_this_Young_Person__c,
				Guardian_Phone_Number__c,
				Guardian_Email__c,
				Emergency_Contact_First_Name__c,
				Emergency_Contact_Last_Name__c,
				Emergency_Contact_Email__c,
				Emergency_Contact_Phone__c,
				Emergency_Contact_Relationship__c,
				Applicant_s_Sex_Assigned_at_Birth__c,
				Applicant_s_Current_Gender__c,
				Applicant_s_Preferred_Pronoun__c,
				Race_and_or_Ethnicity__c,
				Applicant_s_Last_Completed_Grade__c,
				Applicant_s_Current_Most_Recent_School__c,
				Applicant_s_Current_Employment_Status__c,
				Is_this_Youth_TANF_Eligible__c,
				Current_Living_Situation__c,
				Applicant_s_Internet_Connectivity__c,
				Applicant_Medical_Conditions__c,
				Applicant_Mental_Health_Diagnosis__c,
				Applicant_Mental_Disability_Diagnosis__c,
				Applicant_Deaf_Difficulty_Hearing__c,
				Applicant_Blind_Difficulty_Seeing__c,
				Applicant_Involved_in_Justice_System__c,
				Applicant_Need_Support_Assistance__c,
				Income_Attestation__c,
				Wages_from_Employment__c,
				Income_from_operation_of_a_business__c,
				Interest_in_dividends_from_assets__c,
				Social_Security_or_Other_Payments__c,
				Unemployment_or_disability_payments__c,
				Public_assistance_payments__c,
				Any_other_source_not_named_above__c,
				Explanation_of_Attestations__c,
				Willing_to_accept_an_unselected_program__c,
				Media_Picture_Release__c,
				Parent_s_Consent__c,
				Release_of_Information__c,
				Consent_to_Request_Clearance__c
			FROM Launchpad__Applicant_Tracking__c
			WHERE
				Program__c = :currentApp.Program__c
				AND Launchpad__Participant__c = :currentApp.Launchpad__Participant__c
		];

		List<Launchpad__Applicant_Tracking__c> appsToUpdate = new List<Launchpad__Applicant_Tracking__c>();

		for (Launchpad__Applicant_Tracking__c app : relatedApps) {
			app.Applicant_s_Street_Address__c = currentApp.Applicant_s_Street_Address__c ?? app.Applicant_s_Street_Address__c;
			app.Applicant_s_Email_Address__c = currentApp.Applicant_s_Email_Address__c ?? app.Applicant_s_Email_Address__c;
			app.Applicant_City__c = currentApp.Applicant_City__c ?? app.Applicant_City__c;
			app.Applicant_s_State__c = currentApp.Applicant_s_State__c ?? app.Applicant_s_State__c;
			app.Applicant_s_Zip_Code__c = currentApp.Applicant_s_Zip_Code__c ?? app.Applicant_s_Zip_Code__c;
			app.Applicant_s_Phone_Number__c = currentApp.Applicant_s_Phone_Number__c ?? app.Applicant_s_Phone_Number__c;
			app.Applicant_s_Date_of_Birth_MM_DD_YYYY__c = currentApp.Applicant_s_Date_of_Birth_MM_DD_YYYY__c ??
				app.Applicant_s_Date_of_Birth_MM_DD_YYYY__c;
			app.Applicants_Tax_Id__c = currentApp.Applicants_Tax_Id__c ?? app.Applicants_Tax_Id__c;
			app.Applicant_s_Country_of_Nationality__c = currentApp.Applicant_s_Country_of_Nationality__c ??
				app.Applicant_s_Country_of_Nationality__c;
			app.Applicant_s_Primary_Language__c = currentApp.Applicant_s_Primary_Language__c ??
				app.Applicant_s_Primary_Language__c;
			app.Applicant_s_Preferred_Name__c = currentApp.Applicant_s_Preferred_Name__c ??
				app.Applicant_s_Preferred_Name__c;
			app.Guardian_Name__c = currentApp.Guardian_Name__c ?? app.Guardian_Name__c;
			app.Relationship_to_this_Young_Person__c = currentApp.Relationship_to_this_Young_Person__c ??
				app.Relationship_to_this_Young_Person__c;
			app.Guardian_Phone_Number__c = currentApp.Guardian_Phone_Number__c ?? app.Guardian_Phone_Number__c;
			app.Guardian_Email__c = currentApp.Guardian_Email__c ?? app.Guardian_Email__c;
			app.Emergency_Contact_First_Name__c = currentApp.Emergency_Contact_First_Name__c ??
				app.Emergency_Contact_First_Name__c;
			app.Emergency_Contact_Last_Name__c = currentApp.Emergency_Contact_Last_Name__c ??
				app.Emergency_Contact_Last_Name__c;
			app.Emergency_Contact_Email__c = currentApp.Emergency_Contact_Email__c ?? app.Emergency_Contact_Email__c;
			app.Emergency_Contact_Phone__c = currentApp.Emergency_Contact_Phone__c ?? app.Emergency_Contact_Phone__c;
			app.Emergency_Contact_Relationship__c = currentApp.Emergency_Contact_Relationship__c ??
				app.Emergency_Contact_Relationship__c;
			app.Applicant_s_Sex_Assigned_at_Birth__c = currentApp.Applicant_s_Sex_Assigned_at_Birth__c ??
				app.Applicant_s_Sex_Assigned_at_Birth__c;
			app.Social_Security_or_Other_Payments__c = currentApp.Social_Security_or_Other_Payments__c ??
				app.Social_Security_or_Other_Payments__c;
			app.Unemployment_or_disability_payments__c = currentApp.Unemployment_or_disability_payments__c ??
				app.Unemployment_or_disability_payments__c;
			app.Public_assistance_payments__c = currentApp.Public_assistance_payments__c ??
				app.Public_assistance_payments__c;
			app.Any_other_source_not_named_above__c = currentApp.Any_other_source_not_named_above__c ??
				app.Any_other_source_not_named_above__c;
			app.Explanation_of_Attestations__c = currentApp.Explanation_of_Attestations__c ??
				app.Explanation_of_Attestations__c;
			app.Consent_to_Request_Clearance__c = currentApp.Consent_to_Request_Clearance__c ??
				app.Consent_to_Request_Clearance__c;
			app.Interest_in_dividends_from_assets__c = currentApp.Interest_in_dividends_from_assets__c ??
				app.Interest_in_dividends_from_assets__c;
			app.Applicant_s_Current_Gender__c = currentApp.Applicant_s_Current_Gender__c ??
				app.Applicant_s_Current_Gender__c;
			app.Applicant_s_Preferred_Pronoun__c = currentApp.Applicant_s_Preferred_Pronoun__c ??
				app.Applicant_s_Preferred_Pronoun__c;
			app.Race_and_or_Ethnicity__c = currentApp.Race_and_or_Ethnicity__c ?? app.Race_and_or_Ethnicity__c;
			app.Applicant_s_Last_Completed_Grade__c = currentApp.Applicant_s_Last_Completed_Grade__c ??
				app.Applicant_s_Last_Completed_Grade__c;
			app.Applicant_s_Current_Most_Recent_School__c = currentApp.Applicant_s_Current_Most_Recent_School__c ??
				app.Applicant_s_Current_Most_Recent_School__c;
			app.Applicant_s_Current_Employment_Status__c = currentApp.Applicant_s_Current_Employment_Status__c ??
				app.Applicant_s_Current_Employment_Status__c;
			app.Is_this_Youth_TANF_Eligible__c = currentApp.Is_this_Youth_TANF_Eligible__c ??
				app.Is_this_Youth_TANF_Eligible__c;
			app.Current_Living_Situation__c = currentApp.Current_Living_Situation__c ?? app.Current_Living_Situation__c;
			app.Applicant_s_Internet_Connectivity__c = currentApp.Applicant_s_Internet_Connectivity__c ??
				app.Applicant_s_Internet_Connectivity__c;
			app.Applicant_Medical_Conditions__c = currentApp.Applicant_Medical_Conditions__c ??
				app.Applicant_Medical_Conditions__c;
			app.Applicant_Mental_Health_Diagnosis__c = currentApp.Applicant_Mental_Health_Diagnosis__c ??
				app.Applicant_Mental_Health_Diagnosis__c;
			app.Applicant_Mental_Disability_Diagnosis__c = currentApp.Applicant_Mental_Disability_Diagnosis__c ??
				app.Applicant_Mental_Disability_Diagnosis__c;
			app.Applicant_Deaf_Difficulty_Hearing__c = currentApp.Applicant_Deaf_Difficulty_Hearing__c ??
				app.Applicant_Deaf_Difficulty_Hearing__c;
			app.Applicant_Blind_Difficulty_Seeing__c = currentApp.Applicant_Blind_Difficulty_Seeing__c ??
				app.Applicant_Blind_Difficulty_Seeing__c;
			app.Applicant_Involved_in_Justice_System__c = currentApp.Applicant_Involved_in_Justice_System__c ??
				app.Applicant_Involved_in_Justice_System__c;
			app.Applicant_Need_Support_Assistance__c = currentApp.Applicant_Need_Support_Assistance__c ??
				app.Applicant_Need_Support_Assistance__c;
			app.Income_Attestation__c = currentApp.Income_Attestation__c ?? app.Income_Attestation__c;
			app.Wages_from_Employment__c = currentApp.Wages_from_Employment__c ?? app.Wages_from_Employment__c;
			app.Income_from_operation_of_a_business__c = currentApp.Income_from_operation_of_a_business__c ??
				app.Income_from_operation_of_a_business__c;
			app.Willing_to_accept_an_unselected_program__c = currentApp.Willing_to_accept_an_unselected_program__c ??
				app.Willing_to_accept_an_unselected_program__c;
			app.Media_Picture_Release__c = currentApp.Media_Picture_Release__c ?? app.Media_Picture_Release__c;
			app.Parent_s_Consent__c = currentApp.Parent_s_Consent__c ?? app.Parent_s_Consent__c;
			app.Release_of_Information__c = currentApp.Release_of_Information__c ?? app.Release_of_Information__c;

			app.Launchpad__Stage__c = 'Submitted';

			appsToUpdate.add(app);
		}

		update appsToUpdate;
	}
    
    
   
    
    public static List<Database.UpsertResult> saveConsentFormToApplicationAndUpdateFields(Id appId){
        Launchpad__Applicant_Tracking__c currentApp = GuestUserApplicationController.getCurrentJobApplication(appId);
        
        List<Launchpad__Applicant_Tracking__c> relatedApps = GuestUserApplicationController.getRelatedJobApplications(appId);
        List<Launchpad__Applicant_Tracking__c> appsToUpdate = new List<Launchpad__Applicant_Tracking__c>();
     
        
        for(Launchpad__Applicant_Tracking__c relatedApp : relatedApps){
            relatedApp.Media_Picture_Release__c = currentApp.Media_Picture_Release__c ?? relatedApp.Media_Picture_Release__c;
            relatedApp.Parent_s_Consent__c = currentApp.Parent_s_Consent__c ?? relatedApp.Parent_s_Consent__c;
            relatedApp.Release_of_Information__c = currentApp.Release_of_Information__c ?? relatedApp.Release_of_Information__c;
            relatedApp.Consent_to_Request_Clearance__c = currentApp.Consent_to_Request_Clearance__c ?? relatedApp.Consent_to_Request_Clearance__c;
            relatedApp.Guardian_Consent_Required__c = false;
            appsToUpdate.add(relatedApp);
        }
        System.debug('currentApp media release: ' + currentApp.Media_Picture_Release__c);
        return GuestUserApplicationController.updateJobApplications(appsToUpdate);
        
    }
    
    
	@AuraEnabled
	public static Map<String, Object> submitApp(
		SObject sObj,
		String application,
		String filesString,
		Boolean isSaveForLater
	) {
		Map<String, Object> ret = new Map<String, Object>();
		Id sObjectId;

		try {
			// ! IF ADJUSTMENTS ARE NEEDED TO SPECIFIC APPLICATIONS, USE A SWITCH STATEMENT AND UNCOMMENT THE CODE CODE BELOW
            // Pre upsert logic
            if (application == 'C2L_Program_Application' && isSaveForLater != true) {
                List<C2L_PHL_Eligible_Zip_Codes__mdt> zipCodeList = [SELECT Id, Label from C2L_PHL_Eligible_Zip_Codes__mdt];
                Map<String, Id> zipCodeMap = new Map<String, Id>();
                
                for (C2L_PHL_Eligible_Zip_Codes__mdt zipCode : zipCodeList) {
    				zipCodeMap.put(zipCode.Label, zipCode.Id);
				}
                String enteredZip = String.valueOf(sObj.get('Applicant_s_Zip_Code__c'));
                if(zipCodeMap.get(enteredZip) == null){
                    ret.put('error', 'The Zip Code entered is not valid for this program.');
                	return ret;
                }
				sObj.put('Launchpad__Stage__c', 'Submitted'); 
            }
            
             Database.UpsertResult result;
            if(application == 'Consent_Form' && isSaveForLater != true){
                
                Launchpad__Applicant_Tracking__c currentAppForConsent = GuestUserApplicationController.getCurrentJobApplication(appId);
                if(currentAppForConsent.Guardian_Consent_Required__c == false){
                    ret.put('error', 'The Consent Form has already been submitted for this youth.');
                	return ret;
                }
                GuestUserApplicationController.updateSingleJobApplication(sobj);
                result = saveConsentFormToApplicationAndUpdateFields(appId)[0];
            }else{
               result = Database.upsert(sObj, false);
            }

			Database.UpsertResult result = Database.upsert(sObj, false);
			if (!result.isSuccess()) {
				throw new CustomException(result.getErrors()[0].getMessage());
			}

			ret.put('data', result.Id);
			sObjectId = result.Id;

            // Post upsert logic
            if (application == 'C2L_Program_Application' && isSaveForLater != true) {
                updateOtherAppsInSameSession(sObjectId);
            }

			if (filesString != null) {
				List<File> filesList = (List<File>) JSON.deserialize(filesString, List<File>.class);

				List<File> files = new List<File>();
				for (File file : filesList) {
					File newFile = new File();
					newFile.base64 = file.base64;
					newFile.fileName = file.filename;
					files.add(newFile);
				}
				uploadFiles(files, sObjectId);
			}
		} catch (Exception e) {
			ret.put('error', e.getTypeName() + ' | ' + e.getMessage() + ' | ' + e.getStackTraceString());
		}

		return ret;
	}

	@AuraEnabled
	public static void submitChildObjects(List<childRecordsWrapper> childObjs, Id parentId) {
		try {
			List<SObject> records = new List<SObject>();
			for (childRecordsWrapper wrapper : childObjs) {
				for (SObject record : wrapper.records) {
					record.put(wrapper.parentField, parentId);
				}
				records.addAll(wrapper.records);
			}
			insert records;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static Map<String, Object> getChildObjectFields(String ObjectName, String FieldSetName) {
		Map<String, Object> ret = new Map<String, Object>();

		Map<String, List<Object>> fieldsetmap = new Map<String, List<Object>>();

		Schema.FieldSet objFieldSet = ((SObject) Type.forName('Schema', ObjectName)?.newInstance())
			?.getSObjectType()
			?.getDescribe()
			?.fieldSets
			?.getMap()
			?.get(FieldSetName);

		if (objFieldSet == null) {
			ret.put('error', String.format(NULL_FIELDSET, new List<Object>{ FieldSetName, ObjectName }));
		} else {
			Map<String, Set<String>> mapfieldset = new Map<String, Set<String>>();
			Map<String, Map<String, String>> mapFieldSetting = new Map<String, Map<String, String>>();

			Set<String> nullFieldSets = new Set<String>();
			sObject fieldValues = null;

			List<Schema.FieldSetMember> fields = objFieldSet.getFields();
			List<Object> fieldMembers = new List<Object>();
			for (Schema.FieldSetMember member : fields) {
				String altLabel;
				Boolean hasAltLabel = false;

				if (mapFieldSetting?.containsKey(FieldSetName)) {
					if (mapFieldSetting.get(FieldSetName)?.containsKey(member.getFieldPath())) {
						hasAltLabel = true;
						altLabel = mapFieldSetting.get(FieldSetName).get(member.getFieldPath());
					}
				}

				Map<String, Object> fieldMember = new Map<String, Object>{
					'api' => member.getFieldPath(),
					'req' => (member.getDBRequired() || member.getRequired()),
					'label' => member.getLabel(),
					'type' => member.getType().name(),
					'hasAltLabel' => hasAltLabel,
					'altLabel' => altLabel
				};

				fieldMembers.add(fieldMember);
			}
			//fieldsetmap.put(FieldSetName, fieldMembers);

			ret.put('fielddata', fieldMembers);
		}

		return ret;
	}

	//  public static String uploadFiles(String base64, String filename, String recordId) {
	public static void uploadFiles(List<File> files, Id sObjectId) {
		List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
		List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();

		for (File file : files) {
			ContentVersion cv = createContentVersion(file.base64, file.filename);
			contentVersionsToInsert.add(cv);
		}
		insert contentVersionsToInsert;

		for (ContentVersion contVersion : contentVersionsToInsert) {
			ContentDocumentLink cdl = createContentLink(contVersion.Id, sObjectId);
			contentDocumentLinksToInsert.add(cdl);
		}
		insert contentDocumentLinksToInsert;
	}

	private static ContentVersion createContentVersion(String base64, String filename) {
		ContentVersion cv = new ContentVersion();
		cv.VersionData = EncodingUtil.base64Decode(base64);
		cv.Title = filename;
		cv.PathOnClient = filename;
		return cv;
	}

	private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
		if (contentVersionId == null || recordId == null) {
			return null;
		}
		ContentDocumentLink cdl = new ContentDocumentLink();
		cdl.ContentDocumentId = [
			SELECT ContentDocumentId
			FROM ContentVersion
			WHERE Id = :contentVersionId
		]
		.ContentDocumentId;

		cdl.LinkedEntityId = recordId;
		cdl.ShareType = 'V';
		return cdl;
	}

	public class File {
		public String filename;
		public string base64;
	}

	public class childRecordsWrapper {
		@AuraEnabled
		public String objectName { get; set; }
		@AuraEnabled
		public String parentField { get; set; }
		@AuraEnabled
		public List<SObject> records { get; set; }
	}

	public class CustomException extends Exception {
	}
}