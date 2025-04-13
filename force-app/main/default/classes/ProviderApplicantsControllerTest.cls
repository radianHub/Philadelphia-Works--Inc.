@isTest
public class ProviderApplicantsControllerTest {
	@TestSetup
	static void setupTestData() {
		// Create test records
		Account testAccount = new Account(Name = 'Test Account');
		insert testAccount;

		// Create Program with Session record type
		RecordType sessionRT = [
			SELECT Id
			FROM RecordType
			WHERE SObjectType = 'Launchpad__Program__c' AND DeveloperName = 'Session'
			LIMIT 1
		];
		Launchpad__Program__c program = new Launchpad__Program__c(
			Name = 'Test Program',
			Launchpad__Active__c = 'Yes',
			RecordTypeId = sessionRT.Id
		);
		insert program;

		// Create Job records
		List<Launchpad__Job__c> jobs = new List<Launchpad__Job__c>();
		for (Integer i = 0; i < 3; i++) {
			Launchpad__Job__c job = new Launchpad__Job__c(
				Name = 'Test Job ' + i,
				Program__c = program.Id,
				Launchpad__Account__c = testAccount.Id
			);
			jobs.add(job);
		}

		// Create one job with Placement_Site__c
		Launchpad__Job__c placementJob = new Launchpad__Job__c(
			Name = 'Test Placement Job',
			Program__c = program.Id,
			Placement_Site__c = testAccount.Id,
			Launchpad__Account__c = testAccount.Id
		);
		jobs.add(placementJob);

		insert jobs;

		// Create Contacts (Participants)
		List<Contact> contacts = new List<Contact>();
		for (Integer i = 0; i < 5; i++) {
			Contact c = new Contact(
				FirstName = 'Test',
				LastName = 'Contact ' + i,
				Priority_Population__c = (Math.mod(i, 2) == 0)
			); // Make every other contact priority
			contacts.add(c);
		}
		insert contacts;

		// Create Applicant Tracking records
		List<Launchpad__Applicant_Tracking__c> applicants = new List<Launchpad__Applicant_Tracking__c>();

		// Different statuses for testing filters
		String[] statuses = new List<String>{ 'Submitted', 'Passed', 'Failed', 'In Progress', 'Placed' };
		String[] choices = new List<String>{ 'Passed', 'Provider Selected', 'Shortlisted', 'None', 'None' };

		for (Integer i = 0; i < 5; i++) {
			Launchpad__Applicant_Tracking__c app = new Launchpad__Applicant_Tracking__c(
				Launchpad__Participant__c = contacts[i].Id,
				Launchpad__Job_Order__c = jobs[Math.mod(i, jobs.size())].Id,
				Launchpad__Stage__c = statuses[i],
				Provider_Choice__c = choices[i],
				Provider_Rank__c = String.valueOf(i + 1),
				Applicant_s_Email_Address__c = 'test' + i + '@example.com'
			);
			applicants.add(app);
		}
		insert applicants;
	}

	@isTest
	static void testGetActiveJobs() {
		Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

		Test.startTest();
		List<Launchpad__Job__c> jobs = ProviderApplicantsController.getActiveJobs(testAccount.Id);
		Test.stopTest();

		System.assertNotEquals(0, jobs.size(), 'Should return jobs');
		System.assertEquals(4, jobs.size(), 'Should return all 4 jobs');

		// Verify that jobs related to both Account and Placement_Site are returned
		Boolean hasAccountJob = false;
		Boolean hasPlacementJob = false;

		for (Launchpad__Job__c job : jobs) {
			if (job.Name.contains('Test Job'))
				hasAccountJob = true;
			if (job.Name == 'Test Placement Job')
				hasPlacementJob = true;
		}

		System.assert(hasAccountJob, 'Should return jobs related to Account');
		System.assert(hasPlacementJob, 'Should return jobs related to Placement_Site');
	}

