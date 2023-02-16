/**
 * @author      Mavens
 * @group       ServiceCloudVoice
 * @description Test for MVN_StampPrimaryPhoneOnCasesHdlr
 */
@isTest
private class MVN_StampPrimaryPhoneOnCasesHdlrTest {
    private static List<Account> accounts;
    private static Account patient;
    private static Account physician;
    private static Account caregiver;
    private static Account staff;
    private static Case carePlan;

    static {
        PJN_TriggerHandlerSettingQuery.triggerHandlerSettingBySObjectType = new Map<SObjectType, List<PJN_Trigger_Handler_Setting__mdt>> {
            SObjectType.PJN_Contact_Information__c.getSObjectType() => new List<PJN_Trigger_Handler_Setting__mdt> {
                new PJN_Trigger_Handler_Setting__mdt(
                    PJN_Class__c = 'MVN_StampPrimaryPhoneOnCasesHdlr',
                    PJN_Event__c = 'BEFORE_INSERT',
                    PJN_SObject_API_Name__c = 'PJN_Contact_Information__c'
                ),
                new PJN_Trigger_Handler_Setting__mdt(
                    PJN_Class__c = 'MVN_StampPrimaryPhoneOnCasesHdlr',
                    PJN_Event__c = 'BEFORE_UPDATE',
                    PJN_SObject_API_Name__c = 'PJN_Contact_Information__c'
                ),
                new PJN_Trigger_Handler_Setting__mdt(
                    PJN_Class__c = 'MVN_StampPrimaryPhoneOnCasesHdlr',
                    PJN_Event__c = 'AFTER_INSERT',
                    PJN_SObject_API_Name__c = 'PJN_Contact_Information__c'
                ),
                new PJN_Trigger_Handler_Setting__mdt(
                    PJN_Class__c = 'MVN_StampPrimaryPhoneOnCasesHdlr',
                    PJN_Event__c = 'AFTER_UPDATE',
                    PJN_SObject_API_Name__c = 'PJN_Contact_Information__c'
                )
            }
        };

        CareProgram cp = createCareProgram();
        createProgramDataUsePurpose(cp);
        createHealthInfoDataUsePurpose(cp);
        accounts = new List<Account> {
            buildPatient(),
            buildPhysician(),
            buildCaregiver(),
            buildStaff()
        };
        insert accounts;
        patient = getAccount(accounts, 'PJN_Patient');
        physician = getAccount(accounts, 'PJN_Physician');
        caregiver = getAccount(accounts, 'PJN_Caregiver');
        staff = getAccount(accounts, 'PJN_Staff');

        carePlan = createCarePlan(cp);
    }

    private static CareProgram createCareProgram() {
        CareProgram cp;
        try {
            cp = [
                SELECT
                    Id
                FROM
                    CareProgram
                WHERE
                    PJN_Program_DeveloperName__c = :Label.MVN_MyRare_Enrollment_ProgramDevName
            ];
        } catch (System.QueryException ex) {
            cp = new CareProgram(
                Name = 'Test Program',
                PJN_Program_DeveloperName__c = Label.MVN_MyRare_Enrollment_ProgramDevName,
                StartDate = Date.today()
            );
            insert cp;
        }
        return cp;
    }

    static void createProgramDataUsePurpose(CareProgram careProgram) {
        try {
            DataUsePurpose dup = [
                SELECT
                    Id
                FROM
                    DataUsePurpose
                WHERE
                    Name = 'TestProgram'
            ];
        } catch (System.QueryException ex) {
            insert new DataUsePurpose(
                Name = 'TestProgram',
                PJN_Effective_Months__c = 12,
                PurposeId = careProgram.Id,
                PJN_External_Id__c = 'MVN_Test_ProgramConsent'
            );
        }
    }

    static void createHealthInfoDataUsePurpose(CareProgram careProgram) {
        try {
            DataUsePurpose dup = [
                SELECT
                    Id
                FROM
                    DataUsePurpose
                WHERE
                    Name = 'Disclose/Use Health Information'
            ];
        } catch (System.QueryException ex) {
            insert new DataUsePurpose(
                Name = 'Disclose/Use Health Information',
                PJN_Effective_Months__c = 12,
                PurposeId = careProgram.Id,
                PJN_External_Id__c = 'MVN_Test_HealthInformationPrg'
            );
        }
    }

    private static Account buildPatient() {
        Account patient = new Account (
            FirstName = 'Patient',
            LastName = 'Test',
            MVN_Birthdate__c = Date.valueOf('1988-12-06'),
            HealthCloudGA__Gender__pc = 'Male',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId()
        );
        return patient;
    }

    private static Account buildPhysician() {
        Account physician = new Account (
            FirstName = 'Physician',
            LastName = 'Test',
            PJN_Professional_Designation__c = 'MD',
            PJN_DEA__c = '123456789',
            PJN_NPI__c = '987654321',
            PJN_SLN__c = '123789456',
            PJN_Specialty__c = 'Anesthesiology',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId()
        );
        return physician;
    }

    private static Account buildCaregiver() {
        Account caregiver = new Account (
            FirstName = 'Caregiver',
            LastName = 'Test',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Caregiver').getRecordTypeId()
        );
        return caregiver;
    }

    private static Account buildStaff() {
        Account staff = new Account (
            FirstName = 'Staff',
            LastName = 'Test',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Staff').getRecordTypeId()
        );
        return staff;
    }

