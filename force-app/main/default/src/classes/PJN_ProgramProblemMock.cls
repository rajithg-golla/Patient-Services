@isTest(isParallel=true) public with sharing class PJN_ProgramProblemMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'queryByDeveloperName') {
            return this.queryByDeveloperName((String) listOfArgs[0]);
        } else if (stubbedMethodName == 'queryByProgramDeveloperNameAndLibrary'){
            return this.queryByProgramDeveloperNameAndLibrary((String) listOfArgs[0]);
        } else if (stubbedMethodName == 'queryByProgramDeveloperName') {
            return this.queryByProgramDeveloperName((String) listOfArgs[0], (Boolean) listOfArgs[1]);
        } else if (stubbedMethodName == 'getProblemsForProgramInReverseOrder') {
            return this.getProblemsForProgramInReverseOrder((Id) listOfArgs[0]);
        } else {
            return null;
        }
    }

    private PJN_Program_Problem__mdt queryByDeveloperName(String programProblemDeveloperName) {
        return new PJN_Program_Problem__mdt(
            MasterLabel = 'Mocked Program Problem',
            DeveloperName = programProblemDeveloperName,
            PJN_Is_Standard__c = true,
            PJN_Is_Library__c = false,
            PJN_Order__c = 10
        );
    }

    private List<PJN_Program_Problem__mdt> queryByProgramDeveloperName(String programProblemDeveloperName, Boolean isStandard) {
        PJN_Program__mdt program = new PJN_Program__mdt(
            Id = PJN_Program__mdt.sObjectType.getDescribe().getKeyPrefix() + '000000000000',
            Label = 'Test Program ' + programProblemDeveloperName,
            DeveloperName = programProblemDeveloperName,
            MasterLabel = 'Mocked Program Problem ' + programProblemDeveloperName
        );

        List<PJN_Program_Problem__mdt> programProblems = new List<PJN_Program_Problem__mdt>();
        programProblems.add(
            new PJN_Program_Problem__mdt(
                MasterLabel = 'Mocked Program Problem One',
                DeveloperName = 'PJN_Mocked_Program_Problem_Two',
                PJN_Is_Standard__c = isStandard,
                PJN_Is_Library__c = true,
                PJN_Order__c = 10,
                PJN_Program__r = program
            )
        );
        programProblems.add(
            new PJN_Program_Problem__mdt(
                MasterLabel = 'Mocked Program Problem Two',
                DeveloperName = 'PJN_Mocked_Program_Problem_Two',
                PJN_Is_Standard__c = isStandard,
                PJN_Is_Library__c = true,
                PJN_Order__c = 20,
                PJN_Program__r = program
            )
        );
        return programProblems;
    }

    private Object queryByProgramDeveloperNameAndLibrary(String programDeveloperName) {
        List<PJN_Program_Problem__mdt> programProblems = new List<PJN_Program_Problem__mdt>();
        programProblems.add(
            new PJN_Program_Problem__mdt(
                MasterLabel = 'Mocked Program Problem One',
                DeveloperName = 'PJN_Mocked_Program_Problem_Two',
                PJN_Is_Standard__c = false,
                PJN_Is_Library__c = true,
                PJN_Order__c = 10,
                PJN_Program__r = new PJN_Program__mdt(
                    MasterLabel = 'Mocked Program',
                    DeveloperName = programDeveloperName
                )
            )
        );
        programProblems.add(
            new PJN_Program_Problem__mdt(
                MasterLabel = 'Mocked Program Problem Two',
                DeveloperName = 'PJN_Mocked_Program_Problem_Two',
                PJN_Is_Standard__c = false,
                PJN_Is_Library__c = true,
                PJN_Order__c = 20,
                PJN_Program__r = new PJN_Program__mdt(
                    MasterLabel = 'Mocked Program Problem',
                    DeveloperName = programDeveloperName
                )
            )
        );
        return programProblems;
    }

    private Object getProblemsForProgramInReverseOrder(Id programId) {
        return new List<PJN_Program_Problem__mdt>{
            createProblem(programId, 3),
            createProblem(programId, 2),
            createProblem(programId, 1)
        };
    }

    private PJN_Program_Problem__mdt createProblem(Id programId, Integer order) {
        String strVal = String.valueOf(order);
        return new PJN_Program_Problem__mdt(
            Id = PJN_Program_Problem__mdt.SobjectType.getDescribe().getKeyPrefix() + '00000000000' + order,
            Label = 'Program ' + programId + ' problem ' + strVal,
            MasterLabel = 'Program ' + programId + ' problem ' + strVal,
            DeveloperName = 'PJN_Program_Problem_' + strVal,
            PJN_Order__c = order,
            PJN_Is_Standard__c = true,
            PJN_Is_Startable__c = true,
            PJN_Is_Skippable__c = true,
            PJN_Is_Removable__c = false,
            PJN_Program__c = programId
        );
    }
}