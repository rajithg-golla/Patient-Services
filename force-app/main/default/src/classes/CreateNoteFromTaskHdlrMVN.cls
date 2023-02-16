/**
 * @author      Mavens
 * @group       Notes
 * @description create note from just completed task with comments and links to the original task WhatId and WhoId of the task
 */
public with sharing class CreateNoteFromTaskHdlrMVN implements PJN_TriggerDispatcher.HandlerInterface {
    /**
     * list of notes to insert
     */
    private List<ContentNote> notes = new List<ContentNote>();

    /**
     * list of tasks that will create a note
     */
    private List<Task> tasks = new List<Task>();

    /**
     * list of links to insert
     */
    private List<ContentDocumentLink> links = new List<ContentDocumentLink>();

    /**
     * map of note ids to task ids (for exception handling)
     */
    private Map<Id, Id> notesToTaskIds = new Map<Id, Id>();

    /**
     * map of task ids to exception messages (for exception handling)
     */
    Map<Id, String> exceptions = new Map<Id, String>();

    /**
     * handle before insert trigger context
     */
    public void handle() {
        List<Task> completedTasksToCreateNotesFrom = this.getCompletedTasksToCreateNotesFrom();
        Set<Id> whatIds = new Set<Id>();

        if(!completedTasksToCreateNotesFrom.isEmpty()) {
            for(Task thisTask : completedTasksToCreateNotesFrom) {
                String commentsForNote = '<p>' + thisTask.Description.replaceAll('\n','</p><p>') + '</p>';
                this.notes.add(
                    new ContentNote(
                        Title = thisTask.Subject,
                        Content = Blob.valueOf(commentsForNote),
                        SharingPrivacy = 'N'
                    )
                );
                this.tasks.add(thisTask);
            }
        }

        if(!this.notes.isEmpty()) {
            List<Database.SaveResult> insertNotesSaveResults = Database.insert(this.notes, false);
            for(Integer index = 0; index < this.notes.size(); index++) {
                Database.SaveResult insertNoteSaveResult = insertNotesSaveResults.get(index);
                Task thisTask = this.tasks.get(index);
                if(insertNoteSaveResult.isSuccess()) {
                    Id noteId = insertNoteSaveResult.getId();
                    this.notesToTaskIds.put(
                        noteId,
                        thisTask.Id
                    );
                    this.addNoteLinks(noteId, thisTask);
                } else {
                    this.exceptions.put(thisTask.Id, this.getExceptionMessage(insertNoteSaveResult.getErrors()));
                }
            }
        }

        if(!this.links.isEmpty()) {
            List<Database.SaveResult> insertLinksSaveResults = Database.insert(this.links, false);
            for(Integer index = 0; index < this.links.size(); index++) {
                Database.SaveResult insertLinkSaveResult = insertLinksSaveResults.get(index);
                if(!insertLinkSaveResult.isSuccess()) {
                    this.exceptions.put(notesToTaskIds.get(this.links.get(index).ContentDocumentId), this.getExceptionMessage(insertLinkSaveResult.getErrors()));
                }
            }
        }

        if(!this.exceptions.isEmpty()) {
            for(Task thisTask : (List<Task>) trigger.new) {
                if(this.exceptions.containsKey(thisTask.Id)) {
                    thisTask.addError(this.exceptions.get(thisTask.Id));
                }
            }
        }
    }

    /**
     * get completed tasks that will create a note
     * @return  List<Task>
     */
    private List<Task> getCompletedTasksToCreateNotesFrom() {
        List<Task> completedTasksToCreateNotesFrom = new List<Task>();
        for(Task thisTask : (List<Task>) trigger.new) {
            Boolean updatedAndComplete = this.isStatusUpdatedAndCompleted(thisTask.Id);
            Boolean parentTypeRequiresNoteCreation = thisTask.WhatId != null && thisTask.WhatId.getSObjectType() == Case.getSobjectType();
            if (updatedAndComplete && parentTypeRequiresNoteCreation) {
                completedTasksToCreateNotesFrom.add(thisTask);
            }
        }
        return completedTasksToCreateNotesFrom;
    }

    /**
     * add links to the successfully created note
     * @param   Id           noteId
     * @param   Task           thisTask
     */
    private void addNoteLinks(Id noteId, Task thisTask) {
        Set<Id> relatedRecords = new Set<Id> {thisTask.WhatId};

        for(Id relatedRecord : relatedRecords) {
            this.links.add(
                new ContentDocumentLink(
                    ContentDocumentId = noteId,
                    LinkedEntityId = relatedRecord,
                    ShareType = 'I'
                )
            );
        }
    }

    /**
     * creates exception messages from database errors thrown
     * @param   List<Database.Error>           errors
     * @return  String
     */
    @TestVisible
    private String getExceptionMessage(List<Database.Error> errors) {
        String exceptionMessage = 'Something went wrong. Please contact your system administrator.';
        for(Database.Error thisError : errors) {
            exceptionMessage += ' ' + thisError.getMessage();
        }
        return exceptionMessage;
    }

    /**
     * checks if Status has changed to completed
     * @param   Id           taskId
     * @return  true if the Status has changed and is completed and Description are filled out
     */
    private Boolean isStatusUpdatedAndCompleted(Id taskId) {
        if(Trigger.isInsert) {
            Task newTask = (Task) Trigger.newMap.get(taskId);
            if (newTask.Status == 'Completed' && newTask.Description != null) {
                return true;
            }
        } else if(Trigger.isUpdate) {
            Task oldTask = (Task) Trigger.oldMap.get(taskId);
            Task newTask = (Task) Trigger.newMap.get(taskId);
            if (oldTask.Status != newTask.Status && newTask.Status == 'Completed' && newTask.Description != null) {
                return true;
            }
        }
        return false;
    }
}