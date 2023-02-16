/**
 * @author      Mavens
 * @group       Program
 * @description Program Case functionality
 */
public inherited sharing class PJN_ProgramCase {
    @testVisible private static PJN_ProgramCaseQuery programCaseQuery = new PJN_ProgramCaseQuery();
    @testVisible private static PJN_ProgramCaseDependencyQuery programCaseDependencyQuery = new PJN_ProgramCaseDependencyQuery();

    /**
     * get Next Program Cases to start
     * @param   String      programProblemDeveloperName
     * @param   String      programCaseDeveloperName
     * @returns  List<PJN_Program_Case__mdt>
     */
    public static List<PJN_Program_Case__mdt> getNextProgramCasesByProgramProblemDeveloperName(String programProblemDeveloperName, String programCaseDeveloperName) {
        Set<String> dependentProgramCaseDeveloperNames = new Set<String>();
        List<PJN_Program_Case__mdt> nextProgramCases = new List<PJN_Program_Case__mdt>();
        for(PJN_Program_Case__mdt thisProgramCase : programCaseQuery.queryByProgramProblemDeveloperName(programProblemDeveloperName)) {
            if(programCaseDeveloperName != null) {
                if(programCaseDeveloperName == thisProgramCase.DeveloperName) {
                    List<PJN_Program_Case_Dependency__mdt> dependents = programCaseDependencyQuery.queryDependentsByProgramCaseDeveloperName(programCaseDeveloperName);
                    for(PJN_Program_Case_Dependency__mdt thisProgramCaseDependency : programCaseDependencyQuery.queryDependentsByProgramCaseDeveloperName(programCaseDeveloperName)) {
                        dependentProgramCaseDeveloperNames.add(thisProgramCaseDependency.PJN_Dependent__r.DeveloperName);
                    }
                }
            } else {
                List<PJN_Program_Case_Dependency__mdt> dependentOns = programCaseDependencyQuery.queryDependentOnsByProgramCaseDeveloperName(thisProgramCase.DeveloperName);
                if(dependentOns.isEmpty()) {
                    nextProgramCases.add(thisProgramCase);
                }
            }
        }
        for(PJN_Program_Case__mdt thisProgramCase : programCaseQuery.queryByProgramCaseDeveloperNames(dependentProgramCaseDeveloperNames)) {
            nextProgramCases.add(thisProgramCase);
        }
        return nextProgramCases;
    }
}