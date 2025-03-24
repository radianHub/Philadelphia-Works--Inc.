public with sharing class ProviderApplicantsController {
	@AuraEnabled(cacheable=true)
	public static List<Launchpad__Job__c> getActiveJobs(Id accountId) {
		List<Launchpad__Program__c> programs = [
			SELECT Id
			FROM Launchpad__Program__c
			WHERE Launchpad__Active__c = 'Yes' AND RecordType.Name = 'Session'
		];
		Id programId = programs[0].Id;

		List<Launchpad__Job__c> jobs = [
			SELECT Id, Name
			FROM Launchpad__Job__c
			WHERE Program__c = :programId AND (Launchpad__Account__c = :accountId OR Placement_Site__c = :accountId)
			ORDER BY Name ASC
		];

		return jobs;
	}

	@AuraEnabled(cacheable=true)
	public static List<Launchpad__Applicant_Tracking__c> getApplicants(
		Id accountId,
		String choice,
		Id jobId,
		Boolean isPriority
	) {
		if (accountId == null) {
			return null;
		}

		List<Launchpad__Program__c> programs = [
			SELECT Id
			FROM Launchpad__Program__c
			WHERE Launchpad__Active__c = 'Yes' AND RecordType.Name = 'Session'
		];
		Id programId = programs[0].Id;

		String query =
			'SELECT Id, Provider_Rank__c, Launchpad__Participant__r.Name, ' +
			'Launchpad__Job_Order__c, Launchpad__Job_Order__r.Name, ' +
			'Launchpad__Participant__r.Priority_Population__c, Launchpad__Stage__c, Provider_Choice__c, ' +
			'CreatedDate, RecordTypeId ' +
			'FROM Launchpad__Applicant_Tracking__c ' +
			'WHERE Launchpad__Stage__c != \'In Progress\' ' +
			'AND Launchpad__Job_Order__r.Program__c = :programId ' +
			'AND (Launchpad__Job_Order__r.Launchpad__Account__c = :accountId ' +
			'OR Launchpad__Job_Order__r.Placement_Site__c = :accountId) ';

		// Add filter for Provider_Choice__c only if choice is not null
		if (choice != null) {
			query += 'AND Provider_Choice__c = :choice ';
		}

		// Add filter for Job only if jobId is not null
		if (jobId != null) {
			query += 'AND Launchpad__Job_Order__c = :jobId ';
		}

		// Add filter for Priority Population if isPriority is true
		if (isPriority) {
			query += 'AND Launchpad__Participant__r.Priority_Population__c = true ';
		}

		query += 'ORDER BY Launchpad__Participant__r.Priority_Population__c DESC, Provider_Rank__c ASC, CreatedDate DESC';

		return Database.query(query);
	}

	@AuraEnabled
	public static List<FieldWrapper> getFieldsByObjectAndFieldSet(String objectName, String fieldSetName) {
		List<FieldWrapper> fieldWrapperList = new List<FieldWrapper>();

		Schema.FieldSet fieldSet = getFieldSet(objectName, fieldSetName);

		if (fieldSet == null) {
			return fieldWrapperList;
		}

		for (Schema.FieldSetMember fmo : fieldSet.getFields()) {
			Schema.SObjectField sObjField = fmo.getSObjectField();
			Schema.DescribeFieldResult fieldResult = sObjField.getDescribe();
			FieldWrapper fw = new FieldWrapper(
				fmo.getFieldPath(),
				fmo.getLabel(),
				String.valueOf(fmo.getType()),
				fmo.getRequired()
			);
			fw.customHelpText = fieldResult.getInlineHelpText();
			fw.fieldScreenSize = 6;
			fieldWrapperList.add(fw);
		}

		return fieldWrapperList;
	}

	@AuraEnabled
	public static Boolean bulkUpdateApplicantStage(List<String> applicantIds, String choice, String passReason) {
		List<Launchpad__Applicant_Tracking__c> applicants = [
			SELECT Id, Launchpad__Stage__c
			FROM Launchpad__Applicant_Tracking__c
			WHERE Id IN :applicantIds
		];

		List<Launchpad__Applicant_Tracking__c> applicantsToUpdate = new List<Launchpad__Applicant_Tracking__c>();

		for (Launchpad__Applicant_Tracking__c applicant : applicants) {
			if (applicant.Launchpad__Stage__c != choice) {
				applicant.Provider_Choice__c = choice;
				applicant.Launchpad__Stage__c = choice == 'None' ? 'Submitted' : choice;

				if (passReason != null) {
					applicant.Passed_Reason__c = passReason;
				}

				applicantsToUpdate.add(applicant);
			}
		}

		if (!applicantsToUpdate.isEmpty()) {
			update applicantsToUpdate;
		}

		return true;
	}

	public static Schema.DescribeSObjectResult getSObjSchema(String sObj) {
		Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
		Schema.SObjectType sObjectTypeObj = globalDescribeMap.get(sObj);
		return sObjectTypeObj.getDescribe();
	}

	public static Schema.FieldSet getFieldSet(String objectName, String fieldSetName) {
		Schema.DescribeSObjectResult describeSObjectResultObj = getSObjSchema(objectName);
		Schema.FieldSet fieldSet = describeSObjectResultObj.FieldSets.getMap().get(fieldSetName);

		if (fieldSet == null && fieldSetName.countMatches('__') == 1) {
			Integer index = fieldSetName.indexOf('__') + 2;
			fieldSetName = fieldSetName.right(fieldSetName.length() - index);

			fieldSet = describeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
		}

		if (fieldSet == null) {
			System.debug('Field set not found. Make sure the namespace and field set api name are correct');
		}
		return fieldSet;
	}

	public class FieldWrapper {
		@AuraEnabled
		public String fieldApiName;
		@AuraEnabled
		public String fieldLabel;
		@AuraEnabled
		public String fieldType;
		@AuraEnabled
		public Boolean required;
		@AuraEnabled
		public Boolean isReadOnly;
		@AuraEnabled
		public Integer fieldScreenSize;
		@AuraEnabled
		public Boolean isOverrideHelpText;
		@AuraEnabled
		public String customHelpText;

		public FieldWrapper(String fieldApiName, String fieldLabel, String fieldType, Boolean required) {
			this.fieldApiName = fieldApiName;
			this.fieldLabel = fieldLabel;
			this.fieldType = fieldType;
			this.required = required;
			this.isReadOnly = isReadOnly;
			this.fieldScreenSize = fieldScreenSize;
			this.isOverrideHelpText = isOverrideHelpText;
			this.customHelpText = customHelpText;
		}
	}
}