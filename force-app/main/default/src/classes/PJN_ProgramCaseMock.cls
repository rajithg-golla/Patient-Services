@isTest(isParallel=true) public with sharing class PJN_ProgramCaseMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'queryByDeveloperName') {
            return this.queryByDeveloperName((String) listOfArgs[0]);
        } else if (stubbedMethodName == 'queryByProgramProblemDeveloperName'){
            return this.queryByProgramProblemDeveloperName((String) listOfArgs[0]);
        } else if (stubbedMethodName == 'queryByProgramCaseDeveloperNames'){
            return this.queryByProgramCaseDeveloperNames((Set<String>) listOfArgs[0]);
        } else if (stubbedMethodName == 'queryProgramCasesByProblemIds') {
            return this.queryProgramCasesByProblemIds((Set<Id>)listOfArgs[0]);
        } else {
            return null;
        }
    }

    private Object queryByDeveloperName(String programCaseDeveloperName) {
        return new PJN_Program_Case__mdt(
            MasterLabel = 'Mocked Program Case One',
            DeveloperName = programCaseDeveloperName,
            PJN_Order__c = 1
        );
    }

    private Object queryByProgramProblemDeveloperName(String programProblemDeveloperName) {
        List<PJN_Program_Case__mdt> programCases = new List<PJN_Program_Case__mdt>();
        programCases.add(
            new PJN_Program_Case__mdt(
                MasterLabel = 'Mocked Program Case One',
                DeveloperName = 'PJN_Mocked_Program_Case_One',
                PJN_Program_Problem__r = new PJN_Program_Problem__mdt(
                    MasterLabel = 'Mocked Program Problem',
                    DeveloperName = programProblemDeveloperName
                ),
                PJN_Order__c = 1
            )
        );
        programCases.add(
            new PJN_Program_Case__mdt(
                MasterLabel = 'Mocked Program Case Two',
                DeveloperName = 'PJN_Mocked_Program_Case_Two',
                PJN_Program_Problem__r = new PJN_Program_Problem__mdt(
                    MasterLabel = 'Mocked Program Problem',
                    DeveloperName = programProblemDeveloperName
                ),
                PJN_Order__c = 2
            )
        );
        return programCases;
    }

    private Object queryByProgramCaseDeveloperNames(Set<String> programProblemDeveloperNames) {
        List<PJN_Program_Case__mdt> programCases = new List<PJN_Program_Case__mdt>();
        if(!programProblemDeveloperNames.isEmpty()) {
            Integer counter = 0;
            for(String programProblemDeveloperName : programProblemDeveloperNames) {
                counter++;
                programCases.add(
                    new PJN_Program_Case__mdt(
                        MasterLabel = 'Mocked Program Case One',
                        DeveloperName = programProblemDeveloperName,
                        PJN_Program_Problem__r = new PJN_Program_Problem__mdt(
                            MasterLabel = 'Mocked Program Problem',
                            DeveloperName = 'PJN_Mocked_Program_Problem'
                        ),
                        PJN_Order__c = counter
                    )
                );
            }
        }
        return programCases;
    }

    private Object queryProgramCasesByProblemIds(Set<Id> problemIds) {
        List<PJN_Program_Case__mdt> programCases = new List<PJN_Program_Case__mdt> ();

        List<Id> ids = new List<Id>(problemIds);
        for (Integer i=0; i<ids.size(); i++) {
            List<PJN_Program_Case__mdt> problemCases = new List<PJN_Program_Case__mdt> ();
            for (Integer j=1; j<=3; j++) {
                problemCases.add(
                    createProgramCase(ids[i], i, j)
                );
            }
            programCases.addAll(problemCases);
        }

        return programCases;
    }

    private PJN_Program_Case__mdt createProgramCase(Id problemId, Integer problemCounter, Integer order) {
        return new PJN_Program_Case__mdt(
            Id = PJN_Program_Case__mdt.SobjectType.getDescribe().getKeyPrefix() + '0000000000' + problemCounter + order, // ppc000000000013 or ppc000000000021 etc.
            Label = problemId + ' Program Case ' + order,
            MasterLabel = problemId + ' Program Case ' + order,
            DeveloperName = problemId + '_Program_Case_' + order,
            PJN_Order__c = order,
            PJN_Program_Problem__c = problemId
        );
    }
}