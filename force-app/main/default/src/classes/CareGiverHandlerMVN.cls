/**
 * @author      Mavens
 * @group       CareGiverHandlerMVN
 * @description Exposes Invokable method for use in flow
 */
public with sharing class CareGiverHandlerMVN {

    @TestVisible
    private class CareGiverHandlerMVNException extends Exception {}

    @TestVisible
    private static string CAREGIVER_ROLE_NAME = 'Caregiver';
    /*
     * @description Creates a caregiver account if necessary and sets the care plan primary contact
     * @parameter   List<Id> - care plan ids
     */
    @InvocableMethod(
        label='Create Caregiver and Set Primary Contact'
        description='Creates a caregiver account if necessary and sets the care plan primary contact'
        category='Case'
    )
    public static void createCareGivers(List<Id> carePlanIds) {

        List<Case> newCarePlans = getNewCarePlans(carePlanIds);

        // get the care giver account record type id
        Id careGiverRecTypeId = SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('PJN_Caregiver')
            .getRecordTypeId();

        // store the new caregivers that need to be created mapped to the care plan to link them to
        Map<Id, Account> careGiversByCarePlan = new Map<Id, Account>();

        for (Case carePlan : newCarePlans) {
            //default primary contact to main account
            carePlan.Primary_Contact_MVN__c = carePlan.AccountId;

            if (String.isNotBlank(carePlan.Account.Caregiver_Last_Name_on_Conversion_MVN__c)) {
                // prepare the caregiver account
                careGiversByCarePlan.put(
                    carePlan.Id,
                    new Account(
                        RecordTypeId = careGiverRecTypeId,
                        FirstName = carePlan.Account.Caregiver_First_Name_on_Conversion_MVN__c,
                        LastName = carePlan.Account.Caregiver_Last_Name_on_Conversion_MVN__c,
                        HealthCloudGA__Gender__pc = carePlan.Account.Caregiver_Gender_on_Conversion_MVN__c
                    )
                );
            }
        }

        if (!careGiversByCarePlan.isEmpty()) {
            // create care givers and then query for their person contact id
            insert careGiversByCarePlan.values();
            Map<Id, Account> careGiversMap = new Map<Id, Account>([
                SELECT Id, PersonContactId FROM Account WHERE Id IN :careGiversByCarePlan.values()
            ]);

            // query fo the caregiver case team role
            List<CaseTeamRole> caseTeamRoles = [SELECT Id FROM CaseTeamRole WHERE Name = :CAREGIVER_ROLE_NAME];
            if (caseTeamRoles.isEmpty()) {
                throw new CareGiverHandlerMVNException('Missing Case Team Role : Caregiver');
            }
            Id caregiverCaseTeamRoleId = caseTeamRoles[0].Id;

            List<CaseTeamMember> caseTeamMembers = new List<CaseTeamMember>();
            for (Case carePlan : newCarePlans) {
                if (careGiversByCarePlan.containsKey(carePlan.Id)) {
                    Id careGiverId = careGiversByCarePlan.get(carePlan.Id).Id;
                    if (carePlan.Account.Caregiver_Primary_on_Conversion_MVN__c == 'Yes') {
                        // set the primary to the care giver
                        carePlan.Primary_Contact_MVN__c = careGiverId;
                    }
                    //create the case team member
                    caseTeamMembers.add(
                        new CaseTeamMember(
                            ParentId = carePlan.Id,
                            MemberId = careGiversMap.get(careGiverId).PersonContactId,
                            TeamRoleId = caregiverCaseTeamRoleId
                        )
                    );
                }
            }
            insert caseTeamMembers;
        }
        update newCarePlans;
    }

     /*
     * query for new care plans and stamped data on the parnt account
     */
    private static List<Case> getNewCarePlans(List<Id> carePlanIds) {
       return [
            SELECT
                Id,
                AccountId,
                Account.Caregiver_Primary_on_Conversion_MVN__c,
                Account.Caregiver_First_Name_on_Conversion_MVN__c,
                Account.Caregiver_Last_Name_on_Conversion_MVN__c,
                Account.Caregiver_Gender_on_Conversion_MVN__c,
                Primary_Contact_MVN__c
            FROM
                Case
            WHERE
                Id IN :carePlanIds
        ];
    }
}