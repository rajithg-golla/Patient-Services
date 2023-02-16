@isTest(isParallel=true) private  class PJN_AccountSearchRqstTest {

    @isTest private static void itShouldReturnPopulatedInfoByObject() {
        PJN_AccountSearchRqst req = new PJN_AccountSearchRqst();
        req.account = new Account(FirstName='Test', LastName='TestLast', PersonEmail=null);
        req.contactInfo = new PJN_Contact_Information__c(PJN_Phone__c='5555555555', PJN_Email__c=null);
        req.isPersonSearch = true;
        req.maxResults = 200;

        Map<String, Object> populatedAccountFields = req.populatedInfoByObject.get('Account');
        System.assert(populatedAccountFields.containsKey('FirstName'));
        System.assert(populatedAccountFields.containsKey('LastName'));
        System.assert(!populatedAccountFields.containsKey('PersonEmail'));

        Map<String, Object> populatedCiFields = req.populatedInfoByObject.get('PJN_Contact_Information__c');
        System.assert(populatedCiFields.containsKey('PJN_Phone__c'));
        System.assert(!populatedCiFields.containsKey('PJN_Email__c'));

    }
}