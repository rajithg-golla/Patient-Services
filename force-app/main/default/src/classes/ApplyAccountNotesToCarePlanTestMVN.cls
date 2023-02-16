/**
 * @author      Mavens
 * @group       ApplyAccountNotesToCarePlanMVN
 * @description Unit tests for ApplyAccountNotesToCarePlanMVN
 */
@isTest
public class ApplyAccountNotesToCarePlanTestMVN {

    private static final Integer DATA_SIZE = 30;

    @TestSetup
    static void makeData(){
        Test.startTest();
        List<Account> programParticipants = new List<Account>();
        List<ContentNote> newNotes = new List<ContentNote>();

        for (Integer i=0; i<DATA_SIZE; i++) {
            programParticipants.add(
                new Account(
                    LastName = 'Test Account' + i,
                    RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Program_Participant_MVN').getRecordTypeId()
                )
            );

            newNotes.add(
                new ContentNote(
                    Title = 'Test',
                    Content = Blob.valueOf('Test Note Body')
                )
            );
        }
        insert programParticipants;
        insert newNotes;

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (Integer i=0; i<DATA_SIZE; i++) {
            links.add(
                new ContentDocumentLink(
                    ContentDocumentId = newNotes[i].Id,
                    LinkedEntityId = programParticipants[i].Id,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                )
            );
        }

        insert links;
        Test.stopTest();
    }

    @isTest
    private static void itShouldAddNotesLinksToCarePlans() {
        List<Case> carePlans = createCarePlans();
        insert carePlans;

        Map<Id, Case> carePlansById = new Map<Id, Case>(carePlans);
        List<Id> carePlanIds = new List<Id>(carePlansById.keySet());
        Test.startTest();
        ApplyAccountNotesToCarePlanMVN.applyNotes(carePlanIds);
        Test.stopTest();

        System.assertEquals(DATA_SIZE, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId IN :carePlanIds]);
    }

    private static List<Case> createCarePlans() {
        List<Case> newCarePlans = new List<Case>();
        Id carePlanRecTypeId = SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('CarePlan')
            .getRecordTypeId();
        List<Account> programParticipants = [SELECT Id FROM Account];

        for (Account programParticipant : programParticipants) {
            newCarePlans.add(
                new Case (
                    // set the override so tests don't rely on configuration
                    RecordTypeId = carePlanRecTypeId,
                    AccountId = programParticipant.Id
                )
            );
        }

        return newCarePlans;
    }
}