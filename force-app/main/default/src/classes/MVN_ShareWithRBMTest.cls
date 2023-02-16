/**
* @author Mavens
* @description Unit tests for MVN_ShareWithRBM
* @group RBM
*/
@isTest
public class MVN_ShareWithRBMTest {

    private static List<Case> carePlans;

    @isTest 
    private static void itShouldShareUsingTherapyStatusSetting() {
        givenCarePlans();

        carePlans[0].PJN_Therapy_Status__c = 'Cancelled';
        carePlans[0].PJN_Therapy_Sub_Status__c = 'Patient Deceased';
        carePlans[0].MVN_Pharmacy_Status__c = '';
        insert carePlans;

        withUpdatedCarePlans();

        MVN_RBMSharingSettingsQuery query = (MVN_RBMSharingSettingsQuery) Test.createStub(
            MVN_RBMSharingSettingsQuery.class,
             new MVN_RBMSharingSettingsQueryMock()
        );
        Test.startTest();
        MVN_ShareWithRBM.query = query;
        MVN_ShareWithRBM.share(carePlans);
        Test.stopTest();

        System.assert(carePlans[0].MVN_Share_with_RBM__c);
    }

    @isTest 
    private static void itShouldShareUsingPharmacyStatusSetting() {
        givenCarePlans();

        carePlans[0].PJN_Therapy_Status__c = 'Cancelled';
        carePlans[0].PJN_Therapy_Sub_Status__c = 'Patient Deceased';
        carePlans[0].MVN_Pharmacy_Status__c = '';
        insert carePlans;

        carePlans[0].MVN_Pharmacy_Status__c = 'Unknown';
        update carePlans[0];

        withUpdatedCarePlans();

        MVN_RBMSharingSettingsQuery query = (MVN_RBMSharingSettingsQuery) Test.createStub(
            MVN_RBMSharingSettingsQuery.class,
             new MVN_RBMSharingSettingsQueryMock()
        );
        Test.startTest();
        MVN_ShareWithRBM.query = query;
        MVN_ShareWithRBM.share(carePlans);
        Test.stopTest();

        System.assert(carePlans[0].MVN_Share_with_RBM__c);
    }

    @isTest 
    private static void itShouldNotShareWithoutTherapyOrPharmacyStatus() {
        givenCarePlans();
        Test.startTest();
        MVN_ShareWithRBM.share(carePlans);
        Test.stopTest();
        System.assert(!carePlans[0].MVN_Share_with_RBM__c);
    }

    static void givenCarePlans() {
        Id carePlanRecTypeId = SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('CarePlan')
            .getRecordTypeId();

        carePlans = new List<Case> {
            new Case (
                RecordTypeId = carePlanRecTypeId,
                PJN_Program_DeveloperName__c = 'MVN_EVK'
            )
        };
    }

    static void withUpdatedCarePlans() {
        Set<Id> carePlanIds = new Set<Id>();
        for (Case carePlan : carePlans) {
            carePlanIds.add(carePlan.Id);
        }

        carePlans = [
            SELECT Id,
                   PJN_Program_DeveloperName__c,
                   PJN_Therapy_Status__c,
                   PJN_Therapy_Sub_Status__c,
                   MVN_Pharmacy_Status__c,
                   MVN_Last_Pharmacy_Status_Update__c,
                   MVN_Days_in_Pharmacy_Status__c,
                   MVN_Last_Therapy_Status_Update__c,
                   MVN_Days_in_Therapy_Status__c,
                   MVN_Share_with_RBM__c
              FROM Case
             WHERE Id IN :carePlanIds
        ];
    }
}