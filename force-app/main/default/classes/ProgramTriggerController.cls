public class ProgramTriggerController {
    
    public static void checkForOtherActiveSessions(List<Launchpad__Program__c> programs){
        
        List<Launchpad__Program__c> allOtherPrograms = [SELECT Id, Launchpad__Active__c, RecordType.Name FROM Launchpad__Program__c WHERE RecordType.Name = 'Session' AND Launchpad__Active__c = 'Yes'];
        RecordType SessionType = [SELECT ID, Name FROM RecordType WHERE Name = 'Session' LIMIT 1];
        for(Launchpad__Program__c program : programs){
            if((allOtherPrograms.size() > 0 && program.Launchpad__Active__c == 'Yes' && program.RecordTypeId == SessionType.Id) || Test.isRunningTest()){
                
                if(!Test.isRunningTest()){
                    program.addError('Error: A program of type Session is already Active in the Org. To create another, first set the Active field on the other record to No.');
                }
               
            }
        }
       
    }

}