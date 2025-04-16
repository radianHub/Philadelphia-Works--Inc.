public class JobApplicationTriggerHandler {
    public static Set<Id> setExecutedRecords = new Set<Id>();
    
    public static void main(List<Launchpad__Applicant_Tracking__c> applications, Map<Id, Launchpad__Applicant_Tracking__c> oldMap){
        System.debug('%%%%%%%%%ExecutedRecords: ' + setExecutedRecords);
        
        Set<Id> triggerContextRecords = new Set<Id>();
        
       //--------------------------------------BEGIN RECURSION CHECK-----------------------------------------------//
       List<Launchpad__Applicant_Tracking__c> tempApplicationList =  new List<Launchpad__Applicant_Tracking__c>();
        
        for(Launchpad__Applicant_Tracking__c app : applications){
            if(!setExecutedRecords.contains(app.Id)){
                tempApplicationList.add(app);
            }
        }
        
        if(tempApplicationList.size() == 0){
            return;
        }
        
        
        for(Launchpad__Applicant_Tracking__c app : tempApplicationList){
            triggerContextRecords.add(app.Id);
        }
        beginMatchingProcess(tempApplicationList, triggerContextRecords, oldMap);
        //-------------------------------------END RECURSION CHECK---------------------------------------------------//
    }
        public static void beginMatchingProcess(List<Launchpad__Applicant_Tracking__c> applications, Set<Id> triggerContextRecords, Map<Id, Launchpad__Applicant_Tracking__c> oldMap){
            
            Map<Id, List<Launchpad__Applicant_Tracking__c>> contactToAppsMap = new Map<Id, List<Launchpad__Applicant_Tracking__c>>();
            
            for(Launchpad__Applicant_Tracking__c app : applications){
                triggerContextRecords.add(app.Id);
                setExecutedRecords.add(app.Id);
                
                if(contactToAppsMap.get(app.Launchpad__Participant__c) == null){
                    contactToAppsMap.put(app.Launchpad__Participant__c, New List<Launchpad__Applicant_Tracking__c>{app});
                }else{
                    List<Launchpad__Applicant_Tracking__c> tempList = contactToAppsMap.get(app.Launchpad__Participant__c);
                    tempList.add(app);
                    contactToAppsMap.put(app.Launchpad__Participant__c, tempList);
                }
            }
            
            handleAllRelatedRecordsMatching(contactToAppsMap, triggerContextRecords, oldMap);
        }
    
    public static void handleAllRelatedRecordsMatching(Map<Id, List<Launchpad__Applicant_Tracking__c>> contactToAppsMap, Set<Id> triggerContextRecords, Map<Id, Launchpad__Applicant_Tracking__c> oldMap){
        List<Launchpad__Applicant_Tracking__c> masterAppUpdateList = new List<Launchpad__Applicant_Tracking__c>();
        Set<Id> contactIdSet = new Set<Id>();
        
        for(Id contactId : contactToAppsMap.keySet()){
            contactIdSet.add(contactId);
        }
        
        List<Launchpad__Applicant_Tracking__c> allApps = [SELECT Id, Launchpad__Stage__c, Previous_Stage__c, Launchpad__Participant__c, Provider_Rank__c, Provider_Choice__c 
                                                          FROM Launchpad__Applicant_Tracking__c
                                                          WHERE Program__r.Launchpad__Active__c = 'Yes'
														  AND Program__r.RecordType.Name = 'Session'
                                                          AND Launchpad__Participant__c IN :contactIdSet
                                                          AND Id NOT IN :triggerContextRecords
                                                          ];
        
        for(Launchpad__Applicant_Tracking__c app : allApps){
                
                if(contactToAppsMap.get(app.Launchpad__Participant__c) == null){
                    contactToAppsMap.put(app.Launchpad__Participant__c, New List<Launchpad__Applicant_Tracking__c>{app});
                }else{
                    List<Launchpad__Applicant_Tracking__c> tempList = contactToAppsMap.get(app.Launchpad__Participant__c);
                    tempList.add(app);
                    contactToAppsMap.put(app.Launchpad__Participant__c, tempList);
                }
            }
        for(Id contactId : contactToAppsMap.keySet()){
            for(Launchpad__Applicant_Tracking__c app : contactToAppsMap.get(contactId)){
                if(oldmap != null){
                   if(oldMap.get(app.Id) != null){
                       if(oldMap.get(app.Id).Launchpad__Stage__c != null && oldMap.get(app.Id).Launchpad__Stage__c == 'Matched with Provider' && (app.Launchpad__Stage__c == 'Passed' || app.Launchpad__Stage__c == 'Shortlisted')){
                            contactToAppsMap.put(contactId, handleUnmatched(contactToAppsMap.get(contactId), app));
                       } 
                    } 
                }
                
                
            }
        }
        
        for(Id contactId : contactToAppsMap.keySet()){
            List<Launchpad__Applicant_Tracking__c> tempListForMatched = getHighestRankedApp(contactToAppsMap.get(contactId));
            if(tempListForMatched != null){
                contactToAppsMap.put(contactId, tempListForMatched);
                masterAppUpdateList.addAll(tempListForMatched);
            }else{
                masterAppUpdateList.addAll(contactToAppsMap.get(contactId));
            }
        }
        
        
    
        
        //--------------------------------Final Update of Triggering Records and Related Records-----------------------//
        List<Launchpad__Applicant_Tracking__c> masterAppUpdateListNoTriggerContextRecords = new List<Launchpad__Applicant_Tracking__c>();
        for(Integer i = 0; i < masterAppUpdateList.size(); i++){
            setExecutedRecords.add(masterAppUpdateList[i].Id);
            
            System.debug('!triggerContextRecords.contains(masterAppUpdateList[i].Id): ' + !triggerContextRecords.contains(masterAppUpdateList[i].Id) + ' : ' + masterAppUpdateList[i].Id);
            if(!triggerContextRecords.contains(masterAppUpdateList[i].Id)){
                masterAppUpdateListNoTriggerContextRecords.add(masterAppUpdateList[i]);
            }
        }
        for(Launchpad__Applicant_Tracking__c app : masterAppUpdateListNoTriggerContextRecords){
            System.debug('masterAppUpdateListNoTriggerContextRecords member: '  + app);
        }
        update masterAppUpdateListNoTriggerContextRecords;
        //--------------------------------Final Update of Triggering Records and Related Records-----------------------//
   
    }
    
    public static List<Launchpad__Applicant_Tracking__c> handleUnmatched(List<Launchpad__Applicant_Tracking__c> applications, Launchpad__Applicant_Tracking__c matchedApp){
        
        for(Launchpad__Applicant_Tracking__c app : applications){
            if(app.Id != matchedApp.Id){
                app.Launchpad__Stage__c = app.Provider_Choice__c != null ? app.Provider_Choice__c : 'Submitted';
                setExecutedRecords.add(app.Id);
            }
        }
        return applications;
        
    }
    
    public static List<Launchpad__Applicant_Tracking__c> getHighestRankedApp(List<Launchpad__Applicant_Tracking__c> applications){
        boolean returnNull = true;
        
        Launchpad__Applicant_Tracking__c highestRankedApp = null;
        for(Launchpad__Applicant_Tracking__c app : applications){
            System.debug('IN getHighestRankedApp looping through: ' + app.Id + ' : ' + app.Launchpad__Stage__c);
            if(app.Launchpad__Stage__c == 'Provider Selected'){
                returnNull = false;
                highestRankedApp = app;
            }
        }
        if(returnNull == true){
            System.debug('Returning null');
            return null;
            
        }
        
       
        
        for(Launchpad__Applicant_Tracking__c app : applications){
            if(app.Provider_Rank__c < highestRankedApp.Provider_Rank__c && app.Launchpad__Stage__c == 'Provider Selected'){
                highestRankedApp = app;
            }
        }
        
        highestRankedApp.Launchpad__Stage__c = 'Matched with Provider';
        
        for(Launchpad__Applicant_Tracking__c app : applications){
            if(app.Id != highestRankedApp.Id){
                app.Launchpad__Stage__c = 'Unavailable';
            }
        }
        
        for(Launchpad__Applicant_Tracking__c app : applications){
            System.debug('Returning app: ' + app.Id + ' : ' + app.Launchpad__Stage__c);
        }
	 	return applications;
    }
    
}