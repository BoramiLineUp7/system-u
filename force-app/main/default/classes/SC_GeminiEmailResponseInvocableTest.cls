@IsTest
private class SC_GeminiEmailResponseInvocableTest {
    private static final String GEMINI_RESPONSE = 'Test Response';
    private static final String PROMPT = 'Test prompt';
    private static final String USER_HINT = 'Test hint';
    private static final String EMAIL_ADDRESS = 'test1@test.com';
    private static final String FIRST_NAME = 'FirstName1';
    private static final String LAST_NAME = 'LastName1';
    private static final Decimal GEMINI_SCORE = 1;
    private static final String GEMINI_SCORE_TEXT = 'Text Score';

    @IsTest
    static void createGeminiEmailResponseTest() {
        List<SC_GeminiEmailResponseInvocable.FlowInput> flowInputs;
        List<SC_GeminiEmailResponseInvocable.FlowOutput> flowOutputs = new List<SC_GeminiEmailResponseInvocable.FlowOutput>();
        SC_GeminiEmailResponseInvocable.FlowOutput flowOutput = new SC_GeminiEmailResponseInvocable.FlowOutput();

        Account acc = new Account(
                FirstName = FIRST_NAME,
                LastName = LAST_NAME,
                Email_ID__c = EMAIL_ADDRESS,
                PersonEmail = EMAIL_ADDRESS,
                RecordTypeId = SC_RXPService.PRESON_ACCOUNT_RT_ID
        );
        Case c;

        insert acc;

        c = new Case (
                AccountId = acc.Id,
                Status = 'Nouveau',
                Origin = 'Web',
                Priority = 'Moyen',
                Description = 'My test case',
                SuppliedEmail = EMAIL_ADDRESS,
                Subject = 'Problème sur le site',
                Type = SC_RXPService.COMPTE_COURSES_U_CASE_TYPE
        );

        insert c;

        flowOutput.caseId = c.Id;
        flowOutput.prompt = PROMPT;
        flowOutput.emailAddress = 'contact@magasins-u.com';
        flowOutput.geminiResponse = GEMINI_RESPONSE;
        flowOutput.geminiScore = GEMINI_SCORE;
        flowOutput.geminiScoreText = GEMINI_SCORE_TEXT;
        flowOutput.userHint = USER_HINT;

        flowOutputs.add(flowOutput);

        Test.startTest();

        flowInputs = SC_GeminiEmailResponseInvocable.createGeminiEmailResponse(flowOutputs);

        Test.stopTest();
    }

}