/**
 * @author      Mavens
 * @group       MappingEngine
 * @description Unit tests for PJN_MappingEngineQueueHdlr
 * isParallel is set to false as we are inserting a Group inside the PJN_QueueMock stub
 */
@isTest(isParallel=false) private class PJN_MappingEngineQueueHdlrTest {
    @isTest private static void mapRecord() {
        PJN_QueueQuery mockQueueQuery = (PJN_QueueQuery) Test.createStub(PJN_QueueQuery.class, new PJN_QueueMock());
        PJN_MappingQueueQuery mockMappingQueueQuery = (PJN_MappingQueueQuery) Test.createStub(PJN_MappingQueueQuery.class, new PJN_MappingQueueMock());
        PJN_MappingEngineQueueHdlr actualMappingEngineQueueHdlr = new PJN_MappingEngineQueueHdlr();
        actualMappingEngineQueueHdlr.queueQuery = mockQueueQuery;
        actualMappingEngineQueueHdlr.mappingQueueQuery = mockMappingQueueQuery;
        actualMappingEngineQueueHdlr.useMapping(
            new PJN_Mapping__mdt(
                MasterLabel = 'Mocked Mapping',
                DeveloperName = 'PJN_Mocked_Mapping',
                PJN_Source_Object_Type_Name__c = 'Case',
                PJN_Source_Object_API_Name__c = 'Case',
                PJN_Always_Runs__c = true,
                PJN_Mapping_Type__c = 'PJN_Queue'
            )
        );

        Case sourceCase = new Case(
            Subject = 'Test Source Case'
        );
        insert sourceCase;
        Case targetCase = new Case(
            Subject = 'Test Target Case'
        );

        Test.startTest();
            Case actualTargetCase = (Case) actualMappingEngineQueueHdlr.mapRecord(sourceCase, targetCase);
        Test.stopTest();

        Id expectedQueueId = [SELECT Id FROM Group WHERE DeveloperName = 'PJN_Test_Queue'].Id;
        System.assertEquals(expectedQueueId, actualTargetCase.OwnerId, 'Owner id is not set correctly');
    }

    @isTest private static void mapRecordError() {
        PJN_MappingQueueQuery mockMappingQueueQuery = (PJN_MappingQueueQuery) Test.createStub(PJN_MappingQueueQuery.class, new PJN_MappingQueueMock());
        PJN_MappingEngineQueueHdlr actualMappingEngineQueueHdlr = new PJN_MappingEngineQueueHdlr();
        actualMappingEngineQueueHdlr.mappingQueueQuery = mockMappingQueueQuery;

        PJN_Mapping__mdt mapping = new PJN_Mapping__mdt(
            MasterLabel = 'Mocked Mapping',
            DeveloperName = 'PJN_DOES_NOT_EXIST',
            PJN_Source_Object_Type_Name__c = 'Case',
            PJN_Source_Object_API_Name__c = 'Case',
            PJN_Always_Runs__c = true,
            PJN_Mapping_Type__c = 'PJN_Queue'
        );

        Test.startTest();
            try {
                actualMappingEngineQueueHdlr.useMapping(
                    mapping
                );
                System.assertEquals(1, 0, 'No error thrown...');
            } catch(PJN_MappingEngineException ex) {
                System.assertEquals(
                    'No specific Mapping for ' + mapping.Label + '(' + mapping.DeveloperName + ') found.',
                    ex.getMessage(),
                    'Error not thrown correctly'
                );
            } catch(Exception ex) {
                System.assertEquals(1, 0, 'Unexpected error thrown...');
            }
        Test.stopTest();
    }
}