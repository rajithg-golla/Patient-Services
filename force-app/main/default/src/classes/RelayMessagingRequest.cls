global class RelayMessagingRequest {

    public RelayMessagingRequest() {
    }

    @AuraEnabled()
    public ID id;

    @AuraEnabled()
    public String ccid;

    @AuraEnabled()
    public String triggerId;

    @AuraEnabled()
    public String clientMessageTag;
}