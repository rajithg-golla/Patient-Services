/**
 * @author      Mavens
 * @group       Program
 * @description Program Case Queries
 */
public with sharing class PJN_ProgramCaseQuery {
    /**
     * fields to query
     */
    public Set<String> fields = new Set<String>{
        'Id',
        'Label',
        'MasterLabel',
        'DeveloperName',
        'PJN_Order__c',
        'PJN_Program_Problem__c'
    };



    /* CACHE programCasesByDeveloperName */
    static Map<String, PJN_Program_Case__mdt> programCasesByDeveloperName;
    /**
     * query Program Case by Developer Name
     * @param   String      programCaseDeveloperName
     * @returns  PJN_Program_Case__mdt
     */
    public PJN_Program_Case__mdt queryByDeveloperName(String programCaseDeveloperName) {
        if (programCasesByDeveloperName == null) {
            programCasesByDeveloperName = new Map<String, PJN_Program_Case__mdt>();
        }

        if (!programCasesByDeveloperName.containsKey(programCaseDeveloperName)) {
            programCasesByDeveloperName.put( programCaseDeveloperName,
                Database.query(
                    'SELECT ' +
                        String.join(new List<String>(this.fields), ', ') + ' ' +
                    'FROM ' +
                        'PJN_Program_Case__mdt ' +
                    'WHERE ' +
                        'DeveloperName = :programCaseDeveloperName'
                )
            );
        }

        return programCasesByDeveloperName.get(programCaseDeveloperName);
    }

    /* CACHE programCasesByProblemDevName */
    static Map<String, List<PJN_Program_Case__mdt>> programCasesByProblemDevName;
    /**
     * query Program Cases by Program Problem Developer Name
     * @param   String      programProblemDeveloperName
     * @returns  List<PJN_Program_Case__mdt>
     */
    public List<PJN_Program_Case__mdt> queryByProgramProblemDeveloperName(String programProblemDeveloperName) {
        if (programCasesByProblemDevName == null) {
            programCasesByProblemDevName = new Map<String, List<PJN_Program_Case__mdt>>();
        }

        if (!programCasesByProblemDevName.containsKey(programProblemDeveloperName)) {
            programCasesByProblemDevName.put(programProblemDeveloperName,
                Database.query(
                    'SELECT ' +
                        String.join(new List<String>(this.fields), ', ') + ' ' +
                    'FROM ' +
                        'PJN_Program_Case__mdt ' +
                    'WHERE ' +
                        'PJN_Program_Problem__r.DeveloperName = :programProblemDeveloperName ' +
                    'ORDER BY ' +
                        'PJN_Order__c ASC NULLS LAST'
                )
            );
        }

        return programCasesByProblemDevName.get(programProblemDeveloperName);
    }

    static Map<Set<String>,List<PJN_Program_Case__mdt>> programCasesByDeveloperNames;
    /**
     * query Program Cases by Program Problem Developer Name
     * @param   String      programProblemDeveloperName
     * @returns  List<PJN_Program_Case__mdt>
     */
    public List<PJN_Program_Case__mdt> queryByProgramCaseDeveloperNames(Set<String> programCaseDeveloperNames) {
        if (programCasesByDeveloperNames == null) {
            programCasesByDeveloperNames = new Map<Set<String>,List<PJN_Program_Case__mdt>>();
        }

        if (!programCasesByDeveloperNames.containsKey(programCaseDeveloperNames)) {
            programCasesByDeveloperNames.put(programCaseDeveloperNames,
                Database.query(
                    'SELECT ' +
                        String.join(new List<String>(this.fields), ', ') + ' ' +
                    'FROM ' +
                        'PJN_Program_Case__mdt ' +
                    'WHERE ' +
                        'DeveloperName IN :programCaseDeveloperNames ' +
                    'ORDER BY ' +
                        'PJN_Order__c ASC NULLS LAST'
                )
            );
        }
        return programCasesByDeveloperNames.get(programCaseDeveloperNames);
    }

    public List<PJN_Program_Case__mdt> queryProgramCasesByProblemIds(Set<Id> problemIds) {
        PJN_ProgramCaseDependencyQuery caseDependencyQuery = new PJN_ProgramCaseDependencyQuery();
        return Database.query(
            'SELECT ' + String.join(new List<String>(this.fields), ', ') + ' ' +
            'FROM PJN_Program_Case__mdt ' +
            'WHERE PJN_Program_Problem__c IN :problemIds ' +
            'ORDER BY PJN_Order__c'
        );
    }
}