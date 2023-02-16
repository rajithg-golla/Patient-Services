/**
* @author Mavens
* @date Jan 2019
* @description Class to provide factory methods to create test data for Affiliation object
* @group TestFactory
*/
public with sharing class PJN_TestFactoryAffiliation {
    private class PJN_AffiliationException extends Exception {}
    private PJN_TestFactorySObject objectFactory;

    public PJN_TestFactoryAffiliation() {
        objectFactory = new PJN_TestFactorySObject('PJN_Affiliation__c', new Map<String, Object>());
    }

    public PJN_Affiliation__c constructAffiliation(Map<String,Object> valuesByField) {
        return (PJN_Affiliation__c) objectFactory.constructSObject(valuesByField);
    }

    public List<PJN_Affiliation__c> constructManyAffiliations(Map<String,Object> valuesByField, List<Id> parentAccountIds, List<Id> childAccountIds) {
        List<PJN_Affiliation__c> affiliations = new List<PJN_Affiliation__c>();
        if(childAccountIds.size() != 1 && parentAccountIds.size() > 1 && childAccountIds.size() != parentAccountIds.size()) {
            throw new PJN_AffiliationException('Number of parent and child accounts don\'t match.');
        }

        Integer numberOfAffiliations = childAccountIds.size() > parentAccountIds.size() ? childAccountIds.size() : parentAccountIds.size();

        for (Integer index = 0; index < numberOfAffiliations; index++) {

            Map<String,Object> newValuesByField = valuesByField;

            if(parentAccountIds.size() == 1) {
                newValuesByField.put('PJN_Parent_Account__c', parentAccountIds[0]);
            } else {
                newValuesByField.put('PJN_Parent_Account__c', parentAccountIds[index]);
            }

            if(childAccountIds.size() == 1) {
                newValuesByField.put('PJN_Child_Account__c', childAccountIds[0]);
            } else {
                newValuesByField.put('PJN_Child_Account__c', childAccountIds[index]);
            }

            affiliations.add(constructAffiliation(newValuesByField));
        }

        return affiliations;
    }
}