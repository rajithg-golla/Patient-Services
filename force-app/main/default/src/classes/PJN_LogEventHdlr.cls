/**
 * @author      Mavens
 * @group       Log
 * @description publish log event
 */
public inherited sharing class PJN_LogEventHdlr {
    /**
     * publish log event
     * @param   String      source
     * @param   String      message
     * @param   Object      thisException
     * @param   SObject      thisSObject
     * @returns  Database.SaveResult
     */
    public static Database.SaveResult publishLogEvent(String source, String message, Object thisException, SObject thisSObject) {
        String exceptionType;
        String exceptionJson;

        if (thisException instanceof Database.SaveResult) {
            exceptionType = 'Database.SaveResult';
            exceptionJson = JSON.serializePretty(thisException, true);
        } else if (thisException instanceof Database.UpsertResult) {
            exceptionType = 'Database.UpsertResult';
            exceptionJson = JSON.serializePretty(thisException, true);
        } else {
            exceptionType = 'Exception';
            exceptionJson = ((Exception)thisException).getStackTraceString();
        }

        return EventBus.publish(
            new PJN_Log_Event__e(
                PJN_Source__c = source,
                PJN_Message__c = message,
                PJN_Exception_Type__c = exceptionType,
                PJN_Exception_JSON__c = exceptionJson,
                PJN_SObject_Type__c = thisSObject.getSObjectType().getDescribe().getName(),
                PJN_SObject_JSON__c = JSON.serializePretty(thisSObject, true)
            )
        );
    }
}