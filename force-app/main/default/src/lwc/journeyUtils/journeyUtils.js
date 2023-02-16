import onboardCustomer from '@salesforce/apexContinuation/Relay.onboardCustomer';

const find_dynamicInputs = (s) => {
  return s.match(/@{input_[A-Za-z0-9_\-.]+}/g)
}

const getTriggerInputs = (journey, triggerId) => {

  if (!journey || !journey.live) {
    // No live components
    return [];
  }

  const trigger = journey.live.components.find(c => c.name === triggerId);
  if (!trigger) {
    // trigger not found
    return [];
  }

  const stepPrefix = trigger.step + ".";
  const steps = journey.live.components.filter(c => c.step.startsWith(stepPrefix));
  const inputs = find_dynamicInputs(JSON.stringify(steps));

  if (!inputs) {
    // No dynamic input_ on trigger
    return [];
  }

  const clean = inputs.map(input => { return input.substring(8, input.length - 1) }); // remove input_ from name
  const unique = Array.from(new Set(clean));  // Remove duplicates inputs
  return unique;
}

const reducePhoneNumber = (phoneNumber) => {

  if (phoneNumber === null)
    return '';
  if (phoneNumber.length === 0)
    return phoneNumber;

  const numberPattern = /\d+/g;

  return phoneNumber.match(numberPattern).join('');
}

/*
  userId: ID of the SF user currently logged into the system

  opts: {
    ccid: "",
    firstName: "",
    lastName: "",
    birthdate: "",
    mobilePhone: "",
    consent: "",
    deactivatePreviousConnections: true,
    ext: {},
    input_parameters: {},
    triggerId: "",
    triggerNickname: ""
  }
*/
const onboarding = ( userId, opts, apiName ) => {
  let cust = {
    ccid: opts.ccid,    
    first_name: opts.firstName,
    //middle_name: this.fieldData.MiddleName,
    last_name: opts.lastName,
    date_of_birth: opts.birthdate,
    // ssn_last4: '',   // TODO
    gender: '',
    addresses: [],
    notification_channels: [],
    ext: opts.ext
  }

  if (opts.secondary_account_id)
    cust.secondary_account_id = opts.secondary_account_id;

  if (opts.address) {
    let addr = {};
  
    if (opts.address.address1) {
      addr.address1 = opts.address.address1;
    }
    if (opts.address.city) {
      addr.city = opts.address.city;
    }     
    if (opts.address.state_province) {
      addr.state_province = opts.address.state_province;      
    }
    if (opts.address.postal_code) {
      addr.postal_code = opts.address.postal_code;    
    }
    
    cust.addresses.push(addr);    
  }

  let notification = {
    channel_type: 'sms',
    channel_addr: reducePhoneNumber(opts.mobilePhone),
    consent_type: opts.consent.toLowerCase(),
    country_code: '1'
  }

  cust.notification_channels.push(notification);

  let body = {
    trigger_id: opts.triggerId,
    input_parameters: opts.input_parameters,
    product_group_id: 'default',      // TODO
    deactivate_previous_connections: opts.deactivatePreviousConnections,
    invoke_sync: true,
    customer: cust
  }

  return onboardCustomer({onboardRequest: body, triggerNickname:opts.triggerNickname, apiname:apiName});
}

export { getTriggerInputs, reducePhoneNumber, onboarding };