/**
 * @author      Mavens
 * @date        11/2020
 * @description Unit tests for PJN_SPRoundRobinCtrl
 * @group       Specialty Pharmacy
 */
@isTest
public class PJN_SPRoundRobinCtrlTest {

    @TestSetup
    static void makeData(){
        System.runAs(getRunningUser()) {
            CareProgram program = new CareProgram(
                Name = 'Test Program',
                PJN_Program_DeveloperName__c = 'PJN_CLP',
                StartDate = Date.today()
            );
            insert program;

            Map<String, RecordTypeInfo> accountRecTypes = SObjectType.Account.getRecordTypeInfosByDeveloperName();

            Id pharmacyRecTypeId = accountRecTypes.get('PJN_Pharmacy').getRecordTypeId();
            Account specialtyPharmacy1 = new Account( Name = 'Pharmacy 1', RecordTypeId = pharmacyRecTypeId, Site = 'Pharmacy 1 Site');
            Account specialtyPharmacy2 = new Account( Name = 'Pharmacy 2', RecordTypeId = pharmacyRecTypeId, Site = 'Pharmacy 2 Site');
            Account specialtyPharmacy3 = new Account( Name = 'Pharmacy 3', RecordTypeId = pharmacyRecTypeId, Site = 'Pharmacy 3 Site');

            Id payerRecTypeId = accountRecTypes.get('IndustriesPayer').getRecordTypeId();
            Account payer = new Account( Name = 'Payer', RecordTypeId = payerRecTypeId);

            insert new List<Account> {
                specialtyPharmacy1, specialtyPharmacy2, specialtyPharmacy3, payer
            };

            // create program pharmacies
            insert new List<PJN_Care_Program_Specialty_Pharmacy__c> {
                new PJN_Care_Program_Specialty_Pharmacy__c(
                    PJN_Program__c = program.Id,
                    PJN_Specialty_Pharmacy__c = specialtyPharmacy1.Id
                ),
                new PJN_Care_Program_Specialty_Pharmacy__c(
                    PJN_Program__c = program.Id,
                    PJN_Specialty_Pharmacy__c = specialtyPharmacy2.Id
                    // PJN_Last_Round_Robin_Assign_Date_Time__c = DateTime.now().addDays(-2)
                ),
                new PJN_Care_Program_Specialty_Pharmacy__c(
                    PJN_Program__c = program.Id,
                    PJN_Specialty_Pharmacy__c = specialtyPharmacy3.Id
                    // PJN_Last_Round_Robin_Assign_Date_Time__c = DateTime.now().addDays(-1)
                )
            };

            Account patient = new Account (
                LastName = 'Patient',
                RecordTypeId = accountRecTypes.get('PJN_Patient').getRecordTypeId()
            );
            insert patient;

            // create care plan for patient
            Id carePlanRecTypeId = SObjectType.Case
                .getRecordTypeInfosByDeveloperName()
                .get('CarePlan')
                .getRecordTypeId();

            Case carePlan = new Case(
                RecordTypeId = carePlanRecTypeId,
                AccountId = patient.Id,
                PJN_Program__c = program.Id
            );
            insert carePlan;

            PJN_Member_Plan__c mp = new PJN_Member_Plan__c(
                PJN_Care_Plan__c = carePlan.Id,
                PJN_Payer__c = payer.Id,
                PJN_Therapy_Covered__c = 'Covered'
            );
            insert mp;

            PJN_Coverage_Investigation__c investigation = new PJN_Coverage_Investigation__c(
                PJN_Care_Plan__c = carePlan.Id
            );
            insert investigation;

            insert new PJN_Coverage_Investigation_Item__c(
                PJN_Coverage_Investigation__c = investigation.Id,
                RecordTypeId = SObjectType.PJN_Coverage_Investigation_Item__c
                    .getRecordTypeInfosByDeveloperName()
                    .get('PJN_Member_Plan')
                    .getRecordTypeId(),
                PJN_Member_Plan__c = mp.Id
            );
        }
    }

