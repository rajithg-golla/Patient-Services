/**
 * @author      Mavens
 * @date        11/2020
 * @description Unit tests for PJN_AssistanceProgramQuery
 * @group       CoverageInvestigation
 */
@isTest
public class PJN_AssistanceProgramQueryTest {

    @isTest
    private static void itShouldQueryActiveByCarePlanId() {
        //send in fields and expect nothing back. just exercising query as active could be anything
        Test.startTest();
        PJN_AssistanceProgramQuery assistanceProgramQuery = new PJN_AssistanceProgramQuery();
        List<PJN_Assistance_Program__c> programs = assistanceProgramQuery.activeByCarePlanId(
            new Set<String> {'Id', 'Name'}, new Set<Id>{}
        );
        Test.stopTest();

        System.assertEquals(0, programs.size());
    }
}