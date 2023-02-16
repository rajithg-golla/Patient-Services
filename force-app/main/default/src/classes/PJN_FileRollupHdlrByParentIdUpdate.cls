/**
 * @author Mavens
 * @date Jan 2019
 * @description Handler that calls the class containing the logic to roll up files to the parent record
 *      when the parent id field has been updated on a child case.
 */
public with sharing class PJN_FileRollupHdlrByParentIdUpdate implements PJN_TriggerDispatcher.HandlerInterface {

    /**
     * @description ordered fileSettings in a map to be able to retrieve the setting via sObject API name
     */
    private static Map<String, PJN_File_Rollup_Setting__mdt> fileSettings = PJN_FileRollupSetting.fileSettingsByObjectType;

    /**
     * Handle the trigger call
     */
    public void handle() {
        Map<Id, Case> casesToRollupFiles = new Map<Id, Case>{};
        for (Case currentCase : (List<Case>)Trigger.new) {
            if (this.isParentIdUpdated(currentCase.Id)) {
                casesToRollupFiles.put(currentCase.Id, currentCase);
            }
        }
        if (!casesToRollupFiles.isEmpty()) {
            new PJN_FilesHdlr().rollupFilesToParent(casesToRollupFiles);
        }
    }

    /**
     * Checks if the ParentId field has been updated
     * @param  caseId case id
     * @returns        true if the ParentId has changed and it is not null
     */
    private Boolean isParentIdUpdated(Id caseId) {
        Case oldCase = (Case) Trigger.oldMap.get(caseId);
        Case newCase = (Case) Trigger.newMap.get(caseId);
        String parentIdFieldName = fileSettings.get('Case').PJN_Parent_Lookup_Field_API_Name__c;
        if (oldCase.get(parentIdFieldName) != newCase.get(parentIdFieldName) &&
            newCase.get(parentIdFieldName) != null) {
            return true;
        }
        return false;
    }
}