/*************************************************************************************
 * @Name         : SC_LogService.cls
 * @Description  : Logger for Service Clients project
 * @Created By   : Denys Taldykin
 * @Created Date : April 25, 2023
 * @Modification Log:
 **************************************************************************************
 * Version     Developer      Date        Description
 *-------------------------------------------------------------------------------------
 *
 *************************************************************************************/
public with sharing class SC_LogService {
    private static final String SC_SETTINGS_NAME = 'Service_Clients_Settings';
    @TestVisible
    private static Boolean loggingEnabled = isLoggingEnabled();

    /**
     * @author Denys Taldykin
     * @date April 25, 2023
     * @name saveRequestLogs
     * @description method to log request body
     */
    public static void saveRequestLogs(String message, String payload, String className) {
        if (loggingEnabled) {
            SC_Log__c log = new SC_Log__c();
            log.User__c = UserInfo.getUserId();
            log.Message__c = message;
            log.Class__c = className;
            log.Payload__c = payload;

            insert log;
        } else {
            System.debug(message);
        }
    }

    /**
     * @author Denys Taldykin
     * @date April 25, 2023
     * @name isLoggingEnabled
     * @description method to check if logging is enabled
     * @return Boolean
     */
    private static Boolean isLoggingEnabled() {
        List<Service_Clients_Settings__mdt> settings = [SELECT Save_Case_Logs__c FROM Service_Clients_Settings__mdt WHERE DeveloperName = :SC_SETTINGS_NAME];

        if (!settings.isEmpty()) {
            for (Service_Clients_Settings__mdt s : settings) {
                if (s.Save_Case_Logs__c) {
                    return true;
                }
            }
        }

        return false;
    }
}