public with sharing class CreateApplicationController {
    /**
     * Create a new application for a contact and job.
     * @param contactId The contact ID.
     * @param jobId The job ID.
     * @return The ID of the new application.
     */
    @AuraEnabled
    public static Id createApplication(String contactId, String jobId, String contactEmail) {
        try {
            // If youth already has an application for this job in an active program, return the existing application ID.
            List<Launchpad__Applicant_Tracking__c> existingApplications = [
                SELECT Id
                FROM Launchpad__Applicant_Tracking__c
                WHERE Launchpad__Participant__c = :contactId
                AND Launchpad__Job_Order__c = :jobId
                AND Program__r.Launchpad__Active__c = 'Yes'
                AND RecordType.Name = 'Session'
            ];
            if (!existingApplications.isEmpty()) {
                return existingApplications[0].Id;
            }

            Launchpad__Job__c job = [SELECT Id, Program__c FROM Launchpad__Job__c WHERE Id = :jobId];
    
            Launchpad__Applicant_Tracking__c application = new Launchpad__Applicant_Tracking__c(
                Launchpad__Participant__c = contactId,
                Launchpad__Job_Order__c = jobId,
                Provider_Rank__c = '1',
                Applicant_s_Email_Address__c = contactEmail,
                Launchpad__Stage__c = 'In Progress',
                Program__c = job.Program__c
            );
            insert application;
            return application.Id;
        } catch (Exception e) {
            System.debug('Error creating application: ' + e.getMessage());
            throw e;
        }
    }

    @AuraEnabled
    public static Id createBulkApplications(String contactId, String contactEmail, List<Map<String, Object>> applications) {
        try {
            List<Id> jobIds = new List<Id>();
            for (Map<String, Object> app : applications) {
                jobIds.add((String) app.get('id'));
            }

            // If applicant already has an application in the active program session, return the existing application ID.
            List<Launchpad__Applicant_Tracking__c> existingApplications = [
                SELECT Id
                FROM Launchpad__Applicant_Tracking__c
                WHERE Launchpad__Participant__c = :contactId
                AND Launchpad__Job_Order__c IN :jobIds
                AND Program__r.Launchpad__Active__c = 'Yes'
                AND RecordType.Name = 'Session'
            ];
            if (!existingApplications.isEmpty()) {
                return existingApplications[0].Id;
            }

            Launchpad__Job__c job = [SELECT Id, Program__c FROM Launchpad__Job__c WHERE Id = :jobIds[0]];

            List<Launchpad__Applicant_Tracking__c> newApplications = new List<Launchpad__Applicant_Tracking__c>();
            for (Map<String, Object> app : applications) {
    
                Launchpad__Applicant_Tracking__c application = new Launchpad__Applicant_Tracking__c(
                Launchpad__Participant__c = contactId,
                Launchpad__Job_Order__c = (String) app.get('id'),
                Provider_Rank__c = (String) app.get('order'),
                Applicant_s_Email_Address__c = contactEmail,
                Launchpad__Stage__c = 'In Progress',
                Program__c = job.Program__c
            );
                newApplications.add(application);
            }

            Launchpad__Enrollment__c enrollment = new Launchpad__Enrollment__c();
            enrollment.Launchpad__Client__c = contactId;
            enrollment.Launchpad__Program__c = job.Program__c;
            insert enrollment;

            Contact contact = new Contact();
            contact.Id = contactId;
            contact.Enrollment__c = enrollment.Id;
            update contact;

            insert newApplications;
            return newApplications[0].Id;
        } catch (Exception e) {
            System.debug('Error creating application: ' + e.getMessage());
            throw e;
        }
    }
}