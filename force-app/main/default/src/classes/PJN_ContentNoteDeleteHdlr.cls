/**
 * @author Mavens
 * @date Feb 2019
 * @description handle note deletes only possible with the custom permission 'PJN_Delete_Notes' assigned
 * @group Files
 */
public with sharing class PJN_ContentNoteDeleteHdlr implements PJN_TriggerDispatcher.HandlerInterface {
    /**
     * @description handle before delete trigger
     */
    public void handle() {
        Boolean userCanDelete = FeatureManagement.checkPermission('PJN_Delete_Notes');
        if (userCanDelete) {
            return;
        }
        for(ContentDocument thisContentNote : (List<ContentDocument>) trigger.old) {
            if(thisContentNote.FileType == 'SNOTE') {
                thisContentNote.addError('Not allowed to delete the note.');
            }
        }
    }
}