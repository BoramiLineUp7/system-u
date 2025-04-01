/*************************************************************************************
 * @Name         : SC_SLAServiceTest.cls
 * @Description  : Unit test for SC_SLAService class
 * @Created By   : Denys Taldykin
 * @Created Date : January 23, 2023
 * @Modification Log:
 **************************************************************************************
 * Version     Developer      Date        Description
 *-------------------------------------------------------------------------------------
 *************************************************************************************/
@IsTest
private class SC_SLAServiceTest {
    private static final String EMAIL_ADDRESS = 'test@test.com';
    private static final String PERSON_ACCOUNT_RECORDTYPE_DEVELOPER_NAME = 'Client';
    private static final String FIRST_NAME = 'FirstName';
    private static final String LAST_NAME = 'LastName';

    /**
     * @author Denys Taldykin
     * @date January 23, 2023
     * @name updateSLAScheduleDates72h
     * @description test method for updateSLAScheduleDate method
     */
    @IsTest
    static void updateSLAScheduleDates72hTest() {
        List<Case> cases = new List<Case>();
        Case c = new Case (SLA_d_origine__c = SC_SLAService.SLA_72_H);

        cases.add(c);

        SC_SLAService.updateSLAScheduleDate(cases);

        System.assertNotEquals(null, c.SLA_48h_Sch_Action_Date__c, 'SLA_48h_Sch_Action_Date__c should be updated on Case!');
        System.assertNotEquals(null, c.SLA_24h_Sch_Action_Date__c, 'SLA_24h_Sch_Action_Date__c should be updated on Case!');
        System.assertNotEquals(null, c.SLA_4h_Sch_Action_Date__c, 'SLA_4h_Sch_Action_Date__c should be updated on Case!');
        System.assertNotEquals(null, c.SLA_OutOfTime_Sch_Action_Date__c, 'SLA_OutOfTime_Sch_Action_Date__c should be updated on Case!');
    }

    /**
     * @author Denys Taldykin
     * @date January 23, 2023
     * @name updateSLAScheduleDates48h
     * @description test method for updateSLAScheduleDate method
     */
    @IsTest
    static void updateSLAScheduleDates48hTest() {
        List<Case> cases = new List<Case>();
        Case c = new Case (SLA_d_origine__c = SC_SLAService.SLA_48_H);

        cases.add(c);

        SC_SLAService.updateSLAScheduleDate(cases);

        System.assertEquals(null, c.SLA_48h_Sch_Action_Date__c, 'SLA_48h_Sch_Action_Date__c should not be populated on Case!');
        System.assertNotEquals(null, c.SLA_24h_Sch_Action_Date__c, 'SLA_24h_Sch_Action_Date__c should be updated on Case!');
        System.assertNotEquals(null, c.SLA_4h_Sch_Action_Date__c, 'SLA_4h_Sch_Action_Date__c should be updated on Case!');
        System.assertNotEquals(null, c.SLA_OutOfTime_Sch_Action_Date__c, 'SLA_OutOfTime_Sch_Action_Date__c should be updated on Case!');
    }

    /**
     * @author Denys Taldykin
     * @date January 23, 2023
     * @name updateSLAScheduleDates24h
     * @description test method for updateSLAScheduleDate method
     */
    @IsTest
    static void updateSLAScheduleDates24hTest() {
        List<Case> cases = new List<Case>();
        Case c = new Case (SLA_d_origine__c = SC_SLAService.SLA_24_H);

        cases.add(c);

        SC_SLAService.updateSLAScheduleDate(cases);

        System.assertEquals(null, c.SLA_48h_Sch_Action_Date__c, 'SLA_48h_Sch_Action_Date__c should be populated on Case!');
        System.assertEquals(null, c.SLA_24h_Sch_Action_Date__c, 'SLA_24h_Sch_Action_Date__c should not be populated on Case!');
        System.assertNotEquals(null, c.SLA_4h_Sch_Action_Date__c, 'SLA_4h_Sch_Action_Date__c should be updated on Case!');
        System.assertNotEquals(null, c.SLA_OutOfTime_Sch_Action_Date__c, 'SLA_OutOfTime_Sch_Action_Date__c should be updated on Case!');
    }

    /**
     * @author Denys Taldykin
     * @date January 23, 2023
     * @name updateSLAScheduleDates24h
     * @description test method for updateSLAScheduleDate method
     */
    @IsTest
    static void updateSLAScheduleDatesEmptySLATest() {
        List<Case> cases = new List<Case>();
        Case c = new Case (SLA_d_origine__c = null);

        cases.add(c);

        SC_SLAService.updateSLAScheduleDate(cases);

        System.assertEquals(null, c.SLA_48h_Sch_Action_Date__c, 'SLA_48h_Sch_Action_Date__c should not be populated on Case!');
        System.assertEquals(null, c.SLA_24h_Sch_Action_Date__c, 'SLA_24h_Sch_Action_Date__c should not be populated on Case!');
        System.assertEquals(null, c.SLA_4h_Sch_Action_Date__c, 'SLA_4h_Sch_Action_Date__c should not be populated on Case!');
        System.assertEquals(null, c.SLA_OutOfTime_Sch_Action_Date__c, 'SLA_OutOfTime_Sch_Action_Date__c should not be populated on Case!');
    }

    /**
     * @author Denys Taldykin
     * @date January 23, 2023
     * @name originalSLAUpdateTo72hTest
     * @description test method for updateSLAScheduleDate method
     */
    @IsTest
    static void originalSLAUpdateTo72hTest() {
        Id personAccountRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PERSON_ACCOUNT_RECORDTYPE_DEVELOPER_NAME).getRecordTypeId();
        Account acc = new Account(FirstName = FIRST_NAME, LastName = LAST_NAME, Email_ID__c = EMAIL_ADDRESS, PersonEmail = EMAIL_ADDRESS, RecordTypeId = personAccountRTId);
        Case caseOld;
        Case caseNew;
        Map<Id, Case> oldCases = new Map<Id, Case>();
        List<Case> cases = new List<Case>();

        insert acc;

        caseOld = new Case (
                AccountId = acc.Id,
                Status = 'Nouveau',
                Origin = 'Email',
                Priority = 'Moyen',
                Description = 'My test case',
                SuppliedEmail = EMAIL_ADDRESS,
                Subject = 'Test Case'
        );

        insert caseOld;

        oldCases.put(caseOld.Id, caseOld);

        caseNew = new Case (Id = caseOld.Id, SLA_d_origine__c = SC_SLAService.SLA_72_H);

        cases.add(caseNew);

        SC_SLAService.updateSLAScheduleDate(cases, oldCases);

        System.assertNotEquals(null, caseNew.SLA_48h_Sch_Action_Date__c, 'SLA_48h_Sch_Action_Date__c should be updated on Case!');
        System.assertNotEquals(null, caseNew.SLA_24h_Sch_Action_Date__c, 'SLA_24h_Sch_Action_Date__c should be updated on Case!');
        System.assertNotEquals(null, caseNew.SLA_4h_Sch_Action_Date__c, 'SLA_4h_Sch_Action_Date__c should be updated on Case!');
        System.assertNotEquals(null, caseNew.SLA_OutOfTime_Sch_Action_Date__c, 'SLA_OutOfTime_Sch_Action_Date__c should be updated on Case!');
    }
}