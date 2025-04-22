import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getCNPJData from '@salesforce/apex/BrasilApiService.getCNPJData';

export default class LeadFormCompleto extends NavigationMixin(LightningElement) {
    cnpj = '';
    razaoSocial = '';
    nomeFantasia = '';
    cnpjStatus = '';

    guiasAbertas = ['informacoesBasicas', 'informacoesContato', 'informacoesEndereco', 'informacoesAdicionais']

    handleCnpjChange(event) {
        this.cnpj = event.target.value.replace(/[^0-9]/g, '');

        if (this.cnpj.length === 14) {
            getCNPJData({ cnpj: this.cnpj })
                .then(response => {
                    if (response.statusCode === '200') {
                        this.razaoSocial = response.razaoSocial;
                        this.nomeFantasia = response.nomeFantasia ? response.nomeFantasia : 'Não Informado';
                        this.cnpjStatus = response.cnpjStatus;
                    } else {
                        this.razaoSocial = '--';
                        this.nomeFantasia = '--';
                        this.cnpjStatus = 'Inválido';
                        this.showToast('Erro', response.errorMessage, 'error');
                    }
                })
                .catch(error => {
                    this.showToast('Erro na API', error.body.message, 'error');
                });
        }
    }

    handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        fields.CNPJ__c = this.cnpj;
        fields.RazaoSocial__c = this.razaoSocial;
        fields.NomeFantasia__c = this.nomeFantasia;
        fields.CNPJStatus__c = this.cnpjStatus;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess(event) {
        const toastEvent = new ShowToastEvent({
            title: 'Sucesso!',
            message: 'Lead criado com ID: ' + event.detail.id,
            variant: 'success'
        });
        this.dispatchEvent(toastEvent);

        // Navegar para o registro criado
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail.id,
                objectApiName: 'Lead',
                actionName: 'view'
            }
        });
    }

    handleError(event) {
        this.showToast('Erro', event.detail.message || 'Erro ao criar o Lead', 'error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}