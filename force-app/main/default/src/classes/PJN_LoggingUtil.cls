/**
 * @author Mavens
 * @group Util
 * @description   Utility class and methods for improving and standardizing logging and error handling
 **/

public without sharing class PJN_LoggingUtil {

    /**
    * @description Inserts a PJN_Log__c entry
    * @param source An identifier to explain where the error came from, typically the class name
    * @param message The error or message to log
    * @param level Salesforce Logging level to assign to the entry
    */
    public static void logError(String source, String message, System.LoggingLevel level) {
        Integer messageLength = SObjectType.PJN_Log__c.Fields.PJN_Logged_Message__c.Length;
        Integer sourceLength = SObjectType.PJN_Log__c.Fields.PJN_Source__c.Length;

        PJN_Log__c entry = new PJN_Log__c();
        entry.PJN_Source__c = source.abbreviate(sourceLength-5);//leave 5 char for ellipses
        entry.PJN_Logged_Message__c = message.abbreviate(messageLength-5);//leave 5 char for ellipses
        entry.PJN_Logging_Level__c = level.name();
        if (Test.isRunningTest()) {
            // even if running tests, log insert should not fail
            Test.setReadOnlyApplicationMode(false);
        }
        System.debug(level,'PJN_LoggingUtil\n' + source + '\n' + message);
        try {
            insert entry;
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR,'Creating PJN_Log__c Entry FAILED');
            System.debug(e);
        }

    }

    public static void logError(String source, String message) {
        //If no logging level provided, assume it is an error
       logError(source, message, System.LoggingLevel.ERROR);
    }

    public static void logError(String source, Exception e, System.LoggingLevel level) {
        String message = getErrorString(e);
        logError(source,message,level);
    }

    public static void logError(String source, Exception e) {
        //If no logging level provided, assume it is an error
        logError(source,e,LoggingLevel.ERROR);
    }

    /**
    * @description Converts an Apex Exception to a string. Provides a string that includes both the message and stack trace,
    *               as well as the cause (parent exceptions) and their details
    * @param e The exception to turn into a string
    * @returns Formatted string with full exception details
    */
    public static String getErrorString(Exception e) {
        String message = e.getTypeName() + ': ' + e.getMessage() + '\n';
        message += e.getStackTraceString();

        if(e.getCause() != null) {
            message += '\nCaused By: ' + getErrorString(e.getCause());
        }
        return message;
    }

    /**
    * @description Converts a Database Error to a string. Provides the message plus field information if available
    * @param e The database error to turn into a string
    * @returns Formatted string with full error details
    */
    public static String getErrorString(Database.Error e) {
        String message = e.getMessage();
        if(e.getFields() != null && !e.getFields().isEmpty()) {
            message += '\nIn fields: ' + String.join(e.getFields(),', ');
        }
        return message;
    }

    /**
    * @description Converts a Database Error to a string. Provides the message plus field information if available
    * @param e The database error to turn into a string
    * @returns Formatted string with full error details
    */
    public static String getErrorString(List<Database.Error> dbErrors) {
        String message;
        for(Database.Error e : dbErrors) {
            message += '\n' + getErrorString(e) + '\n';
        }
        return message;
    }
}