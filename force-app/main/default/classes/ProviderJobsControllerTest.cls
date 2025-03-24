/**
 * Created by holden on 3/21/25.
 */

@IsTest
private class ProviderJobsControllerTest {

    @TestSetup
    static void setup() {
        Account account = new Account();
        account.Name = 'Test Account';
        insert account;

        Contact supervisor = new Contact();
        supervisor.FirstName = 'Test';
        supervisor.LastName = 'Supervisor';
        supervisor.AccountId = account.Id;
        insert supervisor;

        Launchpad__Job__c job = new Launchpad__Job__c();
        job.Name = 'Test Job';
        job.Launchpad__Contact__c = supervisor.Id;
        job.Launchpad__Account__c = account.Id;
        insert job;
    }

    @IsTest
    static void testController() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        Test.startTest();
        Launchpad__Job__c[] jobs = ProviderJobsController.getJobs(accountId);
        Launchpad__Job__c job = ProviderJobsController.getJob(jobs[0].Id, 'Launchpad__Advanced_Job_Search_Filters');
        job.Name = 'Updated Job';
        ProviderJobsController.updateJob(job);
        Test.stopTest();
    }

}