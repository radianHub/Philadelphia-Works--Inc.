trigger ProgramTrigger on Launchpad__Program__c (before insert) {

    if(Trigger.isInsert & Trigger.isBefore){
        ProgramTriggerController.checkForOtherActiveSessions(Trigger.New);
    }
}