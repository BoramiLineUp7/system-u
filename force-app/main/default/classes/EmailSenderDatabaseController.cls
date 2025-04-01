public with sharing class EmailSenderDatabaseController {
    @AuraEnabled
	public static List<Map<String, String>> getListOfEmailCategory(){
        List<Map<String, String>> listOfCategory = new List<Map<String, String>>();
        Schema.DescribeFieldResult fieldInfo = Case.Email_Category__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldInfo.getPicklistValues();
        for( Schema.PicklistEntry pVal : ple){
            listOfCategory.add(new Map<String, String>{'value' => pVal.getValue(), 'label' => pVal.getLabel()});
        }
        return listOfCategory;
    }
	
    @AuraEnabled
	public static List<Map<String, String>> getListOfTemplates(){
        List<Map<String, String>> listOfTemplates = new List<Map<String, String>>();
        
        List<Folder> myFolders = new List<Folder>([Select Id From Folder Where Type='Email' And DeveloperName='Service_Client_Centrale']);
        List<EmailTemplate> myTemplates = new List<EmailTemplate>([Select Id, Name From EmailTemplate Where FolderId = :myFolders[0].Id]);
        
        //Construction de la liste
        for(EmailTemplate vTemp : myTemplates){
            listOfTemplates.add(new Map<String, String>{'value' => vTemp.Id, 'label' => vTemp.Name});
        }
        return listOfTemplates;
    }
    
    @AuraEnabled
	public static Integer getNumberOfCases(String emailCategory){
        return [SELECT Count()
                FROM Case WHERE Status_of_email__c = 'A envoyer' AND Email_Category__c = :emailCategory];
    }
    
    @AuraEnabled
	public static Integer sendEmails(String emailCategory, Id myTemplateId){
        System.debug('Starting sending... : Category='+emailCategory+' / Template ID='+ myTemplateId);
        
        //We get the sender
        List<OrgWideEmailAddress> mySender =  new List<OrgWideEmailAddress>([SELECT Id
                                                                            FROM OrgWideEmailAddress
                                                                            WHERE DisplayName='Support Course U']);
        
        //We get the list of cases
        List<Case> myCasesToSend = new List<Case> ([SELECT Id, ContactId, Status_of_email__c
                                                    FROM Case
                                                    WHERE Status_of_email__c = 'A envoyer'
                                                    AND Email_Category__c = :emailCategory]);
        System.debug('Number of Cases : '+myCasesToSend.size());
        
        //We create the list of email to send using the template
        List<Messaging.SingleEmailMessage> myEmails = new List<Messaging.SingleEmailMessage>();
        for (Case c : myCasesToSend){
            Messaging.SingleEmailMessage myMail = getTheMail(c, emailCategory, myTemplateId, mySender[0].Id);
            myEmails.add(myMail);
            c.Status_of_email__c = 'Email envoyé';
        }
        
        //We send emails
        Messaging.sendEmail(myEmails);
        
        //We update Cases to notify that email was sent
        update myCasesToSend;

        return myCasesToSend.size();
    }

    private static Messaging.SingleEmailMessage getTheMail(Case myCase, String emailCategory, Id myTemplateId, Id mySender) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(myCase.ContactId);
        mail.setWhatId(myCase.Id);
        mail.setOrgWideEmailAddressId(mySender);
        mail.setUseSignature(false);
        mail.setBccSender(false);
        mail.setSaveAsActivity(true);
        mail.setTemplateId(myTemplateId); 
        return mail;
    }
}