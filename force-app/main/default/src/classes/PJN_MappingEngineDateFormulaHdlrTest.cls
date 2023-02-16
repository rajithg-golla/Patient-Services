/**
 * @author      Mavens
 * @group       MappingEngine
 * @description Unit tests for PJN_MappingEngineDateFormulaHdlr
 */
@isTest(isParallel=false)
private class PJN_MappingEngineDateFormulaHdlrTest {
    @isTest
    private static void mapRecord() {
        PJN_MappingDateFormulaQuery mockMappingDateFormulaQuery = (PJN_MappingDateFormulaQuery) Test.createStub(PJN_MappingDateFormulaQuery.class, new PJN_MappingDateFormulaMock());
        PJN_MappingEngineDateFormulaHdlr actualMappingEngineDateFormulaHdlr = new PJN_MappingEngineDateFormulaHdlr();
        actualMappingEngineDateFormulaHdlr.mappingDateFormulaQuery = mockMappingDateFormulaQuery;
        actualMappingEngineDateFormulaHdlr.useMapping(
            new PJN_Mapping__mdt(
                MasterLabel = 'Mocked Mapping',
                DeveloperName = 'PJN_Mocked_Mapping',
                PJN_Source_Object_Type_Name__c = 'Case',
                PJN_Source_Object_API_Name__c = 'Case',
                PJN_Mapping_Type__c = 'PJN_Date_Formula'
            )
        );

        Case sourceCase = new Case(
            Subject = 'Test Source Case',
            HealthCloudGA__DueDate__c = Date.today().addDays(1)
        );
        insert sourceCase;
        Case targetCase = new Case(
            Subject = 'Test Target Case'
        );

        Test.startTest();
        Case mappedCase = (Case) actualMappingEngineDateFormulaHdlr.mapRecord(sourceCase, targetCase);
        Test.stopTest();

        System.assertNotEquals(null, mappedCase.HealthCloudGA__SourceSystemModified__c, 'HealthCloudGA__SourceSystemModified__c is not set correctly');
        System.assertEquals(System.today().addDays(1), mappedCase.PJN_Override_Next_Activity__c, 'PJN_Override_Next_Activity__c is not set correctly');
        System.assertEquals(sourceCase.HealthCloudGA__DueDate__c.addDays(-1), mappedCase.HealthCloudGA__DueDate__c, 'HealthCloudGA__DueDate__c is not set correctly');
    }

    @isTest
    private static void mapRecordError() {
        PJN_MappingDateFormulaQuery mockMappingDateFormulaQuery = (PJN_MappingDateFormulaQuery) Test.createStub(PJN_MappingDateFormulaQuery.class, new PJN_MappingDateFormulaMock());
        PJN_MappingEngineDateFormulaHdlr actualMappingEngineDateFormulaHdlr = new PJN_MappingEngineDateFormulaHdlr();
        actualMappingEngineDateFormulaHdlr.mappingDateFormulaQuery = mockMappingDateFormulaQuery;
        PJN_Mapping__mdt mapping = new PJN_Mapping__mdt(
            MasterLabel = 'Mocked Mapping',
            DeveloperName = 'PJN_DOES_NOT_EXIST',
            PJN_Source_Object_Type_Name__c = 'Case',
            PJN_Source_Object_API_Name__c = 'Case',
            PJN_Mapping_Type__c = 'PJN_Date_Formula'
        );

        Test.startTest();
            try {
                actualMappingEngineDateFormulaHdlr.useMapping(
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

    @isTest
    private static void getSourceDateFormulas() {
        PJN_MappingDateFormulaQuery mockMappingDateFormulaQuery = (PJN_MappingDateFormulaQuery) Test.createStub(PJN_MappingDateFormulaQuery.class, new PJN_MappingDateFormulaMock());
        PJN_MappingEngineDateFormulaHdlr actualMappingEngineDateFormulaHdlr = new PJN_MappingEngineDateFormulaHdlr();
        actualMappingEngineDateFormulaHdlr.mappingDateFormulaQuery = mockMappingDateFormulaQuery;
        actualMappingEngineDateFormulaHdlr.useMapping(
            new PJN_Mapping__mdt(
                MasterLabel = 'Mocked Mapping',
                DeveloperName = 'PJN_Mocked_Mapping',
                PJN_Source_Object_Type_Name__c = 'Case',
                PJN_Source_Object_API_Name__c = 'Case',
                PJN_Mapping_Type__c = 'PJN_Date_Formula'
            )
        );

        Test.startTest();
            List<String> actualFields = actualMappingEngineDateFormulaHdlr.getSourceFields();
        Test.stopTest();

        System.assertEquals(2, actualFields.size(), 'number of fields are incorrect');
        System.assertEquals('Id', actualFields.get(0), 'field is not set correctly');
        System.assertEquals('HealthCloudGA__DueDate__c', actualFields.get(1), 'field is not set correctly');
    }
}