/**
 * @author      Mavens
 * @group       CaseActions
 * @description Unit tests for PJN_CloseCaseActionCtrl
 */
@isTest(isParallel=true) public with sharing class PJN_CloseCaseActionCtrlTest {
    @isTest private static void closeOpenCase() {
        Case thisCase = new Case();
        thisCase.Status = Label.PJN_Case_Quick_Open_Status;
        insert thisCase;

        Test.startTest();
            PJN_CloseCaseActionCtrl.closeCase(thisCase.Id);
        Test.stopTest();

        Case actualCase = [SELECT IsClosed FROM Case WHERE Id = :thisCase.Id];
        System.assertEquals(true, actualCase.IsClosed, 'case not closed');
    }

    @isTest private static void closeClosedCase() {
        Case thisCase = new Case();
        thisCase.Status = Label.PJN_Case_Quick_Close_Status;
        insert thisCase;

        Test.startTest();
            try {
                PJN_CloseCaseActionCtrl.closeCase(thisCase.Id);
            } catch(AuraHandledException ex) {
                System.assertEquals(
                    String.format(
                        Label.PJN_Close_Case_Error_Already_Closed_Message,
                        new List<String> {
                            thisCase.Status
                        }
                    ),
                    ex.getMessage(),
                    'incorrect error message for case already closed');
            }
        Test.stopTest();
    }

    @isTest private static void closeOpenCaseWithError() {
        Case thisCase = new Case();
        thisCase.Status = Label.PJN_Case_Quick_Open_Status;
        insert thisCase;
        Test.setReadOnlyApplicationMode(true);


        Test.startTest();
            try {
                PJN_CloseCaseActionCtrl.closeCase(thisCase.Id);
            } catch(AuraHandledException ex) {
                System.assert(
                    ex.getMessage().contains(
                        'Update failed.'
                    ),
                    'incorrect error message for case already closed');
            }
        Test.stopTest();

        Test.setReadOnlyApplicationMode(false);
    }
}