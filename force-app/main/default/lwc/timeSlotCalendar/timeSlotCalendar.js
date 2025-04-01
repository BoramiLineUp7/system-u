import { LightningElement, track, wire, api } from 'lwc';
import getSlots from '@salesforce/apex/TimeSlotManager.getSlots';
import { refreshApex } from '@salesforce/apex';
import formFactorPropertyName from '@salesforce/client/formFactor';

export default class App extends LightningElement {
    numberofdays = 7;
    @api captchaRequired;
    @api token;
    storeId = '';
    dateoffset = 0;
    @track wiredSlots = undefined;
    @track hasSlots = true;
    @track isLoading = true;
    @track slotdetail;
    //@wire(getSlots, {storeId:'$storeId',dateOffset:'$dateoffset'}) wiredSlots;

    connectedCallback() {
        this.storeId = this.getUrlParamValue(window.location.href, 'IdMagasin');
        //<-- Adapt number of slot based on the device form factor
        if (formFactorPropertyName=='Medium') { this.numberofdays = 4; }
        if (formFactorPropertyName=='Small') { this.numberofdays = 3; }

        this.getSlotsF();
    }

    getSlotsF(){
        this.isLoading = true;
        this.wiredSlots = undefined;
        try{
            getSlots({storeId:this.storeId,dateOffset:this.dateoffset})
            .then(data => { 
                this.wiredSlots = data;
                this.hasSlots = data.length > 0;
            })
            .catch(error => {
                //console.log(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
        }
        catch(error){
            //IE11 issue
            this.isLoading = false;
            //console.log(error);
        }

    }

    getUrlParamValue(url, key) {
        try{
            return new URL(url).searchParams.get(key);
        }
        catch(error){
            //IE11 fallback
            const name = key.replace(/[\[\]]/g, '\\$&');
            const regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
            results = regex.exec(url);
                if (!results) return null;
                if (!results[2]) return '';
            return decodeURIComponent(results[2].replace(/\+/g, ' '));
        }
    }

    get dates() {
        const dateArray = [];
        let minDate = new Date();
        for (let i = 0; i < this.numberofdays; i++){
            let day = this.addDays(minDate,this.dateoffset + i);
            dateArray.push( {offset:i, date:day, checkerDay: day.getDate().toString()});
        }
        return dateArray;
    }

    addDays (date, days) {
        let result = new Date(date);
        result.setDate(result.getDate() + days);
        return result;
      }

    get daysArray() {
        let array = [];
        for (let i = 0; i < this.numberofdays; i++){
            array.push(i);
        }
    }

    get showBack() {
        return (this.dateoffset > 0);
    }

    handlePrev() {
        this.dateoffset -= this.numberofdays;
        this.getSlotsF();
    } 

    handleNext() {
        this.dateoffset += this.numberofdays;
        this.getSlotsF()();
    }

    handleRefresh() {
        const confirmbox = this.template.querySelector('c-slot-confirmation-box');
        confirmbox.open = false;
        this.hasSlots = true; //just wait the server response to recalculate
        //refreshApex(this.wiredSlots);
        this.getSlotsF();
    }

    handleSlotClick(event) {
        const confirmbox = this.template.querySelector('c-slot-confirmation-box');
        confirmbox.open = true;
        confirmbox.slotid = event.detail.slotId;
        confirmbox.selectedSlotStartdatetime = event.detail.date;
        confirmbox.defaultPosition = event.detail.defaultPosition;
        confirmbox.avalaibleSlots = event.detail.avalaibleSlots;
    }
    handleResetRecaptcha(){
        this.dispatchEvent(new CustomEvent('resetcaptcha'),{ bubbles: true, composed: true });
    }
    handleSubSlotOpen(event){
        this.slotdetail = event.detail;
    }
}