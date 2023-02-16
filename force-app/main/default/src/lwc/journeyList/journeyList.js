import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CurrentPageReference } from 'lightning/navigation';
import userId from '@salesforce/user/Id';
// import { refreshApex } from '@salesforce/apex';
// import { getSObjectValue } from '@salesforce/apex';

import triggerJourney from '@salesforce/apexContinuation/Relay.triggerJourney';
import getJourneyList from '@salesforce/apexContinuation/Relay.getJourneyList';
import getRelaySettings from '@salesforce/apexContinuation/Relay.getRelaySettings';
import getExperienceStatus from '@salesforce/apex/RelayExperienceStatus.getExperienceStatus';
import { getTriggerInputs, onboarding } from 'c/journeyUtils';
import { fireEvent } from 'c/relayPubSub';

const TITLE = 'Relay Experience';
const TITLE_NOT_SENT = 'Relay Experience Not Sent';
const MSG_NO_CONSENT = 'Message was not sent. User does not have consent.';
const OPT_FIELDS = ['Name', 'AccountId'];

export default class Relay extends LightningElement {
  @track greeting = '';
  @track journeys = null;
  @track errors = [];
  @track ccid = '';
  @track consent = '';
  @track settings = null;
  @track sendLabel = 'Send Experience';
  @track selected = false;
  @track showModal = false;
  @track firstName;
  @track lastName;
  @track mobilePhone;
  @track isSending = false;

  @api recordId;
  @api objectApiName;   // used to pass to child componets

  // From our LWC Settings
  @api journeyFilter;
  @api dynamicFilterFieldName;
  @api launchWithApi;
  @api deactivatePreviousConnections;
  @api ccidFieldName;
  @api consentFieldName;
  @api mobilePhoneFieldName;
  @api firstNameFieldName;
  @api lastNameFieldName;
  @api dateOfBirthFieldName;
  @api multiSelection;
  @api secondaryAccountIdFieldName;
  @api addressStreetFieldName;
  @api addressCityFieldName;
  @api addressStateCodeFieldName;
  @api addressPostalCodeFieldName;
  @api addressFieldName;
  @api debugging;

  @track selectedTriggers = [];
  @track confirmHeading;
  @track confirmTriggers = [];
  @track readOnly;

  delayedAPIName = null;
  dynamicFilters = null;
  uniqueInputs = null;  // Will be populated with a list of all potential input_ field names
  uniqueInputFieldNames = null;
  hasConsent = false;
  hasMobilePhone = false;
  fullJourneyList = null;
  extFieldNames = [];

  OPT_FIELDS2 = [];
  
  apiData;
  inputData;

  expandedJourney = {};

  constructor() {
    super();

    getRelaySettings()
      .then(data => {
        this.settings = JSON.parse(data);
        if (this.settings.extFields != null) {
          this.extFieldNames = this.settings.extFields.split(';');
        }
        this.checkObjectApiName();
      })
      .catch(err => {
        this.logmsg(err.message);
      })
  }

  // This fn is a bit of a hack in order to get the Relay settings before getting the field data
  // This is because two of the Relay settings contain additional, optional, field names to get data for.
  checkObjectApiName() {
    if (this.objectApiName) {
      this.delayedAPIName = this.objectApiName;
      if (this.launchWithApi === 'Read Only') {
        this.readOnly = true;
        this.multiSelection = false;
      }
    } else {
      // There is a possibiliy that we retrieved our Settings before SF set our API Name value.
      // In this case we will keep checking every second waiting for SF to set the value (not a very good design on SF part)
      let bindRecheck = this.checkObjectApiName.bind(this);
      setTimeout(bindRecheck, 1000);
    }
  }

  @wire(CurrentPageReference) pageRef; // required for eventing between journeyList and journeyDetails components

  pushIfNotEmpty = function(arry, fieldName) {
    if (fieldName && fieldName.length > 0)
      arry.push(fieldName);
  }

