/**
 * @author      Mavens
 * @group       MissingInformation
 * @description Missing Information Config Queries
 */
public with sharing class PJN_MissingInformationConfigQuery {

    /**
     * CACHE Missing Information Config
     */
    private Map<String, List<PJN_Missing_Information_Config__mdt>> missingInfoConfigsByProgramName;

    /**
     * Query Missing Information Config by Program Case Developer Name
     * @param programCaseDeveloperName  Program Case Developer Name
     * @return  `List<PJN_Missing_Information_Config__mdt>`
     */
    public List<PJN_Missing_Information_Config__mdt> queryMissingInfoConfigsByProgramName(String programCaseDeveloperName) {
        if (missingInfoConfigsByProgramName == null) {
            missingInfoConfigsByProgramName = new  Map<String, List<PJN_Missing_Information_Config__mdt>>();
        }
        if (!missingInfoConfigsByProgramName.containsKey(programCaseDeveloperName)) {
            for (PJN_Missing_Information_Config__mdt missingInfoConfig : queryAllMissingInfoConfigs()) {
                List<PJN_Missing_Information_Config__mdt> currentMICs = missingInfoConfigsByProgramName.containsKey(missingInfoConfig.PJN_Program__r.DeveloperName) ?
                    missingInfoConfigsByProgramName.get(missingInfoConfig.PJN_Program__r.DeveloperName) :
                    new List<PJN_Missing_Information_Config__mdt>();
                currentMICs.add(missingInfoConfig);
                missingInfoConfigsByProgramName.put(missingInfoConfig.PJN_Program__r.DeveloperName, currentMICs);
            }
        }
        return missingInfoConfigsByProgramName.containsKey(programCaseDeveloperName) ?
            missingInfoConfigsByProgramName.get(programCaseDeveloperName) :
            new List<PJN_Missing_Information_Config__mdt>();
    }

    /**
     * Query All Missing Information Configs
     * @return  `List<PJN_Missing_Information_Config__mdt>`
     */
    private static List<PJN_Missing_Information_Config__mdt> queryAllMissingInfoConfigs() {
        return [
            SELECT
                Id,
                DeveloperName,
                MasterLabel,
                PJN_Program__c,
                PJN_Program__r.DeveloperName,
                PJN_Field_Path__c
            FROM
                PJN_Missing_Information_Config__mdt
        ];
    }
}