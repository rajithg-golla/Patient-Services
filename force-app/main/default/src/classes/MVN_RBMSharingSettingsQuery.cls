/**
* @author Mavens
* @description Queries for RBM Sharing Settings records
* @group RBM
*/
public with sharing class MVN_RBMSharingSettingsQuery {

    @TestVisible 
    private List<MVN_RBM_Sharing_Setting__mdt> settings;

    public List<MVN_RBM_Sharing_Setting__mdt> forProgramTherapyStatusMap(Map<String,Map<String,List<String>>> programTherapyStatusMap) {

        System.debug(LoggingLevel.DEBUG, 'Programs to filter RBM Sharing Settings');
        System.debug(LoggingLevel.DEBUG, programTherapyStatusMap.keySet());
        
        List<MVN_RBM_Sharing_Setting__mdt> settingsToReturn = new List<MVN_RBM_Sharing_Setting__mdt>();

        if (settings == null) {
            settings = [
                SELECT
                    DeveloperName,
                    MVN_Days_Visible__c,
                    MVN_Status__c,
                    MVN_Sub_Status__c,
                    MVN_Type__c,
                    MVN_Program_Name__c
                FROM
                    MVN_RBM_Sharing_Setting__mdt
                WHERE 
                    MVN_Type__c = 'Therapy'
            ];
        }
        
        System.debug(LoggingLevel.DEBUG, 'RBM Sharing Settings returned by query for Therapy Status');
        System.debug(LoggingLevel.DEBUG, settings);

        for (MVN_RBM_Sharing_Setting__mdt setting : settings) {

            if (programTherapyStatusMap.containsKey(setting.MVN_Program_Name__c)) {
                Map<String,List<String>> programTherapyStatuses = programTherapyStatusMap.get(setting.MVN_Program_Name__c);
                if (programTherapyStatuses.containsKey(setting.MVN_Status__c)) {
                    List<String> programTherapySubstatuses = programTherapyStatuses.get(setting.MVN_Status__c);
                    for (String programTherapySubstatus : programTherapySubstatuses) {
                        if (setting.MVN_Sub_Status__c.equalsIgnoreCase(programTherapySubstatus)) {
                            settingsToReturn.add(setting);
                            break;
                        }
                    }
                }
            }
        }
        System.debug(LoggingLevel.DEBUG, 'Settings after filtering for Program, Therapy Status and Therapy Sub Status match');
        System.debug(LoggingLevel.DEBUG, settingsToReturn);

        return settingsToReturn;
    }

    public List<MVN_RBM_Sharing_Setting__mdt> forProgramPharmacyStatusMap(Map<String,Set<String>> programPharmacyStatusMap) {

        System.debug(LoggingLevel.DEBUG, 'Programs to filter RBM Sharing Settings');
        System.debug(LoggingLevel.DEBUG, programPharmacyStatusMap.keySet());

        List<MVN_RBM_Sharing_Setting__mdt> settingsToReturn = new List<MVN_RBM_Sharing_Setting__mdt>();

        if (settings == null) {
            settings = [
                SELECT
                    DeveloperName,
                    MVN_Days_Visible__c,
                    MVN_Status__c,
                    MVN_Sub_Status__c,
                    MVN_Type__c,
                    MVN_Program_Name__c
                FROM
                    MVN_RBM_Sharing_Setting__mdt
                WHERE 
                    MVN_Type__c = 'Pharmacy'
            ];
        }
        
        System.debug(LoggingLevel.DEBUG, 'RBM Sharing Settings returned by query for Pharmacy Status');
        System.debug(LoggingLevel.DEBUG, settings);

        for (MVN_RBM_Sharing_Setting__mdt setting : settings) {
            if (programPharmacyStatusMap.containsKey(setting.MVN_Program_Name__c)) {
                Set<String> programPharmacyStatuses = programPharmacyStatusMap.get(setting.MVN_Program_Name__c);
                for (String programPharmacyStatus : programPharmacyStatuses) {
                    if (setting.MVN_Program_Name__c.equalsIgnoreCase(programPharmacyStatus)) {
                        settingsToReturn.add(setting);
                    }
                }
            }            
        }
        System.debug(LoggingLevel.DEBUG, 'Settings after filtering for Program and Pharmacy Status match');
        System.debug(LoggingLevel.DEBUG, settingsToReturn);

        return settingsToReturn;

    }
}