@isTest
public class JobApplicationTriggerHandlerTest {
	@testSetup
	static void setupTestData() {
		RecordType sessionRecordType = [
			SELECT Id
			FROM RecordType
			WHERE SObjectType = 'Launchpad__Program__c' AND Name = 'Session'
			LIMIT 1
		];

		Account testAccount = new Account(Name = 'Test Account', Industry = 'Technology', Phone = '123-456-7890');
		insert testAccount;

		List<Contact> contacts = new List<Contact>();
		for (Integer i = 0; i < 5; i++) {
			contacts.add(
				new Contact(
					FirstName = 'Test',
					LastName = 'Participant ' + i,
					Email = 'giuebhfiuehbfe@greoikjbfwen.com'
				)
			);
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

		for (Integer i = 0; i < 5; i++) {
			if (i == 0) {
				Launchpad__Applicant_Tracking__c firstApp = new Launchpad__Applicant_Tracking__c();
				firstApp.Launchpad__Participant__c = contacts[0].Id;
				firstApp.Launchpad__Stage__c = 'Submitted';
				firstApp.Provider_Rank__c = '1';
				firstApp.Previous_Stage__c = 'Provider Selected';
				firstApp.Launchpad__Job_Order__c = job.Id;
				firstApp.Applicants_Tax_Id__c = '236-33-534' + String.valueOf(i);
				firstApp.Applicant_s_Email_Address__c = 'Test12@test12345.com';
				firstApp.Emergency_Contact_Email__c = 'gegeggegege@rhefgeheg.com';
				firstApp.Program__c = program.Id;
				jobApplications.add(firstApp);
			} else {
				jobApplications.add(
					new Launchpad__Applicant_Tracking__c(
						Launchpad__Participant__c = contacts[0].Id,
						Launchpad__Stage__c = 'Submitted',
						Provider_Rank__c = String.ValueOf(i + 1),
						Previous_Stage__c = 'Provider Selected',
						Launchpad__Job_Order__c = job.Id,
						Applicants_Tax_Id__c = '236-33-5342',
						Applicant_s_Email_Address__c = 'Test12@test12345.com',
						Emergency_Contact_Email__c = 'gegeggegege@rhefgeheg.com',
						Program__c = program.Id
					)
				);
			}
			jobApplications.add(
				new Launchpad__Applicant_Tracking__c(
					Launchpad__Participant__c = contacts[1].Id,
					Launchpad__Stage__c = 'Submitted',
					Provider_Rank__c = String.ValueOf(i + 1),
					Previous_Stage__c = 'Provider Selected',
					Launchpad__Job_Order__c = job.Id,
					Applicants_Tax_Id__c = '236-33-5142',
					Applicant_s_Email_Address__c = 'Test12@test12345.com',
					Emergency_Contact_Email__c = 'gegeggegege@rhefgeheg.com',
					Program__c = program.Id
				)
			);
		}

		insert jobApplications;
	}

	@isTest
	static void testMatchProvider() {
		List<Launchpad__Applicant_Tracking__c> jobApplications = [
			SELECT Id, Launchpad__Participant__c, Launchpad__Stage__c, Previous_Stage__c, Provider_Rank__c
			FROM Launchpad__Applicant_Tracking__c
			ORDER BY Provider_Rank__c
		];

		Test.startTest();
		jobApplications[0].launchpad__Stage__c = 'Provider Selected';
		update jobApplications[0];
		Test.stopTest();

		List<Launchpad__Applicant_Tracking__c> jobApplicationsMatched = [
			SELECT
				Id,
				Launchpad__Participant__c,
				Launchpad__Job_Order__c,
				Launchpad__Stage__c,
				Previous_Stage__c,
				Provider_Rank__c
			FROM Launchpad__Applicant_Tracking__c
			WHERE Launchpad__Stage__c = 'Matched with Provider'
			ORDER BY Provider_Rank__c
		];
		System.debug(jobApplicationsMatched);
		Launchpad__Applicant_Tracking__c firstApp = new Launchpad__Applicant_Tracking__c();
		firstApp.Launchpad__Participant__c = jobApplicationsMatched[0].Launchpad__Participant__c;
		firstApp.Launchpad__Stage__c = 'Submitted';
		firstApp.Provider_Rank__c = '1';
		firstApp.Previous_Stage__c = 'Provider Selected';
		firstApp.Launchpad__Job_Order__c = jobApplicationsMatched[0].Launchpad__Job_Order__c;
		firstApp.Applicant_s_Email_Address__c = 'Test12@test12345.com';
		insert firstApp;

		jobApplicationsMatched[0].launchpad__Stage__c = 'Passed';
		update jobApplicationsMatched[0];
		List<Launchpad__Applicant_Tracking__c> updatedJobApplications = [
			SELECT Id, Launchpad__Stage__c, Previous_Stage__c
			FROM Launchpad__Applicant_Tracking__c
		];

		for (Launchpad__Applicant_Tracking__c app : updatedJobApplications) {
			System.debug(app.Launchpad__Stage__c);
		}

		System.assertEquals(11, updatedJobApplications.size());
	}

	@isTest
	static void testMatchProviderErrorHandling() {
	}
}