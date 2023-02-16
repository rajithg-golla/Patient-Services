/**
 * @author      Mavens
 * @group       ConnectiveRx
 * @description Test for MVN_CarePlanElapsedTimeCal
 */
@IsTest
public with sharing class MVN_CarePlanElapsedTimeCalTest {
  
    @isTest private static void elapsedTimeIsAddedDedsiTest(){
        Account expectedAccount = new Account(
            LastName = 'Test Account',
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Program_Participant_MVN').getRecordTypeId()
        );
        insert expectedAccount;

        Case expectedCarePlan = new Case(
            AccountId = expectedAccount.Id,
            Subject = 'Test Careplan',
            PJN_Program_DeveloperName__c = 'DEDSI'
        );
        insert expectedCarePlan;

        Case ca = [Select Id, Status From Case Limit 1];
        Test.startTest();
            ca.Status = 'Closed';
            update ca;
        Test.stopTest();
        Case updatedCase = [Select Id, Status, CreatedDate, ClosedDate, MVN_Elapsed_Time__c From Case Limit 1];
        System.assertNotEquals(null, updatedCase.MVN_Elapsed_Time__c);
    }

    @isTest private static void elapsedTimeIsAddedmvnevkTest(){
        Account expectedAccount = new Account(
            LastName = 'Test Account',
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Program_Participant_MVN').getRecordTypeId()
        );
        insert expectedAccount;

        Case expectedCarePlan = new Case(
            AccountId = expectedAccount.Id,
            Subject = 'Test Careplan',
            PJN_Program_DeveloperName__c = 'MVN_EVK'
        );
        insert expectedCarePlan;

        Case ca = [Select Id, Status From Case Limit 1];
        Test.startTest();
            ca.Status = 'Closed';
            update ca;
        Test.stopTest();
        Case updatedCase = [Select Id, Status, CreatedDate, ClosedDate, MVN_Elapsed_Time__c From Case Limit 1];
        System.assertNotEquals(null, updatedCase.MVN_Elapsed_Time__c);
    }
    @isTest private static void elapsedTimeIsAddedmvnlcmTest(){
        Account expectedAccount = new Account(
            LastName = 'Test Account',
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Program_Participant_MVN').getRecordTypeId()
        );
        insert expectedAccount;

        Case expectedCarePlan = new Case(
            AccountId = expectedAccount.Id,
            Subject = 'Test Careplan',
            PJN_Program_DeveloperName__c = 'MVN_LCM'
        );
        insert expectedCarePlan;

        Case ca = [Select Id, Status From Case Limit 1];
        Test.startTest();
            ca.Status = 'Closed';
            update ca;
        Test.stopTest();
        Case updatedCase = [Select Id, Status, CreatedDate, ClosedDate, MVN_Elapsed_Time__c From Case Limit 1];
        System.assertNotEquals(null, updatedCase.MVN_Elapsed_Time__c);
    }
    @isTest private static void elapsedTimeIsAddedmvnlbtTest(){
        Account expectedAccount = new Account(
            LastName = 'Test Account',
            RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Program_Participant_MVN').getRecordTypeId()
        );
        insert expectedAccount;

        Case expectedCarePlan = new Case(
            AccountId = expectedAccount.Id,
            Subject = 'Test Careplan',
            PJN_Program_DeveloperName__c = 'MVN_LBT'
        );
        insert expectedCarePlan;

        Case ca = [Select Id, Status From Case Limit 1];
        Test.startTest();
            ca.Status = 'Closed';
            update ca;
        Test.stopTest();
        Case updatedCase = [Select Id, Status, CreatedDate, ClosedDate, MVN_Elapsed_Time__c From Case Limit 1];
        System.assertNotEquals(null, updatedCase.MVN_Elapsed_Time__c);
    }
}