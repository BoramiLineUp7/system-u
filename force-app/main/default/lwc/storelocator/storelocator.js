import { LightningElement,api,track } from 'lwc';
import searchStore from '@salesforce/apex/Storelocator_Controller.searchStore';
import { NavigationMixin } from 'lightning/navigation';
const MINIMAL_SEARCH_TERM_LENGTH = 3; // Min number of chars required to search
const SEARCH_DELAY = 300; // Wait 300 ms after user stops typing then, peform search

export default class Storelocator extends NavigationMixin(LightningElement) {
    @api selectRecordId = '';
    @api searchRecords = [];
    @track issearching = false;
    searchThrottlingTimeout;
    searchTerm;
    cleanSearchTerm;

    connectedCallback() {
        if(this.selectRecordId != null && this.selectRecordName!= null ) {
            this.iconFlag = false;
            this.clearIconFlag = true;
            this.inputclass = 'slds-form-element__control slds-input-has-icon slds-input-has-icon slds-input-has-icon_left-right';
        }
    }

    handleKeyUp(event){
        const isEnterKey = evt.keyCode === 13;
        if (isEnterKey) {
            this.searchField(event);
        }
    }

    /* method to search */
    searchField(event) {
        this.searchTerm = event.target.value;

        // Compare clean new search term with current one and abort if identical
        const newCleanSearchTerm = this.searchTerm.trim().replace(/\*/g, '').toLowerCase();
        if (this.cleanSearchTerm === newCleanSearchTerm) {
            return;
        }

        // Save clean search term
        this.cleanSearchTerm = newCleanSearchTerm;

        // Ignore search terms that are too small
        if (this.cleanSearchTerm.length < MINIMAL_SEARCH_TERM_LENGTH) {
            this.searchResults = [];
            return;
        }

        // Apply search throttling (prevents search if user is still typing)
        if (this.searchThrottlingTimeout) {
            clearTimeout(this.searchThrottlingTimeout);
        }
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.searchThrottlingTimeout = setTimeout(() => {
                this.issearching = true;
                // Send search event if search term is long enougth
                if (this.cleanSearchTerm.length >= MINIMAL_SEARCH_TERM_LENGTH) {
                    searchStore({ searchTerms: this.cleanSearchTerm })
                    .then(result => {
                        this.searchRecords = result;  
                    })
                    .catch(error => {
                        console.log(error);
                    })
                    .finally(()=>{
                        this.issearching = false;
                    });
                }
                this.searchThrottlingTimeout = null;
            },
            SEARCH_DELAY
        );
    }

    /* reset data to empty value */
    resetData() {
        this.selectRecordId = "";
        // Dispatches the event to empty the value
        this.dispatchEvent(new CustomEvent('selected', {
            detail: {selectRecordId:null,selectRecordName:null} ,
        }));
    }

    handleSelect(event){
        this.dispatchEvent(new CustomEvent('selected', {detail: {selectRecordId:event.currentTarget.dataset.id}}));
        // Navigate to a URL
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/?IdMagasin=' + event.currentTarget.dataset.storeid
            }
        },
        true // Replaces the current page in your browser history with the URL
      );
    }

}