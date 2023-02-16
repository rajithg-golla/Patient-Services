/*
** We are only concerned about updates because an insert implies they are not in Relay yet.
*/
trigger RelayAccountTrigger on Account (after update) {
  // Note, updates could be happening before they are onboarded to Relay. Im this case we will ignore the error

  String relayMobilePhoneFieldName = 'MobilePhone';
  String consentFieldName = null;

  Relay_Network__mdt settings = Relay.getMetadata();

  if (settings.RelayDisableAccountTrigger__c == true) {      
    return;
  }
  if (settings.RelayMobilePhoneFieldName__c != null) {
    relayMobilePhoneFieldName = settings.RelayMobilePhoneFieldName__c;
  }
  if (settings.AccountConsentFieldName__c != null) {
    consentFieldName = settings.AccountConsentFieldName__c;
  }

  
  String consent = null;
  String mobilePhoneFieldName = null;
  String mobilePhone = null;

  // Locate the Relay fields
  Account tempacct = (Account)Trigger.new[0];
  System.debug('userId: '+UserInfo.getUserId());  
  System.debug('isBatch='+System.isBatch()+' isQueueable()='+System.isQueueable());
  Set<String> fieldNames = tempacct.getPopulatedFieldsAsMap().keySet();

  for (String f: fieldNames) {    
    if (consentFieldname == null && f.startsWithIgnoreCase('RelayConsent__')) {
      consentFieldName = f;      
    } else if (f.startsWithIgnoreCase(relayMobilePhoneFieldName)) { 
      mobilePhoneFieldName = f;      
    }
  }
    
  if (consentFieldName == null || mobilePhoneFieldName == null ) {
    System.debug('Missing Relay Fields');
    return;
  }

  List<Relay.ConsentUpdate> batchUpdate = new List<Relay.ConsentUpdate>();

  // The trigger may contain updates for more than one record
  for (SObject c : Trigger.new) {

    consent = (String)c.get(consentFieldName);               
    mobilePhone = (String)c.get(mobilePhoneFieldName);
    	  
    if (mobilePhone == null) {
      System.debug('mobile phone field is empty for '+c.id);      
    } 
    else {
      SObject oldC = Trigger.oldMap.get(c.Id);
      String oldPhone = (String)oldC.get(mobilePhoneFieldName);
      if (oldC != null) {
        Boolean sameConsent = consent.equalsIgnoreCase((String)oldC.get(consentFieldName));
        Boolean sameMobile = mobilePhone.equalsIgnoreCase((String)oldC.get(mobilePhoneFieldName));

        if (!sameConsent || !sameMobile) {        
          // Send Consent change to Relay
          // if (Test.isRunningTest()) {
          //   System.debug('inTest: consent='+consent+' mobile='+mobilePhone);
          // } 
          // else {
              batchUpdate.add(new Relay.ConsentUpdate(mobilePhone, consent, (String)oldC.get(consentFieldName) ));
          // }
        }
      }
    }
  }
  
  if (batchUpdate.size() > 0) {    
    System.debug('batch size='+batchUpdate.size());
    if (System.isQueueable()) {
      String str = JSON.serialize(batchUpdate);
      Relay.updateConsentBatchAsync(str);    
    } else {
      try {
        RelayUpdateConsent ruc = new RelayUpdateConsent(batchUpdate);
        ID jobId = System.enqueueJob(ruc);
        System.debug('batch consent update jobId='+jobId);
      } catch (Exception ex) {
        System.debug('Failed to enqueue Batch consent update. '+ex.getMessage()); 
      }
    }    
  }
}