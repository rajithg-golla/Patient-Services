/**
 * @author      Mavens
 * @group       ApplyCarePlanTemplate
 * @description Unit tests for ApplyCarePlanTemplateHdlrMVN
 */
@isTest(isParallel=true)
public class ApplyCarePlanTemplateHdlrTestMVN {
    
    private static final Integer DATA_SIZE = 200;

    @TestSetup
    static void makeData(){
        System.runAs(new User(Id=UserInfo.getUserId())) {
            List<CaseTeamRole> ctr = [SELECT Id FROM CaseTeamRole WHERE Name='Care Coordinator'];
            if (ctr.isEmpty()) {
                insert new CaseTeamRole(Name='Care Coordinator', AccessLevel='Edit');
            }
        }

        List<Account> programParticipants = new List<Account>();
        for (Integer i=0; i<DATA_SIZE; i++) {
            programParticipants.add(
                new Account(
                    LastName = 'Test Account' + i,
                    RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Program_Participant_MVN').getRecordTypeId()
                )
            );
        }
        insert programParticipants;

        insert new List<SObject> {
            new HealthCloudGA__CarePlanTemplate__c(
                Name = 'DEDSI - DR Negative/Not Yet Screened',
                HealthCloudGA__Active__c = true,
                HealthCloudGA__Category__c = null,
                HealthCloudGA__Description__c = 'Test Care Plan Template',
                External_ID_MVN__c = 'Test_CPT'
            ),

            new HealthCloudGA__CarePlanTemplateGoal__c (
                HealthCloudGA__Active__c = true,
                HealthCloudGA__CarePlanTemplate__r = new HealthCloudGA__CarePlanTemplate__c(
                    External_ID_MVN__c = 'Test_CPT' 
                ),
                HealthCloudGA__Description__c = 'Goal Description',
                HealthCloudGA__Priority__c = 'Medium',
                HealthCloudGA__SortOrder__c = 1,
                External_ID_MVN__c = 'Test_CPTGoal'
            ),

            new HealthCloudGA__CarePlanTemplateTask__c(
                HealthCloudGA__Active__c = true,
                HealthCloudGA__AssignedTo__c = 'Care Coordinator',
                HealthCloudGA__CarePlanTemplateGoal__r = new HealthCloudGA__CarePlanTemplateGoal__c (
                    External_ID_MVN__c = 'Test_CPTGoal'
                ),
                HealthCloudGA__Category__c = null,
                HealthCloudGA__Description__c = null,
                HealthCloudGA__Offset__c = 10,
                HealthCloudGA__Priority__c = 'Normal',
                HealthCloudGA__SortOrder__c = 1,
                HealthCloudGA__Status__c = 'Open',
                HealthCloudGA__Subject__c = 'Test Subject 1',
                HealthCloudGA__Type__c = 'Uncategorized',
                External_ID_MVN__c = 'Test_CPTTask1'
            ),

            new HealthCloudGA__CarePlanTemplateTask__c(
                HealthCloudGA__Active__c = true,
                HealthCloudGA__AssignedTo__c = 'Care Coordinator',
                HealthCloudGA__CarePlanTemplateGoal__r = new HealthCloudGA__CarePlanTemplateGoal__c (
                    External_ID_MVN__c = 'Test_CPTGoal'
                ),
                HealthCloudGA__Category__c = null,
                HealthCloudGA__Description__c = null,
                HealthCloudGA__Offset__c = 20,
                HealthCloudGA__Priority__c = 'Normal',
                HealthCloudGA__SortOrder__c = 2,
                HealthCloudGA__Status__c = 'Open',
                HealthCloudGA__Subject__c = 'Test Subject 2',
                HealthCloudGA__Type__c = 'Uncategorized',
                External_ID_MVN__c = 'Test_CPTTask2'
            )
        };
    }

