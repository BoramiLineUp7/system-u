/*************************************************************************************
 * @Name         : SC_ServiceNowInvocable.cls
 * @Description  : Invocable class for creating ServiceNow Incidents
 * @Created By   : Denys Taldykin
 * @Created Date : September 18, 2023
 * @Modification Log:
 **************************************************************************************
 * Version     Developer      Date        Description
 *-------------------------------------------------------------------------------------
 *
 *************************************************************************************/
public with sharing class SC_ServiceNowNoteInvocable {
    /**
     * @author Denys Taldykin
     * @date September 18, 2023
     * @name createServiceNowIncident
     * @param flowOutputs List<FlowOutput>
     * @return List<FlowInput>
     * @description method to create ServiceNow Incident
     */
    @InvocableMethod(Callout=true)
    public static List<FlowInput> createServiceNowNote(List<FlowOutput> flowOutputs) {
        List<FlowInput> flowInputs = new List<FlowInput>();
        String statusMessage = SC_ServiceNowService.createServiceNowNote(flowOutputs[0].caseId, flowOutputs[0].comment, flowOutputs[0].commentType);

        if (statusMessage == 'success') {
            flowInputs.add(new FlowInput(true, null));
        } else {
            flowInputs.add(new FlowInput(false, statusMessage));
        }

        return flowInputs;
    }

    /**
     * @author Denys Taldykin
     * @date September 18, 2023
     * @name FlowInput
     * @description flow input wrapper class
     */
    public class FlowInput {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String errorMessage;

        public FlowInput(Boolean success, String errorMessage) {
            this.success = success;
            this.errorMessage = errorMessage;
        }
    }

    /**
     * @author Denys Taldykin
     * @date September 18, 2023
     * @name FlowOutput
     * @description flow output wrapper class
     */
    public class FlowOutput {
        @InvocableVariable
        public String caseId;
        @InvocableVariable
        public String comment;
        @InvocableVariable
        public String commentType;

        public FlowOutput() {
        }

        public FlowOutput(String caseId) {
            this.caseId = caseId;
        }

        public FlowOutput(String caseId, String category, String commentType) {
            this.caseId = caseId;
            this.comment = comment;
            this.commentType = commentType;
        }
    }
}