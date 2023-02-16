/**
 * @author      Mavens
 * @group       MappingEngine
 * @description Unit tests for PJN_MappingEngineLabelHdlr
 */
@isTest(isParallel=true) private class PJN_MappingEngineLabelHdlrTest {
    @isTest private static void mapRecord() {
        PJN_MappingLabelQuery mockMappingLabelQuery = (PJN_MappingLabelQuery) Test.createStub(PJN_MappingLabelQuery.class, new PJN_MappingLabelMock());
        PJN_MappingEngineLabelHdlr actualMappingEngineLabelHdlr = new PJN_MappingEngineLabelHdlr();
        actualMappingEngineLabelHdlr.mappingLabelQuery = mockMappingLabelQuery;
        actualMappingEngineLabelHdlr.useMapping(
            new PJN_Mapping__mdt(
                MasterLabel = 'Mocked Mapping',
                DeveloperName = 'PJN_Mocked_Mapping',
                PJN_Source_Object_Type_Name__c = 'Case',
                PJN_Source_Object_API_Name__c = 'Case',
                PJN_Mapping_Type__c = 'PJN_Label'
            )
        );

        Case sourceCase = new Case(
            Subject = 'Test Source Case',
            Status = 'Open'
        );
        insert sourceCase;
        Case targetCase = new Case(
            Subject = 'Test Target Case'
        );

        Test.startTest();
            Case actualTargetCase = (Case) actualMappingEngineLabelHdlr.mapRecord(sourceCase, targetCase);
        Test.stopTest();

        System.assertEquals('Subject: ' + sourceCase.Subject + ', ' + sourceCase.Status, actualTargetCase.Description, 'Description is not set correctly');
    }

    @isTest private static void mapRecordError() {
        PJN_MappingLabelQuery mockMappingLabelQuery = (PJN_MappingLabelQuery) Test.createStub(PJN_MappingLabelQuery.class, new PJN_MappingLabelMock());
        PJN_MappingEngineLabelHdlr actualMappingEngineLabelHdlr = new PJN_MappingEngineLabelHdlr();
        actualMappingEngineLabelHdlr.mappingLabelQuery = mockMappingLabelQuery;
        PJN_Mapping__mdt mapping = new PJN_Mapping__mdt(
            MasterLabel = 'Mocked Mapping',
            DeveloperName = 'PJN_DOES_NOT_EXIST',
            PJN_Source_Object_Type_Name__c = 'Case',
            PJN_Source_Object_API_Name__c = 'Case',
            PJN_Mapping_Type__c = 'PJN_Label'
        );

        Test.startTest();
            try {
                actualMappingEngineLabelHdlr.useMapping(
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

    @isTest private static void getSourceFields() {
        PJN_MappingLabelQuery mockMappingLabelQuery = (PJN_MappingLabelQuery) Test.createStub(PJN_MappingLabelQuery.class, new PJN_MappingLabelMock());
        PJN_MappingEngineLabelHdlr actualMappingEngineLabelHdlr = new PJN_MappingEngineLabelHdlr();
        actualMappingEngineLabelHdlr.mappingLabelQuery = mockMappingLabelQuery;
        actualMappingEngineLabelHdlr.useMapping(
            new PJN_Mapping__mdt(
                MasterLabel = 'Mocked Mapping',
                DeveloperName = 'PJN_Mocked_Mapping',
                PJN_Source_Object_Type_Name__c = 'Case',
                PJN_Source_Object_API_Name__c = 'Case',
                PJN_Mapping_Type__c = 'PJN_Label'
            )
        );

        Test.startTest();
            List<String> actualFields = actualMappingEngineLabelHdlr.getSourceFields();
        Test.stopTest();

        System.assertEquals(3, actualFields.size(), 'number of fields are incorrect');
        System.assertEquals('Id', actualFields.get(0), 'Field is not set correctly');
        System.assertEquals('Subject', actualFields.get(1), 'Field is not set correctly');
        System.assertEquals('Status', actualFields.get(2), 'Field is not set correctly');
    }
}