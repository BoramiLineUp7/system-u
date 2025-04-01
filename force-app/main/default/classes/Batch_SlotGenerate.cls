/**
* @author : Nicolas Greard (Salesforce)
* @date : 2/5/2020
* @description : class to generate slot based on account config
* @last modified date/comments :
*/
global class Batch_SlotGenerate implements Database.Batchable<sObject>,schedulable{
    public Integer BATCH_SIZE = 200;
    public Date firstDayOfWeek = Date.newInstance(2020,5,4);
    /**
    * @description start
    * @param bc : context
    * @return query
    */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id,Account__c,AvailablePositions__c,IsActive__c,RecurrenceDays__c,StartDatetime__c,Account__r.IsIncludedOnlineBooking__c FROM RecurringSlot__c WHERE IsActive__c = true AND Account__r.IsIncludedOnlineBooking__c = true'
        );
    }

    global void execute(Database.BatchableContext bc, List<RecurringSlot__c> rss){
        List<String> rsIds = new List<String>();
        for(RecurringSlot__c rs : rss){
            rsIds.add(rs.Id);
        }
        System.debug(LoggingLevel.DEBUG,'rsIds:' + rsIds.size());
        if(!rsIds.isEmpty()){
            Integer numOfWeeks = Integer.valueOf(QueueBustingConfig__c.getInstance().NumWeeksGeneratedSlots__c);
            GenerateSlots_Service.generateSlotsFromRecurringSlotsIds(rsIds,numOfWeeks - 1);
        }
    }

    global void finish(Database.BatchableContext bc){
    }
    
    /**
    * @description scheduler
    * @param ctx : context
    */
    global void execute(SchedulableContext ctx){
        database.executebatch(new Batch_SlotGenerate(),BATCH_SIZE);
    }
}