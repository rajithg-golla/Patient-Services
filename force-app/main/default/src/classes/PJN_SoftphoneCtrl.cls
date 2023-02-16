public with sharing class PJN_SoftphoneCtrl {
    public Id newCaseId {get; private set;}
    public String phone {get; private set;}

    public void doAction() {
        phone = ApexPages.currentpage().getparameters().get('c__phone');
        if (String.isBlank(phone)) {
            phone = ApexPages.currentpage().getparameters().get('phone');
        }
        Id requestRecTypeId = SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('PJN_Request')
            .getRecordTypeId();

        Case newCase = new Case(
            OwnerId = UserInfo.getUserId(),
            Subject = 'Inbound Call',
            HealthCloudGA__DueDate__c = Date.today(),
            RecordTypeId = requestRecTypeId,
            Type = 'Inbound',
            Origin = 'Phone'
        );

        insert newCase;
        newCaseId = newCase.Id;
    }
}