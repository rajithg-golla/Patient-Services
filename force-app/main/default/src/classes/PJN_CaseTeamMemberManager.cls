/**
 * @author Mavens
 * @date Jan 2019
 * @description Creates Case Team Members on the Care Plan based on fields (Patient, Physician,
 *              Staff, Caregiver) set on the child case.
 *              The configuration for case team members is defined on custom metadata
 *              PJN_Case_Field_Configuration__mdt.
 *              It also creates Contact-to-Contact relationships for HC.
 */
public without sharing class PJN_CaseTeamMemberManager {

    /**
    * @description Map of case fields to monitor to the roles they control for case team
    */
    private static List<PJN_Case_Field_Configuration__mdt> caseFieldToConfigMap {
        get {
            if (caseFieldToConfigMap == null) {
                return PJN_CaseFieldConfigurations.all;
            }
            return caseFieldToConfigMap;
        }
        private set;
    }

    /**
    * @description Map of case fields to monitor to the IDS of the roles they control for case team
    */
    private static Map<String, Set<Id>> caseFieldToRoleIdMap {
        get {
            if (caseFieldToRoleIdMap == null) {
                List<String> roles = new List<String>();
                for (PJN_Case_Field_Configuration__mdt config : caseFieldToConfigMap) {
                    roles.add(config.PJN_Case_Team_Role_Mapping__c);
                }
                List<CaseTeamRole> teamRoles = [
                    SELECT
                        Id,
                        Name
                    FROM
                        CaseTeamRole
                    WHERE
                        Name IN :roles
                ];

                Map<String, Id> roleNameToIdMap = new Map<String, Id>();
                for (CaseTeamRole teamRole : teamRoles) {
                    roleNameToIdMap.put(teamRole.Name, teamRole.Id);
                }

                caseFieldToRoleIdMap = new Map<String, Set<Id>>();
                for(PJN_Case_Field_Configuration__mdt config : caseFieldToConfigMap) {
                    String fieldName = config.PJN_Case_Field_API_Name__c;
                    Set<Id> roleIds = new Set<Id>();
                    if(caseFieldToRoleIdMap.containsKey(fieldName)) {
                        roleIds = caseFieldToRoleIdMap.get(fieldName);
                    }
                    roleIds.add(roleNameToIdMap.get(config.PJN_Case_Team_Role_Mapping__c));
                    caseFieldToRoleIdMap.put(
                        fieldName,
                        roleIds
                    );
                }
            }
            return caseFieldToRoleIdMap;
        }
        private set;
    }

    /**
     * Create Case Team Members on the Care Plan as long as that member is not already there.
     * It receives a list of child cases and case team members will be created against the parents
     * (Care Plans) of those child cases.
     * It also creates HC Contact-to-Contact relationships.
     * @param  caseList list of child cases
     */
    public static void createTeamMembersAndContactRelationships(List<Case> caseList) {
        Map<Id, List<CaseTeamMember>> caseTeamMembersParentMap = getCaseTeamMembersFromParent(caseList);
        Map<Id, Account> personAccounts = getPersonAccounts(caseList);
        Map<String, HealthCloudGA__ContactContactRelation__c> relationByContactIdMap = getExistingRelationships(caseList, personAccounts);
        Map<String, HealthCloudGA__ReciprocalRole__c> reciprocalRolesMap = getReciprocalRoles();

        Map<Id, CaseTeamMember> caseTeamMembersToInsertByMemberId = new Map<Id, CaseTeamMember>();
        List<HealthCloudGA__ContactContactRelation__c> contactContactRelation = new List<HealthCloudGA__ContactContactRelation__c>();
        List<AccountContactRelation> accountContactRelationshipsToInsert = new List<AccountContactRelation>();
        for (Case currentCase : caseList) {

            // Go through the different lookup fields defined in custom metadata (patient, Physician, etc)
            for(PJN_Case_Field_Configuration__mdt config : caseFieldToConfigMap) {
                String field = config.PJN_Case_Field_API_Name__c;
                System.debug('caseFieldToRoleIdMap::' + caseFieldToRoleIdMap);

                Id parentId = currentCase.ParentId;
                Id memberId = (Id) currentCase.get(field);

                System.debug('parentId::' + parentId);
                System.debug('memberId::' + memberId);

                for(Id teamRoleId : caseFieldToRoleIdMap.get(field)) {
                    System.debug('teamRoleId::' + teamRoleId);

                    if (memberId == null || memberId.getSObjectType() == (new Group()).getSObjectType()) {
                        continue;
                    }

                    String entityName = memberId.getSObjectType().getDescribe().getName();
                    Id personContactId = memberId;
                    if (memberId.getSObjectType() == (new Account()).getSObjectType()) {
                        Account acc = personAccounts.get(memberId);
                        if (acc.IsPersonAccount) {
                            personContactId = personAccounts.get(memberId).PersonContactId;
                        } else {
                            personContactId = personAccounts.get(memberId).OwnerId;
                        }
                    }
                    Boolean duplicated = false;
                    if (!caseTeamMembersParentMap.isEmpty()) {
                        List<CaseTeamMember> existingCaseTeamMembers = caseTeamMembersParentMap.containsKey(parentId) ?
                            caseTeamMembersParentMap.get(parentId) :
                            new List<CaseTeamMember>();
                        for (CaseTeamMember existingCaseTeamMember : existingCaseTeamMembers) {
                            if (existingCaseTeamMember.MemberId == personContactId) {
                                duplicated = true;
                                break;
                            }
                        }
                    }

                    if (teamRoleId != null &&
                            !duplicated &&
                            (!caseTeamMembersToInsertByMemberId.containsKey(personContactId)
                            ||
                            caseTeamMembersToInsertByMemberId.get(personContactId).ParentId != parentId)) {
                        caseTeamMembersToInsertByMemberId.put(
                            personContactId,
                            new CaseTeamMember(
                                ParentId = parentId,
                                MemberId = personContactId,
                                TeamRoleId = teamRoleId
                            )
                        );
                    }
                }

                System.debug('config::' + config);
                // ContactContactRelation
                if (config.PJN_Reciprocal_Role_Case_Field__c != null && config.PJN_Reciprocal_Inverse_Role_Case_Field__c != null) {
                    Id HCRelationContact = (Id) currentCase.get(config.PJN_Reciprocal_Role_Case_Field__c);
                    Id HCRelationRelatedContact = (Id) currentCase.get(config.PJN_Reciprocal_Inverse_Role_Case_Field__c);
                    If (HCRelationContact == null || HCRelationRelatedContact == null) {
                        continue;
                    }
                    Id HCRelationPersonContactId = personAccounts.get(HCRelationContact).PersonContactId;
                    Id HCRelationRelatedPersonContactId = personAccounts.get(HCRelationRelatedContact).PersonContactId;
                    if (!reciprocalRolesMap.containsKey(config.PJN_Reciprocal_Inverse_Role__c+config.PJN_Reciprocal_Role__c)) {
                        continue;
                    }
                    Id reciprocalRoleId = reciprocalRolesMap.get(config.PJN_Reciprocal_Inverse_Role__c+config.PJN_Reciprocal_Role__c).Id;
                    if (relationByContactIdMap.containsKey(String.valueOf(HCRelationPersonContactId)+String.valueOf(HCRelationRelatedPersonContactId)+String.valueOf(reciprocalRoleId))) {
                        continue;
                    }
                    contactContactRelation.add(
                        new HealthCloudGA__ContactContactRelation__c(
                            HealthCloudGA__Active__c = true,
                            HealthCloudGA__Contact__c = HCRelationPersonContactId,
                            HealthCloudGA__RelatedContact__c = HCRelationRelatedPersonContactId,
                            HealthCloudGA__Role__c = reciprocalRoleId
                        )
                    );
                }

                // AccountContactRelation
                if(String.isNotBlank(config.MVN_Account_Role_Mapping__c)
                        && config.MVN_Account_Role_Case_Field__c != null
                        && (Id) currentCase.get(config.MVN_Account_Role_Case_Field__c) != null) {
                    Id accountRoleCaseId = (Id) currentCase.get(config.MVN_Account_Role_Case_Field__c);
                    accountContactRelationshipsToInsert.add(
                        new AccountContactRelation(
                            AccountId = memberId,
                            ContactId = personAccounts.get(accountRoleCaseId).PersonContactId,
                            Roles = config.MVN_Account_Role_Mapping__c,
                            MVN_External_Id__c = memberId + '|' + personAccounts.get(accountRoleCaseId).PersonContactId
                        )
                    );
                }
            }
        }
        System.debug('caseTeamMembersToInsertByMemberId::' + caseTeamMembersToInsertByMemberId);
        System.debug('caseTeamMembersToInsertByMemberId::' + Database.insert(caseTeamMembersToInsertByMemberId.values(), false));
        System.debug('contactContactRelation::' + contactContactRelation);
        System.debug('contactContactRelation::' + Database.insert(contactContactRelation, false));
        System.debug('accountContactRelationshipsToInsert::' + accountContactRelationshipsToInsert);
        System.debug('accountContactRelationshipsToInsert::' + Database.upsert(accountContactRelationshipsToInsert, AccountContactRelation.MVN_External_Id__c, false));
    }

    /**
     * Get existing Case Team Members created against the Care Plan
     * @param  caseList List of child cases
     * @returns          Map of lists of case team members per id of the case having them
     */
    private static Map<Id, List<CaseTeamMember>> getCaseTeamMembersFromParent(List<Case> caseList) {

        Set<Id> parentIdSet = new Set<Id>();
        for (Case currentCase : caseList) {
            parentIdSet.add(currentCase.parentId);
        }

        List<CaseTeamMember> caseTeamMemberListFromParent = [
            SELECT
                MemberId,
                TeamRoleId,
                TeamTemplateId,
                TeamTemplateMemberId,
                ParentId
            FROM
                CaseTeamMember
            WHERE
                ParentId =: parentIdSet
        ];

        Map<Id, List<CaseTeamMember>> caseTeamMemberParentMap = new Map<Id, List<CaseTeamMember>>();
        for (CaseTeamMember currentCaseTeamMember : caseTeamMemberListFromParent) {
            if (!caseTeamMemberParentMap.containsKey(currentCaseTeamMember.ParentId)) {
                caseTeamMemberParentMap.put(currentCaseTeamMember.ParentId, new List<CaseTeamMember>());
            }
            caseTeamMemberParentMap.get(currentCaseTeamMember.ParentId).add(currentCaseTeamMember);
        }
        return caseTeamMemberParentMap;
    }

    /**
     * Get Person Accounts objects to use the personAccountId field when creating a case team member
     * @param  caseList list of child cases
     * @returns          Map of Accounts per account id
     */
    private static Map<Id, Account> getPersonAccounts(List<Case> caseList) {
        Set<Id> personAccountIds = new Set<Id>();
        for (Case currentCase : caseList) {
            for(PJN_Case_Field_Configuration__mdt config : caseFieldToConfigMap) {
                String field = config.PJN_Case_Field_API_Name__c;
                personAccountIds.add((Id) currentCase.get(field));
            }
        }

        Map<Id, Account> personAccounts = new Map<Id, Account>([
            SELECT
                Id,
                IsPersonAccount,
                PersonContactId,
                OwnerId
            FROM
                Account
            WHERE
                Id IN :personAccountIds
        ]);
        return personAccounts;
    }

    /**
     * getExistingRelationships  Get existing contact-to-contact relationships
     * @param  caseList       List of child cases
     * @param  personAccounts map of accounts by account id
     * @returns                map of contact-to-contact relationships by unique key
     */
    private static Map<String, HealthCloudGA__ContactContactRelation__c> getExistingRelationships(List<Case> caseList, Map<Id, Account> personAccounts) {
        Set<Id> contactIds = new Set<Id>();
        for (Case currentCase : caseList) {
            for(PJN_Case_Field_Configuration__mdt config : caseFieldToConfigMap) {
                String field = config.PJN_Case_Field_API_Name__c;
                if (config.PJN_Reciprocal_Role_Case_Field__c != null) {
                    Id HCRelationContact = (Id) currentCase.get(config.PJN_Reciprocal_Role_Case_Field__c);
                    if (HCRelationContact != null) {
                        contactIds.add(personAccounts.get(HCRelationContact).PersonContactId);
                    }
                }
            }
        }
        List<HealthCloudGA__ContactContactRelation__c> existingRelationships = [
            SELECT
                HealthCloudGA__Active__c,
                HealthCloudGA__Contact__c,
                HealthCloudGA__RelatedContact__c,
                HealthCloudGA__Role__c
            FROM
                HealthCloudGA__ContactContactRelation__c
            WHERE
                HealthCloudGA__Contact__c = :contactIds
        ];
        Map<String, HealthCloudGA__ContactContactRelation__c> relationByContactIdMap = new Map<String, HealthCloudGA__ContactContactRelation__c>();
        for (HealthCloudGA__ContactContactRelation__c relation : existingRelationships) {
            relationByContactIdMap.put(
                String.valueOf(relation.HealthCloudGA__Contact__c)+
                String.valueOf(relation.HealthCloudGA__RelatedContact__c)+
                String.valueOf(relation.HealthCloudGA__Role__c),
                relation
            );
        }
        return relationByContactIdMap;
    }

    /**
     * getReciprocalRoles get all existing HC reciprocal roles
     * @returns   map of HC reciprocal roles by unique key
     */
    private static Map<String, HealthCloudGA__ReciprocalRole__c> getReciprocalRoles() {
        Map<String, HealthCloudGA__ReciprocalRole__c> reciprocalRolesMap = new Map<String, HealthCloudGA__ReciprocalRole__c>();
        List<HealthCloudGA__ReciprocalRole__c> reciprocalRoles = [
            SELECT
                Id,
                Name,
                HealthCloudGA__InverseRole__c
            FROM
                HealthCloudGA__ReciprocalRole__c
        ];
        for (HealthCloudGA__ReciprocalRole__c reciprocalRole : reciprocalRoles){
            String key = reciprocalRole.Name + reciprocalRole.HealthCloudGA__InverseRole__c;
            if (!reciprocalRolesMap.containsKey(key)) {
                reciprocalRolesMap.put(key, reciprocalRole);
            }
        }
        return reciprocalRolesMap;
    }

    /**
     * Create Case Team Members on the Care Plan as long as that member is not already there.
     * It receives a list of child cases and case team members will be created against the parents
     * (Care Plans) of those child cases.
     * It also creates HC Contact-to-Contact relationships.
     * @param  caseList list of child cases
     */
    public static void createTeamMembersAndContactRelationshipsForCarePlanUpdate(List<Case> caseList) {
        Map<Id, Account> personAccounts = getPersonAccounts(caseList);
        Map<String, HealthCloudGA__ContactContactRelation__c> relationByContactIdMap = getExistingRelationships(caseList, personAccounts);
        Map<String, HealthCloudGA__ReciprocalRole__c> reciprocalRolesMap = getReciprocalRoles();

        Map<Id, CaseTeamMember> caseTeamMembersToInsertByMemberId = new Map<Id, CaseTeamMember>();
        List<HealthCloudGA__ContactContactRelation__c> contactContactRelation = new List<HealthCloudGA__ContactContactRelation__c>();
        List<AccountContactRelation> accountContactRelationshipsToInsert = new List<AccountContactRelation>();
        for (Case currentCase : caseList) {
            // Go through the different lookup fields defined in custom metadata (patient, Physician, etc)
            for(PJN_Case_Field_Configuration__mdt config : caseFieldToConfigMap) {
                String field = config.PJN_Case_Field_API_Name__c;
                Id memberId = (Id) currentCase.get(field);
                if (memberId == null || memberId.getSObjectType() == (new Group()).getSObjectType()) {
                    continue;
                }
                for(Id teamRoleId : caseFieldToRoleIdMap.get(field)) {
                    System.debug('teamRoleId::' + teamRoleId);
                    if (teamRoleId == null) {
                        continue;
                    }
                    String entityName = memberId.getSObjectType().getDescribe().getName();
                    Id personContactId = memberId;
                    if (memberId.getSObjectType() == (new Account()).getSObjectType()) {
                        Account acc = personAccounts.get(memberId);
                        if (acc.IsPersonAccount) {
                            personContactId = personAccounts.get(memberId).PersonContactId;
                        } else {
                            personContactId = personAccounts.get(memberId).OwnerId;
                        }
                    }

                    if (!caseTeamMembersToInsertByMemberId.containsKey(personContactId)) {

                        caseTeamMembersToInsertByMemberId.put(
                            personContactId,
                            new CaseTeamMember(
                                ParentId = currentCase.Id,
                                MemberId = personContactId,
                                TeamRoleId = teamRoleId
                            )
                        );
                    }
                }

                // ContactContactRelation
                if (config.PJN_Reciprocal_Role_Case_Field__c != null && config.PJN_Reciprocal_Inverse_Role_Case_Field__c != null) {
                    Id HCRelationContact = (Id) currentCase.get(config.PJN_Reciprocal_Role_Case_Field__c);
                    Id HCRelationRelatedContact = (Id) currentCase.get(config.PJN_Reciprocal_Inverse_Role_Case_Field__c);
                    If (HCRelationContact == null || HCRelationRelatedContact == null) {
                        continue;
                    }
                    Id HCRelationPersonContactId = personAccounts.get(HCRelationContact).PersonContactId;
                    Id HCRelationRelatedPersonContactId = personAccounts.get(HCRelationRelatedContact).PersonContactId;
                    if (!reciprocalRolesMap.containsKey(config.PJN_Reciprocal_Inverse_Role__c+config.PJN_Reciprocal_Role__c)) {
                        continue;
                    }
                    Id reciprocalRoleId = reciprocalRolesMap.get(config.PJN_Reciprocal_Inverse_Role__c+config.PJN_Reciprocal_Role__c).Id;
                    if (relationByContactIdMap.containsKey(String.valueOf(HCRelationPersonContactId)+String.valueOf(HCRelationRelatedPersonContactId)+String.valueOf(reciprocalRoleId))) {
                        continue;
                    }
                    contactContactRelation.add(
                        new HealthCloudGA__ContactContactRelation__c(
                            HealthCloudGA__Active__c = true,
                            HealthCloudGA__Contact__c = HCRelationPersonContactId,
                            HealthCloudGA__RelatedContact__c = HCRelationRelatedPersonContactId,
                            HealthCloudGA__Role__c = reciprocalRoleId
                        )
                    );
                }

                // AccountContactRelation
                if(String.isNotBlank(config.MVN_Account_Role_Mapping__c)
                        && config.MVN_Account_Role_Case_Field__c != null
                        && (Id) currentCase.get(config.MVN_Account_Role_Case_Field__c) != null) {
                    Id accountRoleCaseId = (Id) currentCase.get(config.MVN_Account_Role_Case_Field__c);
                    accountContactRelationshipsToInsert.add(
                        new AccountContactRelation(
                            AccountId = memberId,
                            ContactId = personAccounts.get(accountRoleCaseId).PersonContactId,
                            Roles = config.MVN_Account_Role_Mapping__c,
                            MVN_External_Id__c = memberId + '|' + personAccounts.get(accountRoleCaseId).PersonContactId
                        )
                    );
                }
            }
        }
        System.debug('caseTeamMembersToInsertByMemberId::' + caseTeamMembersToInsertByMemberId);
        System.debug('caseTeamMembersToInsertByMemberId::' + Database.insert(caseTeamMembersToInsertByMemberId.values(), false));
        System.debug('contactContactRelation::' + contactContactRelation);
        System.debug('contactContactRelation::' + Database.insert(contactContactRelation, false));
        System.debug('accountContactRelationshipsToInsert::' + accountContactRelationshipsToInsert);
        System.debug('accountContactRelationshipsToInsert::' + Database.upsert(accountContactRelationshipsToInsert, AccountContactRelation.MVN_External_Id__c, false));
    }

}