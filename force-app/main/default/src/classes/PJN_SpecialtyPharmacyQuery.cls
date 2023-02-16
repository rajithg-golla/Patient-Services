/**
 * @author      Mavens
 * @date        11/2020
 * @description Queries for Specialty Pharmacies
 * @group       Specialty Pharmacy
 */
public with sharing class PJN_SpecialtyPharmacyQuery {

    public Map<Id, CareProgram> byProgram(Set<Id> programIds) {
        return new Map<Id, CareProgram>([
            SELECT
                Id,
                Name,
                (
                    SELECT
                        Id,
                        PJN_Specialty_Pharmacy__c,
                        PJN_Specialty_Pharmacy__r.Name,
                        PJN_Last_Round_Robin_Assign_Date_Time__c
                    FROM Program_Specialty_Pharmacies__r
                    ORDER BY PJN_Last_Round_Robin_Assign_Date_Time__c, CreatedDate
                )
            FROM CareProgram
            WHERE Id IN :programIds
        ]);
    }

    public Map<Id, Account> byPayer(Set<Id> payerIds) {
        return new Map<Id, Account>([
            SELECT Id,
                (
                    SELECT PJN_Specialty_Pharmacy__c, PJN_Specialty_Pharmacy__r.Name
                    FROM Payer_Specialty_Pharmacies__r
                )
            FROM Account
            WHERE Id IN :payerIds
        ]);
    }
}