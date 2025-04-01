/*************************************************************************************
 * @Name         : SC_EmailTemplateChangeEventTriggerTest.cls
 * @Description  : unit test for SC_EmailTemplateChangeEventTrigger trigger
 * @Created By   : Denys Taldykin
 * @Created Date : February 5, 2024
 * @Modification Log:
 **************************************************************************************
 * Version     Developer      Date        Description
 *-------------------------------------------------------------------------------------
 *************************************************************************************/
@IsTest
public with sharing class SC_EmailTemplateChangeEventTriggerTest {
    @IsTest
    static void testTriggerLogic() {
        EmailTemplate t = new EmailTemplate();
        Folder f = [SELECT Id FROM Folder WHERE Type = 'Email'  LIMIT 1];

        t.Name = 'Test Template EmailTemplateChangeEventTrigger';
        t.DeveloperName = 'Test_Template_EmailTemplateChangeEventTrigger';
        t.HtmlValue = '<html style="overflow-y: hidden;">Test HTML</html>';
        t.TemplateType = 'custom';
        t.FolderId = f.Id;

        Test.startTest();
        insert t;
        Test.getEventBus().deliver();
        Test.stopTest();

        t = [SELECT HtmlValue FROM EmailTemplate WHERE Id = :t.Id];

        System.assertEquals('<html style="overflow-y: scroll;">Test HTML</html>', t.HtmlValue);
    }
}