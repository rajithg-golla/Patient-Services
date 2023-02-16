@IsTest
private class MVN_SetTransformDocumentCaseLinkHdlrTest {

    @TestSetup
    static void makeData(){
        Test.startTest();
        Case request = createRequest();
        ContentVersion file = createFile();
        createChecklistItem(request, file);
        Test.stopTest();
    }

    private static Case createRequest() {
        Case request = new Case (
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Request').getRecordTypeId(),
            Status = 'Open'
        );
        insert request;
        return [
            SELECT
                Id,
                CaseNumber
            FROM
                Case
            WHERE
                Id = :request.Id
        ];
    }

    private static ContentVersion createFile() {
        ContentVersion file = new ContentVersion(
            Description = 'Test file description',
            PathOnClient = 'MyTestFile.txt',
            Title = 'MyTestFile',
            VersionData = Blob.valueOf('populated')
        );
        insert file;
        return [
            SELECT
                Id,
                ContentDocumentId,
                Title
            FROM
                ContentVersion
            WHERE
                Id = :file.Id
        ];
    }

    private static void createChecklistItem(Case request, ContentVersion file) {
        insert new DocumentChecklistItem(
            Name = 'Checklist Item for ' + request.CaseNumber + ' - ' + file.Title,
            ParentRecordId = request.Id,
            MVN_Document_Id__c = file.ContentDocumentId,
            Status = 'New'
        );
    }

    @IsTest
    static void testIfReassignFileToCase() {
        ContentDocumentLink cdl = buildContentDocumentLink();
        Test.startTest();
        insert cdl;
        Test.stopTest();
        List<ContentDocumentLink> cdls = getContentDocumentLink(cdl.ContentDocumentId);
        System.assertEquals(2, cdls.size(), 'Must have one ContentDocumentLink in the system.');
        Case request = getRequest();
        Set<Id> linkedEntityIds = new Set<Id> {
            UserInfo.getUserId(),
            request.Id
        };
        for (ContentDocumentLink thisCDL : cdls) {
            System.assert(linkedEntityIds.contains(thisCDL.LinkedEntityId), 'ContentDocumentLink must be related to the Request or User ONLY.');
        }
    }

    private static ContentDocumentLink buildContentDocumentLink() {
        DocumentChecklistItem dcli = getChecklistItem();
        return new ContentDocumentLink(
            ContentDocumentId = dcli.MVN_Document_Id__c,
            LinkedEntityId = dcli.Id
        );
    }

    private static DocumentChecklistItem getChecklistItem() {
        return [
            SELECT
                Id,
                MVN_Document_Id__c
            FROM
                DocumentChecklistItem
            WHERE
                MVN_Document_Id__c != null
            LIMIT 1
        ];
    }

    private static List<ContentDocumentLink> getContentDocumentLink(Id cdId) {
        return [
            SELECT
                Id,
                ContentDocumentId,
                LinkedEntityId
            FROM
                ContentDocumentLink
            WHERE
                ContentDocumentId = :cdId
        ];
    }

    private static Case getRequest() {
        return [
            SELECT
                Id,
                CaseNumber
            FROM
                Case
            WHERE
                RecordType.DeveloperName = 'PJN_Request'
            LIMIT 1
        ];
    }
}