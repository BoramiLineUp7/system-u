/*************************************************************************************
 * @Name         : SC_ServiceNowInvocableTest.cls
 * @Description  : Unit test for SC_ServiceNowInvocable class
 * @Created By   : Denys Taldykin
 * @Created Date : September 18, 2023
 * @Modification Log:
 **************************************************************************************
 * Version     Developer      Date        Description
 *-------------------------------------------------------------------------------------
 *
 *************************************************************************************/
@IsTest
public with sharing class SC_ServiceNowNoteInvocableTest {
    public static final String SN_INCIDENT_ID = '41805d2a1b5d3550881a2f02604bcb63';
    private static final String EMAIL_ADDRESS = 'test1@test.com';
    private static final String FIRST_NAME = 'FirstName1';
    private static final String LAST_NAME = 'LastName1';
    private static final String RESPONSE_INCIDENT_SUCCESS = '{"result":{"sys_id":"41805d2a1b5d3550881a2f02604bcb63"}}';
    private static final String RESPONSE_INCIDENT_ERROR = '{}';
    private static final String COURSES_U_CATEGORY = 'Courses U';
    private static final String COMMENTS = 'Comments';

    /**
    * @author Denys Taldykin
    * @date September 18, 2023
    * @name createServiceNowIncidentTest
    * @description unit test for createServiceNowIncident method
    */
    @IsTest
    static void createServiceNowNoteTest() {
        List<SC_ServiceNowNoteInvocable.FlowInput> flowInputs;
        Account acc = new Account(
                FirstName = FIRST_NAME,
                LastName = LAST_NAME,
                Email_ID__c = EMAIL_ADDRESS,
                PersonEmail = EMAIL_ADDRESS,
                RecordTypeId = SC_RXPService.PRESON_ACCOUNT_RT_ID
        );
        Case c;

        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        insert acc;

        c = new Case (
                AccountId = acc.Id,
                Status = 'Nouveau',
                ServiceNowId__c = SN_INCIDENT_ID,
                Origin = 'Web',
                Priority = 'Moyen',
                Description = 'My test case',
                SuppliedEmail = EMAIL_ADDRESS,
                Subject = 'Problème sur le site',
                Type = SC_RXPService.COMPTE_COURSES_U_CASE_TYPE
        );

        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        insert c;

        Test.startTest();
        flowInputs = SC_ServiceNowNoteInvocable.createServiceNowNote(new List<SC_ServiceNowNoteInvocable.FlowOutput>{
                new SC_ServiceNowNoteInvocable.FlowOutput(c.Id, COMMENTS, 'comments')
        });
        Test.stopTest();


        c = [SELECT Id, ServiceNowId__c FROM Case WHERE Id = :c.Id LIMIT 1];

        System.assertEquals(true, flowInputs[0].success);
        System.assertEquals(SN_INCIDENT_ID, c.ServiceNowId__c);
    }

    /**
     * @author Denys Taldykin
     * @date September 18, 2023
     * @name MockSuccess
     * @description Callout Mock with success response
     */
    public class MockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody(RESPONSE_INCIDENT_SUCCESS);

            res.setStatusCode(200);

            return res;
        }
    }

    /**
     * @author Denys Taldykin
     * @date March 16, 2023
     * @name MockError
     * @description Callout Mock with success response
     */
    public class MockError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody(RESPONSE_INCIDENT_ERROR);

            res.setStatusCode(200);

            return res;
        }
    }
}