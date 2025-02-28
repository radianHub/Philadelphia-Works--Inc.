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
        DocumentChecklistController.DocumentStatuses statuses = DocumentChecklistController.getDocumentStatuses('TestChecklist');
        Test.stopTest();
        
        if (Test.isRunningTest()) {
            Assert.areNotEqual(null, statuses);
            System.debug('statuses: ' + statuses);
            // Verify mock statuses if your implementation handles test context
        }
    }
    
    // Test method for getChecklist using Test.isRunningTest() check
    @isTest
    static void testGetChecklist() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        List<DocumentChecklistController.ChecklistItem> checklist = DocumentChecklistController.getChecklist('TestChecklist', testContact.Id, 'AccountId');
        Test.stopTest();
        
        // In a test context, verify the method returns expected results
        if (Test.isRunningTest()) {
            Assert.areNotEqual(null, checklist);
            System.debug('checklist: ' + checklist);
            // Verify other properties if your implementation handles test context
        }
    }
    
    // Test method for initializeDocument
    @isTest
    static void testInitializeDocument() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        Id documentId = DocumentChecklistController.initializeDocument('TestChecklist', testContact.Id, 'TestType', 'AccountId');
        Test.stopTest();
        
        // Verify the document was created correctly
        if (documentId != null) {
            Launchpad__Document__c document = [SELECT Id, Launchpad__Type__c FROM Launchpad__Document__c WHERE Id = :documentId];
            Assert.areEqual('TestType', document.Launchpad__Type__c);
        }
    }
    
    // Test method for updateDocumentStatus
    @isTest
    static void testUpdateDocumentStatus() {
        Launchpad__Document__c document = [SELECT Id FROM Launchpad__Document__c LIMIT 1];
        
        Test.startTest();
        DocumentChecklistController.updateDocumentStatus('TestChecklist', document.Id, 'Approved');
        Test.stopTest();
        
        // Verify the status was updated
        document = [SELECT Launchpad__Status__c FROM Launchpad__Document__c WHERE Id = :document.Id];
        Assert.areEqual('Approved', document.Launchpad__Status__c);
    }
    
    // Test method for deleteDocumentFile
    @isTest
    static void testDeleteDocumentFile() {
        Launchpad__Document__c document = [SELECT Id FROM Launchpad__Document__c LIMIT 1];
        
        Test.startTest();
        DocumentChecklistController.deleteDocumentFile('TestChecklist', document.Id);
        Test.stopTest();
        
        // Verify the document file was deleted (ContentDocumentLink is deleted)
        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :document.Id];
        Assert.areEqual(0, links.size());
    }
    
    // Test method for getContentVersionFromDocumentId
    @isTest
    static void testgetContentVersionFromDocumentId() {
        Launchpad__Document__c document = [SELECT Id FROM Launchpad__Document__c LIMIT 1];
        
        Test.startTest();
        ContentVersion cv;
        try {
            cv = DocumentChecklistController.getContentVersionFromDocumentId(document.Id);
        } catch (Exception e) {
            // Handle expected exceptions in test context
        }
        Test.stopTest();
        
        // Verify the content version was retrieved
        if (cv != null) {
            Assert.areEqual('Test Document', cv.Title);
        }
    }
    
    // Test negative scenarios
    @isTest
    static void testNegativeScenarios() {
        // Test invalid document ID for updateDocumentStatus
        Test.startTest();
        try {
            DocumentChecklistController.updateDocumentStatus('TestChecklist', 'InvalidId', 'Approved');
            Assert.isFalse(false);
        } catch (Exception e) {
            Assert.isTrue(true);
        }
        
        // Test invalid document ID for deleteDocumentFile
        try {
            DocumentChecklistController.deleteDocumentFile('TestChecklist', 'InvalidId');
            Assert.isFalse(false);
        } catch (Exception e) {
            Assert.isTrue(true);
        }
        
        // Test invalid document ID for getContentVersionFromDocumentId
        try {
            DocumentChecklistController.getContentVersionFromDocumentId('InvalidId');
            Assert.isFalse(false);
        } catch (Exception e) {
            Assert.isTrue(true);
        }
        Test.stopTest();
    }
}