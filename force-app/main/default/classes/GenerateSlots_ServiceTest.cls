/**
* @author : Nicolas Greard(Salesforce)
* @date : 08/05/2020
* @description : class to handle slots generation test class
* @last modified date/comments :
*/
@IsTest
public class GenerateSlots_ServiceTest {
    @testSetup
    public static void setup(){
        TestDataFactory.createCS();
        Account a = TestDataFactory.createAccount(1).get(0);
        RecurringSlot__c rs = TestDataFactory.createRecurringSlot(a.Id,1).get(0);
    }

    @IsTest
    public static void test(){
        //rsIds
        List<String> rsIds = new List<String>();
        for(RecurringSlot__c rs : [SELECT Id FROM RecurringSlot__c]){
            rsIds.add(rs.Id);
        }
        GenerateSlots_Service.generateSlotsFromRecurringSlots(rsIds);
    }
}