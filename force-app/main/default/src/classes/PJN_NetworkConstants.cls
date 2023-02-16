/**
 * Apex class to call Veeva Network API
 * @author  Mavens
 * @group   Network
 */
public with sharing class PJN_NetworkConstants {

    /**
     * Veeva Network Debug name
     */
    public static final String NETWORK_DEBUG = 'Network';

    /**
     * Veeva Network System name
     */
    public static final String NETWORK_SYSTEM = 'PJN';

    /**
     * Veeva Network Named credential
     */
    public static final String NETWORK_NAMED_CREDENTIAL = 'PJN_Veeva_Network';

    /**
     * Veeva Network API version
     */
    public static final String NETWORK_API_VERSION = 'v19.0';

    /**
     * DCR Account Record type developer name
     */
    public static final String DCR_ACCOUNT = 'PJN_Account';

    /**
     * DCR Address Record type developer name
     */
    public static final String DCR_ADDRESS = 'PJN_Contact_Information';

    /**
     * DCR License Record type developer name
     */
    public static final String DCR_LICENSE = 'PJN_License';

    /**
     * Network Account Name
     */
    public static final String NETWORK_ACCOUNT_TYPE = 'ACCOUNT';

    /**
     * Network Address Name
     */
    public static final String NETWORK_ADDRESS_TYPE = 'ADDRESS';

    /**
     * Network License Address ID Field name
     */
    public static final String NETWORK_DCR_LICENSE_ADDRESS_ID_FIELD = 'address_vid_key';

    /**
     * Network License Address ID Field name
     */
    public static final String NETWORK_SYNC_LICENSE_ADDRESS_ID_FIELD = 'address_vid__v';

    /**
     * Network License Name
     */
    public static final String NETWORK_LICENSE_TYPE = 'LICENSE';

    /**
     * Invalid session name
     */
    public static final String NETWORK_INVALID_SESSION = 'INVALID_SESSION';

    /**
     * Success status
     */
    public static final String NETWORK_SUCCESS = 'SUCCESS';

    /**
     * Partial Success status
     */
    public static final String NETWORK_PARTIAL_SUCCESS = 'PARTIAL_SUCCESS';

    /**
     * Failure status
     */
    public static final String NETWORK_FAILURE = 'FAILURE';

    /**
     * DCR STATUS PENDING
     */
    public static final String DCR_STATUS_PENDING = 'Pending';

    /**
     * DCR STATUS SUBMITTED
     */
    public static final String DCR_STATUS_SUBMITTED = 'Submitted';

    /**
     * DCR STATUS CANCELLED
     */
    public static final String DCR_STATUS_CANCELLED = 'Cancelled';

    /**
     * DCR STATUS PROCESSED
     */
    public static final String DCR_STATUS_PROCESSED = 'Processed';

    /**
     * DCR STATUS UPDATED
     */
    public static final String DCR_STATUS_UPDATED = 'Updated';

    /**
     * DCR STATUS APPROVED
     */
    public static final String DCR_STATUS_APPROVED = 'Approved';

    /**
     * DCR STATUS REJECTED
     */
    public static final String DCR_STATUS_REJECTED = 'Rejected';

    /**
     * DCR TYPE DELETE
     */
    public static final String DCR_TYPE_DELETE = 'Delete';

    /**
     * DCR TYPE NEW
     */
    public static final String DCR_TYPE_NEW = 'New';

    /**
     * DCR TYPE EDIT
     */
    public static final String DCR_TYPE_EDIT = 'Edit';
}