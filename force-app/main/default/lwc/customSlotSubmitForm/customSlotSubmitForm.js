import { LightningElement,track,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createCS from '@salesforce/apex/CustomerSlotBooking_Controller.insertCS';
import CSInsertSuccessMsg from '@salesforce/label/c.CSInsertSuccessMsg';
import CSCheckEmailsError from '@salesforce/label/c.CSCheckEmailsError';

export default class CustomSlotSubmitForm extends LightningElement {

    @api slotId;
    _token;
    @api captchaRequired;
    @api 
    get token(){
        return this._token;
    };
    set token(value){
        if(value){
            this._token = value;
            this.createRecord();
        }
    }
    @track sameEmailInput = false;

    record = {
        firstName:'',
        lastName:'',
        email:'',
        confirmEmail:'',
        numPlaces:1
    };

    updateField(event){
        const field = event.target.dataset.field;
        this.record[field] = event.target.value;
        if(field == 'email' || field == 'confirmEmail'){
            this.confirmEmail(event);
        }
    }

    confirmEmail(event){
        const regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        const value = event.target.value;
        if(value && value.match(regExpEmailformat)){
            event.target.setCustomValidity('');
        }
        else{
            event.target.setCustomValidity('Format de l\'adresse email non valide');
        }

        this.sameEmailInput = (this.record.email == this.record.confirmEmail);        
    }

    @api submit(){
        if(!this.sameEmailInput){
            this.dispatchEvent(new CustomEvent('surfaceerror', { bubbles: true, composed: true }));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Erreur',
                    message : CSCheckEmailsError,
                    variant: 'error',
                }),
            );
            return;
        }
        if(this.captchaRequired){
            this.dispatchEvent(new CustomEvent('validatecaptcha', { bubbles: true, composed: true }));
        }
        else{
            this.createRecord();
        }
    }

    createRecord(){
        createCS({slotId:this.slotId, firstName:this.record.firstName, lastName:this.record.lastName, email:this.record.email, confirmEmail:this.record.confirmEmail, numPlaces:this.record.numPlaces, token:this.token})
        .then(result => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Réussite',
                    message : CSInsertSuccessMsg,
                    variant: 'success',
                }),
            );
            this.dispatchEvent(new CustomEvent('createsuccess', { bubbles: true, composed: true }));
        })
        .catch(error => {
            this.dispatchEvent(new CustomEvent('createerror'),{ bubbles: true, composed: true });
            let message = 'Erreur inconnue';
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
}