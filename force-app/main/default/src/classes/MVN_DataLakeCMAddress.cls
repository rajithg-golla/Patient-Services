/**
 * @author      Mavens
 * @group       DataLake
 * @description Wrapper for the MVN_DataLakeCMAddress Address DataLake Object
 */
public with sharing class MVN_DataLakeCMAddress {

    /**
     * DataLake Address objects
     */
    public String addr_id;
    public String addr_country;
    public String addr_address_line1;
    public String addr_address_line2;
    public String addr_city;
    public String addr_state;
    public String addr_postal_zip_code;
    public String addr_valid_status;
    public String primary_addr_ind;
    public String parent_id;

    /**
     * Search Address Populated Fields
     */
    private Map<String, Object> reqAddressPopulatedFields;

    /**
     * Country Mapping from and to Datalake
     */
    private static final Map<String, String> COUNTRY_MAPPING = new Map<String, String> {
        'us' => 'United States',
        'united states' => 'US'
    };

    /**
     * Constructor to get all search fields and store into this wrapper to build they query
     * @param reqAddressPopulatedFields Address Search populated fields
     */
    public MVN_DataLakeCMAddress(Map<String, Object> reqAddressPopulatedFields) {
        this.reqAddressPopulatedFields = reqAddressPopulatedFields;
        if (this.reqAddressPopulatedFields == null || this.reqAddressPopulatedFields.isEmpty()) {
            return;
        }
        this.addr_id = MVN_DataLakeCMSearchUtil.getStringValue(this.reqAddressPopulatedFields, 'id');
        this.addr_country = getCountryMapped(MVN_DataLakeCMSearchUtil.getStringValue(this.reqAddressPopulatedFields, 'PJN_Country__c'));
        this.addr_address_line1 = MVN_DataLakeCMSearchUtil.getStringValue(this.reqAddressPopulatedFields, 'PJN_Address_Line_1__c');
        this.addr_address_line2 = MVN_DataLakeCMSearchUtil.getStringValue(this.reqAddressPopulatedFields, 'PJN_Address_Line_2__c');
        this.addr_city = MVN_DataLakeCMSearchUtil.getStringValue(this.reqAddressPopulatedFields, 'PJN_City__c');
        this.addr_state = MVN_DataLakeCMSearchUtil.getStringValue(this.reqAddressPopulatedFields, 'PJN_State__c');
        this.addr_postal_zip_code = MVN_DataLakeCMSearchUtil.getStringValue(this.reqAddressPopulatedFields, 'PJN_Postal_Code__c');
        this.addr_valid_status = 'Y';
    }

    /**
     * Get Address Search filter using the populated fields
     * @return  `String`
     */
    public String getSearchFilters() {
        String filters = '';
        if (String.isNotBlank(this.addr_city)) {
            filters += MVN_DataLakeCMSearchUtil.getFieldFilter('addr_city', this.addr_city);
        }
        if (String.isNotBlank(this.addr_state)) {
            filters += MVN_DataLakeCMSearchUtil.getFieldFilter('addr_state', this.addr_state);
        }
        if (String.isNotBlank(filters)) {
            MVN_DataLakeCMSearchHdlr.hasSearchFilter = true;
            filters += 'Upper(addr_valid_status) = \'' + this.addr_valid_status + '\' AND ';
        }
        return filters.substringBeforeLast(' AND ');
    }

    /**
     * Get SFDC Record using the wrapper parameters obtained from the search
     * @return  `PJN_Contact_Information__c`
     */
    public PJN_Contact_Information__c getSFDCRecord() {
        PJN_Contact_Information__c ci = new PJN_Contact_Information__c (
            RecordTypeId = Schema.SObjectType.PJN_Contact_Information__c.getRecordTypeInfosByDeveloperName().get('PJN_Address').getRecordTypeId(),
            PJN_Address_Line_1__c = this.addr_address_line1,
            PJN_Address_Line_2__c = this.addr_address_line2,
            PJN_Set_as_Primary__c = getPrimaryMapped(this.primary_addr_ind),
            PJN_City__c = this.addr_city,
            PJN_State__c = this.addr_state,
            PJN_Postal_Code__c = this.addr_postal_zip_code,
            PJN_Status__c = MVN_DataLakeCMSearchUtil.getStatusFromMapped(this.addr_valid_status),
            PJN_External_Id__c = this.addr_id
        );
        ci.PJN_Country__c = getCountryMapped(this.addr_country);
        return ci;
    }

    /**
     * Get Country value mapped
     * Defaulting to United States because DataLake does not store country and it cause an error in SFDC if brings the State
     * @param value country value
     * @return  `String`
     */
    private static String getCountryMapped(String value) {
        return String.isNotBlank(value) && COUNTRY_MAPPING.containsKey(value.toLowerCase()) ?
            COUNTRY_MAPPING.get(value.toLowerCase()) :
            'United States';
    }

    /**
     * Get Primary flag mapped from Datalake where 1 is Primary and 0 is non primary
     * @param value Datalake primary flag value
     * @return  `Boolean`
     */
    private static Boolean getPrimaryMapped(String value) {
        return String.isNotBlank(value) && value == '1';
    }
}