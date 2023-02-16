/**
 * Queue Network sync for all HCP and Radiologist
 * @author  Mavens
 * @group   Network
 */
public class PJN_NetworkSyncQueueable implements Queueable, Database.AllowsCallouts {

    /**
     * Max records proceed during on queue
     */
    private static final Integer QUEUE_DATA_SIZE = 1000;

    /**
     * List of account to sync
     */
    private List<Account> accounts;

    /**
     * Constructor calling all allowed account to be synced order by Last Date Network Synced and Modified
     */
    public PJN_NetworkSyncQueueable() {
        List<String>  accountRecordTypesAllowed = String.isNotBlank(PJN_NetworkObjectSetting.getSettingByName('Account').PJN_Sync_Record_Types_Allowed__c) ?
            PJN_NetworkObjectSetting.getSettingByName('Account').PJN_Sync_Record_Types_Allowed__c.toLowerCase().split(',') :
            new List<String>();

        Set<Id> accountIds = getAccountIdsWithSubmittedDCR();

        String query = String.format(
            'SELECT Id, PJN_Veeva_Network_Id__c FROM Account WHERE (PJN_Veeva_Network_Id__c != null OR Id IN :accountIds) {0} ORDER BY PJN_Last_Date_Network_Synced__c, PJN_Last_Date_Network_Modified__c',
            new List<String> {
                accountRecordTypesAllowed.contains('all') ? '' : 'AND RecordType.DeveloperName IN :accountRecordTypesAllowed'
            }
        );

        accounts = (List<Account>) Database.query(query);
    }

    private static Set<Id> getAccountIdsWithSubmittedDCR() {
        Set<Id> accountIdsWithSubmittedDCR = new Set<Id>();

        List<PJN_Data_Change_Request__c> dcrs = [
            SELECT
                PJN_Account__c
            FROM
                PJN_Data_Change_Request__c
            WHERE
                PJN_Account__c != null
            AND
                PJN_Status__c = :PJN_NetworkConstants.DCR_STATUS_SUBMITTED
        ];

        for (PJN_Data_Change_Request__c dcr : dcrs) {
            accountIdsWithSubmittedDCR.add(dcr.PJN_Account__c);
        }

        return accountIdsWithSubmittedDCR;
    }

    /**
     * Constructor passing account remaining to be synced
     * @param accounts
     */
    public PJN_NetworkSyncQueueable(List<Account> accounts) {
        accounts = this.accounts;
    }


    /**
     * Queue execute method
     * @param context
     */
    public void execute(QueueableContext context) {
        if (PJN_NetworkCallout.noRunInTest || accounts == null || accounts.isEmpty()) {
            return;
        }

        Set<String> accountIds = new Set<String>();

        Integer lastListIndex = accounts.size()-1;
        Integer minIndex = (lastListIndex - QUEUE_DATA_SIZE) >= 0 ?
            lastListIndex - QUEUE_DATA_SIZE :
            0;

        for (Integer accIndex = lastListIndex; accIndex >= minIndex; accIndex--) {
            Account thisAccount = accounts.remove(accIndex);
            accountIds.add(thisAccount.Id);
        }

        PJN_NetworkSync networkSync = new PJN_NetworkSync(accountIds);
        networkSync.sync();

        if (!this.accounts.isEmpty()) {
            System.enqueueJob(this);
        }
    }
}