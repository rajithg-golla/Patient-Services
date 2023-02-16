/**
 *
 * @author
 * @since
 */
@IsTest
private class MVN_DeleteChecklistSchTest {

    private static final String CRON_EXP = '0 0 0 3 9 ? ' + System.now().addYears(1).year();

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
            Name = String.format(
                Label.MVN_Transform_Document_Checklist_Name,
                new List<String> {
                    request.CaseNumber,
                    file.Title,
                    '0'
                }
            ),
            ParentRecordId = request.Id,
            MVN_Document_Id__c = file.ContentDocumentId,
            Status = Label.MVN_Transform_Document_Checklist_Status
        );
    }

    @IsTest
    static void testIfSchedulesCorrectly() {
        Test.startTest();
        // Schedule the test job
        String jobId = System.schedule('MVN_DeleteChecklistSch', CRON_EXP, new MVN_DeleteChecklistSch());
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        // Verify the expressions are the same System.assertEquals(CRON_EXP, ct.CronExpression);
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        // Verify the next time the job will run
        System.assertEquals(System.now().addYears(1).year() + '-09-03 00:00:00', String.valueOf(ct.NextFireTime));
        Test.stopTest();
    }

    @IsTest
    static void testIfDeleteCorrectly() {
        Test.startTest();
        MVN_DeleteChecklistSch.deleteDocCheckListItemsAndContentDocLinks();
        Test.stopTest();
        List<DocumentChecklistItem> checklistItems = [SELECT Id FROM DocumentChecklistItem LIMIT 2];
        System.assert(checklistItems.isEmpty(), 'Checklist Items were NOT deleted correctly.');
    }
}