public without sharing class consentFormGuestController {
    
    @AuraEnabled(cacheable=false)
    public static void updateSingleJobApplication(Launchpad__Applicant_Tracking__c appToUpdate){
        appToUpdate.Guardian_Consent_Required__c = false;
          update appToUpdate;    
    }

    
    @AuraEnabled(cacheable=true)
    public static Launchpad__Applicant_Tracking__c getCurrentJobApplication(Id appId){
        System.debug('app.Id: ' + appId);
            return [SELECT Id, Applicant_s_Legal_First_Name__c, Applicant_s_Legal_Last_Name__c, Media_Picture_Release__c, Parent_s_Consent__c, Release_of_Information__c, Consent_to_Request_Clearance__c, Guardian_Consent_Required__c 
                FROM Launchpad__Applicant_Tracking__c
                WHERE Id = :appId
                LIMIT 1
            ];
        }
}