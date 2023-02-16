/**
 * @author      Mavens
 * @group       MappingEngine
 * @description Unit tests for PJN_MappingEngineHdlr & PJN_MappingEngineMockHdlr
 */
@isTest(isParallel=true) private with sharing class PJN_MappingEngineHdlrTest {
    @isTest private static void useMapping() {
        PJN_Mapping__mdt mapping = new PJN_Mapping__mdt(
            MasterLabel = 'Mocked Mapping',
            DeveloperName = 'PJN_DOES_NOT_EXIST',
            PJN_Source_Object_Type_Name__c = 'Case',
            PJN_Source_Object_API_Name__c = 'Case',
            PJN_Mapping_Type__c = 'PJN_Field'
        );
        PJN_MappingEngineMockHdlr mappingEngineHdlr = new PJN_MappingEngineMockHdlr();

        Test.startTest();
            mappingEngineHdlr.useMapping(mapping);
        Test.stopTest();

        System.assertEquals(mapping.DeveloperName, mappingEngineHdlr.mapping.DeveloperName);
    }

    @isTest private static void mapRecord() {
        Case sourceCase = new Case(
            Subject = 'Test Source Case'
        );
        insert sourceCase;
        Case targetCase = new Case(
            Subject = 'Test Target Case'
        );
        insert targetCase;
        PJN_MappingEngineMockHdlr mappingEngineHdlr = new PJN_MappingEngineMockHdlr();

        Test.startTest();
            Case actualCase = (Case) mappingEngineHdlr.mapRecord(sourceCase.Id, targetCase);
        Test.stopTest();

        System.assertEquals(targetCase.Id, actualCase.Id);
        System.assertNotEquals(sourceCase.Subject, actualCase.Subject);
    }

    @isTest private static void mapRecordMultiple() {
        Case sourceCase = new Case(
            Subject = 'Test Source Case'
        );
        insert sourceCase;
        Case targetCase = new Case(
            Subject = 'Test Target Case'
        );
        insert targetCase;
        PJN_MappingEngineMockHdlr mappingEngineHdlr = new PJN_MappingEngineMockHdlr();

        Test.startTest();
            List<SObject> actualCases = mappingEngineHdlr.maprecord(new List<Id> { sourceCase.Id }, new List<SObject> { targetCase });
        Test.stopTest();

        System.assertEquals(1, actualCases.size());
        Case actualCase = (Case) actualCases.get(0);
        System.assertEquals(targetCase.Id, actualCase.Id);
        System.assertNotEquals(sourceCase.Subject, actualCase.Subject);
    }
}