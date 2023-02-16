/**
 * @author      Mavens
 * @group       ConnectiveRx
 * @description Wrapper for Enrollment workflow
 */
public with sharing class MVN_ConnectiveRxEnrollWorkflow {

    /**
     * JSON Parameters from ConnectiveRx Workflow
     */
    public String name;
    public Map<String, Object> settings;

    /**
     * Constructor to populate the workflow for ConnectiveRx
     * @param name  Workflow name
     */
    public MVN_ConnectiveRxEnrollWorkflow(String name) {
        this.name = name;
    }
}