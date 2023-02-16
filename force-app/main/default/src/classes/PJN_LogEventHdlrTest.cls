@isTest(isParallel=true)
private with sharing class PJN_LogEventHdlrTest {
    @isTest
    private static void logEvent() {
        String expectedSource = 'Test Log';
        String expectedMessage = 'Test Message';
        Exception expectedException = new System.AuraHandledException(expectedMessage);
        SObject expectedSObject = new Account(LastName = 'Test Account');

        Test.startTest();
            PJN_LogEventHdlr.publishLogEvent(expectedSource, expectedMessage, expectedException, expectedSObject);
        Test.stopTest();

        PJN_Log__c actualLog = [
            SELECT
                Id,
                PJN_Source__c,
                PJN_Message__c,
                PJN_Exception_Type__c,
                PJN_Exception_JSON__c,
                PJN_SObject_Type__c,
                PJN_SObject_JSON__c
            FROM
                PJN_Log__c
            LIMIT
                1
        ];
        System.assertEquals(
            expectedSource,
            actualLog.PJN_Source__c,
            'Incorrect Source'
        );
        System.assertEquals(
            expectedMessage,
            actualLog.PJN_Message__c,
            'Incorrect Message'
        );
        System.assertEquals(
            'Exception',
            actualLog.PJN_Exception_Type__c,
            'Incorrect Exception Type'
        );
        System.assertEquals(
            expectedException.getStackTraceString(),
            actualLog.PJN_Exception_JSON__c,
            'Incorrect Exception'
        );
        System.assertEquals(
            expectedSObject.getSObjectType().getDescribe().getName(),
            actualLog.PJN_SObject_Type__c,
            'Incorrect SObject Type'
        );
        System.assertEquals(
            JSON.serializePretty(expectedSObject, true),
            actualLog.PJN_SObject_JSON__c,
            'Incorrect SObject'
        );
    }
}