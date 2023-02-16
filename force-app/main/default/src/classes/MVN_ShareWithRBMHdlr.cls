/**
 * @author      Mavens
 * @group       RBM
 * @description Sets the Share with RBM flag on Care Plans
 */
public with sharing class MVN_ShareWithRBMHdlr implements PJN_TriggerDispatcher.HandlerInterface {
    public void handle() {

        Id carePlanRecTypeId = SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('CarePlan')
            .getRecordTypeId();

        List<Case> carePlans = new List<Case>();

        if (Trigger.isInsert || Trigger.isUpdate) {
            for (Case newCase : (List<Case>) Trigger.new) {
                if (newCase.RecordTypeId == carePlanRecTypeId) {
                    carePlans.add(newCase);
                }
            }
            System.debug(LoggingLevel.DEBUG, 'Setting RBM Sharing for Care Plans');
            System.debug(carePlans);
            MVN_ShareWithRBM.share(carePlans);
        }
    }
}