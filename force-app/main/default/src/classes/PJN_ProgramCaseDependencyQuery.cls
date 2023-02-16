/**
 * @author      Mavens
 * @group       Program
 * @description Program Case Queries
 */
public with sharing class PJN_ProgramCaseDependencyQuery {
    /**
     * fields to query
     */
    public Set<String> fields = new Set<String>{
        'Id',
        'Label',
        'DeveloperName',
        'PJN_Dependent_On__c',
        'PJN_Dependent_On__r.DeveloperName',
        'PJN_Dependent_On__r.MasterLabel',
        'PJN_Dependent__c',
        'PJN_Dependent__r.DeveloperName',
        'PJN_Dependent__r.MasterLabel'
    };

    /* CACHE dependentsByProgramCaseDevName */
    static Map<String, List<PJN_Program_Case_Dependency__mdt>> dependentsByProgramCaseDevName;
    /**
     * query Program Case Dependencies by Program Case Developer Name
     * @param   String      programCaseDeveloperName
     * @returns  List<PJN_Program_Case__mdt>
     */
    public List<PJN_Program_Case_Dependency__mdt> queryDependentsByProgramCaseDeveloperName(String programCaseDeveloperName) {
        if (dependentsByProgramCaseDevName == null) {
            dependentsByProgramCaseDevName = new Map<String, List<PJN_Program_Case_Dependency__mdt>>();
        }

        if (!dependentsByProgramCaseDevName.containsKey(programCaseDeveloperName)) {
            dependentsByProgramCaseDevName.put(programCaseDeveloperName,
                Database.query(
                    'SELECT ' +
                        String.join(new List<String>(this.fields), ', ') + ' ' +
                    'FROM ' +
                        'PJN_Program_Case_Dependency__mdt ' +
                    'WHERE ' +
                        'PJN_Dependent_On__r.DeveloperName = :programCaseDeveloperName '
                )
            );
        }

        return dependentsByProgramCaseDevName.containsKey(programCaseDeveloperName) ?
            dependentsByProgramCaseDevName.get(programCaseDeveloperName) :
            new List<PJN_Program_Case_Dependency__mdt>();
    }

    /* CACHE dependentsByProgramCaseDevName */
    static Map<String, List<PJN_Program_Case_Dependency__mdt>> dependentOnsByProgramCaseDevName;
    /**
     * query Program Case Dependencies by Program Case Developer Name
     * @param   String      programCaseDeveloperName
     * @returns  List<PJN_Program_Case__mdt>
     */
    public List<PJN_Program_Case_Dependency__mdt> queryDependentOnsByProgramCaseDeveloperName(String programCaseDeveloperName) {
        if (dependentOnsByProgramCaseDevName == null) {
            dependentOnsByProgramCaseDevName = new  Map<String, List<PJN_Program_Case_Dependency__mdt>>();
        }

        if (!dependentOnsByProgramCaseDevName.containsKey(programCaseDeveloperName)) {
            dependentOnsByProgramCaseDevName.put(programCaseDeveloperName,
                Database.query(
                    'SELECT ' +
                        String.join(new List<String>(this.fields), ', ') + ' ' +
                    'FROM ' +
                        'PJN_Program_Case_Dependency__mdt ' +
                    'WHERE ' +
                        'PJN_Dependent__r.DeveloperName = :programCaseDeveloperName '
                )
            );
        }

        return dependentOnsByProgramCaseDevName.get(programCaseDeveloperName);
    }

    /**
     * query for dependencies belongnig to the program cases and group them together
     * @param programCases
     * @returns `Map<Id, List<PJN_Program_Case_Dependency__mdt>>`
     */
    public Map<Id, List<PJN_Program_Case_Dependency__mdt>> queryDependenciesByProgramCase(List<PJN_Program_Case__mdt> programCases) {

        String query = 'SELECT ' + String.join(new List<String>(this.fields), ', ') + ' ' +
        'FROM PJN_Program_Case_Dependency__mdt ' +
        'WHERE PJN_Dependent_On__c IN :programCases';

        List<PJN_Program_Case_Dependency__mdt> dependencies = Database.query(query);

        Map<Id, List<PJN_Program_Case_Dependency__mdt>> dependenciesByProgramCase = new Map<Id, List<PJN_Program_Case_Dependency__mdt>>();
        for (PJN_Program_Case_Dependency__mdt dependency : dependencies) {
            if (!dependenciesByProgramCase.containsKey(dependency.PJN_Dependent_On__c)) {
                dependenciesByProgramCase.put(
                    dependency.PJN_Dependent_On__c,
                    new List<PJN_Program_Case_Dependency__mdt>()
                );
            }
            dependenciesByProgramCase.get(dependency.PJN_Dependent_On__c).add(dependency);
        }

        return dependenciesByProgramCase;
    }
}