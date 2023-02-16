public with sharing class RelayUpdateConsentFromPhone implements Queueable, Database.AllowsCallouts {
        private List<Relay.ConsentUpdate> consentUpdates;
    
        public RelayUpdateConsentFromPhone(List<Relay.ConsentUpdate> batch) {
            this.consentUpdates = batch;
        }
    
        public void execute(QueueableContext context) {
            Relay_Network__mdt settings = Relay.getMetadata();

            String accountConsentFieldName = null;

            if (settings.AccountConsentFieldName__c != null) {
                accountConsentFieldName = settings.AccountConsentFieldName__c;
            }
            
            // Locate the Relay field names from the Account object
            Set<String> accountFields = Schema.SObjectType.Account.fields.getMap().keySet();
            for (String f : accountFields) {
                if (accountConsentFieldName == null && f.startsWithIgnoreCase('relayconsent')) {
                    accountConsentFieldName = f;
                }
            }

            Integer soslCount = 0;
            List<Account> accountsToUpdate = new List<Account>();
            List<Id> dupCheck = new List<Id>();

            while (consentUpdates.size() > 0) {
                Relay.ConsentUpdate consentUpdate = consentUpdates.remove(0);
                try {            
                    String phone = consentUpdate.mobilePhone;
                    if (phone.length() > 10)
                        phone = phone.substring(1);

                    String query = 'FIND \''+phone+'\' IN PHONE FIELDS RETURNING Account('+accountConsentFieldName+')';
                    List<List<SObject>> data = search.query(query);
                    List<Account> accounts = data[0];
                    
                    if (accounts.size() > 0) {
                        for (Account acct : accounts ) {
                            try {
                                String consent = (String)acct.get(accountConsentFieldName);
                                System.debug(consent+' -> '+consentUpdate.newConsent);
                                if ((consent == null) || (consentUpdate.newConsent.equalsIgnoreCase(consent) == false)) {                                    
                                    if (!dupCheck.contains(acct.Id)) {
                                        acct.put(accountConsentFieldName, consentUpdate.newConsent);
                                        accountsToUpdate.add(acct);
                                        dupCheck.add(acct.Id);
                                    }
                                }
                            }
                            catch (Exception ex) {
                                System.debug(LoggingLevel.ERROR, 'Exception enumerating through Accounts');
                            }
                        }
                        if (accountsToUpdate.size() > 100) {
                            break;
                        }
                    }  

                    if (++soslCount == 20)
                        break;  // we hit our limit per transaction
                }
                catch (Exception ex) {
                    System.debug(LoggingLevel.ERROR, 'Error looking up mobile phone in Account');            
                }
            }

            if (accountsToUpdate.size() > 0) {
                Database.SaveResult[] srList = Database.update(accountsToUpdate, false);

                // Iterate through each returned result
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess() == false) {
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {
                            System.debug(LoggingLevel.ERROR, err.getStatusCode() + ': ' + err.getMessage());
                        }
                    }
                }
            }

            if (consentUpdates.size() > 0) {
                System.debug('split update consent from phone job');
                System.enqueueJob(new RelayUpdateConsentFromPhone(consentUpdates));
                return;
            }
        }
    }