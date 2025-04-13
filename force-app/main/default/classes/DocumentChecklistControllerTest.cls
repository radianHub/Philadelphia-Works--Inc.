@isTest
public class DocumentChecklistControllerTest {
	@testSetup
	static void setup() {
		Account testAccount = new Account(Name = 'Test Account');
		insert testAccount;

		Contact testContact = new Contact(LastName = 'Test', AccountId = testAccount.Id);
		insert testContact;

		Launchpad__Document__c document = new Launchpad__Document__c(
			Launchpad__Type__c = 'Proof of ID',
			Launchpad__Status__c = 'Not Started',
			Launchpad__Contact__c = testContact.Id
		);
		insert document;

		ContentVersion cv = new ContentVersion();
		cv.Title = 'Test Document';
		cv.VersionData = Blob.valueOf('Test Content');
		cv.PathOnClient = 'testdocument.pdf';
		insert cv;

		Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

		ContentDocumentLink cdl = new ContentDocumentLink();
		cdl.ContentDocumentId = contentDocumentId;
		cdl.LinkedEntityId = document.Id;
		cdl.ShareType = 'V';
		insert cdl;
	}

	@isTest
	static void testGetDocumentStatuses() {
		Test.startTest();
		DocumentChecklistController.DocumentStatuses statuses = DocumentChecklistController.getDocumentStatuses(
			'TestChecklist'
		);
		Test.stopTest();

		if (Test.isRunningTest()) {
			Assert.areNotEqual(null, statuses);
			Assert.areEqual(statuses.approvedStatus, 'Approved');
		}
	}

	@isTest
	static void testGetChecklist() {
		Contact testContact = [SELECT Id FROM Contact LIMIT 1];

		Test.startTest();
		List<DocumentChecklistController.ChecklistItem> checklist = DocumentChecklistController.getChecklist(
			'TestChecklist',
			testContact.Id,
			'Launchpad__Contact__c'
		);
		Test.stopTest();

		if (Test.isRunningTest()) {
			Assert.areNotEqual(null, checklist);
		}
	}

	@isTest
	static void testInitializeDocument() {
		Contact testContact = [SELECT Id FROM Contact LIMIT 1];

		Test.startTest();
		Id documentId = DocumentChecklistController.initializeDocument(
			'TestChecklist',
			testContact.Id,
			'TestType',
			'Launchpad__Contact__c'
		);
		Test.stopTest();

		if (documentId != null) {
			Launchpad__Document__c document = [
				SELECT Id, Launchpad__Type__c
				FROM Launchpad__Document__c
				WHERE Id = :documentId
			];
			Assert.areEqual('TestType', document.Launchpad__Type__c);
		}
	}

	@isTest
	static void testUpdateDocumentStatus() {
		Launchpad__Document__c document = [SELECT Id FROM Launchpad__Document__c LIMIT 1];

		Test.startTest();
		DocumentChecklistController.updateDocumentStatus('TestChecklist', document.Id, 'Default', null);
		Test.stopTest();

		document = [SELECT Launchpad__Status__c FROM Launchpad__Document__c WHERE Id = :document.Id];
		Assert.areEqual('Not Started', document.Launchpad__Status__c);
	}

	@isTest
	static void testDeleteDocumentFile() {
		Launchpad__Document__c document = [SELECT Id FROM Launchpad__Document__c LIMIT 1];

		Test.startTest();
		DocumentChecklistController.deleteDocumentFile('TestChecklist', document.Id);
		Test.stopTest();

		List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :document.Id];
		Assert.areEqual(0, links.size());
	}

	@isTest
	static void testgetContentVersionFromDocumentId() {
		Launchpad__Document__c document = [SELECT Id FROM Launchpad__Document__c LIMIT 1];

		Test.startTest();
		ContentVersion cv = DocumentChecklistController.getContentVersionFromDocumentId(document.Id);
		Test.stopTest();

		if (cv != null) {
			Assert.areEqual('Test Document', cv.Title);
		}
	}
}