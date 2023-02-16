/**
* @author Mavens
* @date Feb 2019
* @description Test class for PJN_ZipToTeamAssignment
* @group TestFactory
*/
@isTest
private class PJN_ZipToTeamAssignmentTest {
    static String REGION = 'Northeast';
    static String REGION2 = 'Southwest';
    static String TERRITORY = 'Boston';
    /**
    * @description setups data for all unit tests
    */
    @testSetup
    private static void setup() {
        CareProgram program = new CareProgram(
            Name = 'Test Program',
            PJN_Program_DeveloperName__c = 'PJN_Test_Program',
            StartDate = Date.today()
        );
        insert program;

        PJN_TestFactoryAccount accountFactory = new PJN_TestFactoryAccount();
        Account physician = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId(),
                'LastName' => 'Physician Test'
            }
        );
        PJN_TestFactoryContactInformation contactInformationFactory = new PJN_TestFactoryContactInformation();
        PJN_Contact_Information__c contactInfoPhysician = contactInformationFactory.createAddress(new Map<String,Object>{
            'PJN_Address_Line_1__c' => 'Physician Address Line 1',
            'PJN_Address_Line_2__c' => 'Physician Address Line 2',
            'PJN_Set_as_Primary__c' => true,
            'PJN_City__c' => 'Physician City',
            'PJN_Postal_Code__c' => '11111',
            'PJN_Country__c' => 'United States',
            'PJN_Account__c' => Physician.Id
        });

        Account physicianUpdated = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId(),
                'LastName' => 'Physician Updated Test'
            }
        );
        PJN_Contact_Information__c contactInfoPhysicianUpdated = contactInformationFactory.createAddress(new Map<String,Object>{
            'PJN_Address_Line_1__c' => 'Physician Address Line 1',
            'PJN_Address_Line_2__c' => 'Physician Address Line 2',
            'PJN_Set_as_Primary__c' => true,
            'PJN_City__c' => 'Physician City',
            'PJN_Postal_Code__c' => '22222',
            'PJN_Country__c' => 'United States',
            'PJN_Account__c' => PhysicianUpdated.Id
        });
        physicianUpdated.PJN_Primary_Address__c = contactInfoPhysicianUpdated.Id;
        update physicianUpdated;

        Account patient = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
                'LastName' => 'Patient Test'
            }
        );
        PJN_Contact_Information__c contactInfoPatient = contactInformationFactory.createAddress(new Map<String,Object>{
            'PJN_Address_Line_1__c' => 'Patient Address Line 1',
            'PJN_Address_Line_2__c' => 'Patient Address Line 2',
            'PJN_Set_as_Primary__c' => true,
            'PJN_City__c' => 'Patient City',
            'PJN_Postal_Code__c' => '11111',
            'PJN_Country__c' => 'United States',
            'PJN_Account__c' => Patient.Id
        });
        patient.PJN_Primary_Address__c = contactInfoPatient.Id;
        update patient;
        Account patientUpdated = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
                'LastName' => 'Patient Updated Test'
            }
        );
        PJN_Contact_Information__c contactInfoPatientUpdated = contactInformationFactory.createAddress(new Map<String,Object>{
            'PJN_Address_Line_1__c' => 'Patient Address Line 1',
            'PJN_Address_Line_2__c' => 'Patient Address Line 2',
            'PJN_Set_as_Primary__c' => true,
            'PJN_City__c' => 'Patient City',
            'PJN_Postal_Code__c' => '22222',
            'PJN_Country__c' => 'United States',
            'PJN_Account__c' => PatientUpdated.Id
        });
        patientUpdated.PJN_Primary_Address__c = contactInfoPatientUpdated.Id;
        update PatientUpdated;

        String country =  PJN_Contact_Information__c.PJN_Country__c.getDescribe().getPicklistValues().get(0).getValue();
        List<User> userList = [
            SELECT 
                Id 
            FROM 
                User 
            WHERE 
                Name!='Automated Process' 
            AND 
                Name!='System' 
            AND 
                (NOT Name LIKE '%Guest User%') 
            AND 
                IsActive=true 
            LIMIT 2];
        List<PJN_Zip_To_Team__c> zipToTeamList = new List<PJN_Zip_To_Team__c>();
        zipToTeamList.add(
            new PJN_Zip_To_Team__c(
                Name = 'Zip To Team Test 1',
                PJN_Case_Manager__c = userList.get(0).Id,
                PJN_Zip_Code__c = '11111',
                PJN_Program__c = program.Id,
                PJN_Country__c = 'United States',
                PJN_Region__c = REGION,
                PJN_Territory__c = TERRITORY
            )
        );
         zipToTeamList.add(
            new PJN_Zip_To_Team__c(
                Name = 'Zip To Team Test 2',
                PJN_Case_Manager__c = userList.get(1).Id,
                PJN_Zip_Code__c = '22222',
                PJN_Program__c = program.Id,
                PJN_Country__c = 'United States',
                PJN_Region__c = REGION2,
                PJN_Territory__c = TERRITORY
            )
        );
        insert zipToTeamList;


    }

    @isTest
    private static void testInsertCarePlanAndUpdatePhysician() {
        List<User> userList = [
            SELECT 
                Id 
            FROM 
                User 
            WHERE 
                Name!='Automated Process' 
            AND 
                Name!='System' 
            AND 
                (NOT Name LIKE '%Guest User%') 
            AND 
                IsActive=true 
            LIMIT 2];
        Map<String, Account> acctMap = getAccounts();
        Account physician = acctMap.get('Physician Test');
        Account physicianUpdated = acctMap.get('Physician Updated Test');
        PJN_Contact_Information__c contactInfoPhysician = [SELECT Id FROM PJN_Contact_Information__c WHERE PJN_Account__c = :physician.Id LIMIT 1];
        PJN_TestFactoryCase caseFactory = new PJN_TestFactoryCase();
        Case carePlan = caseFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId(),
                'PJN_Program_DeveloperName__c' => 'PJN_Test_Program',
                'Status' => 'Test',
                'Subject' => 'Care Plan Case',
                'PJN_Physician__c' => physician.Id,
                'PJN_Enrollment_Address__c' => contactInfoPhysician.Id
            }
        );
        carePlan = [
            SELECT
                OwnerId,
                PJN_Region__c,
                PJN_Territory__c
            FROM
                Case
            WHERE
                Id = :carePlan.Id
        ];

        Test.startTest();
            carePlan.PJN_Physician__c = physicianUpdated.Id;
            update carePlan;
        Test.stopTest();

        carePlan = [
            SELECT
                OwnerId,
                PJN_Region__c,
                PJN_Territory__c
            FROM
                Case
            WHERE
                Id = :carePlan.Id
        ];
        System.assertEquals(TERRITORY, carePlan.PJN_Territory__c);
        System.assertEquals(REGION2, carePlan.PJN_Region__c);
    }

    @isTest
    private static void testInsertCarePlanWithNoPhysician() {
        List<User> userList = [
            SELECT 
                Id 
            FROM 
                User 
            WHERE 
                Name!='Automated Process' 
            AND 
                Name!='System' 
            AND 
                (NOT Name LIKE '%Guest User%') 
            AND 
                IsActive=true 
            LIMIT 2];

        Map<String, Account> acctMap = getAccounts();
        Account patient = acctMap.get('Patient Test');
        Account patientUpdated = acctMap.get('Patient Updated Test');
        Account physician = acctMap.get('Physician Test');
        Account physicianUpdated = acctMap.get('Physician Updated Test');
        PJN_TestFactoryCase caseFactory = new PJN_TestFactoryCase();
        Case carePlan = caseFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId(),
                'PJN_Program_DeveloperName__c' => 'PJN_Test_Program',
                'Status' => 'Test',
                'Subject' => 'Care Plan Case',
                'AccountId' => patient.Id
            }
        );
        carePlan = [
            SELECT
                OwnerId,
                PJN_Region__c,
                PJN_Territory__c
            FROM
                Case
            WHERE
                Id = :carePlan.Id
        ];

        carePlan.PJN_Physician__c = physician.Id;
        update carePlan;

        Test.startTest();
            carePlan.AccountId = patientUpdated.Id;
            carePlan.PJN_Physician__c = null;
            update carePlan;
        Test.stopTest();

        carePlan = [
            SELECT
                OwnerId,
                PJN_Region__c,
                PJN_Territory__c
            FROM
                Case
            WHERE
                Id = :carePlan.Id
        ];
        System.assertEquals(TERRITORY, carePlan.PJN_Territory__c);
        System.assertEquals(REGION2, carePlan.PJN_Region__c);
    }

    private static Map<String, Account> getAccounts() {
        Map<String, Account> acctMap = new Map<String, Account>();

        for(Account acct : [SELECT Id, LastName FROM Account]) {
            acctMap.put(acct.LastName, acct);
        }

        return acctMap;
    }
}