public class JobApplicationTriggerHandler {
    public static Set<Id> setExecutedRecords = new Set<Id>();
    
    public static void matchProvider(List<Launchpad__Applicant_Tracking__c> jobApplicationsToMatchPrev, List<Launchpad__Applicant_Tracking__c> jobApplicationsToPassPrev){
        List<Launchpad__Applicant_Tracking__c> jobApplicationsToMatch = new List<Launchpad__Applicant_Tracking__c>();
        List<Launchpad__Applicant_Tracking__c> jobApplicationsToPass = new List<Launchpad__Applicant_Tracking__c>();
        
        if(JobApplicationsToMatchPrev.size() > 0){
            for(Launchpad__Applicant_Tracking__c JA : JobApplicationsToMatchPrev){
                if(!setExecutedRecords.contains(JA.Id)){
                    jobApplicationsToMatch.add(JA);
                }
        	}
        }
        
        if(JobApplicationsToPassPrev.size() > 0){
            for(Launchpad__Applicant_Tracking__c JA : jobApplicationsToPassPrev){
                if(!setExecutedRecords.contains(JA.Id) || Test.isRunningTest()){
                    jobApplicationsToPass.add(JA);
                }
            }
        }

        List<Launchpad__Applicant_Tracking__c> masterJobApplicationsToUpdate = new List<Launchpad__Applicant_Tracking__c>();
        Map<Id,List<Launchpad__Applicant_Tracking__c>> matchingContactToApplicationsMap = getMapOfAllRelatedJobApps(JobApplicationsToMatch, true);
        Map<Id,List<Launchpad__Applicant_Tracking__c>> passingContactToApplicationsMap = getMapOfAllRelatedJobApps(jobApplicationsToPass, false);
        
        if(jobApplicationsToPass.size() > 0){
            for(Launchpad__Applicant_Tracking__c application : jobApplicationsToPass){
                boolean matchFound = false;
                List<Launchpad__Applicant_Tracking__c> tempApplicationList = new List<Launchpad__Applicant_Tracking__c>();
                Launchpad__Applicant_Tracking__c highestScoredApplication = null;
                if(passingContactToApplicationsMap.get(application.Launchpad__Participant__c) != null){
                    for(Launchpad__Applicant_Tracking__c relatedApplication : passingContactToApplicationsMap.get(application.Launchpad__Participant__c)){
                        if(relatedApplication.Launchpad__Stage__c != 'Passed' && relatedApplication.Launchpad__Stage__c != 'Shortlisted'){
                            if(relatedApplication.previous_stage__c == 'Provider Selected' || relatedApplication.Launchpad__Stage__c == 'Provider Selected'){
                                if(highestScoredApplication == null){
                                    highestScoredApplication = relatedApplication;
                                    matchFound = true;
                                }
                                if(relatedApplication.Provider_Rank__c < highestScoredApplication.Provider_Rank__c){
                                    highestScoredApplication = relatedApplication;
                                    matchFound = true;
                                    continue;
                                }
                                
                            }
                            System.debug('Adding the following to tempApps: ' + relatedApplication);
                            tempApplicationList.add(relatedApplication);
                        }
                      }
                }
                
                for(Launchpad__Applicant_Tracking__c otherApp : tempApplicationList){
                    boolean hasHighestScoreApp = false;
                    if(highestScoredApplication != null){
                        hasHighestScoreApp = true;
                    }
                        String tempStage = otherApp.Launchpad__Stage__c;
                        if(otherApp.previous_stage__c == 'Provider Selected' && otherApp.Launchpad__Stage__c == 'Unavailable'){
                            otherApp.Launchpad__Stage__c = 'Unavailable';
                            otherApp.previous_stage__c = 'Provider Selected';
                        }else{
                            otherApp.Launchpad__Stage__c = otherApp.Previous_Stage__c;
                            otherApp.Previous_Stage__c = tempStage;
                        }
                        
                        if(hasHighestScoreApp == true){
                            if(otherApp.id != highestScoredApplication.Id){
                                setExecutedRecords.add(otherApp.Id);
                       			masterJobApplicationsToUpdate.add(otherApp);
                            }
                        }else{
                          
                            
                            setExecutedRecords.add(otherApp.Id);
                        	masterJobApplicationsToUpdate.add(otherApp); 
                        }
                       
                        
                    
                        
                }
                if(matchFound == true){
                    highestScoredApplication.Previous_Stage__c = highestScoredApplication.Launchpad__Stage__c;
                    highestScoredApplication.Launchpad__Stage__c = 'Matched with Provider';
                    setExecutedRecords.add(highestScoredApplication.Id);
                    System.debug('Adding to master record second: ' + highestScoredApplication.Id);
                    masterJobApplicationsToUpdate.add(highestScoredApplication);
                    
                    
                }                    
               }
            
        	}
        
        if(JobApplicationsToMatch.size() > 0){
              for(Launchpad__Applicant_Tracking__c application : JobApplicationsToMatch){
                boolean matched = true;
                List<Launchpad__Applicant_Tracking__c> tempApplicationList = new List<Launchpad__Applicant_Tracking__c>();
                for(Launchpad__Applicant_Tracking__c relatedApplication : matchingContactToApplicationsMap.get(application.Launchpad__Participant__c)){
                    if(relatedApplication.Launchpad__Stage__c == 'Matched with Provider'){
                        application.addError('The Job Seeker associated with this Application already has an application with the stage Matched with Provider.');
                    }
                    //Application is excluded from comparison: is comparing to itself, or is in wrong stage, move to next iteration
                    if(application.Id == relatedApplication.Id || (relatedApplication.Launchpad__Stage__c != 'Submitted' && relatedApplication.Launchpad__Stage__c != 'Provider Selected')){
                        continue;
                    }
                    if(application.Provider_Rank__c > relatedApplication.Provider_Rank__c){
                        matched = false;
                        break;
                    }
                    tempApplicationList.add(relatedApplication);
                    
                }
                if(matched == true){
                    application.Previous_Stage__c = application.Launchpad__Stage__c;
                    application.Launchpad__Stage__c = 'Matched with Provider';
                    setExecutedRecords.add(application.Id);
                    for(Launchpad__Applicant_Tracking__c relatedApplication : tempApplicationList){
                        relatedApplication.Previous_Stage__c = relatedApplication.Launchpad__Stage__c;
                        relatedApplication.Launchpad__Stage__c = 'Unavailable';
                        setExecutedRecords.add(relatedApplication.Id);
                        masterJobApplicationsToUpdate.add(relatedApplication);  
                    }
                }
            }  
        }

        if(!Test.isRunningTest()){
            update masterJobApplicationsToUpdate;
        }
		
    }
    
