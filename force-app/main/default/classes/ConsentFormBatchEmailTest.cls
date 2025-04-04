@isTest
public class ConsentFormBatchEmailTest {
    @testSetup
    static void setupTestData() {
         Account testAccount = new Account(
            Name = 'Test Account',
            Industry = 'Technology',  
            Phone = '123-456-7890' 
        );
        insert testAccount;
        
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(FirstName = 'Test', LastName = 'Participant ' + i));
        }
        insert contacts;

        List<Launchpad__Applicant_Tracking__c> jobApplications = new List<Launchpad__Applicant_Tracking__c>();
        
        Launchpad__Job__c job = new Launchpad__Job__c();
        job.Launchpad__Openings__c = 10;
        job.Launchpad__Account__c = testAccount.Id;
        job.Launchpad__Stage__c = 'Interviewing';
        job.Launchpad__Closing_Date__c = Date.today();
        job.Launchpad__Source__c = 'Direct Employer Contact';
        job.Launchpad__Hourly_Wage_Minimum__c = 30.00;
        job.Launchpad__Hourly_Wage_Maximum__c = 60.00;
        
        insert job;
        
        
        Launchpad__Applicant_Tracking__c firstApp = new Launchpad__Applicant_Tracking__c();
        firstApp.Launchpad__Participant__c = contacts[0].Id; 
        firstApp.Launchpad__Stage__c = 'Submitted';
        firstApp.Provider_Rank__c = '1';
        firstApp.Previous_Stage__c = 'Provider Selected';
        firstApp.Launchpad__Job_Order__c = job.Id;
        firstApp.Applicant_s_Email_Address__c = 'Test12@test12345.com';
        firstApp.guardian_consent_required__c = true;
        firstApp.Applicants_Tax_Id__c = '332-65-7823';
        firstApp.submitted_from_universal_app__c = true;
        firstApp.Emergency_Contact_Email__c = 'egeeggbrnrn@fwewgreeffe.com';
        firstApp.guardian_email__c = 'Test3423322324242424244224@test4gfdwegegf.com';
        firstApp.Applicant_s_Date_of_Birth_MM_DD_YYYY__c = Date.ValueOf('2008-03-03');
        jobApplications.add(firstApp);

            
        
        
        insert jobApplications;
    }
    @isTest
    public static void testBatch(){
        List<Launchpad__Applicant_Tracking__c> jobApplications = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Previous_Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        List<List<Id>> t = new List<List<Id>>();
        List<Id> tempList = new List<Id>();
        for(Launchpad__Applicant_Tracking__c l : jobApplications){
            tempList.add(l.Id);
        }
        t.add(tempList);
        JobApplicationConsentFormController.sendConsentFormEmail(t);
    }
}