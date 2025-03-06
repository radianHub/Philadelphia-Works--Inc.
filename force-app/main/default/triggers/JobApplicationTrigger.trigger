trigger JobApplicationTrigger on Launchpad__Applicant_Tracking__c (before insert, before update, After insert, after update) {
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) ){
        List<Launchpad__Applicant_Tracking__c> listToMatch = new List<Launchpad__Applicant_Tracking__c>();
        List<Launchpad__Applicant_Tracking__c> listToPass = new List<Launchpad__Applicant_Tracking__c>();
           
        for(Launchpad__Applicant_Tracking__c JA : Trigger.New){
            if(JA.launchpad__Stage__c == 'Provider Selected'){
                listToMatch.add(JA);
            }
            if(Trigger.OldMap != null){
                if((Trigger.OldMap.get(JA.Id).launchpad__Stage__c == 'Matched with Provider' || Trigger.OldMap.get(JA.Id).launchpad__Stage__c == 'Ready for JEVs Sign-Off') && (JA.launchpad__Stage__c == 'Passed' || JA.launchpad__Stage__c == 'Shortlisted')){
                    System.debug('Passing to deny: ' + JA.Id);
                    listToPAss.add(JA);
                }
        }
        }
        
        if(listToMatch.size() > 0 || listToPass.size() > 0){
            JobApplicationTriggerHandler.matchProvider(listToMatch, listToPass);
        }
       
    }
    
   
}