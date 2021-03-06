/**
 * @File Name          : JobButtons.cls
 * @Description        : 
 * @Author             : Sean Gray
 * @Group              : 
 * @Last Modified By   : Sean Gray
 * @Last Modified On   : 2/2/2020, 3:03:59 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    2/1/2020   Sean Gray     Initial Version
**/
public with sharing class JobButtons {
    @AuraEnabled
    public static Date projectNoteDate(String recordId){
         if(recordId != null){
        List<ATI_Job__c> job = [Select Id, Estimated_Completion_Date_Per_PD__c FROM ATI_Job__c WHERE Id =: recordId];
        system.debug('Job info is : '+' Job Info 0 is : ' + job);
       
        return job[0].Estimated_Completion_Date_Per_PD__c;
        }else{
            return null;
        }
    }
     @AuraEnabled
     public static Decimal projectNotePercent(String recordId){
         if(recordId != null){
        List<ATI_Job__c> job = [Select Id, Percent_Complete__c FROM ATI_Job__c WHERE Id =: recordId];

       
        return job[0].Percent_Complete__c;
        }else{
            return null;
        }
    }
    @AuraEnabled
    public static String createTaskProjectNote(Decimal percent, String recordId, String ownerId, String workCompleted, String workStarted, Date completionDate, String insured, String supplement, String repairComments){
        ATI_Job__c job = [Select Id, office2__c, Project_Manager__c, Project_manager_new__c, lead_source__c, Name, Percent_Complete__c, Estimated_Completion_Date_Per_PD__c FROM ATI_Job__c WHERE Id =: recordId];
        List<office__c> office = [Select Id, office_manager__c, project_coordinator__c, project_admin_two__c FROM Office__c WHERE id =:job.office2__c];
        system.debug('Working + ' + ownerId);
        string comments = '\n' + 'Project Note: ' + job.name +'\n' + '\n' + '\n' + 'Percent of Job Complete: ' + percent + '%' + '\n' +'\n' + 'Work/Trades started/completed since last week: ' + workCompleted + '\n' +'\n' + 'Work to be started this week: '+ workStarted + '\n' + '\n' +'Estimated completion date Per PM: '+ completionDate + '\n' + '\n' +'Has Insured/Member completed all selections? Y/N:' + insured + '\n' +'\n' + 'Potential Supplement?Y/N: '+ supplement + '\n' +'\n' + 'Repair Update Comments: ' + repairComments;
        Task t = new Task( Type = 'Project Note', ActivityDate = system.today(), Description = comments, OwnerId = ownerId, Priority = 'Low', Status='Completed', Subject = 'Project Note', WhatId = recordId);
        
        insert t;
        system.debug('Task '+ t);
        FeedItem post = new FeedItem();
        post.ParentId = recordId;
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        ConnectApi.MentionSegmentInput mentionSegmentInput1 = new ConnectApi.MentionSegmentInput();
        ConnectApi.MentionSegmentInput mentionSegmentInput2 = new ConnectApi.MentionSegmentInput();
        ConnectApi.MentionSegmentInput mentionSegmentInput3 = new ConnectApi.MentionSegmentInput();
        if(job.lead_source__c.startsWith('Program') && office != null && office[0].project_admin_two__c != null){
        mentionSegmentInput3.id = office[0].project_admin_two__c;
        messageBodyInput.messageSegments.add(mentionSegmentInput3);
        }
        if(job.Project_Manager__c != null){
        mentionSegmentInput.id = job.project_manager__c;
        messageBodyInput.messageSegments.add(mentionSegmentInput);
        }
        if(job.Project_Manager_new__c != null){
            mentionSegmentInput1.id = job.project_manager_new__c;
             messageBodyInput.messageSegments.add(mentionSegmentInput1);
        }
        if(job.lead_source__c.startsWith('Program') && office != null && office[0].project_coordinator__c != null){
             mentionSegmentInput2.id = office[0].project_coordinator__c;
            messageBodyInput.messageSegments.add(mentionSegmentInput2);
        }
       
        
        //messageBodyInput.messageSegments.add(mentionSegmentInput1);
        
        textSegmentInput.text = comments;
        messageBodyInput.messageSegments.add(textSegmentInput);
        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.subjectId = recordId;
        if(Test.isRunningTest()){return 'success';}
        else{
        ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
        UpdateProjectNote(job.id, completionDate, percent);
        // job.Percent_Complete__c = percent;
        // job.Estimated_Completion_Date_Per_PD__c = completionDate;
        // update job;
        return 'Success';
        }
//insert feedElement;

       
    }
    
    @future
    public static void UpdateProjectNote(Id JobID, Date estimatedCompletionDate, Decimal percent){
        ATI_Job__c job = new ATI_Job__c(ID = JobID, Estimated_completion_date_per_PD__c = estimatedCompletionDate, percent_complete__c = percent);
        update job;
    }

    @AuraEnabled
    public static string PMAssignmentQuery(String recordId){
        
        ATI_Job__c job = [Select Id, Account__r.Name, lead_source__c, amount__c,total_billing_forecast_amount__c, Insurance_Adjuster_Broker__c, contact__c,office2__c, Project_Manager__c, Project_manager_new__c, Name, Percent_Complete__c, Estimated_Completion_Date__c, completion_date__c FROM ATI_Job__c WHERE Id =: recordId];
        List<office__c> office = [Select Id, office_manager__c, project_coordinator__c, regional_manager__c FROM Office__c WHERE id =:job.office2__c];
        //List<Contact> cont = [Select Name FROM Contact Where Id =: job.contact__c];
        // Contact ins = new Contact();
        // if(job.Insurance_Adjuster_Broker__c != null){
        // ins = [Select Name FROM Contact Where Id =: job.Insurance_Adjuster_Broker__c Limit 1];
        // }
        List<Budget__c> bud = new List<Budget__c>();
        bud = [Select Name, Total_Allocations__c, Total_Program_Fees_New__c, Total_Budget_Goal__c, ATI_Job__c FROM Budget__c Where ATI_Job__c =:job.id Order By createdDate DESC Limit 1];
        Budget__c bu = new Budget__c();
        for(budget__c b : bud){
            bu = b;
        }
        String PMAssignmentResults;
        // if(!ins.isEmpty()){
        PMAssignmentResults = '{"Insurance":"'+ job.Account__r.Name + ' ' + job.lead_source__c +'", "Fees":"'+bu.Total_Program_Fees_New__c+'","Allocation":"'+ bu.Total_Allocations__c +'", "Price":"'+ job.amount__c +'", "Budget":"'+ bu.Total_Budget_Goal__c +'", "Forecast":"'+ job.total_billing_forecast_Amount__c +'"}';  
        // }else{
        // PMAssignmentResults = '{"Insurance":"'+ 'Null' +'", "Fees":"'+bud[0].Total_Program_Fees_New__c+'","Allocation":"'+ bud[0].Total_Allocations__c +'", "Price":"'+ job.amount__c +'", "Budget":"'+ bud[0].Total_Budget_Goal__c +'", "Forecast":"'+ job.total_billing_forecast_Amount__c +'"}';
        // }
            system.debug('JSON set up : ' + PMAssignmentResults);
            return PMAssignmentResults;
    }

    public class JSONWrapper{
        public List<Id> ContactString {get;set;}
        public List<Id> ProjectManagerString {get;set;}
    }
    @AuraEnabled
    public static string PMAssignmentChatter(Date startDate, String recordId, String ownerId, Date completionDate,  String notes, String briefScope,String PackagedJSON){
        system.debug('StartDate ' + startDate + ' Record Id ' + recordId);
        JSONWrapper ContactID;
        Id conId;
        Id projectManagerId;
        system.debug('JSON is ' + PackagedJSON);
        ContactID = (JSONWrapper)JSON.deserialize(PackagedJSON, JSONWrapper.class);
        for(Id ca : ContactID.ContactString){
        conId = ca;
        }
        for(Id ca1 : ContactID.ProjectManagerString){
        projectManagerId = ca1;
        }
         Contact contactName = new Contact();
         contactName = [Select Name, mobilephone FROM Contact Where Id =: conId];
        User pm = [Select Name FROM User WHere Id =: projectManagerId];
         
        ATI_Job__c job = [Select Id, amount__c,total_billing_forecast_amount__c,Account__r.Name, Lead_Source__c, contact__c,office2__c, Project_Manager__c, Project_manager_new__c, Name, Percent_Complete__c, Estimated_Completion_Date_Per_PD__c, completion_date__c FROM ATI_Job__c WHERE Id =: recordId];
        List<office__c> office = [Select Id, office_manager__c, project_coordinator__c, branch_manager__c FROM Office__c WHERE id =:job.office2__c];
        //  Contact ins = new Contact();
        //  if(job.Insurance_Adjuster_Broker__c != null){
        // ins = [Select Name FROM Contact Where Id =: job.Insurance_Adjuster_Broker__c];
        //  }
        List<Budget__c> bud = [Select Name, Total_Allocations__c, Total_Program_Fees_New__c, Total_Budget_Goal__c, ATI_Job__c FROM Budget__c Where ATI_Job__c =:job.id Order By createdDate DESC Limit 1];
        system.debug('Working + ' + ownerId);
        Budget__c bu = new Budget__c();
        for(budget__c b : bud){
            bu = b;
        }
        String contactUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + conId;
        //if(!bud.isempty()){
        //string comments = '\n' + 'PM Assignment: ' + job.name +'\n' + '\n' + '\n' + 'Insurance Carrier/TPA: ' + ins.name +'\n' + 'Fees: ' + bu.Total_Program_Fees_New__c + '\n' + 'Allocation: '+ bu.Total_Allocations__c + '\n'  +'Price: '+ job.amount__c + '\n'  +'Budget: ' + bu.Total_Budget_Goal__c + '\n' + 'Contract Start Date: '+ startDate + '\n' + 'Contract Completion Date: ' + completionDate + '\n' + 'Forecast: '+ job.total_billing_forecast_Amount__c +'\n' + 'Brief Scope: '+briefScope+'\n' + 'Notes: '+notes +'\n' + 'ContactInfo: '+contactInfo+'\n' + 'Suggested PM: ' + projectManager; 
        string comments = '\n' + 'PM Assignment: ' + job.name +'\n' + '\n' + '\n' + 'Insurance Carrier/TPA: ' + job.Account__r + ' ' + job.lead_source__c  +'\n' + 'Fees: ' + bu.Total_Program_Fees_New__c + '\n' + 'Allocation: '+ bu.Total_Allocations__c + '\n'  +'Price: '+ job.amount__c + '\n'  +'Budget: ' + bu.Total_Budget_Goal__c + '\n' + 'Contract Start Date: '+ startDate + '\n' + 'Contract Completion Date: ' + completionDate + '\n' + 'Forecast: '+ job.total_billing_forecast_Amount__c +'\n' + 'Brief Scope: '+briefScope+'\n' + 'Notes: '+notes +'\n' + 'ContactInfo: '+ contactName.Name +  '\n' + 'Suggested PM: ' + pm.Name;
        
        //Task t = new Task( Type = 'Project Note', ActivityDate = system.today(), Description = comments, OwnerId = ownerId, Priority = 'Low', Status='Completed', Subject = 'Project Note', WhatId = recordId);
        //insert t;
        //system.debug('Task '+ t);
        //FeedItem post = new FeedItem();
        //post.ParentId = recordId;
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        ConnectApi.MentionSegmentInput mentionSegmentInput1 = new ConnectApi.MentionSegmentInput();
        ConnectApi.MentionSegmentInput mentionSegmentInput2 = new ConnectApi.MentionSegmentInput();
        mentionSegmentInput.id = job.project_manager__c;
        //mentionSegmentInput1.id = job.project_manager_new__c;
        if(office != null && office[0].office_manager__c != null){
             mentionSegmentInput1.id = office[0].office_manager__c;
            messageBodyInput.messageSegments.add(mentionSegmentInput1);
        }
        if(office != null && office[0].branch_manager__c != null){
             mentionSegmentInput2.id = office[0].branch_manager__c;
            messageBodyInput.messageSegments.add(mentionSegmentInput2);
        }
       
        //messageBodyInput.messageSegments.add(mentionSegmentInput);
       // messageBodyInput.messageSegments.add(mentionSegmentInput1);
        
        textSegmentInput.text = comments;
        messageBodyInput.messageSegments.add(textSegmentInput);
        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.subjectId = recordId;
        ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
        //job.estimated_completion_date_per_PD__c = completionDate;
        UpdateCompletionDatePerPM(job.id, completionDate, projectManagerId);
       //update job;
//insert feedElement;
        approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval. Details are: ' + comments);
        req1.setObjectId(recordId);
        // Submit on behalf of a specific submitter
        req1.setSubmitterId(UserInfo.getUserId());
        // Submit the record to specific process and skip the criteria evaluation
        req1.setProcessDefinitionNameOrId('PMAssignmentApproval');
        req1.setSkipEntryCriteria(true);
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);

        return 'Success';
    }
    @future
    public static void UpdateCompletionDatePerPM(Id JobID, Date completionDatePerPD, Id ProjectManagerId){
        ATI_Job__c job = new ATI_Job__c(ID = JobID, Estimated_Completion_Date__c = completionDatePerPD, Suggested_PM__c = ProjectManagerId, PM_Assignment_Status__c = 'Sent for Approval');
        update job;
    }


    @AuraEnabled
    public static string JobCaseInfo(Id recordId){
    ATI_Job__c job = [Select Id, project_site_contact_name__c FROM ATI_Job__c Where Id =: recordId];
    if(job.project_Site_contact_name__c != null){
    return job.project_site_contact_Name__c;
    }else{
        return null;
    }
    }
    @AuraEnabled
    public static string ContactAccount(Id recordId){
    ATI_Job__c job = [Select Id, project_site_contact_name__c FROM ATI_Job__c Where Id =: recordId];
    
    if(job.project_Site_contact_name__c != null){
        system.debug('Job project site contact ' + job.Project_Site_Contact_Name__c);
        Contact c = [Select id, AccountId FROM Contact where id =: job.Project_Site_Contact_Name__c];
        system.debug('contact is ' + c);
    Account a = [Select Id FROM Account Where Id =: c.AccountId];
    system.debug('Account ' + a);
    return a.id;
    }else{
        return null;
    }
    }
    @AuraEnabled
    public static Case ChatterJobId(Id recordId) {
        Case cs = [Select Id, ATI_Job__c FROM Case Where Id =: recordId];
        system.debug('Cs is ' + cs);
        return cs;
    }
    @AuraEnabled
    public static String CaseChatterTaskCreation(Id recordId, String subject, String description){
        
            
       
        Id caseOwner = UserInfo.getUserId();
        List<case> cases = [Select Id FROM CASE WHERE ATI_Job__c =: recordId ORDER BY createdDate DESC LIMIT 1];
        system.debug('Cases ' + cases);
        String fullRecordURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' + cases[0].id;
        String fullRecordURLJOB = URL.getSalesforceBaseUrl().toExternalForm() + '/' + recordId;
        
        string descriptionPlus = 'A new case has been opened for the Job: ' + fullRecordURLJOB+  '\n' +'Case Link: '+ fullRecordURL + '\n' + '\n' +description;

        Task t = new Task( Type = 'Log a Call', ActivityDate = system.today(), Description = descriptionPlus, OwnerId = caseOwner, Priority = 'Low', Status='Completed', Subject = subject, WhatId = recordId);
        insert t;
        ATI_Job__c job = [Select Id, Project_Manager__c, Project_manager_new__c, Name FROM ATI_Job__c WHERE Id =: recordId];
        
        FeedItem post = new FeedItem();
        post.ParentId = recordId;
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        ConnectApi.MentionSegmentInput mentionSegmentInput1 = new ConnectApi.MentionSegmentInput();
        ConnectApi.MentionSegmentInput mentionSegmentInput2 = new ConnectApi.MentionSegmentInput();
        if(job.Project_Manager_new__c != null){
            mentionSegmentInput.id = job.project_manager_new__c;
            messageBodyInput.messageSegments.add(mentionSegmentInput);
        }
        if(job.Project_Manager__c != null){
            mentionSegmentInput1.id = job.project_manager__c;
            messageBodyInput.messageSegments.add(mentionSegmentInput1);
        }
        
        
        String comments = '\n' + 'Case Link: ' + fullRecordURL +  '\n' + '\n' +description;
        // messageBodyInput.messageSegments.add(mentionSegmentInput);
        // messageBodyInput.messageSegments.add(mentionSegmentInput1);
        
        textSegmentInput.text = descriptionPlus;
        messageBodyInput.messageSegments.add(textSegmentInput);
        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.subjectId = recordId;
        if(Test.isRunningTest()){}
        else{
        ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
        }
        system.debug('Cases Id before return is ' + cases[0].id);
        return cases[0].id;
        
    }
    @AuraEnabled
    public static string AllocationApproval(String OppName, String recordId, String JobNumber, Integer Amount, String FirstQ, String SecondQ, String ThirdQ, 
    String Subcontractor, String Description){
        system.debug(OppName + recordId + JobNumber + Amount + FirstQ + SecondQ + ThirdQ + Description + Subcontractor);
        approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval. Details are: ');
        req1.setObjectId(recordId);
        // Submit on behalf of a specific submitter
        req1.setSubmitterId(UserInfo.getUserId());
        // Submit the record to specific process and skip the criteria evaluation
        req1.setProcessDefinitionNameOrId('X2PercentAllocation');
        req1.setSkipEntryCriteria(true);
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);
        return 'success';
    }
    
}