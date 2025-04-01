/**
* @author : Nicolas (Salesforce)
* @date : 20/04/2020
* @description : class to handle the CustomerSlots
* @last modified date/comments :
*/
@isTest
public class CustomerSlot_Controller_Test {


    @testSetup
    public static void setup(){

    }

    @isTest
    public static void testCS(){
        CustomerSlot__c cs = TestDataFactory.createUnitTestCase();

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestPardotMock());
        CustomerSlot_Controller.searchTodayCustomerSlotByEmail('test');
        test.stopTest();
    }
}