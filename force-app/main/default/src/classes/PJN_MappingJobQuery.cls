/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping job query
 */
public with sharing class PJN_MappingJobQuery {

    static Map<String, PJN_Mapping_Job__mdt> jobsByName;

    public PJN_Mapping_Job__mdt queryByJobName(String jobName) {
        if (jobsByName == null) {
            jobsByName = new Map<String, PJN_Mapping_Job__mdt>();
        }

        if (!jobsByName.containsKey(jobName)) {
            jobsByName.put(jobName,
                [
                    SELECT
                        Id,
                        Label,
                        DeveloperName,
                        PJN_Target_Object_API_Name__c
                    FROM
                        PJN_Mapping_Job__mdt
                    WHERE
                        DeveloperName = :jobName
                    AND
                        PJN_Is_Active__c = true
                ]
            );
        }

        return jobsByName.get(jobName);
    }
}