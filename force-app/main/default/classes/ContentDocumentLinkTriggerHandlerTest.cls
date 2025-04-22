@isTest
private class ContentDocumentLinkTriggerHandlerTest {
    @TestSetup
    static void setup() {
        // Criar Opportunities de teste


            Opportunity opp1 = new Opportunity(
                Name = 'Opportunity 1',
                StageName = 'Negociação',
                CloseDate = Date.today(),
                PropostaAnexada__c = false,
                TecnologiaProjeto__c = 'Java',
                TempoEstimadoProjeto__c = 10,
                DataInicio__c = Date.today().addDays(1),
                DataFim__c = Date.today().addDays(10),
                CustoEstimadoProjeto__c = 1000,
                DesenvolvedorDisponivel__c = true
            );
            Opportunity opp2 = new Opportunity(
                Name = 'Opportunity 2',
                StageName = 'Formalização',
                CloseDate = Date.today(),
                NDAAnexado__c = false,
                PropostaAnexada__c = true,
                ValorProposta__c = 5000
            );
            insert new List<Opportunity>{opp1, opp2};
        }

    @isTest
    static void testOnAfterInsertByStage() {
        // Obter Opportunities
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        
        // Criar ContentDocumentLinks de teste
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (Opportunity opp : opps) {
            ContentDocumentLink cdl = new ContentDocumentLink(
                LinkedEntityId = opp.Id,
                ContentDocumentId = '069xx0000000001AAA', // ID fictício
                ShareType = 'V'
            );
            links.add(cdl);
        }
        
        Test.startTest();
        ContentDocumentLinkTriggerHandler.onAfterInsertByStage(links);
        Test.stopTest();
        
        // Verificar se as Opportunities foram atualizadas corretamente
        Opportunity updatedOpp1 = [SELECT PropostaAnexada__c FROM Opportunity WHERE Name = 'Opportunity 1'];
        System.assertEquals(true, updatedOpp1.PropostaAnexada__c, 'PropostaAnexada__c deveria ser true para Opportunity 1');
        
        Opportunity updatedOpp2 = [SELECT NDAAnexado__c FROM Opportunity WHERE Name = 'Opportunity 2'];
        System.assertEquals(true, updatedOpp2.NDAAnexado__c, 'NDAAnexado__c deveria ser true para Opportunity 2');
    }
}