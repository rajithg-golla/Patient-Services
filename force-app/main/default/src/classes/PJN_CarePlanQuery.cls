/**
 * @author      Mavens
 * @group       CarePlan
 * @description CarePlan Queries
 */
public without sharing class PJN_CarePlanQuery {
    /**
     * fields to query
     */
    public static Set<String> fields = new Set<String>{
        'Id',
        'OwnerId',
        'PJN_Program_DeveloperName__c',
        'AccountId',
        'PJN_Care_Plan_Start_Status__c',
        'PJN_Program_Start_Problem__c'
    };

    public static Case queryById(Id carePlanId) {
        return queryByIds(new Set<Id> {carePlanId}).get(carePlanId);
    }

    /**
     * query care plan by ids
     * @param   Set<Id>       carePlanIds
     * @returns  Map<Id, Case>
     */
    public static Map<Id, Case> queryByIds(Set<Id> carePlanIds) {
        return new Map<Id, Case>(
            (List<Case>) Database.query(
                'SELECT ' +
                    String.join(new List<String>(fields), ', ') + ', ' +
                    '( '+
                        'SELECT ' +
                            String.join(new List<String>(PJN_CarePlanProblemQuery.fields), ', ') + ' ' +
                        'FROM ' +
                            'HealthCloudGA__CarePlanProblems__r ' +
                        'ORDER BY ' +
                            'HealthCloudGA__SortOrder__c ASC NULLS LAST' +
                    '), '+
                    '( '+
                        'SELECT ' +
                            String.join(new List<String>(PJN_CarePlanCaseQuery.fields), ', ') + ' ' +
                        'FROM ' +
                            'Cases' +
                    ') '+
                'FROM ' +
                    'Case ' +
                'WHERE ' +
                    'Id IN :carePlanIds'
            )
        );
    }
}