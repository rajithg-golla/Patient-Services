@isTest(isParallel=true)
public with sharing class PJN_ProgramQueryMock implements System.StubProvider {
    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {


        if (stubbedMethodName == 'getAllPrograms') {
            return new List<PJN_Program__mdt>{
                new PJN_Program__mdt(
                    Id = PJN_Program__mdt.SobjectType.getDescribe().getKeyPrefix() + '000000000001',
                    Label = 'Alpha Program',
                    MasterLabel = 'Alpha Program',
                    DeveloperName = 'PJN_Alpha_Program'
                ),
                new PJN_Program__mdt(
                    Id = PJN_Program__mdt.SobjectType.getDescribe().getKeyPrefix() + '000000000002',
                    Label = 'Beta Program',
                    MasterLabel = 'Beta Program',
                    DeveloperName = 'PJN_Beta_Program'
                )
            };
        }

        String devName = (String) listOfArgs[0];

        return new PJN_Program__mdt(
            Id = PJN_Program__mdt.sObjectType.getDescribe().getKeyPrefix() + '000000000000',
            Label = 'Test Program ' + devName,
            DeveloperName = devName,
            MasterLabel = 'Mocked Program Problem ' + devName
        );
    }
}