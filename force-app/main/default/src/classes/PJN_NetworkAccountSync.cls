/**
 * Network Account Sync controller
 * @author  Mavens
 * @since   Network
 */
public with sharing class PJN_NetworkAccountSync {

    @AuraEnabled
    public static Boolean syncAccount(Id recordId, String fields) {
        Set<String> accountIds = new Set<String>();

        if (String.isBlank(fields)) {
            accountIds.add(recordId);
        } else {
            accountIds.addAll(getAccountIds(recordId, fields));
        }

        PJN_NetworkSync networkSync = new PJN_NetworkSync(accountIds);
        Boolean response = networkSync.sync();

        queueSyncAccount();

        return response;
    }

    private static Set<String> getAccountIds(Id recordId, String fields) {
        String query = String.format(
            'SELECT {0} FROM {1} WHERE Id = :recordId',
            new List<String> {
                fields,
                recordId.getSobjectType().getDescribe().getName()
            }
        );

        SObject record = Database.query(query);
        Set<String> accountIds = new Set<String>();

        for (String field : fields.split(',')) {
            String currentAccountId = String.valueOf(record.get(field));
            if (String.isNotBlank(currentAccountId)) {
                accountIds.add(currentAccountId);
            }
        }

        return accountIds;
    }

    @Future
    private static void queueSyncAccount() {
        List<AsyncApexJob> asyncApexJobs = [
            SELECT
                Id,
                MethodName
            FROM
                AsyncApexJob
            WHERE
                ApexClass.Name = 'PJN_NetworkSyncQueueable'
            AND
                Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
            AND
                JobType = 'Queueable'
        ];

        if (!asyncApexJobs.isEmpty()) {
            return;
        }

        System.debug(LoggingLevel.DEBUG, PJN_NetworkConstants.NETWORK_DEBUG + '::asyncApexJobs: ' + asyncApexJobs);
        PJN_NetworkSyncQueueable networkSyncQueueable = new PJN_NetworkSyncQueueable();
        System.enqueueJob(networkSyncQueueable);
    }
}