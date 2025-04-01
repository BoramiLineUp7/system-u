@IsTest
private class SC_GeminiScoringInvocableTest {
    private static final String SCORING_VALUE = '1';
    private static final String SCORING_RESPONSE = '{"scoring":{"document_sentiment":"Neutre","score":"' + SCORING_VALUE + '","text_language":"Anglais"}}';
    private static final String SCORING_PROMPT = 'Test prompt';
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
    private static void testGetGeminiScoring() {
        List<SC_GeminiScoringInvocable.FlowInput> flowInputs;
        List<SC_GeminiScoringInvocable.FlowOutput> flowOutputs = new List<SC_GeminiScoringInvocable.FlowOutput>();

        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        flowOutputs.add(new SC_GeminiScoringInvocable.FlowOutput(SCORING_PROMPT));

        Test.startTest();

        flowInputs = SC_GeminiScoringInvocable.getGeminiScoring(flowOutputs);

        Test.stopTest();

        Assert.isTrue(!flowInputs.isEmpty(), 'Scoring response should not be empty!');

        for (SC_GeminiScoringInvocable.FlowInput i : flowInputs) {
            Assert.areEqual(1, i.geminiScoring, 'Scoring should be equal to Gemini response scoring!');
        }
    }

    public class MockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();

            if (req.getEndpoint().contains('Gemini_Auth')) {
                res.setBody(AUTH_RESPONSE_SUCCESS);
            } else {
                res.setBody(SCORING_RESPONSE);
            }

            res.setStatusCode(200);

            return res;
        }
    }
}