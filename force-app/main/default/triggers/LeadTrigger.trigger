trigger LeadTrigger on Lead (before insert, before update, before delete, after insert, after update, after delete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            LeadHelper.createTasksForLeads(Trigger.new);
        }

        if (Trigger.isUpdate) {
            System.debug('Lead Trigger After Update');
            LeadHelper.validateLead(Trigger.new, Trigger.oldMap);
            LeadHelper.handleLeadConversion(Trigger.new, Trigger.oldMap);
        }
    }
}