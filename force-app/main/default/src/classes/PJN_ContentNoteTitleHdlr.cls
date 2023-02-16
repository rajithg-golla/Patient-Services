/**
 * @author Mavens
 * @date Feb 2019
 * @description handle Title pre-set if it has not manually been set
 * @group Files
 */
public with sharing class PJN_ContentNoteTitleHdlr implements PJN_TriggerDispatcher.HandlerInterface {
    /**
     * @description default titles that will get changed
     */
    private static final String DEFAULTTITLE = 'Untitled Note';

    /**
     * @description handle before update trigger
     */
    public void handle() {
        Map<Id, String> contentNotesToSetTitle = new Map<Id, String>();
        for(ContentDocument thisContentNote : (List<ContentDocument>) trigger.new) {
            if(thisContentNote.FileType == 'SNOTE' && thisContentNote.Title == DEFAULTTITLE) {
                contentNotesToSetTitle.put(thisContentNote.Id, thisContentNote.Title);
            }
        }
        Set<Id> contentNoteIds = contentNotesToSetTitle.keySet();
        if(!contentNoteIds.isEmpty()) {
            Map<Id, Id> linkedCaseIds = new Map<Id, Id>();
            for(ContentDocumentLink thisContentNoteLink : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :contentNoteIds AND LinkedEntityId != :UserInfo.getUserId()]) {
                if(thisContentNoteLink.LinkedEntityId.getSObjectType() == (new Case().getSObjectType())) {
                    linkedCaseIds.put(thisContentNoteLink.LinkedEntityId, thisContentNoteLink.ContentDocumentId);
                } else {
                    contentNotesToSetTitle.put(thisContentNoteLink.ContentDocumentId, Label.PJN_Default_Note_Title);
                }
            }
            if(!linkedCaseIds.isEmpty()) {
                for (Case thisLinkedCase : [SELECT Id, Subject, ParentId FROM Case WHERE Id IN :linkedCaseIds.keySet()]) {
                    // Activity Case
                    if(thisLinkedCase.ParentId != null) {
                        contentNotesToSetTitle.put(
                            linkedCaseIds.get(thisLinkedCase.Id),
                            String.format(
                                Label.PJN_Default_Activity_Note_Title,
                                new List<String> {
                                    thisLinkedCase.Subject
                                }
                            )
                        );
                    // Care Plan
                    } else {
                        contentNotesToSetTitle.put(linkedCaseIds.get(thisLinkedCase.Id), Label.PJN_Default_Care_Plan_Note_Title);
                    }
                }
            }
            for(ContentDocument thisContentNote : (List<ContentDocument>) trigger.new) {
                if(contentNotesToSetTitle.containsKey(thisContentNote.Id)) {
                    thisContentNote.Title = contentNotesToSetTitle.get(thisContentNote.Id);
                }
            }
        }
    }
}