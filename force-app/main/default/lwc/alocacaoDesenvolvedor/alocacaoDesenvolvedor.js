
import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDevelopers from '@salesforce/apex/AlocacaoDesenvolvedorController.getDevelopers';
import saveAllocations from '@salesforce/apex/AlocacaoDesenvolvedorController.saveAllocations';

export default class DeveloperAllocation extends LightningElement {
    @api recordId;
    developers = [];
    selectedDevelopers = [];
    columns = [
        { label: 'Nome', fieldName: 'Name' },
        { label: 'Especialidade', fieldName: 'Especialidade__c' }
    ];

    @wire(getDevelopers, { opportunityId: '$recordId' })
    wiredDevelopers({ error, data }) {
        if (data) {
            this.developers = data;
        } else if (error) {
            this.showToast('Erro', error.body.message, 'error');
        }
    }

    handleRowSelection(event) {
        this.selectedDevelopers = event.detail.selectedRows.map(row => row.Id);
    }

    async handleSave() {
        console.log('Desenvolvedores selecionados:', this.selectedDevelopers);
        if (!this.selectedDevelopers || this.selectedDevelopers.length === 0) {
            this.showToast('Erro', 'Selecione pelo menos um Desenvolvedor para alocar.', 'error');
            return;
        }

        try {
            await saveAllocations({ opportunityId: this.recordId, developerIds: this.selectedDevelopers });
            this.showToast('Sucesso', 'Desenvolvedores alocados com sucesso', 'success');
            this.selectedDevelopers = [];
            this.template.querySelector('lightning-datatable').selectedRows = [];
        } catch (error) {
            this.showToast('Erro', error.body.message, 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}