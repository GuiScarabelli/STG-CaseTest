public class CnpjValidator implements Queueable, Database.AllowsCallouts {
    public final String leads;
    
    public CnpjValidator(String leads) {
        this.leads = leads;
    }
    
    public void execute(QueueableContext context) {
        validateCNPJ(leads);
    }

    @future(callout=true)
    private static void validateCNPJ(String leads) {
        System.debug('CnpjValidator.validateCNPJ');
        List<Lead> leadList = (List<Lead>) JSON.deserialize(leads, List<Lead>.class);
        
        // Obter os IDs dos Leads
        Set<Id> leadIds = new Set<Id>();
        for (Lead lead : leadList) {
            leadIds.add(lead.Id);
        }
        
        for (Lead lead : leadList) {
            String formattedCnpj = lead.CNPJ__c.replaceAll('[^0-9]', '');
            String endpoint = 'https://brasilapi.com.br/api/cnpj/v1/' + formattedCnpj;
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            request.setTimeout(120000);
            request.setHeader('Accept', 'application/json');
            request.setHeader('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');
            HttpResponse response = http.send(request);
            System.debug('Status code: ' + response.getStatusCode());
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> cnpjData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                lead.RazaoSocial__c = (String) cnpjData.get('razao_social');
                lead.NomeFantasia__c = (String) cnpjData.get('nome_fantasia') != '' ? (String) cnpjData.get('nome_fantasia') : 'Não Registrado';
                lead.CNPJStatus__c = 'Válido';
            } else {
                System.debug('Erro ao validar CNPJ: ' + response.getStatus());
                System.debug('Resposta: ' + response.getBody());
                lead.RazaoSocial__c = '';
                lead.NomeFantasia__c = '';
                lead.CNPJStatus__c = 'Inválido';
            }
        }
        
        // Atualizar os Leads
        if (!leadList.isEmpty()) {
            update leadList;
        }
    }
}