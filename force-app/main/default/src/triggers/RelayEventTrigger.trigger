Trigger RelayEventTrigger on RelayEvents__c (before insert) {

    // Read settings to see if any options are disabled
    Relay_Network__mdt settings = Relay.getMetadata();
    // Relay_Network__mdt[] settings = [SELECT RelayDisableEventConsentTrigger__c,RelayEventsAccountCCIDFieldName__c,
    //                                         RelayEventsContactCCIDFieldName__c,RelayEventsDisableContactLookup__c, 
    //                                         RelayEventsDisableAccountLookup__c FROM Relay_Network__mdt];

    Boolean disableEventConsentTrigger = false;
    Boolean disableAccountLookup = false;
    Boolean disableContactLookup = false;
    String accountCcidField = null;
    String contactField = null;    

    disableEventConsentTrigger = settings.RelayDisableEventConsentTrigger__c;
    accountCcidField = settings.RelayEventsAccountCCIDFieldName__c;
    contactField = settings.RelayEventsContactCCIDFieldName__c;
    disableAccountLookup = settings.RelayEventsDisableAccountLookup__c;
    disableContactLookup = settings.RelayEventsDisableContactLookup__c;
    System.debug('RelayDisableEventConsentTrigger__c='+disableEventConsentTrigger);

    // Locate the Relay field names from the Contact object
    if (contactField == null && !disableContactLookup) {
        System.debug('contactField not set in settings');
        Set<String> contactFields = Schema.SObjectType.Contact.fields.getMap().keySet();    
        String contactQuery = null;
        for (String f : contactFields) {
            if (f.startsWithIgnoreCase('relayccid')) {
                contactField = f;
            }
        }
    }

    // Locate the Relay field names from the Account object
    Set<String> accountFields = Schema.SObjectType.Account.fields.getMap().keySet();        
    String accountQuery = null;
    for (String f : accountFields) {
        if (accountCcidField == null) {
            if (f.startsWithIgnoreCase('relayccid')) {
                accountCcidField = f;
            }
        }

    }

    System.debug('contact field:'+contactField+' account field: '+accountCcidField);

    //
    // Time to start processing the list of records
    //
    List<String> ccids = new List<String>();
    List<Account> accts = null;
    List<Contact> cc = null;
    List<CaseComment> caseComments = new List<CaseComment>();
    List<Relay.ConsentUpdate> consentUpdates = new List<Relay.ConsentUpdate>(); 
    
    for (RelayEvents__c e : Trigger.new) {        
        if (e.RelayCCID__c != null)
            ccids.add(e.RelayCCID__c);

        // split action event into two fields
        if (e.EventSubType__c != null && e.EventSubType__c.startsWithIgnoreCase('action_')) {
            e.EventType__c = 'action';
            e.EventSubType__c = e.EventSubType__c.substringAfter('action_');
        }   

        // See if we need to queue up consent changes
        if (!disableEventConsentTrigger) {            
            if (e.EventType__c == 'channel_consent' && e.EventSubType__c == 'update' && e.ChannelAddr__c != null) {
                String phone = e.ChannelAddr__c;
                if (phone.length() > 10)
                    phone = phone.substring(1);

                Relay.ConsentUpdate rcu = new Relay.ConsentUpdate(phone, e.CurrentConsent__c, e.PreviousConsent__c);
                consentUpdates.add(rcu);
            }
        }        
    }

    // Execute up to two batch queries
    if (ccids.size() > 0) {
        
        if ((disableContactLookup == false) && (contactField != null)) {
            String contactQuery = '';
            if (ccids.size() == 1) {
                String ccid = ccids[0];                
                contactQuery = 'SELECT Name,'+contactField+' FROM Contact where '+contactField+' = :ccid';
            }
            else {                
                contactQuery = 'SELECT Name,'+contactField+' FROM Contact where '+contactField+'  in :ccids';
            }
            try {
                cc = Database.query(contactQuery);
            }
            catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, ex.getMessage()); 
                cc = null;
            }
        }

        if ((disableAccountLookup == false) && (accountCcidField != null)) {
            String accountQuery = '';
            if (ccids.size() == 1) {
                String ccid = ccids[0];                
                accountQuery = 'SELECT Name,'+accountCcidField+' FROM Account where '+accountCcidField+' = :ccid';
            } else {                
                accountQuery = 'SELECT Name,'+accountCcidField+' FROM Account where '+accountCcidField+' in :ccids';
            }
            try {
                accts = Database.query(accountQuery);
            }
            catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, ex.getMessage()); 
                accts = null;
            }
        }        
    }

    // Next, let's try and fill in the related Account and Contact fields
    // Note: Depending on the org config they may not be found and that is ok
    for ( RelayEvents__c e : Trigger.new) {
        String eventCCID = e.RelayCCID__c;

        if (ccids.size()  > 0) {
            if ((accts != null) && (eventCCID != null) && (accountCcidField != null)) {
                for (Account a : accts) {
                    String ccid = (String)a.get(accountCcidField);
                    if (ccid != null && eventCCID == ccid) {
                        e.Account__c = a.id;
                        break;
                    }
                }
            }

            if ((cc != null) && (eventCCID != null) && (contactField != null)) {
                system.debug('populating Contact__c');
                for (Contact c : cc) {
                    String ccid = (String)c.get(contactField);
                    if (ccid != null && eventCCID == ccid) {
                        system.debug('match '+c.id);
                        e.Contact__c = c.id;
                        break;
                    }
                }
            }
        }

        // Optionally insert a new Case Comment
        //    1. The EventType__c must be 'journey_trigger'
        //    2. The ClientMessageTag__c field must contain a valid Case object ID
        if (e.ClientMessageTag__c != null && e.ClientMessageTag__c.length() > 0) {
            try {
                Id id = e.ClientMessageTag__c;      // may throw an exception and this is expected         
                if (e.EventType__c == 'journey_trigger' && id.getSObjectType().getDescribe().getName() == 'Case') {
                    CaseComment c = new CaseComment();
                    c.ParentId = e.ClientMessageTag__c;
                    c.CommentBody = 'Sent Relay Experience: '+e.TriggerNickname__c;
                    caseComments.add(c);                
                }
            }
            catch (Exception ex) {
                // Not all ClientMessageTag__c field values will contain a valid Salesforce IDs so an exception may be thrown
                System.debug(LoggingLevel.ERROR, ex.getMessage()); 
            }
        }
    }

    // Batch update Case Comments (if we have any)
    if (caseComments.size() > 0) {
        Database.SaveResult[] results = Database.insert(caseComments, false);
         
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess() == false) {
                // Operation failed, so log all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug(LoggingLevel.ERROR, err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }
    }

    // Create Job to update Consents
    if (consentUpdates.size() > 0) {
        RelayUpdateConsentFromPhone ruc = new RelayUpdateConsentFromPhone(consentUpdates);
        ID jobId = System.enqueueJob(ruc);
        System.debug('RelayEvents Consent update jobId='+jobId);    
    }
}