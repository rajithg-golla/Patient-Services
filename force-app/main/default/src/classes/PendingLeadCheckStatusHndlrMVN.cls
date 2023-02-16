/**
 * @author      Mavens
 * @description If Agreement Status turns to “Signed” then convert the record to a Lead and stamp the Lead to the lookup field. 
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class PendingLeadCheckStatusHndlrMVN implements PJN_TriggerDispatcher.HandlerInterface {
    public void handle() {
        List<Pending_Lead_MVN__c> pendingConsumersForProcess = new List<Pending_Lead_MVN__c>();
        for (Pending_Lead_MVN__c pendingConsumer : (List<Pending_Lead_MVN__c>) Trigger.new) {
            if (isPendingLeadEligibleForConversion(pendingConsumer)) {
                pendingConsumersForProcess.add(pendingConsumer);
            }
        }

        convertPendingLeadsIntoLeads(pendingConsumersForProcess);
    }

    public static void convertPendingLeadsIntoLeads(List<Pending_Lead_MVN__c> pendingConsumersForProcess) {
        List<Pending_Lead_Mapping_MVN__mdt> consumerMappings = [SELECT Pending_Consumer_Field_MVN__c, Lead_Field_MVN__c FROM Pending_Lead_Mapping_MVN__mdt WHERE Active_MVN__c = true];
        Lead_Convert_Care_Plan_RT_Mapping_MVN__mdt rtMapping = [SELECT CarePlan_RecordType_Namespace_Prefix_MVN__c, Care_Plan_Record_Type_DeveloperName_MVN__c FROM Lead_Convert_Care_Plan_RT_Mapping_MVN__mdt WHERE Lead_Record_Type_Namespace_Prefix_MVN__c = '' AND Lead_Record_Type_DeveloperName_MVN__c = 'Libtayo_Marketing_Consumer_MVN' LIMIT 1][0];
        List<LeadWrapper> wrappers = new List<LeadWrapper>();
        List<Lead> consumers = new List<Lead>();
        Map<Id, echosign_dev1__SIGN_Agreement__c> agreementMap = queryAgreementMap(pendingConsumersForProcess);
        System.debug('#### agreementMap: ' + agreementMap);
        Id recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName = 'Libtayo_Marketing_Consumer_MVN' LIMIT 1].Id;
        Id integrationUserId = [SELECT Id FROM User WHERE Name = 'Integration User' LIMIT 1].Id;

        for (Pending_Lead_MVN__c pendingConsumer : pendingConsumersForProcess) {
            Lead consumer = new Lead();

            for (Pending_Lead_Mapping_MVN__mdt consumerMapping : consumerMappings) {
                // make sure the field from the mapping actually exists and the pending consumer value isn't null
                if (pendingConsumer.get(consumerMapping.Pending_Consumer_Field_MVN__c) != NULL) {
                    System.debug('#### Setting ' + consumerMapping.Lead_Field_MVN__c + ' to ' + pendingConsumer.get(consumerMapping.Pending_Consumer_Field_MVN__c));
                    consumer.put(consumerMapping.Lead_Field_MVN__c, pendingConsumer.get(consumerMapping.Pending_Consumer_Field_MVN__c));
                }
            }

            consumer.HealthCloudGA__IsMarkedForPatientConversion__c = true;
            consumer.HealthCloudGA__CarePlanRecordTypeNamespace__c = rtMapping.CarePlan_RecordType_Namespace_Prefix_MVN__c;
            consumer.HealthCloudGA__CarePlanRecordTypeName__c = rtMapping.Care_Plan_Record_Type_DeveloperName_MVN__c;
            consumer.Consumer_has_consented_to_the_prog_MVN__c = 'Yes';
            consumer.LeadSource = 'Website';
            consumer.RecordTypeId = recordTypeId;
            consumer.OwnerId = integrationUserId;
            consumer.Pending_Lead_MVN__c = pendingConsumer.Id;
            consumer.Status = 'Enrolled';

            LeadWrapper wrapper = new LeadWrapper(consumer, agreementMap.get(pendingConsumer.Id), pendingConsumer.Id);
            System.debug('#### agreementMap.get(' + pendingConsumer.Id + '): ' + agreementMap.get(pendingConsumer.Id));
            System.debug('#### new wrapper: ' + wrapper);
            wrappers.add(wrapper);
            consumers.add(consumer);
        }

        // prevent flows from running when testing.
        if (Test.isRunningTest()) {
            for (Lead consumer : consumers) {
                consumer.Status = 'Interaction';
                consumer.Consumer_has_consented_to_the_prog_MVN__c = 'No';
                consumer.HealthCloudGA__IsMarkedForPatientConversion__c = false;
            }
        }

        System.debug('#### consumers: ' + consumers);
        insert consumers;

        List<Pending_Lead_MVN__c> pendingConsumers = new List<Pending_Lead_MVN__c>();
        List<echosign_dev1__SIGN_Agreement__c> agreements = new List<echosign_dev1__SIGN_Agreement__c>();
        for (LeadWrapper wrapper : wrappers) {
            System.debug('#### wrapper: ' + wrapper);

            System.debug('#### wrapper.consumer: ' + wrapper.consumer);
            wrapper.pendingConsumer.Lead_MVN__c = wrapper.consumer.Id;
            pendingConsumers.add(wrapper.pendingConsumer);

            System.debug('#### wrapper.agreement: ' + wrapper.agreement);
            if (wrapper.agreement != NULL) {
                wrapper.agreement.CustomConsumer__c = wrapper.consumer.Id;
                wrapper.agreement.echosign_dev1__Recipient_Lead__c = wrapper.consumer.Id;
                agreements.add(wrapper.agreement);
            }
        }

        update pendingConsumers;
        update agreements;
    }

    private static Boolean isPendingLeadEligibleForConversion(Pending_Lead_MVN__c pendingConsumer) {
        Boolean result = false;
        // if agreement status is signed or agreement id is null on insert
        if (Trigger.isInsert && (pendingConsumer.Agreement_Status_MVN__c == 'Signed' || pendingConsumer.Agreement_Id_MVN__c == NULL)) {
            result = true;
        // if agreement status switched to signed
        } else if (Trigger.isUpdate && pendingConsumer.Agreement_Status_MVN__c == 'Signed') {
            Pending_Lead_MVN__c oldPendingLead = (Pending_Lead_MVN__c) Trigger.oldMap.get(pendingConsumer.Id);
            if (pendingConsumer.Agreement_Status_MVN__c != oldPendingLead.Agreement_Status_MVN__c) {
                result = true;
            }
        // if agreement id has become null
        } else if (Trigger.isUpdate && pendingConsumer.Agreement_Id_MVN__c == NULL) {
            Pending_Lead_MVN__c oldPendingLead = (Pending_Lead_MVN__c) Trigger.oldMap.get(pendingConsumer.Id);
            if (pendingConsumer.Agreement_Id_MVN__c != oldPendingLead.Agreement_Id_MVN__c) {
                result = true;
            }
        }

        return result;
    }

    private static Map<Id, echosign_dev1__SIGN_Agreement__c> queryAgreementMap(List<Pending_Lead_MVN__c> pendingConsumers) {
        Map<Id, echosign_dev1__SIGN_Agreement__c> result = new Map<Id, echosign_dev1__SIGN_Agreement__c>();
        for (echosign_dev1__SIGN_Agreement__c agreement : [SELECT CustomConsumer__c, Pending_Lead_MVN__c FROM echosign_dev1__SIGN_Agreement__c WHERE Pending_Lead_MVN__c IN :pendingConsumers]) {
            result.put(agreement.Pending_Lead_MVN__c, agreement);
        }
        return result;
    }

    private class LeadWrapper {
        public Pending_Lead_MVN__c pendingConsumer;
        public Lead consumer;
        public echosign_dev1__SIGN_Agreement__c agreement;

        public LeadWrapper(Lead consumer, echosign_dev1__SIGN_Agreement__c agreement, Id pendingConsumerId) {
            this.consumer = consumer;
            this.pendingConsumer = new Pending_Lead_MVN__c(Id = pendingConsumerId);
            this.agreement = agreement;
        }
    }
}