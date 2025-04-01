/**
* @author : Nicolas Greard(Salesforce)
* @date : 08/05/2020
* @description : class to handle slots generation
* @last modified date/comments :
*/
public with sharing class GenerateSlots_Service {
    
    private static Map<String, Integer> daysMap = new Map<String, Integer>{'Monday' => 0, 'Tuesday' => 1, 'Wednesday' => 2,'Thursday' => 3,'Friday' => 4,'Saturday' => 5,'Sunday' => 6};

    @InvocableMethod
    public static List<Integer> generateSlotsFromRecurringSlots(List<String> rsIds) {
        System.debug(LoggingLevel.DEBUG,'rsIds:' + rsIds);
        Integer totalInsert = 0;
        Integer numOfWeeks = Integer.valueOf(QueueBustingConfig__c.getInstance().NumWeeksGeneratedSlots__c);
        if(!rsIds.isEmpty()){
            for(Integer i=0; i < numOfWeeks; i++){
                totalInsert += generateSlotsFromRecurringSlotsIds(rsIds,i);
            }  
        }
        return new List<Integer> {totalInsert};
    }

    public static Integer generateSlotsFromRecurringSlotsIds(List<String> rsIds,Integer weekOffset){
        Integer totalInsert = 0;
        System.debug(LoggingLevel.DEBUG,'rsIds: ' + rsIds + ' weekOffset: ' + weekOffset);
        List<RecurringSlot__c> rslots= [SELECT Id,StartTime__c,RecurrenceDays__c,EndTime__c,Duration__c,Account__c
                                         FROM RecurringSlot__c
                                        WHERE Id IN :rsIds AND IsActive__c = true]; //only active recurring slots
        
        Map<String,Slot__c> slots = new Map<String,Slot__c>();
        Datetime now = Datetime.now();
        Set<String> accIds = new Set<String>();
        for(RecurringSlot__c rs : rslots){
            accIds.add(rs.Account__c);
            String[] days = rs.RecurrenceDays__c.split(';');
            Integer duration = Integer.valueOf(rs.Duration__c);
            //For all specified recurring days
            for(String d : days){
                //generate the date from day + week offset
                Date startOfWeek = Date.today().toStartofWeek().addDays(weekOffset*7);
                Date startDay = startOfWeek.addDays(daysMap.get(d));

                Time startTime = rs.StartTime__c;
                //generate slots for specific day between starttime and endtime from a recurring slot
                while(startTime < rs.EndTime__c){
                    Datetime slotSartdt = DateTime.newInstance(startDay, startTime);
                    //generate slot only if they are planned in the future
                    if(now < slotSartdt){
                        System.debug(LoggingLevel.FINEST,'create slot : ' + slotSartdt);
                        Slot__c s = new Slot__c(
                            Account__c = rs.Account__c,
                            StartDatetime__c = slotSartdt,
                            IsActive__c = true,
                            RecurringSlot__c = rs.Id
                        );
                        slots.put(s.Account__c + slotSartdt.format('yyyy-MM-dd\'T\'HH:mm'),s); //generate unique key to dedup
                    }
                    startTime = startTime.addMinutes(duration);
                }
            }
        }

        System.debug(LoggingLevel.DEBUG,'accIds: ' + accIds.size());
        List<Slot__c> existingSlots = [SELECT Id,Account__c,StartDatetime__c FROM Slot__c WHERE Account__c IN :accIds AND IsActive__c = true];
        Set<String> slotKeys = new Set<String>();
        for(Slot__c s : existingSlots){
            slotKeys.add(s.Account__c + s.StartDatetime__c.format('yyyy-MM-dd\'T\'HH:mm'));
        }

        System.debug(LoggingLevel.DEBUG,'slots generated: ' + slots.size());
        if(!slots.isEmpty()){
            //remove duplicate
            List<Slot__c> toInsert = new List<Slot__c>();
            for(String key : slots.keySet()){
                if(!slotKeys.contains(key)){
                    toInsert.add(slots.get(key));
                }
            }

            totalInsert = toInsert.size();
            System.debug(LoggingLevel.DEBUG,'toInsert: ' + totalInsert);
            if(!toInsert.isEmpty()){
                insert toInsert;
            }
        }
        return totalInsert;
    }

}