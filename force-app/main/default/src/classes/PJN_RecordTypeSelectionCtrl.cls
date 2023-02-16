public with sharing class PJN_RecordTypeSelectionCtrl {
    @auraEnabled
    public static List<RecordType> getRecordTypes(String sObjectName) {

        Set<Id> recordTypeIds = new Set<Id>();
        for (RecordTypeInfo rti : Schema.getGlobalDescribe().get(sObjectName).getDescribe().getRecordTypeInfos()) {
            if (rti.isAvailable()) {
                recordTypeIds.add(rti.getRecordTypeId());
            }
        }
        return [
            SELECT
                Id,
                Name
            FROM
                RecordType
            WHERE
                Id IN :recordTypeIds
        ];
    }
}