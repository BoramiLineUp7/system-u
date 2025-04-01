/**
* @author : Nicolas Greard (Salesforce)
* @date : 16/06/2020
* @description : class to handle the account header
* @last modified date/comments :
*/
global with sharing class Batch_StoreResetCounter implements Database.Batchable<sObject>,schedulable {
    public Integer BATCH_SIZE = 200;

    /**
    * @description start
    * @param bc : context
    * @return query
    */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id,StoreCustomerCount__c,IsIncludedOnlineBooking__c FROM Account WHERE IsIncludedOnlineBooking__c = true AND StoreCustomerCount__c > 0'
        );
    }

    global void execute(Database.BatchableContext bc, List<Account> accs){
        for(Account a : accs){
            a.StoreCustomerCount__c = 0;
        }

        System.debug(LoggingLevel.DEBUG,'accs: ' + accs.size());
        if(!accs.isEmpty()){
            update accs;
        }
    }

    global void finish(Database.BatchableContext bc){
    }
    
    /**
    * @description scheduler
    * @param ctx : context
    */
    global void execute(SchedulableContext ctx){
        database.executebatch(new Batch_StoreResetCounter(),BATCH_SIZE);
    }
}