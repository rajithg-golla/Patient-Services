/**
 * @author      Mavens
 * @date        11/2020
 * @description Unit tests for PJN_CoverageInvestigationHelper
 * @group       CoverageInvestigation
 */
@isTest
public class PJN_CoverageInvestigationHelperTest {

    private static final Integer DATA_SIZE = 200;


    @TestSetup
    static void makeData(){
        PJN_TestFactoryCase caseFactory = new PJN_TestFactoryCase();
        caseFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId(),
                'Status' => 'Test',
                'Subject' => 'Care Plan Case'
            }
        );
    }

    @isTest
    private static void itShouldReturnInvestigationCarePlanId() {
        Id carePlanId = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'CarePlan' LIMIT 1].Id;

        PJN_Coverage_Investigation__c investigation = new PJN_Coverage_Investigation__c(
            PJN_Care_Plan__c = carePlanId
        );
        insert investigation;

        Test.startTest();
        Id returnedId = PJN_CoverageInvestigationHelper.getInvestigationCarePlanId(investigation.Id);
        Test.stopTest();

        System.assertEquals(carePlanId, returnedId);
    }

    @isTest
    private static void itShouldHandleInvestigationCarePlanIdError() {
        Exception e;
        Test.startTest();
        try {
            PJN_CoverageInvestigationHelper.getInvestigationCarePlanId(null);
        } catch(Exception ex) {
            e = ex;
        }
        Test.stopTest();

        System.assertNotEquals(null, e);
    }

    @isTest
    private static void itShouldReturnMemberPlans() {
        Id carePlanId = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'CarePlan' LIMIT 1].Id;

        List<PJN_Member_Plan__c> memberPlans = createMemberPlans(carePlanId);

        Test.startTest();
        List<PJN_Member_Plan__c> plans = PJN_CoverageInvestigationHelper.retrieveMemberPlans(carePlanId);
        Test.stopTest();

        System.assertEquals(2, plans.size());
    }

    @isTest
    private static void itShouldReturnNoMemberPlans() {
        Test.startTest();
        List<PJN_Member_Plan__c> plansAndPAs = PJN_CoverageInvestigationHelper.retrieveMemberPlans('001000000000000');
        Test.stopTest();

        System.assertEquals(0, plansAndPAs.size());
    }

    @isTest
    private static void itShouldGetFieldSet() {

        Test.startTest();
        List<PJN_FieldWrapper> fieldSet = PJN_CoverageInvestigationHelper.getFieldSet();
        Test.stopTest();

        System.assertNotEquals(0, fieldSet.size());
    }

    @isTest
    private static void itShouldRetrieveCoverageInvestigationItems() {
        Id carePlanId = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'CarePlan' LIMIT 1].Id;
        PJN_Coverage_Investigation__c ci = new PJN_Coverage_Investigation__c(
            PJN_Care_Plan__c = carePlanId
        );
        insert ci;

        List<PJN_Coverage_Investigation_Item__c> items = new List<PJN_Coverage_Investigation_Item__c>();

        Map<String, RecordTypeInfo> ciiRecTypeInfos = SObjectType.PJN_Coverage_Investigation_Item__c
            .getRecordTypeInfosByDeveloperName();

        List<PJN_Member_Plan__c> memberPlans = createMemberPlans(carePlanId);
        for (PJN_Member_Plan__c memberPlan : memberPlans) {
            items.add( new PJN_Coverage_Investigation_Item__c(
                PJN_Coverage_Investigation__c = ci.Id,
                PJN_Member_Plan__c = memberPlan.Id,
                RecordTypeId = ciiRecTypeInfos.get('PJN_Member_Plan').getRecordTypeId()
            ));
        }

        insert items;

        Test.startTest();
        List<PJN_Coverage_Investigation_Item__c> retreivedItems = PJN_CoverageInvestigationHelper.retrieveCoverageInvestigationItems(ci.Id);
        Test.stopTest();

        System.assertEquals(memberPlans.size(), retreivedItems.size());
    }

    @isTest
    private static void itShouldCreateCoverageInvestigationItems() {
        Id carePlanId = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'CarePlan' LIMIT 1].Id;

        Map<String, PJN_Member_Plan__c> memberPlans = new Map<String, PJN_Member_Plan__c>(
            createMemberPlans(carePlanId)
        );

        PJN_Coverage_Investigation__c investigation = new PJN_Coverage_Investigation__c(
            PJN_Care_Plan__c = carePlanId,
            PJN_Type__c = 'PJN_Initial_Investigation'
        );

        Test.startTest();
        Id investigationId = PJN_CoverageInvestigationHelper.createCoverageInvestigationItems(
            investigation,
            new List<String>(memberPlans.keySet())
        );
        Test.stopTest();

        System.assertEquals(2, [
            SELECT COUNT()
            FROM PJN_Coverage_Investigation_Item__c
            WHERE PJN_Coverage_Investigation__c = :investigationId
        ]);
    }

    @isTest
    private static void itShouldNotCreateCoverageInvestigationItemsForNonStandard() {
        Id carePlanId = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'CarePlan' LIMIT 1].Id;
        Map<String, PJN_Member_Plan__c> memberPlans = new Map<String, PJN_Member_Plan__c>(
            createMemberPlans(carePlanId)
        );
        PJN_Coverage_Investigation__c investigation = new PJN_Coverage_Investigation__c(
            PJN_Care_Plan__c = carePlanId,
            PJN_Type__c = '' // IMPORTANT PART OF TEST IS HERE
        );

        Test.startTest();
        Id investigationId = PJN_CoverageInvestigationHelper.createCoverageInvestigationItems(
            investigation,
            new List<String>(memberPlans.keySet())
        );
        Test.stopTest();

        System.assertNotEquals(null, investigationId);
        System.assertEquals(0, [ //NOTHING Created
            SELECT COUNT()
            FROM PJN_Coverage_Investigation_Item__c
            WHERE PJN_Coverage_Investigation__c = :investigationId
        ]);
    }

    private static List<PJN_Member_Plan__c> createMemberPlans(Id carePlanId) {
        List<PJN_Member_Plan__c> memberPlans = new List<PJN_Member_Plan__c> {
            new PJN_Member_Plan__c(
                PJN_Care_Plan__c = carePlanId
            ),
            new PJN_Member_Plan__c(
                PJN_Care_Plan__c = carePlanId
            )
        };
        insert memberPlans;
        return memberPlans;
    }
}