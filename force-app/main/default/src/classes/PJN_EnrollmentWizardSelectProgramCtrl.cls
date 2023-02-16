/**
 * @author Mavens
 * @date Apri 2019
 * @description Get list of programs to be presented to the user to create the care plan
 * @group EnrollmentWizard
 */
public with sharing class PJN_EnrollmentWizardSelectProgramCtrl {
    /**
     * getProgramList get list of available programs for current user
     * @returns  List<Map<String, String>> list of programs
     */
    @auraEnabled
    public static List<Map<String, String>> getProgramList() {
        List<CareProgram> visiblePrograms = getVisiblePrograms();
        List<Map<String, String>> programList = new List<Map<String, String>>();
        for (CareProgram visibleProgram : visiblePrograms) {
            programList.add(
                new Map<String, String> {
                    'value' => visibleProgram.PJN_Program_DeveloperName__c,
                    'label' => visibleProgram.Name
                }
            );
        }
        return programList;
    }

    /**
     * get all visible programs
     * @returns List<CareProgram>
     */
    private static List<CareProgram> getVisiblePrograms() {
        return [
            SELECT
                Id,
                Name,
                PJN_Program_DeveloperName__c
            FROM
                CareProgram
            WHERE
                StartDate <= :System.today()
            AND
                (
                    EndDate >= :System.today()
                OR
                    EndDate = null
                )
            ORDER BY
                Name
        ];
    }
}