    @isTest
    private static void itShouldApplyCarePlanTemplates() {
        List<Case> newCarePlans = createCarePlans('Test_CPT');
        insert newCarePlans;

        List<Id> newCarePlanIds = new List<Id>((new Map<Id, Case>(newCarePlans)).keySet());

        CaseTeamRole tr = [SELECT Id FROM CaseTeamRole WHERE Name ='Care Coordinator' LIMIT 1];
        List<CaseTeamMember> caseTeamMembers = new List<CaseTeamMember>();
        for (Case carePlan : newCarePlans) {
            caseTeamMembers.add(
                new caseTeamMember (
                    ParentId = carePlan.Id,
                    MemberId = UserInfo.getUserId(),
                    TeamRoleId=tr.Id
                )
            );
        }
        insert caseTeamMembers;

        Test.startTest();
        ApplyCarePlanTemplateHdlrMVN.applyCarePlanTemplates(newCarePlanIds);
        Test.stopTest();

        System.assertEquals(DATA_SIZE, [SELECT COUNT() FROM Case WHERE RecordType.DeveloperName = 'CarePlan']);
        HealthCloudGA__CarePlanGoal__c[] goals = [SELECT Id FROM HealthCloudGA__CarePlanGoal__c WHERE HealthCloudGA__CarePlan__c IN :newCarePlans];
        System.assertEquals(DATA_SIZE, goals.size());
        System.assertEquals(DATA_SIZE*2, [SELECT COUNT() FROM Task WHERE HealthCloudGA__CarePlanGoal__c IN :goals]);
    }

    @isTest
    private static void itShouldSkipApplicationOfCarePlanTemplateWhenTemplateDoesNotExist() {
        List<Case> newCarePlans = createCarePlans('Test_CPT_Bad_Value');
        insert newCarePlans;
        List<Id> newCarePlanIds = new List<Id>((new Map<Id, Case>(newCarePlans)).keySet());
        Test.startTest();
        ApplyCarePlanTemplateHdlrMVN.applyCarePlanTemplates(newCarePlanIds);
        Test.stopTest();

        System.assertEquals(DATA_SIZE, [SELECT COUNT() FROM Case WHERE RecordType.DeveloperName = 'CarePlan']);
        HealthCloudGA__CarePlanGoal__c[] goals = [SELECT Id FROM HealthCloudGA__CarePlanGoal__c WHERE HealthCloudGA__CarePlan__c IN :newCarePlans];
        System.assertEquals(0, goals.size());
    }

    @isTest
    private static void itShouldSkipApplicationOfCarePlanTemplateWhenNoneGiven() {
        List<Case> newCarePlans = createCarePlans('');
        insert newCarePlans;
        List<Id> newCarePlanIds = new List<Id>((new Map<Id, Case>(newCarePlans)).keySet());
        Test.startTest();
        ApplyCarePlanTemplateHdlrMVN.applyCarePlanTemplates(newCarePlanIds);
        Test.stopTest();

        System.assertEquals(DATA_SIZE, [SELECT COUNT() FROM Case WHERE RecordType.DeveloperName = 'CarePlan']);
        HealthCloudGA__CarePlanGoal__c[] goals = [SELECT Id FROM HealthCloudGA__CarePlanGoal__c WHERE HealthCloudGA__CarePlan__c IN :newCarePlans];
        System.assertEquals(0, goals.size());
    }


    private static List<Case> createCarePlans(String templateName) {
        List<Case> newCarePlans = new List<Case>();
        Id carePlanRecTypeId = SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('CarePlan')
            .getRecordTypeId();
        List<Account> programParticipants = [SELECT Id FROM Account];

        for (Account programParticipant : programParticipants) {
            newCarePlans.add(
                new Case (
                    // set the override so tests don't rely on configuration
                    Care_Plan_Template_Ext_ID_Override_MVN__c = templateName,
                    RecordTypeId = carePlanRecTypeId,
                    AccountId = programParticipant.Id
                )
            );
        }

        return newCarePlans;
    }
    
}