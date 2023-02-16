/**
 * Mock for PJN_NetworkStatusMapping
 * @author  Mavens
 * @group   Network
 */
@IsTest
public with sharing class PJN_NetworkStatusMappingMock implements System.StubProvider {

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
     * Mock all Network status mapping metadatas
     * @returns `List<PJN_Network_Status_Mapping__mdt>`
     */
    public List<PJN_Network_Status_Mapping__mdt> queryAll() {
        List<PJN_Network_Status_Mapping__mdt> networkStatusMappings = new List<PJN_Network_Status_Mapping__mdt>();

        networkStatusMappings.add(
            new PJN_Network_Status_Mapping__mdt(
                Label = 'INACTIVE_USER',
                DeveloperName = 'INACTIVE_USER',
                PJN_Message__c = 'Inactive user in Veeva Network.'
            )
        );

        networkStatusMappings.add(
            new PJN_Network_Status_Mapping__mdt(
                Label = 'USER_LOCKED_OUT',
                DeveloperName = 'USER_LOCKED_OUT',
                PJN_Message__c = 'User locked out in Veeva Network'
            )
        );

        networkStatusMappings.add(
            new PJN_Network_Status_Mapping__mdt(
                Label = 'INVALID_SESSION_ID',
                DeveloperName = 'INVALID_SESSION_ID',
                PJN_Message__c = 'Invalid session id.'
            )
        );

        networkStatusMappings.add(
            new PJN_Network_Status_Mapping__mdt(
                Label = 'INSUFFICIENT_ACCESS',
                DeveloperName = 'INSUFFICIENT_ACCESS',
                PJN_Message__c = 'Insufficient access.'
            )
        );

        networkStatusMappings.add(
            new PJN_Network_Status_Mapping__mdt(
                Label = 'CHANGE_CANCELLED',
                DeveloperName = 'CHANGE_CANCELLED',
                PJN_Message__c = PJN_NetworkConstants.DCR_STATUS_CANCELLED
            )
        );

        networkStatusMappings.add(
            new PJN_Network_Status_Mapping__mdt(
                Label = 'CHANGE_ACCEPTED',
                DeveloperName = 'CHANGE_ACCEPTED',
                PJN_Message__c = PJN_NetworkConstants.DCR_STATUS_APPROVED
            )
        );

        networkStatusMappings.add(
            new PJN_Network_Status_Mapping__mdt(
                Label = 'CHANGE_REJECTED',
                DeveloperName = 'CHANGE_REJECTED',
                PJN_Message__c = PJN_NetworkConstants.DCR_STATUS_REJECTED
            )
        );

        networkStatusMappings.add(
            new PJN_Network_Status_Mapping__mdt(
                Label = 'CHANGE_MODIFIED',
                DeveloperName = 'CHANGE_MODIFIED',
                PJN_Message__c = PJN_NetworkConstants.DCR_STATUS_REJECTED
            )
        );

        networkStatusMappings.add(
            new PJN_Network_Status_Mapping__mdt(
                Label = 'CHANGE_ALREADYAPPLIED',
                DeveloperName = 'CHANGE_ALREADYAPPLIED',
                PJN_Message__c = PJN_NetworkConstants.DCR_STATUS_APPROVED
            )
        );

        networkStatusMappings.add(
            new PJN_Network_Status_Mapping__mdt(
                Label = 'CHANGE_ADDED',
                DeveloperName = 'CHANGE_ADDED',
                PJN_Message__c = PJN_NetworkConstants.DCR_STATUS_REJECTED
            )
        );

        return networkStatusMappings;
    }
}