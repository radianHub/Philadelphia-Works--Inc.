trigger ContactTrigger on Contact (after insert) {

    if(Trigger.isAfter && Trigger.isInsert && ContactTriggerHandler.runOnce == false){
        List<Contact> conToRun = new List<Contact>();
        
        System.debug('RUNNING TRIGGER');
        ContactTriggerHandler.handleAccountProcess(Trigger.New);
        ContactTriggerHandler.runOnce = true;
    }
   
}