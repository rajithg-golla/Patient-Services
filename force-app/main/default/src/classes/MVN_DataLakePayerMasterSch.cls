/**
 * @author      Mavens
 * @group       DataLake
 * @description Schedule DataLake Payer Master retrieve process
 */
public with sharing class MVN_DataLakePayerMasterSch implements Schedulable {

    /**
     * Schedule execute method which will queue the datalake payer master retrieve process
     * @param SC    Schedule context
     */
    public void execute (SchedulableContext SC) {
        System.enqueueJob(new MVN_DataLakePayerMasterQueue(null));
    }
}