    private static Account getAccount(List<Account> accounts, String recordTypeDevName) {
        return [
            SELECT
                Id
            FROM
                Account
            WHERE
                Id IN :accounts
            AND
                RecordType.DeveloperName = :recordTypeDevName
            LIMIT 1
        ];
    }

    private static List<PJN_Contact_Information__c> buildContactInformations(Account acc) {
        List<PJN_Contact_Information__c> cis = new List<PJN_Contact_Information__c>();
        cis.add(
            new PJN_Contact_Information__c (
                PJN_Account__c = acc.Id,
                PJN_Address_Line_1__c = '123 Main Street',
                PJN_Address_Line_2__c = 'Building 1',
                PJN_City__c = 'Chicago',
                PJN_State__c = 'IL',
                PJN_Postal_Code__c = '60606',
                PJN_Country__c = 'United States',
                RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId()
            )
        );
        cis.add(
            new PJN_Contact_Information__c (
                PJN_Account__c = acc.Id,
                PJN_Email__c = 'test@test.test',
                RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Email').getRecordTypeId()
            )
        );
        cis.add(
            new PJN_Contact_Information__c (
                PJN_Account__c = acc.Id,
                PJN_Phone__c = '8005551111',
                RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Phone').getRecordTypeId()
            )
        );
        return cis;
    }

    private static Case createCarePlan(CareProgram careProgram) {
        Case carePlan = new Case (
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            AccountId = patient.Id,
            PJN_Physician__c = physician.Id,
            PJN_Caregiver__c = caregiver.Id,
            PJN_Staff__c = staff.Id,
            PJN_Program__c = careProgram.Id,
            Status = 'Open'
        );
        insert carePlan;
        return carePlan;
    }

    @isTest
    static void testStampPrimaryPhoneOnCasesOnCIInsert() {
        List<PJN_Contact_Information__c> cis = new List<PJN_Contact_Information__c>();
        cis.addAll(buildContactInformations(patient));
        cis.addAll(buildContactInformations(physician));
        cis.addAll(buildContactInformations(caregiver));
        cis.addAll(buildContactInformations(staff));
        insert cis;

        carePlan = [
            SELECT Id,
                   MVN_Patient_Primary_Phone_E164__c,
                   MVN_Caregiver_Primary_Phone_E164__c,
                   MVN_Physician_Primary_Phone_E164__c,
                   MVN_Staff_Primary_Phone_E164__c
              FROM Case 
             WHERE Id = :carePlan.Id
        ];
        
        System.assertEquals(carePlan.MVN_Patient_Primary_Phone_E164__c, '+18005551111');
        System.assertEquals(carePlan.MVN_Caregiver_Primary_Phone_E164__c, '+18005551111');
        System.assertEquals(carePlan.MVN_Physician_Primary_Phone_E164__c, '+18005551111');
        System.assertEquals(carePlan.MVN_Staff_Primary_Phone_E164__c, '+18005551111');
    }

    @isTest
    static void testStampPrimaryPhoneOnCasesOnCIUpdate() {
        List<PJN_Contact_Information__c> cis = new List<PJN_Contact_Information__c>();
        cis.addAll(buildContactInformations(patient));
        cis.addAll(buildContactInformations(physician));
        cis.addAll(buildContactInformations(caregiver));
        cis.addAll(buildContactInformations(staff));
        insert cis;

        cis.clear();
        cis.add(
            new PJN_Contact_Information__c (
                PJN_Account__c = patient.Id,
                PJN_Phone__c = '8005552222',
                PJN_Set_as_Primary__c = false,
                RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Phone').getRecordTypeId()
            )
        );
        cis.add(
            new PJN_Contact_Information__c (
                PJN_Account__c = physician.Id,
                PJN_Phone__c = '8005552222',
                PJN_Set_as_Primary__c = false,
                RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Phone').getRecordTypeId()
            )
        );
        cis.add(
            new PJN_Contact_Information__c (
                PJN_Account__c = caregiver.Id,
                PJN_Phone__c = '8005552222',
                PJN_Set_as_Primary__c = false,
                RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Phone').getRecordTypeId()
            )
        );
        cis.add(
            new PJN_Contact_Information__c (
                PJN_Account__c = staff.Id,
                PJN_Phone__c = '8005552222',
                PJN_Set_as_Primary__c = false,
                RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Phone').getRecordTypeId()
            )
        );
        insert cis;
        
        for (PJN_Contact_Information__c ci : cis) {
            ci.PJN_Set_as_Primary__c = true;
        }
        Test.startTest();
        update cis;
        Test.stopTest();

        carePlan = [
            SELECT Id,
                   MVN_Patient_Primary_Phone_E164__c,
                   MVN_Caregiver_Primary_Phone_E164__c,
                   MVN_Physician_Primary_Phone_E164__c,
                   MVN_Staff_Primary_Phone_E164__c
              FROM Case 
             WHERE Id = :carePlan.Id
        ];

        System.assertEquals(carePlan.MVN_Patient_Primary_Phone_E164__c, '+18005552222');
        System.assertEquals(carePlan.MVN_Caregiver_Primary_Phone_E164__c, '+18005552222');
        System.assertEquals(carePlan.MVN_Physician_Primary_Phone_E164__c, '+18005552222');
        System.assertEquals(carePlan.MVN_Staff_Primary_Phone_E164__c, '+18005552222');
    }

}