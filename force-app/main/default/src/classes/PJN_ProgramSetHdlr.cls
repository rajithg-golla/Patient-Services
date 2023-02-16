/**
 * @author      Mavens
 * @group       Program
 * @description set Program lookup on the care plan
 */
public with sharing class PJN_ProgramSetHdlr implements PJN_TriggerDispatcher.HandlerInterface {
    /**
     * handle before insert trigger context
     */
    public void handle() {
        Set<String> programDevNames = new Set<String>();
        for(Case thisCase : (List<Case>) trigger.new) {
            if(!String.isBlank(thisCase.PJN_Program_DeveloperName__c)) {
                programDevNames.add(thisCase.PJN_Program_DeveloperName__c);
            }
        }

        Map<String, Id> programIdsByExternalId = new Map<String, Id>();
        for (CareProgram program : [SELECT Id, PJN_Program_DeveloperName__c FROM CareProgram WHERE PJN_Program_DeveloperName__c IN :programDevNames]) {
            programIdsByExternalId.put(program.PJN_Program_DeveloperName__c, program.Id);
        }

        for(Case thisCase : (List<Case>) trigger.new) {
            if(!String.isBlank(thisCase.PJN_Program_DeveloperName__c) && programIdsByExternalId.containsKey(thisCase.PJN_Program_DeveloperName__c)) {
                thisCase.PJN_Program__c =programIdsByExternalId.get(thisCase.PJN_Program_DeveloperName__c);
            }
        }
    }
}