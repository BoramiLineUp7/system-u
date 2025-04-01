/**
* @author : Nicolas (Salesforce)
* @date : 20/04/2020
* @description : class to handle the CustomerSlots
* @last modified date/comments :
*/
@isTest
public class TestDataFactory {

    /*Create Running User*/
    public static User createRunningUser(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String key = EncodingUtil.convertToHex(crypto.generateAesKey(128));
        String userEmailPrefix = key.substring(0, 10);
        
        User user = new User(Alias = 'test', Email =  userEmailPrefix+'@test.fr',
                             EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                             LocaleSidKey = 'en_US', ProfileId = p.Id,
                             TimeZoneSidKey = 'Europe/Paris', UserName = userEmailPrefix+'@test.fr');
        insert user;
        return user;
    }

    /*Create Accounts*/
    public static List<Account> createAccount(integer nb) {
        List<Account> accs = new List<Account>();
        for(Integer i=0;i<nb;i++) {
            accs.add(new Account(Name='Test Account' + i,StoreId__c= '' + i));
        }
        insert accs;
        return accs;
    }
    /*Create RecurringSlot__c*/
    public static List<RecurringSlot__c> createRecurringSlot(String accId,integer nb) {
        List<RecurringSlot__c> rs = new List<RecurringSlot__c>();
        Time startTime = Time.newInstance(9, 0, 0, 0);
        for(Integer i=0;i<nb;i++) {
            rs.add(new RecurringSlot__c(Account__c=accId,isActive__c=true,RecurrenceDays__c='Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday',
                        StartDatetime__c=Datetime.now(),AvailablePositions__c=10,Duration__c=60,StartTime__c=startTime,EndTime__c=startTime.addHours(8)));
        }
        insert rs;
        return rs;
    }
    /*Create Slot__c*/
    public static List<Slot__c> createSlot(String accId,String recurringSlotId,integer nb) {
        List<Slot__c> s = new List<Slot__c>();
        for(Integer i=0;i<nb;i++) {
            s.add(new Slot__c(Account__c=accId,RecurringSlot__c=recurringSlotId,StartDatetime__c=Datetime.now()));
        }
        insert s;
        return s;
    }
    /*Create CustomerSlot__c*/
    public static List<CustomerSlot__c> createCustomerSlot(String accId,String slotId,integer nb) {
        List<CustomerSlot__c> cs = new List<CustomerSlot__c>();
        Datetime dt = Datetime.now();
        for(Integer i=0;i<nb;i++) {
            cs.add(new CustomerSlot__c(Account__c=accId,Slot__c=slotId,
                                       ProvidedFirstName__c='Test ' + i,
                                       ProvidedLastName__c='Test ' + i,
                                       ProvidedEmail__c = 'test' + i + '@testclient.com',
                                       ProvidedNumberOfPersons__c=1,
                                       ExpectedStartDatetime__c = dt,
                                       UUID__c = GuidUtil.NewGuid()));
        }
        insert cs;
        return cs;
    }

    public static Slot__c createUnitTestCaseSlot() {
        Account a = createAccount(1).get(0);
        RecurringSlot__c rs = createRecurringSlot(a.Id,1).get(0);
        return createSlot(a.Id,rs.Id,1).get(0);
    }

    public static CustomerSlot__c createUnitTestCase() {
        Account a = createAccount(1).get(0);
        RecurringSlot__c rs = createRecurringSlot(a.Id,1).get(0);
        Slot__c s = createSlot(a.Id,rs.Id,1).get(0);
        return createCustomerSlot(a.Id,s.Id,1).get(0);
    }

    public static void createCS(){
        insert new reCaptcha__c(
            isReCaptchaEnabled__c=true,
            SecretKey__c='23456789',
            SiteKey__c='234567IUHG');
        insert new QueueBustingConfig__c(
            DefaultSlotDuration__c=60,
            NumWeeksGeneratedSlots__c=1,
            isCheckCustomerSlotDaysEnabled__c = true,
            NumberOfDaysBeforeToCheck__c = 0,
            NumberOfDaysAfterToCheck__c = 2,
            isGeneratePdfEnabled__c = true);
    }

}