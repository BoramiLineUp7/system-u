/*************************************************************************************
 * @Name         : SC_REST_CaseControllerTest.cls
 * @Description  : Unit Test for SC_REST_CaseController class
 * @Created By   : Denys Taldykin
 * @Created Date : April 25, 2023
 * @Modification Log:
 **************************************************************************************
 * Version     Developer      Date        Description
 *-------------------------------------------------------------------------------------
 *
 *************************************************************************************/
@IsTest
public with sharing class SC_REST_CaseControllerTest {
    private static final String EMAIL_ADDRESS = 'test@test.com';
    private static final String PERSON_ACCOUNT_RECORDTYPE_DEVELOPER_NAME = 'Client';
    private static final String STORE_ACCOUNT_RECORDTYPE_DEVELOPER_NAME = 'Store';
    private static final String FIRST_NAME = 'FirstName';
    private static final String LAST_NAME = 'LastName';
    private static final Id PRESON_ACCOUNT_RT_ID = SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PERSON_ACCOUNT_RECORDTYPE_DEVELOPER_NAME).getRecordTypeId();
    private static final Id STORE_ACCOUNT_RT_ID = SObjectType.Account.getRecordTypeInfosByDeveloperName().get(STORE_ACCOUNT_RECORDTYPE_DEVELOPER_NAME).getRecordTypeId();

    /**
     * @author Denys Taldykin
     * @date April 25, 2023
     * @name testCreateCase
     * @description test for createCase method
     */
    @IsTest
    private static void testCreateCase() {
        Account acc = new Account(FirstName = FIRST_NAME, LastName = LAST_NAME, Email_ID__c = EMAIL_ADDRESS, PersonEmail = EMAIL_ADDRESS, RecordTypeId = PRESON_ACCOUNT_RT_ID);
        Case c;

        insert acc;

        c = new Case (
                AccountId = acc.Id,
                Status = 'Nouveau',
                Origin = 'Email',
                Priority = 'Moyen',
                Description = 'My test case',
                SuppliedEmail = EMAIL_ADDRESS,
                Subject = 'Problème sur le site'
        );

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(c));
        SC_REST_CaseController.createCase();

        System.assertEquals(201, RestContext.response.statusCode);
    }

    /**
     * @author Denys Taldykin
     * @date April 25, 2023
     * @name testCreateCaseWithStoreId
     * @description test for createCase method with Store Id populated
     */
    @IsTest
    private static void testCreateCaseWithStoreId() {
        Account acc = new Account(FirstName = FIRST_NAME, LastName = LAST_NAME, Email_ID__c = EMAIL_ADDRESS, PersonEmail = EMAIL_ADDRESS, RecordTypeId = PRESON_ACCOUNT_RT_ID);
        Account store = new Account(Name = 'Lyon Store 66101', RecordTypeId = STORE_ACCOUNT_RT_ID, StoreId__c = '66101');
        Account storeRef = new Account(StoreId__c = '66101');
        Case c;

        insert acc;
        insert store;

        c = new Case (
                AccountId = acc.Id,
                Status = 'Nouveau',
                Origin = 'Email',
                Priority = 'Moyen',
                Description = 'My test case',
                SuppliedEmail = EMAIL_ADDRESS,
                Subject = 'Problème sur le site',
                Store__r = storeRef
        );

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(c));
        SC_REST_CaseController.createCase();

        System.assertEquals(201, RestContext.response.statusCode);
    }

    /**
     * @author Denys Taldykin
     * @date April 25, 2023
     * @name testCreateCaseWithInvalidStoreId
     * @description test for createCase method with invalid Store Id
     */
    @IsTest
    private static void testCreateCaseWithInvalidStoreId() {
        Account acc = new Account(FirstName = FIRST_NAME, LastName = LAST_NAME, Email_ID__c = EMAIL_ADDRESS, PersonEmail = EMAIL_ADDRESS, RecordTypeId = PRESON_ACCOUNT_RT_ID);
        Account store = new Account(Name = 'Lyon Store 66101', RecordTypeId = STORE_ACCOUNT_RT_ID, StoreId__c = '66101');
        Account storeRef = new Account(StoreId__c = '12345');
        Case c;

        insert acc;
        insert store;

        c = new Case (
                AccountId = acc.Id,
                Status = 'Nouveau',
                Origin = 'Email',
                Priority = 'Moyen',
                Description = 'My test case',
                SuppliedEmail = EMAIL_ADDRESS,
                Subject = 'Problème sur le site',
                Store__r = storeRef
        );

        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(c));
        SC_REST_CaseController.createCase();

        System.assertEquals(201, RestContext.response.statusCode);
    }

    /**
     * @author Denys Taldykin
     * @date April 25, 2023
     * @name testCreateCaseError
     * @description test for createCase method with invalid request body
     */
    @IsTest
    private static void testCreateCaseError() {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize('123'));
        SC_LogService.loggingEnabled = true;

        SC_REST_CaseController.createCase();

        System.assertEquals(400, RestContext.response.statusCode);
    }
}