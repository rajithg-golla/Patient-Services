/**
 * @author      Mavens
 * @group       Notes
 * @description Unit tests for CreateNoteFromTaskHdlrMVN
 */
@isTest public with sharing class CreateNoteFromTaskHdlrTestMVN {
    @isTest private static void insertCompletedTasksWithComments() {
        Account expectedAccount = new Account(
            LastName = 'Test Account',
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Program_Participant_MVN').getRecordTypeId()
        );
        insert expectedAccount;

        Case expectedCarePlan = new Case(
            AccountId = expectedAccount.Id,
            Subject = 'Test Careplan'
        );
        insert expectedCarePlan;

        List<Task> expectedTasks = new List<Task>();

        String subject = 'Test Subject';
        String description = 'Test Description';
        for (Integer i=0; i<30; i++) {
            expectedTasks.add(
                new Task(
                    WhatId = expectedCarePlan.Id,
                    Subject = subject,
                    Description = description,
                    Status = 'Completed'
                )
            );
        }

        Test.startTest();
            insert expectedTasks;
        Test.stopTest();


        System.assertNotEquals(null, expectedTasks[0].Id);
        List<ContentDocumentLink> actualNoteToCarePlanLinks = [SELECT Id, ContentDocumentId, LinkedEntityId, ShareType FROM ContentDocumentLink WHERE LinkedEntityId = :expectedCarePlan.Id];
        System.assertEquals('I', actualNoteToCarePlanLinks[0].ShareType);
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink link : actualNoteToCarePlanLinks) {
            contentDocumentIds.add(link.ContentDocumentId);
        }
        List<ContentNote> actualNotes = [SELECT Id, Title, Content FROM ContentNote WHERE Id IN :contentDocumentIds];
        System.assertEquals(subject, actualNotes[0].Title);
        System.assertEquals(Blob.valueOf('<p>' + description.replaceAll('\n','</p><p>') + '</p>'), actualNotes[0].Content);
    }

    @isTest private static void updateTaskWithCommentsToComplete() {
        Account expectedAccount = new Account(
            LastName = 'Test Account',
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Program_Participant_MVN').getRecordTypeId()
        );
        insert expectedAccount;

        Case expectedCarePlan = new Case(
            AccountId = expectedAccount.Id,
            Subject = 'Test Careplan'
        );
        insert expectedCarePlan;

        Task expectedTask = new Task(
            WhatId = expectedCarePlan.Id,
            Subject = 'Test Subject',
            Description = 'Test Description',
            Status = 'In Progress'
        );
        insert expectedTask;
        System.assertNotEquals(null, expectedTask.Id);
        System.assertEquals(0, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :expectedCarePlan.Id]);

        Test.startTest();
            expectedTask.Status = 'Completed';
            update expectedTask;
        Test.stopTest();

        ContentDocumentLink actualNoteToCarePlanLink = [SELECT Id, ContentDocumentId, LinkedEntityId, ShareType FROM ContentDocumentLink WHERE LinkedEntityId = :expectedCarePlan.Id];
        System.assertEquals('I', actualNoteToCarePlanLink.ShareType);
        ContentNote actualNote = [SELECT Id, Title, Content FROM ContentNote WHERE Id = :actualNoteToCarePlanLink.ContentDocumentId];
        System.assertEquals(expectedTask.Subject, actualNote.Title);
        System.assertEquals(Blob.valueOf('<p>' + expectedTask.Description.replaceAll('\n','</p><p>') + '</p>'), actualNote.Content);
    }

    /*
     * Test that the error message string method returns expected string
     * Uses insert of contact info without account to produce error
     */
    @isTest
    private static void itShouldGetExceptionMessages() {
        Database.SaveResult result = Database.insert(new PJN_Contact_Information__c(), false);

        CreateNoteFromTaskHdlrMVN handler = new CreateNoteFromTaskHdlrMVN();
        Test.startTest();
        String message = handler.getExceptionMessage(result.getErrors());
        Test.stopTest();

        System.assertEquals(message, 'Something went wrong. Please contact your system administrator. Required fields are missing: [PJN_Account__c]');
    }
}