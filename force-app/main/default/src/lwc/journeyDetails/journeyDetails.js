import { LightningElement, track, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getLastTriggerDate from '@salesforce/apexContinuation/Relay.getLastTriggerDate';
import { registerListener, unregisterAllListeners } from 'c/relayPubSub';
import getExperienceStatus from '@salesforce/apex/RelayExperienceStatus.getExperienceStatus';

const TITLE = 'Relay Experience';

export default class JourneyDetails extends LightningElement {
  @api multiSelection;
  @api readOnly;

  @track sendingStatus = '';
  @track lastTimeSent = 0;
  @track lastOpenedTime = 0;
  @track greeting = '';
  @track isSelected = false;

  @track sentStatus = 'Not Sent';
  @track sentNotes = null;
  @track openedStatus = 'Not Opened';

  @wire(CurrentPageReference) pageRef;

  curLocale = navigator.language || 'en-us';

  connectedCallback() {
    this.isSelected = this._trigger.isSelected;

    registerListener('refreshLastTimeSent', this.handleRefreshLastTimeSent, this);
    registerListener('refreshSelection', this.handleRefreshSelection, this);
    registerListener('experience-status', this.handleExperienceStatus, this);
  }

  disconnectedCallback() {
    // unsubscribe from events
    unregisterAllListeners(this);
  }

  _journey;
  @api get journey() {
    return this._journey;
  }

  set journey(value) {
    this._journey = value;
  }

  _currentCcid;
  @api get currentCcid() {
    return this._currentCcid;
  }
  set currentCcid(value) {
    this._currentCcid = value;
  }

  _trigger;
  @api get trigger() {
    return this._trigger;
  }
  set trigger(value) {
    this._trigger = value;
  }

  @api get isSent() {
    return (this.lastTimeSent > 0) ? true : false;
  }
  @api get isOpened() {
    return (this.lastOpenedTime > 0) ? true : false;
  }

  handleRefreshLastTimeSent(triggerId) {
    if (this._trigger && this._trigger.name === triggerId) {
      this.isSelected = this._trigger.isSelected; // false;
      
      let triggerIds = [];
      triggerIds.push(this._trigger.name);
      const expStatus = getExperienceStatus({ccid:this._currentCcid, triggerIds:triggerIds})
      .then(data => {
        if (data.length == 1) { // there should only be one result returned. 
          this.handleExperienceStatus(data[0]);
        }
      })
      .catch(err => {});
    }
  }

  handleRefreshSelection(triggerId) {
    if (this._trigger && this._trigger.name === triggerId) {
      this.isSelected = this._trigger.isSelected;
    }
  }

  handleExperienceStatus(expStatus) {
    let opts = { 'weekday': 'short', 'month': 'short', 'day': 'numeric', 'hour': 'numeric', 'minute':'numeric'};

    let sentDtm = 0;    
    let preText = 'Not Sent';

    if (this._trigger && this._trigger.name === expStatus.triggerId) {
      if (expStatus.undeliveredDtm > 0) {
        sentDtm = expStatus.undeliveredDtm;
        preText = 'Not Delivered';
        this.sentNotes = expStatus.undeliveredReason;
      } else if (expStatus.deliveredDtm > 0) {
        sentDtm = expStatus.deliveredDtm;        
        preText = 'Delivered';
        this.sentNotes = null;
      } else if (expStatus.notPostedDtm > 0) {
        sentDtm = expStatus.notPostedDtm;
        preText = 'Not Posted';
        this.sentNotes = expStatus.notPostedReason;
      } else if (expStatus.postedDtm > 0) {
        sentDtm = expStatus.postedDtm;
        preText = 'Sending';
        this.sentNotes = null;
      } else if (expStatus.requestSentDtm > 0) {
        sentDtm = expStatus.requestSentDtm;
        preText = 'Sending';
        this.sentNotes = null;
      } 
      if (sentDtm > 0) 
        this.sentStatus = `${preText} ${new Date(sentDtm).toLocaleDateString(this.curLocale, opts)}`;
      else 
        this.sentStatus = `${preText}`
      
      if (expStatus.openedDtm > 0) {
        this.openedStatus = `Opened ${new Date(expStatus.openedDtm).toLocaleDateString(this.curLocale, opts)}`;
      }
      else {
        this.openedStatus = 'Not Opened';
      }      
    }
  }

  get hasSentNotes() {
    return (this.sentNotes == null) ? false : true;
  }

  handleSelectedChange(event) {
    this.isSelected = !this.isSelected;
    this.sendSelectedEvent();
  }

  sendSelectedEvent() {
    const checkedEvent = new CustomEvent('triggerselect', { detail:{ journeyId: this._journey.id, triggerName: this._trigger.name, isSelected: this.isSelected } });
    this.dispatchEvent(checkedEvent);
  }

  handleSendClick() {
    const evt = new CustomEvent('triggersend', { detail: { journeyId: this._journey.id, triggerName: this._trigger.name } });
    this.dispatchEvent(evt);
  }

  get hasBeenTriggered() {
    return (this.lastTimeSent === null || this.lastTimeSent.length === 0) ? false : true;
  }

  get hasTriggerNotes() {
    return (this.trigger && this.trigger.notes && this.trigger.notes.length > 0) ? true : false;
  }

  logmsg(msg) {
    this.greeting += ' ' + msg;
  }
}