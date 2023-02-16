/**
* @author Mavens
* @date Mar 2019
* @description Test class for PJN_PatientMergeCtrl
* @group TestFactory
*/
@isTest(isParallel=true) private class PJN_PatientMergeCtrlTest {
    @testSetup private static void setup() {
        PJN_TestFactoryAccount accountFactory = new PJN_TestFactoryAccount();
        List<Account> patientList = new List<Account>();
        patientList.add(accountFactory.construct(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
                'LastName' => 'Patient 1 Test'
            }
        ));
        patientList.add(accountFactory.construct(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId(),
                'LastName' => 'Patient 2 Test'
            }
        ));
        insert patientList;

        PJN_TestFactoryContactInformation contactInformationFactory = new PJN_TestFactoryContactInformation();
        List<PJN_Contact_Information__c> contactInfoList = new List<PJN_Contact_Information__c>();
        contactInfoList.add(contactInformationFactory.constructAddress(new Map<String,Object>{
            'PJN_Address_Line_1__c' => 'Patient1 Address Line 1',
            'PJN_Address_Line_2__c' => 'Patient1 Address Line 2',
            'PJN_Set_as_Primary__c' => false,
            'PJN_City__c' => 'Patient1 City',
            'PJN_Postal_Code__c' => '1111',
            'PJN_State__c' => PJN_Contact_Information__c.PJN_State__c.getDescribe().getPicklistValues().get(0).getValue(),
            'PJN_Country__c' => 'United States',
            'PJN_Account__c' => patientList.get(0).Id
        }));
        contactInfoList.add(contactInformationFactory.constructAddress(new Map<String,Object>{
            'PJN_Address_Line_1__c' => 'Patient2 Address Line 1',
            'PJN_Address_Line_2__c' => 'Patient2 Address Line 2',
            'PJN_Set_as_Primary__c' => false,
            'PJN_City__c' => 'Patient2 City',
            'PJN_Postal_Code__c' => '2222',
            'PJN_State__c' => PJN_Contact_Information__c.PJN_State__c.getDescribe().getPicklistValues().get(0).getValue(),
            'PJN_Country__c' => 'United States',
            'PJN_Account__c' => patientList.get(1).Id
        }));
        insert contactInfoList;

        PJN_Data_Change_Request__c dcr = new PJN_Data_Change_Request__c(
            RecordTypeId = SObjectType.PJN_Data_Change_Request__c.getRecordTypeInfosByName().get('Patient Merge').getRecordTypeId(),
            PJN_Patient_1__c = patientList.get(0).Id,
            PJN_Patient_2__c = patientList.get(1).Id,
            PJN_Status__c = 'Pending',
            PJN_External_Id__c = 'TEST|Pending'
        );
        insert dcr;
    }

    @isTest private static void testGetDCRRecords() {
        PJN_MergeToolSetting mockMergeToolSetting = (PJN_MergeToolSetting) Test.createStub(PJN_MergeToolSetting.class, new PJN_MergeToolSettingMock());
        PJN_PatientMergeCtrl.mergeToolSetting = mockMergeToolSetting;

        Test.startTest();
            List<Schema.FieldSetMember> fields =
                Schema.SObjectType.PJN_Data_Change_Request__c.fieldSets.PJN_Merge_Tool_DCR_Fields.getFields();

            PJN_DataTable dcrRecords = PJN_PatientMergeCtrl.getDCRRecords();
            System.assertEquals(1, dcrRecords.data.size());
            System.assertEquals(fields.size() + 1, dcrRecords.columns.size()); // +1 for Merge+Reject actions
        Test.stopTest();
    }

    @isTest private static void testGetAccounts() {
        PJN_MergeToolSetting mockMergeToolSetting = (PJN_MergeToolSetting) Test.createStub(PJN_MergeToolSetting.class, new PJN_MergeToolSettingMock());
        PJN_PatientMergeCtrl.mergeToolSetting = mockMergeToolSetting;

        Id patientRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
        Account patient1 = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId LIMIT 1];
        Account patient2 = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId AND Id != :patient1.Id LIMIT 1];

        Test.startTest();
            List<Schema.FieldSetMember> fields =
                Schema.SObjectType.Account.fieldSets.PJN_Merge_Tool_Account_Fields.getFields();

            Map<String, List<Object>> accountRecords = PJN_PatientMergeCtrl.getAccounts(
                new List<Id>{patient1.Id, patient2.Id}
            );
            System.assertEquals(2, accountRecords.get('accountList').size());
            System.assertEquals(fields.size(), accountRecords.get('fieldList').size());
        Test.stopTest();
    }

    @isTest private static void testGetCarePlans() {
        PJN_MergeToolSetting mockMergeToolSetting = (PJN_MergeToolSetting) Test.createStub(PJN_MergeToolSetting.class, new PJN_MergeToolSettingMock());
        PJN_PatientMergeCtrl.mergeToolSetting = mockMergeToolSetting;

        Id patientRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
        Account patient1 = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId LIMIT 1];
        Account patient2 = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId AND Id != :patient1.Id LIMIT 1];

        Test.startTest();
            PJN_TestFactoryCase caseFactory = new PJN_TestFactoryCase();
            List<Case> carePlanList = new List<Case>();
            carePlanList.add(caseFactory.construct(
                new Map<String, Object> {
                    'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId(),
                    'Status' => 'Test',
                    'Subject' => 'Care Plan Case',
                    'AccountId' => patient1.Id
                }
            ));
            carePlanList.add(caseFactory.construct(
                new Map<String, Object> {
                    'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId(),
                    'Status' => 'Test',
                    'Subject' => 'Care Plan Case',
                    'AccountId' => patient2.Id
                }
            ));
            insert carePlanList;
            Case carePlan1 = carePlanList.get(0);
            Case carePlan2 = carePlanList.get(1);

            List<Case> activityList = new List<Case>();
            activityList.add(caseFactory.construct(
                new Map<String, Object> {
                    'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('Activity').getRecordTypeId(),
                    'Status' => 'Test',
                    'Subject' => 'Activity Case',
                    'ParentId' => carePlan1.Id,
                    'AccountId' => patient1.Id
                }
            ));
            activityList.add(caseFactory.construct(
                new Map<String, Object> {
                    'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('Activity').getRecordTypeId(),
                    'Status' => 'Test',
                    'Subject' => 'Activity Case',
                    'ParentId' => carePlan2.Id,
                    'AccountId' => patient2.Id
                }
            ));
            insert activityList;
            Case activityCase1 = activityList.get(0);
            Case activityCase2 = activityList.get(1);

            List<Schema.FieldSetMember> fieldsTable =
                Schema.SObjectType.Case.fieldSets.PJN_Merge_Tool_Table_Care_Plan_Fields.getFields();
            List<Schema.FieldSetMember> fieldsCard =
                Schema.SObjectType.Case.fieldSets.PJN_Merge_Tool_Card_Care_Plan_Fields.getFields();

            PJN_PatientMergeCtrl.PJN_ChildObject carePlanResult = PJN_PatientMergeCtrl.getCarePlanRecords(
                new List<Id>{patient1.Id, patient2.Id}
            );
            System.assertEquals(2, carePlanResult.recordList.size());
            System.assertEquals(fieldsTable.size()+1, carePlanResult.columns.size());
            System.assertEquals(fieldsCard.size(), carePlanResult.cardFieldList.size());
            System.assertEquals(fieldsTable.size(), carePlanResult.fieldList.size());
            System.assertEquals('Case', carePlanResult.childRecordName);
        Test.stopTest();
    }

    @isTest private static void testGetChildRecords() {
        PJN_MergeToolSetting mockMergeToolSetting = (PJN_MergeToolSetting) Test.createStub(PJN_MergeToolSetting.class, new PJN_MergeToolSettingMock());
        PJN_PatientMergeCtrl.mergeToolSetting = mockMergeToolSetting;

        Id patientRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
        Account patient1 = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId LIMIT 1];
        Account patient2 = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId AND Id != :patient1.Id LIMIT 1];

        Test.startTest();
            PJN_TestFactoryCase caseFactory = new PJN_TestFactoryCase();
            List<Case> carePlanList = new List<Case>();
            carePlanList.add(caseFactory.construct(
                new Map<String, Object> {
                    'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId(),
                    'Status' => 'Test',
                    'Subject' => 'Care Plan Case',
                    'AccountId' => patient1.Id
                }
            ));
            carePlanList.add(caseFactory.construct(
                new Map<String, Object> {
                    'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId(),
                    'Status' => 'Test',
                    'Subject' => 'Care Plan Case',
                    'AccountId' => patient2.Id
                }
            ));
            insert carePlanList;
            Case carePlan1 = carePlanList.get(0);
            Case carePlan2 = carePlanList.get(1);

            List<Case> activityList = new List<Case>();
            activityList.add(caseFactory.construct(
                new Map<String, Object> {
                    'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('Activity').getRecordTypeId(),
                    'Status' => 'Test',
                    'Subject' => 'Activity Case',
                    'ParentId' => carePlan1.Id,
                    'AccountId' => patient1.Id
                }
            ));
            activityList.add(caseFactory.construct(
                new Map<String, Object> {
                    'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('Activity').getRecordTypeId(),
                    'Status' => 'Test',
                    'Subject' => 'Activity Case',
                    'ParentId' => carePlan2.Id,
                    'AccountId' => patient2.Id
                }
            ));
            insert activityList;
            Case activityCase1 = activityList.get(0);
            Case activityCase2 = activityList.get(1);

            List<HealthCloudGA__EhrMedicationPrescription__c> prescriptionList = new List<HealthCloudGA__EhrMedicationPrescription__c>();
            prescriptionList.add(new HealthCloudGA__EhrMedicationPrescription__c(
                PJN_Care_Plan__c = carePlan1.Id,
                HealthCloudGA__DispenseMedicationCode__c = 'Code1'
            ));
            prescriptionList.add(new HealthCloudGA__EhrMedicationPrescription__c(
                PJN_Care_Plan__c = carePlan2.Id,
                HealthCloudGA__DispenseMedicationCode__c = 'Code2'
            ));
            insert prescriptionList;
            HealthCloudGA__EhrMedicationPrescription__c prescription1 = prescriptionList.get(0);
            HealthCloudGA__EhrMedicationPrescription__c prescription2 = prescriptionList.get(1);

            List<PJN_Member_Plan__c> memberPlanList = new List<PJN_Member_Plan__c>();
            memberPlanList.add(new PJN_Member_Plan__c(
                PJN_Care_Plan__c = carePlan1.Id,
                PJN_Expiration_Date__c = Date.today(),
                PJN_Coverage_Order__c = 'Primary'
            ));
            memberPlanList.add(new PJN_Member_Plan__c(
                PJN_Care_Plan__c = carePlan2.Id,
                PJN_Expiration_Date__c = Date.today(),
                PJN_Coverage_Order__c = 'Primary'
            ));
            insert memberPlanList;
            PJN_Member_Plan__c memberPlan1 = memberPlanList.get(0);
            PJN_Member_Plan__c memberPlan2 = memberPlanList.get(1);

            List<PJN_PatientMergeCtrl.PJN_ChildObject> childRecords = PJN_PatientMergeCtrl.getChildRecords(
                new List<Id>{carePlan1.Id, carePlan2.Id}
            );
            System.assertEquals(2, childRecords.size());

            PJN_PatientMergeCtrl.PJN_ChildObject childRecord1 = childRecords.get(0);
            System.assertEquals('HealthCloudGA__EhrMedicationPrescription__c', childRecord1.childRecordName);
            System.assertEquals(3, childRecord1.columns.size());
            System.assertEquals(2, childRecord1.recordList.size());

            PJN_PatientMergeCtrl.PJN_ChildObject childRecord2 = childRecords.get(1);
            System.assertEquals('PJN_Member_Plan__c', childRecord2.childRecordName);
            System.assertEquals(3, childRecord2.columns.size());
            System.assertEquals(2, childRecord2.recordList.size());
        Test.stopTest();
    }

    @isTest private static void testGetContactInformation() {
        PJN_MergeToolSetting mockMergeToolSetting = (PJN_MergeToolSetting) Test.createStub(PJN_MergeToolSetting.class, new PJN_MergeToolSettingMock());
        PJN_PatientMergeCtrl.mergeToolSetting = mockMergeToolSetting;

        Id patientRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
        Account patient1 = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId LIMIT 1];
        Account patient2 = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId AND Id != :patient1.Id LIMIT 1];
        PJN_Data_Change_Request__c dcr = [SELECT Id FROM PJN_Data_Change_Request__c WHERE PJN_Patient_1__c = :patient1.Id AND PJN_Patient_2__c = :patient2.Id LIMIT 1];

        Test.startTest();
            List<Schema.FieldSetMember> fields =
                Schema.SObjectType.PJN_Contact_Information__c.fieldSets.PJN_Merge_Tool_Contact_Info_Fields.getFields();

            PJN_PatientMergeCtrl.PJN_ChildObject contactInfoResult = PJN_PatientMergeCtrl.getContactInformationRecords(
                new List<Id>{patient1.Id, patient2.Id}
            );
            System.assertEquals(2, contactInfoResult.recordList.size());
            System.assertEquals(fields.size()+1, contactInfoResult.columns.size());
            System.assertEquals('PJN_Contact_Information__c', contactInfoResult.childRecordName);
        Test.stopTest();
    }

    @isTest private static void testRejectMerge() {
        PJN_MergeToolSetting mockMergeToolSetting = (PJN_MergeToolSetting) Test.createStub(PJN_MergeToolSetting.class, new PJN_MergeToolSettingMock());
        PJN_PatientMergeCtrl.mergeToolSetting = mockMergeToolSetting;

        Id patientRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
        Account patient1 = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId LIMIT 1];
        Account patient2 = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId AND Id != :patient1.Id LIMIT 1];
        PJN_Data_Change_Request__c dcr = [SELECT Id FROM PJN_Data_Change_Request__c WHERE PJN_Patient_1__c = :patient1.Id AND PJN_Patient_2__c = :patient2.Id LIMIT 1];

        Test.startTest();
            PJN_PatientMergeCtrl.rejectMerge(dcr.Id);
            System.assertEquals('Rejected', [SELECT PJN_Status__c FROM PJN_Data_Change_Request__c
                                            WHERE Id = :dcr.Id].PJN_Status__c);
        Test.stopTest();
    }

    @isTest private static void testMergeAccounts() {
        PJN_MergeToolSetting mockMergeToolSetting = (PJN_MergeToolSetting) Test.createStub(PJN_MergeToolSetting.class, new PJN_MergeToolSettingMock());
        PJN_PatientMergeCtrl.mergeToolSetting = mockMergeToolSetting;

        Id patientRTId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId();
        Account patient1 = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId LIMIT 1];
        Account patient2 = [SELECT Id FROM Account WHERE RecordTypeId = :patientRTId AND Id != :patient1.Id LIMIT 1];
        PJN_Contact_Information__c contactInfo1 = [SELECT Id FROM PJN_Contact_Information__c WHERE PJN_Account__c = :patient1.Id LIMIT 1];
        PJN_Data_Change_Request__c dcr = [SELECT Id FROM PJN_Data_Change_Request__c WHERE PJN_Patient_1__c = :patient1.Id AND PJN_Patient_2__c = :patient2.Id LIMIT 1];

        Test.startTest();
            PJN_TestFactoryCase caseFactory = new PJN_TestFactoryCase();
            List<Case> carePlanList = new List<Case>();
            carePlanList.add(caseFactory.construct(
                new Map<String, Object> {
                    'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId(),
                    'Status' => 'Test',
                    'Subject' => 'Care Plan Case',
                    'AccountId' => patient1.Id
                }
            ));
            carePlanList.add(caseFactory.construct(
                new Map<String, Object> {
                    'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId(),
                    'Status' => 'Test',
                    'Subject' => 'Care Plan Case',
                    'AccountId' => patient2.Id
                }
            ));
            insert carePlanList;
            Case carePlan1 = carePlanList.get(0);
            Case carePlan2 = carePlanList.get(1);

            List<Case> activityList = new List<Case>();
            activityList.add(caseFactory.construct(
                new Map<String, Object> {
                    'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('Activity').getRecordTypeId(),
                    'Status' => 'Test',
                    'Subject' => 'Activity Case',
                    'ParentId' => carePlan1.Id,
                    'AccountId' => patient1.Id
                }
            ));
            activityList.add(caseFactory.construct(
                new Map<String, Object> {
                    'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('Activity').getRecordTypeId(),
                    'Status' => 'Test',
                    'Subject' => 'Activity Case',
                    'ParentId' => carePlan2.Id,
                    'AccountId' => patient2.Id
                }
            ));
            insert activityList;
            Case activityCase1 = activityList.get(0);
            Case activityCase2 = activityList.get(1);

            List<HealthCloudGA__EhrMedicationPrescription__c> prescriptionList = new List<HealthCloudGA__EhrMedicationPrescription__c>();
            prescriptionList.add(new HealthCloudGA__EhrMedicationPrescription__c(
                PJN_Care_Plan__c = carePlan1.Id,
                HealthCloudGA__DispenseMedicationCode__c = 'Code1'
            ));
            prescriptionList.add(new HealthCloudGA__EhrMedicationPrescription__c(
                PJN_Care_Plan__c = carePlan2.Id,
                HealthCloudGA__DispenseMedicationCode__c = 'Code2'
            ));
            insert prescriptionList;
            HealthCloudGA__EhrMedicationPrescription__c prescription1 = prescriptionList.get(0);
            HealthCloudGA__EhrMedicationPrescription__c prescription2 = prescriptionList.get(1);

            List<PJN_Member_Plan__c> memberPlanList = new List<PJN_Member_Plan__c>();
            memberPlanList.add(new PJN_Member_Plan__c(
                PJN_Care_Plan__c = carePlan1.Id,
                PJN_Expiration_Date__c = Date.today(),
                PJN_Coverage_Order__c = 'Primary'
            ));
            memberPlanList.add(new PJN_Member_Plan__c(
                PJN_Care_Plan__c = carePlan2.Id,
                PJN_Expiration_Date__c = Date.today(),
                PJN_Coverage_Order__c = 'Primary'
            ));
            insert memberPlanList;
            PJN_Member_Plan__c memberPlan1 = memberPlanList.get(0);
            PJN_Member_Plan__c memberPlan2 = memberPlanList.get(1);

            String selectedCarePlanChildren = '{"' + carePlan1.Id +
                '":{"HealthCloudGA__EhrMedicationPrescription__c":["' + prescription1.Id +
                '"],"PJN_Member_Plan__c":["' + memberPlan1.Id + '","' + memberPlan2.Id + '"]}}';
            String selectedAccountChildren = '{"Case":["' + carePlan1.Id +
                '"],"PJN_Contact_Information__c":["' + contactInfo1.Id + '"]}';

            PJN_PatientMergeCtrl.mergeAccounts(
                dcr.Id,
                patient1.Id,
                selectedCarePlanChildren,
                selectedAccountChildren,
                new List<Id>{contactInfo1.Id},
                new List<Account>{patient1, patient2},
                new List<Id>{carePlan1.Id, carePlan2.Id},
                new Map<Id, List<Id>>()
            );
        Test.stopTest();

        System.assertEquals('Merged', [SELECT PJN_Status__c FROM PJN_Data_Change_Request__c
                                        WHERE Id = :dcr.Id].PJN_Status__c);
        System.assertEquals(0, [SELECT Id FROM Account WHERE Id = :patient2.Id].size());
        System.assertEquals(0, [SELECT Id FROM Case WHERE Id = :carePlan2.Id].size());
        System.assertEquals(2, [SELECT Id FROM PJN_Member_Plan__c WHERE PJN_Care_Plan__c = :carePlan1.Id].size());
        List<HealthCloudGA__EhrMedicationPrescription__c> actualPrescriptionList = [
            SELECT Id FROM HealthCloudGA__EhrMedicationPrescription__c WHERE PJN_Care_Plan__c = :carePlan1.Id
        ];
        System.assertEquals(1, actualPrescriptionList.size());
        System.assertEquals(prescription1.Id, actualPrescriptionList.get(0).Id);
        List<PJN_Contact_Information__c> contactInfoList = [
            SELECT Id FROM PJN_Contact_Information__c WHERE PJN_Account__c = :patient1.Id
        ];
        System.assertEquals(1, contactInfoList.size());
        System.assertEquals(contactInfo1.Id, contactInfoList.get(0).Id);
    }
}