/**
 * @author      Mavens
 * @date        12/2020
 * @description Controller for pjnCoverageInvestigationUpdater lwc
 * @group       CoverageInvestigation
 */
public with sharing class PJN_CoverageInvestigationUpdaterCtrl {

    private class PJN_CoverageInvestigationUpdaterCtrlException extends exception {}

    @AuraEnabled
    public static PJN_DataTable getTable(String investigationId, String childObjectApiName){
        try {
            switch on (childObjectApiName) {
                when 'PJN_Member_Plan__c' { return memberPlanTable(investigationId); }
                when 'PJN_Prior_Authorization__c' { return priorAuthTable(investigationId); }
                when 'PJN_Assistance_Program__c' { return assistanceProgramTable(investigationId); }
            }
            throw new PJN_CoverageInvestigationUpdaterCtrlException('Unable to process object with api name ' + childObjectApiName + '. Please check spelling.');
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }

    @AuraEnabled
    public static List<InputField> getFields(String objectApiName){
        try {
            List<InputField> inputFields = new List<InputField>();
            for (FieldSetMember fsm : Schema.getGlobalDescribe().get(objectApiName).getDescribe().fieldSets.getMap().get('PJN_Coverage_Investigation_Update_Screen').getFields()) {
                inputFields.add( new InputField(fsm));
            }
            return inputFields;
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }

    public class InputField {
        @AuraEnabled public String name;
        @AuraEnabled public Boolean required;

        public InputField(FieldSetMember fsm) {
            this.name = fsm.getFieldPath();
            this.required = fsm.getRequired();
        }
    }

    @AuraEnabled
    public static String getTherapyAccessRecTypeId() {
        return PJN_Event__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PJN_Therapy_Access').getRecordTypeId();
    }

    @AuraEnabled
    public static void submit(Map<String, SObject> data){
        try {
            if (data.containsKey('PJN_Coverage_Investigation__c')) {
                PJN_Coverage_Investigation__c investigation = (PJN_Coverage_Investigation__c) data.get('PJN_Coverage_Investigation__c');
                update investigation;
            }

            if (data.containsKey('Case')) {
                Case activity = (Case) data.get('Case');
                Case carePlanInfo = getCarePlanInfo(activity.PJN_Coverage_Investigation__c);
                activity.ParentId = carePlanInfo.Id;
                activity.AccountId = carePlanInfo.AccountId;
                activity.PJN_Program__c = carePlanInfo.PJN_Program__c;
                activity.PJN_Program_DeveloperName__c = carePlanInfo.PJN_Program_DeveloperName__c;
                activity.RecordTypeId = Case.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId();
                insert activity;
            }

            if (data.containsKey('PJN_Event__c')) {
                PJN_Event__c event = (PJN_Event__c) data.get('PJN_Event__c');
                Case carePlanInfo = getCarePlanInfo(event.PJN_Coverage_Investigation__c);
                event.PJN_Case__c = carePlanInfo.Id;
                event.PJN_Patient__c = carePlanInfo.AccountId;
                event.PJN_Program_DeveloperName__c = carePlanInfo.PJN_Program_DeveloperName__c;
                event.RecordTypeId = PJN_Event__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PJN_Therapy_Access').getRecordTypeId();
                insert event;
            }
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage() + ' ' + e.getStackTraceString());
            throw ex;
        }
    }

    private static Case getCarePlanInfo(Id investigationId) {
        PJN_Coverage_Investigation__c investigation = [
            SELECT PJN_Care_Plan__r.Id, PJN_Care_Plan__r.AccountId, PJN_Care_Plan__r.PJN_Program__c, PJN_Care_Plan__r.PJN_Program_DeveloperName__c
            FROM PJN_Coverage_Investigation__c
            WHERE Id = :investigationId
        ];

        return investigation.PJN_Care_Plan__r;
    }


    /*
     * Query for member plans attached to investigation items
     */
    private static PJN_DataTable memberPlanTable(String investigationId) {

        PJN_DataTable table = new PJN_DataTable();
        table.columns = new List<PJN_FieldWrapper>();

        List<PJN_Coverage_Investigation_Item__c> items = [
            SELECT PJN_Member_Plan__c
            FROM PJN_Coverage_Investigation_Item__c
            WHERE PJN_Coverage_Investigation__c = :investigationId
        ];

        Set<Id> memberPlanIds = new Set<Id>();
        for (PJN_Coverage_Investigation_Item__c item : items) {
            memberPlanIds.add(item.PJN_Member_Plan__c);
        }

        List<String> fields = new List<String>();
        Map<String, Schema.SObjectField> fieldMap = PJN_Member_Plan__c.SObjectType.getDescribe().fields.getMap();

        for (FieldSetMember fsm : Schema.SObjectType.PJN_Member_Plan__c.fieldSets.PJN_Coverage_Investigation_Update_Screen.getFields()) {
            // prepare the fields for query
            fields.add(fsm.fieldpath);

            // add the fields as columns for the data table
            table.columns.add(
                new PJN_FieldWrapper('PJN_Member_Plan__c', fieldMap.get(fsm.fieldpath).getDescribe())
            );
        }

        String queryString = String.format(
            'SELECT {0} FROM PJN_Member_Plan__c WHERE Id IN :memberPlanIds ORDER BY PJN_Coverage_Order__c',
            new List<String> { String.join(fields, ', ') }
        );

        System.debug('QueryString: ' + queryString);
        table.data = Database.query(queryString);

        return table;
    }

    /*
     * Query for prior authorizations attached to the investigation
     */
    private static PJN_DataTable priorAuthTable(String investigationId) {
        PJN_DataTable table = new PJN_DataTable();
        table.columns = new List<PJN_FieldWrapper>();

        List<String> fields = new List<String>();
        Map<String, Schema.SObjectField> fieldMap = PJN_Prior_Authorization__c.SObjectType.getDescribe().fields.getMap();

        for (FieldSetMember fsm : Schema.SObjectType.PJN_Prior_Authorization__c.fieldSets.PJN_Coverage_Investigation_Update_Screen.getFields()) {
            // prepare the fields for query
            fields.add(fsm.fieldpath);

            // add the fields as columns for the data table
            table.columns.add(
                new PJN_FieldWrapper('PJN_Prior_Authorization__c', fieldMap.get(fsm.fieldpath).getDescribe())
            );
        }

        String queryString = String.format(
            'SELECT {0} FROM PJN_Prior_Authorization__c WHERE PJN_Coverage_Investigation__c = :investigationId ORDER BY PJN_Submitted_Date__c DESC',
            new List<String> { String.join(fields, ', ') }
        );

        System.debug('QueryString: ' + queryString);
        table.data = Database.query(queryString);

        return table;
    }

    /*
     * Query for assistance programs attached to the investigation
     */
    private static PJN_DataTable assistanceProgramTable(String investigationId) {
        PJN_DataTable table = new PJN_DataTable();
        table.columns = new List<PJN_FieldWrapper>();

        List<String> fields = new List<String>();
        Map<String, Schema.SObjectField> fieldMap = PJN_Assistance_Program__c.SObjectType.getDescribe().fields.getMap();

        for (FieldSetMember fsm : Schema.SObjectType.PJN_Assistance_Program__c.fieldSets.PJN_Coverage_Investigation_Update_Screen.getFields()) {
            // prepare the fields for query
            fields.add(fsm.fieldpath);

            // add the fields as columns for the data table
            table.columns.add(
                new PJN_FieldWrapper('PJN_Assistance_Program__c', fieldMap.get(fsm.fieldpath).getDescribe())
            );
        }

        String queryString = String.format(
            'SELECT {0} FROM PJN_Assistance_Program__c WHERE PJN_Coverage_Investigation__c = :investigationId',
            new List<String> { String.join(fields, ', ') }
        );

        System.debug('QueryString: ' + queryString);
        table.data = Database.query(queryString);

        return table;
    }
}