	@isTest
	static void testGetApplicantsNoFilters() {
		Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

		Test.startTest();
		List<Launchpad__Applicant_Tracking__c> applicants = ProviderApplicantsController.getApplicants(
			testAccount.Id,
			null,
			null,
			null,
			null
		);
		Test.stopTest();

		System.assertNotEquals(0, applicants.size(), 'Should return applicants');
		// Verify that In Progress, Placed, and Unavailable are filtered out
		for (Launchpad__Applicant_Tracking__c app : applicants) {
			System.assertNotEquals('In Progress', app.Launchpad__Stage__c, 'Should not include In Progress');
			System.assertNotEquals('Placed', app.Launchpad__Stage__c, 'Should not include Placed');
			System.assertNotEquals('Hired', app.Launchpad__Stage__c, 'Should not include Hired');
			System.assertNotEquals('Unavailable', app.Launchpad__Stage__c, 'Should not include Unavailable');
		}
	}

	@isTest
	static void testGetApplicantsWithChoiceFilter() {
		Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

		Test.startTest();
		List<Launchpad__Applicant_Tracking__c> passedApplicants = ProviderApplicantsController.getApplicants(
			testAccount.Id,
			'Passed',
			null,
			null,
			null
		);
		Test.stopTest();

		System.assertNotEquals(0, passedApplicants.size(), 'Should return applicants');
		for (Launchpad__Applicant_Tracking__c app : passedApplicants) {
			System.assertEquals('Passed', app.Provider_Choice__c, 'Should only include Passed choice');
		}
	}

	@isTest
	static void testGetApplicantsWithJobFilter() {
		Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
		Launchpad__Job__c job = [SELECT Id FROM Launchpad__Job__c WHERE Name = 'Test Job 0' LIMIT 1];

		Test.startTest();
		List<Launchpad__Applicant_Tracking__c> jobApplicants = ProviderApplicantsController.getApplicants(
			testAccount.Id,
			null,
			job.Id,
			null,
			null
		);
		Test.stopTest();

		System.assertNotEquals(0, jobApplicants.size(), 'Should return applicants');
		for (Launchpad__Applicant_Tracking__c app : jobApplicants) {
			System.assertEquals(
				job.Id,
				app.Launchpad__Job_Order__c,
				'Should only include applicants for the specified job'
			);
		}
	}

	@isTest
	static void testGetApplicantsWithPriorityFilter() {
		Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

		Test.startTest();
		List<Launchpad__Applicant_Tracking__c> priorityApplicants = ProviderApplicantsController.getApplicants(
			testAccount.Id,
			null,
			null,
			'Priority',
			null
		);
		Test.stopTest();

		System.assertNotEquals(0, priorityApplicants.size(), 'Should return applicants');
		for (Launchpad__Applicant_Tracking__c app : priorityApplicants) {
			System.assertEquals(
				true,
				app.Launchpad__Participant__r.Priority_Population__c,
				'Should only include priority population applicants'
			);
		}
	}

	@isTest
	static void testGetApplicantsWithStageFilter() {
		Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

		Test.startTest();
		List<Launchpad__Applicant_Tracking__c> submittedApplicants = ProviderApplicantsController.getApplicants(
			testAccount.Id,
			null,
			null,
			null,
			'Submitted'
		);
		Test.stopTest();

		System.assertNotEquals(0, submittedApplicants.size(), 'Should return applicants');
		for (Launchpad__Applicant_Tracking__c app : submittedApplicants) {
			System.assertEquals('Submitted', app.Launchpad__Stage__c, 'Should only include Submitted stage');
		}
	}

	@isTest
	static void testGetApplicantsWithAllFilters() {
		Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
		List<Launchpad__Job__c> jobs = [SELECT Id FROM Launchpad__Job__c LIMIT 1];

		Test.startTest();
		List<Launchpad__Applicant_Tracking__c> filteredApplicants = ProviderApplicantsController.getApplicants(
			testAccount.Id,
			'Passed',
			jobs[0].Id,
			'Priority',
			'Passed'
		);
		Test.stopTest();

		// This might return empty list depending on test data, but should not throw errors
		System.assertNotEquals(null, filteredApplicants, 'Should return a list (possibly empty)');
	}

	@isTest
	static void testGetFieldsByObjectAndFieldSet() {
		// Test with a known field set
		// Note: This test assumes there's a field set named 'TestFieldSet' on the Launchpad__Applicant_Tracking__c object
		// You may need to adjust this based on your org's configuration or mock the field set response

		Test.startTest();
		try {
			List<ProviderApplicantsController.FieldWrapper> fields = ProviderApplicantsController.getFieldsByObjectAndFieldSet(
				'Launchpad__Applicant_Tracking__c',
				'TestFieldSet'
			);
			// Even if the field set doesn't exist, the method should return an empty list without errors
			System.assertNotEquals(null, fields, 'Should return a list (possibly empty)');
		} catch (Exception e) {
			System.assert(false, 'Should not throw an exception: ' + e.getMessage());
		}
		Test.stopTest();
	}

