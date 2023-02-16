/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping engine handler
 */
public inherited sharing abstract class PJN_MappingEngineHdlr implements PJN_MappingEngineHdlrIntf {
    /**
     * mapping
     */
    @testVisible protected PJN_Mapping__mdt mapping;

    /**
     * standard useMapping implementation
     * @param PJN_Mapping__mdt      mapping
     */
    public virtual void useMapping(PJN_Mapping__mdt mapping) {
        this.mapping = mapping;
    }

    /**
     * map single record
     * @param Id      sourceObjectId
     * @param SObject      targetObject
     * @returns SObject
     */
    public SObject mapRecord(Id sourceObjectId, SObject targetObject) {
        SObject sourceObject;
        if(sourceObjectId != null) {
            sourceObject = this.querySourceObject(sourceObjectId);
        }
        return this.mapRecord(sourceObject, targetObject);
    }

    /**
     * map multiple records
     * @param List<Id>      sourceObjectIds
     * @param List<SObject>      targetObjects
     * @returns List<SObject>
     */
    public List<SObject> mapRecord(List<Id> sourceObjectIds, List<SObject> targetObjects) {
        Map<Id, SObject> sourceObjects = this.querySourceObjects(new Set<Id>(sourceObjectIds));
        List<SObject> returnedObjects = new List<SObject>();
        for(Integer index = 0; index < targetObjects.size(); index++) {
            if (sourceObjectIds.size() <= index) {
                continue;
            }
            SObject sourceObject = sourceObjects.get(sourceObjectIds.get(index));
            SObject targetObject = targetObjects.get(index);
            returnedObjects.add(this.mapRecord(sourceObject, targetObject));
        }
        return returnedObjects;
    }

    /**
     * map single record
     * @param SObject      sourceObjectId
     * @param SObject      targetObject
     * @returns SObject
     */
    protected virtual SObject mapRecord(SObject sourceObject, SObject targetObject) {
        return targetObject;
    }

    /**
     * query source object
     * @param Id      sourceObjectId
     * @returns SObject
     */
    protected SObject querySourceObject(Id sourceObjectId) {
        return this.querySourceObjects(new Set<Id> { sourceObjectId }).values().get(0);
    }

    /**
     * query source objects
     * @param Set<Id>       sourceObjectIds
     * @returns Map<Id, SObject>
     */
    protected Map<Id, SObject> querySourceObjects(Set<Id> sourceObjectIds) {
        Id sourceObjectId = (new List<Id>(sourceObjectIds)).get(0);
        Map<Id, SObject> sourceObjects = new Map<Id, SObject>();
        for(SObject thisObject : Database.query(
                                    'SELECT ' +
                                        String.join(this.getSourceFields(), ', ') + ' ' +
                                    'FROM ' +
                                        sourceObjectId.getSObjectType().getDescribe().getName() + ' ' +
                                    'WHERE ' +
                                        'Id IN :sourceObjectIds'
                                )) {
            sourceObjects.put((Id)thisObject.get('Id'), thisObject);
        }
        return sourceObjects;
    }

    /**
     * get source fields to query
     * @returns List<String>
     */
    protected virtual List<String> getSourceFields() {
        Set<String> fields = new Set<String> {'Id'};
        return new List<String>(fields);
    }

    /**
     * get field value
     * @param SObject       sObj
     * @param String       sourceField
     * @returns Object
     */
    protected Object getFieldValue(SObject sObj, String sourceField) {
        SObject sObjectOfSourceField = sObj;
        List<String> relationshipAPINames = sourceField.split('\\.');
        Integer sourceFieldAPINameIndex = relationshipAPINames.size() - 1;
        String sourceFieldAPIName = relationshipAPINames.get(sourceFieldAPINameIndex);
        relationshipAPINames.remove(sourceFieldAPINameIndex);
        for(String relationshipAPIName : relationshipAPINames) {
            if(sObjectOfSourceField != null) {
                sObjectOfSourceField = sObjectOfSourceField.getSObject(relationshipAPIName);
            }
        }
        return (sObjectOfSourceField != null ? sObjectOfSourceField.get(sourceFieldAPIName) : null);
    }
}