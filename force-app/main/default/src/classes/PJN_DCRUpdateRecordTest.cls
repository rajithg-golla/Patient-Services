/**
 * Test for PJN_DCRUpdateRecord
 * @author  Mavens
 * @group   DCR
 */
@IsTest
public with sharing class PJN_DCRUpdateRecordTest {
    private static final Integer DATA_SIZE = 100;

    static {
        PJN_NetworkObjectSetting.NetworkObjectSettingsQuery = (PJN_NetworkObjectSettingsQuery) Test.createStub(PJN_NetworkObjectSettingsQuery.class, new PJN_NetworkObjectSettingsMock());
        PJN_NetworkObjectSetting.NetworkRecordTypeMappingsQuery = (PJN_NetworkRecordTypeMappingsQuery) Test.createStub(PJN_NetworkRecordTypeMappingsQuery.class, new PJN_NetworkRecordTypeMappingsMock());
        PJN_NetworkObjectSetting.NetworkFieldMappingsQuery = (PJN_NetworkFieldMappingsQuery) Test.createStub(PJN_NetworkFieldMappingsQuery.class, new PJN_NetworkFieldMappingsMock());

        PJN_NetworkStatusMapping.networkStatusMappingQuery = (PJN_NetworkStatusMappingQuery) Test.createStub(PJN_NetworkStatusMappingQuery.class, new PJN_NetworkStatusMappingMock());
        Test.setMock(HttpCalloutMock.class, new PJN_NetworkSyncMock.RetrieveHCPSuccessMock());
    }

    @TestSetup
    static void makeData(){
        PJN_TestFactoryGlobalSetting.setMock();

        Test.startTest();
        List<Account> accounts = createAccounts(DATA_SIZE);
        createAddresses(accounts);
        createLicenses(accounts);
        Test.stopTest();
    }

    private static List<Account> createAccounts(Integer numOfAccounts) {
        List<Account> accounts = new List<Account>();

        for (Integer accIndex = 0; accIndex < numOfAccounts; accIndex++) {
            Integer currentAccountNetworkId = 6000 + accIndex;

            accounts.add(
                new Account(
                    FirstName = 'Test' + accIndex,
                    LastName = 'Test' + accIndex,
                    RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Physician').getRecordTypeId(),
                    PersonMobilePhone = '555555555555',
                    PJN_Veeva_Network_Id__c = '93358025901211' + currentAccountNetworkId
                )
            );
        }

        insert accounts;

        return accounts;
    }

    private static void createAddresses(List<Account> accounts) {
        List<PJN_Contact_Information__c> address = new List<PJN_Contact_Information__c>();

        Integer currentCount = 6000;

        for (Account thisAccount : accounts) {
            address.add(
                new PJN_Contact_Information__c(
                    PJN_Address_Line_1__c = 'Main Street 123',
                    PJN_Account__c = thisAccount.Id,
                    PJN_Veeva_Network_Id__c = '93358025901200' + currentCount,
                    RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId()
                )
            );
            currentCount++;
        }

        insert address;
    }

    private static void createLicenses(List<Account> accounts) {
        List<PJN_License__c> licenses = new List<PJN_License__c>();

        Integer currentCount = 6000;

        for (Account thisAccount : accounts) {
            licenses.add(
                new PJN_License__c(
                    Name = '1234567',
                    PJN_Type__c = 'NPI',
                    PJN_Account__c = thisAccount.Id,
                    PJN_Veeva_Network_Id__c = '93291072424496' + currentCount
                )
            );
            currentCount++;
        }

        insert licenses;
    }

    @IsTest
    static void testIfDCRUpdateRecords() {
        List<PJN_Data_Change_Request__c> dcrs = getDCRsWithStatusUpdated();
        List<PJN_Data_Change_Request_Line__c> dcrLines = new List<PJN_Data_Change_Request_Line__c>();

        for (PJN_Data_Change_Request__c dcr : dcrs) {
            dcrLines.addAll(dcr.PJN_Data_Change_Request_Lines__r);
        }

        // update dcrLines;

        Test.startTest();
        PJN_DCR.updateFromNetwork = true;
        update dcrs;
        Test.stopTest();

        dcrs = [
            SELECT
                Id,
                PJN_Status__c
            FROM
                PJN_Data_Change_Request__c
        ];

        System.assert(!dcrs.isEmpty(), 'NO DCR found.');

        for (PJN_Data_Change_Request__c dcr : dcrs) {
            System.assertEquals(PJN_NetworkConstants.DCR_STATUS_UPDATED, dcr.PJN_Status__c, 'DCR Status must be ' + PJN_NetworkConstants.DCR_STATUS_UPDATED);
        }
    }

    private static List<PJN_Data_Change_Request__c> getDCRsWithStatusUpdated() {
        List<PJN_Data_Change_Request__c> dcrs = [
            SELECT
                Id,
                PJN_Status__c,
                (
                    SELECT
                        Id,
                        Name,
                        PJN_Account__c,
                        PJN_Field_Label__c,
                        PJN_Field_API_Name__c,
                        PJN_Old_Value__c,
                        PJN_New_Value__c,
                        PJN_Final_Value__c
                    FROM
                        PJN_Data_Change_Request_Lines__r
                )
            FROM
                PJN_Data_Change_Request__c
        ];

        for (PJN_Data_Change_Request__c dcr : dcrs) {
            dcr.PJN_Status__c = PJN_NetworkConstants.DCR_STATUS_PROCESSED;
            for (PJN_Data_Change_Request_Line__c dcrLine : dcr.PJN_Data_Change_Request_lines__r) {
                if (String.isBlank(dcrLine.PJN_New_Value__c)) {
                    continue;
                }
                dcrLine.PJN_Final_Value__c = dcrLine.PJN_New_Value__c + 'Updated';
            }
        }

        return dcrs;
    }
}