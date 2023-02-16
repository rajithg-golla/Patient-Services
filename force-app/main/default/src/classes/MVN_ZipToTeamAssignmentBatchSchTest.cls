@IsTest
private class MVN_ZipToTeamAssignmentBatchSchTest {
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
        Account IndustriesIndividualUpdated = accountFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesIndividual').getRecordTypeId(),
                'Name' => 'IndustriesIndividual Updated Test'
            }
        );

        PJN_Contact_Information__c contactInfoPhysicianUpdated = contactInformationFactory.createAddress(new Map<String,Object>{
            'PJN_Address_Line_1__c' => 'Physician Address Line 1',
            'PJN_Address_Line_2__c' => 'Physician Address Line 2',
            'PJN_Set_as_Primary__c' => true,
            'PJN_City__c' => 'Physician City',
            'PJN_Postal_Code__c' => '22222',
            'PJN_Country__c' => 'United States',
            'PJN_Account__c' => physicianUpdated.Id
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
        List<User> userList = [SELECT Id FROM User WHERE Name!='Automated Process' AND Name!='System' AND IsActive=true LIMIT 2];
        List<PJN_Zip_To_Team__c> zipToTeamList = new List<PJN_Zip_To_Team__c>();
        zipToTeamList.add(
            new PJN_Zip_To_Team__c(
                Name = 'Zip To Team Test 1',
                MVN_RBM_User__c = userList.get(0).Id,
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
                MVN_RBM_User__c = userList.get(1).Id,
                PJN_Zip_Code__c = '22222',
                PJN_Program__c = program.Id,
                PJN_Country__c = 'United States',
                PJN_Region__c = REGION2,
                PJN_Territory__c = TERRITORY
            )
        );
        insert zipToTeamList;
        Test.startTest();
        PJN_TestFactoryCase caseFactory = new PJN_TestFactoryCase();
        List<Case> carePlans = caseFactory.constructMany(100,
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId(),
                'PJN_Program_DeveloperName__c' => 'PJN_Test_Program',
                'Status' => 'Test',
                'Subject' => 'Care Plan Case',
                'PJN_Physician__c' => physician.Id,
                'PJN_Enrollment_Address__c' => contactInfoPhysician.Id
            }
        );
        carePlans.addAll(
            caseFactory.constructMany(100,
                new Map<String, Object> {
                    'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId(),
                    'PJN_Program_DeveloperName__c' => 'PJN_Test_Program',
                    'Status' => 'Test',
                    'Subject' => 'Care Plan Case',
                    'PJN_Physician__c' => physicianUpdated.Id,
                    'PJN_Enrollment_Address__c' => contactInfoPhysicianUpdated.Id
                }
            )
        );
        carePlans.addAll(
            caseFactory.constructMany(1,
                new Map<String, Object> {
                    'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId(),
                    'PJN_Program_DeveloperName__c' => 'PJN_Test_Program',
                    'Status' => 'Test',
                    'Subject' => 'Care Plan Case',
                    'AccountId' => IndustriesIndividualUpdated.Id
                }
            )
        );
        insert carePlans;
        Test.stopTest();
    }

    @isTest
    private static void testInsertCarePlanAndUpdatePhysician() {
        List<Case> carePlans = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'CarePlan'];
        for (Case carePlan : carePlans) {
            carePlan.PJN_Zip_To_Team__c = null;
            carePlan.PJN_Run_ZTT_Against_Enrollment_Address__c = false;
            carePlan.PJN_Region__c = null;
            carePlan.PJN_Territory__c = null;
            carePlan.MVN_RBM_User__c = null;
        }
        update carePlans;
        Test.startTest();
        MVN_ZipToTeamAssignmentBatchSch zttAssignmentBatch = new MVN_ZipToTeamAssignmentBatchSch();
        ID batchprocessid = Database.executeBatch(zttAssignmentBatch, 2000);
        Test.stopTest();
        carePlans = [
            SELECT
                OwnerId,
                PJN_Zip_To_Team__c,
                PJN_Run_ZTT_Against_Enrollment_Address__c,
                PJN_Region__c,
                PJN_Territory__c,
                MVN_RBM_User__c,
                PJN_Physician__r.LastName
            FROM
                Case
            WHERE
                Id IN :carePlans
        ];
        /*
        System.assertEquals(200, carePlans.size(), 'CarePlans were not created or retrieved correctly.');
        for (Case carePlan : carePlans) {
            System.assertEquals(TERRITORY, carePlan.PJN_Territory__c);
            if (carePlan.PJN_Physician__r.LastName == 'Physician Test') {
                System.assertEquals(REGION, carePlan.PJN_Region__c);
            } else {
                System.assertEquals(REGION2, carePlan.PJN_Region__c);
            }
        }
        */
    }
}