@isTest
public class JobApplicationConsentFormControllerTest {
	@testSetup
	static void setupTestData() {
		Account testAccount = new Account(Name = 'Test Account', Industry = 'Technology', Phone = '123-456-7890');
		insert testAccount;

		List<Contact> contacts = new List<Contact>();
		for (Integer i = 0; i < 5; i++) {
			contacts.add(new Contact(FirstName = 'Test', LastName = 'Participant ' + i));
		}
		insert contacts;

		RecordType sessionRecordType = [
			SELECT Id
			FROM RecordType
			WHERE SobjectType = 'Launchpad__Program__c' AND Name = 'Session'
			LIMIT 1
		];

		Launchpad__Program__c program = new Launchpad__Program__c(
			Name = 'Test Program',
			Launchpad__Active__c = 'Yes',
			RecordTypeId = sessionRecordType.Id
		);
		insert program;

		List<Launchpad__Applicant_Tracking__c> jobApplications = new List<Launchpad__Applicant_Tracking__c>();

		Launchpad__Job__c job = new Launchpad__Job__c();
		job.Launchpad__Openings__c = 10;
		job.Launchpad__Account__c = testAccount.Id;
		job.Launchpad__Stage__c = 'Interviewing';
		job.Launchpad__Closing_Date__c = Date.today();
		job.Launchpad__Source__c = 'Direct Employer Contact';
		job.Launchpad__Hourly_Wage_Minimum__c = 30.00;
		job.Launchpad__Hourly_Wage_Maximum__c = 60.00;
		job.Program__c = program.Id;

		insert job;

		for (Integer i = 0; i < 5; i++) {
			if (i == 0) {
				Launchpad__Applicant_Tracking__c firstApp = new Launchpad__Applicant_Tracking__c();
				firstApp.Launchpad__Participant__c = contacts[0].Id;
				firstApp.Launchpad__Stage__c = 'Submitted';
				firstApp.Provider_Rank__c = '1';
				firstApp.Previous_Stage__c = 'Provider Selected';
				firstApp.Launchpad__Job_Order__c = job.Id;
				firstApp.Applicant_s_Email_Address__c = 'Test12@test12345.com';
				firstApp.Guardian_Email__c = 'Test@test.com';
				jobApplications.add(firstApp);
			} else {
				jobApplications.add(
					new Launchpad__Applicant_Tracking__c(
						Launchpad__Participant__c = contacts[0].Id,
						Launchpad__Stage__c = 'Submitted',
						Provider_Rank__c = String.ValueOf(i + 1),
						Previous_Stage__c = 'Provider Selected',
						Launchpad__Job_Order__c = job.Id,
						Applicant_s_Email_Address__c = 'Test12@test12345.com',
						Guardian_Email__c = 'Test2@test.com'
					)
				);
			}
		}

		insert jobApplications;
	}

	// TODO: Include test apps without guardian emails

	@isTest
	public static void testEmail() {
		List<List<Id>> input = new List<List<Id>>();
		List<Id> appIds = new List<Id>();
		for (Launchpad__Applicant_Tracking__c app : [
			SELECT Id, Guardian_Email__c
			FROM Launchpad__Applicant_Tracking__c
			WHERE Applicant_s_Email_Address__c != NULL AND Guardian_Email__c != NULL
		]) {
			appIds.add(app.Id);
		}

		input.add(appIds);

		JobApplicationConsentFormController.sendConsentFormEmail(input);
	}
}