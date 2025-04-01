/*************************************************************************************
 * @Name         : SC_EmailTemplateChangeEventTrigger.cls
 * @Description  : Trigger for updating email templates css styling
 * @Created By   : Denys Taldykin
 * @Created Date : February 5, 2024
 * @Modification Log:
 **************************************************************************************
 * Version     Developer      Date        Description
 *-------------------------------------------------------------------------------------
 *************************************************************************************/
trigger SC_EmailTemplateChangeEventTrigger on EmailTemplateChangeEvent (after insert) {
    try {
        List<EmailTemplate> emailTemplates;
        List<EmailTemplate> emailTemplatesToUpdate;
        Set<String> templatesIds = new Set<String>();

        for (EmailTemplateChangeEvent e : Trigger.new) {
            EventBus.ChangeEventHeader header = e.ChangeEventHeader;
            if (header.changeType == 'CREATE' || header.changeType == 'UPDATE') {
                List<String> recordIds = header.getRecordIds();

                if (recordIds != null && !recordIds.isEmpty()) {
                    templatesIds.addAll(recordIds);
                }
            }
        }

        emailTemplates = [SELECT Id, HtmlValue FROM EmailTemplate WHERE Id IN :templatesIds];
        emailTemplatesToUpdate = new List<EmailTemplate>();

        for (EmailTemplate et : emailTemplates) {
            if (String.isNotBlank(et.HtmlValue)) {
                if (et.HtmlValue.contains('<html style="overflow-y: hidden;">')) {
                    et.HtmlValue = et.HtmlValue.replace('<html style="overflow-y: hidden;">', '<html style="overflow-y: scroll;">');
                    emailTemplatesToUpdate.add(et);
                }
            }
        }

        if (!emailTemplatesToUpdate.isEmpty()) {
            update emailTemplatesToUpdate;
        }

    } catch (Exception exc) {
        Logger.error('SC SC_EmailTemplateChangeEventTrigger', new List<String>{
                String.valueOf(exc.getLineNumber()), exc.getMessage(), exc.getStackTraceString()
        });
    }
}