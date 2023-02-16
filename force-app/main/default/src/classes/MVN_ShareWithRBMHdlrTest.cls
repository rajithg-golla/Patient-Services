/**
* @author Mavens
* @description Unit tests for MVN_ShareWithRBMHdlr
* @group RBM
*/
@isTest 
public class MVN_ShareWithRBMHdlrTest {
    
    private static List<Case> carePlans;

    static {
        PJN_TriggerHandlerSettingQuery.triggerHandlerSettingBySObjectType = new Map<SObjectType, List<PJN_Trigger_Handler_Setting__mdt>> {
            SObjectType.PJN_Contact_Information__c.getSObjectType() => new List<PJN_Trigger_Handler_Setting__mdt> {
                new PJN_Trigger_Handler_Setting__mdt(
                    PJN_Class__c = 'MVN_ShareWithRBMHdlr',
                    PJN_Event__c = 'BEFORE_INSERT',
                    PJN_SObject_API_Name__c = 'Case'
                ),
                new PJN_Trigger_Handler_Setting__mdt(
                    PJN_Class__c = 'MVN_ShareWithRBMHdlr',
                    PJN_Event__c = 'BEFORE_UPDATE',
                    PJN_SObject_API_Name__c = 'Case'
                )
            }
        };

        MVN_RBMSharingSettingsQuery query = (MVN_RBMSharingSettingsQuery) Test.createStub(
            MVN_RBMSharingSettingsQuery.class,
             new MVN_RBMSharingSettingsQueryMock()
        );
        MVN_ShareWithRBM.query = query;
    }

    @isTest 
    private static void itShouldSetShareWithRBMForNewCarePlans() {
        givenCarePlans();

        carePlans[0].PJN_Therapy_Status__c = 'Cancelled';
        carePlans[0].PJN_Therapy_Sub_Status__c = 'Patient Deceased';
        carePlans[0].MVN_Pharmacy_Status__c = '';

        Test.startTest();
        insert carePlans;
        Test.stopTest();

        withUpdatedCarePlans();
        System.assert(carePlans[0].MVN_Share_with_RBM__c);
    }

    @isTest 
    private static void itShouldSetShareWithRBMForUpdatedCarePlans() {
        givenCarePlans();

        carePlans[0].PJN_Therapy_Status__c = '';
        carePlans[0].PJN_Therapy_Sub_Status__c = '';
        carePlans[0].MVN_Pharmacy_Status__c = '';
        insert carePlans;

        withUpdatedCarePlans();
        System.assert(!carePlans[0].MVN_Share_with_RBM__c);

        carePlans[0].PJN_Therapy_Status__c = 'Cancelled';
        carePlans[0].PJN_Therapy_Sub_Status__c = 'Patient Deceased';
        
        Test.startTest();
        update carePlans[0];
        Test.stopTest();

        withUpdatedCarePlans();
        System.assert(carePlans[0].MVN_Share_with_RBM__c);        
    }

    static void givenCarePlans() {
        Id carePlanRecTypeId = SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('CarePlan')
            .getRecordTypeId();

        carePlans = new List<Case> {
            new Case (
                RecordTypeId = carePlanRecTypeId
            )
        };
    }

    static void withUpdatedCarePlans() {
        Set<Id> carePlanIds = new Set<Id>();
        for (Case carePlan : carePlans) {
            carePlanIds.add(carePlan.Id);
        }

        carePlans = [
            SELECT Id,
                   PJN_Therapy_Status__c,
                   PJN_Therapy_Sub_Status__c,
                   MVN_Pharmacy_Status__c,
                   MVN_Last_Pharmacy_Status_Update__c,
                   MVN_Days_in_Pharmacy_Status__c,
                   MVN_Last_Therapy_Status_Update__c,
                   MVN_Days_in_Therapy_Status__c,
                   MVN_Share_with_RBM__c
              FROM Case
             WHERE Id IN :carePlanIds
        ];
    }
}