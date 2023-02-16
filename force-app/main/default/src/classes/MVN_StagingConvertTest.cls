/**
 * @author      Mavens
 * @date        July 8, 2021
 * @description Unit tests for MVN_StagingConvertMedical and MVN_StagingConvertPharmacy.
 */
@IsTest
private class MVN_StagingConvertTest {

    private static final String CRON_EXP = '0 0 0 3 9 ? ' + System.now().addYears(1).year();

    @TestSetup
    static void makeData() {
        createAssistancePrograms();
        insert new List<MVN_Staging_Claim__c>{buildMedicalStagingClaim(), buildPharmacyStagingClaim()};
    }

    @IsTest
    static void testIfSchedulesMedicalCorrectly() {
        Test.startTest();
        // Schedule the test job
        String jobId = System.schedule('MVN_StagingConvertMedical', CRON_EXP, new MVN_StagingConvertMedical());
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        // Verify the expressions are the same System.assertEquals(CRON_EXP, ct.CronExpression);
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered, 'Times triggered should be 0');
        // Verify the next time the job will run
        System.assertEquals(System.now().addYears(1).year() + '-09-03 00:00:00', String.valueOf(ct.NextFireTime), 'Dates should match');
        Test.stopTest();
    }

    @IsTest
    static void testIfSchedulesPharmacyCorrectly() {
        Test.startTest();
        // Schedule the test job
        String jobId = System.schedule('MVN_StagingConvertPharmacy', CRON_EXP, new MVN_StagingConvertPharmacy());
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        // Verify the expressions are the same System.assertEquals(CRON_EXP, ct.CronExpression);
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered, 'Times triggered should be 0');
        // Verify the next time the job will run
        System.assertEquals(System.now().addYears(1).year() + '-09-03 00:00:00', String.valueOf(ct.NextFireTime), 'Dates should match');
        Test.stopTest();
    }

    @IsTest
    static void testIfMedicalBatchConvertsSuccessfully() {

        Test.startTest();
        Database.executeBatch(new MVN_StagingConvertMedical(), 200);
        Test.stopTest();


        System.assertNotEquals(NULL, [SELECT MVN_Care_Plan__c FROM MVN_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Medical_Claim' LIMIT 1][0].MVN_Care_Plan__c, 'Claim\'s Care Plan should not be NULL.');
        System.assertNotEquals(NULL, [SELECT MVN_Copay_Assistance_Program__c FROM MVN_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Medical_Claim' LIMIT 1][0].MVN_Copay_Assistance_Program__c, 'Claim\'s Assistance Program should not be NULL.');
        System.assertEquals(System.Label.MVN_Staging_Claim_Conversion_Status_Complete, [SELECT MVN_Status__c FROM MVN_Staging_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Medical' LIMIT 1][0].MVN_Status__c, 'Staging Claim should have been updated to Complete');
        System.assertNotEquals(0, [SELECT Id FROM MVN_Claim__c].size(), 'Staging Claims should\'ve been converted and created Claims.');

        String activityRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        System.assertNotEquals(0, [SELECT MVN_Coordinator__c FROM Case WHERE RecordTypeId = :activityRecordTypeId].size(), 'Activities should have been inserted.');

        Id userId = [SELECT Id FROM User WHERE Alias = 'Testy' LIMIT 1][0].Id;
        System.assertEquals(userId, [SELECT OwnerId FROM Case WHERE RecordTypeId = :activityRecordTypeId LIMIT 1].OwnerId, 'OwnerId should match the test user added to CarePlan as MVN_Coordinator__c.');
    }


    @IsTest
    static void testIfMedicalBatchConvertsSuccessfulWithoutCoordinator() {

        // remove coordinator, should only be one case
        Case carePlan = [SELECT OwnerId, MVN_Coordinator__c FROM Case WHERE MVN_Coordinator__c != NULL LIMIT 1][0];
        carePlan.MVN_Coordinator__c = NULL;
        update carePlan;

        Test.startTest();
        Database.executeBatch(new MVN_StagingConvertMedical(), 200);
        Test.stopTest();


        System.assertNotEquals(NULL, [SELECT MVN_Care_Plan__c FROM MVN_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Medical_Claim' LIMIT 1][0].MVN_Care_Plan__c, 'Claim\'s Care Plan should not be NULL.');
        System.assertNotEquals(NULL, [SELECT MVN_Copay_Assistance_Program__c FROM MVN_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Medical_Claim' LIMIT 1][0].MVN_Copay_Assistance_Program__c, 'Claim\'s Assistance Program should not be NULL.');
        System.assertEquals(System.Label.MVN_Staging_Claim_Conversion_Status_Complete, [SELECT MVN_Status__c FROM MVN_Staging_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Medical' LIMIT 1][0].MVN_Status__c, 'Staging Claim should have been updated to Complete');
        System.assertNotEquals(0, [SELECT Id FROM MVN_Claim__c].size(), 'Staging Claims should\'ve been converted and created Claims.');

        String activityRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
        System.assertNotEquals(0, [SELECT MVN_Coordinator__c FROM Case WHERE RecordTypeId = :activityRecordTypeId].size(), 'Activities should have been inserted.');
        System.assertEquals(carePlan.OwnerId, [SELECT OwnerId FROM Case WHERE RecordTypeId = :activityRecordTypeId LIMIT 1].OwnerId, 'OwnerId should still be populated with CarePlan OwnerId.');
    }

    @IsTest
    static void testIfMedicalBatchConvertsError() {

        List<PJN_Assistance_Program__c> programs = [SELECT Id FROM PJN_Assistance_Program__c];
        delete programs; // this should make batch error

        Test.startTest();
        Database.executeBatch(new MVN_StagingConvertMedical(), 200);
        Test.stopTest();

        System.assertEquals(System.Label.MVN_Staging_Claim_Conversion_Status_Error, [SELECT MVN_Status__c FROM MVN_Staging_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Medical' LIMIT 1][0].MVN_Status__c, 'Staging Claim should have been updated to Error');
    }


    @IsTest
    static void testIfMedicalBatchConvertsMemberIdError() {

        // Make Member Id blank to trip error
        List<MVN_Staging_Claim__c> stagingClaims = [SELECT MVN_Member_Id__c FROM MVN_Staging_Claim__c];
        for (MVN_Staging_Claim__c stagingClaim : stagingClaims) {
            stagingClaim.MVN_Member_Id__c = '';
        }
        update stagingClaims;

        Test.startTest();
        Database.executeBatch(new MVN_StagingConvertMedical(), 200);
        Test.stopTest();

        System.assertEquals(System.Label.MVN_Staging_Claim_Conversion_Status_Error, [SELECT MVN_Status__c FROM MVN_Staging_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Medical' LIMIT 1][0].MVN_Status__c, 'Staging Claim should have been updated to Error');
        System.assertEquals(System.Label.MVN_Staging_Claim_Conversion_Error_Msg_Member_Id_is_Blank, [SELECT MVN_Error_Message__c FROM MVN_Staging_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Medical' LIMIT 1][0].MVN_Error_Message__c, 'Staging Claim should have been updated with \'' + System.Label.MVN_Staging_Claim_Conversion_Error_Msg_Member_Id_is_Blank + '\' as Error Message');
    }

    @IsTest
    static void testIfPharmacyBatchConvertsSuccessfully() {

        Test.startTest();
        Database.executeBatch(new MVN_StagingConvertPharmacy(), 200);
        Test.stopTest();


        System.assertNotEquals(NULL, [SELECT MVN_Care_Plan__c FROM MVN_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Pharmacy_Claim' LIMIT 1][0].MVN_Care_Plan__c, 'Claim\'s Care Plan should not be NULL.');
        System.assertNotEquals(NULL, [SELECT MVN_Copay_Assistance_Program__c FROM MVN_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Pharmacy_Claim' LIMIT 1][0].MVN_Copay_Assistance_Program__c, 'Claim\'s Assistance Program should not be NULL.');
        System.assertEquals(System.Label.MVN_Staging_Claim_Conversion_Status_Complete, [SELECT MVN_Status__c FROM MVN_Staging_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Pharmacy' LIMIT 1][0].MVN_Status__c, 'Staging Claim should have been updated to Complete');
        System.assertNotEquals(0, [SELECT Id FROM MVN_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Pharmacy_Claim'].size(), 'Staging Claims should\'ve been converted and created Claims.');
    }

    @IsTest
    static void testIfPharmacyBatchConvertsError() {

        List<PJN_Assistance_Program__c> programs = [SELECT Id FROM PJN_Assistance_Program__c];
        delete programs; // this should make batch error

        Test.startTest();
        Database.executeBatch(new MVN_StagingConvertPharmacy(), 200);
        Test.stopTest();

        System.assertEquals(System.Label.MVN_Staging_Claim_Conversion_Status_Error, [SELECT MVN_Status__c FROM MVN_Staging_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Pharmacy' LIMIT 1][0].MVN_Status__c, 'Staging Claim should have been updated to Error');
    }


    @IsTest
    static void testIfPharmacyBatchConvertsAuthNumberBlankError() {

        // Make Original Claim Auth Number to trip error
        List<MVN_Staging_Claim__c> stagingClaims = [SELECT MVN_Claim_Authorization_Number__c FROM MVN_Staging_Claim__c];
        for (MVN_Staging_Claim__c stagingClaim : stagingClaims) {
            stagingClaim.MVN_Claim_Authorization_Number__c = '';
        }
        update stagingClaims;

        List<PJN_Assistance_Program__c> programs = [SELECT Id FROM PJN_Assistance_Program__c];
        delete programs; // prevent match on program to trip specific error

        Test.startTest();
        Database.executeBatch(new MVN_StagingConvertPharmacy(), 200);
        Test.stopTest();

        System.assertEquals(System.Label.MVN_Staging_Claim_Conversion_Status_Error, [SELECT MVN_Status__c FROM MVN_Staging_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Pharmacy' LIMIT 1][0].MVN_Status__c, 'Staging Claim should have been updated to Error');
        System.assertEquals(System.Label.MVN_Staging_Claim_Conversion_Error_Msg_Auth_Number_is_Blank, [SELECT MVN_Error_Message__c FROM MVN_Staging_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Pharmacy' LIMIT 1][0].MVN_Error_Message__c, 'Staging Claim should have been updated with \'' + System.Label.MVN_Staging_Claim_Conversion_Error_Msg_Auth_Number_is_Blank + '\' as Error Message');
    }

    @IsTest
    static void testIfPharmacyBatchConvertsMemberIdBlankError() {

        // Make Member Id blank to trip error
        List<MVN_Staging_Claim__c> stagingClaims = [SELECT MVN_Claim_Authorization_Number__c FROM MVN_Staging_Claim__c];
        for (MVN_Staging_Claim__c stagingClaim : stagingClaims) {
            stagingClaim.MVN_Member_Id__c = '';
        }
        update stagingClaims;

        Test.startTest();
        Database.executeBatch(new MVN_StagingConvertPharmacy(), 200);
        Test.stopTest();

        System.assertEquals(System.Label.MVN_Staging_Claim_Conversion_Status_Error, [SELECT MVN_Status__c FROM MVN_Staging_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Pharmacy' LIMIT 1][0].MVN_Status__c, 'Staging Claim should have been updated to Error');
        System.assertEquals(System.Label.MVN_Staging_Claim_Conversion_Error_Msg_No_Auth_Match_Member_Id_Blank, [SELECT MVN_Error_Message__c FROM MVN_Staging_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Pharmacy' LIMIT 1][0].MVN_Error_Message__c, 'Staging Claim should have been updated with \'' + System.Label.MVN_Staging_Claim_Conversion_Error_Msg_No_Auth_Match_Member_Id_Blank + '\' as Error Message');
    }

    @IsTest
    static void testIfPharmacyBatchConvertsBothBlankError() {

        // Make Original Claim Auth Number and Member Id blank to trip error
        List<MVN_Staging_Claim__c> stagingClaims = [SELECT MVN_Claim_Authorization_Number__c, MVN_Member_Id__c FROM MVN_Staging_Claim__c];
        for (MVN_Staging_Claim__c stagingClaim : stagingClaims) {
            stagingClaim.MVN_Claim_Authorization_Number__c = '';
            stagingClaim.MVN_Member_Id__c = '';
        }
        update stagingClaims;

        Test.startTest();
        Database.executeBatch(new MVN_StagingConvertPharmacy(), 200);
        Test.stopTest();

        System.assertEquals(System.Label.MVN_Staging_Claim_Conversion_Status_Error, [SELECT MVN_Status__c FROM MVN_Staging_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Pharmacy' LIMIT 1][0].MVN_Status__c, 'Staging Claim should have been updated to Error');
        System.assertEquals(System.Label.MVN_Staging_Claim_Conversion_Error_Msg_Matching_Fields_Blank, [SELECT MVN_Error_Message__c FROM MVN_Staging_Claim__c WHERE RecordType.DeveloperName = 'MVN_Copay_Pharmacy' LIMIT 1][0].MVN_Error_Message__c, 'Staging Claim should have been updated with \'' + System.Label.MVN_Staging_Claim_Conversion_Error_Msg_Matching_Fields_Blank + '\' as Error Message');
    }

    private static MVN_Staging_Claim__c buildMedicalStagingClaim() {
        Id recordTypeId = Schema.SObjectType.MVN_Staging_Claim__c.getRecordTypeInfosByDeveloperName().get('MVN_Copay_Medical').getRecordTypeId();
        return new MVN_Staging_Claim__c(MVN_CRM_Patient_Id__c = '234242',
            MVN_Product_Code__c = 'EVK',
            MVN_Claim_Id__c = '2',
            MVN_Partner_Id__c = 'CRx',
            MVN_Client_Id__c = '131',
            MVN_Member_Id__c = '9610834643',
            MVN_Payment_Type__c = 'CTM',
            MVN_Patient_Copay_Before_Benefit__c = 250,
            MVN_Patient_OOP__c = 5,
            MVN_Claim_Outcome__c = 'R',
            MVN_Copay_Amount__c = 250,
            MVN_Rejected_Reason__c = 'No Eligible Charges',
            MVN_Billing_Provider_Name__c = 'Jimmy Almond',
            MVN_Billing_Provider_Contact_First_Name__c = 'Jimmy',
            MVN_Billing_Provider_Contact_Last_Name__c = 'Almond',
            MVN_Billing_Provider_Address1__c = '5401 S KIRKMAN RD SUITE 310',
            MVN_Billing_Provider_Address2__c = '',
            MVN_Billing_Provider_City__c = 'ORLANDO',
            MVN_Billing_Provider_State__c = 'FL',
            MVN_Billing_Provider_Zip__c = '32819',
            MVN_Billing_Provider_Phone__c = '6465675765',
            MVN_Billing_Provider_Fax_Number__c = '5345333333',
            MVN_Billing_Provider_NPI__c = '1073621249',
            MVN_Treating_Practice_Name__c = 'Katherine Acosta',
            MVN_Treating_Practice_Address1__c = '6645 VINELAND RD',
            MVN_Treating_Practice_Address2__c = 'STE 210',
            MVN_Treating_Practice_City__c = 'ORLANDO',
            MVN_Treating_Practice_State__c = 'FL',
            MVN_Treating_Practice_Fax_Number__c = '8976546789',
            MVN_Treating_Practice_Provider_NPI__c = '1891351250',
            MVN_Treating_Practice_Tax_Id__c = '',
            MVN_Treating_Physician_First_Name__c = 'Kathleen',
            MVN_Treating_Physician_Last_Name__c = 'Avocado',
            MVN_Treating_Physician_NPI__c = '1407388499',
            RecordTypeId = recordTypeId);
    }

    private static MVN_Staging_Claim__c buildPharmacyStagingClaim() {
        Id recordTypeId = Schema.SObjectType.MVN_Staging_Claim__c.getRecordTypeInfosByDeveloperName().get('MVN_Copay_Pharmacy').getRecordTypeId();
        return new MVN_Staging_Claim__c(
            MVN_CRM_Patient_Id__c = '234242',
            MVN_Product_Code__c = 'EVK',
            MVN_Partner_Id__c = 'CRx',
            MVN_Client_Id__c = '131',
            MVN_Transaction_Type__c = 'Processed',
            MVN_Claim_Authorization_Number__c = 'U18337O37',
            MVN_Original_Claim_Authorization_Number__c = 'U18337O37',
            MVN_Rx_Number__c = 'aeosFLgVgcsVE',
            MVN_Day_Supply__c = 28,
            MVN_DAW__c = '0',
            MVN_NDC__c = '64764030020',
            MVN_Drug_Description__c = 'ENTYVIO 300 MG VIAL',
            MVN_New_Refill_Code__c = '3',
            MVN_Number_Of_Refills__c = '11',
            MVN_Other_Coverage_Code__c = '8',
            MVN_Group_Number__c = 'EC13103002',
            MVN_Member_Id__c = '9137243527',
            MVN_Patient_Gender__c = 'F',
            MVN_NABP__c = '4842717',
            MVN_Pharmacy_Name__c = 'ECCCC PHARMACY',
            MVN_Pharmacy_Address1__c = '1240 LEE ST',
            MVN_Pharmacy_Address2__c = '',
            MVN_Pharmacy_City__c = 'CHARLOTTESVILLE',
            MVN_Pharmacy_State__c = 'VA',
            MVN_Pharmacy_Zip__c = '22903',
            MVN_Pharmacy_NPI__c = '1114947140',
            MVN_Physician_Name__c = 'BEHM, BRIAN WINTERS MD',
            MVN_Physician_First_Name__c = 'BRIAN WINTERS',
            MVN_Physician_Middle_Name__c = '',
            MVN_Physician_Last_Name__c = 'BEHM',
            MVN_Physician_Suffix__c = '',
            MVN_Physician_Prof_Designation__c = 'MD',
            MVN_Physician_Specialty_1__c = 'Gastroenterology',
            MVN_Physician_Specialty_2__c = 'Internal Medicine',
            MVN_Physician_Address1__c = '1301 JEFFERSON PARK AVE',
            MVN_Physician_Address2__c = '',
            MVN_Physician_City__c = 'CHARLOTTESVILLE',
            MVN_Physician_State__c = 'VA',
            MVN_Physician_Zip__c = '229033362',
            MVN_Submission_Method__c = 'E',
            RecordTypeId = recordTypeId);
    }

    private static void createAssistancePrograms() {

        // insert User that will be used as Coordinator
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1][0];
        User testUser = new User(
            LastName = 'Testerson',
            FirstName = 'Testy',
            Email = 'testerson@testcode.com',
            Username= 'testerson@testcode.com.test',
            ProfileId= adminProfile.id,
            Alias = 'testy',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocalesIdKey='en_US',
            TimezonesIdKey='America/Los_Angeles',
            Street = 'Test Street',
            MobilePhone = '12345678',
            Phone = '12345678'
        );
        insert testUser;

        // insert Care Plan
        Case carePlan = new Case (
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            Status = 'Open',
            MVN_Coordinator__c = testUser.Id
        );
        insert carePlan;

        // insert Assistance Programs
        Id recordTypeId = Schema.SObjectType.PJN_Assistance_Program__c.getRecordTypeInfosByDeveloperName().get('PJN_Copay').getRecordTypeId();
        upsert new List<PJN_Assistance_Program__c>{
            new PJN_Assistance_Program__c(MVN_Copay_Member_Id__c='9610834643', PJN_Care_Plan__c = carePlan.Id, RecordTypeId = recordTypeId),
            new PJN_Assistance_Program__c(MVN_Copay_Member_Id__c='9137243527', PJN_Care_Plan__c = carePlan.Id, RecordTypeId = recordTypeId)
        };
    }
}