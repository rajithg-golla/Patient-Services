/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_CarePlanPathProblemActionsCtrl
 */
@isTest(isParallel=true) public with sharing class PJN_CarePlanPathProblemActionsCtrlTest {
    @isTest private static void startCarePlanProblem() {
        MVN_ProgramEventHdlr.programEventQuery = (MVN_ProgramEventQuery) Test.createStub(
            MVN_ProgramEventQuery.class,
             new MVN_ProgramEventQueryMock()
        );
        String programDeveloperName = [SELECT DeveloperName FROM PJN_Program__mdt LIMIT 1].DeveloperName;
        String programProblemDeveloperName = [SELECT DeveloperName FROM PJN_Program_Problem__mdt WHERE PJN_Program__r.DeveloperName = :programDeveloperName LIMIT 1].DeveloperName;
        Account expectedAccount = new Account(
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
            FirstName = 'Test',
            LastName = 'Ing'
        );
        insert expectedAccount;
        Case expectedCase = new Case(
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            AccountId = expectedAccount.Id,
            PJN_Program_DeveloperName__c = programDeveloperName,
            MVN_Coordinator__c = UserInfo.getUserId(),
            Subject = 'Care Plan'
        );
        insert expectedCase;
        HealthCloudGA__CarePlanProblem__c expectedCarePlanProblem = new HealthCloudGA__CarePlanProblem__c(
            HealthCloudGA__CarePlan__c = expectedCase.Id,
            Name = 'Test Problem One',
            PJN_Status__c = 'Planned',
            PJN_Program_Problem_DeveloperName__c = programProblemDeveloperName,
            HealthCloudGA__SortOrder__c = 1
        );
        insert expectedCarePlanProblem;
        expectedCarePlanProblem = PJN_CarePlanProblemQuery.queryById(expectedCarePlanProblem.Id);

        Test.startTest();
            Boolean isSuccess = PJN_CarePlanPathProblemActionsCtrl.startCarePlanProblem(expectedCarePlanProblem);
        Test.stopTest();

        System.assertEquals(true, isSuccess);
        HealthCloudGA__CarePlanProblem__c actualCarePlanProblem = [SELECT Id, PJN_Status__c FROM HealthCloudGA__CarePlanProblem__c WHERE Id = :expectedCarePlanProblem.Id];
        System.assertEquals(expectedCarePlanProblem.Id, actualCarePlanProblem.Id);
        System.assertNotEquals(expectedCarePlanProblem.PJN_Status__c, actualCarePlanProblem.PJN_Status__c);
    }

    @isTest private static void skipCarePlanProblem() {
        String programDeveloperName = [SELECT DeveloperName FROM PJN_Program__mdt LIMIT 1].DeveloperName;
        String programProblemDeveloperName = [SELECT DeveloperName FROM PJN_Program_Problem__mdt WHERE PJN_Program__r.DeveloperName = :programDeveloperName LIMIT 1].DeveloperName;
        Account expectedAccount = new Account(
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId(),
            FirstName = 'Test',
            LastName = 'Ing'
        );
        insert expectedAccount;
        Case expectedCase = new Case(
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            AccountId = expectedAccount.Id,
            PJN_Program_DeveloperName__c = programDeveloperName,
            Subject = 'Care Plan'
        );
        insert expectedCase;
        HealthCloudGA__CarePlanProblem__c expectedCarePlanProblem = new HealthCloudGA__CarePlanProblem__c(
            HealthCloudGA__CarePlan__c = expectedCase.Id,
            Name = 'Test Problem One',
            PJN_Status__c = 'Planned',
            PJN_Program_Problem_DeveloperName__c = programProblemDeveloperName,
            HealthCloudGA__SortOrder__c = 1
        );
        insert expectedCarePlanProblem;
        expectedCarePlanProblem = PJN_CarePlanProblemQuery.queryById(expectedCarePlanProblem.Id);

        Test.startTest();
            Boolean isSuccess = PJN_CarePlanPathProblemActionsCtrl.skipCarePlanProblem(expectedCarePlanProblem);
        Test.stopTest();

        System.assertEquals(true, isSuccess);
        HealthCloudGA__CarePlanProblem__c actualCarePlanProblem = [SELECT Id, PJN_Status__c FROM HealthCloudGA__CarePlanProblem__c WHERE Id = :expectedCarePlanProblem.Id];
        System.assertEquals(expectedCarePlanProblem.Id, actualCarePlanProblem.Id);
        System.assertNotEquals(expectedCarePlanProblem.PJN_Status__c, actualCarePlanProblem.PJN_Status__c);
    }

    @isTest private static void deleteCarePlanProblem() {
        String programDeveloperName = [SELECT DeveloperName FROM PJN_Program__mdt LIMIT 1].DeveloperName;
        String programProblemDeveloperName = [SELECT DeveloperName FROM PJN_Program_Problem__mdt WHERE PJN_Program__r.DeveloperName = :programDeveloperName LIMIT 1].DeveloperName;
        Account expectedAccount = new Account(
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId(),
            FirstName = 'Test',
            LastName = 'Ing'
        );
        insert expectedAccount;
        Case expectedCase = new Case(
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            AccountId = expectedAccount.Id,
            PJN_Program_DeveloperName__c = programDeveloperName,
            Subject = 'Care Plan'
        );
        insert expectedCase;
        HealthCloudGA__CarePlanProblem__c expectedCarePlanProblem = new HealthCloudGA__CarePlanProblem__c(
            HealthCloudGA__CarePlan__c = expectedCase.Id,
            Name = 'Test Problem One',
            PJN_Status__c = 'Planned',
            PJN_Program_Problem_DeveloperName__c = programProblemDeveloperName,
            HealthCloudGA__SortOrder__c = 1
        );
        insert expectedCarePlanProblem;
        expectedCarePlanProblem = PJN_CarePlanProblemQuery.queryById(expectedCarePlanProblem.Id);

        Test.startTest();
            Boolean isSuccess = PJN_CarePlanPathProblemActionsCtrl.deleteCarePlanProblem(expectedCarePlanProblem);
        Test.stopTest();

        System.assertEquals(true, isSuccess);
        try {
            HealthCloudGA__CarePlanProblem__c actualCarePlanProblem = [SELECT Id, PJN_Status__c FROM HealthCloudGA__CarePlanProblem__c WHERE Id = :expectedCarePlanProblem.Id];
            System.assert(false, 'if this is executed, something went wrong');
        } catch(System.QueryException queryException) {
            System.assertEquals('List has no rows for assignment to SObject', queryException.getMessage());
        }
    }
}