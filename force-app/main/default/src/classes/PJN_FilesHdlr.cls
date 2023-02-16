/**
 * @author Mavens
 * @date Feb 2019
 * @description Manages the roll up of files to parent entities.
 *   - processEmailMessages: Method to create a link to the Case when an email-to-case is received with attchaments, since files
 *      are only linked to the EmailMessage object
 *   - processFiles: For those objects defined in PJN_File_Rollup_Setting__mdt custom metadata object,
 *      it links any new file created to the parent record, as per file rollup setting definition.
 * @group Files
 */
public without sharing class PJN_FilesHdlr {

    /**
     * @description ordered fileSettings in a map to be able to retrieve the setting via sObject API name
     */
    private static Map<String, PJN_File_Rollup_Setting__mdt> fileSettings = PJN_FileRollupSetting.fileSettingsByObjectType;

    /**
     * Retreive file information attached to the EmailMessage that has been created by Email-To-Case.
     * If the email is an inbound email and has attachments, link each of those files to the
     * Case where the email is stored.
     * @param  emailMessageIds set of EmailMessage ids to process
     */
    public void processEmailMessages(Set<Id> emailMessageIds) {
        List<EmailMessage> emailMessageList = [
            SELECT
                Incoming,
                ContentDocumentIds,
                ParentId
            FROM
                EmailMessage
            WHERE
                Id IN :emailMessageIds
        ];

        List<ContentDocumentLink> linkList = new List<ContentDocumentLink>();
        for (EmailMessage email : emailMessageList) {
            if (email.Incoming && !email.ContentDocumentIds.isEmpty()) {
                for (Id docId : email.ContentDocumentIds) {
                    linkList.add(
                        new ContentDocumentLink(
                            ContentDocumentId = docId,
                            LinkedEntityId = email.ParentId,
                            ShareType = 'I'
                        )
                    );
                }
            }
        }
        if(!linkList.isEmpty()) {
            List<Database.SaveResult> linkListSaveResults = Database.insert(linkList, false);
            for(Integer index = 0; index < linkListSaveResults.size(); index++) {
                Database.SaveResult thisLinkListSaveResult = linkListSaveResults.get(index);
                ContentDocumentLink thisLink = linkList.get(index);
                if(!thisLinkListSaveResult.isSuccess()) {
                    PJN_LogEventHdlr.publishLogEvent(
                        PJN_FilesHdlr.class.getName(),
                        'Unsuccessful link insert for *** ' + thisLink,
                        thisLinkListSaveResult,
                        thisLink
                    );
                }
            }
        }
    }

    /**
     * For each new file generated, if the object type containig that file is defined in the File Settings
     * Custom Metadata object, then roll up that file to the parent record, creating a new link to the
     * existing file.
     * @param  docLinksByRecordIdMapByObjectType mapping that contains the list of document links by record id
     *                                          and by object type name to process
     */
    public void processFiles(Map<String, Map<Id, List<Id>>> docLinksByRecordIdMapByObjectType) {
        for (String objectType : docLinksByRecordIdMapByObjectType.keySet()) {

            Map<Id, List<Id>> docLinksByRecordIdMap = docLinksByRecordIdMapByObjectType.get(objectType);
            Set<Id> docLinkIds = docLinksByRecordIdMap.keySet();
            PJN_File_Rollup_Setting__mdt fileSetting = fileSettings.get(objectType);
            List<ContentDocumentLink> linkList = new List<ContentDocumentLink>();

            String query = 'SELECT Id, ' + fileSetting.PJN_Parent_Lookup_Field_API_Name__c +
                            ' FROM ' + objectType +
                            ' WHERE Id IN: docLinkIds';
            for(SObject thisObject : Database.query(query)) {
                Id parentId = (Id)thisObject.get(fileSetting.PJN_Parent_Lookup_Field_API_Name__c);
                if (parentId != null) {
                    for (Id docId : docLinksByRecordIdMap.get((Id)thisObject.get('Id'))) {
                        linkList.add(
                            new ContentDocumentLink(
                                ContentDocumentId = docId,
                                LinkedEntityId = parentId,
                                ShareType = 'I'
                            )
                        );
                    }
                }
            }
            if(!linkList.isEmpty()) {
                List<Database.SaveResult> linkListSaveResults = Database.insert(linkList, false);
                for(Integer index = 0; index < linkListSaveResults.size(); index++) {
                    Database.SaveResult thisLinkListSaveResult = linkListSaveResults.get(index);
                    ContentDocumentLink thisLink = linkList.get(index);
                    if(!thisLinkListSaveResult.isSuccess() && thisLinkListSaveResult.getErrors().get(0).getMessage().startsWith('Document with ID: ' + thisLink.ContentDocumentId + ' is already linked with the entity with ID')) {
                        PJN_LogEventHdlr.publishLogEvent(
                            PJN_FilesHdlr.class.getName(),
                            'Unsuccessful link insert for *** ' + thisLink,
                            thisLinkListSaveResult,
                            thisLink
                        );
                    }
                }
            }
        }
    }

    /**
     * Create new links to the same file from a child case to its parent record.
     * @param  caseMap map of child cases
     */
    public void rollupFilesToParent(Map<Id, Case> caseMap) {
        String parentIdFieldName = fileSettings.get('Case').PJN_Parent_Lookup_Field_API_Name__c;
        Set<Id> caseIds = caseMap.keySet();

        Map<Id, Id> parentCaseIdByChildCaseId = new Map<Id, Id>();
        for (Case currentCase : caseMap.values()) {
            parentCaseIdByChildCaseId.put(currentCase.Id, (Id) currentCase.get(parentIdFieldName));
        }
        List<ContentDocumentLink> docLinkList = [
            SELECT
                ContentDocumentId,
                LinkedEntityId
            FROM
                ContentDocumentLink
            WHERE
                LinkedEntityId IN :caseIds
        ];
        List<ContentDocumentLink> contentDocLinkToCreate = new List<ContentDocumentLink>();
        for (ContentDocumentLink docLink : docLinkList) {
            contentDocLinkToCreate.add(
                new ContentDocumentLink(
                    ContentDocumentId = docLink.ContentDocumentId,
                    LinkedEntityId = parentCaseIdByChildCaseId.get(docLink.LinkedEntityId),
                    ShareType = 'I'
                )
            );
        }
        if(!contentDocLinkToCreate.isEmpty()) {
            List<Database.SaveResult> contentDocLinkToCreateSaveResults = Database.insert(contentDocLinkToCreate, false);
            for(Integer index = 0; index < contentDocLinkToCreateSaveResults.size(); index++) {
                Database.SaveResult thisContentDocLinkToCreateSaveResult = contentDocLinkToCreateSaveResults.get(index);
                ContentDocumentLink thisContentDocLinkToCreate = contentDocLinkToCreate.get(index);
                if(!thisContentDocLinkToCreateSaveResult.isSuccess()) {
                    PJN_LogEventHdlr.publishLogEvent(
                        PJN_FilesHdlr.class.getName(),
                        'Unsuccessful contentDocLinkToCreate insert for *** ' + thisContentDocLinkToCreate,
                        thisContentDocLinkToCreateSaveResult,
                        thisContentDocLinkToCreate
                    );
                }
            }
        }
    }
}