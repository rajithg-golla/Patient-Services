/**
 * @author      Mavens
 * @group       CarePlan-UI
 * @description Unit tests for PJN_CarePlanProblemWrapper
 */
@isTest(isParallel=true) private class PJN_CarePlanProblemWrapperTest {

    @isTest private static void itShouldConstructWrappedProblemWithCases() {
        String programDeveloperName = [SELECT DeveloperName FROM PJN_Program__mdt LIMIT 1].DeveloperName;
        String programProblemDeveloperName = [SELECT DeveloperName FROM PJN_Program_Problem__mdt WHERE PJN_Program__r.DeveloperName = :programDeveloperName LIMIT 1].DeveloperName;
        Case carePlan = new Case(
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            PJN_Program_DeveloperName__c = programDeveloperName,
            Subject = 'Care Plan'
        );
        insert carePlan;
        HealthCloudGA__CarePlanProblem__c problem = new HealthCloudGA__CarePlanProblem__c(
            HealthCloudGA__CarePlan__c = carePlan.Id,
            Name = 'Test Problem One',
            PJN_Status__c = 'Planned',
            PJN_Program_Problem_DeveloperName__c = programProblemDeveloperName,
            HealthCloudGA__SortOrder__c = 1
        );
        insert problem;

        List<Case> cases = new List<Case>{
            new Case(PJN_CarePlan_Problem__c = problem.Id, Subject = 'Case 1'),
            new Case(PJN_CarePlan_Problem__c = problem.Id, Subject = 'Case 2')
        };
        insert cases;

        // query for the prolem and all of it's cases
        problem = PJN_CarePlanProblemQuery.queryByCarePlanId(carePlan.Id, true)[0];
        PJN_CarePlanProblemWrapper wrapper;
        Test.startTest();
        wrapper = new PJN_CarePlanProblemWrapper(problem);
        Test.stopTest();

        System.assertEquals(problem.Id, wrapper.detail.Id);
        System.assertEquals(2, wrapper.cases.size());

    }
}