/**
 * @author Mavens
 * @group Util
 * @description   Utility class for augmenting SObject metadata retrieval
 *                Primary use is navigating getDescribes, labels, and record types
 **/

 public with sharing class PJN_SObjectUtil {

    public static Map<Id, Schema.RecordTypeInfo> getRecordTypesByIdForObject(String objectName) {
        return Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosById();
    }

    public static Map<String, Schema.RecordTypeInfo> getRecordTypesByDevNameForObject(String objectName) {
        return Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosByDeveloperName();
    }

    public static Schema.RecordTypeInfo getPhysicianRecordType() {
        return getRecordTypesByDevNameForObject('Account').get('PJN_Physician');
    }

    public static Schema.RecordTypeInfo getHCORecordType() {
        return getRecordTypesByDevNameForObject('Account').get('PJN_Organization');
    }

    public static Schema.RecordTypeInfo getAddressRecordType() {
        return getRecordTypesByDevNameForObject('PJN_Contact_Information__c').get('PJN_Address');
    }

    public static boolean isValidPicklistValue(String objName, String fieldApiName, String fieldValue) {
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objName);
        Schema.SObjectField objField = objType.getDescribe().fields.getMap().get(fieldApiName);
        //make sure it is a valid field for the object
        if(objField != null) {
            List<Schema.PicklistEntry> validValues = objField.getDescribe().getPicklistValues();

            for (Schema.PicklistEntry ple : validValues) {
                if (fieldValue != null && fieldValue.equals(ple.getValue())) {
                    return true;
                }
            }
        }
        return false;
    }

    /*
    * @description Returns Select query for an object that queries for all fields
    *        NOTE: Custom Settings/Metadata Only. DO NOT USE FOR REGULAR OBJECTS
    *        It is dangerous to use for regular objects as
    *           a) they tend to have a lot more fields
    *           b) customers can an arbitrary additional fields, inflating the query even more
    * @param objectName the sobject to build the query for
    * @returns map of SObject Fields to Field API Names
    */
    public static String getSelectForSetupObject(String objectName) {
        String query = 'SELECT ';

        List<String> objectFields = new List<String>(Schema.getGlobalDescribe().get(objectName).getDescribe().Fields.getMap().keySet());

        query += String.escapeSingleQuotes(String.join(objectFields, ','));
        query += ' FROM ' + objectName;
        return query;
    }
}