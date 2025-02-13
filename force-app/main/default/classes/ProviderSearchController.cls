public with sharing class ProviderSearchController {
    @AuraEnabled(cacheable=true)
    public static List<Launchpad__Job__c> searchJobs(String zipCode, List<String> age, List<String> grade, List<String> gender, List<String> school) {
        String searchQuery = '';

        if (zipCode != null) {
            zipCode = '%' + zipCode + '%';
            searchQuery = ' AND Job_Site_Address__c LIKE :zipCode';
        }

        if (age != null && !age.isEmpty()) {
            searchQuery = ' AND Ages_Served__c INCLUDES (' + getMultiselectString(age) + ')';
        }

        if (grade != null && !grade.isEmpty()) {
            searchQuery = ' AND Grades_Served__c INCLUDES (' + getMultiselectString(grade) + ')';
        }

        if (school != null && !school.isEmpty()) {
            searchQuery = ' AND Schools_Served__c INCLUDES (' + getMultiselectString(school) + ')';
        }

        if (gender != null && !gender.isEmpty()) {
            searchQuery = ' AND Genders_Served__c INCLUDES (' + getMultiselectString(gender) + ')';
        }

        System.debug('QUERIED!!!' + searchQuery);
        
        String query = 'SELECT Id, Name, Launchpad__Job_Description__c, Ages_Served__c, Grades_Served__c, Gender_Served__c, Interest_Areas__c, Program_Type__c, Launchpad__Account__r.Name, Launchpad__Account__r.BillingStreet, Launchpad__Account__r.BillingCity, Launchpad__Account__r.BillingState, Launchpad__Account__r.BillingPostalCode, Job_Site__r.BillingStreet, Job_Site__r.BillingCity, Job_Site__r.BillingState, Job_Site__r.BillingPostalCode FROM Launchpad__Job__c WHERE Program__r.Launchpad__Active__c = \'Yes\'' + searchQuery;
        System.debug('final query: ' + query);
        return Database.query(query, AccessLevel.USER_MODE);
    }

    private static String getMultiselectString(List<String> values) {
        return '\'' + String.join(values, '\', \'') + '\'';
    }
}