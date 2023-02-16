/**
 * @author      Mavens
 * @group       RBM
 * @description Sets the Share with RBM flag on Care Plans based on RBM Sharing Settings custom metadata
 */
public with sharing class MVN_ShareWithRBM {

    @TestVisible
    private static MVN_RBMSharingSettingsQuery query = new MVN_RBMSharingSettingsQuery();

    public static void share(List<Case> carePlans) {

        // Collect the Program Name, Therapy Status, Sub Status and Pharmacy Status from the Care Plans
        Map<String,Map<String,List<String>>> programTherapyStatusMap = new Map<String,Map<String,List<String>>>();
        Map<String,Set<String>> programPharmacyStatusMap = new Map<String,Set<String>>();

        for (Case carePlan : carePlans) {
            if (String.isNotBlank(carePlan.PJN_Program_DeveloperName__c)) {

                if (String.isNotBlank(carePlan.PJN_Therapy_Status__c) && String.isNotBlank(carePlan.PJN_Therapy_Sub_Status__c)) {
                    
                    if (programTherapyStatusMap.containsKey(carePlan.PJN_Program_DeveloperName__c)) {
                        Map<String,List<String>> therapyStatusMap = programTherapyStatusMap.get(carePlan.PJN_Program_DeveloperName__c);
                        if (therapyStatusMap.containsKey(carePlan.PJN_Therapy_Status__c)) {
                            List<String> therapySubstatuses = therapyStatusMap.get(carePlan.PJN_Therapy_Status__c);
                            if (!therapySubstatuses.contains(carePlan.PJN_Therapy_Sub_Status__c)) {
                                therapySubstatuses.add(carePlan.PJN_Therapy_Sub_Status__c);
                            }
                        } else {
                            therapyStatusMap.put(carePlan.PJN_Therapy_Status__c, new List<String> { carePlan.PJN_Therapy_Sub_Status__c });
                        }
                    } else {
                        Map<String,List<String>> therapyStatusMap = new Map<String,List<String>>();
                        therapyStatusMap.put(carePlan.PJN_Therapy_Status__c, new List<String> { carePlan.PJN_Therapy_Sub_Status__c });
                        programTherapyStatusMap.put(carePlan.PJN_Program_DeveloperName__c, therapyStatusMap);
                    }
                    
                }
    
                if (String.isNotBlank(carePlan.MVN_Pharmacy_Status__c)) {
                    if (programPharmacyStatusMap.containsKey(carePlan.PJN_Program_DeveloperName__c)) {
                        programPharmacyStatusMap.get(carePlan.PJN_Program_DeveloperName__c).add(carePlan.MVN_Pharmacy_Status__c);
                    } else {
                        programPharmacyStatusMap.put(carePlan.PJN_Program_DeveloperName__c, new Set<String> { carePlan.MVN_Pharmacy_Status__c });
                    }
                }
            }
        }

        System.debug(LoggingLevel.DEBUG, 'Therapy Statuses on Care Plans');
        System.debug(LoggingLevel.DEBUG, programTherapyStatusMap);
        System.debug(LoggingLevel.DEBUG, 'Pharmacy Statuses on Care Plans');
        System.debug(LoggingLevel.DEBUG, programPharmacyStatusMap);
        
        // Query RMB Sharing Settings for the Therapy Status, Sub Status and Pharmacy Status values
        List<MVN_RBM_Sharing_Setting__mdt> rbmSharingSettings = new List<MVN_RBM_Sharing_Setting__mdt>();
        rbmSharingSettings.addAll(query.forProgramTherapyStatusMap(programTherapyStatusMap));
        rbmSharingSettings.addAll(query.forProgramPharmacyStatusMap(programPharmacyStatusMap));

        System.debug('RBM Sharing Settings that matched values on the Care Plan');
        System.debug(rbmSharingSettings);

        for (Case carePlan : carePlans) {

            System.debug(LoggingLevel.DEBUG, 'Setting Share with RBM for Care Plan');
            System.debug(LoggingLevel.DEBUG, carePlan);

            // The Share with RBM flag is referenced in Case sharing rules to provide visibility to Care Plans
            // for RBMs based on visibility rules defined in RBM Sharing Settings custom metadata.
            carePlan.MVN_Share_with_RBM__c = false;

            // The Share with RBM flag is set based on the latest update to either Therapy or Pharmacy Status
            Boolean useTherapyStatus;

            if (carePlan.MVN_Last_Pharmacy_Status_Update__c == null && carePlan.MVN_Last_Therapy_Status_Update__c != null) {
                useTherapyStatus = true;
            } else if (carePlan.MVN_Last_Pharmacy_Status_Update__c != null && carePlan.MVN_Last_Therapy_Status_Update__c == null) {
                useTherapyStatus = false;
            } else if (carePlan.MVN_Last_Pharmacy_Status_Update__c != null && carePlan.MVN_Last_Therapy_Status_Update__c != null) {
                if (carePlan.MVN_Last_Pharmacy_Status_Update__c > carePlan.MVN_Last_Therapy_Status_Update__c) {
                    useTherapyStatus = false;
                } else {
                    useTherapyStatus = true;
                }
            }

            System.debug(LoggingLevel.DEBUG, 'Use Therapy Status instead of Pharmacy Status?');
            System.debug(LoggingLevel.DEBUG, useTherapyStatus);

            if (useTherapyStatus != null) {
                if (useTherapyStatus) {
                    for (MVN_RBM_Sharing_Setting__mdt rbmSharingSetting : rbmSharingSettings) {
                        if (rbmSharingSetting.MVN_Type__c.equalsIgnoreCase('Therapy') && 
                            rbmSharingSetting.MVN_Status__c.equalsIgnoreCase(carePlan.PJN_Therapy_Status__c) && 
                            rbmSharingSetting.MVN_Sub_Status__c.equalsIgnoreCase(carePlan.PJN_Therapy_Sub_Status__c) && 
                            rbmSharingSetting.MVN_Days_Visible__c > carePlan.MVN_Days_in_Therapy_Status__c) {
                                System.debug(LoggingLevel.DEBUG, 'Sharing with RBM because Therapy Status was Last Updated and is within Days Visible');
                                carePlan.MVN_Share_with_RBM__c = true;
                                break;
                        }
                    }
                } else {
                    for (MVN_RBM_Sharing_Setting__mdt rbmSharingSetting : rbmSharingSettings) {
                        if (rbmSharingSetting.MVN_Type__c.equalsIgnoreCase('Pharmacy') && 
                            rbmSharingSetting.MVN_Status__c.equalsIgnoreCase(carePlan.MVN_Pharmacy_Status__c) && 
                            rbmSharingSetting.MVN_Days_Visible__c > carePlan.MVN_Days_in_Pharmacy_Status__c) {
                                
                                System.debug(LoggingLevel.DEBUG, 'Sharing with RBM because Pharmacy Status was Last Updated and is within Days Visible');
                                carePlan.MVN_Share_with_RBM__c = true;
                                break;
                        }
                    }
                }
            } else {
                System.debug(LoggingLevel.DEBUG, 'No Therapy or Pharmacy Status set on the Care Plan');
            }   
        }
    }

}