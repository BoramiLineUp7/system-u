/*import { LightningElement, track } from 'lwc';
import pageUrl from '@salesforce/resourceUrl/recaptcha2';

export default class GoogleCapatcha extends LightningElement {
    @track navigateTo;
    captchaWindow = null;

    constructor(){
        super();

        this.navigateTo = pageUrl;

        window.addEventListener("message", this.listenForMessage);
    }

    captchaLoaded(evt){
        var e = evt;
        console.log(e.target.getAttribute('src') + ' loaded');
        if(e.target.getAttribute('src') == pageUrl){
            // You know that your captcha is loaded
        } 
    }

    listenForMessage(message){
        console.log(message);
    }
}*/