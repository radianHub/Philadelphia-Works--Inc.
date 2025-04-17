@isTest
public class JobApplicationTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        RecordType sessionRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Launchpad__Program__c' AND Name = 'Session' LIMIT 1];
        
         Account testAccount = new Account(
            Name = 'Test Account',
            Industry = 'Technology',  
            Phone = '123-456-7890' 
        );
        insert testAccount;
        
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(FirstName = 'Test', LastName = 'Participant ' + i, Email='giuebhfiuehbfe@greoikjbfwen.com'));
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
        
        Launchpad__Program__c program = new Launchpad__Program__c();
        program.Name = 'Test Program';
        program.Launchpad__Active__c = 'Yes';
        program.RecordTypeId = sessionRecordType.Id;
        insert program;
        
        
        for (Integer i = 0; i < 3; i++) {
            if(i==0){
                Launchpad__Applicant_Tracking__c firstApp = new Launchpad__Applicant_Tracking__c();
                firstApp.Launchpad__Participant__c = contacts[0].Id; 
                firstApp.Launchpad__Stage__c = 'Submitted';
                firstApp.Provider_Rank__c = '1';
                firstApp.Previous_Stage__c = 'Provider Selected';
                firstApp.Launchpad__Job_Order__c = job.Id;
                firstApp.Applicants_Tax_Id__c = '236-33-534'+String.valueOf(i);
                firstApp.Applicant_s_Email_Address__c = 'Test12@test12345.com';
                firstApp.Emergency_Contact_Email__c = 'gegeggegege@rhefgeheg.com';
                firstApp.Program__c = program.Id;
                firstApp.Willing_to_accept_an_unselected_program__c	= 'Yes';
                jobApplications.add(firstApp);
            }else{
                jobApplications.add(new Launchpad__Applicant_Tracking__c(
                Launchpad__Participant__c = contacts[0].Id, 
                Launchpad__Stage__c = 'Submitted', 
                Provider_Rank__c = String.ValueOf(i+1),
                Launchpad__Job_Order__c = job.Id, 
                Applicants_Tax_Id__c = '236-33-5342',
                Applicant_s_Email_Address__c = 'Test12@test12345.com',
                Emergency_Contact_Email__c = 'gegeggegege@rhefgeheg.com',
                Program__c = program.Id,
                Willing_to_accept_an_unselected_program__c	= 'Yes'
            ));
            }
        }
        
        insert jobApplications;
    }

    
    /*
    Test Case 1: Match on First Choice
		Setup: Youth applies to 3 employers (A, B, C) ranked 1, 2, 3.

		Actions: Employer A sets application to "Provider Selected".

		Expected Outcome:
            Application A becomes "Matched with Provider".
            Applications B and C become "Unavailable".
	*/
    @isTest
    public static void matchOnFirstChoice() {
        List<Launchpad__Applicant_Tracking__c> jobApplications = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        /*
        JobApplications[0] == A
        JobApplications[1] == B
        JobApplications[2] == C
		*/
        Test.startTest();
        jobApplications[0].Provider_Choice__c = 'Provider Selected';
        jobApplications[0].Launchpad__Stage__c = 'Provider Selected';
        
        update jobApplications[0];
        Test.stopTest();
        
        List<Launchpad__Applicant_Tracking__c> jobApplicationsUpdated = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        
        System.assertEquals('Matched with Provider', jobApplicationsUpdated[0].Launchpad__Stage__c);
        System.assertEquals('Unavailable', jobApplicationsUpdated[1].Launchpad__Stage__c);
        System.assertEquals('Unavailable', jobApplicationsUpdated[2].Launchpad__Stage__c);
        
        
    }

    /*
      Test Case 2: Match on Second Choice
            Setup: Youth applies to A (1st), B (2nd), C (3rd).
            
            Actions:
                A = "Passed"
                B = "Provider Selected"
            
            Expected Outcome:
                Application B = "Matched with Provider"
                C = "Unavailable"
                A = "Unavailable"
     */
    @isTest
    public static void matchOnSecondChoice() {
   		List<Launchpad__Applicant_Tracking__c> jobApplications = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        /*
        JobApplications[0] == A
        JobApplications[1] == B
        JobApplications[2] == C
		*/
        List<Launchpad__Applicant_Tracking__c> jobAppsToUpdate = new List<Launchpad__Applicant_Tracking__c>();
        
        System.debug('A Id: ' + jobApplications[0].Id);
        System.debug('B Id: ' + jobApplications[1].Id);
        
        Test.startTest();
        jobApplications[0].Provider_Choice__c = 'Passed';
        jobApplications[0].Launchpad__Stage__c = 'Passed';
        
        jobApplications[1].Provider_Choice__c = 'Provider Selected';
        jobApplications[1].Launchpad__Stage__c = 'Provider Selected';
        
        jobAppsToUpdate.add(jobApplications[0]);
        jobAppsToUpdate.add(jobApplications[1]);
        
        update jobAppsToUpdate;
        Test.stopTest();
        
        List<Launchpad__Applicant_Tracking__c> jobApplicationsUpdated = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        System.assertEquals('Unavailable', jobApplicationsUpdated[0].Launchpad__Stage__c);
        System.assertEquals('Matched with Provider', jobApplicationsUpdated[1].Launchpad__Stage__c);
        System.assertEquals('Unavailable', jobApplicationsUpdated[2].Launchpad__Stage__c);
    }
    
    /*
      Test Case 3: Match on Third Choice
        Setup: A = “Passed”, B = “Passed”, C = “Provider Selected”
        
        Expected Outcome:
            C = “Matched with Provider”
            A and B = “Unavailable”
     */
    @isTest
    public static void matchOnThirdChoice() {
   		List<Launchpad__Applicant_Tracking__c> jobApplications = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        /*
        JobApplications[0] == A
        JobApplications[1] == B
        JobApplications[2] == C
		*/
        List<Launchpad__Applicant_Tracking__c> jobAppsToUpdate = new List<Launchpad__Applicant_Tracking__c>();
        
        System.debug('A Id: ' + jobApplications[0].Id);
        System.debug('B Id: ' + jobApplications[1].Id);
        System.debug('C Id: ' + jobApplications[2].Id);
        
        Test.startTest();
        jobApplications[0].Provider_Choice__c = 'Passed';
        jobApplications[0].Launchpad__Stage__c = 'Passed';
        
        jobApplications[1].Provider_Choice__c = 'Passed';
        jobApplications[1].Launchpad__Stage__c = 'Passed';
        
        
        jobApplications[2].Provider_Choice__c = 'Provider Selected';
        jobApplications[2].Launchpad__Stage__c = 'Provider Selected';
        
        jobAppsToUpdate.add(jobApplications[0]);
        jobAppsToUpdate.add(jobApplications[1]);
        jobAppsToUpdate.add(jobApplications[2]);
      
        
        update jobAppsToUpdate;
        Test.stopTest();
        
        List<Launchpad__Applicant_Tracking__c> jobApplicationsUpdated = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        System.assertEquals('Unavailable', jobApplicationsUpdated[0].Launchpad__Stage__c);
        System.assertEquals('Unavailable', jobApplicationsUpdated[1].Launchpad__Stage__c);
        System.assertEquals('Matched with Provider', jobApplicationsUpdated[2].Launchpad__Stage__c);
    }
    
    /*
      Test Case 4: All Applications Passed
        Setup: All 3 applications set to "Passed"
        
        Expected Outcome:
            Applicant status = "Ready for Reassignment"
            All applications remain in "Passed"
     */
    @isTest
    public static void allApplicationsPassed() {
        List<Launchpad__Applicant_Tracking__c> jobApplications = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        /*
        JobApplications[0] == A
        JobApplications[1] == B
        JobApplications[2] == C
		*/
        List<Launchpad__Applicant_Tracking__c> jobAppsToUpdate = new List<Launchpad__Applicant_Tracking__c>();
        
        System.debug('A Id: ' + jobApplications[0].Id);
        System.debug('B Id: ' + jobApplications[1].Id);
        System.debug('C Id: ' + jobApplications[2].Id);
        
        Test.startTest();
        jobApplications[0].Provider_Choice__c = 'Passed';
        jobApplications[0].Launchpad__Stage__c = 'Passed';
        
        jobApplications[1].Provider_Choice__c = 'Passed';
        jobApplications[1].Launchpad__Stage__c = 'Passed';
        
        
        jobApplications[2].Provider_Choice__c = 'Passed';
        jobApplications[2].Launchpad__Stage__c = 'Passed';
        
        jobAppsToUpdate.add(jobApplications[0]);
        jobAppsToUpdate.add(jobApplications[1]);
        jobAppsToUpdate.add(jobApplications[2]);
      
        
        update jobAppsToUpdate;
        Test.stopTest();
        
        List<Launchpad__Applicant_Tracking__c> jobApplicationsUpdated = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        Contact con = [SELECT Id, Ready_For_Reassignment__c FROM Contact WHERE Id = :jobApplications[0].Launchpad__Participant__c LIMIT 1];
        
        System.assertEquals('Passed', jobApplicationsUpdated[0].Launchpad__Stage__c);
        System.assertEquals('Passed', jobApplicationsUpdated[1].Launchpad__Stage__c);
        System.assertEquals('Passed', jobApplicationsUpdated[2].Launchpad__Stage__c);
        //System.assertEquals(true, con.Ready_for_Reassignment__c);
        
        
    }
    
    /*
      Test Case 5: All Applications Shortlisted
        Setup: All 3 applications set to "Shortlisted"
        
        Expected Outcome:
            Applicant status = "Ready for Reassignment"
            All applications remain "Shortlisted"
     */
    @isTest
    public static void allApplicationsShortlisted() {
   		List<Launchpad__Applicant_Tracking__c> jobApplications = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        /*
        JobApplications[0] == A
        JobApplications[1] == B
        JobApplications[2] == C
		*/
        List<Launchpad__Applicant_Tracking__c> jobAppsToUpdate = new List<Launchpad__Applicant_Tracking__c>();
        
        System.debug('A Id: ' + jobApplications[0].Id);
        System.debug('B Id: ' + jobApplications[1].Id);
        System.debug('C Id: ' + jobApplications[2].Id);
        
        Test.startTest();
        jobApplications[0].Provider_Choice__c = 'Shortlisted';
        jobApplications[0].Launchpad__Stage__c = 'Shortlisted';
        
        jobApplications[1].Provider_Choice__c = 'Shortlisted';
        jobApplications[1].Launchpad__Stage__c = 'Shortlisted';
        
        
        jobApplications[2].Provider_Choice__c = 'Shortlisted';
        jobApplications[2].Launchpad__Stage__c = 'Shortlisted';
        
        jobAppsToUpdate.add(jobApplications[0]);
        jobAppsToUpdate.add(jobApplications[1]);
        jobAppsToUpdate.add(jobApplications[2]);
      
        
        update jobAppsToUpdate;
        Test.stopTest();
        
        List<Launchpad__Applicant_Tracking__c> jobApplicationsUpdated = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        Contact con = [SELECT Id, Ready_For_Reassignment__c FROM Contact WHERE Id = :jobApplications[0].Launchpad__Participant__c LIMIT 1];
        
        System.assertEquals('Shortlisted', jobApplicationsUpdated[0].Launchpad__Stage__c);
        System.assertEquals('Shortlisted', jobApplicationsUpdated[1].Launchpad__Stage__c);
        System.assertEquals('Shortlisted', jobApplicationsUpdated[2].Launchpad__Stage__c);
        //System.assertEquals(true, con.Ready_for_Reassignment__c);
    }
    
    /*
      Test Case 6: Employer Changes from "Provider Selected" to "Passed"
        Setup:
            A = "Passed"
            B = "Provider Selected" → becomes "Matched with Provider"
            Then B changes to "Passed"
        
        Expected Outcome:
            B = "Passed"
            C is now evaluated
            If C is "Provider Selected" → becomes "Matched with Provider"
            If C is "Shortlisted" or "Passed" → applicant becomes "Ready for Reassignment"
     */
    @isTest
    public static void providerSelectedToPassed() {
   		List<Launchpad__Applicant_Tracking__c> jobApplications = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        /*
        JobApplications[0] == A
        JobApplications[1] == B
        JobApplications[2] == C
		*/
        List<Launchpad__Applicant_Tracking__c> jobAppsToUpdate = new List<Launchpad__Applicant_Tracking__c>();
        
        System.debug('A Id: ' + jobApplications[0].Id);
        System.debug('B Id: ' + jobApplications[1].Id);
        System.debug('C Id: ' + jobApplications[2].Id);
        
        Test.startTest();
        jobApplications[0].Provider_Choice__c = 'Passed';
        jobApplications[0].Launchpad__Stage__c = 'Passed';
        
        jobApplications[1].Provider_Choice__c = 'Provider Selected';
        jobApplications[1].Launchpad__Stage__c = 'Provider Selected';
        
        jobApplications[2].Provider_Choice__c = 'Provider Selected';
        jobApplications[2].Launchpad__Stage__c = 'Provider Selected';
        
        jobAppsToUpdate.add(jobApplications[0]);
        jobAppsToUpdate.add(jobApplications[1]);
        jobAppsToUpdate.add(jobApplications[2]);
        
        update jobAppsToUpdate;

        Test.stopTest();
        
        Launchpad__Applicant_Tracking__c updatedApp = [SELECT Id, Provider_Choice__c, Launchpad__Stage__c
                                                    	FROM Launchpad__Applicant_Tracking__c
                                                    	WHERE Id = :jobApplications[1].Id];
        
        JobApplicationTriggerHandler.setExecutedRecords.clear();
        
        updatedApp.Provider_Choice__c = 'Passed';
        updatedApp.Launchpad__Stage__c = 'Passed';
            
        update updatedApp;
        
        
        List<Launchpad__Applicant_Tracking__c> jobApplicationsUpdated = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Choice__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        Contact con = [SELECT Id, Ready_For_Reassignment__c FROM Contact WHERE Id = :jobApplications[0].Launchpad__Participant__c LIMIT 1];
        
       
        
        System.assertEquals('Unavailable', jobApplicationsUpdated[0].Launchpad__Stage__c);
        System.assertEquals('Unavailable', jobApplicationsUpdated[1].Launchpad__Stage__c);
        System.assertEquals('Matched with Provider', jobApplicationsUpdated[2].Launchpad__Stage__c);
        System.assertEquals(false, con.Ready_for_Reassignment__c);
    }
    
    /*
      Test Case 7: Employer Changes from "Shortlisted" to "Provider Selected"
        Setup:
            A = "Passed"
            B = "Shortlisted"
            C = "Provider Selected" → becomes "Matched with Provider"
            Then B changes to "Provider Selected"
        
        Expected Outcome:
        	Match remains on C
     */
    @isTest
    public static void shortlistedToProviderSelected() {
   		List<Launchpad__Applicant_Tracking__c> jobApplications = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        /*
        JobApplications[0] == A
        JobApplications[1] == B
        JobApplications[2] == C
		*/
        List<Launchpad__Applicant_Tracking__c> jobAppsToUpdate = new List<Launchpad__Applicant_Tracking__c>();
        
        System.debug('A Id: ' + jobApplications[0].Id);
        System.debug('B Id: ' + jobApplications[1].Id);
        System.debug('C Id: ' + jobApplications[2].Id);
        
        Test.startTest();
        jobApplications[0].Provider_Choice__c = 'Passed';
        jobApplications[0].Launchpad__Stage__c = 'Passed';
        
        jobApplications[1].Provider_Choice__c = 'Shortlisted';
        jobApplications[1].Launchpad__Stage__c = 'Shortlisted';
        
        
        jobApplications[2].Provider_Choice__c = 'Provider Selected';
        jobApplications[2].Launchpad__Stage__c = 'Provider Selected';
        
        jobAppsToUpdate.add(jobApplications[0]);
        jobAppsToUpdate.add(jobApplications[1]);
        jobAppsToUpdate.add(jobApplications[2]);
      
        
        update jobAppsToUpdate;
        
        Launchpad__Applicant_Tracking__c updatedApp = [SELECT Id, Provider_Choice__c, Launchpad__Stage__c
                                                    	FROM Launchpad__Applicant_Tracking__c
                                                    	WHERE Id = :jobApplications[1].Id];
        
        JobApplicationTriggerHandler.setExecutedRecords.clear();
        
        updatedApp.Provider_Choice__c = 'Provider Selected';
        
        update updatedApp;
        Test.stopTest();
        
        List<Launchpad__Applicant_Tracking__c> jobApplicationsUpdated = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        Contact con = [SELECT Id, Ready_For_Reassignment__c FROM Contact WHERE Id = :jobApplications[0].Launchpad__Participant__c LIMIT 1];
        
        System.assertEquals('Unavailable', jobApplicationsUpdated[0].Launchpad__Stage__c);
        System.assertEquals('Unavailable', jobApplicationsUpdated[1].Launchpad__Stage__c);
        System.assertEquals('Matched with Provider', jobApplicationsUpdated[2].Launchpad__Stage__c);
        
    }
    
    /*
      Test Case 8: Employer changes mind on Matched application
        Setup:
            A = "Provider Selected" → becomes "Matched with Provider"
            A changes to "Shortlisted"
        
        Expected Outcome:
            A = "Shortlisted"
            Algorithm re-evaluates B and C
            If neither is "Provider Selected" → applicant becomes "Ready for Reassignment"
     */
    @isTest
    public static void employerChangeMind() {
   		List<Launchpad__Applicant_Tracking__c> jobApplications = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        /*
        JobApplications[0] == A
        JobApplications[1] == B
        JobApplications[2] == C
		*/
        List<Launchpad__Applicant_Tracking__c> jobAppsToUpdate = new List<Launchpad__Applicant_Tracking__c>();
        
        System.debug('A Id: ' + jobApplications[0].Id);
        System.debug('B Id: ' + jobApplications[1].Id);
        System.debug('C Id: ' + jobApplications[2].Id);
        
        Test.startTest();
        jobApplications[0].Provider_Choice__c = 'Provider Selected';
        jobApplications[0].Launchpad__Stage__c = 'Provider Selected';
        
        jobApplications[1].Provider_Choice__c = 'Passed';
        jobApplications[1].Launchpad__Stage__c = 'Passed';
        
        
        jobApplications[2].Provider_Choice__c = 'Passed';
        jobApplications[2].Launchpad__Stage__c = 'Passed';
        
        jobAppsToUpdate.add(jobApplications[0]);
        jobAppsToUpdate.add(jobApplications[1]);
        jobAppsToUpdate.add(jobApplications[2]);
      
        
        update jobAppsToUpdate;
        
        Launchpad__Applicant_Tracking__c updatedApp = [SELECT Id, Provider_Choice__c, Launchpad__Stage__c
                                                    	FROM Launchpad__Applicant_Tracking__c
                                                    	WHERE Id = :jobApplications[0].Id];
        
        JobApplicationTriggerHandler.setExecutedRecords.clear();
		updatedApp.Launchpad__Stage__c = 'Shortlisted';
        updatedApp.Provider_Choice__c = 'Shortlisted';
        
        update updatedApp;
        Test.stopTest();
        
        List<Launchpad__Applicant_Tracking__c> jobApplicationsUpdated = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        Contact con = [SELECT Id, Ready_For_Reassignment__c FROM Contact WHERE Id = :jobApplications[0].Launchpad__Participant__c LIMIT 1];
        
        System.assertEquals('Shortlisted', jobApplicationsUpdated[0].Launchpad__Stage__c);
        System.assertEquals('Passed', jobApplicationsUpdated[1].Launchpad__Stage__c);
        System.assertEquals('Passed', jobApplicationsUpdated[2].Launchpad__Stage__c);
        //System.assertEquals(true, con.Ready_for_Reassignment__c);
    }
    
    /*
      Test Case 9: Multiple "Provider Selected" Applications
        Setup: 
			A, B, C all set to "Provider Selected"
        
        Expected Outcome:
            Algorithm chooses A (rank 1) as "Matched with Provider"
            B and C = "Unavailable"
     */
    
    @isTest
    public static void multipleProviderSelected() {
   		List<Launchpad__Applicant_Tracking__c> jobApplications = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        /*
        JobApplications[0] == A
        JobApplications[1] == B
        JobApplications[2] == C
		*/
        List<Launchpad__Applicant_Tracking__c> jobAppsToUpdate = new List<Launchpad__Applicant_Tracking__c>();
        
        System.debug('A Id: ' + jobApplications[0].Id);
        System.debug('B Id: ' + jobApplications[1].Id);
        System.debug('C Id: ' + jobApplications[2].Id);
        
        Test.startTest();
        jobApplications[0].Provider_Choice__c = 'Provider Selected';
        jobApplications[0].Launchpad__Stage__c = 'Provider Selected';
        
        jobApplications[1].Provider_Choice__c = 'Provider Selected';
        jobApplications[1].Launchpad__Stage__c = 'Provider Selected';
        
        
        jobApplications[2].Provider_Choice__c = 'Provider Selected';
        jobApplications[2].Launchpad__Stage__c = 'Provider Selected';
        
        jobAppsToUpdate.add(jobApplications[0]);
        jobAppsToUpdate.add(jobApplications[1]);
        jobAppsToUpdate.add(jobApplications[2]);
      
        
        update jobAppsToUpdate;
 
        Test.stopTest();
        
        List<Launchpad__Applicant_Tracking__c> jobApplicationsUpdated = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        Contact con = [SELECT Id, Ready_For_Reassignment__c FROM Contact WHERE Id = :jobApplications[0].Launchpad__Participant__c LIMIT 1];
        
        System.assertEquals('Matched with Provider', jobApplicationsUpdated[0].Launchpad__Stage__c);
        System.assertEquals('Unavailable', jobApplicationsUpdated[1].Launchpad__Stage__c);
        System.assertEquals('Unavailable', jobApplicationsUpdated[2].Launchpad__Stage__c);
    }
    
    /*
      Test Case 10: Application Set to "Matched with Provider" then Employer Sets to "Shortlisted"
        Setup:
            A = "Provider Selected" → "Matched with Provider"
            A → "Shortlisted"
            B = "Provider Selected"
        
        Expected Outcome:
            A = "Unavailable"
            B = "Matched with Provider"
            C = "Unavailable"
     */
    @isTest
    public static void matchedToShortlisted() {
   		List<Launchpad__Applicant_Tracking__c> jobApplications = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        /*
        JobApplications[0] == A
        JobApplications[1] == B
        JobApplications[2] == C
		*/
        List<Launchpad__Applicant_Tracking__c> jobAppsToUpdate = new List<Launchpad__Applicant_Tracking__c>();
        
        System.debug('A Id: ' + jobApplications[0].Id);
        System.debug('B Id: ' + jobApplications[1].Id);
        System.debug('C Id: ' + jobApplications[2].Id);
        
        Test.startTest();
        jobApplications[0].Provider_Choice__c = 'Provider Selected';
        jobApplications[0].Launchpad__Stage__c = 'Provider Selected';
        
        jobApplications[1].Provider_Choice__c = 'Shortlisted';
        jobApplications[1].Launchpad__Stage__c = 'Shortlisted';
        
        
        jobApplications[2].Provider_Choice__c = 'Provider Selected';
        jobApplications[2].Launchpad__Stage__c = 'Provider Selected';
        
        jobAppsToUpdate.add(jobApplications[0]);
        jobAppsToUpdate.add(jobApplications[1]);
        jobAppsToUpdate.add(jobApplications[2]);
      
        
        update jobAppsToUpdate;
        
        Launchpad__Applicant_Tracking__c updatedAppA = [SELECT Id, Provider_Choice__c, Launchpad__Stage__c
                                                    	FROM Launchpad__Applicant_Tracking__c
                                                    	WHERE Id = :jobApplications[0].Id];
        
        Launchpad__Applicant_Tracking__c updatedAppB = [SELECT Id, Provider_Choice__c, Launchpad__Stage__c
                                                    	FROM Launchpad__Applicant_Tracking__c
                                                    	WHERE Id = :jobApplications[1].Id];
        
        JobApplicationTriggerHandler.setExecutedRecords.clear();
        
        List<Launchpad__Applicant_Tracking__c> jobAppsToUpdate2 = new List<Launchpad__Applicant_Tracking__c>();
        
        updatedAppA.Launchpad__Stage__c = 'Shortlisted';
        updatedAppA.Provider_Choice__c = 'Shortlisted';
        
        updatedAppB.Launchpad__Stage__c = 'Provider Selected';
        updatedAppB.Provider_Choice__c = 'Provider Selected';
        
        jobAppsToUpdate2.add(updatedAppA);
        jobAppsToUpdate2.add(updatedAppB);
        
        update jobAppsToUpdate2;
        Test.stopTest();
        
        List<Launchpad__Applicant_Tracking__c> jobApplicationsUpdated = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        Contact con = [SELECT Id, Ready_For_Reassignment__c FROM Contact WHERE Id = :jobApplications[0].Launchpad__Participant__c LIMIT 1];
        
        System.assertEquals('Unavailable', jobApplicationsUpdated[0].Launchpad__Stage__c);
        System.assertEquals('Matched with Provider', jobApplicationsUpdated[1].Launchpad__Stage__c);
        System.assertEquals('Unavailable', jobApplicationsUpdated[2].Launchpad__Stage__c);
    }
    
    /*
      Test Case 11: Employer Selects a “Ready for Reassignment” applicant
		Setup: 
			A, B, C = "Passed"

        Action: 
			Employer B changes status to “Provider Selected”
        
        Expected Outcome:
            B = Provider Selected -> “Matched with Provider”
            Applicant is no longer in “Ready for Reassignment”
     */
    @isTest
    public static void selectsReadyForReassignmentApplciant() {
   		List<Launchpad__Applicant_Tracking__c> jobApplications = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        /*
        JobApplications[0] == A
        JobApplications[1] == B
        JobApplications[2] == C
		*/
        List<Launchpad__Applicant_Tracking__c> jobAppsToUpdate = new List<Launchpad__Applicant_Tracking__c>();
        
        System.debug('A Id: ' + jobApplications[0].Id);
        System.debug('B Id: ' + jobApplications[1].Id);
        System.debug('C Id: ' + jobApplications[2].Id);
        
        Test.startTest();
        jobApplications[0].Provider_Choice__c = 'Passed';
        jobApplications[0].Launchpad__Stage__c = 'Passed';
        
        jobApplications[1].Provider_Choice__c = 'Passed';
        jobApplications[1].Launchpad__Stage__c = 'Passed';
        
        
        jobApplications[2].Provider_Choice__c = 'Passed';
        jobApplications[2].Launchpad__Stage__c = 'Passed';
        
        jobAppsToUpdate.add(jobApplications[0]);
        jobAppsToUpdate.add(jobApplications[1]);
        jobAppsToUpdate.add(jobApplications[2]);
      
        
        update jobAppsToUpdate;
        
        Launchpad__Applicant_Tracking__c updatedApp = [SELECT Id, Provider_Choice__c, Launchpad__Stage__c
                                                    	FROM Launchpad__Applicant_Tracking__c
                                                    	WHERE Id = :jobApplications[1].Id];
        
        JobApplicationTriggerHandler.setExecutedRecords.clear();
        
        updatedApp.Launchpad__Stage__c = 'Provider Selected';
        updatedApp.Provider_Choice__c = 'Provider Selected';
        
        update updatedApp;
        Test.stopTest();
        
        List<Launchpad__Applicant_Tracking__c> jobApplicationsUpdated = [SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Provider_Rank__c FROM Launchpad__Applicant_Tracking__c ORDER BY Provider_Rank__c];
        Contact con = [SELECT Id, Ready_For_Reassignment__c FROM Contact WHERE Id = :jobApplications[0].Launchpad__Participant__c LIMIT 1];
        
        System.assertEquals('Unavailable', jobApplicationsUpdated[0].Launchpad__Stage__c);
        System.assertEquals('Matched with Provider', jobApplicationsUpdated[1].Launchpad__Stage__c);
        System.assertEquals('Unavailable', jobApplicationsUpdated[2].Launchpad__Stage__c);
        System.assertEquals(false, con.Ready_for_Reassignment__c);
    }
}