  @wire(getObjectInfo, { objectApiName: '$delayedAPIName' })
  getObjectInfo({ data, error }) {
    if (data) {
      let tmpFields = OPT_FIELDS.concat(
        [this.ccidFieldName,
        this.consentFieldName,
        this.mobilePhoneFieldName        
        ]);

      if (this.firstNameFieldName && this.firstNameFieldName.length > 0)
        tmpFields.push(this.firstNameFieldName);
      
      if (this.lastNameFieldName && this.lastNameFieldName.length > 0)
        tmpFields.push(this.lastNameFieldName);
      
      if (this.dateOfBirthFieldName && this.dateOfBirthFieldName.length > 0) {
        tmpFields.push(this.dateOfBirthFieldName);
      } else {
        this.dateOfBirthFieldName = 'Birthdate';
        tmpFields.push(this.dateOfBirthFieldName);
      }

      this.pushIfNotEmpty(tmpFields, this.secondaryAccountIdFieldName);
      this.pushIfNotEmpty(tmpFields, this.addressStreetFieldName);
      this.pushIfNotEmpty(tmpFields, this.addressCityFieldName);
      this.pushIfNotEmpty(tmpFields, this.addressStateCodeFieldName);
      this.pushIfNotEmpty(tmpFields, this.addressPostalCodeFieldName);

      if (this.dynamicFilterFieldName && this.dynamicFilterFieldName.length > 0)
        tmpFields.push(this.dynamicFilterFieldName);

      this.extFieldNames.forEach(ext => tmpFields.push(ext));
      this.OPT_FIELDS2 = [...tmpFields.map(v => `${this.objectApiName}.${v}`)];

//      this.loadExperienceList()
    } else if (error) {
      this.logmsg(" error in getObjectInfo");
    }
  }

  @wire(getRecord, { recordId: '$recordId', fields: '$REQ_FIELDS', optionalFields: '$OPT_FIELDS2' })
  dynamicUpdate({ data, error }) {
    if (data) {
      this.apiData = data;

      this.ccid = this.getApiValue(this.ccidFieldName);
      this.firstName = this.getApiValue(this.firstNameFieldName);
      this.lastName = this.getApiValue(this.lastNameFieldName);
      this.mobilePhone = this.getApiValue(this.mobilePhoneFieldName);
      this.consent = this.getApiValue(this.consentFieldName);

      this.checkForMissingData();

      if (this.dynamicFilterFieldName) {
        const labels = this.getApiValue(this.dynamicFilterFieldName);
        if (labels.length > 0)
          this.dynamicFilters = labels.toLowerCase().split('|');
      }
      this.loadExperienceList();
      //this.filterExperienceList();
    }
    else if (error) {
      this.logmsg(error);
      this.checkForMissingData();
    }
  }

  checkForMissingData() {
    this.errors = []; // reset error list

    if (this.ccid.length === 0) {
      this.errors.push('CCID has not been set');
    }

    if (this.mobilePhone.length === 0) {
      this.errors.push('Mobile Phone is required');
    }
    else {
      this.hasMobilePhone = true;
    }

    const currentConsent = this.getApiValue(this.consentFieldName).toLowerCase();

    if (currentConsent.length === 0) {
      this.errors.push('SMS consent is required');
      this.hasConsent = false;
    } else if (currentConsent.toLowerCase() === 'stop') {
      this.errors.push('SMS consent is STOP');
      this.hasConsent = false;
    } else {
      this.hasConsent = true;
    }
  }

  BATCH_SIZE = 3;
  loadingJourneys = false;
  
