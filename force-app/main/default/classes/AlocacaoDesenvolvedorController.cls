public with sharing class AlocacaoDesenvolvedorController {

    @AuraEnabled(cacheable=true)
    public static List<Desenvolvedor__c> getDevelopers(Id opportunityId) {
        Opportunity opp = [SELECT TecnologiaProjeto__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        return [SELECT Id, Name, Especialidade__c FROM Desenvolvedor__c WHERE Especialidade__c = :opp.TecnologiaProjeto__c];
    }

    @AuraEnabled
    public static void saveAllocations(Id opportunityId, List<Id> developerIds) {
        Set<Id> existingDevs = new Set<Id>();
        for (AlocacaoDesenvolvedor__c alloc : [SELECT Desenvolvedor__c FROM AlocacaoDesenvolvedor__c WHERE OportunidadeAlocacao__c = :opportunityId]) {
            existingDevs.add(alloc.Desenvolvedor__c);
        }
    
        Opportunity opp = [SELECT Name, DesenvolvedorDisponivel__c FROM Opportunity WHERE Id = :opportunityId];
        Map<Id, Desenvolvedor__c> devMap = new Map<Id, Desenvolvedor__c>([SELECT Id, Name FROM Desenvolvedor__c WHERE Id IN :developerIds]);
    
        List<AlocacaoDesenvolvedor__c> allocations = new List<AlocacaoDesenvolvedor__c>();
        List<String> duplicateNames = new List<String>();
    
        for (Id devId : new Set<Id>(developerIds)) { // Evita duplicatas na entrada
            if (!devMap.containsKey(devId)) continue; // Ignora IDs inválidos
    
            if (existingDevs.contains(devId)) {
                duplicateNames.add(devMap.get(devId).Name);
            } else {
                String nomeAlocacao = devMap.get(devId).Name + ' - ' + opp.Name;
                allocations.add(new AlocacaoDesenvolvedor__c(
                    OportunidadeAlocacao__c = opportunityId,
                    Desenvolvedor__c = devId,
                    Name = nomeAlocacao.left(80) // Garante limite de 80 caracteres
                ));
            }
        }
    
        if (!allocations.isEmpty()) {
            insert allocations;
        }
    
        Integer allocationCount = existingDevs.size() + allocations.size();
        opp.DesenvolvedorDisponivel__c = (allocationCount > 0);
        update opp;
    
        if (!duplicateNames.isEmpty()) {
            throw new AuraHandledException('Desenvolvedores já alocados: ' + String.join(duplicateNames, ', '));
        }
    }
}