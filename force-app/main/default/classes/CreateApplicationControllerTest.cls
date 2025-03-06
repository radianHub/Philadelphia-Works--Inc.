@isTest
public class CreateApplicationControllerTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Participant',
            Email = 'test@example.com'
        );
        insert testContact;

        RecordType sessionRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Launchpad__Program__c' AND Name = 'Session' LIMIT 1];

        Launchpad__Program__c program = new Launchpad__Program__c(
            Name = 'Test Program',
            Launchpad__Active__c = 'Yes',
            RecordTypeId = sessionRecordType.Id
        );
        insert program;
        
        List<Launchpad__Job__c> testJobs = new List<Launchpad__Job__c>();
        Launchpad__Job__c testJob1 = new Launchpad__Job__c(
            Name = 'Test Job 1',
            Launchpad__Account__c = testAccount.Id,
            Program__c = program.Id
        );
        testJobs.add(testJob1);
        Launchpad__Job__c testJob2 = new Launchpad__Job__c(
            Name = 'Test Job 2',
            Launchpad__Account__c = testAccount.Id,
            Program__c = program.Id
        );
        testJobs.add(testJob2);
        Launchpad__Job__c testJob3 = new Launchpad__Job__c(
            Name = 'Test Job 3',
            Launchpad__Account__c = testAccount.Id,
            Program__c = program.Id
        );
        testJobs.add(testJob3);
        insert testJobs;
    }
    
    @isTest
    static void testCreateNewApplication() {
        Contact testContact = [SELECT Id, Email FROM Contact LIMIT 1];
        Launchpad__Job__c testJob = [SELECT Id FROM Launchpad__Job__c LIMIT 1];
        
        Test.startTest();
        Id applicationId = CreateApplicationController.createApplication(
            testContact.Id, 
            testJob.Id, 
            testContact.Email
        );
        Test.stopTest();
        
        System.assertNotEquals(null, applicationId, 'Application ID should not be null');
        
        Launchpad__Applicant_Tracking__c createdApp = [
            SELECT Id, Launchpad__Participant__c, Launchpad__Job_Order__c, Provider_Rank__c, Applicant_s_Email_Address__c
            FROM Launchpad__Applicant_Tracking__c
            WHERE Id = :applicationId
        ];
        
        System.assertEquals(testContact.Id, createdApp.Launchpad__Participant__c, 'Contact ID should match');
        System.assertEquals(testJob.Id, createdApp.Launchpad__Job_Order__c, 'Job ID should match');
        System.assertEquals('1', createdApp.Provider_Rank__c, 'Provider Rank should be 1');
        System.assertEquals(testContact.Email, createdApp.Applicant_s_Email_Address__c, 'Email should match');
    }
    
    @isTest
    static void testInvalidContactId() {
        Launchpad__Job__c testJob = [SELECT Id FROM Launchpad__Job__c LIMIT 1];
        
        Test.startTest();
        try {
            Id applicationId = CreateApplicationController.createApplication(
                '003000000000001', 
                testJob.Id, 
                'test@example.com'
            );
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('INVALID_CROSS_REFERENCE_KEY') || 
                         e.getMessage().contains('invalid ID'), 
                         'Expected exception for invalid contact ID');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateBulkApplications() {
        Contact testContact = [SELECT Id, Email FROM Contact LIMIT 1];
        List<Launchpad__Job__c> testJobs = [SELECT Id FROM Launchpad__Job__c ORDER BY Name];
        
        List<Map<String, Object>> applicationsList = new List<Map<String, Object>>();
        for(Integer i = 0; i < testJobs.size(); i++) {
            Map<String, Object> appData = new Map<String, Object>{
                'id' => testJobs[i].Id,
                'order' => String.valueOf(i + 1)
            };
            applicationsList.add(appData);
        }
        
        Test.startTest();
        Id resultId = CreateApplicationController.createBulkApplications(
            testContact.Id,
            testContact.Email,
            applicationsList
        );
        Test.stopTest();
        
        System.assertNotEquals(null, resultId, 'Result ID should not be null');
        
        List<Launchpad__Applicant_Tracking__c> createdApps = [
            SELECT Id, Launchpad__Participant__c, Launchpad__Job_Order__c, Provider_Rank__c, Applicant_s_Email_Address__c
            FROM Launchpad__Applicant_Tracking__c
            WHERE Launchpad__Participant__c = :testContact.Id
            ORDER BY Provider_Rank__c
        ];
        
        System.assertEquals(testJobs.size(), createdApps.size(), 'All applications should be created');
        
        for(Integer i = 0; i < createdApps.size(); i++) {
            Launchpad__Applicant_Tracking__c app = createdApps[i];
            System.assertEquals(testContact.Id, app.Launchpad__Participant__c, 'Contact ID should match');
            System.assertEquals(String.valueOf(i + 1), app.Provider_Rank__c, 'Provider Rank should match');
            System.assertEquals(testContact.Email, app.Applicant_s_Email_Address__c, 'Email should match');
        }
        
        System.assertEquals(createdApps[0].Id, resultId, 'First application ID should be returned');
    }
}