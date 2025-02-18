@isTest
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
                Schools_Served__c = 'AMY Northwest',
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
                Schools_Served__c = 'AMY Northwest',
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
                Schools_Served__c = 'AMY Northwest',
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
                Schools_Served__c = 'AMY at James Martin',
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
                Schools_Served__c = 'AMY Northwest',
                Genders_Served__c = 'Female'
			)
		);
        jobs.add(
			new Launchpad__Job__c(
				Name = 'Test Job Grade 9',
				Launchpad__Account__c = accounts[0].Id,
				Launchpad__Available_in_Community__c = true,
				Program__c = program.Id,
				Launchpad__Job_Description__c = 'Test Description 1',
				Ages_Served__c = '13;14',
				Grades_Served__c = '9;10',
                Schools_Served__c = 'AMY Northwest',
                Genders_Served__c = 'Male'
			)
		);
		insert jobs;
	}

	@isTest
	static void testSearchByAge() {
		List<Launchpad__Job__c> jobs = ProviderSearchController.searchJobs(
			null,
			new List<String>{ '12' },
			null,
			null,
			null
		);
		Assert.areEqual(1, jobs.size());
		Assert.areEqual('Test Job 1', jobs[0].Name);
	}

    @isTest
	static void testSearchByGrade() {
		List<Launchpad__Job__c> jobs = ProviderSearchController.searchJobs(
			null,
			null,
			new List<String>{ '9' },
			null,
			null
		);
		Assert.areEqual(1, jobs.size());
		Assert.areEqual('Test Job Grade 9', jobs[0].Name);
	}

    @isTest
	static void testSearchBySchool() {
		List<Launchpad__Job__c> jobs = ProviderSearchController.searchJobs(
			null,
			null,
			null,
			null,
			new List<String>{ 'AMY at James Martin' }
		);
		Assert.areEqual(1, jobs.size());
		Assert.areEqual('Test Job AMY at James Martin', jobs[0].Name);
	}

    @isTest
	static void testSearchByGender() {
		List<Launchpad__Job__c> jobs = ProviderSearchController.searchJobs(
			null,
			null,
			null,
			new List<String>{ 'Female' },
			null
		);
		Assert.areEqual(1, jobs.size());
		Assert.areEqual('Test Job Females', jobs[0].Name);
	}

    @isTest
    static void testSearchByZipCode() {
        List<Launchpad__Job__c> jobs = ProviderSearchController.searchJobs(
            '19104',
            null,
            null,
            null,
            null
        );
        Assert.areEqual(1, jobs.size());
        Assert.areEqual('Test Job Zip 19104', jobs[0].Name);
    }

    @isTest
    static void testSearchByGradeAndAge() {
        List<Launchpad__Job__c> jobs = ProviderSearchController.searchJobs(
            null,
            new List<String>{ '13' },
            new List<String>{ '6' },
            null,
            null
        );
        Assert.areEqual(1, jobs.size());
        Assert.areEqual('Test Job 3', jobs[0].Name);
    }

	@isTest
	static void testGetFilterOptions() {
		Map<String, Object> filterOptions = ProviderSearchController.getFilterOptions();
		Assert.isTrue(filterOptions.containsKey('ages'));
		Assert.isTrue(filterOptions.containsKey('grades'));
		Assert.isTrue(filterOptions.containsKey('genders'));
		Assert.isTrue(filterOptions.containsKey('schools'));
	}
}
