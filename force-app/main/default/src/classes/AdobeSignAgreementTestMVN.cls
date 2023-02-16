@isTest
public class AdobeSignAgreementTestMVN {
    
    @isTest
    private static void itShouldInitializeAnAgreement() {
        Test.startTest();
        AdobeSignAgreementMVN agreement = new AdobeSignAgreementMVN('name', 'sigType', 'state', 'externalId')
            .addSigners(new List<String>{'test@email.com'})
            .addPostSignOption('https://www.redirectUrl.com', 3)
            .addEmailOption('ALL', 'ALL', 'ALL')
            .addMergeField('fieldName', 'defaultValue');

        agreement.addLibraryFileInfo('documentId');
        Test.stopTest();

        System.assertEquals('name', agreement.name);
        System.assertEquals('sigType', agreement.signatureType);
        System.assertEquals('state', agreement.state);
        System.assertEquals('externalId', agreement.externalId.id);
        System.assertEquals('test@email.com', agreement.participantSetsInfo[0].memberInfos[0].email);
        System.assertEquals('https://www.redirectUrl.com', agreement.postSignOption.redirectUrl);
        System.assertEquals(3, agreement.postSignOption.redirectDelay);
        System.assertEquals('documentId', agreement.fileInfos[0].libraryDocumentId);
        System.assertEquals('ALL', agreement.emailOption.sendOptions.initEmails);
        System.assertEquals('ALL', agreement.emailOption.sendOptions.completionEmails);
        System.assertEquals('ALL', agreement.emailOption.sendOptions.inFlightEmails);
        System.assertEquals('fieldName', agreement.mergeFieldInfo[0].fieldName);
        System.assertEquals('defaultValue', agreement.mergeFieldInfo[0].defaultValue);
    }
}