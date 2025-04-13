@isTest
public class UniversalApp_Test {
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
        
        for (Integer i = 0; i < 5; i++) {
            if(i==0){
                Launchpad__Applicant_Tracking__c firstApp = new Launchpad__Applicant_Tracking__c();
                firstApp.Launchpad__Participant__c = contacts[0].Id; 
                firstApp.Launchpad__Stage__c = 'Submitted';
                firstApp.Provider_Rank__c = '1';
                firstApp.Previous_Stage__c = 'Provider Selected';
                firstApp.Launchpad__Job_Order__c = job.Id;
                firstApp.Applicant_s_Email_Address__c = 'Test12@test12345.com';
                firstApp.Emergency_Contact_Email__c = 'gegeggegege@rhefgeheg.com';
                jobApplications.add(firstApp);
            }else{
                jobApplications.add(new Launchpad__Applicant_Tracking__c(
                Launchpad__Participant__c = contacts[0].Id, 
                Launchpad__Stage__c = 'Submitted', 
                Provider_Rank__c = String.ValueOf(i+1),
                Previous_Stage__c = 'Provider Selected',
                Launchpad__Job_Order__c = job.Id, 
                Applicant_s_Email_Address__c = 'Test12@test12345.com',
                Emergency_Contact_Email__c = 'gegeggegege@rhefgeheg.com'
            ));
            }
            
        }
        
