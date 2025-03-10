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
				WHERE
					Launchpad__Participant__c = :contactId
					AND Launchpad__Job_Order__c = :jobId
					AND Program__r.Launchpad__Active__c = 'Yes'
					AND Program__r.RecordType.Name = 'Session'
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
	public static Id createBulkApplications(
		String contactId,
		String contactEmail,
		List<Map<String, Object>> applications
	) {
		try {
			List<Id> jobIds = new List<Id>();
			for (Map<String, Object> app : applications) {
				jobIds.add((String) app.get('id'));
			}

			// If applicant already has an application in the active program session, return the existing application ID.
			List<Launchpad__Applicant_Tracking__c> existingApplications = [
				SELECT Id
				FROM Launchpad__Applicant_Tracking__c
				WHERE
					Launchpad__Participant__c = :contactId
					AND Launchpad__Job_Order__c IN :jobIds
					AND Program__r.Launchpad__Active__c = 'Yes'
					AND Program__r.RecordType.Name = 'Session'
			];
			if (!existingApplications.isEmpty()) {
				throw new AuraHandledException('You have already applied to a program in this session.');
			}

			Launchpad__Job__c job = [SELECT Id, Program__c FROM Launchpad__Job__c WHERE Id = :jobIds[0]];
            
            Contact con = [SELECT Id, MailingCity, MailingStreet, MailingState, MailingPostalCode, Birthdate FROM Contact WHERE Id = :contactId];

			List<Launchpad__Applicant_Tracking__c> newApplications = new List<Launchpad__Applicant_Tracking__c>();
			for (Map<String, Object> app : applications) {
                
                Integer postalCode = null;
                                
                if(con.MailingPostalCode != null){
                    postalCode = Integer.valueOf(con?.MailingPostalCode);
                }
                
                if(con.Birthdate != null){
                    
                }
                
				Launchpad__Applicant_Tracking__c application = new Launchpad__Applicant_Tracking__c(
                    Applicant_s_Street_Address__c = con?.MailingStreet,
                    Applicant_City__c = con?.MailingCity,
                    Applicant_s_State__c = con?.MailingState,
                    Applicant_s_Zip_Code__c = postalCode,
                    Applicant_s_Date_of_Birth_MM_DD_YYYY__c  = con?.Birthdate,
					Launchpad__Participant__c = contactId,
					Launchpad__Job_Order__c = (String) app.get('id'),
					Provider_Rank__c = (String) app.get('order'),
					Applicant_s_Email_Address__c = contactEmail,
					Launchpad__Stage__c = 'In Progress',
					Program__c = job.Program__c
				);
				newApplications.add(application);
			}

			insert newApplications;
			return newApplications[0].Id;
		} catch (Exception e) {
			System.debug('Error creating application: ' + e.getMessage());
			throw e;
		}
	}

	@AuraEnabled
	public static List<Launchpad__Applicant_Tracking__c> getContactApplications(Id contactId) {
		try {
			List<Launchpad__Applicant_Tracking__c> applications = [
				SELECT Id, Launchpad__Stage__c, Launchpad__Job_Order__r.Name, Provider_Rank__c
				FROM Launchpad__Applicant_Tracking__c
				WHERE
					Launchpad__Participant__c = :contactId
					AND Program__r.Launchpad__Active__c = 'Yes'
					AND Program__r.RecordType.Name = 'Session'
			];

            return applications;
		} catch (Exception e) {
			System.debug('Error getting applications: ' + e.getMessage());
			throw e;
		}
	}

    @AuraEnabled
    public static Boolean hasActiveApplication(Id contactId) {
        try {
            List<Launchpad__Applicant_Tracking__c> applications = [
                SELECT Id
                FROM Launchpad__Applicant_Tracking__c
                WHERE
                    Launchpad__Participant__c = :contactId
                    AND Program__r.Launchpad__Active__c = 'Yes'
                    AND Program__r.RecordType.Name = 'Session'
            ];

            return !applications.isEmpty();
        } catch (Exception e) {
            System.debug('Error getting applications: ' + e.getMessage());
            throw e;
        }
    }
}