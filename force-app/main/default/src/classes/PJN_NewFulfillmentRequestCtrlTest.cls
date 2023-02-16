/**
 * @author      Mavens
 * @group       Fulfillment
 * @description Unit tests for PJN_NewFulfillmentRequestCtrl
 */
@isTest
public with sharing class PJN_NewFulfillmentRequestCtrlTest {

    @TestSetup
    static void makeData(){
        Case carePlan = new Case(
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            Status = 'Test',
            Subject = 'Care Plan',
            PJN_Program_DeveloperName__c = 'PJN_Test_Program'
        );
        insert careplan;
    }

    @isTest
    private static void getFulfillmentRequest() {
        // mocks
        PJN_MappingJobQuery mockMappingJobQuery = (PJN_MappingJobQuery) Test.createStub(PJN_MappingJobQuery.class, new PJN_MappingJobMock());
        PJN_MappingQuery mockMappingQuery = (PJN_MappingQuery) Test.createStub(PJN_MappingQuery.class, new PJN_MappingMock());
        PJN_MappingEngine.mappingJobQuery = mockMappingJobQuery;
        PJN_MappingEngine mockFulfillmentRequestMappingEngine = new PJN_MappingEngine();
        mockFulfillmentRequestMappingEngine.mappingQuery = mockMappingQuery;
        PJN_NewFulfillmentRequestCtrl.fulfillmentRequestMappingEngine = mockFulfillmentRequestMappingEngine;
        PJN_FulfillmentRequestCreationQuery mockFulfillmentRequestCreationQuery = (PJN_FulfillmentRequestCreationQuery) Test.createStub(PJN_FulfillmentRequestCreationQuery.class, new PJN_FulfillmentRequestCreateMock());
        PJN_NewFulfillmentRequestCtrl.fulfillmentRequestCreationQuery = mockFulfillmentRequestCreationQuery;

        // setup data
        RecordType expectedRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'PJN_Fulfillment_Request__c' AND IsActive = true LIMIT 1];
        Case carePlan = [SELECT Id, PJN_Program_DeveloperName__c FROM Case LIMIT 1];

        PJN_Fulfillment_Request__c expectedFulfillmentRequest = new PJN_Fulfillment_Request__c(
            PJN_Care_Plan__c = carePlan.Id,
            PJN_Program_DeveloperName__c = carePlan.PJN_Program_DeveloperName__c,
            RecordTypeId = expectedRecordType.Id
        );

        // run test
        Test.startTest();
            PJN_Fulfillment_Request__c actualFulfillmentRequest = PJN_NewFulfillmentRequestCtrl.getFulfillmentRequest(expectedFulfillmentRequest);
        Test.stopTest();

        // assert
        System.assertNotEquals(null, actualFulfillmentRequest, 'fulfillment request not populated at all');
        System.assertEquals(expectedFulfillmentRequest.PJN_Program_DeveloperName__c, actualFulfillmentRequest.PJN_Program_DeveloperName__c, 'fulfillment request program not set');
        System.assertEquals(expectedFulfillmentRequest.RecordTypeId, actualFulfillmentRequest.RecordTypeId, 'fulfillment request record type not set');
    }

    @isTest
    private static void getFulfillmentRequestNoMapping() {
        // mocks
        PJN_FulfillmentRequestCreationQuery mockFulfillmentRequestCreationQuery = (PJN_FulfillmentRequestCreationQuery) Test.createStub(PJN_FulfillmentRequestCreationQuery.class, new PJN_FulfillmentRequestCreateMock());
        PJN_NewFulfillmentRequestCtrl.fulfillmentRequestCreationQuery = mockFulfillmentRequestCreationQuery;

        // setup data
        RecordType expectedRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'PJN_Fulfillment_Request__c' AND IsActive = true LIMIT 1];
        Case carePlan = [SELECT Id, PJN_Program_DeveloperName__c FROM Case LIMIT 1 FOR UPDATE];
        carePlan.PJN_Program_DeveloperName__c = 'PJN_NO_MAPPING';
        update carePlan;

        PJN_Fulfillment_Request__c expectedFulfillmentRequest = new PJN_Fulfillment_Request__c(
            PJN_Care_Plan__c = carePlan.Id,
            PJN_Program_DeveloperName__c = carePlan.PJN_Program_DeveloperName__c,
            RecordTypeId = expectedRecordType.Id
        );

        // run test
        Test.startTest();
            PJN_Fulfillment_Request__c actualFulfillmentRequest = PJN_NewFulfillmentRequestCtrl.getFulfillmentRequest(expectedFulfillmentRequest);
        Test.stopTest();

        // assert
        System.assertNotEquals(null, actualFulfillmentRequest, 'fulfillment request not populated at all');
        System.assertEquals(expectedFulfillmentRequest.PJN_Program_DeveloperName__c, actualFulfillmentRequest.PJN_Program_DeveloperName__c, 'fulfillment request program not set');
        System.assertEquals(expectedFulfillmentRequest.RecordTypeId, actualFulfillmentRequest.RecordTypeId, 'fulfillment request record type not set');
    }

    @isTest
    private static void getFulfillmentRequestNoMappingJobError() {
        // mocks
        PJN_FulfillmentRequestCreationQuery mockFulfillmentRequestCreationQuery = (PJN_FulfillmentRequestCreationQuery) Test.createStub(PJN_FulfillmentRequestCreationQuery.class, new PJN_FulfillmentRequestCreateMock());
        PJN_NewFulfillmentRequestCtrl.fulfillmentRequestCreationQuery = mockFulfillmentRequestCreationQuery;

        // setup data
        RecordType expectedRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'PJN_Fulfillment_Request__c' AND IsActive = true LIMIT 1];
        Case carePlan = [SELECT Id, PJN_Program_DeveloperName__c FROM Case LIMIT 1];

        PJN_Fulfillment_Request__c expectedFulfillmentRequest = new PJN_Fulfillment_Request__c(
            PJN_Care_Plan__c = carePlan.Id,
            PJN_Program_DeveloperName__c = carePlan.PJN_Program_DeveloperName__c,
            RecordTypeId = expectedRecordType.Id
        );

        // run test
        Test.startTest();
            try {
                PJN_Fulfillment_Request__c actualFulfillmentRequest = PJN_NewFulfillmentRequestCtrl.getFulfillmentRequest(expectedFulfillmentRequest);
            } catch(AuraHandledException auraEx) {
                // assert
                System.assertNotEquals(null, auraEx, 'no expected exception');
                System.assert(
                    auraEx.getMessage().startsWith(
                        String.format(
                            Label.PJN_Contact_Admin,
                            new List<String> { '' }
                        )
                    ),
                    'incorrect message set'
                );
            }
        Test.stopTest();
    }

    @isTest
    private static void insertFulfillmentRequest() {
        // mocks
        PJN_MappingJobQuery mockMappingJobQuery = (PJN_MappingJobQuery) Test.createStub(PJN_MappingJobQuery.class, new PJN_MappingJobMock());
        PJN_MappingQuery mockMappingQuery = (PJN_MappingQuery) Test.createStub(PJN_MappingQuery.class, new PJN_MappingMock());
        PJN_MappingEngine.mappingJobQuery = mockMappingJobQuery;
        PJN_MappingEngine mockFulfillmentRequestMappingEngine = new PJN_MappingEngine();
        mockFulfillmentRequestMappingEngine.mappingQuery = mockMappingQuery;
        PJN_NewFulfillmentRequestCtrl.fulfillmentRequestMappingEngine = mockFulfillmentRequestMappingEngine;
        PJN_FulfillmentRequestCreationQuery mockFulfillmentRequestCreationQuery = (PJN_FulfillmentRequestCreationQuery) Test.createStub(PJN_FulfillmentRequestCreationQuery.class, new PJN_FulfillmentRequestCreateMock());
        PJN_NewFulfillmentRequestCtrl.fulfillmentRequestCreationQuery = mockFulfillmentRequestCreationQuery;

        // setup data
        RecordType expectedRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'PJN_Fulfillment_Request__c' AND IsActive = true LIMIT 1];
        Case carePlan = [SELECT Id, PJN_Program_DeveloperName__c FROM Case LIMIT 1];

        PJN_Assistance_Program__c assistanceProgram = new PJN_Assistance_Program__c(
            RecordTypeId = Schema.SObjectType.PJN_Assistance_Program__c.getRecordTypeInfosByDeveloperName().get('PJN_Copay').getRecordTypeId(),
            PJN_Care_Plan__c = carePlan.Id
        );
        insert assistanceProgram;
        
        PJN_Fulfillment_Request__c expectedFulfillmentRequest = new PJN_Fulfillment_Request__c(
            PJN_Care_Plan__c = carePlan.Id,
            PJN_Program_DeveloperName__c = carePlan.PJN_Program_DeveloperName__c,
            RecordTypeId = expectedRecordType.Id,
            MVN_Copay_Assistance_Program__c = assistanceProgram.Id
        );

        // run test
        Test.startTest();
            PJN_Fulfillment_Request__c actualFulfillmentRequest = PJN_NewFulfillmentRequestCtrl.getFulfillmentRequest(expectedFulfillmentRequest);
            insert actualFulfillmentRequest;
        Test.stopTest();

        // assert
        System.assertNotEquals(null, actualFulfillmentRequest, 'fulfillment request not populated at all');
        System.assertEquals(expectedFulfillmentRequest.PJN_Program_DeveloperName__c, actualFulfillmentRequest.PJN_Program_DeveloperName__c, 'fulfillment request program not set');
        System.assertEquals(expectedFulfillmentRequest.RecordTypeId, actualFulfillmentRequest.RecordTypeId, 'fulfillment request record type not set');
    }
}