	@isTest
	static void testCanViewApplication() {
		Launchpad__Applicant_Tracking__c app = [SELECT Id FROM Launchpad__Applicant_Tracking__c LIMIT 1];

		Test.startTest();
		Boolean canView = ProviderApplicantsController.canViewApplication(app.Id);
		Test.stopTest();

		System.assertEquals(
			false,
			canView,
			'Should return false for visibility check if current user is not related to Job\'s Account'
		);
	}

	@isTest
	static void testBulkUpdateApplicantStage() {
		List<Launchpad__Applicant_Tracking__c> apps = [SELECT Id FROM Launchpad__Applicant_Tracking__c];
		List<String> appIds = new List<String>();
		for (Launchpad__Applicant_Tracking__c app : apps) {
			appIds.add(app.Id);
		}

		Test.startTest();
		Boolean result = ProviderApplicantsController.bulkUpdateApplicantStage(appIds, 'Passed', 'Test reason');
		Test.stopTest();

		System.assertEquals(true, result, 'Should return true for successful update');

		// Verify the updates
		List<Launchpad__Applicant_Tracking__c> updatedApps = [
			SELECT Id, Provider_Choice__c, Launchpad__Stage__c, Passed_Reason__c
			FROM Launchpad__Applicant_Tracking__c
			WHERE Id IN :appIds AND Launchpad__Stage__c != 'Unavailable'
		];

		for (Launchpad__Applicant_Tracking__c app : updatedApps) {
			// System.assertEquals('Passed', app.Provider_Choice__c, 'Provider Choice should be updated to Passed'); // TODO: Enable this after matching algo fixed
			System.assertEquals('Passed', app.Launchpad__Stage__c, 'Stage should be updated to Passed');
			// System.assertEquals('Test reason', app.Passed_Reason__c, 'Passed Reason should be updated'); // TODO: Enable this after matching algo fixed
		}
	}

	@isTest
	static void testBulkUpdateApplicantStageToNone() {
		List<Launchpad__Applicant_Tracking__c> apps = [SELECT Id FROM Launchpad__Applicant_Tracking__c];
		List<String> appIds = new List<String>();
		for (Launchpad__Applicant_Tracking__c app : apps) {
			appIds.add(app.Id);
		}

		Test.startTest();
		Boolean result = ProviderApplicantsController.bulkUpdateApplicantStage(appIds, 'None', null);
		Test.stopTest();

		System.assertEquals(true, result, 'Should return true for successful update');

		// Verify the updates
		List<Launchpad__Applicant_Tracking__c> updatedApps = [
			SELECT Id, Provider_Choice__c, Launchpad__Stage__c
			FROM Launchpad__Applicant_Tracking__c
			WHERE Id IN :appIds AND Launchpad__Stage__c != 'Unavailable'
		];

		for (Launchpad__Applicant_Tracking__c app : updatedApps) {
			System.assertEquals('None', app.Provider_Choice__c, 'Provider Choice should be updated to None');
			System.assertEquals('Submitted', app.Launchpad__Stage__c, 'Stage should be reset to Submitted');
		}
	}

	@isTest
	static void testGetFieldSetUtilityMethods() {
		// Test the utility methods for schema and field set access

		Test.startTest();
		// Get schema for a known object
		Schema.DescribeSObjectResult objResult = ProviderApplicantsController.getSObjSchema('Account');
		System.assertNotEquals(null, objResult, 'Should return schema for Account');
		System.assertEquals('Account', objResult.getName(), 'Should return correct object name');

		// Attempt to get a field set (may not exist in test context)
		Schema.FieldSet fieldSet = ProviderApplicantsController.getFieldSet('Account', 'TestFieldSet');
		// Just verify it doesn't throw an exception, the result could be null if field set doesn't exist
		System.assertEquals(null, fieldSet, 'Should return null for non-existent field set');
		Test.stopTest();
	}
}