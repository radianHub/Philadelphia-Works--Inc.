public class JobApplicationConsentFormController {
    @InvocableMethod(label='Send Consent Form Email' description='Sends an email to the guardian email')
    public static void sendConsentFormEmail(List<Launchpad__Applicant_Tracking__c> applications){
       
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
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
            
            emailList.add(mail); 
        }
        
        if(!Test.isRunningTest()){
            Messaging.sendEmail(emailList);
        }
    }
    
    
}