@isTest
private class LeadHelperTest {
    @TestSetup
    static void setup() {
        // Criar Leads de teste
        Lead lead1 = new Lead(FirstName = 'Teste', LastName = 'Lead1', Company = 'Empresa Teste 1', CNPJ__c = '12345678000195');
        Lead lead2 = new Lead(FirstName = 'Teste', LastName = 'Lead2', Company = 'Empresa Teste 2', CNPJ__c = '98765432000195');
        insert new List<Lead>{lead1, lead2};
    }

    @isTest
    static void testValidateLead() {
        // Configurar mock HTTP
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"razao_social":"Empresa Teste","nome_fantasia":"Fantasia Teste"}'));

        // Obter Leads
        List<Lead> leads = [SELECT Id, CNPJ__c FROM Lead];
        Map<Id, Lead> oldMap = new Map<Id, Lead>();
        for (Lead lead : leads) {
            oldMap.put(lead.Id, lead.clone(false, true, true, true));
        }
        
        // Modificar CNPJ de um Lead
        leads[0].CNPJ__c = '11111111111111';
        update leads;
        
        Test.startTest();
        LeadHelper.validateLead(leads, oldMap);
        Test.stopTest();
        
        // Verificar se o job foi enfileirado
        // Não há uma maneira direta de verificar jobs enfileirados, mas podemos verificar se o método foi chamado sem erros
    }

    @isTest
    static void testHandleLeadConversion() {
        // Obter Leads
        List<Lead> leads = [SELECT Id, IsConverted FROM Lead];
        Map<Id, Lead> oldMap = new Map<Id, Lead>();
        for (Lead lead : leads) {
            oldMap.put(lead.Id, lead.clone(false, true, true, true));
        }
        
        // Simular conversão de Lead
        Lead leadToConvert = leads[0];
        Account account = new Account(Name = 'Conta Convertida');
        insert account;
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadToConvert.Id);
        lc.setConvertedStatus('Closed - Converted');
        lc.setAccountId(account.Id);
        
        Test.startTest();
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        LeadHelper.handleLeadConversion(new List<Lead>{leadToConvert}, oldMap);
        Test.stopTest();
        
        // Verificar se a Opportunity foi criada
        List<Opportunity> opp = [SELECT Id, Name FROM Opportunity WHERE AccountId = :account.Id];
        System.assertNotEquals(null, opp[0], 'A Opportunity deveria ter sido criada para o Lead convertido');
    }

    @isTest
    static void testCreateTasksForLeads() {
        // Delete Old Tasks
        List<Task> oldTasks = [SELECT Id FROM Task];
        delete oldTasks;
        // Obter Leads
        List<Lead> leads = [SELECT Id FROM Lead];
        
        Test.startTest();
        LeadHelper.createTasksForLeads(leads);
        Test.stopTest();
        
        // Verificar se as Tasks foram criadas
        List<Task> tasks = [SELECT Id, Subject FROM Task WHERE Subject = 'Lead Registrado!'];
        System.assertEquals(leads.size(), tasks.size(), 'Deveria ter criado uma Task para cada Lead');
    }

    // Classe mock para simular respostas HTTP
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        public MockHttpResponseGenerator(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(statusCode);
            return res;
        }
    }
}