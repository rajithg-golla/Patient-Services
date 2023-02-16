/**
 * @author      Mavens
 * @group       MissingInformation
 * @description Case Missing Information Controller to display the missing info fields on the Missing Info Activity
 */
public with sharing class PJN_CaseMissingInformationCtrl {

    /**
     * List of Missing Information Config metadata records
     */
    private static List<PJN_Missing_Information_Config__mdt> missingInfoConfigs;

    /**
     * Missing Information Config metadata records query class
     */
    @TestVisible
    private static PJN_MissingInformationConfigQuery missingInformationConfigQuery = new PJN_MissingInformationConfigQuery();

    /**
     * Method called from LWC to get a list of the missing information fields for the Care Plan
     * parent of the current record id which is the missing information activity
     * @param recordId  Missing Information Activity Id
     * @return  `List<String>`
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getMissingInformationFields(Id recordId) {
        Case activity = getActivity(recordId);
        if (activity == null) {
            return null;
        }
        missingInfoConfigs = missingInformationConfigQuery.queryMissingInfoConfigsByProgramName(activity.PJN_Program__r.PJN_Program_DeveloperName__c);
        Case carePlan = getCarePlan(activity.ParentId);
        List<String> missingInformationFields = new List<String>();
        for (PJN_Missing_Information_Config__mdt missingInfoConfig : missingInfoConfigs) {
            Object carePlanFieldValue = getCarePlanFieldValue(carePlan, missingInfoConfig);
            if (carePlanFieldValue == null) {
                missingInformationFields.add(getFieldLabel(carePlan, missingInfoConfig.PJN_Field_Path__c));
            }
        }
        missingInformationFields.sort();
        return missingInformationFields;
    }

    /**
     * Get Missing Information Activity record using the id
     * @param recordId  Activity record id
     * @return  `Case`
     */
    private static Case getActivity(Id recordId) {
        List<Case> missingInformationActivities = [
            SELECT
                Id,
                ParentId,
                PJN_Program__c,
                PJN_Program__r.PJN_Program_DeveloperName__c
            FROM
                Case
            WHERE
                Id = :recordId
            AND
                RecordType.DeveloperName = 'MVN_Missing_Information'
        ];
        if (missingInformationActivities.isEmpty()) {
            return null;
        }
        return missingInformationActivities[0];
    }

    /**
     * Get Parent Care Plan record with the missing info fields obtained from metadata
     * @param carePlanId    Care Plan Id to query
     * @return  `Case`
     */
    private static Case getCarePlan(Id carePlanId) {
        String fields = '';
        for (PJN_Missing_Information_Config__mdt missingInfoConfig : missingInfoConfigs) {
            fields += missingInfoConfig.PJN_Field_Path__c + ',';
        }
        String query = 'SELECT ' + fields.substringBeforeLast(',') + ' FROM Case WHERE Id = :carePlanId';
        return (Case) Database.query(query);
    }

    /**
     * Get Care Plan Field Value using missing Information Config metadata
     * @param carePlan          Care Plan record
     * @param missingInfoConfig Missing Information Config metadata
     * @return  `Object`
     */
    private static Object getCarePlanFieldValue(Case carePlan, PJN_Missing_Information_Config__mdt missingInfoConfig) {
        Object carePlanFieldValue;
        if (missingInfoConfig.PJN_Field_Path__c.contains('.') && carePlan.getSObject(missingInfoConfig.PJN_Field_Path__c.substringBeforeLast('.')) != null) {
            carePlanFieldValue = carePlan.getSObject(missingInfoConfig.PJN_Field_Path__c.substringBeforeLast('.')).get(missingInfoConfig.PJN_Field_Path__c.substringAfterLast('.'));
        } else if (!missingInfoConfig.PJN_Field_Path__c.contains('.')) {
            carePlanFieldValue = carePlan.get(missingInfoConfig.PJN_Field_Path__c);
        }
        return carePlanFieldValue;
    }

    /**
     * Get the field labels from those missing info fields from the Care Plan
     * @param carePlan  CarePlan record
     * @param fieldPath Field API (path) name
     * @return  `String`
     */
    private static String getFieldLabel(Case carePlan, String fieldPath) {
        String fieldLabel = '';
        Schema.SObjectType sobjType = Schema.Case.getSObjectType();
        String fieldName = fieldPath;
        if (fieldPath.contains('.')) {
            fieldName = fieldPath.substringAfterLast('.');
            sobjType = getCarePlanChildSObjectType(carePlan, fieldPath.substringBeforeLast('.'));
            fieldLabel += sobjType.getDescribe().getLabel() + ': ';
        }
        fieldLabel += sobjType.getDescribe().fields.getMap().get(fieldName).getDescribe().getLabel();
        return fieldLabel;
    }

    /**
     * Get Care Plan child SObject Type from parent field name
     * @param carePlan      Care Plan record
     * @param parentField   Parent API Relationship Field Name
     * @return  `Schema.SObjectType`
     */
    private static Schema.SObjectType getCarePlanChildSObjectType(Case carePlan, String parentField) {
        if (carePlan.getSObject(parentField) == null) {
            String parentSObjectName = parentField.endsWith('__r') ?
                parentField.substringBeforeLast('__r') + '__c' :
                parentField;
            Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap().get(parentSObjectName).getDescribe();
            return fieldResult.getReferenceTo()[0];
        }
        return carePlan.getSObject(parentField).getSObjectType();
    }
}