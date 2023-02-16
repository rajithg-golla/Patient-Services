/**
 * @author      Mavens
 * @group       MappingEngine
 * @description Unit tests for PJN_MappingEngineFieldHdlr
 */
@isTest(isParallel=true) private class PJN_MappingEngineFieldHdlrTest {
    @isTest private static void mapRecord() {
        PJN_MappingFieldQuery mockMappingFieldQuery = (PJN_MappingFieldQuery) Test.createStub(PJN_MappingFieldQuery.class, new PJN_MappingFieldMock());
        PJN_MappingEngineFieldHdlr actualMappingEngineFieldHdlr = new PJN_MappingEngineFieldHdlr();
        actualMappingEngineFieldHdlr.mappingFieldQuery = mockMappingFieldQuery;
        actualMappingEngineFieldHdlr.useMapping(
            new PJN_Mapping__mdt(
                MasterLabel = 'Mocked Mapping',
                DeveloperName = 'PJN_Mocked_Mapping',
                PJN_Source_Object_Type_Name__c = 'Account',
                PJN_Source_Object_API_Name__c = 'Account',
                PJN_Mapping_Type__c = 'PJN_Field'
            )
        );

        Account parentAccount = new Account(
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Organization').getRecordTypeId(),
            Name = 'Test Parent Account'
        );
        insert parentAccount;
        Account sourceAccount = new Account(
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Organization').getRecordTypeId(),
            ParentId = parentAccount.Id,
            Name = 'Test Source Account'
        );
        insert sourceAccount;
        Account targetAccount = new Account(
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Organization').getRecordTypeId(),
            Name = 'Test Target Account'
        );

        Test.startTest();
            Account actualTargetAccount = (Account) actualMappingEngineFieldHdlr.mapRecord(sourceAccount, targetAccount);
        Test.stopTest();

        System.assertEquals(false, actualTargetAccount.HealthCloudGA__Disabled__c, 'HealthCloudGA__Disabled__c is not set correctly');
    }

    @isTest private static void mapRecordError() {
        PJN_MappingFieldQuery mockMappingFieldQuery = (PJN_MappingFieldQuery) Test.createStub(PJN_MappingFieldQuery.class, new PJN_MappingFieldMock());
        PJN_MappingEngineFieldHdlr actualMappingEngineFieldHdlr = new PJN_MappingEngineFieldHdlr();
        actualMappingEngineFieldHdlr.mappingFieldQuery = mockMappingFieldQuery;
        PJN_Mapping__mdt mapping = new PJN_Mapping__mdt(
            MasterLabel = 'Mocked Mapping',
            DeveloperName = 'PJN_DOES_NOT_EXIST',
            PJN_Source_Object_Type_Name__c = 'Account',
            PJN_Source_Object_API_Name__c = 'Account',
            PJN_Mapping_Type__c = 'PJN_Field'
        );

        Test.startTest();
            try {
                actualMappingEngineFieldHdlr.useMapping(
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
        PJN_MappingFieldQuery mockMappingFieldQuery = (PJN_MappingFieldQuery) Test.createStub(PJN_MappingFieldQuery.class, new PJN_MappingFieldMock());
        PJN_MappingEngineFieldHdlr actualMappingEngineFieldHdlr = new PJN_MappingEngineFieldHdlr();
        actualMappingEngineFieldHdlr.mappingFieldQuery = mockMappingFieldQuery;
        actualMappingEngineFieldHdlr.useMapping(
            new PJN_Mapping__mdt(
                MasterLabel = 'Mocked Mapping',
                DeveloperName = 'PJN_Mocked_Mapping',
                PJN_Source_Object_Type_Name__c = 'Account',
                PJN_Source_Object_API_Name__c = 'Account',
                PJN_Mapping_Type__c = 'PJN_Field'
            )
        );

        Test.startTest();
            List<String> actualFields = actualMappingEngineFieldHdlr.getSourceFields();
        Test.stopTest();

        System.assertEquals(3, actualFields.size(), 'number of fields are incorrect');
        System.assertEquals('Id', actualFields.get(0), 'Field is not set correctly');
        System.assertEquals('Parent.Name', actualFields.get(1), 'Field is not set correctly');
        System.assertEquals('HealthCloudGA__Disabled__c', actualFields.get(2), 'Field is not set correctly');
    }
}