/**
 * @author      Mavens
 * @group       ConnectiveRx
 * @description Wrapper for the Membership in the Enrollment Request
 */
public with sharing class MVN_ConnectiveRxEnrollMembership {

    /**
     * JSON Parameters requesting into ConnectiveRx Membership
     */
    public String program;
    public String groupNumber;
    public String memberId;
    public String bin;
    public String pcn;
    public Boolean isActivated;
    public Datetime issuedDate;
    public Datetime effectiveDate;
    public Datetime activatedDate;
    public Datetime expirationDate;
    public Datetime deactivatedDate;
    public Integer programCap;
    public Integer totalUses;
    public Integer usagePeriodValue;
    public String usagePeriodUnit;
    public Boolean isActive;
}