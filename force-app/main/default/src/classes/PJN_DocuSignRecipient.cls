public with sharing class PJN_DocuSignRecipient {
    private String recipientType;
    public Map<String, String> fieldValuePairs;
    public class PJN_DocuSignRecipientException extends Exception {}

    public PJN_DocuSignRecipient(String type) {
        this.recipientType = type;
        this.fieldValuePairs = new Map<String,String> {
            'AccessCode' => '',
            'Email' => '',
            'FirstName' => '',
            'LastName' => '',
            'RecipientNote' => '',
            'Role' => '',
            'RoutingOrder' => '',
            'SignInPersonName' => '',
            'SignNow' => '',
            'SMSAuthPhone' => ''
        };
    }

    public String getFormattedString() {
        System.debug(this.fieldValuePairs);
        if (this.recipientType == 'Calling Individual') {
            if (fieldValuePairs.get('Email') == '') {
                throw new PJN_DocuSignRecipientException(Label.PJN_D1C_Email_Param_Required);
            }
            return 'Email~' + encode('Email') + ';'
                + 'FirstName~'+ encode('FirstName') + ';'
                + 'LastName~'+ encode('LastName') + ';'
                + 'Role~'+ encode('Role') + ';'
                + 'SignInPersonName~'+ encode('SignInPersonName') + ';'
                + 'RoutingOrder~'+ encode('RoutingOrder') + ';'
                + 'AccessCode~'+ encode('AccessCode') + ';'
                + 'SMSAuthPhone~'+ encode('SMSAuthPhone') + ';'
                + 'RecipientNote~'+ encode('RecipientNote') + ';'
                + 'SignNow~'+ encode('SignNow');
        }

        if (this.recipientType == 'Signing Group') {
            if (fieldValuePairs.get('SigningGroup') == '') {
                throw new PJN_DocuSignRecipientException(Label.PJN_D1C_Signing_Group_Param_Required);
            }
            return 'SigningGroup~' + encode('SigningGroup') + ';'
                + 'Role~'+ encode('Role') + ';'
                + 'RoutingOrder~'+ encode('RoutingOrder') + ';'
                + 'AccessCode~'+ encode('AccessCode') + ';'
                + 'RecipientNote~'+ encode('RecipientNote');
        }

        return '';
    }

    private String encode(String key) {
        return EncodingUtil.urlEncode(fieldValuePairs.get(key), 'UTF-8');
    }
}