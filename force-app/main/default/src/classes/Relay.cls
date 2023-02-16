public with sharing class Relay {

    // @AuraEnabled(continuation=true cacheable=true)
    // public static Object getNonBreakingSpace() {
    //     String s = '{"msg":"A\uC2A0non-breaking space"}';
    //     return JSON.serialize(s);
    // }

    @TestVisible private static Relay_Network__mdt testMetaData;
    @TestVisible private static ConnState continuationState;
    @TestVisible private static String continuationLabel;

    private static Relay_Network__mdt getSettings() {        
        if (Test.isRunningTest()) {
            return new Relay_Network__mdt(
                Client_ID__c='sf-unit=test', 
                API_Key__c='111-222-333', 
                RelayApiUrl__c='https://sf-unit-test.relayit.com');
        }
        Relay_Network__mdt settings = [SELECT Client_ID__c, API_Key__c, RelayApiUrl__c FROM Relay_Network__mdt limit 1];
        return settings;
    }

    public static Relay_Network__mdt getMetadata() {
        if (testMetaData != null)
            return testMetaData;

        Relay_Network__mdt settings = [SELECT RelayDisableEventConsentTrigger__c,RelayEventsAccountCCIDFieldName__c,
                                                RelayEventsContactCCIDFieldName__c,RelayEventsDisableContactLookup__c, 
                                                RelayEventsDisableAccountLookup__c, RelayMobilePhoneFieldName__c, 
                                                RelayDisableAccountTrigger__c, RelayDisableTaskEventing__c, 
                                                AccountConsentFieldName__c FROM Relay_Network__mdt limit 1];
        return settings;
    }


    @AuraEnabled(continuation=true)
    public static Object triggerJourney(String triggerId, String ccid, String body, String triggerNickname, String apiName) {
        Relay_Network__mdt settings = getSettings();

        // String urlTemplate = 'https://api-dev.relaystaging.com/platform/v3/api/messaging/client/{0}/journey_trigger/{1}/customer/{2}';
        String urlTemplate = '{0}/messaging/client/{1}/journey_trigger/{2}/customer/{3}';
        List<Object> parameters = new List<Object> {settings.RelayApiUrl__c, settings.Client_ID__c, triggerId, ccid};
        String url = String.format(urlTemplate, parameters);

        System.debug(url);

        Continuation con = new Continuation(40);    // 40 second timeout
        con.state = new ConnState( 'trigger', ccid, triggerId, triggerNickname, apiName);
        con.ContinuationMethod = 'processHttpResponse';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('xx-relay-api-key', settings.API_Key__c);
        String dt = System.Now().format();
        if (body != null) {
            // String json = '{"input_parameters" : {"input_rnd" : "' + dt + '"}}';
            req.setBody(body);
        }

        continuationLabel = con.addHttpRequest(req);        

        return con;
    }

    // @future (callout=true)
    public static Integer triggerBatchExperience(String body) {
        Relay_Network__mdt settings = getSettings();

        String urlTemplate = '{0}/messaging/client/{1}/journey_trigger';
        List<Object> parameters = new List<Object> {settings.RelayApiUrl__c, settings.Client_ID__c};
        String url = String.format(urlTemplate, parameters);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('xx-relay-api-key', settings.API_Key__c);
        req.setBody(body);

        HTTP http = new Http();
        HTTPResponse res = http.send(req);

        return res.getStatusCode();
    }

    @future (callout=true)
    public static void triggerBatchExperienceAsync(String body) {
        Relay_Network__mdt settings = getSettings();

        String urlTemplate = '{0}/messaging/client/{1}/journey_trigger';
        List<Object> parameters = new List<Object> {settings.RelayApiUrl__c, settings.Client_ID__c};
        String url = String.format(urlTemplate, parameters);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('xx-relay-api-key', settings.API_Key__c);
        req.setBody(body);

        HTTP http = new Http();
        HTTPResponse res = http.send(req);
        // TODO log error
        // res.getStatusCode();
    }

    @AuraEnabled(continuation=true cacheable=true)
    public static Object getJourneyList(Integer skip, Integer getLimit, String labels) {
        Relay_Network__mdt settings = getSettings();

        String offset = String.valueOf(skip);
		// String urlTemplate = '{0}/messaging/client/{1}/journeys?live_only=true&exclude_deleted=true&limit=100&offset={2}';
		String urlTemplate = '{0}/messaging/client/{1}/journeys?live_only=true&limit={2}&offset={3}';
        
        if ( labels.length() > 0) {
            List<string> l = labels.split('\\|',0);        
            String filterBy = '';
            for (String s : l)
                filterBy = filterBy + '&filter_by=' + EncodingUtil.urlEncode(s, 'UTF-8');
            urlTemplate = urlTemplate + filterBy;
        }

        List<Object> parameters = new List<Object> {settings.RelayApiUrl__c, settings.Client_ID__c, getLimit, offset};
        String url = String.format(urlTemplate, parameters);

        Continuation con = new Continuation(15);    // 15 second timeout
        con.state = new ConnState( 'getJourneyList', null, null, null, null);
        con.ContinuationMethod = 'processHttpResponse';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('xx-relay-api-key', settings.API_Key__c);

        continuationLabel = con.addHttpRequest(req);        

        return con;
    }

    /*
    ** This function returns several of the Relay Package settings to the UI via a JSON string.
    ** The frontend will need to parse the string.
    */
    @AuraEnabled(continuation=true cacheable=true)
    public static Object getRelaySettings() {
        Relay_Network__mdt[] settings = [SELECT ExtFields__c FROM Relay_Network__mdt];

        Relay.RelaySetting rs = new Relay.RelaySetting();
        if ( settings.size() > 0) {
            rs.extFields = settings[0].ExtFields__c;
        }

        return JSON.serialize(rs);
    }

// SELECT CreatedDate FROM RelayEvents__c WHERE RelayCCID__c = '3445' AND Name = 'journey_trigger' AND TriggerID__c = '9c7a47da-05a8-4c68-8c4a-e57ee442003a' ORDER BY CreatedDate
    @AuraEnabled(continuation=true cacheable=false)
    public static String getLastTriggerDate(String ccid, String triggerId) {
        EngagementDates edtm = new EngagementDates();

        try {
            Datetime dt = [SELECT CreatedDate FROM RelayEvents__c WHERE RelayCCID__c = :ccid AND (EventType__c = 'journey_trigger' OR Name = 'Message: Added to wire') AND TriggerID__c = :triggerId ORDER BY CreatedDate DESC NULLS LAST LIMIT 1].CreatedDate;
            edtm.sentDtm = dt.getTime();
        }
        catch (QueryException qe) {
            // not found
        }

        try {
            Datetime dt = [SELECT CreatedDate FROM RelayEvents__c WHERE RelayCCID__c = :ccid AND EventSubType__c = 'auth_link_used' AND TriggerID__c = :triggerId ORDER BY CreatedDate DESC NULLS LAST LIMIT 1].CreatedDate;
            edtm.openedDtm = dt.getTime();
        }
        catch (QueryException qe) {
            // not found
        }

        return JSON.serialize(edtm);
    }

    @AuraEnabled(continuation=true)
    public static Object onboardCustomer(Relay.CustomerOnboard onboardRequest, String triggerNickname, String apiname) {
        Relay_Network__mdt settings = getSettings();

        String urlTemplate = '{0}/cdm/client/{1}/onboard';
        List<Object> parameters = new List<Object> {settings.RelayApiUrl__c, settings.Client_ID__c};
        String url = String.format(urlTemplate, parameters);

        String jsonbody = JSON.serialize(onboardRequest);
        System.debug(jsonbody);

        Continuation con = new Continuation(15);    // 15 second timeout
        con.state = new ConnState( 'trigger', onboardRequest.customer.ccid,
                onboardRequest.trigger_id, triggerNickname, apiname); // TODO triggerNickname
        con.ContinuationMethod = 'processHttpResponse';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('xx-relay-api-key', settings.API_Key__c);
        req.setBody(jsonbody);

        continuationLabel = con.addHttpRequest(req);
        
        return con;
    }

    public static HttpResponse onboard(Relay.CustomerOnboard onboardRequest) {
        Relay_Network__mdt settings = getSettings();

        String urlTemplate = '{0}/cdm/client/{1}/onboard';
        List<Object> parameters = new List<Object> {settings.RelayApiUrl__c, settings.Client_ID__c};
        String url = String.format(urlTemplate, parameters);

        String jsonbody = JSON.serialize(onboardRequest);
        System.debug(jsonbody);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('xx-relay-api-key', settings.API_Key__c);
        req.setBody(jsonbody);

        HTTP http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        return res;
    }

    @future (callout=true)
    public static void onboardAsync(String jsonOnboardRequest) {
        
        String url = '[API_URL]/cdm/client/[CLIENT_ID]/onboard';

        HttpRequest req = getRelayHttpRequest('POST', url, jsonOnboardRequest);

        HTTP http = new Http();
        HTTPResponse res = http.send(req);
        System.debug('onboardAsync statisCode = '+res.getStatusCode());
        System.debug(res.getBody());
    }
    
    // ============
    // Consent APIs
    // ============
    @TestVisible private static HttpRequest getUpdateConsentHttpRequest(String ccid, String mobilePhone, String newConsent) {
        Relay_Network__mdt settings = getSettings();

        if (mobilePhone == null)
            throw new IllegalArgumentException('mobilePhone');

        mobilePhone = mobilePhone.replaceAll('\\D',''); // get rid of everything but the digits!

        System.debug('UpdateConsent: ccid='+ccid+'; mobile='+mobilePhone+'; consent='+newConsent);

        String urlTemplate = '{0}/messaging/client/{1}/consent/channel_addr/{2}/channel_type/sms';
        List<Object> parameters = new List<Object> {settings.RelayApiUrl__c, settings.Client_ID__c, mobilePhone};
        String url = String.format(urlTemplate, parameters);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('PUT');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('xx-relay-api-key', settings.API_Key__c);
        String body = '{ "consent_type" : "'+newConsent.toLowerCase()+'" }';
        req.setBody(body);

        return req;
    }

    @future (callout=true)
    public static void updateConsentAsync(String ccid, String mobilePhone, String newConsent) {
        Http h = new Http();
        HttpRequest req = getUpdateConsentHttpRequest(ccid, mobilePhone, newConsent);
        HttpResponse res = h.send(req);
        System.debug('updateConsentAsync statusCode='+res.getStatusCode());
        System.debug(res.getBody());
    }

    @TestVisible private static String buildConsentUpdateRequest(List<Relay.ConsentUpdate> consentUpdates) {
        Integer batchSize = 0;

        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartObject();
        gen.writeFieldName('batch');
        gen.writeStartArray();
        
        while (!consentUpdates.isEmpty()) {
            Relay.ConsentUpdate cu = consentUpdates.remove(0);

            gen.writeStartObject();
            gen.writeStringField('channel_type', 'sms');
            gen.writeStringField('channel_addr', cu.mobilePhone);
            gen.writeStringField('consent_type', cu.newConsent.toLowerCase());
            gen.writeEndObject();

            if (++batchSize == 200)
                break;
        }
        gen.writeEndArray();
        gen.writeEndObject();

        // return the JSON string
        return gen.getAsString();
    }

    public static HttpResponse updateConsentBatch(List<Relay.ConsentUpdate> consentUpdates) {
        try {
            HttpResponse res = null;
            while (!consentUpdates.isEmpty()) {
                System.debug('updateConsentBatch size = '+consentUpdates.size());
                String body = buildConsentUpdateRequest(consentUpdates);

                Http h = new Http();        
                String url = '[API_URL]/messaging/client/[CLIENT_ID]/consent/bulk';
                HttpRequest req = getRelayHttpRequest('PUT', url, body);
                res = h.send(req);
                System.debug('updateConsentBatchAsync statusCode='+res.getStatusCode());
                System.debug(res.getBody());                
            }
            return res;
        }
        catch (Exception ex)
        {
            System.debug('Error in updateConsentBatch. '+ex.getMessage());
            return null;
        }        
    }

    @future (callout=true)
    public static void updateConsentBatchAsync(String jsonConsentUpdate) {
        try {
            List<Relay.ConsentUpdate> consentUpdates = (List<Relay.ConsentUpdate>)JSON.deserialize(jsonConsentUpdate, List<Relay.ConsentUpdate>.class);
            System.debug('updateConsentBatchAsync: '+consentUpdates.size());
            updateConsentBatch(consentUpdates);            
        }
        catch (Exception ex)
        {
            System.debug('Error in updateConsentBatchAsync. '+ex.getMessage());
        }
    }
    
    public static HttpRequest getRelayHttpRequest(String method, String url, String jsonBody) {
        Relay_Network__mdt settings = getSettings();
         
        url = url.replace('[API_URL]', settings.RelayApiUrl__c).replace('[CLIENT_ID]', settings.Client_ID__c);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('xx-relay-api-key', settings.API_Key__c);
        if (jsonBody != null)
            req.setBody(jsonbody);

        return req;
    }

    @AuraEnabled(continuation=true)
    public static Object processHttpResponse(List<String> labels, Object state) {    
        String lbl = labels[0];
        HttpResponse resp = Continuation.getResponse(lbl);

        String result = resp.getStatus();
        System.debug('HTTP Continuation '+lbl+' - '+result);        

        System.debug('state='+state);
        ConnState connState = (ConnState)state;

        JsHttpResponse jhr = new JsHttpResponse();
        jhr.statusCode = resp.getStatusCode();
        if (connState.method == 'getJourneyList') {
            // For some reason if a Journey has a non-breaking space character C2 0A
            // in the message then the JSON deserializatoin in the Javascirpt side fails
            // so we base64 encode the result which then works fine. Appears to be a bug
            // in the SF translation layer from apex to Javascript
            jhr.bodyBase64 = EncodingUtil.base64Encode(Blob.valueof(resp.getBody()));
        }
        else {
            jhr.body = resp.getBody();
        }

        if (jhr.statusCode == 200) {
            if ( connState.method == 'trigger') { // && state && state.startsWith('trigger|')) {
                try {
                    Datetime dt = Datetime.now();
                    RelayEvents__c re = new RelayEvents__c(
                        Name = 'Sent Experience',
                        EventType__c = 'journey_trigger',
                        RelayCCID__c = connState.ccid,
                        EventTimestamp__c = dt,
                        TriggerID__c = connState.triggerId,
                        TriggerNickname__c = connState.triggerNickname,
                        ClientMessageTag__c = connState.apiName
                    );
                    insert re;
                }
                catch (Exception ex) {
                    System.debug('Error in updateConsentBatch. '+ex.getMessage());  
                }
            }
        }

        String rsp = JSON.serialize(jhr);
        System.debug(rsp);
        return rsp;
    }

    /*
    ** This function supports parsing a dotted field. e.g. 'ReportsTo.FieldName'
    */
    public static Object getField(String fieldName, SObject so) {
        if (!fieldName.contains('.')) {
            return so.get(fieldName);
        }
        else {
            Map<String,Object> pop = so.getPopulatedFieldsAsMap();
            List<String> parts = fieldName.split('\\.');
            while (parts.size() > 1) {
                String e = parts.remove(0);
                so = (SObject)pop.get(e);
                if (so == null) {
                    return null;
                }
                pop = so.getPopulatedFieldsAsMap();
            }
            return so.get(parts.get(0));
            //replace('\n', '<br>')
        }
    }

    /*
    ** Over time these internal classes started to get numerious.
    ** TOOD: Move internal clases to separate cls file.
    */

    class ConnState {
        public String method;
        public String ccid;
        public String triggerId;
        public String triggerNickname;
        public String currentConsent;
        public String previousConsent;
        public String channelAddr;
        public String apiName;
        public ConnState(String method, String newCcid, String newTriggerId, String newTriggerNickName, String apiName) {
            this.method = method;
            this.apiName = apiName;
            this.ccid = newCcid;
            this.triggerId = newTriggerId;
            this.triggerNickname = newTriggerNickname;  
            continuationState = this;          
        }
    }

    class JsHttpResponse {
        public Integer statusCode;
        public String body;
        public String bodyBase64;
    }

    class RelaySetting {
        public String extFields;
        public String relayCCIDFieldName;       // deprecated, no longer used in code
        public String relayConsentFieldName;    // deprecated, no longer used in code
    }

    public with sharing class EngagementDates {
        public Long sentDtm;
        public Long openedDtm;

        public EngagementDates() {
            this.sentDtm = 0;
            this.openedDtm = 0;
        }
    }

    public class BatchExperience {
        private List<SingleExperience> batch;

        public BatchExperience() {
            this.batch = new List<SingleExperience>();
        }

        public void addSingleExperience(SingleExperience se) {
            this.batch.add(se);
        }

        public String getJson() {
            return JSON.serialize(this);
        }
    }

    public class SingleExperience {
        private String trigger_id;
        private String ccid;
        private Map<String,String> input_parameters;

        public SingleExperience(String triggerId, String ccid) {
            this.trigger_id = triggerId;
            this.ccid = ccid;
            this.input_parameters = new Map<String,String>();
        }

        public void addInput(String k, Object v) {
            String s = String.valueOf(v);
            if (s == null) s = '';
            this.input_parameters.put('input_'+k, s);

        }

        public String getJson() {
            return JSON.serialize(this);
        }
    }

    public class Address {
        @AuraEnabled
        public String address1 {
            get {
                return address1;
            }
            set {                
                address1 = value;
            }
        }

        @AuraEnabled
        public String city {
            get {
                return city;
            }
            set {                
                city = value;
            }
        }

        @AuraEnabled
        public String state_province {
            get {
                return state_province;
            }
            set {                
                state_province = value;
            }
        }

        @AuraEnabled
        public String postal_code {
            get {
                return postal_code;
            }
            set {                
                postal_code = value;
            }
        }

        public Address(String address1, String city, String state_province, String postal_code) {
            this.address1 = address1;
            this.city = city;
            this.state_province = state_province;
            this.postal_code = postal_code;
        }

        public Address() {
        }
    }

    public class NotificationChannel {
        @AuraEnabled
        public String channel_addr {
            get {
                return channel_addr;
            }
            set {
                if (value != null)
                    channel_addr = value.replaceAll('\\D','');
                else
                    channel_addr = '';
            }
        }

        @AuraEnabled
        public String channel_type {
            get {
                return channel_type;
            }
            set {
                if (value != null)
                    channel_type = value.toLowerCase();
                else
                    channel_type = 'sms';
            }
        }

        @AuraEnabled
        public String consent_type {
            get {
                return consent_type;
            }
            set {
                if (value != null)
                    consent_type = value.toLowerCase();
                else  
                    consent_type = 'stop';
            }
        }

        @AuraEnabled
        public String country_code {
            get {
                return country_code;
            }
            set {
                country_code = value;
            }
        }

        public NotificationChannel(String addr, String type, String consent) {
            this();
            this.channel_addr = addr;
            this.channel_type = type;
            this.consent_type = consent;
        }

        public NotificationChannel() {
            this.country_code = '1';
        }
    }

    public class Customer {
        @AuraEnabled
        public String first_name{
            get {
                return first_name;
            }
            set {
                first_name = value;
            }
        }
        @AuraEnabled
        public String last_name {
            get {
                return last_name;
            }
            set {
                last_name = value;
            }
        }
        @AuraEnabled
        public String gender {
            get {
                return gender;
            }
            set {
                gender = value;
            }
        }
        @AuraEnabled
        public String ccid {
            get {
                return ccid;
            }
            set {
                ccid = value;
            }
        }
        @AuraEnabled
        public String date_of_birth {
            get {
                return date_of_birth;
            }
            set {
                date_of_birth = value;  //Should be in yyyy/mm/dd format
            }
        }

        @AuraEnabled
        public String secondary_account_id {
            get {
                return secondary_account_id;
            }
            set {
                secondary_account_id = value;
            }
        }
        @AuraEnabled
        public List<NotificationChannel> notification_channels {
            get {
                return notification_channels;
            }
            set {
                notification_channels = value;
            }
        }

        public void addNotificationChannel(NotificationChannel channel) {
            this.notification_channels.add(channel);
        }

        @AuraEnabled
        public List<Address> addresses {
            get {
                return addresses;
            }
            set {
                addresses = value;
            }
        }

        public void addAddress(Address address) {
            if (this.addresses == null) {
                this.addresses = new List<Address>();
            }
            this.addresses.add(address);
        }

        @AuraEnabled
        public Map<String,String> ext {
            get {
                return ext;
            }
            set {
                ext = value;
            }
        }

        public Customer(String ccid, String firstName, String lastName, String gender, Datetime dob) {
            this();
            this.ccid = ccid;
            this.first_name = firstName;
            this.last_name = lastName;
            this.gender = gender;
            if (dob != null)
                this.date_of_birth = dob.format('yyyy-MM-dd');
        }

        public Customer() {
            first_name = '';
            last_name = '';
            date_of_birth = '';
            gender = '';
            ccid = '';
            this.notification_channels = new List<NotificationChannel>();
            this.ext = new Map<String,String>();
        }
    }

    public class LaunchedBy {
        @AuraEnabled public String lb_name {
            get {
                return lb_name;
            }
            private set {
                lb_name = value;
            }
        }

        @AuraEnabled
        public string lb_source{
           get {
               return 'salesforce';
           }
        }

        public LaunchedBy() {
            this.lb_name = UserInfo.getUserEmail();
        }
    }

    public class CustomerOnboard {
        @AuraEnabled public String trigger_id {
            get {
                return trigger_id;
            }
            set {
                trigger_id = value;
            }
        }
        @AuraEnabled
        public String product_group_id {
            get {
                return product_group_id;
            }
            set {
                product_group_id = value;
            }
        }
        @AuraEnabled
        public Boolean deactivate_previous_connections {
            get {
                return deactivate_previous_connections;
            }
            set {
                deactivate_previous_connections = value;
            }
        }
        @AuraEnabled
        public Customer customer {
            get {
                return customer;
            }
            set {
                customer = value;
            }
        }

        private LaunchedBy launched_by;

        @AuraEnabled
        public Map<String,String> input_parameters {
            get {
                return input_parameters;
            }
            set {
                input_parameters = value;
            }
        }

        public void addInput(String k, Object v) {
            String s = String.valueOf(v);
            if (s == null) s = '';
            this.input_parameters.put('input_'+k, s);
        }

        public CustomerOnboard(Customer customer, String triggerId, Boolean deactivatePreviousConnections) {
            this();
            this.product_group_id = 'default';
            this.trigger_id = triggerId;
            this.customer = customer;
            this.deactivate_previous_connections = deactivatePreviousConnections;
            this.input_parameters = new Map<String, String>();
        }

        public CustomerOnboard() {
            this.input_parameters = new Map<String, String>();
            deactivate_previous_connections = true;

            // fill in our Launched by information
            this.launched_by = new LaunchedBy();
        }
    }

    public class ConsentUpdate {
        public String mobilePhone {
            get { return mobilePhone;}
            set {
                if (value != null) {
                    mobilePhone = value.replaceAll('\\D','');   // get rid of everything but the digits
                }
                else {
                    mobilePhone = '';
                }

            }
        }

        public String newConsent {
            get { return newConsent;}
            set {
                if (value == null) {
                    newConsent = 'stop';
                } else {
                    newConsent = value.toLowerCase();
                }
            }
        }

        public String oldConsent {
            get { return oldConsent;}
            set {
                if (value == null) {
                    oldConsent = null;
                } else {
                    oldConsent = value.toLowerCase();
                }

            }
        }

        public ConsentUpdate(String mobilePhone, String newConsent, String oldConsent) {            
            this.mobilePhone = mobilePhone;
            this.newConsent = newConsent;
            this.oldConsent = oldConsent;
        }
    }
}