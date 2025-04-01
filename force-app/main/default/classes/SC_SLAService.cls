/*************************************************************************************
 * @Name         : SC_SLAService.cls
 * @Description  : SLA Service class
 * @Created By   : Denys Taldykin
 * @Created Date : January 23, 2023
 * @Modification Log:
 **************************************************************************************
 * Version     Developer      Date        Description
 *-------------------------------------------------------------------------------------
 *************************************************************************************/
public with sharing class SC_SLAService {
    @TestVisible
    private static final String SLA_24_H = '24 H';
    @TestVisible
    private static final String SLA_48_H = '48 H';
    @TestVisible
    private static final String SLA_72_H = '72 H';

    /**
     * @author Denys Taldykin
     * @date January 23, 2023
     * @name updateSLAScheduleDate
     * @param cases List<Case>
     * @description method for updating SLA Scheduled Actions dates
     */
    public static void updateSLAScheduleDate(List<Case> cases) {
        List<BusinessHours> bhList = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];
        BusinessHours bh;
        Datetime startDate;

        try {
            if (!bhList.isEmpty()) {
                bh = bhList[0];

                for (Case c : cases) {
                    if (c.SLA_d_origine__c != null) {
                        if (c.CreatedDate != null) {
                            startDate = c.CreatedDate;
                        } else {
                            startDate = Datetime.now();
                        }

                        if (!BusinessHours.isWithin(bh.Id, startDate)) {
                            startDate = BusinessHours.nextStartDate(bh.Id, startDate);
                        }

                        if (c.SLA_d_origine__c == SLA_24_H) {
                            //clear 48h action scheduled date
                            c.SLA_48h_Sch_Action_Date__c = null;
                            //clear 24h action scheduled date
                            c.SLA_24h_Sch_Action_Date__c = null;
                            //action in 1+ working days - 4h
                            c.SLA_4h_Sch_Action_Date__c = getDateInWorkingDays(startDate, 1, bh).addHours(-4);
                            //action in 1+ working days
                            c.SLA_OutOfTime_Sch_Action_Date__c = getDateInWorkingDays(startDate, 1, bh);
                        }

                        if (c.SLA_d_origine__c == SLA_48_H) {
                            //clear 48h action scheduled date
                            c.SLA_48h_Sch_Action_Date__c = null;
                            //action in 1 working day
                            c.SLA_24h_Sch_Action_Date__c = getDateInWorkingDays(startDate, 1, bh);
                            //action in 1 working days - 4h
                            c.SLA_4h_Sch_Action_Date__c = getDateInWorkingDays(startDate, 2, bh).addHours(-4);
                            //action in 2+ working days
                            c.SLA_OutOfTime_Sch_Action_Date__c = getDateInWorkingDays(startDate, 2, bh);
                        }

                        if (c.SLA_d_origine__c == SLA_72_H) {
                            c.SLA_48h_Sch_Action_Date__c = getDateInWorkingDays(startDate, 1, bh);
                            //action in 1 working day
                            c.SLA_24h_Sch_Action_Date__c = getDateInWorkingDays(startDate, 2, bh);
                            //action in 3 working days - 4h
                            c.SLA_4h_Sch_Action_Date__c = getDateInWorkingDays(startDate, 3, bh).addHours(-4);
                            //action in 3+ working days
                            c.SLA_OutOfTime_Sch_Action_Date__c = getDateInWorkingDays(startDate, 3, bh);
                        }
                    } else {
                        c.SLA_48h_Sch_Action_Date__c = null;
                        c.SLA_24h_Sch_Action_Date__c = null;
                        c.SLA_4h_Sch_Action_Date__c = null;
                        c.SLA_OutOfTime_Sch_Action_Date__c = null;
                    }
                }
            }
        } catch (Exception ex) {
            Logger.error(Label.VE_LoggingTemplate, new List<String>{
                    String.valueOf(ex.getLineNumber()), ex.getMessage(), ex.getStackTraceString()
            });
        }
    }

    /**
     * @author Denys Taldykin
     * @date January 23, 2023
     * @name updateSLAScheduleDate
     * @param cases List<Case>
     * @param oldCases Map<Id, Case>
     * @description method for updating SLA Scheduled Actions dates
     */
    public static void updateSLAScheduleDate(List<Case> cases, Map<Id, Case> oldCases) {
        List<Case> casesToUpdateSLADates = new List<Case>();

        for (Case c : cases) {
            if (c.SLA_d_origine__c != oldCases.get(c.Id).SLA_d_origine__c) {
                casesToUpdateSLADates.add(c);
            }
        }

        updateSLAScheduleDate(casesToUpdateSLADates);
    }

    /**
     * @author Denys Taldykin
     * @date January 23, 2023
     * @name getDateInWorkingDays
     * @param originalDate Datetime
     * @param workingDays Integer
     * @param bh BusinessHours
     * @return Datetime
     * @description method for calculating next working day in business hours date time
     */
    private static Datetime getDateInWorkingDays(Datetime originalDate, Integer workingDays, BusinessHours bh) {
        Datetime dateWorkingDays = originalDate;
        Integer workingDaysCounter = 0;
        Integer totalCounter = 0;

        if (workingDays == 0) {
            return BusinessHours.nextStartDate(bh.Id, originalDate);
        } else {
            while (workingDays > workingDaysCounter && totalCounter < 100) {
                dateWorkingDays = dateWorkingDays.addDays(1);
                totalCounter++;
                
                if (BusinessHours.isWithin(bh.Id, dateWorkingDays)) {
                    workingDaysCounter++;
                }
            }
        }

        return dateWorkingDays;
    }
}