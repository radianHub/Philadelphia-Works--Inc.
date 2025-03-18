@isTest
public class ProgramTriggerControllerTest {
    
    @isTest
    public static void checkForOtherActiveSessionsTest(){
        
        Launchpad__Program__c p1 = new Launchpad__Program__c();
        p1.Name = 'Test Program';
        p1.Launchpad__Active__c = 'Yes';
        insert p1;
        
        Test.startTest();
        
        Launchpad__Program__c p2 = new Launchpad__Program__c();
        p2.Name = 'Test Program';
        p2.Launchpad__Active__c = 'Yes';
        insert p2;
        
        Test.stopTest();
    }

}