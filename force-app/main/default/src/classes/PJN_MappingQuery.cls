/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping query
 */
public with sharing class PJN_MappingQuery {
    static Map<String, List<PJN_Mapping__mdt>> mappingsByJobName;
    static Map<Id, List<PJN_Mapping_Field__mdt>> fieldMappingsByMappingId;

    /**
     * query mapping by mapping job name
     * @param String       jobName
     * @returns List<PJN_Mapping__mdt>
     */
    public List<PJN_Mapping__mdt> queryMappingsByJobName(String jobName) {
        if (mappingsByJobName == null) {
            mappingsByJobName = new Map<String, List<PJN_Mapping__mdt>>();
        }

        if (!mappingsByJobName.containsKey(jobName)) {
            List<PJN_Mapping__mdt> mappingsForJob = [
                SELECT
                    Id,
                    Label,
                    DeveloperName,
                    PJN_Mapping_Type__c,
                    PJN_Always_Runs__c,
                    PJN_Source_Object_Type_Name__c,
                    PJN_Source_Object_API_Name__c
                FROM
                    PJN_Mapping__mdt
                WHERE
                    PJN_Mapping_Job__r.DeveloperName = :jobName
            ];
            mappingsByJobName.put(jobName, mappingsForJob);
        }

        return mappingsByJobName.get(jobName);
    }
}