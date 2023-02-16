/**
 * @author      Mavens
 * @group       MissingInformation
 * @description Mock Missing Information Config metadatas for testing
 */
@isTest(isParallel=true)
public with sharing class PJN_MissingInformationConfigMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                    String stubbedMethodName,
                                    Type returnType,
                                    List<Type> listOfParamTypes,
                                    List<String> listOfParamNames,
                                    List<Object> listOfArgs) {
        if(stubbedMethodName == 'queryMissingInfoConfigsByProgramName') {
            return this.queryMissingInfoConfigsByProgramName((String) listOfArgs[0]);
        } else if(stubbedMethodName == 'queryAllMissingInfoConfigs') {
            return this.queryAllMissingInfoConfigs();
        } else {
            return null;
        }
    }

    private Object queryMissingInfoConfigsByProgramName(String programCaseDeveloperName) {
        List<PJN_Missing_Information_Config__mdt> missingInfoConfigs = getAllMissingInfoConfigs(programCaseDeveloperName);
        return missingInfoConfigs;
    }

    private Object queryAllMissingInfoConfigs() {
        List<PJN_Missing_Information_Config__mdt> missingInfoConfigs = getAllMissingInfoConfigs('PJN_CLP');
        return missingInfoConfigs;
    }

    private static List<PJN_Missing_Information_Config__mdt> getAllMissingInfoConfigs(String programCaseDeveloperName) {
        List<PJN_Missing_Information_Config__mdt> missingInfoConfigs = new List<PJN_Missing_Information_Config__mdt>();
        missingInfoConfigs.add(
            new PJN_Missing_Information_Config__mdt(
                MasterLabel = 'Patient Name',
                DeveloperName = 'PJN_Patient_Name',
                PJN_Program__r = new PJN_Program__mdt(
                    MasterLabel = 'Mocked Program',
                    DeveloperName = programCaseDeveloperName
                ),
                PJN_Field_Path__c = 'PJN_Patient_Name__c'
            )
        );
        missingInfoConfigs.add(
            new PJN_Missing_Information_Config__mdt(
                MasterLabel = 'Patient: Address',
                DeveloperName = 'PJN_Patient_Address',
                PJN_Program__r = new PJN_Program__mdt(
                    MasterLabel = 'Mocked Program',
                    DeveloperName = programCaseDeveloperName
                ),
                PJN_Field_Path__c = 'Account.PJN_Primary_Address__c'
            )
        );
        missingInfoConfigs.add(
            new PJN_Missing_Information_Config__mdt(
                MasterLabel = 'Patient: Gender',
                DeveloperName = 'PJN_Patient_Gender',
                PJN_Program__r = new PJN_Program__mdt(
                    MasterLabel = 'Mocked Program',
                    DeveloperName = programCaseDeveloperName
                ),
                PJN_Field_Path__c = 'Account.HealthCloudGA__Gender__pc'
            )
        );
        return missingInfoConfigs;
    }
}