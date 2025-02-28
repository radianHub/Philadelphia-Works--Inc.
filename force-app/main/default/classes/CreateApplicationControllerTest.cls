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
        
        Launchpad__Job__c testJob = new Launchpad__Job__c(
            Name = 'Test Job',
            Launchpad__Account__c = testAccount.Id
        );
        insert testJob;
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
    static void testExistingApplication() {
        Contact testContact = [SELECT Id, Email FROM Contact LIMIT 1];
        Launchpad__Job__c testJob = [SELECT Id FROM Launchpad__Job__c LIMIT 1];
        
        Launchpad__Applicant_Tracking__c existingApp = new Launchpad__Applicant_Tracking__c(
            Launchpad__Participant__c = testContact.Id,
            Launchpad__Job_Order__c = testJob.Id,
            Provider_Rank__c = '2',  
            Applicant_s_Email_Address__c = 'old@example.com' 
        );
        insert existingApp;
        
        Test.startTest();
        Id applicationId = CreateApplicationController.createApplication(
            testContact.Id, 
            testJob.Id, 
            testContact.Email
        );
        Test.stopTest();
        
        System.assertEquals(existingApp.Id, applicationId, 'Should return the existing application ID');
        
        Launchpad__Applicant_Tracking__c retrievedApp = [
            SELECT Id, Provider_Rank__c, Applicant_s_Email_Address__c
            FROM Launchpad__Applicant_Tracking__c
            WHERE Id = :applicationId
        ];
        
        System.assertEquals('2', retrievedApp.Provider_Rank__c, 'Provider Rank should not be changed');
        System.assertEquals('old@example.com', retrievedApp.Applicant_s_Email_Address__c, 'Email should not be changed');
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
}