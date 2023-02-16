/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_CarePlanUICtrl
 */
@isTest
public with sharing class PJN_CarePlanUICtrlTest {

    @TestSetup
    private static void setup() {
        Case expectedCase = new Case(
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            Status = 'Test',
            Subject = 'Care Plan'
        );
        insert expectedCase;
        List<HealthCloudGA__CarePlanProblem__c> expectedCarePlanProblems = new List<HealthCloudGA__CarePlanProblem__c> {
            new HealthCloudGA__CarePlanProblem__c(
                HealthCloudGA__CarePlan__c = expectedCase.Id,
                Name = 'Test Problem One',
                HealthCloudGA__SortOrder__c = 1,
                PJN_Program_Problem_DeveloperName__c = 'devname1'
            ),
            new HealthCloudGA__CarePlanProblem__c(
                HealthCloudGA__CarePlan__c = expectedCase.Id,
                Name = 'Test Problem',
                HealthCloudGA__SortOrder__c = 2,
                PJN_Program_Problem_DeveloperName__c = 'devname2'
            )
        };
        insert expectedCarePlanProblems;
    }

    @isTest
    private static void getCarePlanPathCoachingSettingsComponent() {
        Id carePlanRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();
        Case expectedCase = [SELECT Id FROM Case WHERE RecordTypeId = :carePlanRTId LIMIT 1];
        List<HealthCloudGA__CarePlanProblem__c> expectedCarePlanProblems = [SELECT Id, Name, HealthCloudGA__SortOrder__c FROM HealthCloudGA__CarePlanProblem__c WHERE HealthCloudGA__CarePlan__c =  :expectedCase.Id];

        Test.startTest();
            List<HealthCloudGA__CarePlanProblem__c> actualCarePlanProblems = PJN_CarePlanUICtrl.getCarePlanProblems(expectedCase.Id);
        Test.stopTest();

        System.assertEquals(2, actualCarePlanProblems.size());
        for(Integer index = 0; index < actualCarePlanProblems.size(); index++) {
            HealthCloudGA__CarePlanProblem__c expectedCarePlanProblem = expectedCarePlanProblems.get(index);
            HealthCloudGA__CarePlanProblem__c actualCarePlanProblem = actualCarePlanProblems.get(index);
            System.assertEquals(expectedCase.Id, actualCarePlanProblem.HealthCloudGA__CarePlan__c);
            System.assertEquals(expectedCarePlanProblem.Name, actualCarePlanProblem.Name);
            System.assertEquals(expectedCarePlanProblem.HealthCloudGA__SortOrder__c, actualCarePlanProblem.HealthCloudGA__SortOrder__c);
        }
    }

    @isTest
    private static void getAllWrappedCarePlanProblemsWithCases() {
        PJN_ProgramCaseQuery mockProgramCaseQuery = (PJN_ProgramCaseQuery) Test.createStub(PJN_ProgramCaseQuery.class, new PJN_ProgramCaseMock());
        PJN_CarePlanUICtrl.programCaseQuery = mockProgramCaseQuery;

        Id carePlanRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();
        Case expectedCase = [SELECT Id FROM Case WHERE RecordTypeId = :carePlanRTId LIMIT 1];
        List<HealthCloudGA__CarePlanProblem__c> expectedCarePlanProblems = [SELECT Id, Name, HealthCloudGA__SortOrder__c FROM HealthCloudGA__CarePlanProblem__c WHERE HealthCloudGA__CarePlan__c =  :expectedCase.Id];

        List<Case> carePlanProblemCases = new List<Case>();
        for (HealthCloudGA__CarePlanProblem__c problem : expectedCarePlanProblems) {
            carePlanProblemCases.add(new Case(
                ParentId = expectedCase.Id,
                PJN_CarePlan_Problem__c = problem.Id,
                Subject = problem.Id + ' 1',
                HealthCloudGA__DueDate__c = Date.today()
            ));
            carePlanProblemCases.add(new Case(
                ParentId = expectedCase.Id,
                PJN_CarePlan_Problem__c = problem.Id,
                Subject = problem.Id + ' 2',
                HealthCloudGA__DueDate__c = Date.today().addDays(1)
            ));
        }
        carePlanProblemCases.add(new Case(
            ParentId = expectedCase.Id,
            Subject = 'Additional Info Case',
            Status = 'Cancelled'
        ));
        // add a problem that has no cases yet
        expectedCarePlanProblems.add(
            new HealthCloudGA__CarePlanProblem__c(
                HealthCloudGA__CarePlan__c = expectedCase.Id,
                Name = 'Problem with no cases yet. Mock will provide the placeholders',
                HealthCloudGA__SortOrder__c = 3,
                PJN_Program_Problem_DeveloperName__c = 'PJN_Mocked_Program_Case_One'
            )
        );
        upsert expectedCarePlanProblems;

        insert carePlanProblemCases;

        Test.startTest();
        List<PJN_CarePlanProblemWrapper> actualCarePlanProblems = PJN_CarePlanUICtrl.getWrappedCarePlanProblems(expectedCase.Id, 'all');
        Test.stopTest();

        System.assertEquals(4, actualCarePlanProblems.size());

        // verify details of the first problem and it's two cases. Based on due date case with subject having 1 in it should show up first
        System.assertEquals(expectedCase.Id, actualCarePlanProblems[0].detail.HealthCloudGA__CarePlan__c);
        System.assertEquals(expectedCarePlanProblems[0].Name, actualCarePlanProblems[0].detail.Name);
        System.assertEquals(expectedCarePlanProblems[0].HealthCloudGA__SortOrder__c, actualCarePlanProblems[0].detail.HealthCloudGA__SortOrder__c);
        System.assertEquals(expectedCarePlanProblems[0].Id + ' 1', actualCarePlanProblems[0].cases[0].caseRecord.Subject);
        System.assertEquals(expectedCarePlanProblems[0].Id + ' 2', actualCarePlanProblems[0].cases[1].caseRecord.Subject);

        // verify details of the second problem and it's two cases. Based on due date case with subject having 1 in it should show up first
        System.assertEquals(expectedCase.Id, actualCarePlanProblems[1].detail.HealthCloudGA__CarePlan__c);
        System.assertEquals(expectedCarePlanProblems[1].Name, actualCarePlanProblems[1].detail.Name);
        System.assertEquals(expectedCarePlanProblems[1].HealthCloudGA__SortOrder__c, actualCarePlanProblems[1].detail.HealthCloudGA__SortOrder__c);
        System.assertEquals(expectedCarePlanProblems[1].Id + ' 1', actualCarePlanProblems[1].cases[0].caseRecord.Subject);
        System.assertEquals(expectedCarePlanProblems[1].Id + ' 2', actualCarePlanProblems[1].cases[1].caseRecord.Subject);

        // third problem should be the placeholder with the mocked program cases
        System.assertEquals(expectedCase.Id, actualCarePlanProblems[2].detail.HealthCloudGA__CarePlan__c);
        System.assertEquals('Mocked Program Case One', actualCarePlanProblems[2].cases[0].programCase.MasterLabel);
        System.assertEquals('Mocked Program Case Two', actualCarePlanProblems[2].cases[1].programCase.MasterLabel);

        // fourth problem should be additional details with one closed activity since we requested the variant 'all'
        System.assertEquals(null, actualCarePlanProblems[3].detail.HealthCloudGA__CarePlan__c);
        System.assertEquals(Label.PJN_Additional_Activities, actualCarePlanProblems[3].detail.Name);
        System.assertEquals('Additional Info Case', actualCarePlanProblems[3].cases[0].caseRecord.Subject);
    }

    @isTest
    private static void getOpenWrappedCarePlanProblemsWithCases() {
        Id carePlanRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();
        Case expectedCase = [SELECT Id FROM Case WHERE RecordTypeId = :carePlanRTId LIMIT 1];
        List<HealthCloudGA__CarePlanProblem__c> expectedCarePlanProblems = [SELECT Id, Name, HealthCloudGA__SortOrder__c FROM HealthCloudGA__CarePlanProblem__c WHERE HealthCloudGA__CarePlan__c =  :expectedCase.Id];

        List<Case> carePlanProblemCases = new List<Case>();
        for (HealthCloudGA__CarePlanProblem__c problem : expectedCarePlanProblems) {
            carePlanProblemCases.add(new Case(
                ParentId = expectedCase.Id,
                PJN_CarePlan_Problem__c = problem.Id,
                Subject = problem.Id + ' 1',
                HealthCloudGA__DueDate__c = Date.today(),
                Status = 'Cancelled'
            ));
            carePlanProblemCases.add(new Case(
                ParentId = expectedCase.Id,
                PJN_CarePlan_Problem__c = problem.Id,
                Subject = problem.Id + ' 2',
                HealthCloudGA__DueDate__c = Date.today().addDays(1)
            ));
        }
        carePlanProblemCases.add(new Case(
            ParentId = expectedCase.Id,
            Subject = 'Additional Info Case',
            Status = 'Cancelled'
        ));

        insert carePlanProblemCases;

        Test.startTest();
        //request only open
        List<PJN_CarePlanProblemWrapper> actualCarePlanProblems = PJN_CarePlanUICtrl.getWrappedCarePlanProblems(expectedCase.Id, 'open');
        Test.stopTest();

        System.assertEquals(3, actualCarePlanProblems.size(), actualCarePlanProblems);

        // verify details of the first problem and it's two cases. Based on due date case with subject having 1 in it should show up first
        System.assertEquals(expectedCase.Id, actualCarePlanProblems[0].detail.HealthCloudGA__CarePlan__c);
        System.assertEquals(expectedCarePlanProblems[0].Name, actualCarePlanProblems[0].detail.Name);
        System.assertEquals(expectedCarePlanProblems[0].HealthCloudGA__SortOrder__c, actualCarePlanProblems[0].detail.HealthCloudGA__SortOrder__c);
        System.assertEquals(expectedCarePlanProblems[0].Id + ' 2', actualCarePlanProblems[0].cases[0].caseRecord.Subject);

        // verify details of the second problem and it's two cases. Based on due date case with subject having 1 in it should show up first
        System.assertEquals(expectedCase.Id, actualCarePlanProblems[1].detail.HealthCloudGA__CarePlan__c);
        System.assertEquals(expectedCarePlanProblems[1].Name, actualCarePlanProblems[1].detail.Name);
        System.assertEquals(expectedCarePlanProblems[1].HealthCloudGA__SortOrder__c, actualCarePlanProblems[1].detail.HealthCloudGA__SortOrder__c);
        System.assertEquals(expectedCarePlanProblems[1].Id + ' 2', actualCarePlanProblems[1].cases[0].caseRecord.Subject);

        // third problem should be additional details with one closed activity since we requested the variant 'all'
        System.assertEquals(null, actualCarePlanProblems[2].detail.HealthCloudGA__CarePlan__c);
        System.assertEquals(Label.PJN_Additional_Activities, actualCarePlanProblems[2].detail.Name);
        System.assertEquals(0, actualCarePlanProblems[2].cases.size());
    }
}