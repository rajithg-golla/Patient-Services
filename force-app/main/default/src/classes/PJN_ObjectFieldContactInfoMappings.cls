/**
 * Retrieves Object Field Contact Info Mappings and return only necessary record using object name
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_ObjectFieldContactInfoMappings {

    /**
     * Object Field Contact Info Mapping query wrapper
     */
    @TestVisible
    private static PJN_ObjectFieldContactInfoMappingsQuery objectFieldContactInfoMappingsQuery = new PJN_ObjectFieldContactInfoMappingsQuery();

    /**
     * All Object Field Contact Info Mapping metadatas by SObject name
     */
    private static Map<String, List<PJN_Object_Field_Contact_Info_Mapping__mdt>> objectFieldContactInfoMappingsByObject {
        get {
            if (objectFieldContactInfoMappingsByObject != null && !objectFieldContactInfoMappingsByObject.isEmpty()) {
                return objectFieldContactInfoMappingsByObject;
            }

            List<PJN_Object_Field_Contact_Info_Mapping__mdt> objectFieldContactInfoMappings = objectFieldContactInfoMappingsQuery.queryAll();

            objectFieldContactInfoMappingsByObject = new Map<String, List<PJN_Object_Field_Contact_Info_Mapping__mdt>>();

            for (PJN_Object_Field_Contact_Info_Mapping__mdt objectFieldContactInfoMapping : objectFieldContactInfoMappings) {
                List<PJN_Object_Field_Contact_Info_Mapping__mdt> currentObjectFieldContactInfoMappings = objectFieldContactInfoMappingsByObject.containsKey(objectFieldContactInfoMapping.PJN_Object_Name__c.toLowerCase()) ?
                    objectFieldContactInfoMappingsByObject.get(objectFieldContactInfoMapping.PJN_Object_Name__c.toLowerCase()) :
                    new List<PJN_Object_Field_Contact_Info_Mapping__mdt>();

                currentObjectFieldContactInfoMappings.add(objectFieldContactInfoMapping);

                objectFieldContactInfoMappingsByObject.put(objectFieldContactInfoMapping.PJN_Object_Name__c.toLowerCase(), currentObjectFieldContactInfoMappings);
            }

            return objectFieldContactInfoMappingsByObject;
        } set;
    }

    /**
     * Get Object Field Contact Info Mappings using SObject name
     * @param sobjectName   SObject name to get Object Field Contact Info Mappings for
     * @returns `List<PJN_Object_Field_Contact_Info_Mapping__mdt>`
     */
    public static List<PJN_Object_Field_Contact_Info_Mapping__mdt> getObjectFieldContactInfoMappingByObjectName(String sobjectName) {
        List<PJN_Object_Field_Contact_Info_Mapping__mdt> currentObjectFieldContactInfoMappings = objectFieldContactInfoMappingsByObject.get(sobjectName.toLowerCase());

        if (currentObjectFieldContactInfoMappings == null) {
            return new List<PJN_Object_Field_Contact_Info_Mapping__mdt>();
        }

        return currentObjectFieldContactInfoMappings;
    }
}