/**
 * Created by holden on 3/20/25.
 */

public with sharing class ProviderJobsController {

    @AuraEnabled(Cacheable = true)
    public static Launchpad__Job__c[] getJobs(Id accountId) {
        return [
                SELECT Id, Name, Program__r.Name, Launchpad__Contact__r.Name
                FROM Launchpad__Job__c WHERE Launchpad__Account__c = :accountId
        ];
    }

    @AuraEnabled
    public static Launchpad__Job__c getJob(Id jobId, String fieldSetName) {
        ProviderSearchController.FieldData[] fieldData = ProviderSearchController.getJobFieldSetMembers(fieldSetName);
        String query = 'SELECT Id, ';
        for (ProviderSearchController.FieldData data : fieldData) {
            query += data.apiName + ', ';
            if (data.type == 'REFERENCE') {
                query += data.apiName.replace('__c', '__r') + '.Name, ';
            }
        }
        query = query.removeEnd(', ');
        query += ' FROM Launchpad__Job__c WHERE Id = :jobId';
        return Database.query(query);
    }

    @AuraEnabled
    public static Map<String, Object> updateJob(Launchpad__Job__c job) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            update job;
            result.put('success', 'Program saved successfully.');
        } catch (Exception e) {
            result.put('error', e.getMessage());
        }
        return result;
    }

}