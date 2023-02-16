/**
 * @author      Mavens
 * @group       Program
 * @description Program Problem Queries
 */
public with sharing class PJN_ProgramProblemQuery {
    /**
     * fields to query
     */
    public Set<String> fields = new Set<String>{
        'Id',
        'Label',
        'MasterLabel',
        'DeveloperName',
        'PJN_Order__c',
        'PJN_Is_Standard__c',
        'PJN_Is_Startable__c',
        'PJN_Is_Skippable__c',
        'PJN_Is_Removable__c'
    };

    /* CACHE programProblemsByDevName */
    static Map<String, PJN_Program_Problem__mdt> programProblemsByDevName;
    /**
     * query Program Problem by Developer Name
     * @param   String      programProblemDeveloperName
     * @returns  PJN_Program_Problem__mdt
     */
    public PJN_Program_Problem__mdt queryByDeveloperName(String programProblemDeveloperName) {
        if (programProblemsByDevName == null) {
            programProblemsByDevName = new Map<String, PJN_Program_Problem__mdt>();
        }

        if (!programProblemsByDevName.containsKey(programProblemDeveloperName)) {
            programProblemsByDevName.put(programProblemDeveloperName,
                Database.query(
                    'SELECT ' +
                        String.join(new List<String>(fields), ', ') + ' ' +
                    'FROM ' +
                        'PJN_Program_Problem__mdt ' +
                    'WHERE ' +
                        'DeveloperName = :programProblemDeveloperName ' +
                    'ORDER BY ' +
                        'PJN_Order__c ASC'
                )
            );
        }

        return programProblemsByDevName.get(programProblemDeveloperName);
    }



    /* CACHE programProblemsByDevNameAndIsStandardFilter */
    static Map<String, List<PJN_Program_Problem__mdt>> programProblemsByDevNameAndIsStandardFilter;
    /**
     * query Program Problem by Developer Name
     * @param   String      programProblemDeveloperName
     * @returns  PJN_Program_Problem__mdt
     */
    public List<PJN_Program_Problem__mdt> queryByProgramDeveloperName(String programProblemDeveloperName, Boolean isStandard) {
        if (programProblemsByDevNameAndIsStandardFilter == null) {
            programProblemsByDevNameAndIsStandardFilter = new Map<String, List<PJN_Program_Problem__mdt>>();
        }

        String key = programProblemDeveloperName + String.valueOf(isStandard);

        if (!programProblemsByDevNameAndIsStandardFilter.containsKey(key)) {
            programProblemsByDevNameAndIsStandardFilter.put(key,
                Database.query(
                    'SELECT ' +
                        String.join(new List<String>(fields), ', ') + ' ' +
                    'FROM ' +
                        'PJN_Program_Problem__mdt ' +
                    'WHERE ' +
                        'PJN_Program__r.DeveloperName = :key ' +
                    (isStandard ? ' AND PJN_Is_Standard__c = true ' : '') +
                    'ORDER BY ' +
                        'PJN_Order__c ASC'
                )
            );
        }

        return programProblemsByDevNameAndIsStandardFilter.get(key);
    }



    /* CACHE programProblemsByDevName */
    static Map<String, List<PJN_Program_Problem__mdt>> problemsByProgramDevNameAndLibrary;
    /**
     * query Program Problem by Program Developer Name
     * @param   String      programDeveloperName
     * @returns  List<PJN_Program_Problem__mdt>
     */
    public List<PJN_Program_Problem__mdt> queryByProgramDeveloperNameAndLibrary(String programDeveloperName) {
        if (problemsByProgramDevNameAndLibrary == null) {
            problemsByProgramDevNameAndLibrary = new Map<String, List<PJN_Program_Problem__mdt>>();
        }

        if (!problemsByProgramDevNameAndLibrary.containsKey(programDeveloperName)) {
            problemsByProgramDevNameAndLibrary.put(programDeveloperName,
                Database.query(
                    'SELECT ' +
                        String.join(new List<String>(fields), ', ') + ' ' +
                    'FROM ' +
                        'PJN_Program_Problem__mdt ' +
                    'WHERE ' +
                        'PJN_Program__r.DeveloperName = :programDeveloperName ' +
                    'AND ' +
                        'PJN_Is_Library__c = true ' +
                    'ORDER BY ' +
                        'Label'
                )
            );
        }

        return problemsByProgramDevNameAndLibrary.get(programDeveloperName);
    }

    public List<PJN_Program_Problem__mdt> getProblemsForProgramInReverseOrder(Id programId) {
        return Database.query(
            'SELECT ' + String.join(new List<String>(fields), ', ') + ' ' +
            'FROM PJN_Program_Problem__mdt ' +
            'WHERE PJN_Program__c = \'' + programId + '\' ' +
            'ORDER BY PJN_Order__c DESC'
        );
    }
}