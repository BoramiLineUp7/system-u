trigger CaseTrigger on Case (before insert, before update, before delete, after insert, after update, after delete,  after undelete) {
    if (Trigger.isBefore && Trigger.isInsert) {
        CaseTriggerHandler.beforeInsert(Trigger.new);
    }
}