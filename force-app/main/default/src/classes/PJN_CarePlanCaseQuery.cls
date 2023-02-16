/**
 * @author      Mavens
 * @group       CarePlan
 * @description CarePlan Case Queries
 */
public with sharing class PJN_CarePlanCaseQuery {
    /**
     * fields to query
     */
    public static Set<String> fields = new Set<String>{
        'Id',
        'Parent.PJN_Program_DeveloperName__c',
        'AccountId',
        'ParentId',
        'PJN_CarePlan_Problem__c',
        'PJN_CarePlan_Problem__r.PJN_Program_Problem_DeveloperName__c',
        'PJN_Program_Case_DeveloperName__c',
        'ClosedDate',
        'HealthCloudGA__DueDate__c',
        'Subject',
        'Status',
        'Owner.Name',
        'Owner.FirstName',
        'Owner.LastName',
        'IsClosed',
        'Parent.AccountId',
        'PJN_Activity_Timeline_Status__c'
    };

    /**
     * query care plan case by id
     * @param   Id       carePlanCaseId
     * @returns  Case
     */
    public static Case queryById(Id carePlanCaseId) {
        return Database.query(
            'SELECT ' +
                String.join(new List<String>(fields), ', ') + ' ' +
            'FROM ' +
                'Case ' +
            'WHERE ' +
                'Id = :carePlanCaseId'
        );
    }

    /**
     * query care plan case by ids
     * @param   Set<Id>       carePlanCaseIds
     * @returns  Case
     */
    public static Map<Id, Case> queryByIds(Set<Id> carePlanCaseIds) {
        Map<Id, Case> caseMap = new Map<Id, Case>();
        for(Case thisCase : Database.query(
                                'SELECT ' +
                                    String.join(new List<String>(fields), ', ') + ' ' +
                                'FROM ' +
                                    'Case ' +
                                'WHERE ' +
                                    'Id IN :carePlanCaseIds'
                            )) {
            caseMap.put(thisCase.Id, thisCase);
        }
        return caseMap;
    }

    /**
     * query care plan cases by problem
     * @param   Id       carePlanProblemId
     * @returns  List<Case>
     */
    public static List<Case> queryCasesByProblem(Id carePlanProblemId) {
        return Database.query(
            'SELECT ' +
                String.join(new List<String>(fields), ', ') + ' ' +
            'FROM ' +
                'Case ' +
            'WHERE ' +
                'PJN_CarePlan_Problem__c = :carePlanProblemId ' +
            'ORDER BY ' +
                'ClosedDate NULLS LAST, HealthCloudGA__DueDate__c NULLS LAST'
        );
    }

    /**
     * query care plan cases by problem
     * @param   Id       carePlanProblemId
     * @returns  List<Case>
     */
    public static List<Case> queryCasesByCarePlan(Id carePlanId) {
        return Database.query(
            'SELECT ' +
                String.join(new List<String>(fields), ', ') + ' ' +
            'FROM ' +
                'Case ' +
            'WHERE ' +
                'PJN_CarePlan_Problem__c = null ' +
            'AND ' +
                'ParentId = :carePlanId ' +
            'ORDER BY ' +
                'ClosedDate NULLS LAST, HealthCloudGA__DueDate__c NULLS LAST'
        );
    }

    /**
     * query open care plan cases by problem
     * @param   Id       carePlanProblemId
     * @returns  List<Case>
     */
    public static List<Case> queryOpenCasesByProblem(Id carePlanProblemId) {
        return Database.query(
            'SELECT ' +
                String.join(new List<String>(fields), ', ') + ' ' +
            'FROM ' +
                'Case ' +
            'WHERE ' +
                'PJN_CarePlan_Problem__c = :carePlanProblemId ' +
            'AND ' +
                'IsClosed = false'
        );
    }
}