public with sharing class SC_GeminiEmailResponseInvocable {
    private static final String NEW_STATUS = 'New';
    private static final String DRAFT_STATUS = 'Draft';
    private static final String SUCCESS_STATUS = 'success';

    @InvocableMethod
    public static List<FlowInput> createGeminiEmailResponse(List<FlowOutput> flowParameters) {
        List<FlowInput> flowInputs = new List<FlowInput>();

        for (FlowOutput p : flowParameters) {
            Case c = [SELECT Id, OwnerId, Description, SuppliedEmail, Account.Name, Subject FROM Case WHERE Id = :p.caseId];
            EmailMessage e = createEmailMessageDraft(c, p.emailAddress, p.geminiResponse);

            createGeminiResponse(c, e, p);

            flowInputs.add(new FlowInput(SUCCESS_STATUS));
        }

        return flowInputs;
    }

    private static EmailMessage createEmailMessageDraft(Case c, String emailAddress, String geminiCaseResponse) {
        SC_Gemini_Settings__c geminiSettings = SC_Gemini_Settings__c.getOrgDefaults();
        String responseHtml;
        EmailMessage m = new EmailMessage();
        String formattedResponse = geminiCaseResponse.replace(' ', '&nbsp;').replace('\n', '<br/>');
        if (String.isNotBlank(geminiSettings.Gemini_Email_Template_Developer_Name__c)) {
            EmailTemplate et = [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName = :geminiSettings.Gemini_Email_Template_Developer_Name__c];        
            responseHtml = et.HtmlValue.replace(geminiSettings.Email_Template_Body_Parameter__c, formattedResponse);
            responseHtml = responseHtml.replace('<html style="overflow-y: hidden;">','<html>');
        } else {
            responseHtml = formattedResponse;
            responseHtml = responseHtml.replace('<html style="overflow-y: hidden;">','<html>');
        }

        m.IsPrivateDraft = true;
        //m.Subject = 'RE: ' + c.Subject;
        m.Subject = 'Les magasins U vous répondent';
        m.RelatedToId = c.Id;
        m.Status = '5';
        m.FromAddress = emailAddress;
        m.ToAddress = c.SuppliedEmail;
        m.HtmlBody = responseHtml;

        insert m;

        return m;
    }

    private static void createGeminiResponse(Case c, EmailMessage e, FlowOutput p) {
        SC_Gemini_Email_Response__c r = new SC_Gemini_Email_Response__c();

        r.Email_Message_Id__c = e.Id;
        r.Gemini_Response__c = p.geminiResponse;
        r.Gemini_Sync_Status__c = NEW_STATUS;
        r.Gemini_Score__c = p.geminiScore;
        r.User_Hint__c = p.userHint;
        r.Gemini_Score_Text__c = p.geminiScoreText;
        r.Prompt__c = p.prompt;
        r.Status__c = DRAFT_STATUS;
        r.Case__c = c.Id;

        insert r;
    }

    public class FlowOutput {
        @InvocableVariable
        public String caseId;
        @InvocableVariable
        public String emailAddress;
        @InvocableVariable
        public String prompt;
        @InvocableVariable
        public String userHint;
        @InvocableVariable
        public String geminiResponse;
        @InvocableVariable
        public Decimal geminiScore;
        @InvocableVariable
        public String geminiScoreText;
    }

    public class FlowInput {
        @InvocableVariable
        public String status;

        public FlowInput(String status) {
            this.status = status;
        }
    }
}