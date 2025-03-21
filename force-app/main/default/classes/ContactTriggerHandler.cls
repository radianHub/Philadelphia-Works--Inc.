public class ContactTriggerHandler {
    public static Boolean runOnce = false;
    public static void handleAccountProcess(List<Contact> contacts){
       
        Set<Id> contactIds = new Set<Id>();
        for(Contact c : contacts){
            contactIds.add(c.Id);
        }
        
        makeUpdatesAsync(contactIds);
   
    }
    
    @future
    public static void makeUpdatesAsync(Set<Id> contactIds){
        List<Contact> contacts = [SELECT Id, LastName, MailingCity, MailingStreet, MailingState, MailingPostalCode, AccountId, Account.Name, recordType.Name FROM Contact WHERE Id IN :contactIDs];
        List<Contact> consToUpdate = new List<Contact>();
        Set<Id> consWithNewAccounts = new Set<Id>();
        List<Account> accountsToInsert = new List<Account>();
        Map<String, Account> conIdToAccountMap = new Map<String, Account>();
        RecordType householdRecordType = [SELECT Id, Name FROM RecordType WHERE Name = 'Household'];
        
        List<Account> allAccountList = [SELECT Id, Name, BillingCity, BillingStreet, BillingState, recordType.Name FROM Account];
        Map<String, List<Account>> accountNameToObjectMap = new Map<String,List<Account>>();
        
        for(Account a : allAccountList){
            if(accountNameToObjectMap.get(a.Name) == null){
                List<Account> tempList = new List<Account>();
                tempList.add(a);
                accountNameToObjectMap.put(a.Name, tempList);
            }else{
                List<Account> tempList = accountNameToObjectMap.get(a.Name);
                tempList.add(a);
                accountNameToObjectMap.put(a.Name, tempList);
            }
            
        }
        
        for(Contact contact : contacts){
            if(contact.recordType.Name != 'Job Seeker'){
                continue;
            }
            
            String tempName = contact.LastName + ' Household';
           //List<Account> accountList = [SELECT Id, Name, BillingCity, BillingStreet, BillingState, recordType.Name FROM Account WHERE Name = :tempName ];
            List<Account> accountList = accountNameToObjectMap.get(tempName);
            if(accountList == null){
                Account newAccount = new Account();
                newAccount.Name = contact.LastName != null ? contact.LastName + ' Household' : 'Unnamed Account';
                newAccount.BillingStreet = contact.MailingStreet != null ? contact.MailingStreet : null;
                newAccount.BillingCity = contact.MailingCity != null ? contact.MailingCity : null;
                newAccount.BillingState = contact.MailingState != null ? contact.MailingState : null;
                newAccount.BillingPostalCode = contact.MailingPostalCode  != null ? contact.MailingPostalCode  : null;
                newAccount.BillingCountry = 'USA';
                newAccount.RecordTypeId = householdRecordType.Id;
                
                accountsToInsert.add(newAccount);
                consWithNewAccounts.add(contact.Id);
            }else{
                for(Account a : accountList){
                    if(a.BillingCity == contact.MailingCity && a.BillingStreet == contact.MailingStreet && a.BillingState == contact.MailingState){
                        contact.AccountId = a.Id;
                    }
            	}
                consToUpdate.add(contact);
            }
            
            
        }
        
        insert accountsToInsert;
        
        if(consWithNewAccounts.size() > 0){
            Map<String, Id> accountNameToIdMap = new Map<String, Id>();
            for(Account a : [SELECT Id, Name FROM Account WHERE CreatedDate = TODAY]){
            	accountNameToIdMap.put(a.Name, a.Id);
        	}
            for(Contact c : contacts){
                if(consWithNewAccounts.contains(c.Id)){
                    String tempName = c.LastName + ' Household';
                    if(accountNameToIdMap.get(tempName) != null){
                        c.AccountId = accountNameToIdMap.get(tempName);
                        consToUpdate.add(c);
                        
                    }
                }
            }
        }
        update consToUpdate;
   }
}