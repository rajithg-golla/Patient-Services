/**
 * @author      Mavens
 * @group       CareGiverHandlerMVN
 * @description Unit tests for CareGiverHandlerMVN
 */
@isTest (isParallel=true)
public class CareGiverHandlerTestMVN {

    private static final Integer DATA_SIZE = 200;

    @TestSetup
    static void makeData() {
        System.runAs(new User(Id=UserInfo.getUserId())) {
            List<CaseTeamRole> ctr = [SELECT Id FROM CaseTeamRole WHERE Name='Caregiver'];
            if (ctr.isEmpty()) {
                insert new CaseTeamRole(Name='Caregiver', AccessLevel='None');
            }
        }

        List<Account> programParticipants = new List<Account>();
        for (Integer i=0; i<DATA_SIZE; i++) {
            programParticipants.add(
                new Account(
                    LastName = 'Test Account' + i,
                    RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Program_Participant_MVN').getRecordTypeId()
                )
            );
        }
        insert programParticipants;

        List<Case> carePlans = new List<Case>();
        Id carePlanRecTypeId = SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('CarePlan')
            .getRecordTypeId();

        for (Account programParticipant : programParticipants) {
            carePlans.add(
                new Case (
                    // set the override so tests don't rely on configuration
                    RecordTypeId = carePlanRecTypeId,
                    AccountId = programParticipant.Id
                )
            );
        }

        insert carePlans;
    }

    @isTest
    private static void itShouldSetParticipantAsPrimaryWhenNoCareGiver() {
        List<Account> participants = [SELECT Id, Caregiver_Primary_on_Conversion_MVN__c FROM Account];
        for (Account participant : participants) {
            participant.Caregiver_Primary_on_Conversion_MVN__c = 'No';
        }

        update participants;

        List<Id> carePlanIds = new List<Id>((new Map<Id, Case>([SELECT Id FROM Case])).keySet());
        Test.startTest();
        CareGiverHandlerMVN.createCareGivers(carePlanIds);
        Test.stopTest();

        System.assertEquals(200, [
            SELECT COUNT() FROM Case WHERE Primary_Contact_MVN__c IN :participants
        ]);
    }

    @isTest
    private static void itShouldSetPrimaryAsCareGiver() {
        List<Account> participants = [
            SELECT
                Id,
                Caregiver_Primary_on_Conversion_MVN__c,
                Caregiver_First_Name_on_Conversion_MVN__c,
                Caregiver_Last_Name_on_Conversion_MVN__c,
                Caregiver_Gender_on_Conversion_MVN__c
            FROM
                Account
        ];
        for (Account participant : participants) {
            participant.Caregiver_Primary_on_Conversion_MVN__c = 'Yes';
            participant.Caregiver_First_Name_on_Conversion_MVN__c = 'First';
            participant.Caregiver_Last_Name_on_Conversion_MVN__c = 'Last';
            participant.Caregiver_Gender_on_Conversion_MVN__c = 'Female';
        }

        update participants;

        List<Id> carePlanIds = new List<Id>((new Map<Id, Case>([SELECT Id FROM Case])).keySet());
        Test.startTest();
        CareGiverHandlerMVN.createCareGivers(carePlanIds);
        Test.stopTest();

        List<case> carePlans = [
            SELECT Primary_Contact_MVN__r.FirstName, Primary_Contact_MVN__r.LastName, Primary_Contact_MVN__r.HealthCloudGA__Gender__pc
            FROM Case
            WHERE Primary_Contact_MVN__c NOT IN :participants
            AND Primary_Contact_MVN__r.RecordType.DeveloperName = 'PJN_Caregiver'
        ];

        System.assertEquals(200, carePlans.size());
        for (Case carePlan : carePlans) {
            System.assertEquals('First', carePlan.Primary_Contact_MVN__r.FirstName);
            System.assertEquals('Last', carePlan.Primary_Contact_MVN__r.LastName);
            System.assertEquals('Female', carePlan.Primary_Contact_MVN__r.HealthCloudGA__Gender__pc);
        }

        Id careGiverRoleId = [SELECT Id FROM CaseTeamRole WHERE Name = 'Caregiver'].Id;
        System.assertEquals(200, [
            SELECT COUNT() FROM CaseTeamMember WHERE TeamRoleId = :careGiverRoleId
        ]);
    }

