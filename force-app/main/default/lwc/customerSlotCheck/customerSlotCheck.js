import { LightningElement,api,wire,track } from 'lwc';
import { getRecord,updateRecord,getFieldValue } from 'lightning/uiRecordApi';
import getSlotByIdOrUUID from '@salesforce/apex/CustomerSlot_Controller.getSlotByIdOrUUID';
import checkinCustomer from '@salesforce/apex/CustomerSlot_Controller.checkinCustomer';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ID_FIELD from '@salesforce/schema/CustomerSlot__c.Id';
import CS_STATUS from '@salesforce/schema/CustomerSlot__c.Status__c';
import CS_STATUSICON from '@salesforce/schema/CustomerSlot__c.StatusIcon__c';
import CS_ANP from '@salesforce/schema/CustomerSlot__c.ActualNumberOfPersons__c';
//labels
import status from '@salesforce/label/c.CSCheckInStatus';
import title from '@salesforce/label/c.CSCheckInTitle';
import enternnum from '@salesforce/label/c.CSCheckInEnterNumber';
import errorpers from '@salesforce/label/c.CSCheckInErrorPerson';
import updatesuccess from '@salesforce/label/c.CSCheckInUpdateSuccess';
import images from '@salesforce/resourceUrl/GraphicsPack';
import { fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';

export default class CustomerSlotCheck extends LightningElement {
    @track isLoading = false;
    @track slotRecord;
    wiredSlot;

    _recordId;
    @api 
    get recordId(){
        return this._recordId;
    }
    set recordId(value){
        if(value != this._recordId){
            this._recordId = value;
            this.isLoading = true;
        }
    }

    labels = {
        status,title,enternnum
    }

    @wire(CurrentPageReference) pageRef;

    @wire(getSlotByIdOrUUID, { recordId: '$_recordId'})
    wiredGetSlot(value){
        // Hold on to the provisioned value so we can refresh it later.
        this.wiredSlot = value;
        // destructure the provisioned value 
        const { data, error } = value;
        if (data) {
             this.slotRecord = data;
            //this.isLoading = false;
        }
        else if (error) {
            this.isLoading = false;
        }
    }

    get imgSrc(){
        return images + `${this.slotRecord.StatusIcon__c}`;
    }

    get noRecord(){
        return !this.isLoading && !this.slotRecord;
    }

    handleCheckIn(event){
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.slotRecord.Id;
        fields[CS_STATUS.fieldApiName] = 'Checked-In';

        let numOfpeople = parseInt(event.target.dataset.number || this.template.querySelector('.num-of-people').value);
        if(isNaN(numOfpeople)){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Erreur',
                    message: errorpers,
                    variant: 'error'
                })
            );
            return;
        }

        fields[CS_ANP.fieldApiName] = parseInt(numOfpeople);
        const recordInput = { fields };
        checkinCustomer({id : this.slotRecord.Id, numOfpeople : parseInt(numOfpeople)})
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Réussite',
                    message: updatesuccess,
                    variant: 'success'
                })
            );
            // Display fresh data in the form
            //dispatch update to store counter component
            fireEvent(this.pageRef, 'cscheckin', {});
            return refreshApex(this.wiredSlot);
        })
        .catch(error => {
            let message = 'Erreur inconnue lors de la mise à jour';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            } else if(typeof error.body === 'object' && Array.isArray(error.body.pageErrors)){
                message = error.body.pageErrors.map(e => e.message).join(', ');
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Erreur',
                    message : message,
                    variant: 'error',
                }),
            );
        });
    }

    handleLoadEnd(){
        this.isLoading = false;
    }
}