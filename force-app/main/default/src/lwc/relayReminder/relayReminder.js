import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';

const CHANNEL_NAME = '/event/RelayReminder__e';

export default class RelayReminder extends LightningElement {

  // These are standard LWC API fields
  @api recordId;
  @api objectApiName;

  // These come from the LWC Settings Page
  @api consentFieldName;

  OPT_FIELDS = [];

  subscription = {};
  currentConsent = '';

  constructor() {
    super();

    this.subscribeToPlatformEvent();
  }

  connectedCallback() {
    this.OPT_FIELDS.push(this.objectApiName+'.'+this.consentFieldName);
  }

  disconnectedCallback() {
    // unsubscribe from events
    this.unregisterAllListeners();
  }

  @wire(getRecord, {recordId: '$recordId', optionalFields: '$OPT_FIELDS' })
    apiData({data, error}) {
      if (data) {
        if (data.fields[this.consentFieldName]) {
          this.currentConsent = data.fields[this.consentFieldName].value;
        }
      }
    }

  subscribeToPlatformEvent() {
    subscribe(CHANNEL_NAME, -1, (rsp) => {
      if ((rsp.data.payload.WhatId__c !== this.recordId) && (rsp.data.payload.WhoId__c !== this.recordId))
        return;

      if (this.currentConsent === null || this.currentConsent === '' || this.currentConsent.toLowerCase() === 'stop')
        return;

      const evt = new ShowToastEvent({
        title: 'Reminder',
        message: `Don't forget to send your Relay experiences.`,
        variant: 'success',
        mode: 'sticky'
      });
      this.dispatchEvent(evt);
    })
      .then(response => {
        this.subscription = response;
      })
  }

  unregisterAllListeners() {
    unsubscribe(this.subscription)
      .then(response => {
      });
  }
}