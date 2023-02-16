@isTest(isParallel=true) private class PJN_CaseFilesPreviewLightningUtilTest {

    @isTest private static void itShouldReturnFileOptions() {
        Case testCase = new Case();
        insert testCase;

        List<ContentVersion> cvs = new List<ContentVersion> {
            new Contentversion(
                Title = 'ABC.pdf',
                PathOnClient = 'test',
                VersionData = EncodingUtil.base64Decode('Unit Test Attachment Body')
            ),
            new Contentversion(
                Title = 'DEF.pdf',
                PathOnClient = 'test1',
                VersionData = EncodingUtil.base64Decode('Unit Test Attachment Body1')
            )
        };

        insert cvs;

        List<ContentDocument> cds = [SELECT Id from ContentDocument];

        List<ContentDocumentLink> cdls = new List<ContentDocumentLink> {
            new ContentDocumentLink(
                LinkedEntityId = testCase.Id,
                ContentDocumentId = cds[0].Id,
                ShareType = 'I'
            ),
            new ContentDocumentLink(
                LinkedEntityId = testCase.Id,
                ContentDocumentId = cds[1].Id,
                ShareType = 'I'
            )
        };

        insert cdls;

        Test.startTest();
        List<PJN_CaseFilesPreviewLightningUtil.FileOption> options = PJN_CaseFilesPreviewLightningUtil.getFileOptions(testCase.Id);
        Test.stopTest();

        System.assertEquals(3, options.size());
    }
}