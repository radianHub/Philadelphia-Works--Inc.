public with sharing class ProviderSearchController {
    @AuraEnabled(cacheable=true)
    public static List<Launchpad__Job__c> searchJobs(String zipCode, List<String> age, List<String> grade, List<String> gender, List<String> school) {
        String searchQuery = '';

        if (zipCode != null) {
            zipCode = '%' + zipCode + '%';
            searchQuery += ' AND (Job_Site_Address__c LIKE :zipCode OR (Job_Site_Address__c = NULL AND Launchpad__Account_Address__c LIKE :zipCode))';
        }

        if (age != null && !age.isEmpty()) {
            searchQuery += ' AND (Ages_Served__c INCLUDES (' + getMultiselectString(age) + ') OR Ages_Served__c = NULL)';
        }

        if (grade != null && !grade.isEmpty()) {
            searchQuery += ' AND (Grades_Served__c INCLUDES (' + getMultiselectString(grade) + ') OR Grades_Served__c = NULL)';
        }

        if (gender != null && !gender.isEmpty()) {
            searchQuery += ' AND (Genders_Served__c INCLUDES (' + getMultiselectString(gender) + ') OR Genders_Served__c = NULL)';
        }

        if (school != null && !school.isEmpty()) {
            searchQuery += ' AND (Schools_Served__c INCLUDES (' + getMultiselectString(school) + ') OR Schools_Served__c = NULL)';
        }
        
        String query = 'SELECT Id, Name, Launchpad__Job_Description__c, Ages_Served__c, Grades_Served__c, Genders_Served__c, Schools_Served__c, Interest_Areas__c, Program_Type__c, Launchpad__Account__r.Name, Launchpad__Account__r.BillingStreet, Launchpad__Account__r.BillingCity, Launchpad__Account__r.BillingState, Launchpad__Account__r.BillingPostalCode, Placement_Site__r.BillingStreet, Placement_Site__r.BillingCity, Placement_Site__r.BillingState, Placement_Site__r.BillingPostalCode FROM Launchpad__Job__c WHERE Program__r.Launchpad__Active__c = \'Yes\' AND Launchpad__Available_in_Community__c = TRUE' + searchQuery + ' ORDER BY Name ASC, Job_Site_Address__c ASC NULLS LAST';
        return Database.query(query, AccessLevel.USER_MODE);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getFilterOptions() {
        Map<String, Object>  picklistValues = new Map<String, Object>();
        picklistValues.put('ages', getPicklistValues('Launchpad__Job__c', 'Ages_Served__c'));
        picklistValues.put('grades', getPicklistValues('Launchpad__Job__c', 'Grades_Served__c'));
        picklistValues.put('genders', getPicklistValues('Launchpad__Job__c', 'Genders_Served__c'));
        picklistValues.put('schools', getPicklistValues('Launchpad__Job__c', 'Schools_Served__c'));
        return picklistValues;
    }

    private static List<Map<String, Object>> getPicklistValues(String objectName, String fieldName) {
        List<Map<String, Object>> values = new List<Map<String, Object>>();
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry picklistEntry : ple) {
            values.add(new Map<String, String> {
                'label' => picklistEntry.getLabel(),
                'value' => picklistEntry.getValue()
            });
        }
        return values;
    }

    private static String getMultiselectString(List<String> values) {
        return '\'' + String.join(values, '\', \'') + '\'';
    }
}