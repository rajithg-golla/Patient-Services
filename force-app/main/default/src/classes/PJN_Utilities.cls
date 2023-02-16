/**
 * @author      Mavens
 * @group       Util
 * @description Utility methods that will need to be used in multiple places throughout the application.
 **/
public with sharing class PJN_Utilities {
    @TestVisible
    private static PJN_Global_Setting__mdt globalSettingMock;

    public static List<String> splitCommaSeparatedString(String stringToSplit){
        return splitString(stringToSplit,',');
    }

    public static List<String> splitString(String stringToSplit, String stringToSplitBy){
        if(String.isBlank(stringToSplit)){
            return new List<String>();
        } else{
            List<String> splitStrings = stringToSplit.split(stringToSplitBy);
            List<String> stringsToReturn = new List<String>();
            for(String splitString : splitStrings){
                stringsToReturn.add(splitString.normalizeSpace());
            }
            return stringsToReturn;
        }
    }

    public static PJN_Global_Setting__mdt globalSetting {
        get {
            if(globalSetting == null) {
                String queryString =
                    PJN_SObjectUtil.getSelectForSetupObject('PJN_Global_Setting__mdt')
                    + ' LIMIT 1';

                List<PJN_Global_Setting__mdt> globalSettings =
                    (List<PJN_Global_Setting__mdt>) Database.query(queryString);

                globalSetting =
                    globalSettings.isEmpty() ? new PJN_Global_Setting__mdt() : globalSettings[0];

                if(globalSettingMock != null) {
                    globalSetting = globalSettingMock;
                }
            }

            return globalSetting;
        }
        set;
    }

    /**
    * getFields Get list of fields defined in a specific field set
    * @param  objectName   name of the object where the field set is defined
    * @param  fieldSetName name of the field set
    * @returns              List<String> List of field names
    */
    public static List<String> getFields(String objectName, String fieldSetName) {
        List<String> fieldList = new List<String>();
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType == null) {
            return fieldList;
        }

        Schema.FieldSet fs = objectType.getDescribe().FieldSets.getMap().get(fieldSetName);
        if (fs == null) {
            return fieldList;
        }

        for(Schema.FieldSetMember fsm : fs.getFields()) {
            fieldList.add(fsm.getFieldPath());
        }
        return fieldList;
    }

    /**
     * getColumns     Get the list of columns wrapped in a list of PJN_FieldWrapper for the object specified
     *                in the attributes and for the fields passed.
     * @param  objectName Name of the object
     * @param  fieldList  List of fields to be displayed in the columns
     * @param  actions    Map containing the actions to add to the action column. Key=action label; Value=action value.
     * @returns List<PJN_FieldWrapper> List of columns wrapped in a custom class
     */
    public static List<PJN_FieldWrapper> getColumns(String objectName, List<String> fieldList, Map<String, String> actions) {
        Map<String, Schema.SobjectField> allFieldDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();

        List<PJN_FieldWrapper> columns = new List<PJN_FieldWrapper>();
        for(String fieldName : fieldList) {
            fieldName = fieldName.trim();
            Schema.DescribeFieldResult fieldDescribe  = allFieldDescribe.get(fieldName).getDescribe();
            PJN_FieldWrapper column = new PJN_FieldWrapper(objectName, fieldDescribe);
            column.sortable = true;
            columns.add(column);
        }
        if (!actions.isEmpty()) {
            List<PJN_FieldWrapper.PJN_DataTableColumnAction> actionList = new List<PJN_FieldWrapper.PJN_DataTableColumnAction>();
            for (String actionLabel : actions.keySet()) {
                actionList.add(new PJN_FieldWrapper.PJN_DataTableColumnAction(actionLabel, actions.get(actionLabel)));
            }
            PJN_FieldWrapper column = new PJN_FieldWrapper();
            column.type = 'action';
            column.typeAttributes = new PJN_FieldWrapper.PJN_DataTableColumnTypeAttributes();
            column.typeAttributes.rowActions = actionList;

            columns.add(column);
        }
        return columns;
    }
}