  getBatch(skip, batchSize, labels) {
    if (skip === 0) {
      this.journeys = [];
    }

    getJourneyList({ skip: skip, getLimit:batchSize, labels:labels })
      .then(data => {
        const resp = JSON.parse(data);

        if (resp.statusCode === 401) {
          this.toastError(TITLE, 'Unauthorized access to experience list.');
          return;
        }

        if (resp.statusCode !== 200) {
          this.toastError(TITLE, 'Error loading experiences. Please retry.');
          return;
        }

        // this.fullJourneyList = JSON.parse(resp.body).journeys.filter(j => !j.deleted && j.live && j.live.components);
        let jlist = JSON.parse(atob(resp.bodyBase64)).journeys;
        let a = jlist.filter(j => !j.deleted && j.live && j.live.components);
        this.fullJourneyList = this.fullJourneyList.concat(a)

        if (jlist.length < this.BATCH_SIZE) {
          // we are done getting the list 
          
          this.fullJourneyList.sort(this.sortByJourneyName);

          let allInputs = [];
          // 1. Create a separate collection of just the APITriggers
          // 2. Determine all possible input_ parameters
          this.fullJourneyList.forEach(j => {
            j.journeyLabel = j.live.name;
            let components = [];
            j.live.components.forEach(c => {              
              if (c.type === 'APITrigger') {
                if (!c.nickname) {
                  c.nickname = '';
                }
                c.journeyId = j.id;
                allInputs.push(...getTriggerInputs(j, c.name));
                components.push(c);
                
                this.isPreSelected(j, c);
              }
            });
            
            if (components.length > 0) {
              this.journeys.push(j);
              components.sort(this.sortByTriggerNickname);
              j.live.fullTriggerComponents = components;
              j.live.triggerComponents = components;
            }

          });
          this.loadingJourneys = false;
          this.loadInputFields(allInputs);

          // this.filterExperienceList();  // filter list by labels - this is now done server side          

        } else {
          this.getBatch(skip + jlist.length, this.BATCH_SIZE, labels);
        }
      })
      .catch((err) => {
        this.logmsg(' error getting experience list: ' + err.message);
        this.toastError(TITLE, 'Error loading experiences.');
        this.loadingJourneys = false;    
      })
  }

  preSelectExperiences() {
    if (this.canAddTriggerToVisibleList(labels, c)) {
      this.isPreSelected(j, c);
      fireEvent(this.pageRef, 'refreshSelection', c.name);
      components.push(c);
    }
  }

  loadExperienceList() {
      this.fullJourneyList = [];
      this.loadingJourneys = true;
      
      const labels = this.getFilterList().join('|');      

      this.getBatch(0, this.BATCH_SIZE, labels);
  }

  filterExperienceList() {
    if (this.loadingJourneys || !this.fullJourneyList) {
      return;
    }

    const labels = this.getFilterList();
    this.journeys = [];

    this.fullJourneyList.forEach(j => {
      j.journeyLabel = j.live.name;
      let components = [];
      j.live.fullTriggerComponents.forEach(c => {
        if (this.canAddTriggerToVisibleList(labels, c)) {
          this.isPreSelected(j, c);
          fireEvent(this.pageRef, 'refreshSelection', c.name);
          components.push(c);
        }
      });
      if (components.length > 0) {
        this.journeys.push(j);
        j.live.triggerComponents = components;
      }
      this.updateJourneySelectedCount(j);
    });
  }

  loadInputFields(allInputs) {
    this.uniqueInputs = Array.from(new Set(allInputs));
    this.uniqueInputFieldNames = [...this.uniqueInputs.map(i => `${this.objectApiName}.${i}`)];
  }

  @wire(getRecord, { recordId: '$recordId', fields: null, optionalFields: '$uniqueInputFieldNames' })
  retrievedInputFieldData({ data, error }) {
    if (data) {
      if (!data || !data.fields) {
        return;
      }

      this.inputData = data;
    }
    else if (error) {
      this.logmsg(error);
    }
  }

  getFieldValue = function (field, data) {
    try {
      if (!field)
        return '';

      let segments = field.split('.');

      let seg = segments.shift();

      if (seg.toLowerCase() === 'id' && segments.length === 0)
        return data.id;

      if (!data.fields)
        return '';

      let f = data.fields[seg];
      if (!f || !f.value)
        return '';

      // if (f.value.fields) {
      if (typeof f.value === "object") {
        if (segments.length === 0)
          return '';
        return this.getFieldValue(segments.join('.'), f.value);
      }
      return f.value || '';
    } catch (err) {
      console.log(err);
      return ''
    }
  }

  getApiValue = function (field) {
    return this.getFieldValue(field, this.apiData);
  }

  getInputFieldValue = function (field) {
    return this.getFieldValue(field, this.inputData);
  }

  getFilterList() {
    let filters = [];

    if (this.journeyFilter)
      filters = filters.concat(this.journeyFilter.toLowerCase().split('|'));
    if (this.dynamicFilterFieldName && this.dynamicFilterFieldName.length > 0) {
      let data = this.getApiValue(this.dynamicFilterFieldName);
      if (data.length > 0)
        filters = filters.concat(data.toLowerCase().split('|'));
    }

    // Trim all leading and trailing white space and then remove any entires that are empty
    return filters
      .map(f => f.trim())
      .filter(f => f.length > 0);
  }

