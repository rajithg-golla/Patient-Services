/**
 * @author      Mavens
 * @group       AdobeSign
 * @description Update Lead workaround for Guest privilege restrictions.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class AdobeSignLeadUpdateHdlrMVN implements PJN_TriggerDispatcher.HandlerInterface {
    public void handle() {
        Set<Id> processTemplateIds = new Set<Id>();
        for (Lead_Update_MVN__e consumerUpdate : (List<Lead_Update_MVN__e>) trigger.new) {
            if (consumerUpdate.Process_Template_MVN__c != NULL) {
                processTemplateIds.add(consumerUpdate.Process_Template_MVN__c);
            }
        }

        Map<Id, Map<String, String>> fieldMappingMap = getFormFieldMappings(processTemplateIds);

        List<Lead> consumers = new List<Lead>();

        for (Lead_Update_MVN__e consumerUpdate : (List<Lead_Update_MVN__e>) trigger.new) {
            Lead consumer = new Lead(Id = consumerUpdate.Consumer_MVN__c);
            if (consumerUpdate.Process_Template_MVN__c != NULL && fieldMappingMap.containsKey(consumerUpdate.Process_Template_MVN__c)) {
                Map<String, String> fieldMap = fieldMappingMap.get(consumerUpdate.Process_Template_MVN__c);
                for (String key : fieldMap.keySet()) {
                    if (consumerUpdate.get(key) != NULL) {
                        consumer.put(fieldMap.get(key), consumerUpdate.get(key));
                    }
                }
            }

            consumers.add(consumer);
        }

        update consumers;
    }

    /**
     * Query for the lead field mappings
     * @param processTemplateIds - Data Mappings Ids
     * returns Map<Id, Map<String, String>>
     */
    private static Map<Id, Map<String, String>> getFormFieldMappings(Set<Id> processTemplateIds) {
        Map<Id, Map<String, String>> result = new Map<Id, Map<String, String>>();
        for (echosign_dev1__SIGN_Object_Mapping__c objectMapping : queryObjectMappings(processTemplateIds)) {
            Map<String, String> fieldToFieldMap = new Map<String, String>();
            for (echosign_dev1__SIGN_Field_Mapping__c fieldMapping : objectMapping.echosign_dev1__Field_Mappings__r) {
                fieldToFieldMap.put(getFieldName(fieldMapping.Name), fieldMapping.Name);
            }

            result.put(objectMapping.echosign_dev1__SIGN_Data_Mapping__c, fieldToFieldMap);
        }

        return result;
    }

    private static String getFieldName(String fieldName) {
        String result = fieldName + '_MVN__c';
        result = result.replace('HealthCloudGA__', '');
        result = result.replace('echosign_dev1__', '');
        result = result.replace('_MVN__c_MVN__c', '_MVN__c');
        result = result.replace('__c_MVN__c', '_MVN__c');
        return result;
    }

    private static List<echosign_dev1__SIGN_Object_Mapping__c> queryObjectMappings(Set<Id> processTemplateIds) {
        return [SELECT echosign_dev1__SIGN_Data_Mapping__c,
                    (
                        SELECT Name, echosign_dev1__Source__c, echosign_dev1__Type__c
                        FROM echosign_dev1__Field_Mappings__r
                    )
                FROM echosign_dev1__SIGN_Object_Mapping__c
                WHERE echosign_dev1__SIGN_Data_Mapping__c IN :processTemplateIds
                AND Name = 'Lead'];
    }
}