/**
* @author : Nicolas (Salesforce)
* @date : 20/04/2020
* @description : class to handle the CustomerSlots
* @last modified date/comments :
*/
@isTest
public class reCaptchaUtils_Test {

    @testSetup
    public static void setup(){
        TestDataFactory.createCS();
    }

    @isTest
    public static void test() {

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestGoogleMock());
        //TestReCaptcha_Controller.validateCaptcha('3456789');
        reCaptchaUtils.validateToken('45678','45678');
        test.stopTest();
        
    }


}