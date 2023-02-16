/**
 * @author      Mavens
 * @group       ServiceCloudVoice
 * @description Stamps Primary Phone value on related Cases in E.164 format  
 *              For use with Service Cloud Voice
 */
public with sharing class MVN_StampPrimaryPhoneOnCasesHdlr implements PJN_TriggerDispatcher.HandlerInterface {
    
    public static Set<Id> accountIdsWithNewPrimaries = new Set<Id>();

    Id phoneRecordTypeId;
    
    public MVN_StampPrimaryPhoneOnCasesHdlr() {
        phoneRecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Phone').getRecordTypeId();
    }

    public void handle() {

        if (Trigger.isBefore) {
            List<PJN_Contact_Information__c> newContactInfos = (List<PJN_Contact_Information__c>) Trigger.new;
            for (PJN_Contact_Information__c newContactInfo : newContactInfos) {
                if (newContactInfo.RecordTypeId == phoneRecordTypeId && newContactInfo.PJN_Set_as_Primary__c) {
                    accountIdsWithNewPrimaries.add(newContactInfo.PJN_Account__c);
                }
            }

            System.debug(LoggingLevel.DEBUG, 'accountIdsWithNewPrimaries in MVN_StampPrimaryPhoneOnCasesHdlr.handle');
            System.debug(LoggingLevel.DEBUG, accountIdsWithNewPrimaries);

        } else if (Trigger.isAfter) {
            List<PJN_Contact_Information__c> newContactInfos = (List<PJN_Contact_Information__c>) Trigger.new;            
            List<PJN_Contact_Information__c> contactInfosToUpdate = new List<PJN_Contact_Information__c>();
            for (PJN_Contact_Information__c newContactInfo : newContactInfos) {
                if (newContactInfo.RecordTypeId == phoneRecordTypeId && accountIdsWithNewPrimaries.contains(newContactInfo.PJN_Account__c)) {
                    contactInfosToUpdate.add(newContactInfo);
                }
            }

            System.debug(LoggingLevel.DEBUG, 'contactInfosToUpdate in MVN_StampPrimaryPhoneOnCasesHdlr.handle');
            System.debug(LoggingLevel.DEBUG, contactInfosToUpdate);

            stampPhoneOnCases(contactInfosToUpdate);
        }
    }

    private void stampPhoneOnCases(List<PJN_Contact_Information__c> contactInfos) {

        Map<String,PJN_Contact_Information__c> accountContactInfoMap = new Map<String,PJN_Contact_Information__c>();
        for (PJN_Contact_Information__c contactInfo : contactInfos) {
            accountContactInfoMap.put(contactInfo.PJN_Account__c, contactInfo);
        }
        System.debug(LoggingLevel.DEBUG, 'accountContactInfoMap in MVN_StampPrimaryPhoneOnCases.stampPhoneOnCases');
        System.debug(LoggingLevel.DEBUG, accountContactInfoMap);

        List<Case> matchedCases = [
            SELECT Id,
                   AccountId,
                   PJN_Caregiver__c,
                   PJN_Physician__c,
                   PJN_Staff__c,
                   MVN_Caregiver_Primary_Phone_E164__c,
                   MVN_Patient_Primary_Phone_E164__c,
                   MVN_Physician_Primary_Phone_E164__c,
                   MVN_Staff_Primary_Phone_E164__c
              FROM Case 
             WHERE ( 
                AccountId IN :accountContactInfoMap.keySet() OR 
                PJN_Caregiver__c IN :accountContactInfoMap.keySet() OR 
                PJN_Physician__c IN :accountContactInfoMap.keySet() OR 
                PJN_Staff__c IN :accountContactInfoMap.keySet()
            )
        ];
        System.debug(LoggingLevel.DEBUG, 'matchedCases in MVN_StampPrimaryPhoneOnCases.stampPhoneOnCases');
        System.debug(LoggingLevel.DEBUG, matchedCases);

        for (Case matchedCase : matchedCases) {
            String patientId = matchedCase.AccountId;
            if (accountContactInfoMap.containsKey(patientId)) {
                matchedCase.MVN_Patient_Primary_Phone_E164__c = accountContactInfoMap.get(patientId).MVN_Phone_E_164__c;
            }

            String caregiverId = matchedCase.PJN_Caregiver__c;
            if (accountContactInfoMap.containsKey(caregiverId)) {
                matchedCase.MVN_Caregiver_Primary_Phone_E164__c = accountContactInfoMap.get(caregiverId).MVN_Phone_E_164__c;
            }

            String physicianId = matchedCase.PJN_Physician__c;
            if (accountContactInfoMap.containsKey(physicianId)) {
                matchedCase.MVN_Physician_Primary_Phone_E164__c = accountContactInfoMap.get(physicianId).MVN_Phone_E_164__c;
            }
            
            String staffId = matchedCase.PJN_Staff__c;
            if (accountContactInfoMap.containsKey(staffId)) {
                matchedCase.MVN_Staff_Primary_Phone_E164__c = accountContactInfoMap.get(staffId).MVN_Phone_E_164__c;
            }
        }

        try {
            update matchedCases;
        } catch (System.DmlException e) {
            System.debug(LoggingLevel.ERROR, 'Failed to stamp new primary phone on related cases');
            System.debug(LoggingLevel.ERROR, e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
        }

    }
}