@isTest
public class ContactTriggerHandlerTest {

    @testSetup
    public static void setup(){
		Account acc = new Account(Name = 'Test2 Account', BillingCity = 'Test City', BillingStreet = 'Test Street', BillingState = 'Test State');
        insert acc;

        Contact contact1 = new Contact(LastName = 'Test1', Launchpad__Mailing_City__c = 'Test City', Launchpad__Mailing_Street__c = 'Test Street', Launchpad__Mailing_State__c = 'Test State');
        Contact contact2 = new Contact(LastName = 'Test2', Launchpad__Mailing_City__c = 'Different City', Launchpad__Mailing_Street__c = 'Different Street', Launchpad__Mailing_State__c = 'Different State');
        insert contact1;        
        insert contact2;
    }
    @isTest
    public static void testHandleAccountProcess() {
        

        List<Contact> conList = [SELECT Id, AccountId, Launchpad__Mailing_Country__c, Launchpad__Mailing_Zip_Postal_Code__c, Launchpad__Mailing_City__c, Launchpad__Mailing_Street__c, Launchpad__Mailing_State__c, LastName FROM Contact WHERE LastName = 'Test1' OR LastName = 'Test2' ];
        Test.startTest();
        ContactTriggerHandler.handleAccountProcess(conList);
        Test.stopTest();

        Contact contact1 = [SELECT AccountId FROM Contact WHERE LastName = 'Test1' LIMIT 1];
        Contact contact2 = [SELECT AccountId FROM Contact WHERE LastName = 'Test2' LIMIT 1];

    }
}