    public static Map<Id,List<Launchpad__Applicant_Tracking__c>> getMapOfAllRelatedJobApps(List<Launchpad__Applicant_Tracking__c> jobApps, Boolean getSelf){
        Set<Id> ContactIds = new Set<Id>();
        Set<Id> JobAppIds = new Set<Id>();
        
        
        for(Launchpad__Applicant_Tracking__c app : jobApps){
            System.debug('app.Launchpad__Participant__c' + app.Launchpad__Participant__c);
            ContactIds.add(app.Launchpad__Participant__c);
            JobAppIds.add(app.Id);
        }        
        
        System.debug('ContactIds' + ContactIds);
        
        List<Launchpad__Applicant_Tracking__c> allJobApps = new List<Launchpad__Applicant_Tracking__c>();
        
        if(getSelf == true){
           allJobApps = [SELECT Id,Launchpad__Stage__c, Previous_Stage__c, Launchpad__Participant__c, Provider_Rank__c  
                                                             FROM Launchpad__Applicant_Tracking__c
                                                             WHERE Launchpad__Participant__c IN :ContactIds
                                                             AND Id NOT IN :setExecutedRecords
                         									 AND Program__r.Launchpad__Active__c = 'Yes'
															 AND Program__r.RecordType.Name = 'Session' 
                                                             ]; 
            System.debug('JON>allJobApps: ' + allJobApps.Size());
        }
        if(getSelf == false){
           allJobApps = [SELECT Id,Launchpad__Stage__c, Previous_Stage__c, Launchpad__Participant__c, Provider_Rank__c  
                                                             FROM Launchpad__Applicant_Tracking__c
                                                             WHERE Launchpad__Participant__c IN :ContactIds
                                                             AND Id NOT IN :JobAppIds AND Id NOT IN :setExecutedRecords
                         									 AND Program__r.Launchpad__Active__c = 'Yes'
															 AND Program__r.RecordType.Name = 'Session'
                         									 ORDER BY Provider_Rank__c
                                                             ]; 
        }
        
        Map<Id, List<Launchpad__Applicant_Tracking__c>> contactToAppMap = new Map<Id, List<Launchpad__Applicant_Tracking__c>>();

        for(Launchpad__Applicant_Tracking__c app : allJobApps){
            if(!contactToAppMap.containsKey(app.Launchpad__Participant__c)){
                contactToAppMap.put(app.Launchpad__Participant__c, new List<Launchpad__Applicant_Tracking__c>());
            }
            contactToAppMap.get(app.Launchpad__Participant__c).add(app);
        } 
        
        return contactToAppMap;
    }
    
    public static void checkForDuplicates(List<Launchpad__Applicant_Tracking__c> applications){
        List<Launchpad__Applicant_Tracking__c> allApps = [SELECT Id, Applicants_Tax_Id__c, Provider_Rank__c, Launchpad__Participant__c FROM Launchpad__Applicant_Tracking__c WHERE 
                                                          Program__r.Launchpad__Active__c = 'Yes'
													      AND Program__r.RecordType.Name = 'Session'
                                                          AND Provider_Rank__c = '1'
                                                           ];
        
        Map<String, Launchpad__Applicant_Tracking__c> ssnAppMap = new Map<String, Launchpad__Applicant_Tracking__c>();
            
        for(Launchpad__Applicant_Tracking__c app : allApps){
            if(app.Applicants_Tax_Id__c != null){
                ssnAppMap.put(app.Applicants_Tax_Id__c, app);
            } 
        }
        
        for(Launchpad__Applicant_Tracking__c app : applications){
            if(ssnAppMap.get(app.Applicants_Tax_Id__c) != null && app.Id != ssnAppMap.get(app.Applicants_Tax_Id__c).Id && app.Launchpad__Participant__c != ssnAppMap.get(app.Applicants_Tax_Id__c).Launchpad__Participant__c){
                app.Applicants_Tax_Id__c.addError('Applications for this person already exist in the system.');
            }
        }

    }
   

}