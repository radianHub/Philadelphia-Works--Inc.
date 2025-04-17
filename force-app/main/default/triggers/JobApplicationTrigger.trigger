trigger JobApplicationTrigger on Launchpad__Applicant_Tracking__c (before insert, before update, After insert, after update) {
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) ){
       JobApplicationTriggerHandler.main(Trigger.New, Trigger.oldMap);
    }
    
   
}