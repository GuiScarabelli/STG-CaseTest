
public with sharing class LeadHelper {
    
    public static void validateLead(List<Lead> leads, Map<Id, Lead> oldMap) {
        System.debug('LeadHelper.validateLead');
        List<Lead> leadsToValidate = new List<Lead>();
        for (Lead lead : leads) {
            Lead oldLead = oldMap == null || oldMap.get(lead.Id) == null ? new Lead() : oldMap.get(lead.Id);  
            if (lead.CNPJ__c != oldLead.CNPJ__c) {
                leadsToValidate.add(lead);
            }
        }
        if (!leadsToValidate.isEmpty()) {
            System.debug('indo pro cnpj validator');
            String serializedList = JSON.serialize(leadsToValidate);
            CnpjValidator updateJob = new CnpjValidator(serializedList);
            ID jobID = System.enqueueJob(updateJob);
        }
    }
    

    public static void handleLeadConversion(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        
        for (Lead lead : newLeads) {
            if (lead.IsConverted && !oldMap.get(lead.Id).IsConverted) {
                // Criar Opportunity para a Conta convertida
                Opportunity opp = new Opportunity(
                    Name = (String.isNotBlank(lead.NomeFantasia__c) ? lead.NomeFantasia__c : lead.RazaoSocial__c) + ' - Oportunidade Inicial',
                    AccountId = lead.ConvertedAccountId,
                    StageName = 'Qualificação',
                    CloseDate = Date.today().addDays(30)
                );
                opportunitiesToInsert.add(opp);
            }
        }
        
        if (!opportunitiesToInsert.isEmpty()) {
            insert opportunitiesToInsert;
        }
    }

    public static void createTasksForLeads(List<Lead> leads) {
        System.debug('LeadHelper.createTasksForLeads');
        List<Task> tasksToInsert = new List<Task>();
        
        for (Lead lead : leads) {
            Task task = new Task();
            task.Subject = 'Lead Registrado!';
            task.Description = 'Novo Lead Cadastrado! Realize o contato com o Lead. ';
            task.Status = 'Not Started';
            task.Priority = 'Normal';
            task.WhoId = lead.Id; // Associa a Task ao Lead
            task.OwnerId = UserInfo.getUserId(); // Define o usuário atual como dono
            task.ActivityDate = Date.today().addDays(7); // Data de vencimento em 7 dias
            tasksToInsert.add(task);
        }
        
        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
}