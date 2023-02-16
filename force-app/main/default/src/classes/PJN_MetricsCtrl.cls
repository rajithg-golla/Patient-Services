/*
 * @description Controller for the Metrics lighting web components
 * @author      Mavens
 * @Created     October 2019
 */
public with sharing class PJN_MetricsCtrl {

    //TODO: filter queries by care plan allowing some for metrics that apply to patient overall
    // OR only speciifically to the care plan of the patient

    @AuraEnabled (cacheable=true)
    public static List<PJN_Metric_Group__c> getMetricGroups() {
        return [
            SELECT
                Id,
                Name
            FROM
                PJN_Metric_Group__c
            WHERE
                PJN_Active__c = true
            ORDER BY
                Name ASC
        ];
    }

    @AuraEnabled (cacheable=true)
    public static Map<Id, Integer> getMetricCountsByGroup(Id patientId, Id carePlanId, Boolean showAllForCurrentPatient) {
        Set<String> fields = new Set<String> {
            'PJN_Metric_Type__r.PJN_Metric_Group__c groupId',
            'COUNT(Id) total'
        };

        String whereStatement = getPatientOrCarePlanFilter(patientId, carePlanId, showAllForCurrentPatient);

        String query = String.format (
            'SELECT {0} FROM {1} WHERE {2} GROUP BY PJN_Metric_Type__r.PJN_Metric_Group__c',
            new List<String> {
                String.join(new List<String>(fields), ','),
                PJN_Medical_History__c.sObjectType.getDescribe().getName(),
                whereStatement
            }
        );

        List<AggregateResult> results = Database.query(query);

        Map<Id, Integer> groupIdToMetricCount = new Map<Id, Integer>();
        for (AggregateResult result : results) {
            groupIdToMetricCount.put(
                (Id) result.get('groupId'),
                (Integer) result.get('total')
            );
        }

        return groupIdToMetricCount;
    }

    @AuraEnabled (cacheable=true)
    public static List<PJN_Metric_Type__c> getMetricTypes(Id groupId) {
        return [
            SELECT
                Id,
                Name,
                PJN_Description__c,
                PJN_Metric_Group__r.Name,
                PJN_Show_Trend__c
            FROM
                PJN_Metric_Type__c
            WHERE
                PJN_Metric_Group__c = :groupId
            AND
                PJN_Active__c = true
            ORDER BY
                Name ASC
        ];
    }

    @AuraEnabled (cacheable=true)
    public static PJN_Metric_Type__c getMetricTypeWithOptions(Id metricTypeId){
        return [
            SELECT
                Id,
                PJN_Type__c,
                PJN_Unit_of_Measure__c,
                (
                    SELECT
                        Id,
                        Name,
                        PJN_Value__c
                    FROM
                        PJN_Metric_Type_Options__r
                    ORDER BY
                        PJN_Order__c NULLS LAST
                )
            FROM
                PJN_Metric_Type__c
            WHERE
                Id = :metricTypeId
        ];
    }

     @AuraEnabled (cacheable=true)
    public static Map<Id, Integer> getMetricCountsByType(Id patientId, Id carePlanId, Id groupId, Boolean showAllForCurrentPatient) {
        Set<String> fields = new Set<String> {
            'PJN_Metric_Type__c groupId',
            'COUNT(Id) total'
        };

        String whereStatement = getPatientOrCarePlanFilter(patientId, carePlanId, showAllForCurrentPatient);

        whereStatement += ' AND PJN_Metric_Type__r.PJN_Metric_Group__c = :groupId';
        whereStatement += ' AND RecordType.DeveloperName = \'PJN_Metric\'';

        String query = String.format (
            'SELECT {0} FROM {1} WHERE {2} GROUP BY PJN_Metric_Type__c',
            new List<String> {
                String.join(new List<String>(fields), ','),
                PJN_Medical_History__c.sObjectType.getDescribe().getName(),
                whereStatement
            }
        );

        List<AggregateResult> results = Database.query(query);

        Map<Id, Integer> typeIdToMetricCount = new Map<Id, Integer>();
        for (AggregateResult result : results) {
            typeIdToMetricCount.put(
                (Id) result.get('groupId'),
                (Integer) result.get('total')
            );
        }

        return typeIdToMetricCount;
    }

    @AuraEnabled (cacheable=true)
    public static List<PJN_Medical_History__c> getMetrics(Id patientId, Id carePlanId, Id typeId, Boolean showAllForCurrentPatient) {
        Set<String> fields = new Set<String> {
            'Id',
            'PJN_Date__c',
            'PJN_Value__c'
        };

        String whereStatement = getPatientOrCarePlanFilter(patientId, carePlanId, showAllForCurrentPatient);

        whereStatement += ' AND PJN_Metric_Type__c = :typeId';
        whereStatement += ' AND RecordType.DeveloperName = \'PJN_Metric\'';

        String query = String.format (
            'SELECT {0} FROM {1} WHERE {2} ORDER BY PJN_Date__c DESC, CreatedDate DESC',
            new List<String> {
                String.join(new List<String>(fields), ','),
                PJN_Medical_History__c.sObjectType.getDescribe().getName(),
                whereStatement
            }
        );

        return Database.query(query);
    }

    @AuraEnabled (cacheable=true)
    public static List<PJN_Medical_History__c> getGroupSummary(Id patientId, Id carePlanId, Id groupId, Boolean showAllForCurrentPatient){
        Set<String> fields = new Set<String> {
            'Id',
            'PJN_Metric_Type__r.PJN_Description__c',
            'PJN_Metric_Type__c',
            'PJN_Date__c',
            'PJN_Value__c'
        };

        String whereStatement = getPatientOrCarePlanFilter(patientId, carePlanId, showAllForCurrentPatient);

        whereStatement += ' AND PJN_Metric_Type__r.PJN_Metric_Group__c = :groupId';
        whereStatement += ' AND RecordType.DeveloperName = \'PJN_Metric\'';

        String query = String.format (
            'SELECT {0} FROM {1} WHERE {2} ORDER BY PJN_Date__c DESC, CreatedDate DESC',
            new List<String> {
                String.join(new List<String>(fields), ','),
                PJN_Medical_History__c.sObjectType.getDescribe().getName(),
                whereStatement
            }
        );

        List<PJN_Medical_History__c> medHistories = Database.query(query);

        Map<Id, PJN_Medical_History__c> latestMetricByType = new Map<Id, PJN_Medical_History__c>();
        for (PJN_Medical_History__c medHistory : medHistories) {
            if (!latestMetricByType.containsKey(medHistory.PJN_Metric_Type__c)) {
                latestMetricByType.put(medHistory.PJN_Metric_Type__c, medHistory);
            }
        }

        return latestMetricByType.values();
    }

    private static String getPatientOrCarePlanFilter(Id patientId, Id carePlanId, Boolean showAllForCurrentPatient) {
        return showAllForCurrentPatient ?
            'PJN_Patient__c = :patientId' :
            'PJN_Care_Plan__c = :carePlanId';
    }
}