/**
* @author : Nicolas (Salesforce)
* @date : 20/04/2020
* @description : class to handle the Storelocator component
* @last modified date/comments :
*/
public without sharing class Storelocator_Controller {

    @AuraEnabled(cacheable=true)
    public static List<Account> searchStore(String searchTerms){
        System.debug('searchTerms: ' + searchTerms);
        if(String.isNotBlank(searchTerms) && String.isNotBlank(searchTerms.trim())){
            return [FIND :searchTerms IN ALL FIELDS RETURNING Account(Id,StoreId__c,Name,CommercialSignLabel__c,BillingStreet,BillingPostalCode,BillingCity WHERE RecordType.DeveloperName = 'Store' LIMIT 10)].get(0);
        }
        return new List<Account>();
    }
}