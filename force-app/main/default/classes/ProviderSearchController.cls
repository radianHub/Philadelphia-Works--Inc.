public with sharing class ProviderSearchController {
    @AuraEnabled(cacheable=true)
    public static List<Launchpad__Job__c> searchJobs(String zipCode, List<String> age, List<String> grade, String gender) {
        String searchQuery = '';

        if (zipCode != null) {
            searchQuery = ' AND Job_Site__r.Job_Site_Address__c CONTAINS :zipCode';
        }

        if (age != null && !age.isEmpty()) {
            searchQuery = ' AND Ages_Served__c INCLUDES :age';
        }

        if (grade != null && !grade.isEmpty()) {
            searchQuery = ' AND Grades_Served__c INCLUDES :grade';
        }

        if (gender != null) {
            searchQuery = ' AND Genders_Served__c INCLUDES :gender';
        }

        System.debug('QUERIED!!!' + searchQuery);
        
        String query = 'SELECT Id, Name, Ages_Served__c, Grades_Served__c, Gender_Served__c, Launchpad__Account__r.BillingStreet, Launchpad__Account__r.BillingCity, Launchpad__Account__r.BillingState, Launchpad__Account__r.BillingPostalCode, Job_Site__r.BillingStreet, Job_Site__r.BillingCity, Job_Site__r.BillingState, Job_Site__r.BillingPostalCode FROM Launchpad__Job__c WHERE Program__r.Launchpad__Active__c = \'Yes\'' + searchQuery;
        System.debug('final query: ' + query);
        return Database.query(query);
    }
}