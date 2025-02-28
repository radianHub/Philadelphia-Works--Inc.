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
            // If youth already has an application for this job, return the existing application ID.
            List<Launchpad__Applicant_Tracking__c> existingApplications = [
                SELECT Id
                FROM Launchpad__Applicant_Tracking__c
                WHERE Launchpad__Participant__c = :contactId
                AND Launchpad__Job_Order__c = :jobId
            ];
            if (!existingApplications.isEmpty()) {
                return existingApplications[0].Id;
            }
    
            Launchpad__Applicant_Tracking__c application = new Launchpad__Applicant_Tracking__c(
                Launchpad__Participant__c = contactId,
                Launchpad__Job_Order__c = jobId,
                Provider_Rank__c = '1',
                Applicant_s_Email_Address__c = contactEmail
            );
            insert application;
            return application.Id;
        } catch (Exception e) {
            System.debug('Error creating application: ' + e.getMessage());
            throw e;
        }
    }
}