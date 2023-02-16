/**
 * @author      Mavens
 * @group       ApplyCarePlanTemplate
 * @description On case creation apply a care plan template if defined 
 */
public with sharing class ApplyCarePlanTemplateHdlrMVN {
   
    /*
     * List of all newly inserted Care Plans
     */
    private static List<Case> newCarePlans;

    /*
     * Map of Accounts related to the care plan, specifically to get to the PersonContactId
     */
    private static Map<Id, Account> carePlanAccountsById;

    /*
     * Set of Care Plan Template External Ids that will be queried for
     */
    private static Set<String> carePlanTemplateExtIds;

    /*
     * Map of Care plan templates that will be used
     */
    private static Map<String, HealthCloudGA__CarePlanTemplate__c> templatesByExtId;

    /*
     * Map of template tasks by goal Id
     */
    private static Map<Id, List<HealthCloudGA__CarePlanTemplateTask__c>> templateTasksByTemplateGoalId;

    /*
     * Map of Care Team Members by Role for each care plan
     */
    private static Map<Id, Map<String, Id>> teamMemberByRoleByCarePlan; 

    /*
     * Provides a method that a flow can invoke
     * Orchestrates the sequence of apply the care plan templates
     */
    @InvocableMethod(label='Apply Care Plan Template' description='Applys CarePlan Indicated in the Care Plan Template External Id' category='Case')
    public static void applyCarePlanTemplates(List<Id> carePlanIds) {
        newCarePlans = new List<Case>();
        carePlanAccountsById = new Map<Id, Account>();
        carePlanTemplateExtIds = new Set<String>();
        templatesByExtId = new Map<String, HealthCloudGA__CarePlanTemplate__c>();
        templateTasksByTemplateGoalId = new Map<Id, List<HealthCloudGA__CarePlanTemplateTask__c>>();
        teamMemberByRoleByCarePlan = new Map<Id, Map<String, Id>>();

        getNewCarePlans(carePlanIds);
        getCaseTeamMemberMaps();
        applyCarePlanTemplates();
    }

    /*
     * Determine all cases which need a care plan template applied; 
     * The field Care_Plan_Template_External_ID_MVN__c will indicate the external id of the template to apply
     */
    private static void getNewCarePlans(List<Id> carePlanIds) {
        Set<Id> carePlanAccountIds = new Set<Id>();

        newCarePlans = [
            SELECT 
                Id,
                AccountId,
                RecordTypeId,
                Care_Plan_Template_External_ID_MVN__c
            FROM
                Case
            WHERE
                Id IN :carePlanIds
        ];

        for (Case thisCase : newCarePlans) {
            if (String.isNotBlank(thisCase.Care_Plan_Template_External_ID_MVN__c)) {
                carePlanAccountIds.add(thisCase.AccountId);
                carePlanTemplateExtIds.add(thisCase.Care_Plan_Template_External_ID_MVN__c);
            }
        }

        carePlanAccountsById = new Map<Id, Account>([
            SELECT Id, PersonContactId 
            FROM Account 
            WHERE Id IN :carePlanAccountIds
        ]);
    }

    /*
     * For all new care plans figure out who is on the care team, mapped by role
     */
    private static void getCaseTeamMemberMaps() {
        List<CaseTeamMember> teamMembers = [
            SELECT MemberId, ParentId, TeamRole.Name FROM CaseTeamMember WHERE ParentId IN :newCarePlans
        ];

        for (CaseTeamMember teamMember : teamMembers) {
            if (!teamMemberByRoleByCarePlan.containsKey(teamMember.ParentId)) {
                teamMemberByRoleByCarePlan.put(teamMember.ParentId, new Map<String, Id>());
            }
            teamMemberByRoleByCarePlan.get(teamMember.ParentId).put(teamMember.TeamRole.Name, teamMember.MemberId);
        }
    }

    /*
     * Apply the care plan templates for the cases
     */
    private static void applyCarePlanTemplates() {
        setupTemplatesAndTasks();

        List<HealthCloudGA__CarePlanGoal__c> newGoals = new List<HealthCloudGA__CarePlanGoal__c>();
        List<Task> newTasks = new List<Task>();

        for (Case carePlan : newCarePlans) {
            if (!templatesByExtId.containsKey(carePlan.Care_Plan_Template_External_ID_MVN__c)) {
                continue;
            }
            HealthCloudGA__CarePlanTemplate__c template = templatesByExtId.get(carePlan.Care_Plan_Template_External_ID_MVN__c);
            Map<String, Id> caseTeamMembers = teamMemberByRoleByCarePlan.get(carePlan.Id);

            Id carePlanTaskId = SObjectType.Task
                .getRecordTypeInfosByDeveloperName()
                .get('CarePlanTask')
                .getRecordTypeId();

            for (HealthCloudGA__CarePlanTemplateGoal__c templateGoal : template.HealthCloudGA__Care_Plan_Template_Goals__r) {
                HealthCloudGA__CarePlanGoal__c goal = new HealthCloudGA__CarePlanGoal__c(
                    Name = templateGoal.Name,
                    HealthCloudGA__CarePlan__c = carePlan.Id,
                    HealthCloudGA__CarePlanTemplate__c = template.Id,
                    HealthCloudGA__Category__c = templateGoal.HealthCloudGA__Category__c,
                    HealthCloudGA__Description__c = templateGoal.HealthCloudGA__Description__c,
                    HealthCloudGA__Priority__c = templateGoal.HealthCloudGA__Priority__c,
                    HealthCloudGA__SortOrder__c = templateGoal.HealthCloudGA__SortOrder__c,
                    Insert_Foreign_Key__c = '' + carePlan.Id + templateGoal.Id
                );

                newGoals.add(goal);

                if (templateTasksByTemplateGoalId.containsKey(templateGoal.Id)) {
                    List<HealthCloudGA__CarePlanTemplateTask__c> taskTemplates = templateTasksByTemplateGoalId.get(templateGoal.Id);
                    for (HealthCloudGA__CarePlanTemplateTask__c taskTemplate : taskTemplates) {
                        Id assignedToId = UserInfo.getUserId();
                        if (String.isNotBlank(taskTemplate.HealthCloudGA__AssignedTo__c)
                            && caseTeamMembers != null
                            && caseTeamMembers.containsKey(taskTemplate.HealthCloudGA__AssignedTo__c)
                        ) {
                            assignedToId = caseTeamMembers.get(taskTemplate.HealthCloudGA__AssignedTo__c);
                        }

                        Integer taskDayToDue = 0;
                        if (taskTemplate.HealthCloudGA__Offset__c != null) {
                            taskDayToDue = Integer.valueOf(taskTemplate.HealthCloudGA__Offset__c);
                        }

                        Id whoId = null;
                        if (carePlanAccountsById.containsKey(carePlan.AccountId)) {
                            whoId = carePlanAccountsById.get(carePlan.AccountId).PersonContactId;
                        }
                        newTasks.add(
                            new Task(
                                WhoId = whoId,
                                WhatId = carePlan.id,
                                OwnerId = assignedToId,
                                Subject = taskTemplate.HealthCloudGA__Subject__c,
                                Description = taskTemplate.HealthCloudGA__Description__c,
                                ActivityDate = Date.today().addDays(taskDayToDue),
                                HealthCloudGA__CarePlanGoal__r = new HealthCloudGA__CarePlanGoal__c(
                                    Insert_Foreign_Key__c = goal.Insert_Foreign_Key__c
                                ),
                                HealthCloudGA__CarePlanTemplate__c = template.Id,
                                HealthCloudGA__SortOrder__c = taskTemplate.HealthCloudGA__SortOrder__c,
                                HealthCloudGA__TaskType__c = taskTemplate.HealthCloudGA__Type__c,                
                                RecordTypeId = carePlanTaskId,
                                Priority = taskTemplate.HealthCloudGA__Priority__c,
                                Status = taskTemplate.HealthCloudGA__Status__c,
                                Survey_MVN__c = taskTemplate.Survey_MVN__c                                                          
                            )
                        );
                    }
                }
            }
        }

        insert newGoals;
        insert newTasks;
    }

     /*
     * Prepare the Care plan templates by querying for data and setting up maps corectly
     */
    private static void setupTemplatesAndTasks() {
        if (carePlanTemplateExtIds.isEmpty()) {
            return;
        }

        List<HealthCloudGA__CarePlanTemplate__c> templates = [
            SELECT
                Id,
                External_ID_MVN__c,
                (
                    SELECT
                        Id,
                        Name,
                        HealthCloudGA__Category__c,
                        HealthCloudGA__Description__c,
                        External_ID_MVN__c,
                        HealthCloudGA__Priority__c,
                        HealthCloudGA__SortOrder__c
                    FROM
                        HealthCloudGA__Care_Plan_Template_Goals__r
                    WHERE
                        HealthCloudGA__Active__c = true
                )
            FROM
                HealthCloudGA__CarePlanTemplate__c
            WHERE
                External_ID_MVN__c IN :carePlanTemplateExtIds
        ];

        Set<Id> goalIds = new Set<Id>();
        for (HealthCloudGA__CarePlanTemplate__c template : templates) {
            templatesByExtId.put(template.External_ID_MVN__c, template);
            Map<Id, HealthCloudGA__CarePlanTemplateGoal__c> goals = new Map<Id, HealthCloudGA__CarePlanTemplateGoal__c>(
                template.HealthCloudGA__Care_Plan_Template_Goals__r
            );
            goalIds.addAll(goals.keySet());
        }

        if (goalIds.isEmpty()) {
            return;
        }

        List<HealthCloudGA__CarePlanTemplateTask__c> templateTasks = [
            SELECT
                Id,
                HealthCloudGA__AssignedTo__c,
                HealthCloudGA__CarePlanTemplateGoal__c,
                HealthCloudGA__Category__c,
                HealthCloudGA__Description__c,
                HealthCloudGA__Offset__c,
                HealthCloudGA__Priority__c,
                HealthCloudGA__SortOrder__c,
                HealthCloudGA__Status__c,
                HealthCloudGA__Subject__c,
                HealthCloudGA__Type__c,
                Survey_MVN__c         
            FROM
                HealthCloudGA__CarePlanTemplateTask__c
            WHERE
                HealthCloudGA__Active__c = true
            AND
                HealthCloudGA__CarePlanTemplateGoal__c IN :goalIds
        ];
        
        for (HealthCloudGA__CarePlanTemplateTask__c templateTask : templateTasks) {
            if (!templateTasksByTemplateGoalId.containsKey(templateTask.HealthCloudGA__CarePlanTemplateGoal__c)) {
                templateTasksByTemplateGoalId.put(
                    templateTask.HealthCloudGA__CarePlanTemplateGoal__c, 
                    new List<HealthCloudGA__CarePlanTemplateTask__c>()
                );
            }
            templateTasksByTemplateGoalId
                .get(templateTask.HealthCloudGA__CarePlanTemplateGoal__c)
                .add(templateTask);
        }
    }
}