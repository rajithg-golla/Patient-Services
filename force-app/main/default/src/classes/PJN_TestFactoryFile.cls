/**
* @author Mavens
* @date Feb 2019
* @description Class to provide factory methods to create test data for File object
* @group TestFactory
*/
@isTest(isParallel=true) public class PJN_TestFactoryFile {

    public ContentDocumentLink createFile(Id linkedEntityId) {

        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'test.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;

        ContentDocument document = [
            SELECT
                Id, Title, LatestPublishedVersionId
            FROM
                ContentDocument
            LIMIT 1
        ];

        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = linkedEntityid;
        cdl.ContentDocumentId = document.Id;
        cdl.shareType = 'V';
        insert cdl;

        return cdl;
    }
}