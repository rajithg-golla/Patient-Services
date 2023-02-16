/**
* @author Mavens
* @date Apr 2019
* @description Mock Provider for MergeToolSetting class
* @group Mock
*/
@isTest(isParallel=true) public with sharing class PJN_MergeToolSettingMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'getAllSettings') {
            return this.getAllSettings();
        } else if (stubbedMethodName == 'getAllSettingsByObjectName'){
            return this.getAllSettingsByObjectName();
        } else {
            return null;
        }
    }

    private Object getAllSettings() {
        List<PJN_Merge_Tool_Setting__mdt> settingList = new List<PJN_Merge_Tool_Setting__mdt>();
        settingList.add(
            new PJN_Merge_Tool_Setting__mdt(
                MasterLabel = 'Prescription',
                DeveloperName = 'PJN_Prescription',
                PJN_Child_SObject_API_Name__c = 'HealthCloudGA__EhrMedicationPrescription__c',
                PJN_Field_API_Name_To_Care_Plan__c = 'PJN_Care_Plan__c',
                PJN_Field_List__c = 'Name, HealthCloudGA__DispenseMedicationCode__c',
                PJN_Order__c = 10
            )
        );
        settingList.add(
            new PJN_Merge_Tool_Setting__mdt(
                MasterLabel = 'Member Plan	',
                DeveloperName = 'PJN_Member_Plan',
                PJN_Child_SObject_API_Name__c = 'PJN_Member_Plan__c',
                PJN_Field_API_Name_To_Care_Plan__c = 'PJN_Care_Plan__c',
                PJN_Field_API_Name_To_Account__c = 'PJN_Patient__c',
                PJN_Field_List__c = 'Name, PJN_Expiration_Date__c',
                PJN_Order__c = 20
            )
        );
        return settingList;
    }

    private Object getAllSettingsByObjectName() {
        Map<String, PJN_Merge_Tool_Setting__mdt> settingMap = new Map<String, PJN_Merge_Tool_Setting__mdt>{
            'HealthCloudGA__EhrMedicationPrescription__c' => new PJN_Merge_Tool_Setting__mdt(
                                                                MasterLabel = 'Prescription',
                                                                DeveloperName = 'PJN_Prescription',
                                                                PJN_Child_SObject_API_Name__c = 'HealthCloudGA__EhrMedicationPrescription__c',
                                                                PJN_Field_API_Name_To_Care_Plan__c = 'PJN_Care_Plan__c',
                                                                PJN_Field_List__c = 'Name, HealthCloudGA__DispenseMedicationCode__c',
                                                                PJN_Order__c = 10
                                                            ),
            'PJN_Member_Plan__c' => new PJN_Merge_Tool_Setting__mdt(
                                        MasterLabel = 'Member Plan	',
                                        DeveloperName = 'PJN_Member_Plan',
                                        PJN_Child_SObject_API_Name__c = 'PJN_Member_Plan__c',
                                        PJN_Field_API_Name_To_Care_Plan__c = 'PJN_Care_Plan__c',
                                        PJN_Field_API_Name_To_Account__c = 'PJN_Patient__c',
                                        PJN_Field_List__c = 'Name, PJN_Expiration_Date__c',
                                        PJN_Order__c = 20
                                    )
        };
        return settingMap;
    }
}