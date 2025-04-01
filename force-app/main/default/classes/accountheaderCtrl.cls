/**
* @author : 
* @date : 23/04/2020
* @description : class to handle the account header
* @last modified date/comments :
*/
public without sharing class accountheaderCtrl {
    //without sharing due to usage as guest user (better than open sharing)

    @AuraEnabled(Cacheable = true)
    public static Account getAccount(String storeId) {
        System.debug(LoggingLevel.DEBUG,'storeId: ' + storeId);
        if(String.isNotBlank(storeId)){
            Account a = [SELECT Id, Industry, Name, CommercialSignLabel__c, Phone, BillingCity,BillingCountry,BillingPostalCode,BillingStreet, StoreId__c,StoreEmail__c 
            FROM Account
            WHERE StoreId__c =: storeId];
            System.debug(LoggingLevel.DEBUG,'account fields are' + a);
            return a;
        }
        else{
            return new Account();
        }
    }
}