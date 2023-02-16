@isTest(isParallel=true) public with sharing class PJN_ProgramCaseDependencyMock implements System.StubProvider {

    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if(stubbedMethodName == 'queryDependentsByProgramCaseDeveloperName') {
            return this.queryDependentsByProgramCaseDeveloperName((String) listOfArgs[0]);
        } else if(stubbedMethodName == 'queryDependentOnsByProgramCaseDeveloperName') {
            return this.queryDependentOnsByProgramCaseDeveloperName((String) listOfArgs[0]);
        } else if(stubbedMethodName == 'queryDependenciesByProgramCase') {
            return this.queryDependenciesByProgramCase((List<PJN_Program_Case__mdt>)listOfArgs[0]);
        } else {
            return null;
        }
    }

    private Object queryDependentsByProgramCaseDeveloperName(String programCaseDeveloperName) {
        List<PJN_Program_Case_Dependency__mdt> programCaseDependencies = new List<PJN_Program_Case_Dependency__mdt>();
        programCaseDependencies.add(
            new PJN_Program_Case_Dependency__mdt(
                MasterLabel = 'Mocked Program Case Dependency',
                DeveloperName = 'PJN_Mocked_Program_Case_Dependency',
                PJN_Dependent_On__r = new PJN_Program_Case__mdt(
                    MasterLabel = 'Mocked Program Case',
                    DeveloperName = programCaseDeveloperName
                )
            )
        );
        return programCaseDependencies;
    }

    private Object queryDependentOnsByProgramCaseDeveloperName(String programCaseDeveloperName) {
        List<PJN_Program_Case_Dependency__mdt> programCaseDependencies = new List<PJN_Program_Case_Dependency__mdt>();
        programCaseDependencies.add(
            new PJN_Program_Case_Dependency__mdt(
                MasterLabel = 'Mocked Program Case Dependency',
                DeveloperName = 'PJN_Mocked_Program_Case_Dependency',
                PJN_Dependent__r = new PJN_Program_Case__mdt(
                    MasterLabel = 'Mocked Program Case',
                    DeveloperName = programCaseDeveloperName
                )
            )
        );
        return programCaseDependencies;
    }

    private Object queryDependenciesByProgramCase(List<PJN_Program_Case__mdt> programCases) {
        // only creating a single, fake, depenency. this is called from the program builder and
        // we need to simply get the dependency creation to fire to ensure it's working right.
        Map<Id, List<PJN_Program_Case_Dependency__mdt>> dependenciesByProgCase = new Map<Id, List<PJN_Program_Case_Dependency__mdt>>();
        if (programCases.size() > 0) {
            dependenciesByProgCase.put(
                programCases[0].Id,
                new List<PJN_Program_Case_Dependency__mdt> {
                    new PJN_Program_Case_Dependency__mdt(
                        PJN_Dependent_On__c = PJN_Program_Case__mdt.SobjectType.getDescribe().getKeyPrefix() + '000000000001',
                        PJN_Dependent__c = PJN_Program_Case__mdt.SobjectType.getDescribe().getKeyPrefix() + '000000000002'
                    )
                }
            );
        }

        return dependenciesByProgCase;

    }
}