/**
 * @author Mavens
 * @description Controller for program builder functionality
 * @group Program builder
 *
 * example visualization:

 flowchart TD
    subgraph problem1Id[Problem 2 label]
        child1Id[Child 1 Label] --> child2Id[Child 2 Label]
    end
    subgraph problem2Id[Probem 2 label]
        child3Id[Child 3 Label] --> child4Id[Child 4 Label]
    end
    problem1Id --> problem2Id

 */
public with sharing class PJN_ProgramBuilderCtrl {
    @TestVisible private static PJN_ProgramQuery programQuery = new PJN_ProgramQuery();
    @TestVisible private static PJN_ProgramProblemQuery programProblemQuery = new PJN_ProgramProblemQuery();
    @TestVisible private static PJN_ProgramCaseQuery programCaseQuery = new PJN_ProgramCaseQuery();
    @TestVisible private static PJN_ProgramCaseDependencyQuery programCaseDependQuery = new PJN_ProgramCaseDependencyQuery();
    /**
     * Returns the Id and master label for all programs
     * @returns `List<PJN_Program__mdt>`
     */
    @AuraEnabled(cacheable=true)
    public static List<PJN_Program__mdt> getPrograms() {
        return programQuery.getAllPrograms();
    }

    /**
     * Return a list of objects mapping a key to a visualization string to be passed to the mermaid.js library
     * ex [{key: "standard", chartDefinition: "flowchart TD\na-->b"}]
     * @param programId
     * @returns `List<Map<string, string>>`
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<string, string>> getProgramVisualizationString(String programId){
        List<PJN_Program_Problem__mdt> programProblems = programProblemQuery.getProblemsForProgramInReverseOrder((Id) programId);

        // throw problems into a map to eaisly get Ids
        Map<Id, PJN_Program_Problem__mdt> programProblemMap = new Map<Id, PJN_Program_Problem__mdt>(
            programProblems
        );

        // pass keyset to get strings by problem
        Map<Id, String> visualizationStrings = getVisualizationStringsByProblem(programProblemMap.keySet());

        String standardFlowchart = 'flowchart TD\n'; // linking the problems together renders top down
        String libraryFlowChart = 'flowchart LR\n'; // without the links each problem is it's own chart and LR flowchart will stack them

        List<PJN_Program_Problem__mdt> standardProblems = new List<PJN_Program_Problem__mdt>();

        // we queried in descending order so we are looping backwards. this is needed or rendering mermaid correctly
        // just a quirk of how it renders, go with it, don't fight it.
        for (PJN_Program_Problem__mdt programProblem : programProblems) {

            // each problem is a subgraph
            String currentChart = 'subgraph ' + programProblem.Id + '["' + programProblem.MasterLabel + '"]\n';
            currentChart += visualizationStrings.get(programProblem.Id) + '\nend\n';

            // Add the subgraph to the correct flowchart (standard or library)
            if (programProblem.PJN_Is_Standard__c) {
                // once the subgraphs are built we need to link the standard problems
                standardProblems.add(programProblem);
                standardFlowchart += currentChart;
            } else {
                libraryFlowChart += currentChart;
            }

        }

        // link all the problems, in order, in the standard flow chart
        for (Integer i=0; i < standardProblems.size()-1; i++) {
            standardFlowchart += standardProblems[i+1].Id + '-->' + standardProblems[i].Id + '\n';
        }

        // Returns a mapping to tell the client how to label the charts
        return new List<Map<String, String>>{
            new Map<String, String>{
                'key' => 'standard',
                'chartDefinition' => standardFlowchart
            },
            new Map<String, String>{
                'key' => 'library',
                'chartDefinition' => libraryFlowChart
            }
        };
    }

    public static Map<Id, String> getVisualizationStringsByProblem(Set<Id> problemIds) {
        List<PJN_Program_Case__mdt> programCases = programCaseQuery.queryProgramCasesByProblemIds(problemIds);
        Map<Id, List<PJN_Program_Case_Dependency__mdt>> dependeciesByProgramCase = programCaseDependQuery.queryDependenciesByProgramCase(programCases);

        // separate out the program cases into lists by program problem. Query above keeps them in order so
        // the order of the program cases in each list will still be correct.
        Map<Id,List<PJN_Program_Case__mdt>> programCasesByProgramProblem = new Map<Id,List<PJN_Program_Case__mdt>>();

        for (PJN_Program_Case__mdt programCase : programCases) {
            if (!programCasesByProgramProblem.containsKey(programCase.PJN_Program_Problem__c)) {
                programCasesByProgramProblem.put(
                    programCase.PJN_Program_Problem__c,
                    new List<PJN_Program_Case__mdt>()
                );
            }
            programCasesByProgramProblem.get(programCase.PJN_Program_Problem__c).add(programCase);
        }

        // for each problem build out the visualization string for the cases under that problem
        Map<Id, String> visualizationStringsByProblem = new Map<Id, String>();
        for (Id problemId : programCasesByProgramProblem.keySet()) {
            List<PJN_Program_Case__mdt> progCases = programCasesByProgramProblem.get(problemId);
            PJN_ProblemVisualization visualization = new PJN_ProblemVisualization(progCases, dependeciesByProgramCase);
            visualizationStringsByProblem.put( problemId, visualization.formattedString());
        }

        return  visualizationStringsByProblem;
    }

    /**
     * Inner class. Contstructor parses out program cases and formats the connections between the two
     * for use with mermaid.js
     * formattedString method returns a mermaid formatted section of a flowchart
     */
    private class PJN_ProblemVisualization {
        private List<String> connections;

        public PJN_ProblemVisualization(List<PJN_Program_Case__mdt> programCases, Map<Id, List<PJN_Program_Case_Dependency__mdt>> dependeciesByProgramCase) {
            Set<Id> programCasesSeen = new Set<Id>();
            connections = new List<String>();

            /**
             * Iterate over the program cases and if they have dependent cases defined create the links
             * between the two cases defined in the dependency
             */

            for (PJN_Program_Case__mdt programCase : programCases) {
                if (!dependeciesByProgramCase.containsKey(programCase.Id)) {
                    // no dependencies to deal with
                    continue;
                }

                for (PJN_Program_Case_Dependency__mdt dependency : dependeciesByProgramCase.get(programCase.Id)) {
                    Id fromId = dependency.PJN_Dependent_On__c;
                    String fromLabel = dependency.PJN_Dependent_On__r.MasterLabel;
                    Id toId = dependency.PJN_Dependent__c;
                    String toLabel = dependency.PJN_Dependent__r.MasterLabel;

                    // add a connection from dependent on to the depenency
                    connections.add(fromId + '(' + fromLabel  + ') --> ' + toId + '(' + toLabel + ')');

                    // track all cases which have been seen, next loop will process any that aren't
                    // linked in any dependencies
                    programCasesSeen.add(fromId);
                    programCasesSeen.add(toId);
                }
            }


            // Iterate over the program cases again and add connections for any node that hasn't
            // yet been seen.
            for (PJN_Program_Case__mdt programCase : programCases) {
                if (!programCasesSeen.contains(programCase.Id)) {
                    connections.add(programCase.Id + '(' + programCase.MasterLabel + ')');
                }
            }
        }

        /**
         * Concatenate all of the connection strings into a single string to create a top down graph
         * @returns `String`
         */
        public String formattedString() {
            return String.join(connections, '\n');
        }
    }
}