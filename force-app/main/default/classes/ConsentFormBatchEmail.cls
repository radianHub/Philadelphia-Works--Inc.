public class ConsentFormBatchEmail implements Database.Batchable<sObject> {
    private List<Id> applicationList;
    
    public ConsentFormBatchEmail(List<Id> applications) {
        this.applicationList = applications;
    }
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id, Guardian_Email__c FROM Launchpad__Applicant_Tracking__c WHERE Id IN :applicationList');
    }

    public void execute(Database.BatchableContext BC, List<Launchpad__Applicant_Tracking__c> scope) {
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        EmailTemplate et = [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName ='Consent_Form_Email_Template'];
        
        for(Launchpad__Applicant_Tracking__c app : scope){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            mail.setTemplateId(et?.Id);
            
            List<String> toAddresses = new List<String>();
            toAddresses.add(app.Guardian_Email__c); 
            
            mail.setToAddresses(toAddresses);  
           
            mail.setSubject('Test Email from Apex'); 
            
            String href = 'https://philaworks--developer.sandbox.my.site.com/youth/s/consentform?recordId=' + String.valueOf(app.Id) ;
            
            String emailBody = et?.HtmlValue;
            emailBody += ' <br/> <a href='+href+' target=_blank> Click here to view the Consent Form</a><br><br>';
            mail.setHTMLBody(emailBody); 
            
            mail.setSaveAsActivity(false);
            mail.setUseSignature(false);
            System.debug('About to add mail');
            emailList.add(mail); 
        }
        
        if(!Test.isRunningTest()){
        	Messaging.sendEmail(emailList);
        }
    }

    public void finish(Database.BatchableContext BC) {
    }
}