public with sharing class RelayMessageAction {

    @InvocableMethod
    public static List <RelayActionResponse> execute (List<RelayMessageActionRequest> requestList) {

        System.debug('start');
        List<RelayActionResponse> results = new List<RelayActionResponse>();
        for (RelayMessageActionRequest req: requestList) {

            if (req.dynamicInputFieldNames == null) {
                req.dynamicInputFieldNames = new List<String>();
            }
            if (req.batchRequest == null) {
                req.batchRequest = new List<RelayMessagingRequest>();
            }
            if (req.singleRequest != null) {
                req.batchRequest.add(req.singleRequest);
            }
            results.add( processSingleRequest(req) );
        }
        System.debug('end');

        return results;
    }

    private static RelayActionResponse processSingleRequest(RelayMessageActionRequest req) {
        Map<ID,RelayMessagingRequest> msgMap = new Map<ID,RelayMessagingRequest>();
        List<ID> ids = new List<ID>();

        List<RelayMessagingRequest> msgbatch = req.batchRequest;
        System.debug(msgbatch);

        for( Integer i = 0; i < msgbatch.size(); i++) {
            RelayMessagingRequest msgReq = msgbatch.get(i);
            System.debug(msgReq);

            msgMap.put(msgReq.id, msgReq);
            ids.add(msgReq.id);
        }

        if (ids.isEmpty()) {
            return new RelayActionResponse(500, 'No record ids');
        }

        String apiname = ids.get(0).getSObjectType().getDescribe().getName();

        String fieldList = buildFieldList(req);
        String whereClause = buildWhereClause(ids);
        String query = 'SELECT '+ fieldList +' FROM ' + String.escapeSingleQuotes(apiname) + ' WHERE id in (' + whereClause + ')';

        System.debug(query);

        Integer responseCode = 500;
        String responseMsg = 'unknown error';

        List<SObject> data  = Database.query(query);
        if (!data.isEmpty()) {
            Relay.BatchExperience batch = new Relay.BatchExperience();
            for (SObject so: data) {
                // Relay.SingleExperience exp = new Relay.SingleExperience(req.triggerId, (String)so.get(req.relayCcidFieldName));
                RelayMessagingRequest msgReq = msgMap.get(so.id);
                
                // If the request does not specify a trigger ID,
                // then use the default trigger id passed in.
                String triggerId = msgReq.triggerId;
                if (triggerId == '' || triggerId == null) {
                    triggerId = req.triggerId;
                }
                Relay.SingleExperience exp = new Relay.SingleExperience(req.triggerId, msgReq.ccid);
                for (String nm : req.dynamicInputFieldNames) {
                    Object o = Relay.getField(nm, so);
                    exp.addInput(nm, o);
                }
                batch.addSingleExperience(exp);
            }
            String str = batch.getJson();
            System.debug(str);
            if (req.useFuture) {
                Relay.triggerBatchExperienceAsync(str);
                responseCode = 202;
                responseMsg = 'Message accepted and will be sent in future';
            }
            else {
                responseCode = Relay.triggerBatchExperience(str);
            }
        } else {
            responseCode = 200;
            responseMsg = 'No record found, nothing to do';
        }

        return new RelayActionResponse(responseCode, responseMsg);
    }

    /*
    ** This function supports parsing a dotted field. e.g. 'ReportsTo.FieldName'
    */
    // private static Object getField(String fieldName, SObject so) {
    //     if (!fieldName.contains('.')) {
    //         return so.get(fieldName);
    //     }
    //     else {
    //         Map<String,Object> pop = so.getPopulatedFieldsAsMap();
    //         List<String> parts = fieldName.split('\\.');
    //         while (parts.size() > 1) {
    //             String e = parts.remove(0);
    //             so = (SObject)pop.get(e);
    //             if (so == null) {
    //                 return null;
    //             }
    //             pop = so.getPopulatedFieldsAsMap();
    //         }
    //         return so.get(parts.get(0));
    //     }
    // }

    private static String buildFieldList(RelayMessageActionRequest req) {
        List<String> quotedList = new List<String>();

        quotedList.add('id');
        // quotedList.add(req.relayCcidFieldName);

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