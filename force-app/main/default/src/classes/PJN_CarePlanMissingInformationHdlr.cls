/**
 * @author      Mavens
 * @group       MissingInformation
 * @description Trigger handler to open the Missing Information stage and activity case associated to it
 *              when at least one or more of the fields defined in the PJN_Missing_Information_Config__mdt object are not filled.
 *              This needs a CarePlan with PJN_Enrollment_Completed__c changing from null to a value.
 */
public with sharing class PJN_CarePlanMissingInformationHdlr implements PJN_TriggerDispatcher.HandlerInterface {

    /**
     * Care Plan Record Type Id
     */
    private static final Id CAREPLAN_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId();

    /**
     * Care Plan Standard Fields
     */
    private static final Set<String> CAREPLAN_STD_FIELDS = new Set<String> {
        'Id',
        'PJN_Program__c',
        'PJN_Program__r.PJN_Program_DeveloperName__c',
        'OwnerId'
    };

    /**
     * Program Problem metadata records query class
     */
    @TestVisible
    private static PJN_ProgramProblemQuery programProblemQuery = new PJN_ProgramProblemQuery();

    /**
     * Missing Information Config metadata records query class
     */
    @TestVisible
    private static PJN_MissingInformationConfigQuery missingInformationQuery = new PJN_MissingInformationConfigQuery();

    /**
     * Trigger handler which will create the stage and activity if matches the criteria
     */
    public void handle() {
        if (Trigger.isAfter && Trigger.isUpdate) {
            List<Case> carePlans = getCarePlansToVerify();
            carePlans = getCarePlansWithMissingInfoFieldsToVerify(carePlans);
            List<Case> missingInfoCarePlans = getMissingInfoCarePlans(carePlans);
            initMissingInfoStage(missingInfoCarePlans);
        }
    }

    /**
     * Gets the CarePlans to verify when those match the criteria for the CarePlan
     * @return  `List<Case>`
     */
    private List<Case> getCarePlansToVerify() {
        List<Case> carePlans = new List<Case>();
        for (Case carePlan : (List<Case>) Trigger.new) {
            Case oldCarePlan = (Case) Trigger.oldMap.get(carePlan.Id);
            Boolean isValidToVerify = carePlan.RecordTypeId == CAREPLAN_RECORD_TYPE_ID
                && carePlan.PJN_Enrollment_Completed__c
                && !oldCarePlan.PJN_Enrollment_Completed__c;
            if (isValidToVerify) {
                carePlans.add(carePlan);
            }
        }
        return carePlans;
    }

    /**
     * Get CarePlans queried with the missing info fields which will be verified
     * @param carePlans List of Care Plans to query
     * @return  `List<Case>`
     */
    private List<Case> getCarePlansWithMissingInfoFieldsToVerify(List<Case> carePlans) {
        if (carePlans.isEmpty()) {
            return new List<Case>();
        }
        Set<String> missingInfoFields = getMissingInfoFields(carePlans);
        return queryCarePlansWithMissingInfoFieldsToVerify(carePlans, missingInfoFields);
    }

    /**
     * Get all missing info fields from metadata config.
     * The fields are obtained using the Care Plan Program.
     * @param carePlans List of CarePlans
     * @return  `Set<String>`
     */
    private Set<String> getMissingInfoFields(List<Case> carePlans) {
        Set<String> missingInfoFields = new Set<String>();
        Set<String> programVisited = new Set<String>();
        for (Case carePlan : getCarePlansWithProgramName(carePlans)) {
            if (carePlan.PJN_Program__c == null || programVisited.contains(carePlan.PJN_Program__r.PJN_Program_DeveloperName__c)) {
                continue;
            }
            for (PJN_Missing_Information_Config__mdt missingInfoConfig : missingInformationQuery.queryMissingInfoConfigsByProgramName(carePlan.PJN_Program__r.PJN_Program_DeveloperName__c)) {
                missingInfoFields.add(missingInfoConfig.PJN_Field_Path__c);
            }
            programVisited.add(carePlan.PJN_Program__r.PJN_Program_DeveloperName__c);
        }
        return missingInfoFields;
    }

    /**
     * Query CarePlans with the Program Name
     * @param carePlans List of care plans to query
     * @return  `List<Case>`
     */
    private List<Case> getCarePlansWithProgramName(List<Case> carePlans) {
        return [
            SELECT
                Id,
                PJN_Program__c,
                PJN_Program__r.PJN_Program_DeveloperName__c
            FROM
                Case
            WHERE
                Id IN :carePlans
        ];
    }

    /**
     * Query CarePlans with all missing info fields to verify
     * @param carePlans         List of care plans to query
     * @param missingInfoFields List of missing info fields to query
     * @return  `List<Case>`
     */
    private List<Case> queryCarePlansWithMissingInfoFieldsToVerify(List<Case> carePlans, Set<String> missingInfoFields) {
        missingInfoFields.addAll(CAREPLAN_STD_FIELDS);
        String fields = '';
        for (String field : missingInfoFields) {
            fields += field + ',';
        }
        fields = fields.substringBeforeLast(',');
        String query = 'SELECT ' + fields + ' FROM Case WHERE Id IN :carePlans';
        return (List<Case>) Database.query(query);
    }

    /**
     * Get Care Plans with missing info checking those fields depending on the careplan program and missing info fields
     * @param carePlans List of Care plans to verify missing info fields
     * @return  `List<Case>`
     */
    private List<Case> getMissingInfoCarePlans(List<Case> carePlans) {
        List<Case> missingCarePlans = new List<Case>();
        if (carePlans.isEmpty()) {
            return missingCarePlans;
        }
        for (Case carePlan : carePlans) {
            for (PJN_Missing_Information_Config__mdt missingInfoConfig : missingInformationQuery.queryMissingInfoConfigsByProgramName(carePlan.PJN_Program__r.PJN_Program_DeveloperName__c)) {
                Object carePlanFieldValue = getCarePlanFieldValue(carePlan, missingInfoConfig);
                if (carePlanFieldValue == null) {
                    missingCarePlans.add(carePlan);
                    break;
                }
            }
        }
        return missingCarePlans;
    }

    /**
     * Get Care Plan Field Value using missing Information Config metadata
     * @param carePlan          Care Plan record
     * @param missingInfoConfig Missing Information Config metadata
     * @return  `Object`
     */
    private Object getCarePlanFieldValue(Case carePlan, PJN_Missing_Information_Config__mdt missingInfoConfig) {
        Object carePlanFieldValue;
        if (missingInfoConfig.PJN_Field_Path__c.contains('.') && carePlan.getSObject(missingInfoConfig.PJN_Field_Path__c.substringBeforeLast('.')) != null) {
            carePlanFieldValue = carePlan.getSObject(missingInfoConfig.PJN_Field_Path__c.substringBeforeLast('.')).get(missingInfoConfig.PJN_Field_Path__c.substringAfterLast('.'));
        } else if (!missingInfoConfig.PJN_Field_Path__c.contains('.')) {
            carePlanFieldValue = carePlan.get(missingInfoConfig.PJN_Field_Path__c);
        }
        return carePlanFieldValue;
    }

    /**
     * Initialize the Missing Info Stage and Create Missing Info Activity to relate to the Care Plan
     * @param missingInfoCarePlans  List of Care Plans with missing information
     */
    private void initMissingInfoStage(List<Case> missingInfoCarePlans) {
        if (missingInfoCarePlans.isEmpty()) {
            return;
        }
        Map<String, List<Case>> carePlansByProgramDevName = getCarePlansByProgramDevName(missingInfoCarePlans);
        Map<Id, HealthCloudGA__CarePlanProblem__c> problemByCarePlanId = getProblemsByCarePlanId(carePlansByProgramDevName);
        List<HealthCloudGA__CarePlanProblem__c> problems = new List<HealthCloudGA__CarePlanProblem__c>();
        List<Case> activities = new List<Case>();
        for (Case missingCarePlan : missingInfoCarePlans) {
            HealthCloudGA__CarePlanProblem__c problem = problemByCarePlanId.get(missingCarePlan.Id);
            if (problem == null) {
                continue;
            }
            PJN_CarePlanProblemHdlr problemHandler = new PJN_CarePlanProblemHdlr(problem);
            Map<HealthCloudGA__CarePlanProblem__c, List<PJN_Program_Case__mdt>> problemCaseMap = problemHandler.start(missingCarePlan);
            problem = new List<HealthCloudGA__CarePlanProblem__c>(problemCaseMap.keySet())[0];
            for (PJN_Program_Case__mdt newProgramCase : problemCaseMap.get(problem)) {
                PJN_CarePlanCaseHdlr handler = new PJN_CarePlanCaseHdlr(problem, newProgramCase);
                activities.add(handler.start());
            }
            problems.add(problem);
        }
        update problems;
        insert activities;
    }

    /**
     * Get List of Care Plans by Program Developer Name using the list of care plans with missing information
     * @param missingInfoCarePlans  List of Care Plans with missing information
     * @return  `Map<String, List<Case>>`
     */
    private Map<String, List<Case>> getCarePlansByProgramDevName(List<Case> missingInfoCarePlans) {
        Map<String, List<Case>> carePlansByProgramDevName = new Map<String, List<Case>>();
        for (Case missingInfoCarePlan : missingInfoCarePlans) {
            List<Case> currentCases = carePlansByProgramDevName.containsKey(missingInfoCarePlan.PJN_Program__r.PJN_Program_DeveloperName__c) ?
                carePlansByProgramDevName.get(missingInfoCarePlan.PJN_Program__r.PJN_Program_DeveloperName__c) :
                new List<Case>();
            currentCases.add(missingInfoCarePlan);
            carePlansByProgramDevName.put(missingInfoCarePlan.PJN_Program__r.PJN_Program_DeveloperName__c, currentCases);
        }
        return carePlansByProgramDevName;
    }

    /**
     * Get Care Plan Problems by Care Plan Id using the care plans to obtain them
     * @param carePlansByProgramDevName List of care plans by program developer name
     * @return  `Map<Id, HealthCloudGA__CarePlanProblem__c>`
     */
    private Map<Id, HealthCloudGA__CarePlanProblem__c> getProblemsByCarePlanId(Map<String, List<Case>> carePlansByProgramDevName) {
        List<HealthCloudGA__CarePlanProblem__c> problems = new List<HealthCloudGA__CarePlanProblem__c>();
        for (String programDevName : carePlansByProgramDevName.keySet()) {
            List<Case> currentCarePlans = carePlansByProgramDevName.get(programDevName);
            PJN_CarePlanProblemHdlr carePlanProblemHdlr = new PJN_CarePlanProblemHdlr(programProblemQuery.queryByDeveloperName(programDevName + '_MI_Stage'));
            problems.addAll(carePlanProblemHdlr.create(currentCarePlans));
        }
        insert problems;
        Map<Id, HealthCloudGA__CarePlanProblem__c> problemByCarePlanId = new Map<Id, HealthCloudGA__CarePlanProblem__c>();
        for (HealthCloudGA__CarePlanProblem__c problem : getProblemsQueried(problems)) {
            problemByCarePlanId.put(problem.HealthCloudGA__CarePlan__c, problem);
        }
        return problemByCarePlanId;
    }

    /**
     * Get Care Plan Problems queried using the actual list of care plan problems.
     * Method is used to obtain fields which don't have it before
     * @param problems  List of Care Plan Problems to query
     * @return  `List<HealthCloudGA__CarePlanProblem__c>`
     */
    private List<HealthCloudGA__CarePlanProblem__c> getProblemsQueried(List<HealthCloudGA__CarePlanProblem__c> problems) {
        return [
            SELECT
                Id,
                PJN_Program_Problem_DeveloperName__c,
                HealthCloudGA__Account__c,
                HealthCloudGA__CarePlanTemplate__c,
                PJN_CarePlan_Path_Status__c,
                HealthCloudGA__CarePlan__c,
                HealthCloudGA__CarePlan__r.OwnerId,
                HealthCloudGA__CarePlan__r.AccountId,
                HealthCloudGA__CarePlan__r.PJN_Program_DeveloperName__c
            FROM
                HealthCloudGA__CarePlanProblem__c
            WHERE
                Id IN :problems
        ];
    }
}