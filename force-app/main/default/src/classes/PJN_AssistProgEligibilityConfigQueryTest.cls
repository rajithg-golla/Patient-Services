/**
 * @author      Mavens
 * @date        10/2020
 * @description Unit tests for PJN_AssistProgEligibilityConfigQuery
 * @group       AssistanceProgramEligibilty
 */
@isTest
public with sharing class PJN_AssistProgEligibilityConfigQueryTest {

    @isTest
    private static void itShouldGetAConfigRecordByDeveloperName() {
        Test.startTest();
        // exercise the query
        try {
            PJN_Assistance_Prog_Eligibility_Config__mdt config = (new PJN_AssistProgEligibilityConfigQuery())
                .getConfigurationByDevName('Test_Record');
        } catch (Exception ex) {}
        Test.stopTest();


    }
}