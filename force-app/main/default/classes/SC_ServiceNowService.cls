/*************************************************************************************
 * @Name         : SC_ServiceNowService.cls
 * @Description  : Class for handling ServiceNow Incident updates
 * @Created By   : Denys Taldykin
 * @Created Date : September 18, 2023
 * @Modification Log:
 **************************************************************************************
 * Version     Developer      Date        Description
 *-------------------------------------------------------------------------------------
 *
 *************************************************************************************/
public without sharing class SC_ServiceNowService {
    private static final String SERVICE_NOW_CASE_STATUS = 'Envoyé à OASIS';
    private static final String CASE_STATUS_ON_HOLD = 'On Hold';
    private static final String DESCRIPTION_TEMPLATE = 'Numéro carte U : "{0}" |  Description: "{1}"';
    private static final String COURSES_U_CATEGORY = 'Courses U';
    private static final String MAGASINS_U_CATEGORY = 'Magasin U';
    @TestVisible
    private static final String NOTE_TYPE_ADDITIONAL_COMMENTS = 'Additional Comments';
    @TestVisible
    private static ServiceNow_Settings__mdt serviceNowSettings = getServiceNowSettings();

    /**
     * @author Denys Taldykin
     * @date September 18, 2023
     * @name createServiceNowIncident
     * @param caseId Id
     * @param category String
     * @param comment String
     * @param parentIncidentId String
     * @return String
     * @description Method to create ServiceNow Incident
     */
    public static String createServiceNowIncident(Id caseId, String category, String comment, String parentIncidentId) {
        try {
            String incidentJson = syncCaseToIncident(caseId, category, comment, parentIncidentId);
            Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(incidentJson);

            updateCase(resultMap, caseId);

            return 'success';

        } catch (Exception exc) {
            return exc.getMessage();
        }
    }

    /**
     * @author Denys Taldykin
     * @date September 18, 2023
     * @name syncCaseToIncident
     * @param caseId Id
     * @param category String
     * @param comment String
     * @param parentIncidentId String
     * @return String
     * @description Method to create ServiceNow Incident
     */
    public static String syncCaseToIncident(Id caseId, String category, String comment, String parentIncidentId) {
        Case c = getCaseRecord(caseId);
        String endpoint = 'callout:ServiceNow/api/now/table/incident';
        Map<String, String> headers = new Map<String, String>();
        String requestBody = getCreateIncidentRequestBody(c, category, comment, parentIncidentId);

        Integer timeout = serviceNowSettings.RequestTimeout__c != null ? (Integer) serviceNowSettings.RequestTimeout__c : 2000;

        headers.put(SC_CalloutService.CONTENT_TYPE, SC_CalloutService.CONTENT_TYPE_JSON);

        return SC_CalloutService.executeRequest(SC_CalloutService.POST_METHOD, endpoint, requestBody, headers, timeout).getBody();
    }

    /**
     * @author Denys Taldykin
     * @date September 18, 2023
     * @name getCreateIncidentRequestBody
     * @param c Case
     * @param category String
     * @param comment String
     * @param parentIncidentId String
     * @return String
     * @description Method to create ServiceNow Incident request body
     */
    private static String getCreateIncidentRequestBody(Case c, String category, String comment, String parentIncidentId) {
        Map<String, String> incidentMap = new Map<String, String>();
        String assignmentGroup;
        String loyaltyCardId;
        String description;
        String uCategory;

        if (COURSES_U_CATEGORY.containsIgnoreCase(category)) {
            category = serviceNowSettings.CoursesUCategory__c;
            assignmentGroup = serviceNowSettings.CoursesUId__c;
            uCategory = String.isNotBlank(serviceNowSettings.CoursesUUCategory__c) ? serviceNowSettings.CoursesUUCategory__c : category;
        } else {
            if (MAGASINS_U_CATEGORY.containsIgnoreCase(category)) {
                category = serviceNowSettings.MagasinsUCategory__c;
                assignmentGroup = serviceNowSettings.MagasinsUId__c;
                uCategory = String.isNotBlank(serviceNowSettings.MagasinsUUCategory__c) ? serviceNowSettings.MagasinsUUCategory__c : category;
            } else {

            }
        }

        loyaltyCardId = String.isNotBlank(c.LoyaltyCardID__c) ?
                c.LoyaltyCardID__c : c.AccountId != null ?
                        String.isNotBlank(c.Account.LoyaltyCardID__pc) ?
                                c.Account.LoyaltyCardID__pc : '' : '';

        description = String.format(DESCRIPTION_TEMPLATE, new List<String>{
                loyaltyCardId, c.Description
        });

        incidentMap.put('u_contact', getContactValue(c));
        incidentMap.put('correlation_display', c.CaseNumber);
        incidentMap.put('description', description);
        incidentMap.put('opened_at', getFormattedDate(c.CreatedDate));
        incidentMap.put('category', category);
        incidentMap.put('assignment_group', assignmentGroup);
        incidentMap.put('correlation_id', c.Id);
        incidentMap.put('priority', serviceNowSettings.Priority__c);
        incidentMap.put('u_category', uCategory);

        if (String.isNotBlank(parentIncidentId)) {
            incidentMap.put('parent_incident', parentIncidentId);
        }

        System.debug(JSON.serialize(incidentMap));
        return JSON.serialize(incidentMap);
    }

    /**
     * @author Denys Taldykin
     * @date September 18, 2023
     * @name getCaseRecord
     * @param caseId Id
     * @return Case
     * @description Method query Case by Case Id
     */
    private static Case getCaseRecord(Id caseId) {
        Case c = [
                SELECT
                        Id,
                        CaseNumber,
                        CreatedDate,
                        Description,
                        Account.FirstName,
                        Account.LastName,
                        Account.PersonEmail,
                        Account.Email_ID__c,
                        Account.LoyaltyCardID__pc,
                        LoyaltyCardID__c,
                        SuppliedEmail,
                        Type
                FROM Case
                WHERE Id = :caseId
        ];

        return c;
    }

    /**
     * @author Denys Taldykin
     * @date September 18, 2023
     * @name updateCase
     * @param resultMap Map<String, Object>
     * @param caseId String
     * @description Method update Case with ServiceNow data after ServiceNow Incident creation
     */
    private static void updateCase(Map<String, Object> resultMap, String caseId) {
        Case c = new Case(Id = caseId);
        Map<String, Object> incidentMap = (Map<String, Object>) resultMap.get('result');

        c.ServiceNowId__c = String.valueOf(incidentMap.get('sys_id'));
        c.ServiceNowStatus__c = SERVICE_NOW_CASE_STATUS;
        c.Status = CASE_STATUS_ON_HOLD;

        update c;
    }

    /**
     * @author Denys Taldykin
     * @date September 18, 2023
     * @name createServiceNowNote
     * @param caseId Id
     * @param comment String
     * @param commentType String
     * @return String
     * @description Method to create ServiceNow Incident
     */
    public static String createServiceNowNote(Id caseId, String comment, String commentType) {
        try {
            syncServiceNowNote(caseId, comment, commentType);

            return 'success';

        } catch (Exception exc) {
            return exc.getMessage();
        }
    }

    /**
     * @author Denys Taldykin
     * @date September 18, 2023
     * @name syncCaseToIncident
     * @param caseId Id
     * @param comment String
     * @param commentType String
     * @return String
     * @description Method to create ServiceNow Incident
     */
    public static String syncServiceNowNote(Id caseId, String comment, String commentType) {
        Case c = [SELECT Id, ServiceNowId__c FROM Case WHERE Id = :caseId LIMIT 1];

        return syncServiceNowNote(c.ServiceNowId__c, comment, commentType);
    }

    /**
     * @author Denys Taldykin
     * @date September 18, 2023
     * @name syncCaseToIncident
     * @param serviceNowId String
     * @param comment String
     * @param commentType String
     * @return String
     * @description Method to create ServiceNow Incident
     */
    public static String syncServiceNowNote(String serviceNowId, String comment, String commentType) {
        String endpoint = 'callout:ServiceNow/api/now/table/incident/' + serviceNowId;
        Map<String, String> headers = new Map<String, String>();
        String requestBody = getCreateNoteRequestBody(comment, commentType);
        System.debug('Request Body: ' + requestBody);
        Integer timeout = serviceNowSettings.RequestTimeout__c != null ? (Integer) serviceNowSettings.RequestTimeout__c : 2000;

        headers.put(SC_CalloutService.CONTENT_TYPE, SC_CalloutService.CONTENT_TYPE_JSON);

        return SC_CalloutService.executeRequest(SC_CalloutService.PATCH_METHOD, endpoint, requestBody, headers, timeout).getBody();
    }

    /**
     * @author Denys Taldykin
     * @date September 18, 2023
     * @name getCreateNoteRequestBody
     * @param comment String
     * @param commentType String
     * @return String
     * @description Method to create ServiceNow Incident request body
     */
    private static String getCreateNoteRequestBody(String comment, String commentType) {
        Map<String, String> incidentMap = new Map<String, String>();
        if (commentType == NOTE_TYPE_ADDITIONAL_COMMENTS) {
            incidentMap.put('comments', comment);
        } else {
            incidentMap.put('work_notes', comment);
        }

        return JSON.serialize(incidentMap);
    }

    /**
     * @author Denys Taldykin
     * @date September 18, 2023
     * @name getFormattedDate
     * @param d Datetime
     * @return String
     * @description Method format Date value to ServiceNow format
     */
    private static String getFormattedDate(Datetime d) {
        Integer timeZoneShift = Integer.valueOf(serviceNowSettings.TimeZoneShift__c);
        d = d.addHours(timeZoneShift);
        Datetime dateTimeInstance = Datetime.newInstance(d.year(), d.month(), d.day(), d.hour(), d.minute(), d.second());

        return dateTimeInstance.formatGmt('yyyy-MM-dd HH:mm:ss');
    }

    /**
     * @author Denys Taldykin
     * @date September 18, 2023
     * @name getServiceNowSettings
     * @return ServiceNow_Settings__mdt
     * @description Method query ServiceNow Settings custom metadata
     */
    private static ServiceNow_Settings__mdt getServiceNowSettings() {
        List<ServiceNow_Settings__mdt> settings = [
                SELECT
                        Id,
                        CoursesUId__c,
                        CoursesUCaseTypes__c,
                        CoursesUCategory__c,
                        MagasinsUId__c,
                        MagasinsUCaseTypes__c,
                        MagasinsUCategory__c,
                        TimezoneShift__c,
                        Priority__c,
                        RequestTimeout__c,
                        MagasinsUUCategory__c,
                        CoursesUUCategory__c
                FROM ServiceNow_Settings__mdt
                LIMIT 1
        ];

        if (!settings.isEmpty()) {
            return settings[0];
        } else {
            return null;
        }
    }

    /**
     * @author Denys Taldykin
     * @date September 18, 2023
     * @name getContactValue
     * @param c Case
     * @return String
     * @description Method format Service Now Incident Contact Name
     */
    private static String getContactValue(Case c) {
        String email = '';
        String firstName = '';
        String lastName = '';

        if (String.isNotBlank(c.SuppliedEmail)) {
            email = c.SuppliedEmail;
        }

        if (c.Account != null) {
            if (String.isNotBlank(c.Account.FirstName)) {
                firstName = c.Account.FirstName;
            }
            if (String.isNotBlank(c.Account.LastName)) {
                lastName = c.Account.LastName;
            }
            if (String.isBlank(email) && String.isNotBlank(c.Account.Email_ID__c)) {
                email = c.Account.Email_ID__c;
            }
        }

        return firstName + ' - ' + lastName + ' - ' + email;
    }
}