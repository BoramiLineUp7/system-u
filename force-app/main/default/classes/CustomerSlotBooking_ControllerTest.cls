/**
* @author : Nicolas Greard(Salesforce)
* @date : 11/05/2020
* @description : class to handle the CustomerSlots
* @last modified date/comments :
*/
@IsTest
public class CustomerSlotBooking_ControllerTest {
    @testSetup
    public static void setup(){
        TestDataFactory.createCS();
        TestDataFactory.createUnitTestCaseSlot();
    }

    @isTest
    public static void test() {
        Slot__c s = [SELECT Id FROM Slot__c LIMIT 1];
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestPardotMock());
        CustomerSlotBooking_Controller.insertCS(s.Id,'test','test','test@test.invalid','test@test.invalid',1,null);
        test.stopTest();
    }

    @isTest
    public static void testPDFVF() {
        PDFDataWrapper pdfwrp = new PDFDataWrapper();
        pdfwrp.uuid = '345678';
        pdfwrp.firstname = 'test';
        pdfwrp.lastname = 'test';
        pdfwrp.startdatetime = Datetime.now();
        pdfwrp.numofpers = 1;
        pdfwrp.storename = 'test';
        pdfwrp.storestreet = '';
        pdfwrp.storepostalcode = '5678';
        pdfwrp.storecity = 'PARIS';
        String data = JSON.serialize(pdfwrp);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new TestPardotMock());
        PageReference pageRef = Page.CustomerSlotPdfGenerate;
        pageRef.getParameters().put('data',data);
        Test.setCurrentPage(pageRef);
        new CustomerSlot_PDF_Controller();
        test.stopTest();
    }
}