@IsTest
private class SC_GeminiResponseInvocableTest {
    private static final String GEMINI_RESPONSE = 'Test Response';
    private static final String RESPONSE_VALUE = '{"response":"' + GEMINI_RESPONSE + '"}';
    private static final String PROMPT = 'Test prompt';
    private static final String USER_HINT = 'Test hint';
    private static final String ACCESS_TOKEN = '12345678910123123123123123143534645687trhfq989498uwiodfnxjovnXUVBXIOCJVNxi' +
            '12345678910123123123123123143534645687trhfq989498uwiodfnxjovnXUVBXIOCJVNxi' +
            '12345678910123123123123123143534645687trhfq989498uwiodfnxjovnXUVBXIOCJVNxi' +
            '12345678910123123123123123143534645687trhfq989498uwiodfnxjovnXUVBXIOCJVNxi' +
            '12345678910123123123123123143534645687trhfq989498uwiodfnxjovnXUVBXIOCJVNxi' +
            '12345678910123123123123123143534645687trhfq989498uwiodfnxjovnXUVBXIOCJVNxi' +
            '12345678910123123123123123143534645687trhfq989498uwiodfnxjovnXUVBXIOCJVNxi' +
            '12345678910123123123123123143534645687trhfq989498uwiodfnxjovnXUVBXIOCJVNxi' +
            '12345678910123123123123123143534645687trhfq989498uwiodfnxjovnXUVBXIOCJVNxi' +
            '12345678910123123123123123143534645687trhfq989498uwiodfnxjovnXUVBXIOCJVNxi' +
            '12345678910123123123123123143534645687trhfq989498uwiodfnxjovnXUVBXIOCJVNxi' +
            '12345678910123123123123123143534645687trhfq989498uwiodfnxjovnXUVBXIOCJVNxi' +
            '12345678910123123123123123143534645687trhfq989498uwiodfnxjovnXUVBXIOCJVNxi' +
            '12345678910123123123123123143534645687trhfq989498uwiodfnxjovnXUVBXIOCJVNxi' +
            '12345678910123123123123123143534645687trhfq989498uwiodfnxjovnXUVBXIOCJVNxi';
    private static final String AUTH_RESPONSE_SUCCESS = '{"access_token":"' + ACCESS_TOKEN + '","scope":"default","token_type":"Bearer","expires_in":3482}';

    @IsTest
    private static void getGeminiResponseTest() {
        List<SC_GeminiResponseInvocable.FlowInput> flowInputs;
        List<SC_GeminiResponseInvocable.FlowOutput> flowOutputs;
        SC_GeminiResponseInvocable.FlowOutput flowOutput = new SC_GeminiResponseInvocable.FlowOutput();

        flowOutput.prompt = PROMPT;
        flowOutput.userHint = USER_HINT;

        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        flowOutputs = new List<SC_GeminiResponseInvocable.FlowOutput>{
                flowOutput
        };

        Test.startTest();

        flowInputs = SC_GeminiResponseInvocable.getGeminiResponse(flowOutputs);

        Test.stopTest();

        Assert.isTrue(!flowInputs.isEmpty(), 'Response should not be empty!');

        for (SC_GeminiResponseInvocable.FlowInput i : flowInputs) {
            Assert.areEqual(GEMINI_RESPONSE, i.geminiResponse, 'Response should be equal to Gemini response!');
        }
    }

    public class MockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();

            if (req.getEndpoint().contains('Gemini_Auth')) {
                res.setBody(AUTH_RESPONSE_SUCCESS);
            } else {
                res.setBody(RESPONSE_VALUE);
            }

            res.setStatusCode(200);

            return res;
        }
    }
}