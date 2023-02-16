/**
* @author Mavens
* @description Unit tests for MVN_RBMSharingSettingsQuery
* @group RBM
*/
@isTest
public class MVN_RBMSharingSettingsQueryTest {


    @isTest 
    private static void itShouldQueryForProgramTherapyStatusMap() {

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

        Map<String,List<String>> therapyStatusMap = new Map<String,List<String>>();
        therapyStatusMap.put('Cancelled', new List<String> { 'Patient Deceased' });

        Map<String,Map<String,List<String>>> programTherapyStatusMap = new Map<String,Map<String,List<String>>>();
        programTherapyStatusMap.put('MVN_EVK', therapyStatusMap);
        
        Test.startTest();

        MVN_RBMSharingSettingsQuery query = new MVN_RBMSharingSettingsQuery();
        query.settings = settings;

        List<MVN_RBM_Sharing_Setting__mdt> returned = query.forProgramTherapyStatusMap(programTherapyStatusMap);
        
        Test.stopTest();

        System.assertNotEquals(null, returned);
    }

    @isTest 
    private static void itShouldQueryForProgramPharmacyStatusMap() {

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

        Set<String> pharmacyStatusSet = new Set<String> { 'Unknown' }; 

        Map<String,Set<String>> programPharmacyStatusMap = new Map<String,Set<String>>();
        programPharmacyStatusMap.put('MVN_EVK', pharmacyStatusSet);
        
        Test.startTest();
        
        MVN_RBMSharingSettingsQuery query = new MVN_RBMSharingSettingsQuery();
        query.settings = settings;

        List<MVN_RBM_Sharing_Setting__mdt> returned = query.forProgramPharmacyStatusMap(programPharmacyStatusMap);
        
        Test.stopTest();

        System.assertNotEquals(null, returned);
    }
}