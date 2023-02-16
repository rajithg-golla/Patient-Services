/**
 * @author      Mavens
 * @group       FieldSettings
 * @description Accessor for Field Settings custom metadata
 */
public with sharing class PJN_FieldSettings {

    private static Map<String, SObjectField> fieldMap = Schema.getGlobalDescribe()
        .get('PJN_Field_Setting__mdt')
        .getDescribe()
        .fields.getMap();

    @AuraEnabled
    public static List<PJN_Field_Setting__mdt> accountSearchFields(String recordType, String sortField, Boolean personSearch) {
        try {
            List<String> whereClauses = new List<String>();

            Set<String> recordTypes = new Set<String> { 'All' };
            // piece together any received record type filters
            if (String.isNotBlank(recordType)) {
                recordTypes.add(recordType);
            }
            whereClauses.add('PJN_Account_Record_Type__c IN :recordTypes');

            // piece together any account type fitlers
            if (personSearch != null) {
                whereClauses.add('PJN_Is_Person_Record_Type__c = :personSearch');
            }

            // piece together any received field filter
            if (String.isNotBlank(sortField)) {
                if (fieldMap.get(sortField).getDescribe().getType() == DisplayType.Boolean) {
                    whereClauses.add(sortField + ' = true');
                } else {
                    whereClauses.add(sortField + ' != null');
                }
            }

            //build query
            String query = baseQuery;

            // combine filters
            if(!whereClauses.isEmpty()) {
                query += ' WHERE ' + String.escapeSingleQuotes(String.join(whereClauses,' AND '));
            }

            // tack on a sort
            if (String.isNotBlank(sortField)) {
                query += ' ORDER BY '+  String.escapeSingleQuotes(sortField) + ' ASC';
            }
            System.debug(query);
            return Database.query(query);
        } catch (Exception ex) {
            throw new AuraHandledException( ex.getMessage());
        }
    }

    private static String baseQuery {
        get {
            if (baseQuery == null) {
                List<String> fieldSettingFields = new List<String>( fieldMap.keySet() );

                String queryStringFields = String.escapeSingleQuotes(String.join(fieldSettingFields, ','));

                baseQuery = 'SELECT ' + queryStringFields + ' FROM PJN_Field_Setting__mdt';
            }

            return baseQuery;
        }
        set;
    }
}