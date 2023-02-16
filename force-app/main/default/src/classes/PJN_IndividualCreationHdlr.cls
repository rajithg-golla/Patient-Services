/**
 * @author      Mavens
 * @group       Individual
 * @description create Individual record on person account creation, also update the account with the reference
 */
public with sharing class PJN_IndividualCreationHdlr implements PJN_TriggerDispatcher.HandlerInterface {
    /**
     * handle before insert trigger context
     */
    public void handle() {
        List<Individual> individualsToInsert = new List<Individual>();
        for(Account thisAccount : (List<Account>) trigger.new) {
            if(thisAccount.IsPersonAccount && thisAccount.PersonIndividualId == null) {
                individualsToInsert.add(
                    new Individual(
                        FirstName = thisAccount.FirstName,
                        LastName = thisAccount.LastName
                    )
                );
            }
        }
        if(!individualsToInsert.isEmpty()) {
            insert individualsToInsert;
            Integer index = 0;
            for(Account thisAccount : (List<Account>) trigger.new) {
                if(thisAccount.IsPersonAccount && thisAccount.PersonIndividualId == null) {
                    thisAccount.PersonIndividualId = individualsToInsert.get(index).Id;
                    index++;
                }
            }
        }
    }
}