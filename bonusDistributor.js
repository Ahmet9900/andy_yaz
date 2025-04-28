import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccounts from '@salesforce/apex/BonusDistributorLwcService.getAccounts';
import distributeBonus from '@salesforce/apex/BonusDistributorLwcService.distributeBonus';


export default class BonusDistributor extends LightningElement {
    @track accountOptions = [];
    @track contacts = [];
    @track accountId;
    @track bonusAmount;
    @track distributionMethod;
    @track showTable = false;

    distributionOptions = [
        { label: 'Oldest', value: 'oldest' },
        { label: 'Youngest and Alphabetically First', value: 'youngest-and-alphabetically-first' },
        { label: 'Evenly Distributed', value: 'evenly-distributed' }
    ];

    columns = [
        { label: 'Name', fieldName: 'Name', type: 'text' },
        { label: 'Birthdate', fieldName: 'Birthdate', type: 'date' },
        { label: 'Payment Amount', fieldName: 'PaymentAmount__c', type: 'currency' }
    ];

    connectedCallback() {
        getAccounts()
            .then(result => {
                this.accountOptions = result.map(acc => ({
                    label: acc.Name,
                    value: acc.Id
                }));
            })
            .catch(error => {
                console.error('Error loading accounts', error);
            });
    }

    handleAccountChange(event) {
        this.accountId = event.detail.value;
        
        
        this.bonusAmount = null;
        this.distributionMethod = null;

       
        this.showTable = false;
        this.contacts = []; 
    }

    handleAmountChange(event) {
        this.bonusAmount = event.detail.value;
        this.showTable = false;
    }

    handleMethodChange(event) {
        this.distributionMethod = event.detail.value;
        this.showTable = false;
    }

    handleDistribute() {

        if (this.showTable) {
            this.showToast('Note', 'Bonus has already been distributed for this account.', 'info');
            return;
        }

        if (!this.accountId || !this.bonusAmount || !this.distributionMethod) {
            this.showToast('Note', 'Please fill out all fields.', 'Note');
            return;
        }
    
        if (this.bonusAmount <= 0) {
            this.showToast('Error', 'Bonus Amount must be greater than zero.', 'error');
            return;
        }
    
        distributeBonus({
            paymentAmount: this.bonusAmount,
            accountId: this.accountId,
            distributionType: this.distributionMethod
        })
        .then(result => {
            this.contacts = result;
            this.showTable = true;
            this.showToast('Success', 'Bonus successfully distributed!', 'success'); 
        })
        .catch(error => {
            console.error('Error distributing bonus', error);
            this.showToast('Error', 'Failed to distribute bonus.', 'error');
        });
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
            })
        );
    }
}