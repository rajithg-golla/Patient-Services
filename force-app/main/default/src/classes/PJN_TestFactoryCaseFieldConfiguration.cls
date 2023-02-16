/**
* @author Mavens
* @date Jan 2019
* @description Class to provide factory methods to create test data for PJN_Case_Field_Configuration__mdt_Field_Configuration__mdt metadata object
* @group TestFactory
*/
@isTest(isParallel=true) public class PJN_TestFactoryCaseFieldConfiguration {

    private PJN_TestFactorySObject objectFactory;

    public PJN_TestFactoryCaseFieldConfiguration() {
        objectFactory = new PJN_TestFactorySObject('PJN_Case_Field_Configuration__mdt', new Map<String, Object>());
    }

    public PJN_Case_Field_Configuration__mdt construct(Map<String, Object> valuesByField){
        return (PJN_Case_Field_Configuration__mdt) objectFactory.constructSObject(valuesByField);
    }

    public List<PJN_Case_Field_Configuration__mdt> constructMany(Integer numOfRequests, Map<String,Object> valuesByField) {
        return (List<PJN_Case_Field_Configuration__mdt>) objectFactory.constructSObjects(numOfRequests, valuesByField);
    }

    public List<PJN_Case_Field_Configuration__mdt> createCaseFieldsConfigurationDefaulted() {
        List<PJN_Case_Field_Configuration__mdt> configurationList = new List<PJN_Case_Field_Configuration__mdt>();
        configurationList.add(
            new PJN_Case_Field_Configuration__mdt(
                MasterLabel = 'AccountId',
                DeveloperName = 'PJN_Patient',
                MVN_Account_Record_Type__c = 'PJN_Patient',
                PJN_Case_Field_API_Name__c = 'AccountId',
                PJN_Case_Team_Inverse_Role_Mapping__c = 'Caregiver',
                PJN_Case_Team_Role_Mapping__c = 'Patient',
                PJN_Delete_Care_Team_Role_on_change__c = true,
                PJN_Reciprocal_Role__c = 'Patient',
                PJN_Reciprocal_Inverse_Role__c = 'Caregiver',
                PJN_Reciprocal_Role_Case_Field__c = 'AccountId',
                PJN_Reciprocal_Inverse_Role_Case_Field__c = 'PJN_Caregiver__c'
            )
        );
        configurationList.add(
            new PJN_Case_Field_Configuration__mdt(
                MasterLabel = 'Caregiver',
                DeveloperName = 'PJN_Caregiver',
                PJN_Case_Field_API_Name__c = 'PJN_Caregiver__c',
                PJN_Case_Team_Role_Mapping__c = 'Caregiver'
            )
        );
        configurationList.add(
            new PJN_Case_Field_Configuration__mdt(
                MasterLabel = 'Physician',
                DeveloperName = 'PJN_Physician',
                PJN_Case_Field_API_Name__c = 'PJN_Physician__c',
                PJN_Case_Team_Role_Mapping__c = 'Physician'
            )
        );
        configurationList.add(
            new PJN_Case_Field_Configuration__mdt(
                MasterLabel = 'Staff',
                DeveloperName = 'PJN_Staff',
                PJN_Case_Field_API_Name__c = 'PJN_Staff__c',
                PJN_Case_Team_Role_Mapping__c = 'Staff'
            )
        );
        return configurationList;
    }
}