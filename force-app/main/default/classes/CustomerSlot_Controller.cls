/**
* @author : Nicolas (Salesforce)
* @date : 20/04/2020
* @description : class to handle the CustomerSlots
* @last modified date/comments :
*/
public with sharing class CustomerSlot_Controller {
    
    /**
    * @description searchTodayCustomerSlotByEmail
    * @param searchTerm : searchTerm (must be the email)
    * @return list of CustomerSlot__c
    */
    @AuraEnabled
    public static List<CustomerSlot__c> searchTodayCustomerSlotByEmail(String searchTerm){
        System.debug(LoggingLevel.DEBUG,'searchTerm:' + searchTerm);

        User u = [SELECT Id,StoreId__c FROM User WHERE Id = :UserInfo.getUserId()];

        Date d = System.today();
        Date tomorrow = System.today() + 1;
        List<List<sObject>> searchList = [FIND :searchTerm IN ALL FIELDS RETURNING CustomerSlot__c(Id WHERE TechnicalStartDatetime__c >= :d AND TechnicalStartDatetime__c < :tomorrow LIMIT 4)];

        List<CustomerSlot__c> searchCustomerSlots = (CustomerSlot__c[])searchList[0];
        System.debug(LoggingLevel.DEBUG,'searchCustomerSlots:' + searchCustomerSlots.size());
        List<Id> csIds = new List<Id>();
        for(CustomerSlot__c cs : searchCustomerSlots){
            csIds.add(cs.Id);
        }
        System.debug(LoggingLevel.DEBUG,'csIds: ' + csIds.size());
        
        if(!csIds.isEmpty()){
            return Security.stripInaccessible(AccessType.READABLE,[SELECT Id,Name,Account__r.Name,ProvidedEmail__c,ProvidedName__c,StartDatetime__c,Status__c,ProvidedNumberOfPersons__c,StatusIcon__c FROM CustomerSlot__c WHERE Id IN :csIds]).getRecords();
        }
        return new List<CustomerSlot__c>();
    }

    /**
    * @description searchTodayCustomerSlotByEmail
    * @param searchTerm : searchTerm (must be the email)
    * @return list of CustomerSlot__c
    */
    @AuraEnabled(cacheable=true)
    public static CustomerSlot__c getSlotByIdOrUUID(String recordId){
        System.debug(LoggingLevel.DEBUG,'recordId:' + recordId);
        List<CustomerSlot__c> cs = Security.stripInaccessible(AccessType.READABLE,[SELECT Id,UUID__c,Status__c,StatusIcon__c FROM CustomerSlot__c WHERE Id = :recordId OR UUID__c = :recordId LIMIT 1]).getRecords();
        if(cs.isEmpty()){
            return new CustomerSlot__c();
        }
        else{
            return cs.get(0);
        }
    }

    @AuraEnabled
    public static Account getStoreCount(){
        User u = [SELECT Id,StoreId__c FROM User WHERE Id = :UserInfo.getUserId()];
        return [SELECT Id,Name,StoreId__c,StoreCustomerCount__c,StoreMaxCustomer__c FROM Account WHERE StoreId__c = :u.StoreId__c LIMIT 1];
    }

    @AuraEnabled
    public static Account setStoreCount(String op){
        System.debug(LoggingLevel.DEBUG,'op: ' + op);
        User u = [SELECT Id,StoreId__c FROM User WHERE Id = :UserInfo.getUserId()];
        Account store = [SELECT Id,Name,StoreId__c,StoreCustomerCount__c,StoreMaxCustomer__c FROM Account WHERE StoreId__c = :u.StoreId__c LIMIT 1];
        if(op.equalsIgnoreCase('minus')){
            store.StoreCustomerCount__c = Math.max(store.StoreCustomerCount__c - 1,0);
        }
        else{
            store.StoreCustomerCount__c = store.StoreCustomerCount__c + 1;
        }
        update store;
        return store;
    }

    @AuraEnabled
    public static void checkinCustomer(String id,Integer numOfpeople){
        System.debug(LoggingLevel.DEBUG,'id: ' + id + ' numOfpeople: ' + numOfpeople);
        CustomerSlot__c cs = [SELECT Id,Account__c,Status__c,ActualNumberOfPersons__c FROM CustomerSlot__c WHERE Id = :id];
        if(!cs.Status__c.equals('Booked')){
            throw new AuraException('Ce créneau ne peut pas/plus être utilisé');
        }
        cs.Status__c = 'Checked-In';
        cs.ActualNumberOfPersons__c = numOfpeople;
        update cs;

        Account store = [SELECT Id,Name,StoreId__c,StoreCustomerCount__c,StoreMaxCustomer__c FROM Account WHERE Id = :cs.Account__c LIMIT 1];
        store.StoreCustomerCount__c = store.StoreCustomerCount__c + numOfpeople;
        update store;
    }
}