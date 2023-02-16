/**
 * @author Mavens
 * @date Feb 2019
 * @description handle Title pre-set if it has not manually been set
 * @group Files
 */
public with sharing class PJN_ContentNoteTitleOnInsertHdlr implements PJN_TriggerDispatcher.HandlerInterface {
    /**
     * @description default titles that will get changed
     */
    private static final String DEFAULTTITLE = 'Untitled Note';

    /**
     * @description handle before update trigger
     */
    public void handle() {
        Map<Id, ContentDocumentLink> contentDocLinkByContentDocIdMap = new Map<Id, ContentDocumentLink>();
        for (ContentDocumentLink docLink : (List<ContentDocumentLink>) Trigger.new){
            if (docLink.LinkedEntityId != UserInfo.getUserId()) {
                contentDocLinkByContentDocIdMap.put(docLink.ContentDocumentId, docLink);
            }
        }
        Map<Id, ContentDocument> contentDocMap = new Map<Id, ContentDocument> ([
            SELECT
                FileType,
                Title
            FROM
                ContentDocument
            WHERE
                Id IN :contentDocLinkByContentDocIdMap.keySet()
        ]);

        List<ContentDocument> contentDocToUpdate = new List<ContentDocument>();
        Map<Id, Id> contentDocIdBylinkedCaseIdMap = new Map<Id, Id>();
        for (ContentDocument contentDoc : contentDocMap.values()) {
            if(contentDoc.FileType == 'SNOTE' && contentDoc.Title == DEFAULTTITLE) {
                Id entityId = contentDocLinkByContentDocIdMap.get(contentDoc.Id).LinkedEntityId;
                if(entityId.getSObjectType() == (new Case().getSObjectType())) {
                    contentDocIdBylinkedCaseIdMap.put(entityId, contentDoc.Id);
                } else {
                    contentDoc.Title = Label.PJN_Default_Note_Title;
                    contentDocToUpdate.add(contentDoc);
                }
            }
        }
        if (!contentDocIdBylinkedCaseIdMap.isEmpty()) {
            for (Case thisLinkedCase : [SELECT Id, Subject, ParentId FROM Case WHERE Id IN :contentDocLinkByContentDocIdMap.keySet()]) {
                Id contentDocId = contentDocIdBylinkedCaseIdMap.get(thisLinkedCase.Id);
                ContentDocument contentDoc = contentDocMap.get(contentDocId);
                // Activity Case
                if(thisLinkedCase.ParentId != null) {
                    contentDoc.Title = String.format(
                                Label.PJN_Default_Activity_Note_Title,
                                new List<String> {
                                    thisLinkedCase.Subject
                                }
                    );
                // Care Plan
                } else {
                    contentDoc.Title = Label.PJN_Default_Care_Plan_Note_Title;
                }
                contentDocToUpdate.add(contentDoc);
            }
        }
        update contentDocToUpdate;
    }
}