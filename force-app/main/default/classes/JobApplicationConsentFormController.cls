public class JobApplicationConsentFormController {
    @InvocableMethod(label='Send Consent Form Email' description='Sends an email to the guardian email')
    public static void sendConsentFormEmail(List<List<Id>> applications){
       ConsentFormBatchEmail batch = new ConsentFormBatchEmail(applications[0]);
	   Database.executeBatch(batch, 50);
        /*List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        EmailTemplate et = [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName ='Consent_Form_Email_Template'];
        for(Launchpad__Applicant_Tracking__c app : applications){
            
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
        System.Debug('About to send mail');
            Messaging.sendEmail(emailList);
        }*/
    }
    
    
}