  canAddTriggerToVisibleList = function (allowedLabels, c) {
    if (allowedLabels.length === 0)
      return true;

    if (!c.labels || c.labels.length === 0)
      return false;

    return c.labels.some(l => allowedLabels.includes(l.toLowerCase()))
  }

  isPreSelected(journey, trigger) {
    if (!this.dynamicFilters || !this.hasConsent) {
      trigger.isSelected = false;
    } else {
      trigger.isSelected = trigger.labels.some(l => this.dynamicFilters.includes(l.toLowerCase()));
    }
    fireEvent(this.pageRef, 'refreshSelection', trigger.name);
  }

  getSelectedTriggers() {
    let selected = [];
    this.journeys.forEach(j => {
      j.live.triggerComponents.forEach(t => {
        if (t.isSelected)
          selected.push(t);
      })
    })
    return selected;
  }

  handleTriggerSelection(evt) {
    const j = this.getJourney(evt.detail.journeyId);
    const trigger = this.getTrigger(evt.detail.journeyId, evt.detail.triggerName);
    if (trigger) {
      trigger.isSelected = evt.detail.isSelected;
    }

    this.updateJourneySelectedCount(j);
  }

  handleSectionToggle(evt) {    
    const openSections = evt.detail.openSections;
    if ( openSections == null || openSections.length === null) {
      return;
    }        
    
    const jid = openSections;
    
    if (!this.expandedJourney[jid]) {
        const tids = this.getTriggerIds(jid);
        if (tids.length == 0)
          return;
        const expStatus = getExperienceStatus({ccid:this.ccid, triggerIds:tids})
        .then(data => {
          data.forEach(tstats => {
            fireEvent(this.pageRef, 'experience-status', tstats);                        
          })
       //   this.expandedJourney[jid] = true;
        })
        .catch(err => {
          this.logmsg(err.message);
          this.toastError(TITLE, 'Error getting experiences status');          
        })      
    }  
  }

  updateJourneySelectedCount(journey) {
    if (!this.multiSelection) {
      return;
    }
    const selectedCount = journey.live.triggerComponents.reduce((acc, t) => {
      if (t.isSelected)
        return acc + 1;
      return acc;
    }, 0);

    if (selectedCount > 0) {
      journey.journeyLabel = `${journey.live.name} (${selectedCount} selected)`;
    }
    else {
      journey.journeyLabel = journey.live.name;
    }
    this.updateTotalSelectedCount();
  }

  updateTotalSelectedCount() {
    if (this.multiSelection) {
      const selectedCount = this.journeys.reduce((acc, j) => {
        return acc + j.live.triggerComponents.reduce((acc2, t) => {
          if (t.isSelected)
            return acc2 + 1;
          return acc2;
        }, 0)
      }, 0);
      this.sendLabel = `Send Experiences (${selectedCount} selected)`;
    }
  }

  haveRequiredFields() {
    if (!this.hasConsent) {
      this.toastWarning(TITLE_NOT_SENT, 'SMS consent is required.');
      return false;
    }

    if (!this.hasMobilePhone) {
      this.toastWarning(TITLE_NOT_SENT, 'A Mobile phone number is required.');
      return false;
    }

    if (this.ccid === '') {
      this.toastWarning(TITLE_NOT_SENT, 'Unique Relay CCID has not been set.');
      return false;
    }

    return true;
  }

  /*
  ** This method is called by the journeyDetails component when it's <send> button is clicked
  **
      evt.detail = {
        journeyId: "",
        triggerName: ""
      }
  */
  handleTriggerSend(evt) {
    if (!this.haveRequiredFields())
      return;

    const trigger = this.getTrigger(evt.detail.journeyId, evt.detail.triggerName);
    this.showConfirmationDialog([trigger]);
  }

