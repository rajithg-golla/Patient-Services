public with sharing class RelayExperienceStatus {
    /* TEST 
		List<String> triggerIds = new List<String>();
		triggerIds.add('3a92cf6e-ee57-475c-b0cc-e150b079d494');
		triggerIds.add('8405a877-8a4f-4aa2-9ecb-bd699b6b4937');
		Map<String, RelayExperienceStatus> restats = RelayExperienceStatus.getExperienceStatus('3445', triggerIds);
		System.debug(restats);
	*/
    
    @AuraEnabled
    public String triggerId {
        get {
            return triggerId;
        }
        private set {
    		triggerId = value;        
        }
    }
    
    @AuraEnabled
    public Long requestSentDtm {
        get {
            return requestSentDtm;
        }
        set {
            if ((value == 0) || (requestSentDtm == 0)) {
                requestSentDtm = value;
            }
        }
    }
    
    @AuraEnabled
    public Long postedDtm {
        get {
            return postedDtm;
		}
        set {
            if ((value == 0) || (postedDtm == 0 && notPostedDtm == 0)) {
	            postedDtm = value;
            }            
        }
	}

    @AuraEnabled
    public Long notPostedDtm {
        get {
            return notPostedDtm;
		}
        set {
            if ((value == 0) || (notPostedDtm == 0 && postedDtm == 0)) {
	            notPostedDtm = value;
                notPostedReason = null;                
            }
        }
	}

    @AuraEnabled
    public string notPostedReason {
        get {
            return notPostedReason;
        }
        private set {
            notPostedReason = value;
        }
    }
    
    @AuraEnabled
    public Long deliveredDtm {
        get {
            return deliveredDtm;
		}
        set {
            if ((value == 0) || (deliveredDtm == 0 && requestSentDtm == 0 && postedDtm == 0 && notPostedDtm == 0)) {
	            deliveredDtm = value;
                undeliveredDtm = 0;                
            }            
        }   
    }
    
    @AuraEnabled
    public Long undeliveredDtm {
        get {
            return undeliveredDtm;
		}
        set {
            if ((value == 0) || (undeliveredDtm == 0 && requestSentDtm == 0 && deliveredDtm == 0 && postedDtm == 0 && notPostedDtm == 0)) {
	            undeliveredDtm = value;
                undeliveredReason = null;
            }            
        } 
    }

    @AuraEnabled
    public string undeliveredReason {
        get {
            return undeliveredReason;
        }
        private set {
            undeliveredReason = value;
        }
    }
    
    @AuraEnabled
    public Long openedDtm {
        get {
            return openedDtm;
		}
        set {
            if (value == 0 || (value > openedDtm))
	            openedDtm = value;
        }      
    }
    
    public RelayExperienceStatus(String triggerId) {
        this.triggerId = triggerId;
        requestSentDtm = postedDtm = notPostedDtm = deliveredDtm = undeliveredDtm = openedDtm = 0L;
    }
    
    /*
     * IMPORTANT!
     * When calling from .js you must pass an object with properties that match the parameter names.
     * If you don't then you will get a server error in the .js code and nothing will be executed on the apex side. 
	 *  e.g. from .js getExperienceStatus({ccid: '', triggerIds:[]});
	 */
    @AuraEnabled(cacheable=false)
    static public List<RelayExperienceStatus> getExperienceStatus(String ccid, List<String> triggerIds) {
        
        List<RelayExperienceStatus> expStatus = new List<RelayExperienceStatus>();        

        try {                        
            List<RelayEvents__c> reEvents  = [SELECT TriggerID__c, EventType__c, EventSubType__c, EventTimestamp__c, ActionValue__c  FROM RelayEvents__c WHERE RelayCCID__c = :ccid 
                AND TriggerID__c in :triggerIds
                AND (EventType__c = 'journey_trigger' OR EventSubType__c in ('delivered','auth_link_used', 'undelivered'))
                ORDER BY TriggerID__c, EventTimestamp__c DESC NULLS LAST];
            System.debug(reEvents.size());         
            
            RelayExperienceStatus reStatus = null;
            
            for (RelayEvents__c revt : reEvents) {     
                System.debug(revt);           
                if ((reStatus == null) || (reStatus.TriggerId != revt.TriggerID__c)) {
                    reStatus = new RelayExperienceStatus(revt.TriggerID__c);
					expStatus.add(reStatus);
                }
				if (revt.EventType__c == 'journey_trigger') {
                    reStatus.requestSentDtm = revt.EventTimestamp__c.getTime();
                    // sentDtm = revt.CreatedDate.getTime();
                }
                if ((revt.EventType__c == 'message') && (revt.EventSubType__c == 'delivered')) {
                    reStatus.postedDtm = revt.EventTimestamp__c.getTime();
                    // sentDtm = revt.CreatedDate.getTime();
                }
                if ((revt.EventType__c == 'message') && (revt.EventSubType__c == 'undelivered')) {
                    reStatus.notPostedDtm = revt.EventTimestamp__c.getTime();
                    reStatus.notPostedReason = revt.ActionValue__c;
                    // sentDtm = revt.CreatedDate.getTime();
                }
                if ((revt.EventType__c == 'notification') && (revt.EventSubType__c == 'delivered')) {
					reStatus.deliveredDtm = revt.EventTimestamp__c.getTime();
//                    smsDeliveredDtm = revt.CreatedDate.getTime();
                }
                if (revt.EventType__c == 'notification' && revt.EventSubType__c == 'undelivered') {
                    reStatus.undeliveredDtm = revt.EventTimestamp__c.getTime();
                    reStatus.undeliveredReason = revt.ActionValue__c;
//                    smsUndeliveredDtm = revt.CreatedDate.getTime();
                }
                if (revt.EventSubType__c == 'auth_link_used') {
					reStatus.openedDtm = revt.EventTimestamp__c.getTime();
//                    openedDtm = revt.CreatedDate.getTime();
                }
            }
        }
        catch (QueryException qe) {
            // not found
        }
        System.debug(expStatus);
        return expStatus;
    }
}