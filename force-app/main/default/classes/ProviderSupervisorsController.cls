public with sharing class ProviderSupervisorsController {
    @AuraEnabled(Cacheable = true)
    public static List<Contact> getContacts(Id accountId) {
        Id supervisorTypeId = Schema.Contact.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supervisor').getRecordTypeId();
        return [SELECT Id,Name,Supervisor_Clearance__c FROM Contact WHERE AccountId = :accountId AND RecordTypeId = :supervisorTypeId ORDER BY Name ASC ];
    }

}