    @isTest
    private static void itShouldAssignAPharmacyFromCareProgramPharmacies() {
        System.runAs(getRunningUser()) {
            PJN_Coverage_Investigation__c investigation = getInvestigation();
            Test.startTest();
            PJN_SPRoundRobinCtrl.assignSpecialtyPharmacy(investigation.Id);
            Test.stopTest();

            investigation = [
                SELECT PJN_Selected_Specialty_Pharmacy__r.Name
                FROM PJN_Coverage_Investigation__c
                WHERE Id = :investigation.Id
                AND PJN_Selected_Specialty_Pharmacy__c != null
                LIMIT 1
            ];

            System.assertEquals('Pharmacy 1', investigation.PJN_Selected_Specialty_Pharmacy__r.Name);
        }
    }

    @isTest
    private static void itShouldCycleThroughPharmacies() {
        System.runAs(getRunningUser()) {
            PJN_Coverage_Investigation__c investigation = getInvestigation();
            PJN_SPRoundRobinCtrl.assignSpecialtyPharmacy(investigation.Id); // "itShouldAssignAPharmacyFromCareProgramPharmacies" proves this is pharmacy 1
            Test.startTest();
            PJN_SPRoundRobinCtrl.assignSpecialtyPharmacy(investigation.Id); // try again and it should be pharmacy 2
            investigation = [
                SELECT PJN_Selected_Specialty_Pharmacy__r.Name
                FROM PJN_Coverage_Investigation__c
                WHERE Id = :investigation.Id
                AND PJN_Selected_Specialty_Pharmacy__c != null
                LIMIT 1
            ];

            System.assertEquals('Pharmacy 2', investigation.PJN_Selected_Specialty_Pharmacy__r.Name);

            PJN_SPRoundRobinCtrl.assignSpecialtyPharmacy(investigation.Id); // try again and it should now be pharmacy 3
            investigation = [
                SELECT PJN_Selected_Specialty_Pharmacy__r.Name
                FROM PJN_Coverage_Investigation__c
                WHERE Id = :investigation.Id
                AND PJN_Selected_Specialty_Pharmacy__c != null
                LIMIT 1
            ];

            System.assertEquals('Pharmacy 3', investigation.PJN_Selected_Specialty_Pharmacy__r.Name);
            Test.stopTest();
        }
    }

    @isTest
    private static void itShouldAssignFromConfiguredPharmaciesForPayer() {
        System.runAs(getRunningUser()) {
            CareProgram program = [SELECT Id, PJN_Filter_Round_Robin_by_Payers__c FROM CareProgram LIMIT 1];
            program.PJN_Filter_Round_Robin_by_Payers__c = true;
            update program;

            List<Account> pharmacies = [SELECT Id FROM Account WHERE Site IN ('Pharmacy 2 Site', 'Pharmacy 3 Site') ORDER BY Site]; // order by name to ensure order
            Id payerRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesPayer').getRecordTypeId();
            Account Payer = [SELECT Id FROM Account WHERE RecordTypeId = :payerRTId LIMIT 1];

            insert new PJN_Payer_Specialty_Pharmacy__c(PJN_Payer__c = payer.id, PJN_Specialty_Pharmacy__c = pharmacies[0].Id);
            insert new PJN_Payer_Specialty_Pharmacy__c(PJN_Payer__c = payer.id, PJN_Specialty_Pharmacy__c = pharmacies[1].Id);

            Test.startTest();
            PJN_Coverage_Investigation__c investigation = [SELECT Id FROM PJN_Coverage_Investigation__c LIMIT 1];
            PJN_SPRoundRobinCtrl.assignSpecialtyPharmacy(investigation.Id);
            investigation = [
                SELECT PJN_Selected_Specialty_Pharmacy__r.Name FROM PJN_Coverage_Investigation__c WHERE Id = :investigation.Id
            ];

            System.assertEquals('Pharmacy 3', investigation.PJN_Selected_Specialty_Pharmacy__r.Name);

            PJN_SPRoundRobinCtrl.assignSpecialtyPharmacy(investigation.Id); // try again and it should now be pharmacy 3
            investigation = [
                SELECT PJN_Selected_Specialty_Pharmacy__r.Name FROM PJN_Coverage_Investigation__c WHERE Id = :investigation.Id
            ];

            System.assertEquals('Pharmacy 2', investigation.PJN_Selected_Specialty_Pharmacy__r.Name);
            Test.stopTest();

            PJN_SPRoundRobinCtrl.assignSpecialtyPharmacy(investigation.Id); // one more time again and it should now be pharmacy 2 again
            investigation = [
                SELECT PJN_Selected_Specialty_Pharmacy__r.Name FROM PJN_Coverage_Investigation__c WHERE Id = :investigation.Id
            ];

            System.assertEquals('Pharmacy 3', investigation.PJN_Selected_Specialty_Pharmacy__r.Name);


        }
    }