    @isTest
    private static void itShouldNOTSetPrimaryAsCareGiver() {
        List<Account> participants = [
            SELECT
                Id,
                Caregiver_Primary_on_Conversion_MVN__c,
                Caregiver_First_Name_on_Conversion_MVN__c,
                Caregiver_Last_Name_on_Conversion_MVN__c,
                Caregiver_Gender_on_Conversion_MVN__c
            FROM
                Account
        ];
        for (Account participant : participants) {
            participant.Caregiver_Primary_on_Conversion_MVN__c = 'No';
            participant.Caregiver_First_Name_on_Conversion_MVN__c = 'First';
            participant.Caregiver_Last_Name_on_Conversion_MVN__c = 'Last';
            participant.Caregiver_Gender_on_Conversion_MVN__c = 'Female';
        }

        update participants;

        List<Id> carePlanIds = new List<Id>((new Map<Id, Case>([SELECT Id FROM Case])).keySet());
        Test.startTest();
        CareGiverHandlerMVN.createCareGivers(carePlanIds);
        Test.stopTest();

        List<case> carePlans = [
            SELECT AccountId, Primary_Contact_MVN__c
            FROM Case
            WHERE Primary_Contact_MVN__c IN :participants
            AND Primary_Contact_MVN__r.RecordType.DeveloperName = 'Program_Participant_MVN'
        ];

        System.assertEquals(200, carePlans.size());
        for (Case carePlan : carePlans) {
            System.assertEquals(carePlan.AccountId, carePlan.Primary_Contact_MVN__c);
        }

        Id careGiverRoleId = [SELECT Id FROM CaseTeamRole WHERE Name = 'Caregiver'].Id;
        System.assertEquals(200, [
            SELECT COUNT() FROM CaseTeamMember WHERE TeamRoleId = :careGiverRoleId
        ]);
    }

    @isTest
    private static void itShouldErrorIfCareGiverRoleIsNotAvailable() {

        List<Account> participants = [
            SELECT
                Id,
                Caregiver_Primary_on_Conversion_MVN__c,
                Caregiver_First_Name_on_Conversion_MVN__c,
                Caregiver_Last_Name_on_Conversion_MVN__c,
                Caregiver_Gender_on_Conversion_MVN__c
            FROM
                Account
        ];
        for (Account participant : participants) {
            participant.Caregiver_Primary_on_Conversion_MVN__c = 'Yes';
            participant.Caregiver_First_Name_on_Conversion_MVN__c = 'First';
            participant.Caregiver_Last_Name_on_Conversion_MVN__c = 'Last';
            participant.Caregiver_Gender_on_Conversion_MVN__c = 'Female';
        }

        update participants;

        List<Id> carePlanIds = new List<Id>((new Map<Id, Case>([SELECT Id FROM Case])).keySet());

        Boolean exceptionCaptured = false;
        Test.startTest();
        String tempValue = CareGiverHandlerMVN.CAREGIVER_ROLE_NAME;
        CareGiverHandlerMVN.CAREGIVER_ROLE_NAME = 'Bad Value';
        try {
            CareGiverHandlerMVN.createCareGivers(carePlanIds);
        } catch (CareGiverHandlerMVN.CareGiverHandlerMVNException ex) {
            exceptionCaptured = true;
        }
        Test.stopTest();
        CareGiverHandlerMVN.CAREGIVER_ROLE_NAME = tempValue;
        System.assert(exceptionCaptured, 'no exception captured');
    }
}