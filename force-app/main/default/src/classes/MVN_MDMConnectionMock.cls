/**
 * @author      Mavens
 * @group       MDM
 * @description Mock for MVN_MDMConnectionQuery
 */
@IsTest
public with sharing class MVN_MDMConnectionMock implements System.StubProvider {

    @TestVisible
    private static final String PREFIX = Schema.SObjectType.MVN_MDM_Connection__mdt.getKeyPrefix();

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public Object handleMethodCall(Object stubbedObject,
                                   String stubbedMethodName,
                                   Type returnType,
                                   List<Type> listOfParamTypes,
                                   List<String> listOfParamNames,
                                   List<Object> listOfArgs) {
        if (stubbedMethodName == 'queryAll') {
            return this.queryAll();
        } else {
            return null;
        }
    }

    /**
     * Initialize all the MDM Connection metadatas when query all
     * @return  `List<MVN_MDM_Connection__mdt>`
     */
    public List<MVN_MDM_Connection__mdt> queryAll() {
        List<MVN_MDM_Connection__mdt> mdmConnections = new List<MVN_MDM_Connection__mdt>();
        mdmConnections.add(
            new MVN_MDM_Connection__mdt(
                Label = 'MyRare',
                DeveloperName = 'MVN_MyRare',
                MasterLabel = 'MVN_MyRare',
                MVN_Is_Active__c = true,
                id = PREFIX + '000000000001'
            )
        );
        mdmConnections.add(
            new MVN_MDM_Connection__mdt(
                Label = 'DataLake Payer',
                DeveloperName = 'MVN_DataLake_Payer',
                MasterLabel = 'MVN_DataLake_Payer',
                MVN_Is_Active__c = true,
                MVN_Environment__c = 'CDL',
                id = PREFIX + '000000000002'
            )
        );
        return mdmConnections;
    }
}