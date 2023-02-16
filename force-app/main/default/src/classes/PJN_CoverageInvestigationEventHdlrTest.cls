/**
 * @author      Mavens
 * @date        05/2021
 * @description Coverage Investigation Event handler PJN_CoverageInvestigationEventHdlr unit tests
 * @group       CoverageInvestigation
 */
@isTest
public class PJN_CoverageInvestigationEventHdlrTest {

    private static final Integer DATA_SIZE = 200;

    @TestSetup
    static void makeData(){
        List<Case> carePlans = new List<Case>();

        for (Integer i=0; i<DATA_SIZE; i++) {
            carePlans.add(
                new Case(
                    Subject = 'Care plan',
                    RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId()
                )
            );
        }

        insert carePlans;

        List<PJN_Coverage_Investigation__c> investigations = new List<PJN_Coverage_Investigation__c>();
        for (Case carePlan : carePlans) {
            investigations.add(
                new PJN_Coverage_Investigation__c(
                    PJN_Care_Plan__c = carePlan.Id
                )
            );
        }

        insert investigations;
    }

    // Explicitly set the four trigger config values so that customers can delete them but
    // the unit tests can still run, test functionalty, and pass
    static {
        PJN_TriggerHandlerSettingQuery.triggerHandlerSettingBySObjectType.put(
            PJN_Event__c.getSObjectType(),
            new List<PJN_Trigger_Handler_Setting__mdt> {
                new PJN_Trigger_Handler_Setting__mdt(
                    DeveloperName = 'PJN_Event_After_Insert_Access_Type',
                    PJN_Class__c = 'PJN_CoverageInvestigationEventHdlr',
                    PJN_Event__c = 'AFTER_INSERT'
                ),
                new PJN_Trigger_Handler_Setting__mdt(
                    DeveloperName = 'PJN_Event_After_Insert_Access_Type',
                    PJN_Class__c = 'PJN_CoverageInvestigationEventHdlr',
                    PJN_Event__c = 'AFTER_UPDATE'
                ),
                new PJN_Trigger_Handler_Setting__mdt(
                    DeveloperName = 'PJN_Event_After_Insert_Access_Type',
                    PJN_Class__c = 'PJN_CoverageInvestigationEventHdlr',
                    PJN_Event__c = 'AFTER_DELETE'
                ),
                new PJN_Trigger_Handler_Setting__mdt(
                    DeveloperName = 'PJN_Event_After_Insert_Access_Type',
                    PJN_Class__c = 'PJN_CoverageInvestigationEventHdlr',
                    PJN_Event__c = 'AFTER_UNDELETE'
                )
            }
        );
    }

    @isTest
    private static void itShouldSetCoverageInvestigationAccessType() {
        List<PJN_Coverage_Investigation__c> investigations = [
            SELECT Id, PJN_Care_Plan__c FROM PJN_Coverage_Investigation__c
        ];

        System.assertEquals(DATA_SIZE, investigations.size());

        List<PJN_Event__c> events = new List<PJN_Event__c>();
        for (PJN_Coverage_Investigation__c investigation : investigations) {
            events.add(
                new PJN_Event__c(
                    PJN_Case__c = investigation.PJN_Care_Plan__c,
                    PJN_Coverage_Investigation__c = investigation.Id,
                    PJN_Access_Type__c = 'Commercial',
                    PJN_Start_Date__c = Date.today()
                )
            );
        }

        Test.startTest();
        insert events;
        Test.stopTest();

        System.assertEquals(200, [
            SELECT COUNT() FROM PJN_Coverage_Investigation__c WHERE PJN_Access_Type__c = 'Commercial'
        ], 'Coverage investigation access types not updated to "Commercial"');
    }

    @isTest
    private static void itShouldExitOutWhenNoInvestigationsToProcess() {
        // cover the return statement when no coverage invesitation attachded to event
        List<PJN_Coverage_Investigation__c> investigations = [
            SELECT Id, PJN_Care_Plan__c FROM PJN_Coverage_Investigation__c
        ];

        System.assertEquals(DATA_SIZE, investigations.size());

        List<PJN_Event__c> events = new List<PJN_Event__c>();
        for (PJN_Coverage_Investigation__c investigation : investigations) {
            events.add(
                new PJN_Event__c(
                    PJN_Case__c = investigation.PJN_Care_Plan__c,
                    PJN_Coverage_Investigation__c = investigation.Id,
                    PJN_Start_Date__c = Date.today()
                    // explicitly not setting access type
                )
            );
        }

        Test.startTest();
        insert events;
        Test.stopTest();

        System.assertEquals(0, [
            SELECT COUNT() FROM PJN_Coverage_Investigation__c WHERE PJN_Access_Type__c = 'Commercial'
        ], 'No coverage investigations should have been updated');
    }

    @isTest
    private static void itShouldHandleDeletedEvents() {
         // cover the return statement when no coverage invesitation attachded to event
         List<PJN_Coverage_Investigation__c> investigations = [
            SELECT Id, PJN_Care_Plan__c FROM PJN_Coverage_Investigation__c
        ];

        System.assertEquals(DATA_SIZE, investigations.size());

        List<PJN_Event__c> events = new List<PJN_Event__c>();
        for (PJN_Coverage_Investigation__c investigation : investigations) {
            events.add(
                new PJN_Event__c(
                    RecordTypeId = Schema.SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName().get('PJN_Therapy_Access').getRecordTypeId(),
                    PJN_Case__c = investigation.PJN_Care_Plan__c,
                    PJN_Coverage_Investigation__c = investigation.Id,
                    PJN_Start_Date__c = Date.today(),
                    PJN_Access_Type__c = 'Cash'
                )
            );
            events.add(
                new PJN_Event__c(
                    PJN_Case__c = investigation.PJN_Care_Plan__c,
                    PJN_Coverage_Investigation__c = investigation.Id,
                    PJN_Start_Date__c = Date.today().addDays(-1),
                    PJN_Access_Type__c = 'Commercial'
                )
            );
        }

        insert events;
        Test.startTest();
        delete [SELECT Id FROM PJN_Event__c WHERE PJN_Access_Type__c = 'Cash'];
        Test.stopTest();

        System.assertEquals(DATA_SIZE, [
            SELECT COUNT() FROM PJN_Coverage_Investigation__c WHERE PJN_Access_Type__c = 'Commercial'
        ], 'Deletion of records not hanlded correctly');
    }

    @isTest
    private static void itShouldHandleNoEventsRemaining() {
        List<PJN_Coverage_Investigation__c> investigations = [
            SELECT Id, PJN_Care_Plan__c FROM PJN_Coverage_Investigation__c
        ];

        System.assertEquals(DATA_SIZE, investigations.size());

        List<PJN_Event__c> events = new List<PJN_Event__c>();
        for (PJN_Coverage_Investigation__c investigation : investigations) {
            events.add(
                new PJN_Event__c(
                    PJN_Case__c = investigation.PJN_Care_Plan__c,
                    PJN_Coverage_Investigation__c = investigation.Id,
                    PJN_Access_Type__c = 'Commercial',
                    PJN_Start_Date__c = Date.today()
                )
            );
        }

        insert events;
        Test.startTest();
        delete events;
        Test.stopTest();

        System.assertEquals(DATA_SIZE, [
            SELECT COUNT() FROM PJN_Coverage_Investigation__c WHERE PJN_Access_Type__c = null
        ], 'Deleting event did not clear the access type');
    }
}