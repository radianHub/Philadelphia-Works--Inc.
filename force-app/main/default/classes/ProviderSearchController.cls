public with sharing class ProviderSearchController {

    @AuraEnabled
    public static Contact_Job_Eligibility_Map__mdt[] getContactJobEligibilityMaps() {
        return Contact_Job_Eligibility_Map__mdt.getAll().values();
    }

    @AuraEnabled(Cacheable = true)
    public static List<Launchpad__Job__c> searchJobsDynamic(
            String zipCode, String[] fieldsToQuery, Map<String, String> textFilters, Map<String, String[]> picklistFilters) {
        String searchQuery = '';

        if (String.isNotBlank(zipCode)) {
            zipCode = '%' + zipCode + '%';
            searchQuery += ' AND (Job_Site_Address__c LIKE :zipCode OR ' +
                    '(Job_Site_Address__c = NULL AND Launchpad__Account_Address__c LIKE :zipCode))';
        }

        if (textFilters != null) {
            for (String fieldApiName : textFilters.keySet()) {
                if (String.isNotBlank(textFilters.get(fieldApiName))) {
                    String searchValue = '%' + textFilters.get(fieldApiName) + '%';
                    searchQuery += ' AND ' + fieldApiName + ' LIKE :searchValue';
                }
            }
        }

        if (picklistFilters != null) {
            for (String fieldApiName : picklistFilters.keySet()) {
                String[] searchValues = picklistFilters.get(fieldApiName);

                if (!searchValues.isEmpty()) {
                    Boolean isMultiselectField = String.valueOf(Schema.SObjectType.Launchpad__Job__c.fields.getMap()
                            .get(fieldApiName).getDescribe().getType()).startsWith('MULTI');
                    String searchString = getMultiselectString(picklistFilters.get(fieldApiName));
                    searchQuery += ' AND (' + fieldApiName + ' ' + (isMultiselectField ? 'INCLUDES' : 'IN') +
                            ' (' + searchString + ') OR ' + fieldApiName + ' = NULL)';
                }
            }
        }

        String query = 'SELECT ' + getFieldsQueryString(fieldsToQuery) + ' Id, Name, Launchpad__Job_Description__c, ' +
                'Launchpad__Account_Address__c, Job_Site_Address__c, Launchpad__Account__r.Name, ' +
                'Launchpad__Account__r.BillingStreet, Launchpad__Account__r.BillingCity, ' +
                'Launchpad__Account__r.BillingState, Launchpad__Account__r.BillingPostalCode, ' +
                'Placement_Site__r.BillingStreet, Placement_Site__r.BillingCity, Placement_Site__r.BillingState, ' +
                'Placement_Site__r.BillingPostalCode FROM Launchpad__Job__c ' +
                'WHERE Program__r.Launchpad__Active__c = \'Yes\' AND Launchpad__Available_in_Community__c = TRUE' +
                searchQuery + ' ORDER BY Name ASC, Job_Site_Address__c ASC NULLS LAST';
        return Database.query(query, AccessLevel.USER_MODE);
    }

    @AuraEnabled
    public static FieldData[] getJobFieldSetMembers(String fieldSetName) {
        FieldData[] result = new FieldData[]{};
        FieldSetMember[] fieldSetMembers = Schema.SObjectType.Launchpad__Job__c.fieldSets.getMap().get(fieldSetName).getFields();
        for (FieldSetMember fsm : fieldSetMembers) {
            String fieldType = String.valueOf(fsm.getType());
            if (fieldType.containsIgnoreCase('picklist')) {
                result.add(new FieldData(fsm.getFieldPath(), fsm.getLabel(), fieldType,
                        getPicklistValues('Launchpad__Job__c', fsm.getFieldPath())));
            } else {
                result.add(new FieldData(fsm.getFieldPath(), fsm.getLabel(), fieldType));
            }
        }
        return result;
    }

    @AuraEnabled
    public static FieldData[] getFieldDataByObjectAndFieldNames(String sObjectName, String[] fieldNames) {
        FieldData[] result = new FieldData[]{};
        Map<String, SObjectField> jobFieldsMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
        DescribeFieldResult[] fieldResults = new DescribeFieldResult[]{};
        for (String field : fieldNames) {
            fieldResults.add(jobFieldsMap.get(field).getDescribe());
        }
        for (DescribeFieldResult fieldResult : fieldResults) {
            String fieldType = String.valueOf(fieldResult.getType());
            if (fieldType.containsIgnoreCase('picklist')) {
                result.add(new FieldData(fieldResult.getName(), fieldResult.getLabel(), fieldType,
                        getPicklistValues(sObjectName, fieldResult.getName())));
            } else {
                result.add(new FieldData(fieldResult.getName(), fieldResult.getLabel(), fieldType));
            }
        }
        return result;
    }

    @AuraEnabled
    public static Contact getCurrentUsersContactFieldValues(String[] fieldNames) {
        Id contactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;
        if (contactId == null) return null;
        String query = 'SELECT ' + getFieldsQueryString(fieldNames) + ' Id FROM Contact WHERE Id = :contactId';
        return Database.query(query);
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

    private static String getFieldsQueryString(String[] values) {
        if (values == null || values.isEmpty()) return '';
        return String.join(values, ', ') + ',';
    }

    private static String getMultiselectString(List<String> values) {
        return '\'' + String.join(values, '\', \'') + '\'';
    }

    public class FieldData {
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public List<Map<String, Object>> options = new List<Map<String, Object>>();
        @AuraEnabled public Boolean isPicklist = false;

        public FieldData(String apiName, String label, String type) {
            this.apiName = apiName;
            this.label = label;
            this.type = type;
        }

        public FieldData(String apiName, String label, String type, List<Map<String, Object>> options) {
            this.apiName = apiName;
            this.label = label;
            this.type = type;
            this.options = options;
            this.isPicklist = true;
        }
    }

}