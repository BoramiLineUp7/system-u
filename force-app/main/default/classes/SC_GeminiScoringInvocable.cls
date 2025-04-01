public with sharing class SC_GeminiScoringInvocable {
    @InvocableMethod
    public static List<FlowInput> getGeminiScoring(List<FlowOutput> flowParameters) {
        SC_GeminiIntegrationService.GeminiScoring scoring;

        for (FlowOutput p : flowParameters) {
            System.debug(p.prompt);
            scoring = SC_GeminiIntegrationService.getGeminiEmailScoring(p.prompt);
        }

        return new List<SC_GeminiScoringInvocable.FlowInput>{
                new FlowInput(scoring.geminiScoring, scoring.geminiScoringText)
        };
    }

    public class FlowOutput {
        @InvocableVariable
        public String prompt;

        public FlowOutput(String prompt) {
            this.prompt = prompt;
        }

        public FlowOutput() {
        }
    }

    public class FlowInput {
        @InvocableVariable
        public Double geminiScoring;
        @InvocableVariable
        public String geminiScoringText;

        public FlowInput(Double geminiScoring, String geminiScoringText) {
            this.geminiScoring = geminiScoring;
            this.geminiScoringText = geminiScoringText;
        }

        public FlowInput() {
        }
    }
}