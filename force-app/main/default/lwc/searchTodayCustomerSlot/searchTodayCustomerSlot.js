import { LightningElement,wire,track } from 'lwc';
import searchTodayCustomerSlotByEmail from '@salesforce/apex/CustomerSlot_Controller.searchTodayCustomerSlotByEmail';
import searchLabel from '@salesforce/label/c.TodayCustomerSlotSearch';
import images from '@salesforce/resourceUrl/GraphicsPack';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
//fields def

const MINIMAL_SEARCH_TERM_LENGTH = 3; // Min number of chars required to search
const SEARCH_DELAY = 300; // Wait 300 ms after user stops typing then, peform search

export default class SearchTodayCustomerSlot extends LightningElement {
    @track queryTerm;
    @track records;
    labels = {
        searchLabel
    }
    searchThrottlingTimeout;
    searchTerm;
    cleanSearchTerm;
    @track singleRecordId;
    @track issearching = false;

    @wire(CurrentPageReference) pageRef;

    connectedCallback(){
        registerListener('cscheckin', this.search, this);
    }

    disconnectedCallback(){
        unregisterAllListeners(this);
    }

    get resultClass(){
        return `slds-m-top_medium ${this.singleRecordId ? 'slds-show_medium' : ''}`;
    }

    handleKeyUp(evt) {
        const isEnterKey = evt.keyCode === 13;
        if (isEnterKey) {
            this.queryTerm = evt.target.value;
        }
    }

    handleSelect(event){
        this.singleRecordId = event.currentTarget.dataset.id;
    }

    /* method to search */
    searchField(event) {
        this.searchTerm = event.target.value;
        this.singleRecordId = undefined;

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
                //this.LoadingText = true;
                // Send search event if search term is long enougth
                if (this.cleanSearchTerm.length >= MINIMAL_SEARCH_TERM_LENGTH) {
                    this.search();
                }
                this.searchThrottlingTimeout = null;
            },
            SEARCH_DELAY
        );
    }

    search(){
        this.issearching = true;
        searchTodayCustomerSlotByEmail({ searchTerm: this.cleanSearchTerm })
        .then(result => {
            this.records = [];
            result.forEach(element => {
                element.image = images + element.StatusIcon__c;
                this.records.push(element);
            });
        })
        .catch(error => {
            //console.log(error);
        })
        .finally(() => {
            this.issearching = false;
        });
    }
}