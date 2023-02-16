/**
 * @author      Mavens
 * @group       ContactInformation
 * @description contact information widget controller
 * @group ContactInformation
 */
public with sharing class PJN_ContactInformationCtrl {
    /**
     * global describe
     */
    private static Map<String,Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

    /**
     * get Contact Information data and columns
     * @param   Id      parentId
     * @returns  PJN_DataTable
     */
    @auraEnabled public static PJN_DataTable getContactInformation(Id parentId) {
        try {
            PJN_DataTable dataTable = new PJN_DataTable();
            dataTable.data = getRecords(parentId);
            dataTable.columns = getColumns(parentId);

            return dataTable;
        } catch (Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex);
        }
    }

    /**
     * get Records to fill the data for the contact information table
     * @param   Id      parentId
     * @returns  List<Object>
     */
    private static List<Object> getRecords(Id parentId) {
        List<PJN_Contact_Information__c> contactInformation = queryContactInformation(parentId);
        return convertContactInformationToData(contactInformation);
    }

    /**
     * query contact information records for parentId
     * @param   Id      parentId
     * @returns  List<PJN_Contact_Information__c>
     */
    private static List<PJN_Contact_Information__c> queryContactInformation(Id parentId) {
        if(isAccount(parentId)) {
            return queryContactInformationFromAccount(parentId);
        } else if(isCase(parentId)) {
            return queryContactInformationFromCarePlan(parentId);
        }
        return new List<PJN_Contact_Information__c>();
    }

    /**
     * query contact information records for parentId if it is an account
     * @param   Id      parentId
     * @returns  List<PJN_Contact_Information__c>
     */
    private static List<PJN_Contact_Information__c> queryContactInformationFromAccount(Id parentId) {
        return [
            SELECT
                Id,
                PJN_Record_Type_Name__c,
                PJN_Type_Formula__c,
                PJN_Value__c,
                PJN_Primary__c,
                PJN_Voice_Messages_OK__c,
                PJN_Text_Messages_OK__c,
                PJN_Best_Time__c
            FROM
                PJN_Contact_Information__c
            WHERE
                PJN_Account__c = :parentId
            ORDER BY
                PJN_Record_Type_Name__c ASC, PJN_Primary__c DESC
        ];
    }

    /**
     * query contact information records for parentId if it is a case
     * @param   Id      parentId
     * @returns  List<PJN_Contact_Information__c>
     */
    private static List<PJN_Contact_Information__c> queryContactInformationFromCarePlan(Id parentId) {
        Case carePlan = PJN_CarePlanQuery.queryById(parentId);
        Date today = System.today();
        return [
            SELECT
                Id,
                PJN_Record_Type_Name__c,
                PJN_Type_Formula__c,
                PJN_Value__c,
                PJN_Primary__c,
                PJN_Voice_Messages_OK__c,
                PJN_Text_Messages_OK__c,
                PJN_Best_Time__c,
                (
                    SELECT
                        Id,
                        PJN_Privacy_Consent_Status__c
                    FROM
                        PJN_Channel_Consent__r
                    WHERE
                        PJN_Data_Use_Purpose__r.Purpose.PJN_Program_DeveloperName__c = :carePlan.PJN_Program_DeveloperName__c
                    LIMIT
                        1
                )
            FROM
                PJN_Contact_Information__c
            WHERE
                PJN_Account__c = :carePlan.AccountId
            ORDER BY
                PJN_Record_Type_Name__c ASC, PJN_Primary__c DESC
        ];
    }

    /**
     * convert list of contact information records to data
     * @param   List<PJN_Contact_Information__c>      contactInformation
     * @returns  List<Object>
     */
    private static List<Object> convertContactInformationToData(List<PJN_Contact_Information__c> contactInformation) {
        List<Object> contactInformationRecords = new List<Object>();
        for(PJN_Contact_Information__c thisContactInformation : contactInformation) {
            Map<String, Object> contentInformationRecord = new Map<String, Object> {
                'Id' => thisContactInformation.Id,
                'PJN_Record_Type_Name__c' => thisContactInformation.PJN_Record_Type_Name__c,
                'PJN_Type_Formula__c' => thisContactInformation.PJN_Type_Formula__c,
                'PJN_Value__c' => thisContactInformation.PJN_Value__c,
                'PJN_Primary__c' => thisContactInformation.PJN_Primary__c,
                'PJN_Voice_Messages_OK__c' => thisContactInformation.PJN_Voice_Messages_OK__c,
                'PJN_Text_Messages_OK__c' => thisContactInformation.PJN_Text_Messages_OK__c,
                'PJN_Best_Time__c' => thisContactInformation.PJN_Best_Time__c
            };
            if(!thisContactInformation.PJN_Channel_Consent__r.isEmpty()) {
                contentInformationRecord.putAll(addConsentData(thisContactInformation.PJN_Channel_Consent__r[0]));
            } else {
                contentInformationRecord.putAll(addConsentData());
            }
            contactInformationRecords.add(contentInformationRecord);
        }
        return contactInformationRecords;
    }

    /**
     * add default consent data to contact information data map
     * @returns  Map<String, Object>
     */
    private static Map<String, Object> addConsentData() {
        Map<String, Object> contentInformationRecord = new Map<String, Object>();
        contentInformationRecord.put('Consent_Status', 'Not Given');
        contentInformationRecord.put('Consent_Status_Icon', 'action:info');
        return contentInformationRecord;
    }

    /**
     * add consent data to contact information data map
     * @param   PJN_Channel_Consent__c      channelConsent
     * @returns  Map<String, Object>
     */
    private static Map<String, Object> addConsentData(PJN_Channel_Consent__c channelConsent) {
        Map<String, Object> contentInformationRecord = new Map<String, Object>();
        contentInformationRecord.put('Consent_Status', channelConsent.PJN_Privacy_Consent_Status__c);
        contentInformationRecord.put('Consent_Status_Icon', 'action:info');
        if(channelConsent.PJN_Privacy_Consent_Status__c == 'Opt In') {
            contentInformationRecord.put('Consent_Status_Icon', 'action:approval');
        } else if(channelConsent.PJN_Privacy_Consent_Status__c == 'Opt Out') {
            contentInformationRecord.put('Consent_Status_Icon', 'action:close');
        }
        return contentInformationRecord;
    }

    /**
     * get columns and actions
     * @param   Id      parentId
     * @returns  List<PJN_FieldWrapper>
     */
    private static List<PJN_FieldWrapper> getColumns(Id parentId) {
        List<PJN_FieldWrapper> columns = createColumns(parentId);
        columns.add(createActions(parentId));
        // ensure the column labels are upper case to align with SF related lists
        for(PJN_FieldWrapper thisColumn : columns) {
            if(thisColumn != null && !String.IsBlank(thisColumn.label)) {
                thisColumn.label = thisColumn.label.toUpperCase();
            }
        }
        return columns;
    }

    /**
     * create columns
     * @param   Id      parentId
     * @returns  List<PJN_FieldWrapper>
     */
    private static List<PJN_FieldWrapper> createColumns(Id parentId) {
        Map<String,Schema.SObjectField> contactInformationAllFieldDescribe = globalDescribe.get('PJN_Contact_Information__c').getDescribe().fields.getMap();
        List<PJN_FieldWrapper> columns = new List<PJN_FieldWrapper>();
        columns.add(new PJN_FieldWrapper('PJN_Contact_Information__c', contactInformationAllFieldDescribe.get('PJN_Type_Formula__c').getDescribe()));
        columns.add(new PJN_FieldWrapper('PJN_Contact_Information__c', contactInformationAllFieldDescribe.get('PJN_Value__c').getDescribe()));
        PJN_FieldWrapper primaryColumn = new PJN_FieldWrapper('PJN_Contact_Information__c', contactInformationAllFieldDescribe.get('PJN_Primary__c').getDescribe());
        primaryColumn.initialWidth = 90;
        columns.add(primaryColumn);
        if(isCase(parentId)) {
            columns.addAll(createConsentColumns());
        }
        return columns;
    }

    /**
     * create consent columns
     * @returns  List<PJN_FieldWrapper>
     */
    private static List<PJN_FieldWrapper> createConsentColumns() {
        Map<String,Schema.SObjectField> channelConsentAllFieldDescribe = globalDescribe.get('PJN_Channel_Consent__c').getDescribe().fields.getMap();
        List<PJN_FieldWrapper> columns = new List<PJN_FieldWrapper>();
        PJN_FieldWrapper consentColumn = new PJN_FieldWrapper();
        consentColumn.objectName = 'PJN_Channel_Consent__r';
        consentColumn.label = channelConsentAllFieldDescribe.get('PJN_Privacy_Consent_Status__c').getDescribe().getLabel();
        consentColumn.fieldName = 'Consent_Status';
        consentColumn.type = 'text';
        consentColumn.objectFieldName = consentColumn.objectName + consentColumn.fieldName;
        consentColumn.cellAttributes = new PJN_FieldWrapper.PJN_CellAttributes('Consent_Status_Icon');
        columns.add(consentColumn);
        return columns;
    }

    /**
     * create actions
     * @param   Id      parentId
     * @returns  PJN_FieldWrapper
     */
    private static PJN_FieldWrapper createActions(Id parentId) {
        List<PJN_FieldWrapper.PJN_DataTableColumnAction> actions = new List<PJN_FieldWrapper.PJN_DataTableColumnAction>();
        if(isCase(parentId)) {
            actions.addAll(createConsentActions());
        }

        DescribeSObjectResult dr = PJN_Contact_Information__c.SObjectType.getDescribe();

        if (dr.isAccessible()) {
            actions.add(new PJN_FieldWrapper.PJN_DataTableColumnAction(
                Label.PJN_Contact_Information_Widget_Show_Details_Action, 'showdetails', 'utility:description')
            );
        }
        if (dr.isUpdateable()) {
            actions.add(new PJN_FieldWrapper.PJN_DataTableColumnAction(
                Label.PJN_Contact_Information_Widget_Edit_Action, 'edit', 'utility:edit')
            );
        }
        if (dr.isDeletable()) {
            actions.add(new PJN_FieldWrapper.PJN_DataTableColumnAction(
                Label.PJN_Contact_Information_Widget_Delete_Action, 'delete', 'utility:delete')
            );
        }
        PJN_FieldWrapper column = new PJN_FieldWrapper();
        column.type = 'action';
        column.typeAttributes = new PJN_FieldWrapper.PJN_DataTableColumnTypeAttributes();
        column.typeAttributes.rowActions = actions;
        return column;
    }

    /**
     * create consent actions
     * @returns  List<PJN_FieldWrapper.PJN_DataTableColumnAction>
     */
    private static List<PJN_FieldWrapper.PJN_DataTableColumnAction> createConsentActions() {
        List<PJN_FieldWrapper.PJN_DataTableColumnAction> actions = new List<PJN_FieldWrapper.PJN_DataTableColumnAction>();
        actions.add(new PJN_FieldWrapper.PJN_DataTableColumnAction(
            Label.PJN_Contact_Information_Widget_Opt_In_Action, 'optin', 'utility:add')
        );
        actions.add(new PJN_FieldWrapper.PJN_DataTableColumnAction(
            Label.PJN_Contact_Information_Widget_Opt_Out_Action, 'optout', 'utility:dash')
        );
        return actions;
    }

    /**
     * get parent type of Id
     * @param  Id       parentId
     * @returns  String
     */
    @auraEnabled public static String getParentType(Id parentId) {
        try {
            String parentType;
            if(isAccount(parentId)) {
                parentType = 'Account';
            } else if(isCase(parentId)) {
                parentType = 'CarePlan';
            }
            return parentType;
        } catch (Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex, Label.PJN_Contact_Information_Exception_General_Message);
        }
    }

    /**
     * check if parentId is an account
     * @param  Id       parentId
     * @returns  Boolean
     */
    private static Boolean isAccount(Id parentId) {
        return parentId.getSObjectType() == (new Account()).getSObjectType();
    }

    /**
     * check if parentId is a case
     * @param  Id       parentId
     * @returns  Boolean
     */
    private static Boolean isCase(Id parentId) {
        return parentId.getSObjectType() == (new Case()).getSObjectType();
    }

    /**
     * delete contact information records
     * @param  Id       contactInformationId
     * @returns  Boolean
     */
    @auraEnabled public static void deleteContactInformation(Id contactInformationId) {
        try {
            Database.delete(contactInformationId);
        } catch (Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex, Label.PJN_Contact_Information_Exception_General_Message);
        }
    }

    /**
     * opt in to consent to contact information record
     * @param  Id       contactInformationId
     * @returns  Boolean
     */
    @auraEnabled public static void optInContactInformation(Id contactInformationId, String programDeveloperName) {
        try {
            PJN_ConsentHdlr.processConsentForContactInformation(
                new List<Id>{contactInformationId},
                programDeveloperName,
                PJN_ConsentHdlr.OPT_IN
            );
        } catch (Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex, Label.PJN_Contact_Information_Exception_General_Message);
        }
    }

    /**
     * opt out from consent to contact information record
     * @param  Id       contactInformationId
     * @returns  Boolean
     */
    @auraEnabled public static void optOutContactInformation(Id contactInformationId, String programDeveloperName) {
        try {
            PJN_ConsentHdlr.processConsentForContactInformation(
                new List<Id>{contactInformationId},
                programDeveloperName,
                PJN_ConsentHdlr.OPT_OUT
            );
        } catch (Exception ex) {
            throw PJN_AuraHandledExceptionUtil.handleException(ex, Label.PJN_Contact_Information_Exception_General_Message);
        }
    }
}