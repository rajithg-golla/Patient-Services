/**
* @author Mavens
* @date Feb 2019
* @description Class to provide factory methods to create test data for PJN_File_Rollup_Setting__mdt metadata object
* @group TestFactory
*/
@isTest(isParallel=true) public class PJN_TestFactoryFileRollupSetting {

    private PJN_TestFactorySObject objectFactory;

    public PJN_TestFactoryFileRollupSetting() {
        objectFactory = new PJN_TestFactorySObject('PJN_File_Rollup_Setting__mdt', new Map<String, Object>());
    }

    public PJN_File_Rollup_Setting__mdt construct(Map<String, Object> valuesByField){
        return (PJN_File_Rollup_Setting__mdt) objectFactory.constructSObject(valuesByField);
    }

    public List<PJN_File_Rollup_Setting__mdt> constructMany(Integer numOfRequests, Map<String,Object> valuesByField) {
        return (List<PJN_File_Rollup_Setting__mdt>) objectFactory.constructSObjects(numOfRequests, valuesByField);
    }

    public List<PJN_File_Rollup_Setting__mdt> createFileRollupSettingDefaulted() {
        List<PJN_File_Rollup_Setting__mdt> settingList = new List<PJN_File_Rollup_Setting__mdt>();
        settingList.add(
            new PJN_File_Rollup_Setting__mdt(
                MasterLabel = 'Case',
                DeveloperName = 'PJN_Case',
                PJN_sObject_API_Name__c = 'Case',
                PJN_Parent_Lookup_Field_API_Name__c = 'ParentId'
            )
        );
        return settingList;
    }
}