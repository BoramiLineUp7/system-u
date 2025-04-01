/**
 * Created by Denys on 12/17/2024.
 */

public with sharing class SC_GeminiIntegrationService {
    @TestVisible
    public static SC_GeminiConnectionSettings__c SETTINGS = SC_GeminiConnectionSettings__c.getOrgDefaults();
    @TestVisible
    private static final String RESPONSE_URL = '/response';
    @TestVisible
    private static final String SCORING_URL = '/scoring';
    @TestVisible
    private static final String RESPONSE_ATTRIBUTE_NAME = 'response';
   // @TestVisible
   // private static final String DOCUMENT_SENTIMENT_PARAMETER = '';
    @TestVisible
    private static final String SCORING_PARAMETER = 'scoring';
    @TestVisible
    private static final String SCORE_PARAMETER = 'score';
    @TestVisible
    private static final String SCORE_TEXT_PARAMETER = 'document_sentiment';
    //@TestVisible
    //private static final String TEXT_LANGUAGE_PARAMETER = '';
    @TestVisible
    private static final String PROMPT_PARAMETER = 'prompt';
    @TestVisible
    private static final String USER_HINT_PARAMETER = 'user_hint';
   // @TestVisible
    //private Boolean authRetry = false;
    @TestVisible
    private static Boolean updateSettings = false;

    public static String getGeminiCaseEmailResponse(String prompt, String userHint) {
        String geminiResponse;

        authenticateGemini();

        geminiResponse = parseGeminiResponse(getGeminiResponse(prompt, userHint));

        if (updateSettings) {
            if (SETTINGS.Id == null) {
                insert SETTINGS;
            } else {
                update SETTINGS;
            }
        }

        return geminiResponse;
    }

    public static GeminiScoring getGeminiEmailScoring(String prompt) {
        authenticateGemini();

        GeminiScoring geminiScore = parseGeminiScoring(getGeminiScoring(prompt));

        if (updateSettings) {
            if (SETTINGS.Id == null) {
                insert SETTINGS;
            } else {
                update SETTINGS;
            }
        }

        System.debug(geminiScore);
        return geminiScore;
    }

    public static HttpResponse getGeminiResponse(String prompt, String userHint) {
        String endpoint = 'callout:Gemini_Credentials' + RESPONSE_URL;
        Map<String, String> headers = new Map<String, String>();
        String requestBody = getGeminiResponseRequestBody(prompt, userHint);
        String accessToken = getToken();
        Integer timeout = SETTINGS.Request_Timeout__c != null ? (Integer) SETTINGS.Request_Timeout__c : 20000;

        headers.put(SC_CalloutService.AUTHORIZATION, 'Bearer ' + accessToken);
        headers.put(SC_CalloutService.CONTENT_TYPE, SC_CalloutService.CONTENT_TYPE_JSON);

        return SC_CalloutService.executeRequest(SC_CalloutService.POST_METHOD, endpoint, requestBody, headers, timeout);
    }

    private static String getGeminiResponseRequestBody(String prompt, String userHint) {
        return JSON.serialize(
                new Map<String, String>{
                        PROMPT_PARAMETER => prompt,
                        USER_HINT_PARAMETER => userHint
                }
        );
    }

    private static String parseGeminiResponse(HttpResponse response) {
        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

        return String.valueOf(resMap.get(RESPONSE_ATTRIBUTE_NAME));
    }


    public static HttpResponse getGeminiScoring(String prompt) {
        String endpoint = 'callout:Gemini_Credentials' + SCORING_URL;
        Map<String, String> headers = new Map<String, String>();
        String requestBody = getGeminiScoringRequestBody(prompt);
        String accessToken = getToken();
        Integer timeout = SETTINGS.Request_Timeout__c != null ? (Integer) SETTINGS.Request_Timeout__c : 20000;

        headers.put(SC_CalloutService.AUTHORIZATION, 'Bearer ' + accessToken);
        headers.put(SC_CalloutService.CONTENT_TYPE, SC_CalloutService.CONTENT_TYPE_JSON);

        return SC_CalloutService.executeRequest(SC_CalloutService.POST_METHOD, endpoint, requestBody, headers, timeout);
    }

    private static GeminiScoring parseGeminiScoring(HttpResponse response) {
        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        Map<String, Object> scoringMap = (Map<String, Object>)resMap.get(SCORING_PARAMETER);

        return new GeminiScoring(String.valueOf(scoringMap.get(SCORE_TEXT_PARAMETER)), Double.valueOf(scoringMap.get(SCORE_PARAMETER)));
    }

    private static String getGeminiScoringRequestBody(String prompt) {
        prompt = prompt.replace('{{{Recipient.Name}}}', '');
        return JSON.serialize(
                new Map<String, String>{
                        PROMPT_PARAMETER => prompt
                }
        );
    }

    public static void updateGeminiResponse(EmailMessage e) {
        List<SC_Gemini_Email_Response__c> responses = [SELECT Id FROM SC_Gemini_Email_Response__c WHERE Email_Message_Id__c = :e.Id LIMIT 1];

        if (!responses.isEmpty()) {
            for (SC_Gemini_Email_Response__c r : responses) {
                r.Support_Agent_Response__c = getAgentResponse(e);

                update r;
            }
        }
    }

    public static void authenticateGemini() {
        if (SETTINGS.Id == null) {
            SETTINGS = new SC_GeminiConnectionSettings__c();
            SETTINGS.SetupOwnerId = UserInfo.getOrganizationId();
            SETTINGS.TokenExpirationDate__c = Datetime.now().addSeconds(-10);
            SETTINGS.Token__c = '';
            SETTINGS.Token_1__c = '';
            SETTINGS.Token_2__c = '';
            SETTINGS.Token_3__c = '';
            SETTINGS.Token_4__c = '';
            SETTINGS.Token_5__c = '';
            SETTINGS.Token_6__c = '';
            SETTINGS.Token_7__c = '';

            SETTINGS.Request_Timeout__c = 20000;
        }

        Integer timeout = SETTINGS.Request_Timeout__c != null ? (Integer) SETTINGS.Request_Timeout__c : 2000;

        if (!tokenIsValid()) {
            String endpoint = 'callout:Gemini_Auth';
            Map<String, String> headers = new Map<String, String>();
            HttpResponse res;
            Map<String, Object> jsonMap;
            String token;
            Datetime expiryDate;

            headers.put(SC_CalloutService.CONTENT_TYPE, SC_CalloutService.CONTENT_TYPE_URL);
            //headers.put('scope', 'COCIAGU001.read');
            res = SC_CalloutService.executeRequest(SC_CalloutService.GET_METHOD, endpoint, SC_CalloutService.GRANT_TYPE_CLIENT_CREDENTIALS, headers, timeout);
            jsonMap = (Map<String, Object>) System.JSON.deserializeUntyped(res.getBody());

            if (res.getStatusCode() == 200) {
                if (jsonMap.containsKey('access_token') && jsonMap.containsKey('expires_in')) {
                    token = (String) jsonMap.get ('access_token');
                    expiryDate = Datetime.now().addSeconds(Integer.valueOf(jsonMap.get ('expires_in')));

                    SETTINGS.TokenExpirationDate__c = expiryDate;
                    setToken(token);

                    updateSettings = true;
                }
            }
        }
    }

    public static String getToken() {
        String token = '';

        if (String.isNotBlank(SETTINGS.Token__c)) {
            token = token + SETTINGS.Token__c;
        }
        if (String.isNotBlank(SETTINGS.Token_1__c)) {
            token = token + SETTINGS.Token_1__c;
        }
        if (String.isNotBlank(SETTINGS.Token_2__c)) {
            token = token + SETTINGS.Token_2__c;
        }
        if (String.isNotBlank(SETTINGS.Token_3__c)) {
            token = token + SETTINGS.Token_3__c;
        }
        if (String.isNotBlank(SETTINGS.Token_4__c)) {
            token = token + SETTINGS.Token_4__c;
        }
        if (String.isNotBlank(SETTINGS.Token_5__c)) {
            token = token + SETTINGS.Token_5__c;
        }
        if (String.isNotBlank(SETTINGS.Token_6__c)) {
            token = token + SETTINGS.Token_6__c;
        }
        if (String.isNotBlank(SETTINGS.Token_7__c)) {
            token = token + SETTINGS.Token_7__c;
        }

        return token;
    }

    public static void setToken(String token) {
        Integer fieldSize = 250;
        Integer tokenLength = token.length();
        Decimal numberOfIterations = tokenLength / fieldSize;
        Integer numberOfIterationsInt = numberOfIterations.intValue();
        numberOfIterationsInt = numberOfIterations - Decimal.valueOf(numberOfIterationsInt) > 0 ? numberOfIterationsInt++ : numberOfIterationsInt;

        SETTINGS.Token__c = '';
        SETTINGS.Token_1__c = '';
        SETTINGS.Token_2__c = '';
        SETTINGS.Token_3__c = '';
        SETTINGS.Token_4__c = '';
        SETTINGS.Token_5__c = '';
        SETTINGS.Token_6__c = '';
        SETTINGS.Token_7__c = '';

        for (Integer index = 0; index <= numberOfIterationsInt; index++) {
            switch on index {
                when 0 {
                    SETTINGS.Token__c = token.mid(0, fieldSize);
                }
                when 1 {
                    SETTINGS.Token_1__c = token.mid(index * fieldSize, fieldSize);
                }
                when 2 {
                    SETTINGS.Token_2__c = token.mid(index * fieldSize, fieldSize);
                }
                when 3 {
                    SETTINGS.Token_3__c = token.mid(index * fieldSize, fieldSize);
                }
                when 4 {
                    SETTINGS.Token_4__c = token.mid(index * fieldSize, fieldSize);
                }
                when 5 {
                    SETTINGS.Token_5__c = token.mid(index * fieldSize, fieldSize);
                }
                when 6 {
                    SETTINGS.Token_6__c = token.mid(index * fieldSize, fieldSize);
                }
                when 7 {
                    SETTINGS.Token_7__c = token.mid(index * fieldSize, fieldSize);
                }
            }
        }
    }

    private static Boolean tokenIsValid() {
        if (SETTINGS.TokenExpirationDate__c == null || SETTINGS.Token__c == null) {
            return false;
        } else {
            if (SETTINGS.TokenExpirationDate__c < Datetime.now()) {
                return false;
            } else {
                return true;
            }
        }
    }

    private static String getAgentResponse(EmailMessage e) {
        return e.TextBody;
    }

    public class GeminiScoring{
        public String geminiScoringText;
        public Double geminiScoring;

        public GeminiScoring(String geminiScoringText, Double geminiScoring) {
            this.geminiScoringText = geminiScoringText;
            this.geminiScoring = geminiScoring;
        }
    }
}