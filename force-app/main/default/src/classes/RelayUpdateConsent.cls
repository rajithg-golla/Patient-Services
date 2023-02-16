public with sharing class RelayUpdateConsent implements Queueable, Database.AllowsCallouts {
    private List<Relay.ConsentUpdate> consentUpdates;

    public RelayUpdateConsent(List<Relay.ConsentUpdate> batch) {
        this.consentUpdates = batch;
    }

    public void execute(QueueableContext context) {
        Integer i = 0;
        List<Relay.ConsentUpdate> partialBatch = new List<Relay.ConsentUpdate>();

        while (!consentUpdates.isEMpty()) {
            partialBatch.add(consentUpdates.remove(0));
            if (partialBatch.size() == 200 || consentUpdates.isEmpty() ) {
                Relay.updateConsentBatch(partialBatch);
                if (++i == 100) {
                    // We hit the limit of callouts per job so let's chain another job
                    // with the remainder of the list
                    System.debug('split job');
                    System.enqueueJob(new RelayUpdateConsent(consentUpdates));
                    return;
                }
            }
        }
    }
}