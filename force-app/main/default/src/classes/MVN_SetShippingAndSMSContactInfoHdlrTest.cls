@IsTest
private class MVN_SetShippingAndSMSContactInfoHdlrTest {

    @TestSetup
    static void makeData(){
        new PJN_TestFactoryAccount().create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByName().get('Patient').getRecordTypeId(),
                'LastName' => 'Patient 1 Test'
            }
        );
    }

    static {
        PJN_Utilities.globalSetting = new PJN_Global_Setting__mdt(
            PJN_Account_Search_Handler_Classes__c = 'PJN_AccountSearchHdlr',
            PJN_Account_Search_Max_Results__c = 20.0,
            PJN_Create_DCR__c = false,
            PJN_Enable_Event_Automation__c = true,
            PJN_Include_Open_Data_Network__c = false,
            PJN_Network_API_Version__c = 'v19.0',
            PJN_Network_Named_Credential__c = 'ARGX_Veeva_Network',
            PJN_Network_System__c = 'PJN',
            PJN_Transaction_Log_Level__c = 'All',
            PJN_Veeva_Network__c = true,
            PJN_Contact_Info_Address_Record_Types__c = 'PJN_Address',
            PJN_Contact_Info_Email_Record_Types__c = 'PJN_Email',
            PJN_Contact_Info_Phone_Record_Types__c = 'PJN_Phone',
            PJN_Contact_Info_Fax_Record_Types__c = 'PJN_Fax'
        );

        PJN_TriggerHandlerSettingQuery.triggerHandlerSettingBySObjectType = new Map<SObjectType, List<PJN_Trigger_Handler_Setting__mdt>> {
            SObjectType.PJN_Contact_Information__c.getSObjectType() => new List<PJN_Trigger_Handler_Setting__mdt> {
                new PJN_Trigger_Handler_Setting__mdt(
                    PJN_Class__c = 'MVN_SetShippingAndSMSContactInfoHdlr',
                    PJN_Event__c = 'BEFORE_INSERT',
                    PJN_SObject_API_Name__c = 'PJN_Contact_Information__c'
                ),
                new PJN_Trigger_Handler_Setting__mdt(
                    PJN_Class__c = 'MVN_SetShippingAndSMSContactInfoHdlr',
                    PJN_Event__c = 'BEFORE_UPDATE',
                    PJN_SObject_API_Name__c = 'PJN_Contact_Information__c'
                ),
                new PJN_Trigger_Handler_Setting__mdt(
                    PJN_Class__c = 'MVN_SetShippingAndSMSContactInfoHdlr',
                    PJN_Event__c = 'AFTER_INSERT',
                    PJN_SObject_API_Name__c = 'PJN_Contact_Information__c'
                ),
                new PJN_Trigger_Handler_Setting__mdt(
                    PJN_Class__c = 'MVN_SetShippingAndSMSContactInfoHdlr',
                    PJN_Event__c = 'AFTER_UPDATE',
                    PJN_SObject_API_Name__c = 'PJN_Contact_Information__c'
                )
            }
        };
    }

    @isTest
    private static void testSetShippingAndSMSContactInformationOnInsert() {
        Account patient = getPatient();
        List<PJN_Contact_Information__c> contactInfoList = new List<PJN_Contact_Information__c>();
        contactInfoList.add(new PJN_Contact_Information__c(
            RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId(),
            PJN_Address_Line_1__c = 'address test',
            PJN_Account__c = patient.Id,
            MVN_Set_as_Shipping__c = true
        ));
        contactInfoList.add(new PJN_Contact_Information__c(
            RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Phone').getRecordTypeId(),
            PJN_Phone__c = '123456789',
            PJN_Account__c = patient.Id,
            MVN_Set_as_SMS__c = true
        ));
        Test.startTest();
        insert contactInfoList;
        Test.stopTest();

        for (PJN_Contact_Information__c contactInfoResult : getContactInformation(contactInfoList)) {
            System.assert(!contactInfoResult.MVN_Set_as_SMS__c);
            System.assert(!contactInfoResult.MVN_Set_as_Shipping__c);
        }
        Account accResult = getPatient(patient.Id);
        System.assert(accResult.MVN_Shipping_Address__c == contactInfoList.get(0).Id);
        System.assert(accResult.MVN_SMS_Phone__c == contactInfoList.get(1).Id);
    }

    @isTest
    private static void testSetShippingAndSMSContactInformationOnUpdate() {
        Account patient = getPatient();
        List<PJN_Contact_Information__c> contactInfoList = new List<PJN_Contact_Information__c>();
        contactInfoList.add(new PJN_Contact_Information__c(
            RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId(),
            PJN_Address_Line_1__c = 'address test',
            PJN_Account__c = patient.Id,
            MVN_Set_as_Shipping__c = false
        ));
        contactInfoList.add(new PJN_Contact_Information__c(
            RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Phone').getRecordTypeId(),
            PJN_Phone__c = '123456789',
            PJN_Account__c = patient.Id,
            MVN_Set_as_SMS__c = false
        ));
        insert contactInfoList;
        patient = getPatient(patient.Id);
        System.assertEquals(null, patient.MVN_Shipping_Address__c, 'Patient cannot have a Shipping Address at this stage.');
        System.assertEquals(null, patient.MVN_SMS_Phone__c, 'Patient cannot have a SMS Phone at this stage.');
        Test.startTest();
        contactInfoList[0].MVN_Set_as_Shipping__c = true;
        contactInfoList[1].MVN_Set_as_SMS__c = true;
        update contactInfoList;
        Test.stopTest();
        patient = getPatient(patient.Id);
        System.assertNotEquals(null, patient.MVN_Shipping_Address__c, 'Patient must have a Shipping Address at this stage.');
        System.assertNotEquals(null, patient.MVN_SMS_Phone__c, 'Patient must have a SMS Phone at this stage.');
    }

    @isTest
    private static void testUpdateSMSContactInformation() {
        Account patient = getPatient();
        PJN_Contact_Information__c contactInfo = new PJN_Contact_Information__c(
            RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Phone').getRecordTypeId(),
            PJN_Phone__c = '123456789',
            PJN_Account__c = patient.Id,
            MVN_Set_as_SMS__c = true
        );
        insert contactInfo;
        patient = getPatient(patient.Id);
        System.assertEquals(null, patient.MVN_Shipping_Address__c, 'Patient cannot have a Shipping Address at this stage.');
        System.assertEquals(contactInfo.Id, patient.MVN_SMS_Phone__c, 'Patient must have a SMS Phone at this stage.');
        Test.startTest();
        PJN_Contact_Information__c newContactInfo = new PJN_Contact_Information__c(
            RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Fax').getRecordTypeId(),
            PJN_Phone__c = '123456789',
            PJN_Account__c = patient.Id,
            MVN_Set_as_SMS__c = true
        );
        insert newContactInfo;
        Test.stopTest();
        patient = getPatient(patient.Id);
        System.assertEquals(newContactInfo.Id, patient.MVN_SMS_Phone__c, 'Patient must have a SMS Phone at this stage.');
    }

    private static List<PJN_Contact_Information__c> getContactInformation(List<PJN_Contact_Information__c> contactInfoList) {
        return [
            SELECT
                MVN_Set_as_SMS__c,
                MVN_Set_as_Shipping__c
            FROM
                PJN_Contact_Information__c
            WHERE
                Id IN :contactInfoList
        ];
    }

    private static Account getPatient(Id patientId) {
        return [
            SELECT
                MVN_Shipping_Address__c,
                MVN_SMS_Phone__c
            FROM
                Account
            WHERE
                Id = :patientId
        ];
    }

    private static Account getPatient() {
        return [SELECT Id FROM Account LIMIT 1];
    }

}