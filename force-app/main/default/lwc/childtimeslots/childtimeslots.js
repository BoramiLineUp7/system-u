import { LightningElement,api,track } from 'lwc';

/**
 * Show an item
 */
export default class Childtimeslots extends LightningElement {
    @api item;
    @api items;
    @api checkerDate;
    @api day;
    @api time;
    @track noslots = false;
    @track slots = false;
    @track empty = false;
    @track slotMessage = "";
    filteredItems;
    @track showSubSlots = false;

    onClickHandler(event) {
        const id = event.target.dataset.id; 
        
        let selectedSlot;
        if(id){
            //get the real record
            selectedSlot = this.filteredItems.filter(i => i.id === id)[0];
        }
        else if(this.filteredItems && this.filteredItems.length === 1 ){
            selectedSlot = this.filteredItems[0];
        }

        if (selectedSlot) {
            //we need to show the confirmation form
            const selectedDatetime = new Date(this.day.getFullYear(),this.day.getMonth(),this.day.getDate(),selectedSlot.hour,selectedSlot.minutes);
            this.dispatchEvent(new CustomEvent('slotclick', { detail: {
                slotId: selectedSlot.id ,
                date: selectedDatetime ,
                defaultPosition: selectedSlot.defaultPositions,
                avalaibleSlots:  selectedSlot.remainingPositions}
            }));
        }
        
        this.dispatchEvent(new CustomEvent('slotdetail', { detail: {day:this.day,time:this.time,id:id}}));
    }

    @api 
    get subslotinfo(){
        return this.subslotinfo;
    }
    set subslotinfo(value){
        this._subslotinfo = value;
        this.showSubSlots = (value && value.day.getDate() === this.day.getDate() && value.time === this.time && this.filteredItems && this.filteredItems.length > 1 && !value.id );
    }

    get menustyle(){
        return 'width:' + (this.template.querySelector("div").clientWidth + 1) + 'px';
    }

    connectedCallback(){
        //let filter = this.items.filter(i => i.hour.toString() + i.Day.toString() === this.time.toString().split(':')[0] + this.checkerDate);
        let filter = this.items.filter(i => i.hour + i.day === this.time.toString().split(':')[0] + this.checkerDate);

        if (filter.length > 0) {
            //slots in the specific hour
            this.filteredItems = filter;
        } else {
            this.slots = false;
            this.empty = true;
            this.slotMessage = "";
            return;
        }

        let total = 0;
        this.filteredItems.forEach(element => total += element.remainingPositions)
        this.slotMessage = total;
        if(total === 0){
            this.noslots = true;
            this.slots = false;
            this.slotMessage = "Non disponible";
        }
        else{
            this.filteredItems = this.filteredItems.filter(el => el.remainingPositions && el.remainingPositions > 0);
            this.noslots = false;
            this.slots = true;
            this.slotMessage = total;
        }
    }
}