  // Called when the multi-selection send button is clicked
  handleOnClick() {
    if (!this.haveRequiredFields())
      return;

    const selectedTriggers = this.getSelectedTriggers();
    if (selectedTriggers.length === 0) {
      this.toastWarning(TITLE, 'Please select at least one experience to send.');
      return;
    }

    if (selectedTriggers.length > 5) {
      this.toastWarning(TITLE, 'You can only send 5 experiences at a time.');
      return;
    }

    this.showConfirmationDialog(selectedTriggers);
  }

  showConfirmationDialog(list) {
      this.confirmTriggers = list;
      if (this.confirmTriggers.length === 1) {
        this.confirmHeading = 'Confirm Sending Experience';
      }
      else {
        this.confirmHeading = 'Confirm Sending Experiences';
      }
      this.showModal = true;
  }

  handleModalCancel() {
    this.showModal = false;
  }

  handleModalSend() {
    this.confirmTriggers.map(t => {
      const journey = this.getJourney(t.journeyId);
      if (this.launchWithApi === 'Onboarding') {
        this.launchViaOnboarding(journey, t);
      } else {
        this.launchViaMessaging(journey, t);
      }
      return null;
    });

    this.showModal = false;
    return null;
  }

  launchViaOnboarding(journey, trigger) {
    this.isSending = true;
    const reqInputs = getTriggerInputs(journey, trigger.name);

    let opts = {
      ccid: this.ccid,
      firstName: this.firstName,
      lastName: this.lastName,
      birthdate: this.getApiValue(this.dateOfBirthFieldName),
      mobilePhone: this.mobilePhone,
      consent: this.getApiValue(this.consentFieldName),
      client_message_tag: this.recordId,
      deactivatePreviousConnections: this.deactivatePreviousConnections,
      ext: this.buildExtParams(),
      input_parameters: this.buildInputParams(reqInputs),
      triggerId: trigger.name,
      triggerNickname: trigger.nickname,
      secondary_account_id: this.getApiValue(this.secondaryAccountIdFieldName)
    }

    if (this.addressStreetFieldName || this.addressCityFieldName || this.addressStateCodeFieldName || this.addressPostalCodeFieldName) {
      opts.address = {};
      if (this.addressStreetFieldName)
        opts.address.address1 =  this.getApiValue(this.addressStreetFieldName);
      if (this.addressCityFieldName)
        opts.address.city = this.getApiValue(this.addressCityFieldName);
      if (this.addressStateCodeFieldName)
        opts.address.state_province = this.getApiValue(this.addressStateCodeFieldName);
      if (this.addressPostalCodeFieldName)
        opts.address.postal_code = this.getApiValue(this.addressPostalCodeFieldName);
    }

    onboarding(userId, opts, this.recordId)
      .then(data => {
        this.isSending = false;
        this.processHttpResponse(data, journey, trigger);
      })
      .catch(err => {
        this.isSending = false;
        this.toastFatalSend(TITLE_NOT_SENT, err.body);
      });
  }

  launchViaMessaging(journey, trigger) {
    this.isSending = true;
    const reqInputs = getTriggerInputs(journey, trigger.name);

    // need to format the Apex call properly
    let req = {
      triggerId: trigger.name,
      ccid: this.ccid,
      body: JSON.stringify({
        client_message_tag: this.recordId,
        input_parameters: this.buildInputParams(reqInputs)
      }),
      triggerNickname: trigger.nickname,
      apiName: this.recordId
    }

    triggerJourney(req) // call to Apex code
      .then(data => {
        this.isSending = false;
        this.processHttpResponse(data, journey, trigger);
      })
      .catch(err => {
        this.isSending = false;
        this.toastFatalSend(TITLE_NOT_SENT, err);
      });
  }

  buildInputParams(reqInputs) {
    let input_parameters = {};
    reqInputs.forEach(t => {
      const nm = `input_${t}`;
      const v = this.getInputFieldValue(t);
      input_parameters[nm] = v.replace(/\n/gi, '<br>');
    })
    return input_parameters;
  }

  buildExtParams() {
    let ext = {};
    this.extFieldNames.forEach(t => {
      ext[t] = this.getApiValue(t);
    })

    return ext;
  }

  getJourney(journeyId) {
    return this.journeys.find(j => j.id === journeyId);
  }

