import { LightningElement } from 'lwc';

export default class CustomSlotSubmitFormTest extends LightningElement {

    handleSubmit(event){
        this.template.querySelector('c-custom-slot-submit-form').submit();
    }
}