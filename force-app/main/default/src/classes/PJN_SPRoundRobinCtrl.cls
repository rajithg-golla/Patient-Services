/**
 * @author      Mavens
 * @date        11/2020
 * @description Controller for the Specialty Pharmacy Round Robin aura quick action
 * @group       Specialty Pharmacy
 */
public with sharing class PJN_SPRoundRobinCtrl {

    @TestVisible
    private static PJN_SpecialtyPharmacyQuery specialtyPharmacyQuery = new PJN_SpecialtyPharmacyQuery();

    private class PJN_SPRoundRobinCtrlException extends Exception {}

    @AuraEnabled
    public static void assignSpecialtyPharmacy(Id recordId){

        try {
            Id memberPlanInvestigationItemRecTypeId = SObjectType.PJN_Coverage_Investigation_Item__c
                .getRecordTypeInfosByDeveloperName()
                .get('PJN_Member_Plan')
                .getRecordTypeId();

            PJN_Coverage_Investigation__c investigation = [
                SELECT
                    Id,
                    PJN_Care_Plan__r.PJN_Program__c,
                    PJN_Care_Plan__r.PJN_Program__r.PJN_Filter_Round_Robin_by_Payers__c,
                    PJN_Selected_Specialty_Pharmacy__c,
                    PJN_Speciality_Pharmacy_Selection_Reason__c,
                    PJN_Special_Pharmacy_Round_Robin_Audit__c,
                    (
                        SELECT
                            Id,
                            PJN_Member_Plan__r.Name,
                            PJN_Member_Plan__r.PJN_Payer__c,
                            PJN_Member_Plan__r.PJN_Payer__r.Name
                        FROM Coverage_Investigation_Items__r
                        WHERE PJN_Member_Plan__r.PJN_Therapy_Covered__c = 'Covered'
                        AND PJN_Member_Plan__c != null
                        AND PJN_Member_Plan__r.PJN_Payer__c != null
                        AND RecordTypeId = :memberPlanInvestigationItemRecTypeId
                        // PJN_Coverage_Order__c is a picklist but the API values are alphabetically
                        // in order but if values are added or changed this could get weird.
                        // highly unlikely so we are not adjusting at this time. a fourth value could
                        // have an API name of U_Fourth so it comes after Tertiary
                        ORDER BY PJN_Member_Plan__r.PJN_Coverage_Order__c NULLS LAST
                    )
                FROM
                    PJN_Coverage_Investigation__c
                WHERE
                    Id = :recordId
            ];

            Map<Id, CareProgram> programsWithSPs = specialtyPharmacyQuery.byProgram(
                new Set<Id>{ investigation.PJN_Care_Plan__r.PJN_Program__c }
            );

            Set<Id> payerIds = new Set<Id>();
            for (PJN_Coverage_Investigation_Item__c item : investigation.Coverage_Investigation_Items__r) {
                payerIds.add(item.PJN_Member_Plan__r.PJN_Payer__c);
            }
            Map<Id, Account> payersWithSpecialtyPharmacies = specialtyPharmacyQuery.byPayer(payerIds);

            List<PJN_Care_Program_Specialty_Pharmacy__c> programPharmacies = programsWithSPs
                .get(investigation.PJN_Care_Plan__r.PJN_Program__c)
                .Program_Specialty_Pharmacies__r;

            PJN_Care_Program_Specialty_Pharmacy__c selectedProgramPharmacy;

            Boolean filterSpecialtyPharmaciesByPayer = investigation.PJN_Care_Plan__r.PJN_Program__r.PJN_Filter_Round_Robin_by_Payers__c;

            PJN_Coverage_Investigation_Item__c highestMemberPlanItem;
            if (!investigation.Coverage_Investigation_Items__r.isEmpty()) {
                highestMemberPlanItem = investigation.Coverage_Investigation_Items__r[0];
            }

            for (PJN_Care_Program_Specialty_Pharmacy__c programPharmacy : programPharmacies) {
                selectedProgramPharmacy = programPharmacy;
                if (filterSpecialtyPharmaciesByPayer) {
                    if (highestMemberPlanItem != null) {
                        Id payerId = highestMemberPlanItem.PJN_Member_Plan__r.PJN_Payer__c;
                        Account payer = payersWithSpecialtyPharmacies.get(payerId);
                        if (payer == null || payer.Payer_Specialty_Pharmacies__r.isEmpty()) {
                            throw new PJN_SPRoundRobinCtrlException(
                                'The payer associated with the member plan '
                                + highestMemberPlanItem.PJN_Member_Plan__r.Name + ' cannot be found'
                                + ' or does not have an associated list of specialty pharmacies'
                            );
                        } else{
                            Boolean foundSelectedPharmacyInPayerPharmacies = false;
                            for (PJN_Payer_Specialty_Pharmacy__c payerPharmacy : payer.Payer_Specialty_Pharmacies__r) {
                                if (selectedProgramPharmacy.PJN_Specialty_Pharmacy__c == payerPharmacy.PJN_Specialty_Pharmacy__c) {
                                    foundSelectedPharmacyInPayerPharmacies = true;
                                    break;
                                }
                            }
                            if (foundSelectedPharmacyInPayerPharmacies) {
                                break;
                            }
                            selectedProgramPharmacy = null; // not found in payer pharmacy list so unset it.
                        }
                    } else {
                        throw new PJN_SPRoundRobinCtrlException(
                            'The application is unable to find a member plan coverage investigation item for this '
                            + 'investigation that is marked as covered and has an associated payer.'
                        );
                    }
                } else {
                    break; // as there is nothing else to check we can just take the first one at the top of the list
                }
            }

            if (selectedProgramPharmacy == null) {
                throw new PJN_SPRoundRobinCtrlException('Unable to find a specialty pharmacy to assign to.');
            }

            investigation.PJN_Selected_Specialty_Pharmacy__c = selectedProgramPharmacy.PJN_Specialty_Pharmacy__c;
            investigation.PJN_Speciality_Pharmacy_Selection_Reason__c = 'Round-Robin';
            String highestMemberPlanInfo = '\n';
            if (highestMemberPlanItem != null) {
                highestMemberPlanInfo = 'And the member plan used is:\n' + JSON.serializePretty(highestMemberPlanItem) + '\n\n';
            }
            investigation.PJN_Special_Pharmacy_Round_Robin_Audit__c =
                'SP Round Robin Assignment at ' + DateTime.now() + ' GMT\n\n'
                + 'Care Program Pharmacies:\n' + JSON.serializePretty(programPharmacies) + '\n\n'
                + 'Filter Specialty Pharmacies by Payer Enabled?: ' + filterSpecialtyPharmaciesByPayer + '\n\n'
                + 'Found Coverage Investigation Item having Member Plan with Payer: ' + String.valueOf(highestMemberPlanItem != null) + '\n'
                + highestMemberPlanInfo
                + 'Payers with associated specialty pharmacies: ' + '\n'
                + JSON.serializePretty(payersWithSpecialtyPharmacies);

            update investigation;

            selectedProgramPharmacy.PJN_Last_Round_Robin_Assign_Date_Time__c = DateTime.now();
            update selectedProgramPharmacy;

        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }
}