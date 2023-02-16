/**
* @author Mavens
* @description Mocks for RBM Sharing Settings Query
* @group RBM
*/
public with sharing class MVN_RBMSharingSettingsQueryMock implements System.StubProvider{

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {

        if (stubbedMethodName == 'forProgramTherapyStatusMap') {
            List<MVN_RBM_Sharing_Setting__mdt> settings = new List<MVN_RBM_Sharing_Setting__mdt>();
            settings.add(
                new MVN_RBM_Sharing_Setting__mdt(
                    DeveloperName = 'Therapy_Cancelled_Patient_Deceased',
                    MVN_Days_Visible__c = 180,
                    MVN_Status__c = 'Cancelled',
                    MVN_Sub_Status__c = 'Patient Deceased',
                    MVN_Type__c = 'Therapy',
                    MVN_Program_Name__c = 'MVN_EVK'
                )
            );
            System.debug('Mock returning settings for therapy map');
            return settings; 
        } else if (stubbedMethodName == 'forProgramPharmacyStatusMap') {
            List<MVN_RBM_Sharing_Setting__mdt> settings = new List<MVN_RBM_Sharing_Setting__mdt>();
            settings.add(
                new MVN_RBM_Sharing_Setting__mdt(
                    DeveloperName = 'Unknown',
                    MVN_Days_Visible__c = 180,
                    MVN_Status__c = 'Unknown',
                    MVN_Sub_Status__c = '',
                    MVN_Type__c = 'Pharmacy',
                    MVN_Program_Name__c = 'MVN_EVK'
                )
            );
            System.debug('Mock returning settings for pharmacy map');
            return settings;
        }

        System.debug('Mock returning null');
        return null;
    }
}