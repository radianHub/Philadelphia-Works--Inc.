@isTest
public with sharing class ProviderSupervisorsControllerTest {

    @TestSetup
    static void makeData(){
        Id supervisorTypeId = Schema.Contact.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supervisor').getRecordTypeId();

        Account account = new Account(
            Name = 'Test Account'
        );
        insert account;

        Contact clearedContact = new Contact(
            FirstName = 'Test',
            LastName = 'Supervisor',
            AccountId = account.Id,
            Supervisor_Clearance__c = true,
            RecordTypeId = supervisorTypeId);
            insert clearedContact;

        Contact unclearedContact = new Contact(
            FirstName = 'Example',
            LastName = 'Supervisor',
            AccountId = account.Id,
            RecordTypeId = supervisorTypeId);
            insert unclearedContact;

    }


    @isTest
    static void getContactsSuccess(){
        Id accountId = [SELECT Id FROM Account WHERE Name = 'Test Account'].Id;
        Test.StartTest();
        List<Contact> supervisorList = ProviderSupervisorsController.getContacts(accountId);
        Test.StopTest();

        System.Assert.areEqual(2, supervisorList.size(), 'Two contacts should have returned');
    }

}