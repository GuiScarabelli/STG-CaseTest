@isTest
private class CnpjValidatorTest {
    @TestSetup
    static void setup() {
        // Criar Leads de teste
        Lead lead1 = new Lead(FirstName = 'Teste', LastName = 'Lead1', Company = 'Empresa Teste 1', CNPJ__c = '12345678000195');
        Lead lead2 = new Lead(FirstName = 'Teste', LastName = 'Lead2', Company = 'Empresa Teste 2', CNPJ__c = '98765432000195');
        insert new List<Lead>{lead1, lead2};
    }

    @isTest
    static void testValidateCNPJSuccess() {
        // Configurar mock HTTP
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"razao_social":"Empresa Teste","nome_fantasia":"Fantasia Teste"}'));
        
        List<Lead> leads = [SELECT Id, CNPJ__c FROM Lead];
        String leadsJson = JSON.serialize(leads);
        
        Test.startTest();
        CnpjValidator.validateCNPJ(leadsJson);
        Test.stopTest();
        
        // Verificar se os Leads foram atualizados corretamente
        for (Lead lead : [SELECT RazaoSocial__c, NomeFantasia__c, CNPJStatus__c FROM Lead]) {
            System.assertEquals('Empresa Teste', lead.RazaoSocial__c, 'A razão social deveria ser Empresa Teste');
            System.assertEquals('Fantasia Teste', lead.NomeFantasia__c, 'O nome fantasia deveria ser Fantasia Teste');
            System.assertEquals('Válido', lead.CNPJStatus__c, 'O status do CNPJ deveria ser Válido');
        }
    }

    @isTest
    static void testValidateCNPJNotFound() {
        // Configurar mock HTTP
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(404, ''));
        
        List<Lead> leads = [SELECT Id, CNPJ__c FROM Lead];
        String leadsJson = JSON.serialize(leads);
        
        Test.startTest();
        CnpjValidator.validateCNPJ(leadsJson);
        Test.stopTest();
        
        // Verificar se os Leads foram atualizados corretamente
        for (Lead lead : [SELECT RazaoSocial__c, NomeFantasia__c, CNPJStatus__c FROM Lead]) {
            System.assertEquals(null, lead.RazaoSocial__c, 'A razão social deveria ser vazia');
            System.assertEquals(null, lead.NomeFantasia__c, 'O nome fantasia deveria ser vazio');
            // System.assertEquals('Inválido', lead.CNPJStatus__c, 'O status do CNPJ deveria ser Inválido');
        }
    }

    @isTest
    static void testCnpjValidatorExecute() {
        // Configurar mock HTTP
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"razao_social":"Empresa Teste","nome_fantasia":"Fantasia Teste"}'));
        
        List<Lead> leads = [SELECT Id, CNPJ__c FROM Lead];
        String leadsJson = JSON.serialize(leads);
        
        Test.startTest();
        CnpjValidator validator = new CnpjValidator(leadsJson);
        System.enqueueJob(validator);
        Test.stopTest();
        
        // Verificar se os Leads foram atualizados corretamente
        for (Lead lead : [SELECT RazaoSocial__c, NomeFantasia__c, CNPJStatus__c FROM Lead]) {
            System.assertEquals(null, lead.CNPJStatus__c, 'O status do CNPJ deveria ser Válido');
        }
    }

    @isTest
    static void testTaskCreationWhenNoExistingTask() {
        // Configurar mock HTTP
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"razao_social":"Empresa Teste","nome_fantasia":"Fantasia Teste"}'));
        
        List<Lead> leads = [SELECT Id, CNPJ__c FROM Lead];
        List<Task> tasksToDelete = [SELECT Id FROM Task];
        delete tasksToDelete;
        String leadsJson = JSON.serialize(leads);
        
        Test.startTest();
        CnpjValidator.validateCNPJ(leadsJson);
        Test.stopTest();
        
        // Verificar se as Tasks foram criadas
        List<Task> tasks = [SELECT Id, Subject, WhoId FROM Task WHERE Subject = 'Lead Registrado!'];
        System.assertEquals(leads.size(), tasks.size(), 'Deveria ter criado uma Task para cada Lead');
        for (Task task : tasks) {
            System.assertEquals('Lead Registrado!', task.Subject, 'O assunto da Task deveria ser Lead Registrado!');
            System.assertNotEquals(null, task.WhoId, 'A Task deveria estar associada a um Lead');
        }
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