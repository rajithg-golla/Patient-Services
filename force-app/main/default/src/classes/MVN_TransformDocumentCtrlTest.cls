/**
 * @author      Mavens
 * @group       TransformDocument
 * @description Test for MVN_TransformDocumentCtrl
 */
@IsTest
private class MVN_TransformDocumentCtrlTest {

    @TestSetup
    static void makeData(){
        Test.startTest();
        Case request = createRequest();
        createFiles(request);
        Test.stopTest();
    }

    private static Case createRequest() {
        Case request = new Case (
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Request').getRecordTypeId(),
            Status = 'Open'
        );
        insert request;
        return request;
    }

    private static void createFiles(Case request) {
        ContentVersion file = new ContentVersion(
            Description = 'Test file description',
            PathOnClient = 'MyTestFile.txt',
            Title = 'MyTestFile',
            VersionData = Blob.valueOf('populated')
        );
        insert file;
        file = [
            SELECT
                Id,
                ContentDocumentId
            FROM
                ContentVersion
            WHERE
                Id = :file.Id
        ];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = file.ContentDocumentId,
            LinkedEntityId = request.Id
        );
        insert cdl;
    }

    @IsTest
    static void testIfGetAllContentDocumentLinks() {
        Case request = getRequest();
        List<ContentVersion> cvs;
        Test.startTest();
        cvs = MVN_TransformDocumentCtrl.getFilesRelated(request.Id);
        Test.stopTest();
        System.assertNotEquals(null, cvs, 'Get Files Related method is not working.');
        System.assert(!cvs.isEmpty(), 'Request must have Files related.');
    }

    @IsTest
    static void testIfCreateDocumentDataCorrectly() {
        Case request = getRequest();
        List<ContentVersion> cvs = MVN_TransformDocumentCtrl.getFilesRelated(request.Id);
        System.assertNotEquals(null, cvs, 'Get Files Related method is not working.');
        System.assert(!cvs.isEmpty(), 'Request must have Files related.');
        Id checklistItemId;
        ContentVersion currentFile = cvs[0];
        Test.startTest();
        checklistItemId = MVN_TransformDocumentCtrl.createDocumentData(request.Id, currentFile);
        Test.stopTest();
        System.assertNotEquals(null, checklistItemId, 'Create Document Data method is not working.');
        DocumentChecklistItem checklistItem = getChecklistItem(checklistItemId);
        String expectedItemName = String.format(
            Label.MVN_Transform_Document_Checklist_Name,
            new List<String> {
                request.CaseNumber,
                currentFile.Title,
                ''
            }
        );
        System.assertEquals(expectedItemName, checklistItem.Name, 'Checklist item name is incorrect.');
        System.assertEquals(request.Id, checklistItem.ParentRecordId, 'Checklist item parent record must be the request.');
        System.assertEquals(currentFile.ContentDocumentId, checklistItem.MVN_Document_Id__c, 'Checklist item document id must be the first Content Version found.');
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

    private static DocumentChecklistItem getChecklistItem(Id checklistItemId) {
        return [
            SELECT
                Id,
                Name,
                ParentRecordId,
                Status,
                MVN_Document_Id__c
            FROM
                DocumentChecklistItem
            WHERE
                Id = :checklistItemId
        ];
    }
}