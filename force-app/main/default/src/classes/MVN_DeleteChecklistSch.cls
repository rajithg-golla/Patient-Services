/**
 * @author      Mavens
 * @group       TransformDocument
 * @description Schedule job to delete all Checklist Items created through our
 *              Transform Document functionality in the system
 */
public with sharing class MVN_DeleteChecklistSch implements Schedulable {

    /**
     * Schedule execute method which deletes:
     *  CheckList Items
     *  Content Document links related to previous records
     * @param SC    Schedule context
     */
    public void execute (SchedulableContext SC) {
        deleteDocCheckListItemsAndContentDocLinks();
    }

    /**
     * Delete checklists and content document links related to the checklists
     */
    @TestVisible
    private static void deleteDocCheckListItemsAndContentDocLinks() {
        List<DocumentChecklistItem> checklistItems = getChecklistItems();
        Set<Id> linkedEntityIds = new Set<Id>();
        for (DocumentChecklistItem checklistItem : checklistItems) {
            linkedEntityIds.add(checklistItem.Id);
        }
        deleteContentDocumentLinks(linkedEntityIds);
        delete checklistItems;
    }

    /**
     * Get all checklist Items created using Transform Document MVN logic
     * @return  `List<DocumentChecklistItem>`
     */
    private static List<DocumentChecklistItem> getChecklistItems() {
        return [
            SELECT
                Id
            FROM
                DocumentChecklistItem
            WHERE
                MVN_Document_Id__c != null
        ];
    }

    /**
     * Delete all Content Document Links related to Checklist Items
     * @param linkedEntityIds   List of checklist item ids
     */
    private static void deleteContentDocumentLinks(Set<Id> linkedEntityIds) {
        delete [
            SELECT
                Id
            FROM
                ContentDocumentLink
            WHERE
                LinkedEntityId = :linkedEntityIds
        ];
    }
}