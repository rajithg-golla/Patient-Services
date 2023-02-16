public with sharing class PJN_FieldWrapper {
    @AuraEnabled public String objectName;
    @AuraEnabled public String label;
    @AuraEnabled public String fieldName;
    @AuraEnabled public String type;
    @AuraEnabled public String objectFieldName;
    @AuraEnabled public Boolean sortable;
    @AuraEnabled public Integer initialWidth;
    @AuraEnabled public PJN_CellAttributes cellAttributes;
    @AuraEnabled public PJN_DataTableColumnTypeAttributes typeAttributes;
    @AuraEnabled public Boolean wrapText;

    public PJN_Field_Setting__mdt setting;
    public DescribeFieldResult fieldDescribe;

    public PJN_FieldWrapper() {
        //constructor used for non sObject field columns. e.g. Actions column in a data table
    }

    public PJN_FieldWrapper(String objectName, Schema.DescribeFieldResult fieldDescribe) {
        this.initialize(objectName, fieldDescribe);
        this.type = columnTypeMap.get(fieldDescribe.getType());
    }

    public PJN_FieldWrapper(PJN_Field_Setting__mdt setting) {
        System.debug('Setting ' + setting);
        DescribeFieldResult fieldDescribe = Schema.getGlobalDescribe()
            .get(setting.PJN_Object__c)
            .getDescribe()
            .fields.getMap()
            .get(setting.PJN_Field__c)
            .getDescribe();

        this.initialize(setting.PJN_Object__c, fieldDescribe);
        this.type = inputFieldMap.get(fieldDescribe.getType());
        this.setting = setting;
    }

    private void initialize(String objectName, Schema.DescribeFieldResult fieldDescribe) {
        this.objectName = objectName;
        this.label = fieldDescribe.getLabel();
        this.fieldName = fieldDescribe.getName();
        this.objectFieldName = this.objectName + this.fieldName;
        this.setting = null;
        this.fieldDescribe = fieldDescribe;
        this.wrapText = true;
    }

    public Boolean isAccountField {
        get { return setting.PJN_Object__c == 'Account'; }
    }

    public Boolean isContactInfoField {
        get { return setting.PJN_Object__c == 'PJN_Contact_Information__c'; }
    }

    public Boolean isCaseField {
        get { return setting.PJN_Object__c == 'Case'; }
    }

    public Map<Schema.DisplayType, String> inputFieldMap = new Map<Schema.DisplayType, String> {
        Schema.DisplayType.Boolean => 'checkbox',
        Schema.DisplayType.Currency => 'number',
        Schema.DisplayType.Date => 'date',
        Schema.DisplayType.Datetime => 'datetime',
        Schema.DisplayType.Double => 'number',
        Schema.DisplayType.Email => 'email',
        Schema.DisplayType.Integer => 'number',
        Schema.DisplayType.Long => 'number',
        Schema.DisplayType.Percent => 'number',
        Schema.DisplayType.Phone => 'tel',
        Schema.DisplayType.String => 'text',
        Schema.DisplayType.URL => 'url',
        Schema.DisplayType.Reference => 'text',
        Schema.DisplayType.Picklist => 'text'
    };

    public Map<Schema.DisplayType, String> columnTypeMap = new Map<Schema.DisplayType, String> {
        Schema.DisplayType.Address => 'location',
        Schema.DisplayType.Boolean => 'boolean',
        Schema.DisplayType.Currency => 'currency',
        Schema.DisplayType.Date => 'date-local',
        Schema.DisplayType.Datetime => 'date-local',
        Schema.DisplayType.Double => 'number',
        Schema.DisplayType.Email => 'email',
        Schema.DisplayType.Integer => 'number',
        Schema.DisplayType.Long => 'number',
        Schema.DisplayType.Percent => 'percentage',
        Schema.DisplayType.Phone => 'phone',
        Schema.DisplayType.String => 'text',
        Schema.DisplayType.URL => 'url',
        Schema.DisplayType.Reference => 'id',
        Schema.DisplayType.Picklist => 'picklist'
    };

    public class PJN_DataTableColumnTypeAttributes {
        @AuraEnabled public List<PJN_DataTableColumnAction> rowActions;
        @AuraEnabled public String label;
        @AuraEnabled public String target;
    }

    public class PJN_DataTableColumnAction {
        @AuraEnabled public String label;
        @AuraEnabled public String name;
        @AuraEnabled public String iconName;

        public PJN_DataTableColumnAction(String label, String name) {
            this.label = label;
            this.name = name;
        }

        public PJN_DataTableColumnAction(String label, String name, String iconName) {
            this(label, name);
            this.iconName = iconName;
        }
    }

    public class PJN_CellAttributes {
        @AuraEnabled public PJN_IconName iconName;

        public PJN_CellAttributes(String fieldName) {
            this.iconName = new PJN_IconName(fieldName);
        }
    }

    public class PJN_IconName {
        @AuraEnabled public String fieldName;

        public PJN_IconName(String fieldName) {
            this.fieldName = fieldName;
        }
    }
}