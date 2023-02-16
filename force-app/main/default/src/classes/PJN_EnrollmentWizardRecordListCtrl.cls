/**
 * @author Mavens
 * @date Jan 2019
 * @description Get data from custom settings to build the table
 * @group EnrollmentWizard
 */
public with sharing class PJN_EnrollmentWizardRecordListCtrl {
    @TestVisible
    private static PJN_EnrollmentWizardRecordListQuery enrollmentRecordListQuery = new PJN_EnrollmentWizardRecordListQuery();

    /**
     * getRecords retrieve records and columns to be displayed in a lightning table
     * @param  componentSettingId   enrollment component id
     * @param  carePlanId           care plan id
     * @returns PJN_DataTable         wrapper object with records and columns
     */
    @auraEnabled
    public static PJN_DataTable getRecords(Id componentSettingId, Id carePlanId) {
        try {
            PJN_Enrollment_Wizard_Record_List__mdt recordListSetting = enrollmentRecordListQuery.getEnrollmentWizardRecordList(componentSettingId);

            PJN_DataTable dataTable = new PJN_DataTable();
            dataTable.data = getRecordList(recordListSetting, carePlanId);
            dataTable.columns = getColumns(recordListSetting);
            return dataTable;
        } catch (Exception exc) {
            String msg = 'No list definition found. Please contact your system administrator.';
            AuraHandledException auraException = new AuraHandledException(msg);
            auraException.setMessage(msg);
            throw auraException;

        }
    }

    /**
     * getRecordList retrieve records from the database with the information passed via the custom metadata record
     * @param  recordListSetting enrollment list custom metadata record
     * @param  carePlanId        care plan id
     * @returns List<SObject>     list of records
     */
    private static List<SObject> getRecordList(PJN_Enrollment_Wizard_Record_List__mdt recordListSetting, Id carePlanId) {
        List<SObject> records = Database.query(
            'SELECT ' +
                String.escapeSingleQuotes(recordListSetting.PJN_Fields__c) + ' ' +
            'FROM ' +
                String.escapeSingleQuotes(recordListSetting.PJN_SObject_API_Name__c) + ' ' +
            (String.IsBlank(recordListSetting.PJN_Care_Plan_Lookup_Field_API_Name__c) ? '' :
                'WHERE ' + String.escapeSingleQuotes(recordListSetting.PJN_Care_Plan_Lookup_Field_API_Name__c) + ' = \'' + carePlanId + '\' '
            ) +
            (String.IsBlank(recordListSetting.PJN_Where_Clause__c) ? '' :
                (String.IsBlank(recordListSetting.PJN_Care_Plan_Lookup_Field_API_Name__c) ? 'WHERE ' : 'AND ') +
                    String.escapeSingleQuotes(recordListSetting.PJN_Where_Clause__c) + ' '
            ) +
            (String.IsBlank(recordListSetting.PJN_Order_By__c) ? '' :
                'ORDER BY ' +
                    String.escapeSingleQuotes(recordListSetting.PJN_Order_By__c)
            )
        );
        return records;
    }

    /**
     * getColumns get columns definition to be passed to a lightning datatable
     * @param  recordListSetting        enrollment list custom metadata id
     * @returns  List<PJN_FieldWrapper>   list of columns wrapped in a custom record
     */
    private static List<PJN_FieldWrapper> getColumns(PJN_Enrollment_Wizard_Record_List__mdt recordListSetting) {
        Schema.DescribeSObjectResult sObjectDescribe = Schema.getGlobalDescribe()
                                        .get(recordListSetting.PJN_SObject_API_Name__c).getDescribe();
        Map<String,String> actions = new Map<String,String>();
        if (recordListSetting.PJN_Editable__c && sObjectDescribe.isUpdateable()) {
            actions.put(Label.PJN_List_Component_Edit_Action, 'edit');
        }
        if (recordListSetting.PJN_Deletable__c && sObjectDescribe.isDeletable()) {
            actions.put(Label.PJN_List_Component_Delete_Action, 'delete');
        }
        return PJN_Utilities.getColumns(
            recordListSetting.PJN_SObject_API_Name__c,
            recordListSetting.PJN_Fields__c.split(','),
            actions
        );
    }

    /**
     * deleteRecord Delete record
     * @param  record record to be deleted
     */
    @auraEnabled
    public static void deleteRecord(SObject record) {
        try {
            delete record;
        } catch (Exception exc) {
            String msg = String.format(Label.PJN_Enrollment_Wizard_Exception_Message, new List<String>{exc.getMessage()});
            AuraHandledException auraException = new AuraHandledException(msg);
            auraException.setMessage(msg);
            throw auraException;
        }
    }
}