/**
 * @author Mavens
 * @date Jan 2019
 * @description Base class used to build out specific object factory classes
 * @group TestFactory
 */
@isTest(isParallel=true) public class PJN_TestFactorySObject {

    private SObject defaultSObject;

    public PJN_TestFactorySObject() {
        //This contructor should only be used for custom metadata factories
    }

    public PJN_TestFactorySObject(String objectType, Map<String,Object> defaultValues) {
        this(objectType, defaultValues, true);
    }

    public PJN_TestFactorySObject(String objectType, Map<String,Object> defaultValues, Boolean populateRequired) {
        defaultSObject = Schema.getGlobalDescribe().get(objectType).newSObject();

        if (populateRequired) {
            populateRequiredFields(objectType);
        }

        if (defaultValues != null) {
            for (String field : defaultValues.keySet()) {
                defaultSObject.put(field, defaultValues.get(field));
            }
        }
    }

    public SObject constructSObject(Map<String,Object> valuesByField) {
        SObject sObj = defaultSObject.clone(false, true, false, false);

        if (valuesByField != null) {
            for (String field : valuesByField.keySet()) {
                sObj.put(field, valuesByField.get(field));
            }
        }

        return sObj;
    }

    public List<SObject> constructSObjects(Integer numOfObjects, Map<String,Object> valuesByField) {
        List<SObject> sObjs = new List<SObject>();
        for (Integer i=0; i<numOfObjects; i++) {
            sObjs.add(constructSObject(valuesByField));
        }
        return sObjs;
    }

    public SObject createSObject(Map<String,Object> valuesByField) {
        SObject sObj = constructSObject(valuesByField);
        insert sObj;
        return sObj;
    }

    public List<SObject> createSObjects(Integer numOfObjects, Map<String,Object> valuesByField) {
        List<SObject> sObjs = constructSObjects(numOfObjects, valuesByField);
        insert sObjs;
        return sObjs;
    }

    private void populateRequiredFields(String type) {
        DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(type).getDescribe();
        // Booleans can't be required. Lookups are too complex. Neither are considered here.
        for (Schema.SObjectField soField : objectDescribe.fields.getMap().values()) {

            Schema.DescribeFieldResult fieldDescribe = soField.getDescribe();
            if (isRequired(fieldDescribe)) {
                Schema.DisplayType displayType = fieldDescribe.getType();

                if (isText(displayType)) {
                    defaultSObject.put(fieldDescribe.getName(), 'Text');
                }
                else if (isNumber(displayType)) {
                    defaultSObject.put(fieldDescribe.getName(), 42);
                }
                else if (isDate(displayType)) {
                    defaultSObject.put(fieldDescribe.getName(), Date.today());
                }
                else if (isPhone(displayType)) {
                    defaultSObject.put(fieldDescribe.getName(), '5555555555');
                }
                else if (isEmail(displayType)) {
                    defaultSObject.put(fieldDescribe.getName(), 'defaultEmail@testdata.com');
                }
                else if (isUrl(displayType)) {
                    defaultSObject.put(fieldDescribe.getName(), 'https://mavens.com');
                }
                else if (isPicklist(displayType)) {
                    defaultSObject.put(fieldDescribe.getName(), fieldDescribe.getPicklistValues()[0].getValue());
                }
            }
        }
    }

    private Boolean isRequired(Schema.DescribeFieldResult describeResult) {
        return describeResult.isUpdateable() && !describeResult.isNillable();
    }

    private Boolean isText(Schema.DisplayType displayType) {
        return displayType == Schema.DisplayType.String || displayType == Schema.DisplayType.TextArea;
    }

    private Boolean isNumber( Schema.DisplayType displayType) {
        return displayType == Schema.DisplayType.Currency ||
               displayType == Schema.DisplayType.Double ||
               displayType == Schema.DisplayType.Integer ||
               displayType == Schema.DisplayType.Percent;
    }

    private Boolean isDate(Schema.DisplayType displayType) {
        return displayType == Schema.DisplayType.Date || displayType == Schema.DisplayType.DateTime;
    }

    private Boolean isPhone(Schema.DisplayType displayType) {
        return displayType == Schema.DisplayType.Phone;
    }

    private Boolean isEmail(Schema.DisplayType displayType) {
        return displayType == Schema.DisplayType.Email;
    }

    private Boolean isUrl(Schema.DisplayType displayType) {
        return displayType == Schema.DisplayType.URL;
    }

    private Boolean isPicklist(Schema.DisplayType displayType) {
        return displayType == Schema.DisplayType.Picklist || displayType == Schema.DisplayType.MultiPicklist;
    }

}