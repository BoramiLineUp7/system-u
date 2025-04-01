/*************************************************************************************
 * @Name         : SC_REST_CaseController.cls
 * @Description  : Class for handling Contact Form callouts from SFCC
 * @Created By   : Denys Taldykin
 * @Created Date : April 10, 2023
 * @Modification Log:
 **************************************************************************************
 * Version     Developer      Date        Description
 *-------------------------------------------------------------------------------------
 *
 *************************************************************************************/
@RestResource(UrlMapping='/Case/*')
global with sharing class SC_REST_CaseController {
    /**
     * @author Denys Taldykin
     * @date April 10, 2023
     * @name createCase
     * @description Method to parse request body and insert Case record
     */
    @HttpPost
    global static void createCase() {
        RestResponse res = RestContext.response;
        Case c;

        try {
            c = (Case) JSON.deserialize(RestContext.request.requestBody.toString(), Case.class);
            checkStoreId(c);

            insert c;

            res.statusCode = 201;
            res.responseBody = Blob.valueOf(JSON.serialize(new responseWrapper(c.Id, true, new List<String>())));
        } catch (Exception exc) {
            SC_LogService.saveRequestLogs(
                    exc.getMessage(),
                    RestContext.request.requestBody.toString(),
                    'VE_REST_OrderResult'
            );

            res.statusCode = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(new responseWrapper(exc.getMessage(), new List<String>())));
        }
    }

    /**
     * @author Denys Taldykin
     * @date April 25, 2023
     * @name checkStoreId
     * @param c Case
     * @description Method to remove Store Id from Case if no Account records associated with Case Store Id
     */
    private static void checkStoreId(Case c) {
        List<Account> stores;
        if (c.Store__r != null && c.Store__r.StoreId__c != null) {
            stores = [SELECT Id FROM Account WHERE StoreId__c = :c.Store__r.StoreId__c];

            if (stores.isEmpty()) {
                c.Store__r = null;
            }
        } else {
            c.Store__r = null;
        }
    }

    /**
     * @author Denys Taldykin
     * @date April 25, 2023
     * @name responseWrapper
     * @description Response Body wrapper
     */
    private class responseWrapper {
        public String message;
        public String id;
        public Boolean success;
        public List<String> errors;

        /**
         * @author Denys Taldykin
         * @date April 25, 2023
         * @name responseWrapper
         * @description Success Response Body wrapper constructor
         */
        public responseWrapper(String id, Boolean success, List<String> errors) {
            this.id = id;
            this.success = success;
            this.errors = errors;
        }

        /**
         * @author Denys Taldykin
         * @date April 25, 2023
         * @name responseWrapper
         * @description Error Response Body wrapper constructor
         */
        public responseWrapper(String message, List<String> errors) {
            this.message = message;
            this.errors = errors;
        }
    }
}