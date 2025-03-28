trigger ContactTrigger on Contact (after insert) {

    if(Trigger.isAfter && Trigger.isInsert && ContactTriggerHandler.runOnce == false){
        ContactTriggerHandler.handleAccountProcess(Trigger.New);
        ContactTriggerHandler.runOnce = true;
    }
   
}