/**
 * @author      Mavens
 * @group       RBM
 * @description Unit tests for MVN_ShareWithRBMBatchSch
 */
@isTest 
public class MVN_ShareWithRBMBatchSchTest {
    
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
    static void itShouldExecuteBatch() {
        givenCarePlans();
        Test.startTest();
        MVN_ShareWithRBMBatchSch shareWithRBMBatch = new MVN_ShareWithRBMBatchSch();
        shareWithRBMBatch.execute(null);
        Test.stopTest();
    }

    @isTest 
    static void itShouldScheduleBatch() {
        givenCarePlans();
        Test.startTest();
        String cronExpression = '00 00 00 * * ? *';
        MVN_ShareWithRBMBatchSch.schedule(cronExpression);
        Test.stopTest();
    }

    static void givenCarePlans() {
        Id carePlanRecTypeId = SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('CarePlan')
            .getRecordTypeId();

        carePlans = new List<Case> {
            new Case (
                RecordTypeId = carePlanRecTypeId,
                PJN_Program_DeveloperName__c = 'MVN_EVK'
            )
        };
        insert carePlans;
    }

    static void withUpdatedCarePlans() {
        Set<Id> carePlanIds = new Set<Id>();
        for (Case carePlan : carePlans) {
            carePlanIds.add(carePlan.Id);
        }

        carePlans = [
            SELECT Id,
                   PJN_Program_DeveloperName__c,
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