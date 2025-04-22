@isTest
public class AlocacaoDesenvolvedorControllerTest {

    @testSetup
    static void setup() {
        // Criar uma oportunidade com tecnologia de projeto
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Qualificação',
            CloseDate = Date.today(),
            TecnologiaProjeto__c = 'Java'
        );
        insert opp;
        
        // Criar desenvolvedores com especialidades
        Desenvolvedor__c dev1 = new Desenvolvedor__c(Name = 'Dev1', Especialidade__c = 'Java');
        Desenvolvedor__c dev2 = new Desenvolvedor__c(Name = 'Dev2', Especialidade__c = 'Java');
        Desenvolvedor__c dev3 = new Desenvolvedor__c(Name = 'Dev3', Especialidade__c = 'Salesforce');
        Desenvolvedor__c dev4 = new Desenvolvedor__c(Name = 'Dev4', Especialidade__c = 'Java');
        insert new List<Desenvolvedor__c>{dev1, dev2, dev3, dev4};

        AlocacaoDesenvolvedor__c alloc1 = new AlocacaoDesenvolvedor__c(
            OportunidadeAlocacao__c = opp.Id,
            Desenvolvedor__c = dev4.Id 
        );
        insert alloc1;

    }
    
    @isTest
    static void testGetDevelopers() {
        Opportunity opp = [SELECT Id, TecnologiaProjeto__c FROM Opportunity LIMIT 1];
        List<Desenvolvedor__c> devs = AlocacaoDesenvolvedorController.getDevelopers(opp.Id);
        
        System.assertEquals(3, devs.size(), 'Deveria retornar 2 desenvolvedores com especialidade Java');
        for (Desenvolvedor__c dev : devs) {
            System.assertEquals('Java', dev.Especialidade__c, 'Especialidade deve ser Java');
        }
    }
    
    @isTest
    static void testSaveAllocationsNewDevelopers() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Desenvolvedor__c> devs = [SELECT Id FROM Desenvolvedor__c WHERE Especialidade__c = 'Java'];
        List<Id> devIds = new List<Id>{devs[0].Id, devs[1].Id};
        
        Test.startTest();
        AlocacaoDesenvolvedorController.saveAllocations(opp.Id, devIds);
        Test.stopTest();
        
        List<AlocacaoDesenvolvedor__c> allocations = [SELECT Id FROM AlocacaoDesenvolvedor__c WHERE OportunidadeAlocacao__c = :opp.Id];
        System.assertEquals(3, allocations.size(), 'Deveria ter 3 alocações');
        
        Opportunity updatedOpp = [SELECT DesenvolvedorDisponivel__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(true, updatedOpp.DesenvolvedorDisponivel__c, 'DesenvolvedorDisponivel__c deve ser true');
    }

    
    @isTest
    static void testSaveAllocationsEmptyList() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Id> devIds = new List<Id>();
        
        Test.startTest();
        AlocacaoDesenvolvedorController.saveAllocations(opp.Id, devIds);
        Test.stopTest();
        
        List<AlocacaoDesenvolvedor__c> allocations = [SELECT Id FROM AlocacaoDesenvolvedor__c WHERE OportunidadeAlocacao__c = :opp.Id];
        System.assertEquals(1, allocations.size(), 'Deve ter uma externa');
        
        Opportunity updatedOpp = [SELECT DesenvolvedorDisponivel__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(true, updatedOpp.DesenvolvedorDisponivel__c, 'DesenvolvedorDisponivel__c deve ser false');
    }
    
    @isTest
    static void testSaveAllocationsUpdateField() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Desenvolvedor__c> devs = [SELECT Id FROM Desenvolvedor__c WHERE Especialidade__c = 'Java'];
        List<Id> devIds = new List<Id>{devs[0].Id};
        
        // Alocar um desenvolvedor
        AlocacaoDesenvolvedorController.saveAllocations(opp.Id, devIds);
        
        Opportunity updatedOpp = [SELECT DesenvolvedorDisponivel__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(true, updatedOpp.DesenvolvedorDisponivel__c, 'DesenvolvedorDisponivel__c deve ser true');
        
        // Remover alocações e chamar novamente com lista vazia
        delete [SELECT Id FROM AlocacaoDesenvolvedor__c WHERE OportunidadeAlocacao__c = :opp.Id];
        AlocacaoDesenvolvedorController.saveAllocations(opp.Id, new List<Id>());
        
        updatedOpp = [SELECT DesenvolvedorDisponivel__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(false, updatedOpp.DesenvolvedorDisponivel__c, 'DesenvolvedorDisponivel__c deve ser false');
    }
}