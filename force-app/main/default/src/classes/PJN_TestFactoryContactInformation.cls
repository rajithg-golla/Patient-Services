/**
* @author Mavens
* @date Jan 2019
* @description Class to provide factory methods to create test data for Contact Information object
* @group TestFactory
*/
@isTest(isParallel=true) public class PJN_TestFactoryContactInformation {
    private class PJN_ContactInformationException extends Exception {}
    private PJN_TestFactorySObject objectFactory;

    public static Map<String, Schema.RecordTypeInfo> ciRecordTypesByName {
        get {
            if (ciRecordTypesByName == null) {
                ciRecordTypesByName = PJN_SObjectUtil.getRecordTypesByDevNameForObject('PJN_Contact_Information__c');
            }
            return ciRecordTypesByName;
        }
        private set;
    }

    public PJN_TestFactoryContactInformation() {
        objectFactory = new PJN_TestFactorySObject('PJN_Contact_Information__c', new Map<String, Object>());
    }

    public PJN_Contact_Information__c constructAddress(Map<String,Object> valuesByField) {
        valuesByField.put('RecordTypeId', ciRecordTypesByName.get('PJN_Address').getRecordTypeId());
        return (PJN_Contact_Information__c) objectFactory.constructSObject(valuesByField);
    }

    public List<PJN_Contact_Information__c> constructManyAddress(Map<String,Object> valuesByField, Integer numberOfAddresses, List<Id> accountIds) {
        List<PJN_Contact_Information__c> addresses = new List<PJN_Contact_Information__c>();
        if(!accountIds.isEmpty() && accountIds.size() > 1 && numberOfAddresses != accountIds.size()) {
            throw new PJN_ContactInformationException('Number of Addresses does not match number of account ids passed.');
        }

        for (Integer index = 0; index < numberOfAddresses; index++) {

            Map<String,Object> newValuesByField = valuesByField;
            if(!accountIds.isEmpty() && accountIds.size() == 1) {
                newValuesByField.put('PJN_Account__c', accountIds[0]);
            } else if(!accountIds.isEmpty() && accountIds.size() > 1) {
                newValuesByField.put('PJN_Account__c', accountIds[index]);
            }

            addresses.add(constructAddress(newValuesByField));
        }

        return addresses;
    }

    public PJN_Contact_Information__c createAddress(Map<String,Object> valuesByField) {
        valuesByField.put('RecordTypeId', ciRecordTypesByName.get('PJN_Address').getRecordTypeId());
        return (PJN_Contact_Information__c) objectFactory.createSObject(valuesByField);
    }

    public PJN_Contact_Information__c constructAddress(
        Id     accountId,
        String line1,
        String line2,
        String city,
        String state,
        String country,
        String postalCode
    ) {
        return new PJN_Contact_Information__c(
            RecordTypeId          = ciRecordTypesByName.get('PJN_Address').getRecordTypeId(),
            PJN_Account__c        = accountId,
            PJN_Address_Line_1__c = line1,
            PJN_Address_Line_2__c = line2,
            PJN_City__c           = city,
            PJN_State__c          = state,
            PJN_Country__c        = country,
            PJN_Postal_Code__c    = postalCode
        );
    }

    public PJN_Contact_Information__c constructEmail(Account parentAccount) {
        PJN_Contact_Information__c email = new PJN_Contact_Information__c(
            PJN_Account__c = parentAccount.Id,
            PJN_Email__c = parentAccount.FirstName + 'email@' + parentAccount.LastName + '.com',
            RecordTypeId = ciRecordTypesByName.get('PJN_Email').getRecordTypeId()
        );

        return email;
    }

    public PJN_Contact_Information__c constructPhone(Account parentAccount) {
        PJN_Contact_Information__c phone = new PJN_Contact_Information__c(
            PJN_Account__c = parentAccount.Id,
            PJN_Phone__c = '5555555555',
            RecordTypeId = ciRecordTypesByName.get('PJN_Phone').getRecordTypeId()
        );

        return phone;
    }


}