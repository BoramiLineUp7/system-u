import { LightningElement, api,track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import createCS from '@salesforce/apex/CustomerSlotBooking_Controller.insertCS';
import CSInsertSuccessMsg from '@salesforce/label/c.CSInsertSuccessMsg';
import CSCheckEmailsError from '@salesforce/label/c.CSCheckEmailsError';

export default class SlotConfirmationBox extends LightningElement {
    @api slotid;
    @api open = false;
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
    _token;
    record = {
        firstName:'',
        lastName:'',
        email:'',
        confirmEmail:'',
        numPlaces:1
    };
    @api selectedSlotStartdatetime;
    @api defaultPosition;
    @api avaliableSlots;

    @track isLoading = false;
    @track sameEmailInput = false;

    handleSubmit(event){
        //this.template.querySelector('c-custom-slot-submit-form').submit();
        if(!this.sameEmailInput){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Erreur',
                    message : CSCheckEmailsError,
                    variant: 'error',
                }),
            );
            return;
        }
        this.isLoading = true;
        if(this.captchaRequired){
            this.dispatchEvent(new CustomEvent('validatecaptcha', { bubbles: true, composed: true }));
        }
        else{
            this.createRecord();
        }
    }
    handleClose() {
        this.open = false;
    }
    get expectedStartdatetime(){
        if(this.selectedSlotStartdatetime){
            const offsetMinutes = Math.floor(60 * (this.defaultPosition - this.avaliableSlots) / (this.defaultPosition * 10))*10;
            let expectedDt = new Date(this.selectedSlotStartdatetime);
            return expectedDt.setMinutes( expectedDt.getMinutes() + offsetMinutes );;
        }
        return;
    }

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

    createRecord(){
        createCS({slotId:this.slotid, firstName:this.record.firstName, lastName:this.record.lastName, email:this.record.email, confirmEmail:this.record.confirmEmail, numPlaces:this.record.numPlaces, token:this.token})
        .then(result => {
            this.downloadPdf(result);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Réussite',
                    message : CSInsertSuccessMsg,
                    variant: 'success',
                }),
            );
            this.dispatchEvent(new CustomEvent('success', { bubbles: true, composed: true }));
        })
        .catch(error => {
            //this.dispatchEvent(new CustomEvent('error'),{ bubbles: true, composed: true });
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
        })
        .finally(() => {
            this.isLoading = false;
            if(this.captchaRequired){
                this.dispatchEvent(new CustomEvent('resetcaptcha'),{ bubbles: true, composed: true });
            }
        });
    }

    downloadPdf(content){
        const filename = content.filename;
        if(filename === ''){
            //no pdf
            return;
        }
        // It is necessary to create a new blob object with mime-type explicitly set for all browsers except Chrome, but it works for Chrome too.
        const newBlob = this.b64toBlob(content.pdf, 'application/pdf');    
        
        // MS Edge and IE don't allow using a blob object directly as link href, instead it is necessary to use msSaveOrOpenBlob
        if (window.navigator && window.navigator.msSaveOrOpenBlob) {
            window.navigator.msSaveOrOpenBlob(newBlob);
        } else {
            // For other browsers: create a link pointing to the ObjectURL containing the blob.
            const objUrl = window.URL.createObjectURL(newBlob);

            let link = document.createElement('a');
            link.href = objUrl;
            link.download = filename;
            link.click();

            // For Firefox it is necessary to delay revoking the ObjectURL.
            setTimeout(() => { window.URL.revokeObjectURL(objUrl); }, 250);
        }
    }

    b64toBlob(b64Data, contentType, sliceSize) {
        contentType = contentType || '';
        sliceSize = sliceSize || 512;
      
        var byteCharacters = atob(b64Data);
        var byteArrays = [];
      
        for (var offset = 0; offset < byteCharacters.length; offset += sliceSize) {
          var slice = byteCharacters.slice(offset, offset + sliceSize);
      
          var byteNumbers = new Array(slice.length);
          for (var i = 0; i < slice.length; i++) {
            byteNumbers[i] = slice.charCodeAt(i);
          }
      
          var byteArray = new Uint8Array(byteNumbers);
      
          byteArrays.push(byteArray);
        }
          
        var blob = new Blob(byteArrays, {type: contentType});
        return blob;
    }
}