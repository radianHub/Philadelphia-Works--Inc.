public with sharing class DocumentChecklistController {
	@AuraEnabled(cacheable=true)
	public static DocumentStatuses getDocumentStatuses(String checklistName) {
		Document_Checklist__mdt checklistSettings = getChecklistSettings(checklistName);
		DocumentStatuses statuses = new DocumentStatuses();
		statuses.approvedStatus = checklistSettings.Approved_Document_Status__c;
		statuses.rejectedStatus = checklistSettings.Rejected_Document_Status__c;
		statuses.defaultStatus = checklistSettings.Default_Document_Status__c;
		statuses.submittedStatus = checklistSettings.Submitted_Document_Status__c;
		return statuses;
	}

	@AuraEnabled(cacheable=true)
	public static List<ChecklistItem> getChecklist(String checklistName, String recordId, String lookupField) {
		List<ChecklistItem> checklist = new List<ChecklistItem>();
		List<Document_Checklist_Item__mdt> checklistItems = new List<Document_Checklist_Item__mdt>();
		List<String> docTypes = new List<String>();
		Document_Checklist__mdt checklistSettings = getChecklistSettings(checklistName);
		String defaultStatus = checklistSettings.Default_Document_Status__c;

		try {
			checklistItems = [
				SELECT MasterLabel, DeveloperName, Document_Type__c, Required__c, Order__c, Description__c
				FROM Document_Checklist_Item__mdt
				WHERE Document_Checklist__r.DeveloperName = :checklistName
				ORDER BY Order__c, DeveloperName NULLS LAST
			];
			for (Document_Checklist_Item__mdt item : checklistItems) {
				ChecklistItem doc = new ChecklistItem();

				doc.developerName = item.DeveloperName;
				doc.name = item.MasterLabel;
				doc.description = item.Description__c;
				doc.type = item.Document_Type__c;
				doc.status = defaultStatus;
				doc.required = item.Required__c;
				doc.submitted = false;
				checklist.add(doc);

				docTypes.add(item.Document_Type__c);
			}

			List<CustomDocument> docs = getDocumentsByType(checklistName, recordId, lookupField, docTypes);
			checklist = processDocuments(checklistName, checklist, docs);
		} catch (Exception e) {
			System.debug('Error getChecklist: ' + e.getMessage());
		}

		return checklist;
	}

	@AuraEnabled
	public static Id initializeDocument(
		String checklistName,
		String recordId,
		String documentType,
		String lookupField
	) {
		Document_Checklist__mdt checklistSettings = getChecklistSettings(checklistName);

		String documentObject = checklistSettings.Document_Object__c;
		String documentTypeField = checklistSettings.Document_Type_Field__c;
		String documentStatusField = checklistSettings.Document_Status_Field__c;
		String defaultStatus = checklistSettings.Default_Document_Status__c;

		try {
			sObject doc = (sObject) Type.forName(documentObject).newInstance();
			doc.put(documentTypeField, documentType);
			doc.put(documentStatusField, defaultStatus);
			doc.put(lookupField, recordId);
			doc.put('Launchpad__Available_in_Community__c', 'Yes'); // implementation-specific

			insert doc;
			return doc.Id;
		} catch (Exception e) {
			System.debug('Error initializeDocument: ' + e.getMessage());
			return null;
		}
	}

	@AuraEnabled
	public static void updateDocumentStatus(
		String checklistName,
		String documentId,
		String status,
		String rejectionReason
	) {
		Document_Checklist__mdt checklistSettings = getChecklistSettings(checklistName);

		String documentObject = checklistSettings.Document_Object__c;
		String documentStatusField = checklistSettings.Document_Status_Field__c;
		String documentDateField = checklistSettings.Document_Date_Field__c;
		String defaultStatus = checklistSettings.Default_Document_Status__c;
		String submittedStatus = checklistSettings.Submitted_Document_Status__c;
		String approvedStatus = checklistSettings.Approved_Document_Status__c;
		String rejectedStatus = checklistSettings.Rejected_Document_Status__c;
		String rejectionReasonField = checklistSettings.Rejection_Reason_Field__c;
		String statusValue;
		Date dateValue;

		switch on status {
			when 'Submitted' {
				statusValue = submittedStatus;
				dateValue = Date.today();
			}
			when 'Approved' {
				statusValue = approvedStatus;
			}
			when 'Rejected' {
				statusValue = rejectedStatus;
			}
			when else {
				statusValue = defaultStatus;
			}
		}

		try {
			sObject doc = Database.query(
				'SELECT Id, ' + documentStatusField + ' FROM ' + documentObject + ' WHERE Id = :documentId'
			);
			doc.put(documentStatusField, statusValue);

			if (dateValue != null && documentDateField != null) {
				doc.put(documentDateField, dateValue);
			}

			if (rejectionReasonField != null && rejectionReason != null) {
				doc.put(rejectionReasonField, rejectionReason);
			}

			update doc;
		} catch (Exception e) {
			System.debug('Error updateDocumentStatus: ' + e.getMessage());
		}
	}

	@AuraEnabled
	public static void deleteDocumentFile(String checklistName, String documentId) {
		try {
			Id contentDocumentId = [
				SELECT Id, ContentDocumentId
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :documentId
				LIMIT 1
			]
			.ContentDocumentId;

			if (contentDocumentId != null) {
				delete [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId];
				updateDocumentStatus(checklistName, documentId, 'Default', null);
			}
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static void approveDocument(String checklistName, String documentId) {
		try {
			updateDocumentStatus(checklistName, documentId, 'Approved', null);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static void rejectDocument(String checklistName, String documentId, String rejectionReason) {
		try {
			updateDocumentStatus(checklistName, documentId, 'Rejected', rejectionReason);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	private static List<CustomDocument> getDocumentsByType(
		String checklistName,
		String recordId,
		String lookupField,
		List<String> docTypes
	) {
		List<CustomDocument> documents = new List<CustomDocument>();
		Document_Checklist__mdt checklistSettings = getChecklistSettings(checklistName);
		String documentObject = checklistSettings.Document_Object__c;
		String documentStatusField = checklistSettings.Document_Status_Field__c;
		String documentTypeField = checklistSettings.Document_Type_Field__c;
		String rejectionReasonField = checklistSettings.Rejection_Reason_Field__c == null
			? ''
			: ', ' + checklistSettings.Rejection_Reason_Field__c; // optional field
		String defaultStatus = checklistSettings.Default_Document_Status__c;

		try {
			String query =
				'SELECT Id, Name, ' +
				documentTypeField +
				', ' +
				documentStatusField +
				rejectionReasonField +
				' FROM ' +
				documentObject +
				' WHERE ' +
				lookupField +
				' = :recordId AND ' +
                ' Launchpad__Available_in_Community__c = \'Yes\' AND ' + // implementation-specific
				documentTypeField +
				' IN :docTypes ORDER BY CreatedDate ASC';
			List<sObject> docs = Database.query(query);
			for (sObject doc : docs) {
				CustomDocument document = new CustomDocument();
				document.id = (String) doc.get('Id');
				document.name = (String) doc.get('Name');
				document.type = (String) doc.get(documentTypeField);
				document.status = (String) doc.get(documentStatusField);

				if (!String.isBlank(rejectionReasonField)) {
					document.rejectionReason = (String) doc.get(checklistSettings.Rejection_Reason_Field__c);
				}

				documents.add(document);
			}
		} catch (Exception e) {
			System.debug('Error getDocumentsByType: ' + e.getMessage());
		}

		return documents;
	}

	private static List<ChecklistItem> processDocuments(
		String checklistName,
		List<ChecklistItem> checklist,
		List<CustomDocument> documents
	) {
		Document_Checklist__mdt checklistSettings = getChecklistSettings(checklistName);
		String defaultStatus = checklistSettings.Default_Document_Status__c;

		for (ChecklistItem item : checklist) {
			for (CustomDocument doc : documents) {
				if (item.type == doc.type) {
					item.documentId = doc.id;
					item.status = doc.status;
					item.submitted = doc.status != defaultStatus;

					if (doc.rejectionReason != null) {
						item.rejectionReason = doc.rejectionReason;
					}
				}
			}
		}

		return checklist;
	}

	@AuraEnabled
	public static ContentVersion getContentVersionFromDocumentId(String documentId) {
		try {
			// Get the document link along with the parent ContentDocument record
			Id contentDocumentId = [
				SELECT Id, ContentDocumentId
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :documentId
				LIMIT 1
			]
			.ContentDocumentId;

			// Get the ContentVersion data where the ContentDocumentId = :contentDocumentId
			return [
				SELECT Id, Title, FileExtension, ContentDocumentId, ContentSize, ContentUrl, VersionData, VersionDataURL
				FROM ContentVersion
				WHERE ContentDocumentId = :contentDocumentId AND FileExtension IN ('docx', 'pdf', 'jpeg', 'png', 'jpg')
				WITH USER_MODE
				LIMIT 1
			];
		} catch (Exception e) {
			System.debug('Error getContentVersionFromDocumentId: ' + e.getMessage() + ' @ ' + e.getStackTraceString());
			throw new AuraHandledException('Exception: ' + e.getMessage() + ' @ ' + e.getStackTraceString());
		}
	}

	private static Document_Checklist__mdt getChecklistSettings(String checklistName) {
		if (!Test.isRunningTest()) {
			return Document_Checklist__mdt.getInstance(checklistName);
		} else {
			Document_Checklist__mdt settings = new Document_Checklist__mdt();
			settings.DeveloperName = 'TestChecklist';
			settings.Default_Document_Status__c = 'Not Started';
			settings.Approved_Document_Status__c = 'Approved';
			settings.Rejected_Document_Status__c = 'Rejected';
			settings.Submitted_Document_Status__c = 'In Review';
			settings.Document_Object__c = 'Launchpad__Document__c';
			settings.Document_Status_Field__c = 'Launchpad__Status__c';
			settings.Document_Type_Field__c = 'Launchpad__Type__c';
			settings.Rejection_Reason_Field__c = 'Rejection_Reason__c';
			return settings;
		}
	}

	public class CustomDocument {
		@AuraEnabled
		public String id;
		@AuraEnabled
		public String name;
		@AuraEnabled
		public String type;
		@AuraEnabled
		public String status;
		@AuraEnabled
		public String rejectionReason;
	}

	public class ChecklistItem {
		@AuraEnabled
		public String developerName;
		@AuraEnabled
		public String name;
		@AuraEnabled
		public String description;
		@AuraEnabled
		public String type;
		@AuraEnabled
		public String status;
		@AuraEnabled
		public Boolean required;
		@AuraEnabled
		public String documentId;
		@AuraEnabled
		public Boolean submitted;
		@AuraEnabled
		public String rejectionReason;
	}

	public class DocumentStatuses {
		@AuraEnabled
		public String defaultStatus;
		@AuraEnabled
		public String approvedStatus;
		@AuraEnabled
		public String rejectedStatus;
		@AuraEnabled
		public String submittedStatus;
	}
}