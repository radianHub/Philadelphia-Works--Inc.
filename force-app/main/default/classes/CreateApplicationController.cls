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

			Launchpad__Job__c job = [SELECT Id, Program__c, Program__r.Application_Close_Date__c FROM Launchpad__Job__c WHERE Id = :jobId];
            
            if(job != null){
                if(job.Program__r.Application_Close_Date__c < System.Today()){
                    throw new AuraHandledException('Application date has passed for the program');
                }
            }

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
					AND Program__r.Launchpad__Active__c = 'Yes'
					AND Program__r.RecordType.Name = 'Session'
			];
			if (!existingApplications.isEmpty()) {
				throw new AuraHandledException('You have already applied to a program in this session.');
			}

			Launchpad__Job__c job = [SELECT Id, Program__c, Program__r.Application_Close_Date__c FROM Launchpad__Job__c WHERE Id = :jobIds[0]];
            
            if(job != null){
                if(job.Program__r.Application_Close_Date__c < System.Today()){
                    throw new AuraHandledException('Application date has passed for the program');
                }
            }

			Contact con = [
				SELECT Id, Race_Ethnicity__c, 	GenderIdentity, HomePhone, Youth_s_Internet_Connectivity__c, Youth_s_Current_Living_Situation__c, Last_Completed_Grade__c, Current_Employment_Status__c, Pronouns, 
                        Sex_Assigned_At_Birth__c, Launchpad__Parent_Guardian_Phone__c, Launchpad__Parent_Guardian_Name__c, Guardian_Email__c, Emergency_Contact_Relationship__c, 
                        Emergency_Contact_Phone__c, Emergency_Contact_Last_Name__c, Emergency_Contact_First_Name__c,  Emergency_Contact_Email__c, 
                        Launchpad__Primary_Language_Spoken_at_Home__c, Country_of_Nationality__c, Middle_Name__c, Phone, Launchpad__Unique_ID_SSN__c, MailingCity, MailingStreet, 
                        MailingState, MailingPostalCode, Birthdate, Launchpad__Gender__c, School__c
                        FROM Contact
				WHERE Id = :contactId
			];

			List<Launchpad__Applicant_Tracking__c> newApplications = new List<Launchpad__Applicant_Tracking__c>();
			for (Map<String, Object> app : applications) {
				Integer postalCode = null;

				if (con.MailingPostalCode != null) {
					postalCode = Integer.valueOf(con?.MailingPostalCode);
				}

				if (con.Birthdate != null) {
				}

				Launchpad__Applicant_Tracking__c application = new Launchpad__Applicant_Tracking__c(
                    Race_and_or_Ethnicity__c = con?.Race_Ethnicity__c,
                    Applicant_s_Internet_Connectivity__c = con?.Youth_s_Internet_Connectivity__c,
                    Current_Living_Situation__c = con?.Youth_s_Current_Living_Situation__c,
                    //Applicant_s_Last_Completed_Grade = con?.Last_Completed_Grade__c, 
                    Applicant_s_Current_Employment_Status__c = con?.Current_Employment_Status__c,
                    Applicant_s_Preferred_Pronoun__c = con?.Pronouns, 
                    Applicant_s_Sex_Assigned_at_Birth__c = con?.Sex_Assigned_At_Birth__c,                                                                                
                    Guardian_Name__c = con?.Launchpad__Parent_Guardian_Name__c,
                    Guardian_Email__c = con?.Guardian_Email__c,
                    Guardian_Phone_Number__c = con?.Launchpad__Parent_Guardian_Phone__c,
                    Emergency_Contact_Email__c = con?.Emergency_Contact_Email__c,
                    Emergency_Contact_First_Name__c = con?.Emergency_Contact_First_Name__c,
                    Emergency_Contact_Last_Name__c = con?.Emergency_Contact_Last_Name__c,
                    Emergency_Contact_Phone__c = con?.Emergency_Contact_Phone__c,
                    Emergency_Contact_Relationship__c = con?.Emergency_Contact_Relationship__c,
                    Applicant_s_Primary_Language__c = con?.Launchpad__Primary_Language_Spoken_at_Home__c,
                    Applicant_s_Country_of_Nationality__c = con?.Country_of_Nationality__c,
                    Middle_Name__c = con?.Middle_Name__c,
                    Applicant_s_Phone_Number__c = con?.	HomePhone,
                    Applicants_Tax_Id__c = con?.Launchpad__Unique_ID_SSN__c,
					Applicant_s_Street_Address__c = con?.MailingStreet,
					Applicant_City__c = con?.MailingCity,
					Applicant_s_State__c = con?.MailingState,
					Applicants_Zip_Code__c = String.valueOf(postalCode),
                    Applicant_s_Current_Gender__c = con?.GenderIdentity,
                    Applicants_Current_Most_Recent_School__c = con?.School__c,
					Applicant_s_Date_of_Birth_MM_DD_YYYY__c = con?.Birthdate,
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