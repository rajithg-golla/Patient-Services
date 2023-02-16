global class RelayOnboardingAction {

    // @InvocableMethod(label='Relay Onboard Customer' configurationEditor='c-relay-onboarding-editor')
    @InvocableMethod(label='Relay Onboard Customer')
    public static List<RelayActionResponse> onboardCustomer(List<RelayOnboardActionRequest> requests) {

        List<RelayActionResponse> results = new List<RelayActionResponse>();

        for (RelayOnboardActionRequest req : requests) {
            if (req.dynamicInputFieldNames == null) {
                req.dynamicInputFieldNames = new List<String>();
            }
            results.add( processSingleRequest(req) );
        }
        return results;
    }

    private static RelayActionResponse processSingleRequest(RelayOnboardActionRequest req) {
        Map<ID,RelayOnboardingRequest> msgMap = new Map<ID,RelayOnboardingRequest>();
    
        List<RelayOnboardingRequest> msgbatch = req.batchRequest;
        if (msgbatch == null) {
            if (req.singleRequest == null)
                return new RelayActionResponse(500, 'Missing batch or single onboard request');
            msgbatch = new List<RelayOnboardingRequest>();
            msgbatch.add(req.singleRequest);
        }

        List<SObject> dataRows = new List<SObject>();        
        if (req.dynamicInputFieldNames != null && !req.dynamicInputFieldNames.isEmpty()) {
            // If we have just a list of dynamic input field names, 
            // then we have to make a SOQL to get the actual field data associated 
            // with the dynamic input name
            List<ID> ids = new List<ID>();

            for( RelayOnboardingRequest onboardReq: msgbatch) {
                System.debug(onboardReq);
                ids.add(onboardReq.id);
            }
            for( Integer i = 0; i < msgbatch.size(); i++) {
                RelayOnboardingRequest onboardReq = msgbatch.get(i);
    
                msgMap.put(onboardReq.id, onboardReq);
            }

            String apiname = ids.get(0).getSObjectType().getDescribe().getName();
            String fieldList = buildFieldList(req);
            String whereClause = buildWhereClause(ids);
            String query = 'SELECT '+ fieldList +' FROM ' + String.escapeSingleQuotes(apiname) + ' WHERE id in (' + whereClause + ')';

            System.debug(query);            
            dataRows  = Database.query(query);
        }

        Integer responseCode = 500;
        String responseMsg = '';

        // TODO implement batch onboarding            
        for( RelayOnboardingRequest onboardReq: msgbatch) {
            
            // If the individual request does not specify a trigger ID,
            // then use the default trigger id passed in with the request.
            String triggerId = onboardReq.triggerId;
            if (triggerId == '') {
                triggerId = req.triggerId;
            }

            Relay.Customer cust = new Relay.Customer(onboardReq.ccid, onboardReq.firstName, onboardReq.lastName,
                    onboardReq.gender, onboardReq.dateOfBirth);
            Relay.NotificationChannel nc = new Relay.NotificationChannel(onboardReq.mobilePhone, 'sms', onboardReq.consent);
            cust.addNotificationChannel(nc);

            if (onboardReq.secondaryAccountId != null) { 
                cust.secondary_account_id = onboardReq.secondaryAccountId;
            }

            if (req.extData != null && !req.extData.isEmpty()) {
                // convert List to Map
                Map<String,String> extdata = new Map<String,String>();
                For (RelayDynamicInput rdi: req.extData) {
                    extData.put(rdi.inputName, rdi.inputValue);
                }
                cust.ext = extData;                    
            }

            // see if we have any address fields populated
            if ( (onboardReq.address1 != null) || (onboardReq.city != null) || (onboardReq.state_province != null) || (onboardReq.postal_code != null) ){
                System.debug('Adding Address');
                Relay.Address addr = new Relay.Address();
                if ( onboardReq.address1 != null) {
                    addr.address1 = onboardReq.address1;
                }
                if (onboardReq.city != null) {
                    addr.city = onboardReq.city;
                }
                if (onboardReq.state_province != null) {
                    addr.state_province = onboardReq.state_province;
                } 
                if (onboardReq.postal_code != null) {
                    addr.postal_code = onboardReq.postal_code;
                }
                cust.addAddress(addr);
            }

            Relay.CustomerOnboard custonboard = new Relay.CustomerOnboard(cust, triggerId, req.deactivatePreviousConnections);

            if ( onboardReq.productGroupId != null) {
                custonboard.product_group_id = onboardReq.productGroupId;
            }
            
            if (!req.dynamicInputFieldNames.isEmpty()) {
                for (SObject so: dataRows) {
                    if (so.id == onboardReq.id) {
                        for (String nm : req.dynamicInputFieldNames) {
                            Object o = Relay.getField(nm, so);
                            custonboard.addInput(nm, o);
                        }                                
                        break;
                    }
                }
            }

            if (req.dynamicInputs != null) {
                for (RelayDynamicInput di : req.dynamicInputs) {
                    custonboard.addInput(di.inputName, di.inputValue);
                }
            }
               
            if (req.useFuture != null && req.useFuture) {
                Relay.onboardAsync(JSON.serialize(custonboard));
                responseCode = 202;
                responseMsg = 'Request accepted';
            }
            else {
                HttpResponse res = Relay.onboard(custonboard);
                responseCode = res.getStatusCode();
                responseMsg = res.getBody();
            }
        }

        return new RelayActionResponse(responseCode, responseMsg);
    }

    private static String buildFieldList(RelayOnboardActionRequest req) {
        List<String> quotedList = new List<String>();

        quotedList.add('id');

        if (req.dynamicInputFieldNames != null) {
            for( String nm: req.dynamicInputFieldNames) {
                quotedList.add(nm);
            }
        }

        return String.join(quotedList, ',');
    }

    private static String buildWhereClause(List<ID> idCollection) {
        List<String> quotedList = new List<String>();
        for (ID id: idCollection)
            quotedList.add('\''+ id +'\'');
        return String.join(quotedList, ',');
    }
}