    @isTest
    private static void itShouldErrorWhenPayerNotPresentOnMemberPlan() {
        CareProgram program = [SELECT Id, PJN_Filter_Round_Robin_by_Payers__c FROM CareProgram LIMIT 1];
        program.PJN_Filter_Round_Robin_by_Payers__c = true;
        update program;

        PJN_Member_Plan__c mp = [SELECT Id,PJN_Payer__c FROM PJN_Member_Plan__c LIMIT 1];
        mp.PJN_Payer__c = null;
        update mp;

        Test.startTest();
        String errorMessage;
        try {
            PJN_Coverage_Investigation__c investigation = [SELECT Id FROM PJN_Coverage_Investigation__c LIMIT 1];
            PJN_SPRoundRobinCtrl.assignSpecialtyPharmacy(investigation.Id);
        } catch (System.AuraHandledException ex) {
            errorMessage = ex.getMessage();
        }
        Test.stopTest();

        System.assertEquals(
            errorMessage,
            'The application is unable to find a member plan coverage investigation item for this investigation that is marked as covered and has an associated payer.',
            errorMessage
        );
    }

    @isTest
    private static void itShouldErrorWhenPayerDoesNotHaveSpecialtyPharmacies() {
        CareProgram program = [SELECT Id, PJN_Filter_Round_Robin_by_Payers__c FROM CareProgram LIMIT 1];
        program.PJN_Filter_Round_Robin_by_Payers__c = true;
        update program;

        Test.startTest();
        String errorMessage;
        try {
            PJN_Coverage_Investigation__c investigation = [SELECT Id FROM PJN_Coverage_Investigation__c LIMIT 1];
            PJN_SPRoundRobinCtrl.assignSpecialtyPharmacy(investigation.Id);
        } catch (System.AuraHandledException ex) {
            errorMessage = ex.getMessage();
        }
        Test.stopTest();

        System.assert(errorMessage.contains('The payer associated with the member plan'), errorMessage);
        System.assert(errorMessage.contains('cannot be found or does not have an associated list of specialty pharmacies'), errorMessage);
    }

    @isTest
    private static void itShouldErrorWhenUnableToAssignPharmacy() {
        delete [SELECT Id FROM PJN_Care_Program_Specialty_Pharmacy__c];

        Test.startTest();
        String errorMessage;
        try {
            PJN_Coverage_Investigation__c investigation = [SELECT Id FROM PJN_Coverage_Investigation__c LIMIT 1];
            PJN_SPRoundRobinCtrl.assignSpecialtyPharmacy(investigation.Id);
        } catch (System.AuraHandledException ex) {
            errorMessage = ex.getMessage();
        }
        Test.stopTest();

        System.assert(errorMessage.contains('Unable to find a specialty pharmacy to assign to.'), errorMessage);
    }

    private static User getRunningUser() {
        try {
            return [SELECT Id FROM User WHERE Alias = 'pjnusr'];
        } catch (System.QueryException ex) {
            Profile p = [SELECT Id FROM Profile WHERE Name = 'PJN - PS User'  LIMIT 1];
            User psUser = new User(alias = 'pjnusr', email='test@pjn.com', emailencodingkey='UTF-8',
                FirstName = 'Test', Lastname='User', languagelocalekey='en_US',  localesidkey='en_US',
                profileid = p.Id, timezonesidkey='America/Los_Angeles', isActive = true,
                username='test@pjn.com'
            );

            insert psUser;

            PermissionSet bps = [SELECT Id FROM PermissionSet WHERE Name = 'PJN_Base_Permissions'];
            insert new PermissionSetAssignment(AssigneeId = psUser.Id, PermissionSetId = bps.Id);

            PermissionSet cips = [SELECT Id FROM PermissionSet WHERE Name = 'PJN_Coverage_Investigation'];
            insert new PermissionSetAssignment(AssigneeId = psUser.Id, PermissionSetId = cips.Id);
            return psUser;
        }
    }

    private static PJN_Coverage_Investigation__c getInvestigation() {
        return [SELECT Id FROM PJN_Coverage_Investigation__c LIMIT 1];
    }

}