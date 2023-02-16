/**
 * @author      Mavens
 * @group       CarePlan
 * @description CarePlan Queries
 */
public with sharing class PJN_CarePlanProblemQuery {
    /**
     * fields to query
     */
    public static Set<String> fields = new Set<String>{
        'Id',
        'Name',
        'PJN_Status__c',
        'PJN_CarePlan_Path_Status__c',
        'PJN_Program_Problem_DeveloperName__c',
        'HealthCloudGA__CarePlan__r.PJN_Program_DeveloperName__c',
        'HealthCloudGA__CarePlan__r.AccountId',
        'HealthCloudGA__CarePlan__r.OwnerId',
        'HealthCloudGA__CarePlan__c',
        'HealthCloudGA__SortOrder__c'
    };

    /**
     * query care plan problem by id
     * @param   Id       carePlanProblemId
     * @returns  HealthCloudGA__CarePlanProblem__c
     */
    public static HealthCloudGA__CarePlanProblem__c queryById(Id carePlanProblemId) {
        return Database.query(
            'SELECT ' +
                String.join(new List<String>(fields), ', ') + ' ' +
            'FROM ' +
                'HealthCloudGA__CarePlanProblem__c ' +
            'WHERE ' +
                'Id = :carePlanProblemId'
        );
    }

    /**
     * query care plan problem by care plan id
     * @param   Id       carePlanId
     * @returns  List<HealthCloudGA__CarePlanProblem__c>
     */
    public static List<HealthCloudGA__CarePlanProblem__c> queryByCarePlanId(Id carePlanId) {
        return queryByCarePlanId(carePlanId, true);
    }

    /**
     * query care plan problem by care plan id
     * @param   Id       carePlanId
     * @param   Boolean   allCases
     * @returns  List<HealthCloudGA__CarePlanProblem__c>
     */
    public static List<HealthCloudGA__CarePlanProblem__c> queryByCarePlanId(Id carePlanId, Boolean allCases) {
        return Database.query(
            'SELECT ' +
                String.join(new List<String>(fields), ', ') + ', (' +
                    'SELECT ' +
                        String.join(new List<String>(PJN_CarePlanCaseQuery.fields), ', ') + ' ' +
                    'FROM ' +
                        'PJN_Cases__r ' +
                    + getOpenCasesWhereClause(allCases) +
                    'ORDER BY ' +
                        'ClosedDate NULLS LAST, HealthCloudGA__DueDate__c NULLS LAST' +
                ') '+
            'FROM ' +
                'HealthCloudGA__CarePlanProblem__c ' +
            'WHERE ' +
                'HealthCloudGA__CarePlan__c = :carePlanId ' +
            'ORDER BY ' +
                'HealthCloudGA__SortOrder__c ASC NULLS LAST, CreatedDate ASC '
        );
    }

    private static String getOpenCasesWhereClause(Boolean allCases) {
        if (allCases) {
            return '';
        }
        return 'WHERE IsClosed = false ';
    }
}