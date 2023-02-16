/**
 * @author      Mavens
 * @description enable simple aura handled error handling in aura controllers
 * @group       Utils
 */
public with sharing class PJN_AuraHandledExceptionUtil {
    /**
    * handle exception, debug it and transform it to an aura handled exception
    * @param    Exception      ex
    * @returns   AuraHandledException
    */
    public static AuraHandledException handleException(Exception ex) {
        debugException(ex);
        String message = String.format(
            Label.PJN_Contact_Admin,
            new List<String> {
                ex.getMessage()
            }
        );
        return createAuraException(message);
    }

    /**
    * handle exception, debug it and transform it to an aura handled exception
    * @param    Exception      ex
    * @returns   AuraHandledException
    */
    public static AuraHandledException handleException(Exception ex, String label) {
        debugException(ex);
        String message = String.format(
            label,
            new List<String> {
                ex.getMessage()
            }
        );
        return createAuraException(message);
    }

    /**
    * handle aura handled exception, debug it and throw it again
    * @param    Exception      ex
    */
    public static AuraHandledException handleAuraException(AuraHandledException ex) {
        debugException(ex);
        return createAuraException(ex.getMessage());
    }

    /**
    * debug exception details
    * @param    Exception      ex
    */
    private static void debugException(Exception ex) {
        System.debug('===> ' + ex.getMessage());
        System.debug('===> ' + ex.getStackTraceString());
    }

    /**
    * throw aura handled exception with set message
    * @param    String      message
    * @returns   AuraHandledException
    */
    private static AuraHandledException createAuraException(String message) {
        AuraHandledException auraException = new AuraHandledException(message);
        auraException.setMessage(message);
        return auraException;
    }
}