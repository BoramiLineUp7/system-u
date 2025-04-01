import { LightningElement,track,wire } from 'lwc';
import getStoreCount from '@salesforce/apex/CustomerSlot_Controller.getStoreCount';
import setStoreCount from '@salesforce/apex/CustomerSlot_Controller.setStoreCount';
import { refreshApex } from '@salesforce/apex';
import { generateRecordInputForCreate } from 'lightning/uiRecordApi';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';

const AUTOREFRESH_DELAY = 60000; // Wait 60 000 ms after user stops typing then, peform search

export default class StoreCountPanel extends LightningElement {
    @track count=0;
    @track store;
    isloading = true;
    _interval;
    _store;

    @wire(CurrentPageReference) pageRef;

    connectedCallback(){
        registerListener('cscheckin', this.getStoreCountF, this);
        this.getStoreCountF();
        //schedule auto refresh
        this._interval = setInterval(() => {
            this.getStoreCountF();
        }, AUTOREFRESH_DELAY);
    }

    disconnectedCallback(){
        clearInterval(this._interval);
        unregisterAllListeners(this);
    }
    
    getStoreCountF(){
        this.isloading = true;
        getStoreCount()
        .then(result => {
            this.store = result;  
        })
        .catch(error => {
            //console.log(error);
        })
        .finally(()=>{
            this.isloading = false;
        });
    }

    handleAction(event){
        this.isloading = true;
        setStoreCount({ op: event.currentTarget.dataset.op })
        .then(result => {
            this.store = result;  
        })
        .catch(error => {
            //console.log(error);
        })
        .finally(()=>{
            this.isloading = false;
        });
    }

    get countClass(){
        let className = 'counter slds-p-left_large slds-p-right_large ';
        if(this.store){
            if(this.store.StoreCustomerCount__c < (this.store.StoreMaxCustomer__c  * 0.9)){
                className += 'green';
            }
            else if(this.store.StoreCustomerCount__c < this.store.StoreMaxCustomer__c){
                className += 'warning';
            }
            else{
                className += 'alert';
            }
        }
        return className;
    }
}