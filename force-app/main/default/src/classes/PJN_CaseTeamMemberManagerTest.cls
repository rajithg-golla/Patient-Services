/**
* @author Mavens
* @date Jan 2019
* @description Test class for PJN_CaseTeamMemberManager
* @group TestFactory
*/
@isTest
private class PJN_CaseTeamMemberManagerTest {

    @TestSetup
    private static void setup() {
        PJN_TestFactoryCase caseFactory = new PJN_TestFactoryCase();
        Case carePlanCase = caseFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
                'Status' => 'Test',
                'Subject' => 'Care Plan Case'
            }
        );

        PJN_TestFactoryAccount accountFactory = new PJN_TestFactoryAccount();
        Account patient = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
                'LastName' => 'Patient Test'
            }
        );
        Account physician = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId(),
                'LastName' => 'Physician Test'
            }
        );
        Account physicianStaff = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Staff').getRecordTypeId(),
                'LastName' => 'Staff Test'
            }
        );
        Account caregiver = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Caregiver').getRecordTypeId(),
                'LastName' => 'Caregiver Test'
            }
        );

        Case activityCase = caseFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId(),
                'Status' => 'Test',
                'Subject' => 'Activity Case',
                'AccountId' => patient.Id,
                'PJN_Caregiver__c' => caregiver.Id,
                'PJN_Physician__c' => Physician.Id,
                'PJN_Staff__c' => PhysicianStaff.Id
            }
        );

        List<PJN_Case_Field_Configuration__mdt> configList = new PJN_TestFactoryCaseFieldConfiguration().createCaseFieldsConfigurationDefaulted();
        List<CaseTeamRole> caseTeamRoleList = new List<CaseTeamRole>();
        for (PJN_Case_Field_Configuration__mdt config : configList) {
            caseTeamRoleList.add(
                new CaseTeamRole(
                    Name = config.PJN_Case_Team_Role_Mapping__c,
                    AccessLevel = 'Read'
                )
            );
        }
        Database.insert(caseTeamRoleList, false);

        HealthCloudGA__ReciprocalRole__c healthCloudRole = new HealthCloudGA__ReciprocalRole__c(
            Name='Patient',
            HealthCloudGA__InverseRole__c='Caregiver',
            RecordTypeId=SObjectType.HealthCloudGA__ReciprocalRole__c.getRecordTypeInfosByName().get('Contact Role').getRecordTypeId()
        );
        insert healthCloudRole;
    }

    @isTest
    private static void testCreateTeamMemberOnParentIdUpdate() {
        Id carePlanRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();
        Case carePlanCase = [SELECT Id FROM Case WHERE RecordTypeId = :carePlanRTId LIMIT 1];
        Id activityRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        Case activityCase = [SELECT Id FROM Case WHERE RecordTypeId = :activityRTId LIMIT 1];
        Id patientRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
        Account patient = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId LIMIT 1];
        Id physicianRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId();
        Account physician = [SELECT Id FROM Account WHERE RecordTypeId = :physicianRTId LIMIT 1];
        Id staffRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Staff').getRecordTypeId();
        Account physicianStaff = [SELECT Id FROM Account WHERE RecordTypeId = :staffRTId LIMIT 1];
        Id caregiverRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Caregiver').getRecordTypeId();
        Account caregiver = [SELECT Id FROM Account WHERE RecordTypeId = :caregiverRTId LIMIT 1];

        Test.startTest();
            activityCase.ParentId = carePlanCase.Id;
            update activityCase;
        Test.stopTest();

        Id patientContactId = [SELECT PersonContactId FROM Account WHERE Id = :patient.Id].PersonContactId;
        System.assertEquals(1, [SELECT count() FROM CaseTeamMember
                                WHERE ParentId = :carePlanCase.Id
                                AND MemberId = :patientContactId]);

        Id PhysicianContactId = [SELECT PersonContactId FROM Account WHERE Id = :physician.Id].PersonContactId;
        System.assertEquals(1, [SELECT count() FROM CaseTeamMember
                                WHERE ParentId = :carePlanCase.Id
                                AND MemberId = :PhysicianContactId]);

        Id PhysicianStaffContactId = [SELECT PersonContactId FROM Account WHERE Id = :physicianStaff.Id].PersonContactId;
        System.assertEquals(1, [SELECT count() FROM CaseTeamMember
                                WHERE ParentId = :carePlanCase.Id
                                AND MemberId = :PhysicianStaffContactId]);

        Id caregiverContactId = [SELECT PersonContactId FROM Account WHERE Id = :caregiver.Id].PersonContactId;
        System.assertEquals(1, [SELECT count() FROM CaseTeamMember
                                WHERE ParentId = :carePlanCase.Id
                                AND MemberId = :caregiverContactId]);
    }

    @isTest
    private static void testCreateTeamMemberOnPatientUpdate() {
        Id carePlanRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();
        Case carePlanCase = [SELECT Id FROM Case WHERE RecordTypeId = :carePlanRTId LIMIT 1];
        Id activityRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        Case activityCase = [SELECT Id FROM Case WHERE RecordTypeId = :activityRTId LIMIT 1];
        Id patientRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
        Account patient = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId LIMIT 1];
        Id physicianRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId();
        Account physician = [SELECT Id FROM Account WHERE RecordTypeId = :physicianRTId LIMIT 1];
        Id staffRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Staff').getRecordTypeId();
        Account physicianStaff = [SELECT Id FROM Account WHERE RecordTypeId = :staffRTId LIMIT 1];
        Id caregiverRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Caregiver').getRecordTypeId();
        Account caregiver = [SELECT Id FROM Account WHERE RecordTypeId = :caregiverRTId LIMIT 1];

        activityCase.ParentId = carePlanCase.Id;
        update activityCase;

        PJN_TestFactoryAccount accountFactory = new PJN_TestFactoryAccount();
        Account patient2 = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
                'LastName' => 'Patient 2 Test'
            }
        );
        patient2 = [
            SELECT
                PersonContactId
            FROM
                Account
            WHERE
                Id =: patient2.Id
        ];

        Test.startTest();
            activityCase.AccountId = patient2.Id;
            update activityCase;
        Test.stopTest();

        List<CaseTeamMember> caseTeamMemberList = [
            SELECT
                ParentId,
                MemberId,
                TeamRoleId
            FROM
                CaseTeamMember
            WHERE
                ParentId =: carePlanCase.Id
            AND
               MemberId =: patient2.PersonContactId
        ];
        System.assert(!caseTeamMemberList.isEmpty());
    }
    @isTest
    private static void testCreateTeamMemberOnCarePlanUpdate() {
        Id carePlanRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();
        Case carePlanCase = [SELECT Id FROM Case WHERE RecordTypeId = :carePlanRTId LIMIT 1];
        Id activityRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        Case activityCase = [SELECT Id FROM Case WHERE RecordTypeId = :activityRTId LIMIT 1];
        Id patientRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
        Account patient = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId LIMIT 1];
        Id physicianRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId();
        Account physician = [SELECT Id FROM Account WHERE RecordTypeId = :physicianRTId LIMIT 1];
        Id staffRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Staff').getRecordTypeId();
        Account physicianStaff = [SELECT Id FROM Account WHERE RecordTypeId = :staffRTId LIMIT 1];
        Id caregiverRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Caregiver').getRecordTypeId();
        Account caregiver = [SELECT Id FROM Account WHERE RecordTypeId = :caregiverRTId LIMIT 1];
        activityCase.ParentId = carePlanCase.Id;
        update activityCase;

        PJN_TestFactoryAccount accountFactory = new PJN_TestFactoryAccount();
        Account patient2 = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
                'LastName' => 'Patient 2 Test'
            }
        );
        patient2 = [
            SELECT
                PersonContactId
            FROM
                Account
            WHERE
                Id =: patient2.Id
        ];

        Test.startTest();
            carePlanCase.AccountId = patient2.Id;
            update carePlanCase;
        Test.stopTest();

        System.assertEquals(1, [SELECT count() FROM CaseTeamMember WHERE ParentId = :carePlanCase.Id AND MemberId = :patient2.PersonContactId]);

        Id patientContactId = [SELECT PersonContactId FROM Account WHERE Id = :patient.Id].PersonContactId;
        System.assertEquals(1, [SELECT count() FROM CaseTeamMember WHERE ParentId = :carePlanCase.Id AND MemberId = :patientContactId]);

        Id PhysicianContactId = [SELECT PersonContactId FROM Account WHERE Id = :Physician.Id].PersonContactId;
        System.assertEquals(1, [SELECT count() FROM CaseTeamMember WHERE ParentId = :carePlanCase.Id AND MemberId = :PhysicianContactId]);

        Id PhysicianStaffContactId = [SELECT PersonContactId FROM Account WHERE Id = :PhysicianStaff.Id].PersonContactId;
        System.assertEquals(1, [SELECT count() FROM CaseTeamMember WHERE ParentId = :carePlanCase.Id AND MemberId = :PhysicianStaffContactId]);

        Id caregiverContactId = [SELECT PersonContactId FROM Account WHERE Id = :caregiver.Id].PersonContactId;
        System.assertEquals(1, [SELECT count() FROM CaseTeamMember WHERE ParentId = :carePlanCase.Id AND MemberId = :caregiverContactId]);
    }

    @isTest
    private static void testCreateTeamMemberOnCarePlanCreation() {
        Id activityRTId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        Case activityCase = [SELECT Id FROM Case WHERE RecordTypeId = :activityRTId LIMIT 1];
        Id patientRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
        Account patient = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId LIMIT 1];
        Id physicianRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId();
        Account physician = [SELECT Id FROM Account WHERE RecordTypeId = :physicianRTId LIMIT 1];
        Id staffRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Staff').getRecordTypeId();
        Account physicianStaff = [SELECT Id FROM Account WHERE RecordTypeId = :staffRTId LIMIT 1];

        Case carePlanCase = new Case(
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            Status = 'Test',
            Subject = 'Care Plan Case',
            AccountId = patient.Id,
            PJN_Physician__c = Physician.Id,
            PJN_Staff__c = PhysicianStaff.Id
        );

        Test.startTest();
            insert carePlanCase;
        Test.stopTest();

        Id patientContactId = [SELECT PersonContactId FROM Account WHERE Id = :patient.Id].PersonContactId;
        System.assertEquals(1, [SELECT count() FROM CaseTeamMember WHERE ParentId = :carePlanCase.Id AND MemberId = :patientContactId]);

        Id PhysicianContactId = [SELECT PersonContactId FROM Account WHERE Id = :Physician.Id].PersonContactId;
        System.assertEquals(1, [SELECT count() FROM CaseTeamMember WHERE ParentId = :carePlanCase.Id AND MemberId = :PhysicianContactId]);

        Id PhysicianStaffContactId = [SELECT PersonContactId FROM Account WHERE Id = :PhysicianStaff.Id].PersonContactId;
        System.assertEquals(1, [SELECT count() FROM CaseTeamMember WHERE ParentId = :carePlanCase.Id AND MemberId = :PhysicianStaffContactId]);
    }
}