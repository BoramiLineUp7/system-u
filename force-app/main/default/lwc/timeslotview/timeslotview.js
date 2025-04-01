import { LightningElement, track, wire } from 'lwc';
import getSlots from '@salesforce/apex/TimeSlotManager.getSlots';
export default class App extends LightningElement {

// today = new Date();
// tomorrow = new Date(today)+1;

// @wire(getSlots) wiredSlots;

// get hours() {
//     if (this.wiredSlots.data) {
//         return this.wiredSlots.data;
//     }
// }

//tomorrow = get Date()+1;
//nextDay = new Date()+2;

    /**
     * Getter for the features property
     */
    get hours() {
        return [
            {
                hour: '07:00',
                slots: [{avaliableSlots: 4}, { avaliableSlots: 4}, { avaliableSlots: 0}]
                //slots: [{hour: 10, day: 20, max: 5}]
            },
            {
                hour: '08:00',
                slots: [{avaliableSlots: 4}, { avaliableSlots: 4}, { avaliableSlots: 4}]
            },
            {
                hour: '09:00',
                slots: [{avaliableSlots: 4}, { avaliableSlots: 0}, { avaliableSlots: 4}]
            },
            {
                hour: '10:00',
                slots: [{avaliableSlots: 4}, { avaliableSlots: 4}, { avaliableSlots: 4}]
            },
            {
                hour: '11:00',
                slots: [{avaliableSlots: 0}, { avaliableSlots: 4}, { avaliableSlots: 4}]
            },
            {
                hour: '12:00',
                slots: [{avaliableSlots: 4}, { avaliableSlots: 4}, { avaliableSlots: 4}]
            },
        ];
    }
}