  getTrigger(journeyId, triggerName) {
    let trigger = null;
    const j = this.getJourney(journeyId);
    if (j) {
      trigger = j.live.triggerComponents.find(t => t.name === triggerName);
    }
    return trigger;
  }

  getTriggerIds(journeyId) {
    let tids = [];
    const j = this.getJourney(journeyId);
    if (j) {
      j.live.triggerComponents.forEach(t => tids.push(t.name));
    }
    return tids;
  }

  processHttpResponse(data, journey, trigger) {
    const rsp = JSON.parse(data);
    const body = JSON.parse(rsp.body);
    if (rsp.statusCode === 200) {
      if (this.hasConsentError(body)) {
        if (body && body.mobile_analysis_results ) {
          this.toastWarning('Experience not sent', 'The phone number entered is not associated with a mobile device.');
          return;
        }
        this.toastMessageIsOnItsWay(trigger);
        trigger.isSelected = false;
        this.updateJourneySelectedCount(journey);
        fireEvent(this.pageRef, 'refreshLastTimeSent', trigger.name);        
      } else {
        this.toastWarning(TITLE_NOT_SENT, MSG_NO_CONSENT);
      }
    } else if (rsp.statusCode === 400) {
      let errmsg = 'Unknown error';
      if (!body) {
        errmsg = 'An error occurred sending the experience';
      } else {
        if (body.reason) {
          errmsg = body.reason;
        }
        if (body.error) {
          if (typeof body.error === "object") {
            errmsg = body.error.type || '';
            if (body.error.data) {
              errmsg = errmsg + ' ' + body.error.data.join(',');
            }
          } else {
            errmsg = body.error;
          }
        }
        else {
          errmsg = body.toString();
        }
      }
      this.toastWarning(TITLE_NOT_SENT, errmsg);
    }
  }

  hasConsentError(body) {
    let consent = true;
    if (body && body.notification && body.notification.results) {
      body.notification.results.forEach(r => {
        if (r.status === "no-consent")
          consent = false;
      })
    }
    return consent;
  }

  toastWarning(title, msg) {
    const evt = new ShowToastEvent({
      title,
      message: msg,
      variant: 'warning',
      mode: 'sticky'
    });
    this.dispatchEvent(evt);
  }

  toastMessageIsOnItsWay(trigger) {
    const evt = new ShowToastEvent({
      title: TITLE,
      message: `The "${trigger.nickname}" experience is on its way.`,
      variant: 'success',
      mode: 'dismissable'
    });
    this.dispatchEvent(evt);
  }

  toastFatalSend(title, err) {
    const evt = new ShowToastEvent({
      title,
      message: 'We were unable to contact the Relay system.' + err,
      variant: 'error',
      mode: 'pester'
    });
    this.dispatchEvent(evt);
  }

  toastError(title, msg) {
    const evt = new ShowToastEvent({
      title,
      message: msg,
      variant: 'error',
      mode: 'sticky'
    });
    this.dispatchEvent(evt);
  }

  toastErrorSending(title, msg, trigger) {
    let toastMsg = msg.error || msg.message || '';
    const evt = new ShowToastEvent({
      title,
      message: `There was an error sending the "${trigger.nickname}" experience. ${toastMsg}`,
      variant: 'error',
      mode: 'pester'
    });
    this.dispatchEvent(evt);
  }

  get errorCount() {
    return (!this.errors) ? 0 : this.errors.length;
  }

  get areExperiencesLoaded() {
    return (this.journeys === null) ? false : true;
  }

  /*
  ** Helper Functions
  */
  sortByJourneyName(j1, j2) {
    const name1 = j1.live.name.toLowerCase();
    const name2 = j2.live.name.toLowerCase();
    if (name1 < name2) {
      return -1;
    }
    if (name1 > name2) {
      return 1;
    }
    return 0;
  }

  sortByTriggerNickname(c1, c2) {
    const name1 = c1.nickname.toLowerCase();
    const name2 = c2.nickname.toLowerCase();
    if (name1 < name2) {
      return -1;
    }
    if (name1 > name2) {
      return 1;
    }
    return 0;
  }

  /*
  ** Logging
  */
  logmsg(msg) { this.greeting += ' ' + msg; }
}