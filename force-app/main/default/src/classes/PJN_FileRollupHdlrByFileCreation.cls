/**
 * @author Mavens
 * @date Feb 2019
 * @description When a ContentDocumentLink is created, check if:
 *   - Linked entity is an EmailMessage. If so, create a link to the Case as well.
 *   - Linked entity is another entity defined in PJN_File_Rollup_Setting__mdt custom metadata type.
 *      If so, and that entity has a parent defined, create a link to the parent as well.
 * @group Files
 */
public with sharing class PJN_FileRollupHdlrByFileCreation implements PJN_TriggerDispatcher.HandlerInterface {

    /**
     * @description ordered fileSettings in a map to be able to retrieve the setting via sObject API name
     */
    private static Map<String, PJN_File_Rollup_Setting__mdt> fileSettings = PJN_FileRollupSetting.fileSettingsByObjectType;

    public void handle() {

        Set<Id> emailMessageIds = new Set<Id>();
        Map<String, Map<Id, List<Id>>> docLinksByRecordIdMapByObjectType = new Map<String, Map<Id, List<Id>>>();

        for (ContentDocumentLink docLink : (List<ContentDocumentLink>) Trigger.new){
            Id entityId = docLink.LinkedEntityId;
            String entityName = entityId.getSObjectType().getDescribe().getName();

            if (entityId.getSObjectType() == (new EmailMessage()).getSObjectType()) {
                emailMessageIds.add(entityId);

            } else if (fileSettings.containsKey(entityName)) {
                if (!docLinksByRecordIdMapByObjectType.containsKey(entityName)) {
                    docLinksByRecordIdMapByObjectType.put(
                        entityName, new Map<Id, List<Id>> {entityId => new List<Id>()}
                    );
                } else if (!docLinksByRecordIdMapByObjectType.get(entityName).containsKey(entityId)) {
                    docLinksByRecordIdMapByObjectType.get(entityName).put(
                        entityId, new List<Id>()
                    );
                }
                docLinksByRecordIdMapByObjectType.get(entityName).get(entityId).add(docLink.ContentDocumentId);
            }
        }
        new PJN_FilesHdlr().processEmailMessages(emailMessageIds);
        new PJN_FilesHdlr().processFiles(docLinksByRecordIdMapByObjectType);
    }
}