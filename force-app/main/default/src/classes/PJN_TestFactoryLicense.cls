@isTest(isParallel=true) public class PJN_TestFactoryLicense {
    private class PJN_LicenseException extends Exception {}
    private PJN_TestFactorySObject objectFactory;

    public PJN_TestFactoryLicense() {
        objectFactory = new PJN_TestFactorySObject('PJN_License__c', new Map<String, Object>());
    }

    public PJN_License__c constructLicense(Map<String,Object> valuesByField) {
        return (PJN_License__c) objectFactory.constructSObject(valuesByField);
    }

    public List<PJN_License__c> constructManyLicense(Map<String,Object> valuesByField, Integer numberOfRecords, List<Id> accountIds) {
        List<PJN_License__c> addresses = new List<PJN_License__c>();
        if(!accountIds.isEmpty() && accountIds.size() != 1 && numberOfRecords != accountIds.size()) {
            throw new PJN_LicenseException('Number of Licenses does not match number of account ids passed.');
        }

        for (Integer index = 0; index < numberOfRecords; index++) {

            Map<String,Object> newValuesByField = valuesByField;
            if(!accountIds.isEmpty() && accountIds.size() == 1) {
                newValuesByField.put('PJN_Account__c', accountIds[0]);
            } else if(!accountIds.isEmpty() && accountIds.size() > 1) {
                newValuesByField.put('PJN_Account__c', accountIds[index]);
            }

            addresses.add(constructLicense(newValuesByField));
        }

        return addresses;
    }

    public PJN_License__c createLicense(Map<String,Object> valuesByField) {
        return (PJN_License__c) objectFactory.createSObject(valuesByField);
    }
}