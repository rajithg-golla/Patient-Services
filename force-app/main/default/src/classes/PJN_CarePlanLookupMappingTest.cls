@isTest(isParallel=true)
private with sharing class PJN_CarePlanLookupMappingTest {
    @testSetup
    private static void setupData() {
        CareProgram program = new CareProgram(
            Name = 'Test Program',
            PJN_Program_DeveloperName__c = 'PJN_CLP',
            StartDate = Date.today()
        );
        insert program;
        CareProgramProduct product = new CareProgramProduct(
            CareProgramId = program.Id,
            PJN_Program_Developer_Name__c = 'PJN_CLP',
            PJN_NDC__c = '1234567890',
            Name = 'Test Product'
        );
        insert product;
        Account patient = new Account(
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
            LastName = 'Test Patient'
        );
        Account physician = new Account(
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId(),
            LastName = 'Test Physician'
        );
        insert new List<Account> {patient, physician};

        Case careplan = new Case(
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            Status = 'Test',
            Subject = 'Care Plan',
            AccountId = patient.Id,
            PJN_Physician__c = physician.Id,
            PJN_Program_DeveloperName__c = 'PJN_CLP',
            PJN_Program__c = program.Id
        );
        insert careplan;
    }

    @isTest
    private static void insertNewPrescriptionOnCareplan() {
        Case careplan = [SELECT Id FROM Case LIMIT 1];
        HealthCloudGA__EhrMedicationPrescription__c prescriptionToInsert = new HealthCloudGA__EhrMedicationPrescription__c(
            PJN_Care_Plan__c = careplan.Id,
            PJN_Quantity__c = '30',
            PJN_Product__c = [SELECT Id FROM CareProgramProduct LIMIT 1].Id
        );

        Test.startTest();
            insert prescriptionToInsert;
        Test.stopTest();

        Case actualCarePlan = [SELECT Id, PJN_Primary_Prescription__c FROM Case WHERE Id = :careplan.Id];
        System.assertEquals(
            prescriptionToInsert.Id,
            actualCarePlan.PJN_Primary_Prescription__c,
            'Primary prescription not set correctly'
        );
    }

    @isTest
    private static void insertPrimaryPrescriptionOnCareplan() {
        Case careplan = [SELECT Id FROM Case LIMIT 1];
        HealthCloudGA__EhrMedicationPrescription__c prescriptionToInsert = new HealthCloudGA__EhrMedicationPrescription__c(
            PJN_Care_Plan__c = careplan.Id,
            PJN_Set_as_Primary__c = true,
            PJN_Quantity__c = '30',
            PJN_Product__c = [SELECT Id FROM CareProgramProduct LIMIT 1].Id
        );

        Test.startTest();
            insert prescriptionToInsert;
        Test.stopTest();

        Case actualCarePlan = [SELECT Id, PJN_Primary_Prescription__c FROM Case WHERE Id = :careplan.Id];
        System.assertEquals(
            prescriptionToInsert.Id,
            actualCarePlan.PJN_Primary_Prescription__c,
            'Primary prescription not set correctly'
        );
    }

    @isTest
    private static void updatePrimaryPrescriptionOnCareplan() {
        Case careplan = [SELECT Id FROM Case LIMIT 1];
        HealthCloudGA__EhrMedicationPrescription__c prescriptionToUpdate = new HealthCloudGA__EhrMedicationPrescription__c(
            PJN_Care_Plan__c = careplan.Id,
            PJN_Set_as_Primary__c = false,
            PJN_Quantity__c = '30',
            PJN_Product__c = [SELECT Id FROM CareProgramProduct LIMIT 1].Id
        );
        insert prescriptionToUpdate;

        Test.startTest();
            prescriptionToUpdate.PJN_Set_as_Primary__c = true;
            update prescriptionToUpdate;
        Test.stopTest();

        Case actualCarePlan = [SELECT Id, PJN_Primary_Prescription__c FROM Case WHERE Id = :careplan.Id];
        System.assertEquals(
            prescriptionToUpdate.Id,
            actualCarePlan.PJN_Primary_Prescription__c,
            'Primary prescription not set correctly'
        );
    }

    @isTest
    private static void insertMemberPlansOnCareplan() {
        Case careplan = [SELECT Id FROM Case LIMIT 1];
        PJN_Member_Plan__c primaryMemberPlanToInsert = new PJN_Member_Plan__c(
            PJN_Care_Plan__c = careplan.Id,
            PJN_Set_as_Active__c = true,
            PJN_Coverage_Order__c = 'Primary'
        );
        PJN_Member_Plan__c secondaryMemberPlanToInsert = new PJN_Member_Plan__c(
            PJN_Care_Plan__c = careplan.Id,
            PJN_Set_as_Active__c = true,
            PJN_Coverage_Order__c = 'Secondary'
        );

        Test.startTest();
            insert new List<PJN_Member_Plan__c> { primaryMemberPlanToInsert, secondaryMemberPlanToInsert };
        Test.stopTest();

        Case actualCarePlan = [SELECT Id, PJN_Primary_Member_Plan__c, PJN_Secondary_Member_Plan__c FROM Case WHERE Id = :careplan.Id];
        System.assertEquals(
            primaryMemberPlanToInsert.Id,
            actualCarePlan.PJN_Primary_Member_Plan__c,
            'Primary member plan not set correctly'
        );
        System.assertEquals(
            secondaryMemberPlanToInsert.Id,
            actualCarePlan.PJN_Secondary_Member_Plan__c,
            'Primary member plan not set correctly'
        );
    }
}