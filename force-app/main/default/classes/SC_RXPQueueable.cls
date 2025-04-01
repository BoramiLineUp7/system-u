/*************************************************************************************
 * @Name         : SC_RXPQueueable.cls
 * @Description  : Queueable class for Case Trigger
 * @Created By   : Denys Taldykin
 * @Created Date : January 5, 2023
 * @Modification Log:
 **************************************************************************************
 * Version     Developer      Date        Description
 *-------------------------------------------------------------------------------------
 *************************************************************************************/
public with sharing class SC_RXPQueueable implements Queueable, Database.AllowsCallouts {
    private final Map<Id, String> casesToProcess;

    /**
     * @author Denys Taldykin
     * @date January 5, 2023
     * @name SC_RXPQueueable
     * @description Constructor
     * @param casesToProcess Map<Id, String>
     */
    public SC_RXPQueueable(Map<Id, String> casesToProcess) {
        this.casesToProcess = casesToProcess;

    }

    /**
     * @author Denys Taldykin
     * @date January 5, 2023
     * @name execute
     * @description Execute method
     * @param param QueueableContext
     */
    public void execute(QueueableContext param) {
        SC_RXPService service = new SC_RXPService();
        service.syncRXPCustomerData(this.casesToProcess);
    }
}