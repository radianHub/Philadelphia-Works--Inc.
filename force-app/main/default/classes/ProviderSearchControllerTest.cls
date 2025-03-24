@IsTest
private class ProviderSearchControllerTest {

	@TestSetup
	static void createJobs() {
		List<Account> accounts = new List<Account>();
		accounts.add(new Account(Name = 'Test Account 1'));
        accounts.add(new Account(Name = 'Test Account 2', BillingPostalCode = '19104'));
		insert accounts;

		Launchpad__Program__c program = new Launchpad__Program__c(
			Name = 'Test Program 1',
			Launchpad__Active__c = 'Yes'
		);
		insert program;

		List<Launchpad__Job__c> jobs = new List<Launchpad__Job__c>();
		jobs.add(
			new Launchpad__Job__c(
				Name = 'Test Job 1',
				Launchpad__Account__c = accounts[0].Id,
				Launchpad__Available_in_Community__c = true,
				Program__c = program.Id,
				Launchpad__Job_Description__c = 'Test Description 1',
				Ages_Served__c = '12;13',
				Grades_Served__c = '7;8',
                Genders_Served__c = 'Male'
			)
		);
		jobs.add(
			new Launchpad__Job__c(
				Name = 'Test Job Zip 19104',
				Launchpad__Account__c = accounts[1].Id,
				Launchpad__Available_in_Community__c = true,
				Program__c = program.Id,
				Launchpad__Job_Description__c = 'Test Description 1',
				Ages_Served__c = '13;14',
				Grades_Served__c = '7;8',
                Genders_Served__c = 'Male'
			)
		);
        jobs.add(
			new Launchpad__Job__c(
				Name = 'Test Job 3',
				Launchpad__Account__c = accounts[0].Id,
				Launchpad__Available_in_Community__c = true,
				Program__c = program.Id,
				Launchpad__Job_Description__c = 'Test Description 1',
				Ages_Served__c = '13;14',
				Grades_Served__c = '6;7;8;',
                Genders_Served__c = 'Male'
			)
		);
        jobs.add(
			new Launchpad__Job__c(
				Name = 'Test Job AMY at James Martin',
				Launchpad__Account__c = accounts[0].Id,
				Launchpad__Available_in_Community__c = true,
				Program__c = program.Id,
				Launchpad__Job_Description__c = 'Test Description 1',
				Ages_Served__c = '13;14;15',
				Grades_Served__c = '7;8',
                Genders_Served__c = 'Male'
			)
		);
        jobs.add(
			new Launchpad__Job__c(
				Name = 'Test Job Females',
				Launchpad__Account__c = accounts[0].Id,
				Launchpad__Available_in_Community__c = true,
				Program__c = program.Id,
				Launchpad__Job_Description__c = 'Test Description 1',
				Ages_Served__c = '13;14',
				Grades_Served__c = '7;8',
                Genders_Served__c = 'Female'
			)
		);
        jobs.add(
			new Launchpad__Job__c(
				Name = 'Test Job Name Search',
				Launchpad__Account__c = accounts[0].Id,
				Launchpad__Available_in_Community__c = true,
				Program__c = program.Id,
				Launchpad__Job_Description__c = 'Test Description 4',
				Ages_Served__c = '13;14',
				Grades_Served__c = '9;10',
                Genders_Served__c = 'Male'
			)
		);
		insert jobs;
	}

    @IsTest
    static void testSearchByZipCode() {
		Test.startTest();
        List<Launchpad__Job__c> jobs = ProviderSearchController.searchJobsDynamic(
            '19104',
            null,
            null,
			null
        );
		Test.stopTest();
        Assert.areEqual(1, jobs.size());
        Assert.areEqual('Test Job Zip 19104', jobs[0].Name);
    }

	@IsTest
	static void testSearchByJobSiteAddress() {
		Test.startTest();
		List<Launchpad__Job__c> jobs = ProviderSearchController.searchJobsDynamic(
				null,
				null,
				new Map<String, String>{
						'Name' => 'Test Job Name'
				},
				null
		);
		Test.stopTest();
		Assert.areEqual(1, jobs.size());
		Assert.areEqual('Test Job Name Search', jobs[0].Name);
	}

	@IsTest
	static void testSearchByGradeAndAge() {
		Test.startTest();
		List<Launchpad__Job__c> jobs = ProviderSearchController.searchJobsDynamic(
				null,
				new List<String>{ 'Ages_Served__c', 'Grades_Served__c' },
				null,
				new Map<String, String[]>{
						'Ages_Served__c' => new String[]{ '12' },
						'Grades_Served__c' => new String[]{ '7', '8' }
				}
		);
		Test.stopTest();
		Assert.areEqual(1, jobs.size());
		Assert.areEqual('Test Job 1', jobs[0].Name);
	}

	@IsTest
	static void testGettingFieldSetMembers() {
		Test.startTest();
		ProviderSearchController.FieldData[] fieldData =
				ProviderSearchController.getJobFieldSetMembers('Launchpad__Advanced_Job_Search_Filters');
		Test.stopTest();
		Assert.isTrue(!fieldData.isEmpty());
	}

	@IsTest
	static void testGettingContactJobEligibilityMaps() {
		Test.startTest();
		ProviderSearchController.getContactJobEligibilityMaps();
		Test.stopTest();
	}

	@IsTest
	static void testGetFieldDataByObjectAndFieldNames() {
		Test.startTest();
		ProviderSearchController.getFieldDataByObjectAndFieldNames('Launchpad__Job__c', new String[]{ 'Schools_Served__c' });
		Test.stopTest();
	}

	@IsTest
	static void testGetCurrentUsersContactFields() {
		Test.startTest();
		ProviderSearchController.getCurrentUsersContactFieldValues(new String[]{ 'School__c '});
		Test.stopTest();
	}

}