        insert jobApplications;
    }
    
	@isTest
	static void retrieveCustomMetadata() {
		// Error scenario -- no app found
		Map<String, Object> ret = UniversalApp.retrieveApp('Testing_Not_Found', null);

		System.assertEquals(
			UniversalApp.NOT_FOUND,
			ret.get('error'),
			'Did not handle the correct error scenario: ' + UniversalApp.NOT_FOUND
		);

		// Error scenario -- catch error
		UniversalApp.apps = new List<Universal_App__mdt>();

		ret = UniversalApp.retrieveApp('FindThisApp', null);

		// Error scenario -- no sections found
		Universal_App__mdt app = new Universal_App__mdt(DeveloperName = 'FindThisApp', Object__c = 'Account');
		UniversalApp.apps = new List<Universal_App__mdt>{ app };

		ret = UniversalApp.retrieveApp('FindThisApp', null);

		// System.assertEquals(
		// 	UniversalApp.NO_SECTION,
		// 	ret.get('error'),
		// 	'Did not handle the correct error scenario: ' + UniversalApp.NO_SECTION
		// );

		// Success scenario -- returned data
		app = new Universal_App__mdt(DeveloperName = 'Example', Object__c = 'Account');
		UniversalApp.apps = new List<Universal_App__mdt>{ app };
		Universal_App_Section__mdt sect = new Universal_App_Section__mdt(
			DeveloperName = 'Section',
			Page__c = 1,
			Order__c = 1,
			Section_Field_Set__c = 'Account_Example'
		);
		UniversalApp.sections = new List<Universal_App_Section__mdt>{ sect };

		ret = UniversalApp.retrieveApp('Example', null);

		System.assertEquals(true, ret.containsKey('data'), 'Did not successfully return the app & section data.');

		// Error scenario -- no object, but with sections
		app = new Universal_App__mdt(DeveloperName = 'FindThisApp', Object__c = 'NOT_FOUND____c');
		UniversalApp.apps = new List<Universal_App__mdt>{ app };

		ret = UniversalApp.retrieveApp('FindThisApp', null);

		System.assertEquals(
			true,
			ret.containsKey('error'),
			'Did not handle the correct error scenario: ' + UniversalApp.NO_FIELDSETS
		);

		// Success scenario -- with recordId
		Contact appObj = new Contact(LastName = 'Test');
		insert appObj;

		app = new Universal_App__mdt(DeveloperName = 'FindThisApp', Object__c = 'Contact');
		UniversalApp.apps = new List<Universal_App__mdt>{ app };
		sect = new Universal_App_Section__mdt(
			DeveloperName = 'Section',
			Page__c = 1,
			Order__c = 1,
			Section_Field_Set__c = 'NOT_PRESENT',
			Universal_App__c = app.Id
		);
		UniversalApp.sections = new List<Universal_App_Section__mdt>{ sect };

		ret = UniversalApp.retrieveApp('FindThisApp', appObj.Id);

		System.assertEquals(true, ret.containsKey('data'), 'Did not successfully return the app & section data.');

		// Query for Boolean Test
		String fld = 'LastName';
		String obj = 'Contact';
		String objId = (String) appObj.Id;

		sObject qry = UniversalApp.queryForBoolean(fld, obj, objId);
		System.assertEquals(true, qry.get(fld) == appObj.get(fld), 'Queried field does not equal actual');

		Account account = new Account(Name = 'Test');
		insert account;

		app = new Universal_App__mdt(DeveloperName = 'Example', Object__c = 'Account');
		UniversalApp.apps = new List<Universal_App__mdt>{ app };
		sect = new Universal_App_Section__mdt(
			DeveloperName = 'Section',
			Page__c = 1,
			Order__c = 1,
			Section_Field_Set__c = 'Account_Example',
			Universal_App__c = app.Id
		);
		UniversalApp.sections = new List<Universal_App_Section__mdt>{ sect };

		ret = UniversalApp.retrieveApp('Example', account.Id);

		System.assertEquals(true, ret.containsKey('data'), 'Did not successfully return the app & section data.');

		// Query for Boolean Test
		String fld2 = 'Name';
		String obj2 = 'Account';
		String obj2Id = (String) account.Id;

		sObject qry2 = UniversalApp.queryForBoolean(fld2, obj2, obj2Id);
		System.assertEquals(true, qry2.get(fld2) == account.get(fld2), 'Queried field does not equal actual');
	}

	@isTest
	static void submitSObject() {
		// May or may not succeed -- depends on org Validation Rules / custom code
		// No system asserts here
		Account act = new Account(Name = 'Test Submit');
		Map<String, Object> ret = new Map<String, Object>();

		List<UniversalApp.File> files = new List<UniversalApp.File>();

		UniversalApp.File file = new UniversalApp.File();
		file.filename = 'Test file';
		file.base64 = EncodingUtil.base64Encode(Blob.valueOf('data'));

		files.add(file);
        /*
        SObject sObj,
		String application,
		String filesString,
		Boolean isSaveForLater
*/
		ret = UniversalApp.submitApp(act, null, JSON.serialize(files), null);

		// Fail scenario
		Account actNull = null;
		UniversalApp.submitApp(actNull, null, null, null);
	}

	@IsTest
	private static void testGetChildObjFields() {
		Map<String, Object> data = UniversalApp.getChildObjectFields('Contact', 'Test');
		System.assert((String) data.get('error') != null, 'Field set found');

		data = UniversalApp.getChildObjectFields('Contact', 'Contact_Example');

		System.assert(data.keySet().size() > 0, 'No data returned');
	}

	@IsTest
	private static void testSubmitChildObjects() {
		Account acc = new Account(Name = 'Test');
		insert acc;

		Contact con = new Contact(LastName = 'Test');

		UniversalApp.childRecordsWrapper crw = new UniversalApp.childRecordsWrapper();
		crw.objectName = 'Contact';
		crw.parentField = 'AccountId';
		crw.records = new List<SObject>{ con };

		UniversalApp.submitChildObjects(new List<UniversalApp.childRecordsWrapper>{ crw }, acc.Id);

		List<Contact> conList = [
			SELECT Id
			FROM Contact
			WHERE LastName = 'Test'
		];
	}
    
    @isTest
    static void testUpdateOtherAppsInSameSession(){
        Launchpad__Applicant_Tracking__c testApp = [SELECT Id FROM Launchpad__Applicant_Tracking__c LIMIT 1];
        UniversalApp.updateOtherAppsInSameSession(testApp.Id);
    }
}