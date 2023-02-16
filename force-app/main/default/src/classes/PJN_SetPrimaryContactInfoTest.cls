/**
* @author Mavens
* @date Apr 2019
* @description Test class for PJN_SetPrimaryContactInfo
* @group ContactInformation
*/
@isTest(isParallel=true)
private class PJN_SetPrimaryContactInfoTest {

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
            PJN_Account_Search_Handler_Classes__c = 'PJN_AccountSearchHdlr,PJN_NetworkSearchHdlr',
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
                    PJN_Class__c = 'PJN_SetPrimaryContactInfo',
                    PJN_Event__c = 'BEFORE_INSERT',
                    PJN_SObject_API_Name__c = 'PJN_Contact_Information__c'
                ),
                new PJN_Trigger_Handler_Setting__mdt(
                    PJN_Class__c = 'PJN_SetPrimaryContactInfo',
                    PJN_Event__c = 'BEFORE_UPDATE',
                    PJN_SObject_API_Name__c = 'PJN_Contact_Information__c'
                ),
                new PJN_Trigger_Handler_Setting__mdt(
                    PJN_Class__c = 'PJN_SetPrimaryContactInfo',
                    PJN_Event__c = 'AFTER_INSERT',
                    PJN_SObject_API_Name__c = 'PJN_Contact_Information__c'
                ),
                new PJN_Trigger_Handler_Setting__mdt(
                    PJN_Class__c = 'PJN_SetPrimaryContactInfo',
                    PJN_Event__c = 'AFTER_UPDATE',
                    PJN_SObject_API_Name__c = 'PJN_Contact_Information__c'
                )
            }
        };
    }

    @isTest
    private static void testSetPrimaryContactInformationOnInsert() {
        Account patient = getPatient();
        List<PJN_Contact_Information__c> contactInfoList = new List<PJN_Contact_Information__c>();
        contactInfoList.add(new PJN_Contact_Information__c(
            RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Email').getRecordTypeId(),
            PJN_Email__c = 'hola@email.com',
            PJN_Account__c = patient.Id,
            PJN_Set_as_Primary__c = true
        ));
        contactInfoList.add(new PJN_Contact_Information__c(
            RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Phone').getRecordTypeId(),
            PJN_Phone__c = '123456789',
            PJN_Account__c = patient.Id,
            PJN_Set_as_Primary__c = true
        ));
        Test.startTest();
            insert contactInfoList;
        Test.stopTest();

        for (PJN_Contact_Information__c contactInfoResult : [SELECT PJN_Primary__c
                                                            FROM PJN_Contact_Information__c
                                                            WHERE Id IN :contactInfoList]) {
            System.assert(contactInfoResult.PJN_Primary__c);
        }
        Account accResult = [SELECT PJN_Primary_Email__c, PJN_Primary_Phone__c
                            FROM Account
                            WHERE Id = :patient.Id];
        System.assert(accResult.PJN_Primary_Email__c == contactInfoList.get(0).Id);
        System.assert(accResult.PJN_Primary_Phone__c == contactInfoList.get(1).Id);
    }

    @isTest
    private static void testSetPrimaryContactInformationOnUpdate() {
        Account patient = getPatient();
        PJN_Contact_Information__c contactInfo = new PJN_Contact_Information__c(
            RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId(),
            PJN_Address_Line_1__c = 'address test',
            PJN_Account__c = patient.Id,
            PJN_Set_as_Primary__c = false
        );
        insert contactInfo;
        System.assert(![SELECT PJN_Primary__c FROM PJN_Contact_Information__c WHERE Id = :contactInfo.Id].PJN_Primary__c);
        System.assert([SELECT PJN_Primary_Address__c FROM Account WHERE Id = :patient.Id].PJN_Primary_Address__c == null);

        Test.startTest();
            contactInfo.PJN_Set_as_Primary__c = true;
            update contactInfo;
        Test.stopTest();

        System.assert([SELECT PJN_Primary__c FROM PJN_Contact_Information__c WHERE Id = :contactInfo.Id].PJN_Primary__c);
        System.assert([SELECT PJN_Primary_Address__c FROM Account WHERE Id = :patient.Id].PJN_Primary_Address__c == contactInfo.Id);
    }

    @isTest
    private static void testUpdatePrimaryContactInformation() {
        Account patient = getPatient();
        PJN_Contact_Information__c contactInfo = new PJN_Contact_Information__c(
            RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Fax').getRecordTypeId(),
            PJN_Fax__c = '123456789',
            PJN_Account__c = patient.Id,
            PJN_Set_as_Primary__c = true
        );
        insert contactInfo;
        System.assert([SELECT PJN_Primary__c FROM PJN_Contact_Information__c WHERE Id = :contactInfo.Id].PJN_Primary__c);
        System.assert([SELECT PJN_Primary_Fax__c FROM Account WHERE Id = :patient.Id].PJN_Primary_Fax__c == contactInfo.Id);

        Test.startTest();
            PJN_Contact_Information__c newContactInfo = new PJN_Contact_Information__c(
                RecordTypeId = SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Fax').getRecordTypeId(),
                PJN_Fax__c = '123456789',
                PJN_Account__c = patient.Id,
                PJN_Set_as_Primary__c = true
            );
            insert newContactInfo;
        Test.stopTest();

        System.assert([SELECT PJN_Primary_Fax__c FROM Account WHERE Id = :patient.Id].PJN_Primary_Fax__c == newContactInfo.Id);

    }

    private static Account getPatient() {
        return [SELECT Id FROM Account LIMIT 1];
    }

}