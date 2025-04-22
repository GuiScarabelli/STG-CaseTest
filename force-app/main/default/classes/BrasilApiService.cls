public with sharing class BrasilApiService {
    @AuraEnabled
    public static Response getCNPJData(String cnpj) {
        cnpj = cnpj.replaceAll('[^0-9]', '');
        Response response = new Response();

        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://brasilapi.com.br/api/cnpj/v1/' + cnpj);
            req.setMethod('GET');
            req.setHeader('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');
            req.setTimeout(120000);  // 2 minutos
            

            HttpResponse res = new Http().send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                // Trata campos nulos
                response.razaoSocial = data.containsKey('razao_social') ? (String) data.get('razao_social') : '';
                response.nomeFantasia = data.containsKey('nome_fantasia') ? (String) data.get('nome_fantasia') : 'Não Informado';
                response.cnpjStatus = 'Válido';
                response.statusCode = '200';
            } else {
                response.errorMessage = 'Erro: CNPJ não encontrado ou inválido.';
                response.razaoSocial = '--';
                response.nomeFantasia = '--';
                response.statusCode = String.valueOf(res.getStatusCode());
            }
        } catch (Exception ex) {
            response.errorMessage = 'Erro na API: ' + ex.getMessage();
            response.statusCode = '500';
        }


        return response;
    }

    public class Response {
        @AuraEnabled public String razaoSocial;
        @AuraEnabled public String nomeFantasia;
        @AuraEnabled public String statusCode;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String cnpjStatus;
    }
}