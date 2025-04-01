public with sharing class SC_GeminiResponseInvocable {
    @InvocableMethod
    public static List<FlowInput> getGeminiResponse(List<FlowOutput> flowParameters) {
        List<FlowInput> flowInputs = new List<FlowInput>();

        for (FlowOutput p : flowParameters) {
            String geminiResponse = SC_GeminiIntegrationService.getGeminiCaseEmailResponse(p.prompt, p.userHint);
            flowInputs.add(new FlowInput(geminiResponse));
        }

        return flowInputs;
    }

    public class FlowOutput {
        @InvocableVariable
        public String prompt;
        @InvocableVariable
        public String userHint;
    }

    public class FlowInput {
        @InvocableVariable
        public String geminiResponse;

        public FlowInput(String geminiResponse) {
            this.geminiResponse = geminiResponse;
        }
    }
}