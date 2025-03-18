public without sharing class GuestUserApplicationController {
    
    public static Launchpad__Applicant_Tracking__c getCurrentJobApplication(Id appId){
        return [SELECT Id, Media_Picture_Release__c, Guardian_Consent_Required__c, Applicant_s_Date_of_Birth_MM_DD_YYYY__c, Parent_s_Consent__c, Release_of_Information__c, Consent_to_Request_Clearance__c, Program__c, Program__r.Launchpad__Active__c, Program__r.Launchpad__Program_Year_Start__c, Launchpad__Participant__c 
			FROM Launchpad__Applicant_Tracking__c
			WHERE Id = :appId
			LIMIT 1
		];
    }
    
    public static List<Launchpad__Applicant_Tracking__c> getRelatedJobApplications(Id appId){
        Launchpad__Applicant_Tracking__c currentApp = getCurrentJobApplication(appId);
        
        return [SELECT Id, Media_Picture_Release__c, Parent_s_Consent__c, Release_of_Information__c, Consent_to_Request_Clearance__c, Program__c, Launchpad__Participant__c
                FROM Launchpad__Applicant_Tracking__c
				WHERE Program__c = :currentApp.Program__c
				AND Launchpad__Participant__c = :currentApp.Launchpad__Participant__c];
    }
    
    public static List<Database.UpsertResult> updateJobApplications(List<Launchpad__Applicant_Tracking__c> appsToUpdate){
        System.debug('Inside update app');
         List<Database.UpsertResult> result = Database.upsert(appsToUpdate, false);
        System.debug('Result: ' + result);
         return result;
    }
    
    public static Database.UpsertResult updateSingleJobApplication(sObject appToUpdate){
         Database.UpsertResult result = Database.upsert(appToUpdate, false);
         return result;
    }
    

}