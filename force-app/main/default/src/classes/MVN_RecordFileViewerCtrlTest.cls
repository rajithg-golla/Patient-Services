@IsTest
public with sharing class MVN_RecordFileViewerCtrlTest {
    private static final String PERMISSION_SET_NAME = 'MVN_RBM_Permissions';

    @TestSetup
    static void makeData() {
        Account patient = new Account(
            LastName = 'Test',
            RecordTypeId = SObjectType.Account
                .getRecordTypeInfosByDeveloperName()
                .get('PJN_Patient')
                .getRecordTypeId()
        );

        insert patient;

        Case carePlan = new Case(
            AccountId = patient.Id,
            RecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId()
        );

        insert carePlan;

        List<ContentVersion> contentVersions = createContentVersion();

        createContentDocumentLink(contentVersions, carePlan.Id);

        Test.startTest();
        assignPermissionSetToUser();
        Test.stopTest();
    }

    @IsTest
    static void getRecordFilesTest() {
        Case carePlan = [SELECT Id FROM Case WHERE RecordType.DeveloperName = 'CarePlan'];
        MVN_RecordFileViewerCtrl.ViewerWrapper viewerWrapper = new MVN_RecordFileViewerCtrl.ViewerWrapper();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            viewerWrapper = MVN_RecordFileViewerCtrl.getRecordFiles(carePlan.Id);
        }

        System.assertEquals(true, viewerWrapper.hasUserPermissions);
        System.assertEquals(2, viewerWrapper.recordFileWrappers.size());
    }

    private static List<ContentVersion> createContentVersion() {
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        contentVersions.add(new ContentVersion(
            Description  = 'test description',
            PathOnClient ='test_file_1.txt',
            Title = 'test file 1 ' + DateTime.now(),
            VersionData = Blob.valueOf('test file body'),
            MVN_Document_Type__c = 'SummaryOfBenefits'
        ));

        contentVersions.add(new ContentVersion(
            Description  = 'test description',
            PathOnClient ='test_file_2.txt',
            Title = 'test file 2 ' + DateTime.now(),
            VersionData = Blob.valueOf('test file body'),
            MVN_Document_Type__c = 'StartForm'
        ));

        insert contentVersions;

        return contentVersions;
    }

    private static void createContentDocumentLink(List<ContentVersion> contentVersions, Id recordId) {
        Map<Id, ContentVersion> contentVersionById = new Map<Id, ContentVersion>(contentVersions);
        contentVersions = getContentVersionsWithContentDocument(contentVersionById.keySet());
        List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();
        for (ContentVersion contentVersion : contentVersions) {
            documentLinks.add(new ContentDocumentLink(
                ContentDocumentId = contentVersion.ContentDocumentId,
                LinkedEntityId = recordId,
                ShareType = 'I',
                Visibility = 'AllUsers'
            ));
        }

        insert documentLinks;
    }

    private static List<ContentVersion> getContentVersionsWithContentDocument(Set<Id> contentVersionIds) {
        return [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionIds];
    }

    private static void assignPermissionSetToUser() {
        Id permissionSetId = getPermissionSetId();
        Boolean hasUserPermissionSet =
            ![
                SELECT Id
                FROM PermissionSetAssignment
                WHERE AssigneeId = :UserInfo.getUserId()
                    AND PermissionSetId = :permissionSetId
            ].isEmpty();

        if (!hasUserPermissionSet) {
            System.runAs(new User(Id = UserInfo.getUserId())) {
                insert new PermissionSetAssignment(
                    AssigneeId = UserInfo.getUserId(),
                    PermissionSetId = permissionSetId
                );
            }
        }
    }

    private static Id getPermissionSetId() {
        return [SELECT Id FROM PermissionSet WHERE Name = :PERMISSION_SET_NAME LIMIT 1].Id;
    }
}