/**
* @author Mavens
* @date Feb 2019
* @description Test class for PJN_FilesHdlr
* @group TestFactory
*/
@isTest
private class PJN_FilesHdlrTest {

    /**
    * @description setups data for all unit tests
    */
    @TestSetup
    static void makeData(){
        PJN_TestFactoryCase caseFactory = new PJN_TestFactoryCase();
        Case carePlanCase = caseFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId(),
                'Status' => 'Test',
                'Subject' => 'Care Plan Case'
            }
        );

       caseFactory.create(
            new Map<String, Object> {
                'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId(),
                'Status' => 'Test',
                'Subject' => 'Activity Case',
                'ParentId' => carePlanCase.Id
            }
        );
    }

    @isTest
    private static void testInsertFileOnChildRecord() {
        Case carePlanCase = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'CarePlan' LIMIT 1];
        Case activityCase = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'PJN_Activity' LIMIT 1];
        List<ContentDocumentLink> parentFiles = [
            SELECT
                Id
            FROM
                ContentDocumentLink
            WHERE
                LinkedEntityId =: carePlanCase.Id
        ];
        System.assert(parentFiles.isEmpty());

        Test.startTest();
        new PJN_TestFactoryFile().createFile(activityCase.Id);
        Test.stopTest();

        parentFiles = [
            SELECT
                Id
            FROM
                ContentDocumentLink
            WHERE
                LinkedEntityId =: carePlanCase.Id
        ];
        System.assert(!parentFiles.isEmpty());
    }

    @isTest
    private static void testInsertEmailMessage() {
        Case carePlanCase = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'CarePlan' LIMIT 1];
        Case activityCase = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'PJN_Activity' LIMIT 1];
        List<ContentDocumentLink> caseFiles = [
            SELECT
                Id
            FROM
                ContentDocumentLink
            WHERE
                LinkedEntityId =: activityCase.Id
        ];
        System.assert(caseFiles.isEmpty());

        EmailMessage emailMessage = new EmailMessage(
            Incoming = true,
            ParentId = activityCase.Id,
            FromAddress = 'test@mavens.org',
            ToAddress= 'hello@670ocglw7xhomi4oyr5yw2zvf.8kp7yeag.8.case.salesforce.com',
            Subject = 'Test email',
            TextBody = 'Test Body'
        );
        insert emailMessage;

        Test.startTest();
        new PJN_TestFactoryFile().createFile(emailMessage.Id);
        Test.stopTest();

        caseFiles = [
            SELECT
                Id
            FROM
                ContentDocumentLink
            WHERE
                LinkedEntityId =: activityCase.Id
        ];
        System.assert(!caseFiles.isEmpty());
    }

    @isTest
    private static void testUpdateParentId() {
        Case carePlanCase = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'CarePlan' LIMIT 1];
        Case activityCase = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'PJN_Activity' LIMIT 1];
        activityCase.ParentId = null;
        update activityCase;

        new PJN_TestFactoryFile().createFile(activityCase.Id);

        List<ContentDocumentLink> parentFiles = [
            SELECT
                Id
            FROM
                ContentDocumentLink
            WHERE
                LinkedEntityId =: carePlanCase.Id
        ];
        System.assert(parentFiles.isEmpty());

        Test.startTest();

        activityCase.ParentId = carePlanCase.Id;
        update activityCase;

        Test.stopTest();

        parentFiles = [
            SELECT
                Id
            FROM
                ContentDocumentLink
            WHERE
                LinkedEntityId =: carePlanCase.Id
        ];
        System.assert(!parentFiles.isEmpty());
    }
}