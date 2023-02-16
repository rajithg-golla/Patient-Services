/**
 * @author      Mavens
 * @group       TransformDocument
 * @description Controller for the Transform Document functionality.
 *              * Query files associated to a given record id
 *              * For a selected file, generates a DocumentChecklistItem records
 *                  linking them to the file and case.
 *              * With those generated record ids build a URL to call standard
 *                  Salsforce screen and functionality "Transform Document"
 */
public with sharing class MVN_TransformDocumentCtrl {

    /**
     * Case to parent the file transformed
     */
    private static Case thisCase;

    /**
     * File to transform and relate to Case parent
     */
    private static ContentVersion thisDocument;

    /**
     * Get All files related to the case
     * @param recordId  Case record Id
     * @return  `List<ContentVersion>`
     * @exception
     */
    @AuraEnabled
    public static List<ContentVersion> getFilesRelated(Id recordId) {
        if (recordId == null) {
            return null;
        }
        try {
            Set<Id> contentDocumentIds = getContentDocumentIds(recordId);
            return [
                SELECT
                    Id,
                    Title,
                    FileType,
                    Description,
                    ContentDocumentId
                FROM
                    ContentVersion
                WHERE
                    ContentDocumentId IN :contentDocumentIds
                AND
                    IsLatest = true
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Get all content document Ids related to the case record id provided
     * @param recordId  Case record id
     * @return  `Set<Id>`
     */
    private static Set<Id> getContentDocumentIds(Id recordId) {
        Set<Id> contentDocumentIds = new Set<Id>();
        if (recordId == null) {
            return contentDocumentIds;
        }
        for (ContentDocumentLink cdl : [
            SELECT
                Id,
                ContentDocumentId
            FROM
                ContentDocumentLink
            WHERE
                LinkedEntityId = :recordId
        ]) {
            contentDocumentIds.add(cdl.ContentDocumentId);
        }
        return contentDocumentIds;
    }

    /**
     * Create DocumentChecklistItem records for the Case and File provided.
     * DocumentChecklistItem records are related to the Case and File to be unique during the execution.
     * The DocumentChecklistItem record will be removed in a trigger to avoid unnecessary data.
     * However the extra field and the relation to the case is necessary in case 2 or
     * more users are working at the same time.
     * @param caseId    Case Record Id
     * @param document  File to be transformed
     * @return  `Id`
     * @exception
     */
    @AuraEnabled
    public static Id createDocumentData(Id caseId, ContentVersion document){
        thisDocument = document;
        try {
            thisCase = getCase(caseId);
            DocumentChecklistItem docCheckListItem = getChecklistItems();
            return docCheckListItem.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Get Case from case id provided
     * @param caseId    Case Record Id
     * @return  `Case`
     */
    private static Case getCase(Id caseId) {
        return [
            SELECT
                Id,
                CaseNumber
            FROM
                Case
            WHERE
                Id = :caseId
        ];
    }

    /**
     * Get Checklist Item from database for the case and file provided
     * This checklist cannot have any file already related.
     * The checklist will be created if the criteria above is not matched
     * @return  `DocumentChecklistItem`
     */
    private static DocumentChecklistItem getChecklistItems() {
        List<DocumentChecklistItem> dclis = [
            SELECT
                Id,
                Name,
                ParentRecordId,
                Status
            FROM
                DocumentChecklistItem
            WHERE
                ParentRecordId = :thisCase.Id
            AND
                MVN_Document_Id__c = :thisDocument.ContentDocumentId
        ];
        if (!dclis.isEmpty()) {
            return dclis[0];
        }
        return createChecklistItems();
    }

    /**
     * Build and create checklist item if need it
     * @return  `DocumentChecklistItem`
     */
    private static DocumentChecklistItem createChecklistItems() {
        DocumentChecklistItem docCheckListItem = new DocumentChecklistItem(
            Name = String.format(
                Label.MVN_Transform_Document_Checklist_Name,
                new List<String> {
                    thisCase.CaseNumber,
                    thisDocument.Title
                }
            ),
            ParentRecordId = thisCase.Id,
            MVN_Document_Id__c = thisDocument.ContentDocumentId,
            Status = Label.MVN_Transform_Document_Checklist_Status
        );
        insert docCheckListItem;
        return docCheckListItem;
    }
}