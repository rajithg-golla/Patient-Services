/**
 * @author      Mavens
 * @description Used by quick action on the Case record to Close Case
 * @group       CaseActions
 */
public with sharing class PJN_CloseCaseActionCtrl {
    /**
    * close case
    * @param    Id      recordId
    */
    @AuraEnabled public static void closeCase(Id recordId) {
        try {
            Case thisCase = [
                SELECT
                    Status,
                    IsClosed
                FROM
                    Case
                WHERE
                    Id = :recordId
            ];
            if(thisCase.IsClosed) {
                AuraHandledException auraException = new AuraHandledException(Label.PJN_Close_Case_Error_Already_Closed_Message + ' ' + thisCase.Status);
                auraException.setMessage(
                    String.format(
                        Label.PJN_Close_Case_Error_Already_Closed_Message,
                        new List<String> {
                            thisCase.Status
                        }
                    )
                );
                throw auraException;
            }
            thisCase.Status = Label.PJN_Case_Quick_Close_Status;
            try {
                update thisCase;
            } catch (Exception e) {
                String message = e.getMessage();
                if (message.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, ')) {
                    message = message.substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION, ');
                    message = message.substringBefore(':');
                }
                AuraHandledException ex = new AuraHandledException(message);
                ex.setMessage(message);
                throw ex;
            }
        } catch(AuraHandledException ex) {
            throw PJN_AuraHandledExceptionUtil.handleAuraException(ex);
        } catch(Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex);
        }
    }
}