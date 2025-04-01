import {LightningElement,track,wire} from 'lwc';
import getAccount from '@salesforce/apex/accountheaderCtrl.getAccount';
import CCFiles from '@salesforce/resourceUrl/CCFiles'

export default class Accountheader extends LightningElement {

  storeId;
  connectedCallback() {
    this.storeId = this.getUrlParamValue(window.location.href, 'IdMagasin');
  }

  get globalStyle(){
    return 'background-image: url(' + CCFiles + '/background.png);';
  }
  get brandingLogo(){
    return 'background-image: url(' + CCFiles + '/brandinglogo.png);';
  }

  get basketIcon(){
    return CCFiles + '/basket.png';
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

  @track account;
  @track error;
  @track noaccount;
  @wire(getAccount, {storeId: '$storeId'}) 
  wiredAccount({
    error,
    data
  }) {
    if (data) {
      this.account = data;
      this.noaccount = Object.keys(data).length === 0 && data.constructor === Object;
    } else if (error) {
      this.error = error;
    }
  }
}