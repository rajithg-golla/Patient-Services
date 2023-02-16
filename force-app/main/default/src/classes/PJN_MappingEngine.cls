/**
 * @author      Mavens
 * @group       MappingEngine
 * @description mapping engine tp map/stamp fields into a record
 * @example
PJN_MappingEngine thisMappingEngine = new PJN_MappingEngine();
thisMappingEngine.initiate('<job-name>');
thisMappingEngine.run(
    new Map<String, Id> {
        'careplan' => '<careplan-id>',
        'patient' => '<patient-id>',
        'careplanlabels' => '<careplan-id>'
    },
    '<target-record-id>'
);
 */
public with sharing class PJN_MappingEngine {
    /**
     * mapping job query
     */
    @testVisible private static PJN_MappingJobQuery mappingJobQuery = new PJN_MappingJobQuery();

    /**
     * mapping query
     */
    @testVisible private PJN_MappingQuery mappingQuery = new PJN_MappingQuery();

    /**
     * mapping job to be executed
     */
    @testVisible private PJN_Mapping_Job__mdt mappingJob;

    /**
     * field used for map
     */
    public String identifier = 'Id';


    /**
     * initiate the engine
     * @param jobName mapping job developer name
     */
    public void initiate(String jobName) {
        this.mappingJob = this.getMappingJobConfiguration(jobName);
    }

    /**
     * run mapping engine
     * @param   Map<String, Id>     sourceObjectIds
     * @param   SObject             targetObject
     * @returns   SObject
     */
    public SObject run(Map<String, Id> sourceObjectIds, SObject targetObject) {
        for(PJN_Mapping__mdt thisMapping : mappingQuery.queryMappingsByJobName(this.mappingJob.DeveloperName)) {
            Type classType = Type.forName(mappingTypes.get(thisMapping.PJN_Mapping_Type__c));
            if(classType != null) {
                if(sourceObjectIds.containsKey(thisMapping.PJN_Source_Object_Type_Name__c) || thisMapping.PJN_Always_Runs__c) {
                    PJN_MappingEngineHdlrIntf mappingHandler = (PJN_MappingEngineHdlrIntf) classType.newInstance();
                    mappingHandler.useMapping(thisMapping);
                    targetObject = mappingHandler.mapRecord(
                        sourceObjectIds.get(thisMapping.PJN_Source_Object_Type_Name__c),
                        targetObject
                    );
                }
            }
        }
        return targetObject;
    }

    /**
     * run mapping engine
     * @param   Map<String, Id>     sourceObjectIds
     * @param   SObject             targetObject
     * @returns   SObject
     */
    public Map<String, SObject> run(Map<String, List<Id>> sourceObjectIds, List<SObject> targetObjects) {
        for(PJN_Mapping__mdt thisMapping : mappingQuery.queryMappingsByJobName(this.mappingJob.DeveloperName)) {
            Type classType = Type.forName(mappingTypes.get(thisMapping.PJN_Mapping_Type__c));
            if(classType != null) {
                if(sourceObjectIds.containsKey(thisMapping.PJN_Source_Object_Type_Name__c) || thisMapping.PJN_Always_Runs__c) {
                    PJN_MappingEngineHdlrIntf mappingHandler = (PJN_MappingEngineHdlrIntf) classType.newInstance();
                    mappingHandler.useMapping(thisMapping);
                    if (sourceObjectIds.containsKey(thisMapping.PJN_Source_Object_Type_Name__c)) {
                        targetObjects = mappingHandler.mapRecord(
                            sourceObjectIds.get(thisMapping.PJN_Source_Object_Type_Name__c),
                            targetObjects
                        );
                    }
                }
            }
        }
        Map<String, SObject> targetObjectMap = new Map<String, SObject>();
        for(SObject thisSObject : targetObjects) {
            targetObjectMap.put(
                (String) thisSObject.get(this.identifier),
                thisSObject
            );
        }
        return targetObjectMap;
    }

    /**
     * get mapping job configuration or fail loud (each job that is called needs to be defined)
     * @param   String      jobName
     * @returns  PJN_Mapping_Job__mdt
     */
    private PJN_Mapping_Job__mdt getMappingJobConfiguration(String jobName) {
        PJN_Mapping_Job__mdt mappingJob;
        try {
            mappingJob = mappingJobQuery.queryByJobName(jobName);
        } catch(System.QueryException qE) {
            throw new PJN_MappingEngineException('Mapping Job ' + jobName + ' is not defined.');
        }
        return mappingJob;
    }

    /**
     * get mapping types and their handler classes
     * @returns  Map<String, String>
     */
    @TestVisible
    private static Map<String, String> mappingTypes {
        get {
            if (mappingTypes == null) {
                mappingTypes = new Map<String, String>();
                for(PJN_Mapping_Type__mdt thisMappingType : [SELECT DeveloperName, PJN_Mapping_Handler__c FROM PJN_Mapping_Type__mdt]) {
                    mappingTypes.put(thisMappingType.DeveloperName, thisMappingType.PJN_Mapping_Handler__c);
                }
            }
            return mappingTypes;
        }
        set;
    }
}