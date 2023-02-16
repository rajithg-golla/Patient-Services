/**
 * @author      Mavens
 * @group       ConnectiveRx
 * @description Wrapper for the Contact Point in the Enrollment Request
 */
public with sharing class MVN_ConnectiveRxEnrollContactPoint {

    /**
     * JSON Parameters requesting into ConnectiveRx Contact Points
     */
    public String extension;
    public String mvn_connectiverx_number;
    public String type;
    public String use;
    public Integer ordinal;
    public String emailAddress;
    public String value;

    /**
     * Contructor to populate the Contact Points for ConnectiveRx
     * @param phoneNumber   Phone number as string
     * @param phoneUse      Phone use as string ("Home","Work"...)
     */
    public MVN_ConnectiveRxEnrollContactPoint(String phoneNumber, String phoneUse) {
        this.mvn_connectiverx_number = phoneNumber;
        this.value = phoneNumber;
        this.type = Label.MVN_CRX_Enroll_Phone_Type; // always "phone"
        this.use = phoneUse;
    }
}