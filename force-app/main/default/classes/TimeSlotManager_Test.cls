/**
* @author : Nicolas (Salesforce)
* @date : 20/04/2020
* @description : class to handle the TimeSlotManager
* @last modified date/comments :
*/
@isTest
public class TimeSlotManager_Test {

    @testSetup
    public static void setup(){
        TestDataFactory.createCS();
    }

    @isTest
    public static void testCS(){
        CustomerSlot__c cs = TestDataFactory.createUnitTestCase();

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestPardotMock());
        TimeSlotManager.getSlots('1',0);
        test.stopTest();
    }
    
}