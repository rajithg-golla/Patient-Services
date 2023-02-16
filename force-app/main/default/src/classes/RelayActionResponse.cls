public class RelayActionResponse {
    @AuraEnabled @InvocableVariable public Integer responseCode;
    @AuraEnabled @InvocableVariable public String responseMessage;

    public RelayActionResponse(Integer code, String message) {
        this.responseCode = code;
        this.responseMessage = message;
    }
}