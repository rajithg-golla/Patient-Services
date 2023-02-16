global class RelayOnboardingRequest {
    @AuraEnabled
    public ID id;

    @AuraEnabled()
    public String ccid = '';

    @AuraEnabled()
    public String productGroupId = 'default';

    @AuraEnabled()
    public String consent = '';

    @AuraEnabled()
    public String triggerId = '';

    @AuraEnabled
    public String firstName = '';

    @AuraEnabled
    public String lastName = '';

    @AuraEnabled
    public DateTime dateOfBirth;

    @AuraEnabled
    public String gender = '';

    @AuraEnabled
    public String last4SSN = '';

    @AuraEnabled
    public String mobilePhone = '';

    @AuraEnabled
    public String secondaryAccountId;

    @AuraEnabled
    public String address1;

    @AuraEnabled
    public String city;

    @AuraEnabled
    public String state_province;

    @AuraEnabled
    public String postal_code;

    public RelayOnboardingRequest() {

    }
}