/*************************************************************************************
 * @Name         : SC_LogServiceTest.cls
 * @Description  : Unit Test for SC_LogService class
 * @Created By   : Denys Taldykin
 * @Created Date : April 25, 2023
 * @Modification Log:
 **************************************************************************************
 * Version     Developer      Date        Description
 *-------------------------------------------------------------------------------------
 *
 *************************************************************************************/
@IsTest
public with sharing class SC_LogServiceTest {
    private static final String LOG_MESSAGE = 'LOG_MESSAGE';
    private static final String LOG_PAYLOAD = 'LOG_PAYLOAD';
    private static final String LOG_CLASS_NAME = 'LOG_CLASS_NAME';

    /**
     * @author Denys Taldykin
     * @date April 25, 2023
     * @name saveRequestLogsTest
     * @description test for saveRequestLogs method
     */
    @IsTest
    private static void saveRequestLogsTest() {
        List<SC_Log__c> logs;

        Test.startTest();
        SC_LogService.loggingEnabled = true;
        SC_LogService.saveRequestLogs(LOG_MESSAGE, LOG_PAYLOAD, LOG_CLASS_NAME);
        Test.stopTest();

        logs = [SELECT Id, User__c, Message__c, Class__c, Payload__c FROM SC_Log__c WHERE Class__c = :LOG_CLASS_NAME];

        System.assertEquals(1, logs.size());
        System.assertEquals(LOG_MESSAGE, logs[0].Message__c);
        System.assertEquals(LOG_CLASS_NAME, logs[0].Class__c);
        System.assertEquals(LOG_PAYLOAD, logs[0].Payload__c);
    }

    /**
     * @author Denys Taldykin
     * @date April 25, 2023
     * @name saveRequestLogsLoggingDisabledTest
     * @description test for saveRequestLogs method with deactivated logging
     */
    @IsTest
    private static void saveRequestLogsLoggingDisabledTest() {
        List<SC_Log__c> logs;

        Test.startTest();
        SC_LogService.loggingEnabled = false;
        SC_LogService.saveRequestLogs(LOG_MESSAGE, LOG_PAYLOAD, LOG_CLASS_NAME);
        Test.stopTest();

        logs = [SELECT Id, User__c, Message__c, Class__c, Payload__c FROM SC_Log__c WHERE Class__c = :LOG_CLASS_NAME];

        System.assertEquals(0, logs.size());
    }
}