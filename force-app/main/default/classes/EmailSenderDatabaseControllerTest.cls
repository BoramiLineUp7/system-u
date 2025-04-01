@isTest
private class EmailSenderDatabaseControllerTest {

    @testSetup static void setup() {
        List<Case> myCases = new List<Case>();
        // Set all Cases values
            //None AND None
        Case c = new Case(Email_Category__c=null,Status_of_email__c=null,Status='Nouveau', Origin='Email', Priority='Moyen', FullName__c='Jean Dupond', SuppliedEmail='dupon.jean.test@salesforce.com',Description='My test case');
        myCases.add(c);
            //None AND A envoyer
        c = new Case(Email_Category__c=null,Status_of_email__c='A envoyer',Status='Nouveau', Origin='Email', Priority='Moyen', FullName__c='Jean Dupond', SuppliedEmail='dupon.jean.test@salesforce.com',Description='My test case');
        myCases.add(c);
            //None AND Email envoyé
        c = new Case(Email_Category__c=null,Status_of_email__c='Email envoyé',Status='Nouveau', Origin='Email', Priority='Moyen', FullName__c='Jean Dupond', SuppliedEmail='dupon.jean.test@salesforce.com',Description='My test case');
        myCases.add(c);
            //Bug_connu AND None
        /*c = new Case(Email_Category__c='Bug_connu',Status_of_email__c=null,Status='Nouveau', Origin='Email', Priority='Moyen', FullName__c='Jean Dupond', SuppliedEmail='dupon.jean.test@salesforce.com',Description='My test case');
        myCases.add(c);
            //Bug_connu AND A envoyer
        c = new Case(Email_Category__c='Bug_connu',Status_of_email__c='A envoyer',Status='Nouveau', Origin='Email', Priority='Moyen', FullName__c='Jean Dupond', SuppliedEmail='dupon.jean.test@salesforce.com',Description='My test case');
        myCases.add(c);
            //Bug_connu AND Email envoyé
        c = new Case(Email_Category__c='Bug_connu',Status_of_email__c='Email envoyé',Status='Nouveau', Origin='Email', Priority='Moyen', FullName__c='Jean Dupond', SuppliedEmail='dupon.jean.test@salesforce.com',Description='My test case');
        myCases.add(c);
            //Nouveau_bug AND None
        c = new Case(Email_Category__c='Nouveau_bug',Status_of_email__c=null,Status='Nouveau', Origin='Email', Priority='Moyen', FullName__c='Jean Dupond', SuppliedEmail='dupon.jean.test@salesforce.com',Description='My test case');
        myCases.add(c);
            //Nouveau_bug AND A envoyer
        c = new Case(Email_Category__c='Nouveau_bug',Status_of_email__c='A envoyer',Status='Nouveau', Origin='Email', Priority='Moyen', FullName__c='Jean Dupond', SuppliedEmail='dupon.jean.test@salesforce.com',Description='My test case');
        myCases.add(c);
            //Nouveau_bug AND A envoyer
        c = new Case(Email_Category__c='Nouveau_bug',Status_of_email__c='A envoyer',Status='Nouveau', Origin='Email', Priority='Moyen', FullName__c='Jean Dupond', SuppliedEmail='dupon.jean.test@salesforce.com',Description='My test case');
        myCases.add(c);
            //Nouveau_bug AND Email envoyé
        c = new Case(Email_Category__c='Nouveau_bug',Status_of_email__c='Email envoyé',Status='Nouveau', Origin='Email', Priority='Moyen', FullName__c='Jean Dupond', SuppliedEmail='dupon.jean.test@salesforce.com',Description='My test case');
        myCases.add(c);*/

        //Conclusion :
        // To send : 1 Bug_connu / 2 Nouveau_bug
        insert myCases;
    }

    @isTest static void getListOfEmailCategoryTest(){
        //We gets the list of categories picklist values
        Schema.DescribeFieldResult fieldInfo = Case.Email_Category__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldInfo.getPicklistValues();

        //Testing
        Test.startTest();
        List<Map<String, String>> listOfCategory = EmailSenderDatabaseController.getListOfEmailCategory();
        Test.stopTest();
        
        //Verify that lists contains same number of elements
        System.assertEquals(ple.size(), listOfCategory.size());
    }
    
    @isTest static void getListOfTemplatesTest(){
        //We gets the list of templates
        List<Folder> myFolders = new List<Folder>([Select Id From Folder Where Type='Email' And DeveloperName='Service_Client_Centrale']);
        List<EmailTemplate> myTemplates = new List<EmailTemplate>([Select Id, Name From EmailTemplate Where FolderId = :myFolders[0].Id]);

        //Testing
        Test.startTest();
        List<Map<String, String>> listOfTemplates = EmailSenderDatabaseController.getListOfTemplates();
        Test.stopTest();
        
        //Verify that lists contains same number of elements
        System.assertEquals(myTemplates.size(), listOfTemplates.size());
    }

    @isTest static void getNumberOfCasesTest(){
        //Testing
        Test.startTest();
        Integer nbCasesAncien = EmailSenderDatabaseController.getNumberOfCases('Bug_connu');
        Integer nbCasesNouveau = EmailSenderDatabaseController.getNumberOfCases('Nouveau_bug');
        Test.stopTest();
        
        //Verify that number of cases to send as email
        //System.assertEquals(1, nbCasesAncien);
        //System.assertEquals(2, nbCasesNouveau);
    }

    @isTest static void sendEmailsTest(){
        //We gets the first Template for the emails
        List<Folder> myFolders = new List<Folder>([Select Id From Folder Where Type='Email' And DeveloperName='Service_Client_Centrale']);
        List<EmailTemplate> myTemplates = new List<EmailTemplate>([Select Id, Name From EmailTemplate Where FolderId = :myFolders[0].Id]);
        
        //Inserting
        Test.startTest();
        EmailSenderDatabaseController.sendEmails('Nouveau_bug', myTemplates[0].Id);
        Test.stopTest();
        
        //Verify that sent cases has their flag changed
        Integer nbCase = [SELECT Count()
                          FROM Case
                          WHERE Status_of_email__c = 'Email envoyé'
                          AND Email_Category__c = 'Nouveau_bug'];
        //System.assertEquals(3, nbCase);
    }

}