/*
 * @author Mavens
 * @date Nov 2019
 * @description Represents the list of care plans for an specific patient and the fields to display
 * @group AccountSearch
*/
public with sharing class PJN_CarePlanSelectorWrapper {
    @auraEnabled 
    public List<String> fieldList { get; set; }
    @auraEnabled 
    public List<String> fieldLabels { get; set; }
    @auraEnabled 
    public List<PJN_CarePlanRecordWrapper> carePlanWrapperList { get; set; }

    public class PJN_CarePlanRecordWrapper {
        @AuraEnabled
        public Case carePlanRecord{ get; set; }
        @AuraEnabled
        public Boolean hasAccess{ get; set; }

        public PJN_CarePlanRecordWrapper(Case carePlan, Boolean hasAccess) {
            this.carePlanRecord = carePlan;
            this.hasAccess = hasAccess;
        }
    }
}