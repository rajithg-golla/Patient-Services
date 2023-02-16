public interface PJN_MappingEngineHdlrIntf {
    void useMapping(PJN_Mapping__mdt mapping);
    SObject mapRecord(Id sourceObjectId, SObject targetObject);
    List<SObject> mapRecord(List<Id> sourceObjectIds, List<SObject> targetObjects);
}