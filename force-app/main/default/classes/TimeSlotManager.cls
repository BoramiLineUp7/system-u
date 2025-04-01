/**
* @author : 
* @date : 20/04/2020
* @description : class to handle time slot (guest page)
* @last modified date/comments :
*/
public without sharing class TimeSlotManager {
    //without sharing due to usage as guest user (better than open sharing)
    
    //(cacheable=true)
    @AuraEnabled(cacheable=false)
    public static List<HoursWrapper> getSlots( String storeId,Integer dateOffset ) {
        Integer STARTTIME = 8;
        Integer LENGTH_OF_DAY = 8;
        System.debug(LoggingLevel.DEBUG,'storeId: ' + storeId + ' dateOffset: ' + dateOffset );
        Date d = Date.today();
        Date startdate = d.addDays(dateOffset);
        Date enddate = startdate.addDays(7);
        System.debug(LoggingLevel.DEBUG,'startDate: ' + startdate + ' enddate: ' + enddate);

        List<HoursWrapper> hourWrapperList = new List<HoursWrapper>();
        Map<String,List<SlotWrapper>> timeSlotMap = new Map<String, List<SlotWrapper>>();

        List<Slot__c> slots = [SELECT Id, Account__r.StoreId__c, StartDatetime__c, RemainingPositions__c, AvailablePositions__c,IsActive__c
                                        FROM Slot__c 
                                        WHERE StartDatetime__c > :startdate AND StartDatetime__c < :enddate 
                                          AND Account__r.StoreId__c = :storeId
                                          AND IsActive__c = true
                                        ORDER BY StartDatetime__c];

        String lastDay = '';
        String lastHour = '';
        String lastMinutes = '';
        for(Slot__c s : slots){ 
            //Create SlotWrapper
            SlotWrapper sw = new SlotWrapper();
            sw.id = s.Id;
            sw.day = s.StartDatetime__c.format('d');
            sw.hour = s.StartDatetime__c.format('HH');
            sw.minutes = s.StartDatetime__c.format('mm');
            sw.remainingPositions = Integer.valueOf(s.RemainingPositions__c);
            sw.defaultPositions = Integer.valueOf(s.AvailablePositions__c);
            sw.StartDatetime = s.StartDatetime__c;

            // Get value the first of hour of slot --> aggregate by hour
            /*if(lastDay + lastHour != sw.day + sw.hour){
                lastMinutes = sw.minutes;
            }
            String timeS = sw.hour + ':' + lastMinutes;
            lastDay = sw.day;
            lastHour = sw.hour;*/
            String timeS = sw.hour + ':00';

            // If the key exists add record to it
            if (timeSlotMap.containsKey(timeS)){
                    timeSlotMap.get(timeS).add(sw);
            } 
            // If the key does not exists create it and add record
            else {
                timeSlotMap.put(timeS, new  List <SlotWrapper> { sw });
            }
        }

        System.debug(LoggingLevel.DEBUG,'Map: ' + timeSlotMap);

        for (String key : timeSlotMap.keySet()) {
            HoursWrapper hoursWrap = new HoursWrapper();
            hoursWrap.hour = String.valueof(key);
            System.debug(LoggingLevel.DEBUG,'yyyy: ' + timeSlotMap.get(key));           
            hoursWrap.slots = timeSlotMap.get(key);
            hourWrapperList.add(hoursWrap);
        }          
        System.debug(LoggingLevel.DEBUG,'Map2: ' + hourWrapperList);   
        hourWrapperList.sort();

        return hourWrapperList;
    }

    public class HoursWrapper implements Comparable {
        @AuraEnabled
        public String hour {get; set;}
        @AuraEnabled
        public List<SlotWrapper> slots {get; set;}

        public Integer compareTo(Object other) {
            String compareToHour = ((HoursWrapper)other).hour;
            return Integer.valueOf(hour.left(2)) - Integer.valueOf(compareToHour.left(2));
        }
    }
    public class SlotWrapper {
        @AuraEnabled
        public String id {get; set;}
        @AuraEnabled
        public String day {get; set;}
        @AuraEnabled
        public String hour {get; set;}
        @AuraEnabled
        public String minutes {get; set;}
        @AuraEnabled
        public Integer remainingPositions {get; set;}
        @AuraEnabled
        public Integer defaultPositions {get; set;}
        @AuraEnabled
        public Datetime StartDatetime {get; set;}
    }     
}