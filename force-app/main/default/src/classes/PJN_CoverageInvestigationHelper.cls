/**
 * @author      Mavens
 * @date        11/2020
 * @description Handles new coverage investigation trigger logic and provdes aura methods for the
 *              coverage investigation quick actions
 * @group       CoverageInvestigation
 */
public with sharing class PJN_CoverageInvestigationHelper {

    @AuraEnabled
    public static string getInvestigationCarePlanId(String investigationId){
        try {
            return [
                SELECT PJN_Care_Plan__c
                FROM PJN_Coverage_Investigation__c
                WHERE Id = :investigationId
            ].PJN_Care_Plan__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<PJN_Member_Plan__c> retrieveMemberPlans(Id carePlanId){
        try {
            Map<Id, List<PJN_Member_Plan__c>> activeMemberPlans
                = retrieveMemberPlans(new Set<Id>{carePlanId});

            if (activeMemberPlans.containsKey(carePlanId)){
                return activeMemberPlans.get(carePlanId);
            }

            return new List<PJN_Member_Plan__c>();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<PJN_FieldWrapper> getFieldSet(){
        try {
            Schema.FieldSet mpFieldSet = PJN_Member_Plan__c.sObjectType
                .getDescribe()
                .fieldSets.getMap()
                .get('PJN_Coverage_Investigation_Add_Screen');
            List<PJN_FieldWrapper> mpFieldWrappers = new List<PJN_FieldWrapper>();
            for (Schema.FieldSetMember fsm: mpFieldSet.getFields()) {
                mpFieldWrappers.add(
                    new PJN_FieldWrapper('PJN_Member_Plan__c', fsm.getSObjectField().getDescribe())
                );
            }

            return mpFieldWrappers;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Query for active member plans given a set of care plan ids
     * @param carePlanIds
     * @returns `Map<Id, List<PJN_Member_Plan__c>>`
     */
    public static Map<Id, List<PJN_Member_Plan__c>> retrieveMemberPlans(Set<Id> carePlanIds) {
        Set<String> memberPlanFields = new Set<String> { 'Id', 'PJN_Care_Plan__c', 'PJN_Active__c'};
        for (PJN_FieldWrapper fieldWrapper : getFieldSet())  {
            memberPlanFields.add(fieldWrapper.fieldName);
        }

        // gather and sort member plans
        List<PJN_Member_Plan__c> memberPlans = Database.query(
            'SELECT ' + String.join(new List<String>(memberPlanFields), ', ') + ' ' +
            'FROM PJN_Member_Plan__c ' +
            'WHERE PJN_Care_Plan__c IN :carePlanIds'
        );

        Map<Id, List<PJN_Member_Plan__c>> activeMemberPlansByCarePlan = new Map<Id, List<PJN_Member_Plan__c>>();
        for (PJN_Member_Plan__c memberPlan : memberPlans) {
            if (!activeMemberPlansByCarePlan.containsKey(memberPlan.PJN_Care_Plan__c)) {
                activeMemberPlansByCarePlan.put(
                    memberPlan.PJN_Care_Plan__c,
                    new List<PJN_Member_Plan__c>()
                );
            }
            activeMemberPlansByCarePlan.get(memberPlan.PJN_Care_Plan__c)
                .add(memberPlan);
        }
        return activeMemberPlansByCarePlan;
    }

    @AuraEnabled
    public static List<PJN_Coverage_Investigation_Item__c> retrieveCoverageInvestigationItems(Id investigationId){
        return [
            SELECT Id, PJN_Assistance_Program__c, PJN_Member_Plan__c, PJN_Prior_Authorization__c
            FROM PJN_Coverage_Investigation_Item__c
            WHERE PJN_Coverage_Investigation__c =  :investigationId
        ];
    }

    /**
     * Query for Prior Authorizaions for given member plans
     * @param carePlanIds
     * @returns `Map<Id, List<PJN_Prior_Authorization__c>>`
     */
    @AuraEnabled
    public static Id createCoverageInvestigationItems(
        PJN_Coverage_Investigation__c coverageInvestigation,
        List<String> memberPlanIds
    ) {
        try {
            if (coverageInvestigation.Id == null) {
                insert coverageInvestigation;

                // When inserting non-standard investigations a trigger will create new records
                if (coverageInvestigation.PJN_Type__c != 'PJN_Initial_Investigation') {
                    return coverageInvestigation.Id;
                }
            }

            List<PJN_Coverage_Investigation_Item__c> items = new List<PJN_Coverage_Investigation_Item__c>();
            Id ciiRecTypeId = SObjectType.PJN_Coverage_Investigation_Item__c
                .getRecordTypeInfosByDeveloperName()
                .get('PJN_Member_Plan')
                .getRecordTypeId();


            for (String id : memberPlanIds) {
                PJN_Coverage_Investigation_Item__c item = new PJN_Coverage_Investigation_Item__c (
                    PJN_Coverage_Investigation__c = coverageInvestigation.Id,
                    RecordTypeId = ciiRecTypeId
                );
                item.PJN_Member_Plan__c = id;
                items.add(item);
            }

            insert items;

            return coverageInvestigation.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}