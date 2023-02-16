/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description get all care plan problems for one care plan
 */
public with sharing class PJN_CarePlanPathListCtrl {
    /**
     *
     */
    @testVisible private static PJN_AllCarePlanSettingQuery allCarePlanSettingQuery = new PJN_AllCarePlanSettingQuery();

    /**
     *
     */
    @testVisible private static PJN_AllCarePlanFieldSettingQuery allCarePlanFieldSettingQuery = new PJN_AllCarePlanFieldSettingQuery();

    /**
     *
     * @param   Id        patientId
     * @returns  List<Case>
     */
	@auraEnabled public static List<Case> getCareplans(Id patientId) {
        try {
            Set<String> fieldsToQuery = new Set<String> { 'PJN_Program_DeveloperName__c', 'Subject' };
            Map<String, PJN_All_Care_Plan_Setting__mdt> allCarePlanSettingsByProgramDeveloperName = getAllCarePlanSettingsByProgramDeveloperName();
            Set<String> allCarePlanSettingDeveloperNames = new Set<String>();
            for(PJN_All_Care_Plan_Setting__mdt thisAllCarePlanSetting : allCarePlanSettingsByProgramDeveloperName.values()) {
                allCarePlanSettingDeveloperNames.add(thisAllCarePlanSetting.DeveloperName);
                fieldsToQuery.add(thisAllCarePlanSetting.PJN_Title_Field_API_Name__c);
                fieldsToQuery.add(thisAllCarePlanSetting.PJN_Subtitle_Field_API_Name__c);
            }

            for(List<PJN_All_Care_Plan_Setting_Field__mdt> thisAllCarePlanSettingFields : getAllCarePlanSettingFieldsBySettingDeveloperName(new List<String>(allCarePlanSettingDeveloperNames)).values()) {
                for(PJN_All_Care_Plan_Setting_Field__mdt thisAllCarePlanSettingField : thisAllCarePlanSettingFields) {
                    fieldsToQuery.add(thisAllCarePlanSettingField.PJN_Field_API_Name__c);
                    if(thisAllCarePlanSettingField.PJN_Link_Record_Id_Field_API_Name__c != null) {
                        fieldsToQuery.add(thisAllCarePlanSettingField.PJN_Link_Record_Id_Field_API_Name__c);
                    }
                }
            }

            return Database.query(
                'SELECT ' +
                    String.join(new List<String>(fieldsToQuery), ', ') + ' ' +
                'FROM ' +
                    'Case ' +
                'WHERE ' +
                    'AccountId = :patientId ' +
                'AND ' +
                    'RecordType.DeveloperName = \'Careplan\' ' +
                'ORDER BY ' +
                    'LastModifiedDate DESC'
            );
        } catch(Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex);
        }
    }

    /**
     *
     * @returns  Map<String, PJN_All_Care_Plan_Setting__mdt>
     */
    @AuraEnabled public static Map<String, PJN_All_Care_Plan_Setting__mdt> getAllCarePlanSettingsByProgramDeveloperName() {
        try {
            Map<String, PJN_All_Care_Plan_Setting__mdt> allCarePlanSettingsByProgramDeveloperName = new Map<String, PJN_All_Care_Plan_Setting__mdt>();
            for(PJN_All_Care_Plan_Setting__mdt thisAllCarePlanSetting : allCarePlanSettingQuery.queryAll()) {
                allCarePlanSettingsByProgramDeveloperName.put(
                    thisAllCarePlanSetting.PJN_Program__r.DeveloperName,
                    thisAllCarePlanSetting
                );
            }
            return allCarePlanSettingsByProgramDeveloperName;
        } catch(Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex);
        }
    }

    /**
     *
     * @param   List<String>        allCarePlanSettingDeveloperNames
     * @returns  Map<String, List<PJN_All_Care_Plan_Setting_Field__mdt>>
     */
    @AuraEnabled public static Map<String, List<PJN_All_Care_Plan_Setting_Field__mdt>> getAllCarePlanSettingFieldsBySettingDeveloperName(List<String> allCarePlanSettingDeveloperNames) {
        try {
            Set<String> allCarePlanSettingDeveloperNamesSet = new Set<String>(allCarePlanSettingDeveloperNames);
            Map<String, List<PJN_All_Care_Plan_Setting_Field__mdt>> allCarePlanSettingFieldsBySettingDeveloperName = new Map<String, List<PJN_All_Care_Plan_Setting_Field__mdt>>();
            for(PJN_All_Care_Plan_Setting_Field__mdt thisAllCarePlanSettingField : allCarePlanFieldSettingQuery.queryBySettingDeveloperNames(allCarePlanSettingDeveloperNamesSet)) {
                List<PJN_All_Care_Plan_Setting_Field__mdt> allCarePlanSettingFields = new List<PJN_All_Care_Plan_Setting_Field__mdt>();
                if(allCarePlanSettingFieldsBySettingDeveloperName.containsKey(thisAllCarePlanSettingField.PJN_All_Care_Plan_Setting__r.DeveloperName)) {
                    allCarePlanSettingFields = allCarePlanSettingFieldsBySettingDeveloperName.get(thisAllCarePlanSettingField.PJN_All_Care_Plan_Setting__r.DeveloperName);
                }
                allCarePlanSettingFields.add(thisAllCarePlanSettingField);
                allCarePlanSettingFieldsBySettingDeveloperName.put(
                    thisAllCarePlanSettingField.PJN_All_Care_Plan_Setting__r.DeveloperName,
                    allCarePlanSettingFields
                );
            }
            return allCarePlanSettingFieldsBySettingDeveloperName;
        } catch(Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex);
        }
    }
}