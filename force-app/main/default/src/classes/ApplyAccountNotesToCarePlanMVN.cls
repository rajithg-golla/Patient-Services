/**
 * @author      Mavens
 * @group       ApplyAccountNotesToCarePlanMVN
 * @description Add link for notes from parent account to a care plan.
 *              This is intented to be called from a lead convert flow to get notes onto the new care plan
 */
public with sharing class ApplyAccountNotesToCarePlanMVN {
   
    @InvocableMethod(label='Apply Account Notes to Care Plan' description='Applies Account Notes to Care Plan' category='Case')
    public static void applyNotes(List<Id> carePlanIds) {
        Map<Id, Case> carePlansByAccountId = getCarePlansByAccountId(carePlanIds);
        
        List<ContentDocumentLink> noteLinks = queryNoteLinksForParentAccounts(carePlansByAccountId.keySet());
        
        List<ContentDocumentLink> newNoteLinks = new List<ContentDocumentLink>();
        for (ContentDocumentLink noteLink : noteLinks) {
            ContentDocumentLink clonedLink = noteLink.clone(false,false,false,false);
            clonedLink.LinkedEntityId = carePlansByAccountId.get(noteLink.LinkedEntityId).Id;                
            newNoteLinks.add(clonedLink);
        }

        insert newNoteLinks;
    }

     /*
     * Query for care plans and arrange them by account id
     * @param carePlanIds
     * @return Map<Id, Case>
     */
    private static Map<Id, Case> getCarePlansByAccountId(List<Id> carePlanIds) {
    
        Map<Id, Case> carePlansByAccountId = new Map<Id, Case>();

        List<Case> carePlans = [
            SELECT Id, AccountId
            FROM Case
            WHERE Id IN :carePlanIds
        ];

        for (Case carePlan : carePlans) {
            // this is meant to be invoked during the conversion of a lead
            // so only one care plan is assumed to exist per account
            carePlansByAccountId.put(carePlan.AccountId, carePlan);
        }

        return carePlansByAccountId;
    }

    /*
     * Query for all content document links for given accounts
     * @param accountIds
     * @return List<ContentDocumentLink>
     */
    private static List<ContentDocumentLink> queryNoteLinksForParentAccounts(Set<Id> accountIds) {
        return [
            SELECT
                ContentDocumentId, 
                LinkedEntityId,
                ShareType
            FROM 
                ContentDocumentLink 
            WHERE
                LinkedEntityId IN :accountIds
            AND
                ContentDocument.FileType = 'SNOTE'
        ];
    }
}