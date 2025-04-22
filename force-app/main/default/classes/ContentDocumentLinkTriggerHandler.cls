public with sharing class ContentDocumentLinkTriggerHandler {
    public static void onAfterInsertByStage(List<ContentDocumentLink> newLinks) {
        // 1. Coletar IDs de Opportunity
        Set<Id> oppIds = new Set<Id>();
        for (ContentDocumentLink cdl : newLinks) {
            if (cdl.LinkedEntityId.getSObjectType() == Opportunity.sObjectType) {
                oppIds.add(cdl.LinkedEntityId);
            }
        }
        if (oppIds.isEmpty()) return;

        // 2. Buscar Opportunities com StageName e Checkboxes
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [SELECT Id, StageName, NDAAnexado__c, PropostaAnexada__c
             FROM Opportunity
             WHERE Id IN :oppIds]
        );

        // 3. Atualizar de acordo com o estágio
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (ContentDocumentLink cdl : newLinks) {
            Opportunity opp = oppMap.get(cdl.LinkedEntityId);
            if (opp == null) continue;

            Boolean changed = false;
            if (opp.StageName == 'Negociação' && !opp.PropostaAnexada__c) {
                opp.PropostaAnexada__c = true;
                changed = true;
            } else if (opp.StageName == 'Formalização' && !opp.NDAAnexado__c) {
                opp.NDAAnexado__c = true;
                changed = true;
            }
            if (changed) {
                oppsToUpdate.add(opp);
            }
        }

        // 4. DML em lote
        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
    }
}