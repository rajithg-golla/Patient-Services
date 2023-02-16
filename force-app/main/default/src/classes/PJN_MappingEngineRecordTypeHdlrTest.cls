/**
 * @author      Mavens
 * @group       MappingEngine
 * @description Unit tests for PJN_MappingEngineRecordTypeHdlr
 */
@isTest(isParallel=true) private class PJN_MappingEngineRecordTypeHdlrTest {
    @isTest private static void mapRecord() {
        PJN_MappingRecordTypeQuery mockMappingRecordTypeQuery = (PJN_MappingRecordTypeQuery) Test.createStub(PJN_MappingRecordTypeQuery.class, new PJN_MappingRecordTypeMock());
        PJN_MappingEngineRecordTypeHdlr actualMappingEngineRecordTypeHdlr = new PJN_MappingEngineRecordTypeHdlr();
        actualMappingEngineRecordTypeHdlr.mappingRecordTypeQuery = mockMappingRecordTypeQuery;
        actualMappingEngineRecordTypeHdlr.useMapping(
            new PJN_Mapping__mdt(
                MasterLabel = 'Mocked Mapping',
                DeveloperName = 'PJN_Mocked_Mapping',
                PJN_Source_Object_Type_Name__c = 'Case',
                PJN_Source_Object_API_Name__c = 'Case',
                PJN_Always_Runs__c = true,
                PJN_Mapping_Type__c = 'PJN_Record_Type'
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
            Case actualTargetCase = (Case) actualMappingEngineRecordTypeHdlr.mapRecord(sourceCase, targetCase);
        Test.stopTest();

        Id expectedActivityRecordTypeId = Case.sObjectType
                                               .getDescribe()
                                               .getRecordTypeInfosByDeveloperName()
                                               .get('PJN_Activity')
                                               .getRecordTypeId();
        System.assertEquals(expectedActivityRecordTypeId, actualTargetCase.RecordTypeId, 'Record Type id is not set correctly');
    }

    @isTest private static void mapRecordError() {
        PJN_MappingRecordTypeQuery mockMappingRecordTypeQuery = (PJN_MappingRecordTypeQuery) Test.createStub(PJN_MappingRecordTypeQuery.class, new PJN_MappingRecordTypeMock());
        PJN_MappingEngineRecordTypeHdlr actualMappingEngineRecordTypeHdlr = new PJN_MappingEngineRecordTypeHdlr();
        actualMappingEngineRecordTypeHdlr.mappingRecordTypeQuery = mockMappingRecordTypeQuery;

        PJN_Mapping__mdt mapping = new PJN_Mapping__mdt(
            MasterLabel = 'Mocked Mapping',
            DeveloperName = 'PJN_DOES_NOT_EXIST',
            PJN_Source_Object_Type_Name__c = 'Case',
            PJN_Source_Object_API_Name__c = 'Case',
            PJN_Always_Runs__c = true,
            PJN_Mapping_Type__c = 'PJN_Record_Type'
        );

        Test.startTest();
            try {
                actualMappingEngineRecordTypeHdlr.useMapping(
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