@isTest
private class BrasilApiServiceTest {
    @isTest
    static void testGetCNPJDataSuccess() {
        // Configurar mock HTTP
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"razao_social":"Empresa Teste","nome_fantasia":"Fantasia Teste"}'));
        
        Test.startTest();
        BrasilApiService.Response response = BrasilApiService.getCNPJData('12.345.678/0001-95');
        Test.stopTest();
        
        System.assertEquals('Empresa Teste', response.razaoSocial, 'A razão social deveria ser Empresa Teste');
        System.assertEquals('Fantasia Teste', response.nomeFantasia, 'O nome fantasia deveria ser Fantasia Teste');
        System.assertEquals('Válido', response.cnpjStatus, 'O status do CNPJ deveria ser Válido');
        System.assertEquals('200', response.statusCode, 'O código de status deveria ser 200');
    }

    @isTest
    static void testGetCNPJDataNotFound() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(404, ''));
        
        Test.startTest();
        BrasilApiService.Response response = BrasilApiService.getCNPJData('12.345.678/0001-95');
        Test.stopTest();
        
        System.assertEquals('Erro: CNPJ não encontrado ou inválido.', response.errorMessage, 'A mensagem de erro deveria indicar que o CNPJ não foi encontrado');
        System.assertEquals('--', response.razaoSocial, 'A razão social deveria ser --');
        System.assertEquals('--', response.nomeFantasia, 'O nome fantasia deveria ser --');
        System.assertEquals('404', response.statusCode, 'O código de status deveria ser 404');
    }

    @isTest
    static void testGetCNPJDataException() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500, null, true));
        
        Test.startTest();
        BrasilApiService.Response response = BrasilApiService.getCNPJData('12.345.678/0001-95');
        Test.stopTest();
        
        System.assert(response.errorMessage.startsWith('Erro na API:'), 'A mensagem de erro deveria indicar um erro na API');
        System.assertEquals('500', response.statusCode, 'O código de status deveria ser 500');
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        private Boolean throwException;

        public MockHttpResponseGenerator(Integer statusCode, String responseBody, Boolean throwException) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
            this.throwException = throwException;
        }

        public MockHttpResponseGenerator(Integer statusCode, String responseBody) {
            this(statusCode, responseBody, false);
        }

        public HTTPResponse respond(HTTPRequest req) {
            if (throwException) {
                throw new CalloutException('Simulated exception');
            }
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(statusCode);
            return res;
        }
    }
}