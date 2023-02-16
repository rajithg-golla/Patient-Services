/**
 * @author      Mavens
 * @group       MappingEngine
 * @description queue query
 */
public with sharing class PJN_QueueQuery {
    /**
     * query queue by developer name
     * @param String       developerName
     * @returns Group
     */
    public Group queryByDeveloperName(String developerName) {
        return [
            SELECT
                Id
            FROM
                Group
            WHERE
                DeveloperName = :developerName
        ];
    }
}