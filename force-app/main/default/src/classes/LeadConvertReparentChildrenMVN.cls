/**
 * @author      Mavens
 * @group       LeadMVN
 * @description Link children of the lead to the newly created account
 */
public without sharing class LeadConvertReparentChildrenMVN {
    
    @InvocableMethod(
        label='Lead Post Convert' 
        description='Reparent Child records to Account/Care Plan' 
        category='Lead'
    )
    public static void reparentLeadChidren(List<Id> carePlanIds) {
        
        List<Case> carePlans = [
            SELECT Id, AccountId FROM Case WHERE Id IN :carePlanIds
        ];

        Map<Id, Case> carePlansByAccount = new Map<Id, Case>();
        for (Case carePlan : carePlans) {
            carePlansByAccount.put(carePlan.AccountId, carePlan);
        }

        List<Lead> convertedLeads = [ SELECT Id FROM Lead WHERE ConvertedAccountId IN :carePlansByAccount.keySet() ];
        
        List<String> querySelections = new List<String>{'Id', 'ConvertedAccountId'};

        List<Lead_Convert_Child_Mapping_MVN__mdt> childMappings = getChildMappings();        
        
        for (Lead_Convert_Child_Mapping_MVN__mdt childMapping : childMappings) {
            if (String.isNotBlank(childMapping.Account_Lookup_Field_MVN__c + childMapping.Care_Plan_Lookup_Field_MVN__c)) {
                Set<String> fields = new Set<String> {
                    childMapping.Account_Lookup_Field_MVN__c, 
                    childMapping.Care_Plan_Lookup_Field_MVN__c
                };
                fields.remove(null);
                fields.remove('');

                querySelections.add(
                    '(SELECT ' + String.join(new List<String>(fields), ', ') + 
                    ' FROM ' + childMapping.Lead_Child_Object_Relationship_MVN__c + ')'
                );
            }
        }

        // build query and get list of leads
        String query = 'SELECT ' + String.join(querySelections, ', ') 
            + ' FROM LEAD'
            + ' WHERE Id IN :convertedLeads';
        
        List<Lead> leads = (List<Lead>) Database.query(query);

        // Map to sort updated objects into lists by object so they can grouped for update via DML
        Map<String, List<Sobject>> objectsByRelationshipKey = new  Map<String, List<Sobject>>();

        // iterate leads
        for (Lead convertedLead : leads) {
            // iterate child mappings
            for (Lead_Convert_Child_Mapping_MVN__mdt childMapping : childMappings) {
                // get children from queried leads and map account id to configured lookup
                for (SObject so : convertedLead.getSObjects(childMapping.Lead_Child_Object_Relationship_MVN__c)) {
                    if (String.isNotBlank(childMapping.Account_Lookup_Field_MVN__c)) {
                        so.put(childMapping.Account_Lookup_Field_MVN__c, convertedLead.ConvertedAccountId);
                    } 

                    if (String.isNotBlank(childMapping.Care_Plan_Lookup_Field_MVN__c)) {
                        Id carePlanId = carePlansByAccount.get(convertedLead.ConvertedAccountId).Id;
                        so.put(childMapping.Care_Plan_Lookup_Field_MVN__c, carePlanId);
                    }
                    
                    if (!objectsByRelationshipKey.containsKey(childMapping.Lead_Child_Object_Relationship_MVN__c)) {
                        objectsByRelationshipKey.put(
                            childMapping.Lead_Child_Object_Relationship_MVN__c, 
                            new List<SObject>()
                        );
                    }
                    // add to map
                    objectsByRelationshipKey.get(childMapping.Lead_Child_Object_Relationship_MVN__c).add(so);
                }
            } 
        }

        //add all sobjects to a single list for update. All rows of similar object type must be grouped together
        List<SObject> objectsToUpdate = new List<SObject>();
        for (List<SObject> objList : objectsByRelationshipKey.values()) {
            objectsToUpdate.addAll(objList);
        }

        update objectsToUpdate;
    }

    private static List<Lead_Convert_Child_Mapping_MVN__mdt> getChildMappings() {
        return [
            SELECT 
                Lead_Child_Object_Relationship_MVN__c, 
                Account_Lookup_Field_MVN__c,
                Care_Plan_Lookup_Field_MVN__c
            FROM 
                Lead_Convert_Child_Mapping_MVN__mdt
        ];
    }
}