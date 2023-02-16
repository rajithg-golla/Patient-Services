/**
 * @author      Mavens
 * @group       Orsini
 * @description Wrapper for the Orsini Patient API Fulfillment
 */
public with sharing class MVN_OrsiniPatientFulfillment {

    /**
     * JSON parameters to response for the Fulfillment
     */
    public String id;
    public Datetime transaction_date;
    public String hub_patient_id;
    public String patient_last_name;
    public String patient_first_name;
    public Date patient_dob;
    public String patient_gender;
    public String patient_addr1;
    public String patient_addr2;
    public String patient_city;
    public String patient_state;
    public String patient_zip;
    public String patient_phone_number;
    public String dx_1;
    public String dx_2;
    public String hcp_last_name;
    public String hcp_first_name;
    public String hcp_addr1;
    public String hcp_addr2;
    public String hcp_city;
    public String hcp_state;
    public String hcp_zip;
    public String hcp_phone;
    public String hcp_fax;
    public String hcp_npi;
    public String hcp_facility;
    public Datetime rx_date;
    public String ndc;
    public String primary_coverage_type;
    public String primary_payer;
    public String primary_payer_type;
    public String primary_payer_subtype;
    public String primary_payer_group;
    public String primary_payer_bin;
    public String primary_payer_iin;
    public String primary_payer_pcn;
    public String primary_plan;
    public String primary_plan_type;
    public String secondary_coverage_type;
    public String secondary_payer;
    public String secondary_payer_type;
    public String secondary_payer_subtype;
    public String secondary_payer_group;
    public String secondary_payer_bin;
    public String secondary_payer_iin;
    public String secondary_payer_pcn;
    public String secondary_plan;
    public String secondary_plan_type;
    public Decimal primary_copay;
    public Decimal primary_coins;
    public Decimal secondary_copay;
    public Decimal secondary_coins;
    public String case_id;
    public String copay_program_number;
    public String copay_group;
    public String copay_bin;
    public String copay_pcn;
    public String hofh_diagnosis;
    public String clinical_trial_transition;
    public String hi_consent_received;
    public String certification_consent_received;
    public String pap_consent_received;
    public List<MVN_OrsiniPatientFile> attachments;

    /**
     * Gender Mapping from SFDC to Orsini
     */
    public static final Map<String, String> GENDER_MAPPING = new Map<String, String> {
        'male' => 'M',
        'female' => 'F'
    };

    /**
     * Consent Mapping from SFDC to Orsini
     */
    public static final Map<String, String> CONSENT_MAPPING = new Map<String, String> {
        'opt in' => 'Y',
        'opt out' => 'N',
        'not given' => 'N'
    };

    /**
     * Constructor to build the Orsini fulfillment from SFDC Fulfillment record
     * @param fulfillmentRequest
     */
    public MVN_OrsiniPatientFulfillment(PJN_Fulfillment_Request__c fulfillmentRequest) {
        this.transaction_date = System.now();
        this.id = fulfillmentRequest.Id;
        this.hub_patient_id = fulfillmentRequest.MVN_Patient_Id__c;
        this.patient_last_name = fulfillmentRequest.PJN_Patient_Last_Name__c;
        this.patient_first_name = fulfillmentRequest.PJN_Patient_First_Name__c;
        this.patient_dob = fulfillmentRequest.PJN_Patient_DOB__c;
        this.patient_gender = getGenderMapped(fulfillmentRequest.PJN_Patient_Gender__c);
        this.patient_addr1 = fulfillmentRequest.PJN_Patient_Address_Line_1__c;
        this.patient_addr2 = fulfillmentRequest.PJN_Patient_Address_Line_2__c;
        this.patient_city = fulfillmentRequest.PJN_Patient_City__c;
        this.patient_state = fulfillmentRequest.PJN_Patient_State__c;
        this.patient_zip = getZipCodeFiveChars(fulfillmentRequest.PJN_Patient_Postal_Code__c);
        this.patient_phone_number = getStringWithAllNonDigitsRemoved(fulfillmentRequest.PJN_Patient_Phone__c);
        this.dx_1 = fulfillmentRequest.MVN_ICD_10_CM_Diagnosis_Code__c;
        this.dx_2 = fulfillmentRequest.MVN_Other_Diagnosis__c;
        this.hcp_last_name = fulfillmentRequest.PJN_Physician_Last_Name__c;
        this.hcp_first_name = fulfillmentRequest.PJN_Physician_First_Name__c;
        this.hcp_addr1 = fulfillmentRequest.PJN_Physician_Address_Line_1__c;
        this.hcp_addr2 = fulfillmentRequest.PJN_Physician_Address_Line_2__c;
        this.hcp_city = fulfillmentRequest.PJN_Physician_City__c;
        this.hcp_state = fulfillmentRequest.PJN_Physician_State__c;
        this.hcp_zip = getZipCodeFiveChars(fulfillmentRequest.PJN_Physician_Postal_Code__c);
        this.hcp_phone = getStringWithAllNonDigitsRemoved(fulfillmentRequest.PJN_Physician_Phone__c);
        this.hcp_fax = getStringWithAllNonDigitsRemoved(fulfillmentRequest.PJN_Physician_Fax__c);
        this.hcp_npi = fulfillmentRequest.PJN_Physician_NPI__c;
        this.hcp_facility = fulfillmentRequest.MVN_Practice_Name__c;
        this.rx_date = fulfillmentRequest.PJN_Date_of_Rx__c;
        this.ndc = getStringWithAllNonDigitsRemoved(fulfillmentRequest.PJN_NDC__c);
        this.primary_coverage_type = fulfillmentRequest.MVN_Primary_Coverage_Type__c;
        this.primary_payer = fulfillmentRequest.PJN_Primary_Payer_Name__c;
        this.primary_payer_type = fulfillmentRequest.PJN_Primary_Payer_Type__c;
        this.primary_payer_group = fulfillmentRequest.PJN_Primary_Group__c;
        this.primary_payer_bin = fulfillmentRequest.PJN_Primary_BIN__c;
        this.primary_payer_pcn = fulfillmentRequest.PJN_Primary_PCN__c;
        this.primary_plan = fulfillmentRequest.PJN_Primary_Plan_Name__c;
        this.secondary_coverage_type = fulfillmentRequest.MVN_Secondary_Coverage_Type__c;
        this.secondary_payer = fulfillmentRequest.PJN_Secondary_Payer_Name__c;
        this.secondary_payer_type = fulfillmentRequest.PJN_Secondary_Payer_Type__c;
        this.secondary_payer_group = fulfillmentRequest.PJN_Secondary_Group__c;
        this.secondary_payer_bin = fulfillmentRequest.PJN_Secondary_BIN__c;
        this.secondary_payer_pcn = fulfillmentRequest.PJN_Secondary_PCN__c;
        this.secondary_plan = fulfillmentRequest.PJN_Secondary_Plan_Name__c;
        this.primary_copay = getDecimalFromField(fulfillmentRequest.PJN_Primary_Copay__c);
        this.primary_coins = getDecimalFromField(fulfillmentRequest.PJN_Primary_Copay__c);//We store this as one value in MVN_Drug_Copay_Coinsurance__c.
        this.secondary_copay = getDecimalFromField(fulfillmentRequest.PJN_Secondary_Copay__c);
        this.secondary_coins = getDecimalFromField(fulfillmentRequest.PJN_Secondary_Copay__c);//We store this as one value in MVN_Drug_Copay_Coinsurance__c.
        this.case_id = fulfillmentRequest.PJN_Care_Plan__c;
        this.copay_program_number = fulfillmentRequest.MVN_Copay_Member_Id__c;
        this.copay_group = fulfillmentRequest.MVN_Copay_Group_Number__c;
        this.copay_bin = fulfillmentRequest.MVN_Copay_BIN__c;
        this.copay_pcn = fulfillmentRequest.MVN_Copay_PCN__c;
        this.hofh_diagnosis = getHoFHMapped(fulfillmentRequest.MVN_Patient_Diagnosis__c);
        this.clinical_trial_transition = getBooleanMapped(fulfillmentRequest.MVN_Clinical_Trial_Transition_Patient__c);
        this.hi_consent_received = getConsentMapped(fulfillmentRequest.PJN_HIPPA_Consent_Status__c);
        this.certification_consent_received = getConsentMapped(fulfillmentRequest.MVN_Program_Consent_Status__c);
        this.pap_consent_received = getConsentMapped(fulfillmentRequest.MVN_PAP_Consent_Status__c);
    }

    /**
     * Add Files to the Fulfillment Response
     * @param files Content Versions
     */
    public void addFiles(List<ContentVersion> files) {
        this.attachments = new List<MVN_OrsiniPatientFile>();
        Integer currentIndex = 0;
        Datetime currentDatetime = System.now();
        for (ContentVersion file : files) {
            file.Title = getCurrentFileName(this.hub_patient_id, currentDatetime.addSeconds(currentIndex));
            this.attachments.add(new MVN_OrsiniPatientFile(file));
            currentIndex++;
        }
    }

    /**
     * Get new File name to be able to extract by Orsini
     * @param hubPatientId      Current HUB Patient Id
     * @param currentDatetime   Current Date time adapted to be unique
     * @return  `String`
     */
    private static String getCurrentFileName(String hubPatientId, Datetime currentDatetime) {
        return hubPatientId + '_' + currentDatetime.format('yyyyMMddHHmmss', 'America/New_York');
    }

    /**
     * Get Gender Mapped using Gender SFDC to Orsini Mapping
     * @param gender    SFDC Gender
     * @return  `String`
     */
    private static String getGenderMapped(String gender) {
        return String.isNotBlank(gender) && GENDER_MAPPING.containsKey(gender.toLowerCase()) ?
            GENDER_MAPPING.get(gender.toLowerCase()) :
            'U';
    }

    /**
     * Get first 5 Zip code digits
     * @param postalCode    SFDC Postal Code
     * @return  `String`
     */
    private static String getZipCodeFiveChars(String postalCode) {
        return String.isNotBlank(postalCode) ?
            postalCode.substring(0, 5) :
            null;
    }

    /**
     * Get HoFH Value translated to Orsini HoFH value
     * @param hofhValue SFDC HoFH Value
     * @return  `String`
     */
    private static String getHoFHMapped(String hofhValue) {
        return String.isNotBlank(hofhValue) && hofhValue.toLowerCase() == 'hofh' ?
            'Y' :
            'N';
    }

    /**
     * Get Boolean mapped to Y/N string value accepted in Orsini
     * @param value Boolean value
     * @return  `String`
     */
    private static String getBooleanMapped(Boolean value) {
        return value != null && value ? 'Y' : 'N';
    }

    /**
     * Get Consent Mapped using Consent SFDC to Orsini Mapping
     * @param consentReceived   SFDC Consent
     * @return  `String`
     */
    private static String getConsentMapped(String consentReceived) {
        return String.isNotBlank(consentReceived) && CONSENT_MAPPING.containsKey(consentReceived.toLowerCase()) ?
            CONSENT_MAPPING.get(consentReceived.toLowerCase()) :
            'N';
    }

    /**
     * Remove all NON-Digits from String provided
     * @param textToReplace String provided
     * @return  `String`
     */
    private static String getStringWithAllNonDigitsRemoved(String textToReplace) {
        return String.isNotBlank(textToReplace) ?
            textToReplace.replaceAll('[^0-9]', '') :
            textToReplace;
    }

    /**
     * Transform String to Decimal
     * @param textToDecimal
     * @return  `Decimal`
     */
    private static Decimal getDecimalFromField(String textToDecimal) {
        return String.isNotBlank(textToDecimal) ?
            Decimal.valueOf(textToDecimal.replaceAll('[^0-9.]', '')) :
            null;
    }
}