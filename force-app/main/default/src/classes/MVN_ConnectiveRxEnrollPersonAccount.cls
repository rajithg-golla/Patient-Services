/**
 * @author      Mavens
 * @group       ConnectiveRx
 * @description Wrapper for Person Account (such as Patient, Physician, Caregivers...) enrollment
 */
public with sharing class MVN_ConnectiveRxEnrollPersonAccount {

    /**
     * JSON Parameters from ConnectiveRx Person Account
     */
    public String partnerId;
    public String memberId;
    public String groupNumber;
    public String title;
    public String suffix;
    public String firstName;
    public String middleName;
    public String lastName;
    public String address1;
    public String address2;
    public String city;
    public String state;
    public String postalCode;
    public String countryCode;
    public String homePhone;
    public String mobilePhone;
    public String textPhone;
    public String workPhone;
    public String extension;
    public String fax;
    public String email;
    public String preferredContactMethod;
    public String preferredContactTime;
    public List<MVN_ConnectiveRxEnrollContactPoint> contactPoints;
    public String gender;
    public Date dob;
    public String salutation;
    public String ssn4;
    public String npi;
    public String specialty;
    public String organizationMasterId;
    public String relationship;
    public List<MVN_ConnectiveRxEnrollInsurance> insurances;
    public MVN_ConnectiveRxEnrollPersonAccount careGiver;
    public String id;
    public MVN_ConnectiveRxEnrollMembership membership;

    /**
     * Country code mapping from SFDC to ConnectiveRx
     */
    private static final Map<String, String> COUNTRY_CODE_BY_NAME = new Map<String, String> {
        'United States' => Label.MVN_CRX_Enroll_Default_Country
    };

    /**
     * Best Time mapping from SFDC to ConnectiveRx
     */
    private static final Map<String, String> BEST_TIME_MAPPING = new Map<String, String> {
        'morning' => 'morning',
        'afternoon' => 'mid-day',
        'evening' => 'evening',
        '' => 'unspecified',
        null => 'unspecified'
	};

    /**
     * Preferred Contact Method mapping from SFDC to ConnectiveRx
     */
    private static final Map<String, String> PREFERRED_CONTACT_MAPPING = new Map<String, String> {
        'phone' => 'mobile-phone',
        'fax' => 'fax',
        'email' => 'email',
        '' => 'unspecified',
        null => 'unspecified'
    };

    /**
     * Constructor to populate the Person Account for ConnectiveRx
     * @param fulfillmentRequest    Fulfillment Request record
     * @param personAccountType     Person Account type (patient, physician, caregiver)
     */
    public MVN_ConnectiveRxEnrollPersonAccount(PJN_Fulfillment_Request__c fulfillmentRequest, String personAccountType) {
        if (personAccountType.toLowerCase() == 'patient') {
            setPatient(fulfillmentRequest);
        } else if (personAccountType.toLowerCase() == 'physician') {
            setPhysician(fulfillmentRequest);
        } else if (personAccountType.toLowerCase() == 'caregiver') {
            setCaregiver(fulfillmentRequest);
        }
    }

    /**
     * Set Patient record for ConnectiveRx
     * @param fulfillmentRequest    Fulfillment Request record
     */
    private void setPatient(PJN_Fulfillment_Request__c fulfillmentRequest) {
        this.partnerId = fulfillmentRequest.MVN_Patient_Id__c;
        this.groupNumber = fulfillmentRequest.MVN_Copay_Group_Number__c;
        this.firstName = fulfillmentRequest.PJN_Patient_First_Name__c;
        this.middleName = fulfillmentRequest.PJN_Patient_Middle_Name__c;
        this.lastName = fulfillmentRequest.PJN_Patient_Last_Name__c;
        this.address1 = fulfillmentRequest.PJN_Patient_Address_Line_1__c;
        this.address2 = fulfillmentRequest.PJN_Patient_Address_Line_2__c;
        this.city = fulfillmentRequest.PJN_Patient_City__c;
        this.state = fulfillmentRequest.PJN_Patient_State__c;
        this.postalCode = fulfillmentRequest.PJN_Patient_Postal_Code__c;
        this.countryCode = COUNTRY_CODE_BY_NAME.containsKey(fulfillmentRequest.PJN_Patient_Country__c) ?
            COUNTRY_CODE_BY_NAME.get(fulfillmentRequest.PJN_Patient_Country__c) :
            null;
        this.email = fulfillmentRequest.PJN_Patient_Email__c;
        this.preferredContactMethod = getPreferredContactMethod(fulfillmentRequest.MVN_Patient_Preferred_Contact_Method__c);
        this.preferredContactTime = getPreferredContactTime(fulfillmentRequest.MVN_Patient_Best_Time__c);
        this.gender = String.isNotBlank(fulfillmentRequest.PJN_Patient_Gender__c) ? fulfillmentRequest.PJN_Patient_Gender__c.toLowerCase() : null;
        this.dob = fulfillmentRequest.PJN_Patient_dob__c;
        this.contactPoints = setPatientContactPoints(fulfillmentRequest);
        this.insurances = setPatientInsurances(fulfillmentRequest);
        this.careGiver = new MVN_ConnectiveRxEnrollPersonAccount(fulfillmentRequest, 'caregiver');
    }

    /**
     * Set Patient Contact Points for ConnectiveRx
     * @param fulfillmentRequest    Fulfillment Request record
     * @return  `List<MVN_ConnectiveRxEnrollContactPoint>`
     */
    private static List<MVN_ConnectiveRxEnrollContactPoint> setPatientContactPoints(PJN_Fulfillment_Request__c fulfillmentRequest) {
        List<MVN_ConnectiveRxEnrollContactPoint> patientContactPoints = new List<MVN_ConnectiveRxEnrollContactPoint>();
        MVN_ConnectiveRxEnrollContactPoint primaryPhone = new MVN_ConnectiveRxEnrollContactPoint(fulfillmentRequest.PJN_Patient_Phone__c, fulfillmentRequest.MVN_Patient_Phone_Type__c);
        if (String.isNotBlank(primaryPhone.mvn_connectiverx_number) && String.isNotBlank(primaryPhone.use)) {
            patientContactPoints.add(primaryPhone);
        }
        return patientContactPoints;
    }

    /**
     * Set Patient Insurance for ConnectiveRx
     * @param fulfillmentRequest    Fulfillment Request record
     * @return  `List<MVN_ConnectiveRxEnrollInsurance>`
     */
    private static List<MVN_ConnectiveRxEnrollInsurance> setPatientInsurances(PJN_Fulfillment_Request__c fulfillmentRequest) {
        List<MVN_ConnectiveRxEnrollInsurance> patientInsurances = new List<MVN_ConnectiveRxEnrollInsurance>();
        MVN_ConnectiveRxEnrollInsurance primaryInsurance = new MVN_ConnectiveRxEnrollInsurance(fulfillmentRequest, true);
        if (String.isNotBlank(primaryInsurance.payerName) || String.isNotBlank(primaryInsurance.groupNumber)) {
            patientInsurances.add(primaryInsurance);
        }
        MVN_ConnectiveRxEnrollInsurance secondaryInsurance = new MVN_ConnectiveRxEnrollInsurance(fulfillmentRequest, false);
        if (String.isNotBlank(secondaryInsurance.payerName) || String.isNotBlank(secondaryInsurance.groupNumber)) {
            patientInsurances.add(secondaryInsurance);
        }
        return patientInsurances;
    }

    /**
     * Set Physician record for ConnectiveRx
     * @param fulfillmentRequest    Fulfillment Request record
     */
    private void setPhysician(PJN_Fulfillment_Request__c fulfillmentRequest) {
        this.partnerId = fulfillmentRequest.PJN_Physician__c;
        this.npi = fulfillmentRequest.PJN_Physician_NPI__c;
        this.specialty = fulfillmentRequest.PJN_Physician_Specialty__c;
        this.firstName = fulfillmentRequest.PJN_Physician_First_Name__c;
        this.middleName = fulfillmentRequest.PJN_Physician_Middle_Name__c;
        this.lastName = fulfillmentRequest.PJN_Physician_Last_Name__c;
        this.address1 = fulfillmentRequest.PJN_Physician_Address_Line_1__c;
        this.address2 = fulfillmentRequest.PJN_Physician_Address_Line_2__c;
        this.city = fulfillmentRequest.PJN_Physician_City__c;
        this.state = fulfillmentRequest.PJN_Physician_State__c;
        this.postalCode = fulfillmentRequest.PJN_Physician_Postal_Code__c;
        this.countryCode = COUNTRY_CODE_BY_NAME.containsKey(fulfillmentRequest.PJN_Physician_Country__c) ?
            COUNTRY_CODE_BY_NAME.get(fulfillmentRequest.PJN_Physician_Country__c) :
            null;
        this.fax = fulfillmentRequest.PJN_Physician_Fax__c;
        this.email = fulfillmentRequest.PJN_Physician_Email__c;
        this.contactPoints = setPhysicianContactPoints(fulfillmentRequest);
    }

    /**
     * Set Physician Contact Points for ConnectiveRx
     * @param fulfillmentRequest    Fulfillment Request record
     * @return  `List<MVN_ConnectiveRxEnrollContactPoint>`
     */
    private static List<MVN_ConnectiveRxEnrollContactPoint> setPhysicianContactPoints(PJN_Fulfillment_Request__c fulfillmentRequest) {
        List<MVN_ConnectiveRxEnrollContactPoint> physicianContactPoints = new List<MVN_ConnectiveRxEnrollContactPoint>();
        MVN_ConnectiveRxEnrollContactPoint primaryPhone = new MVN_ConnectiveRxEnrollContactPoint(fulfillmentRequest.PJN_Physician_Phone__c, fulfillmentRequest.MVN_Physician_Phone_Type__c);
        if (String.isNotBlank(primaryPhone.mvn_connectiverx_number) && String.isNotBlank(primaryPhone.use)) {
            physicianContactPoints.add(primaryPhone);
        }
        return physicianContactPoints;
    }

    /**
     * Set Caregier record for ConnectiveRx
     * @param fulfillmentRequest    Fulfillment Request record
     */
    private void setCaregiver(PJN_Fulfillment_Request__c fulfillmentRequest) {
        this.firstName = fulfillmentRequest.PJN_Caregiver_First_Name__c;
        this.middleName = fulfillmentRequest.PJN_Caregiver_Middle_Name__c;
        this.lastName = fulfillmentRequest.PJN_Caregiver_Last_Name__c;
        this.homePhone = fulfillmentRequest.PJN_Caregiver_Primary_Phone_Number__c;
        this.relationship = fulfillmentRequest.PJN_Caregiver_Relationship__c;
    }

    /**
     * Get Preferred Contact Time from Best Time
     * @param bestTime  SFDC best time to contact
     * @return  `String`
     */
    private String getPreferredContactTime(String bestTime) {
        bestTime = String.isNotBlank(bestTime) ?
            bestTime.toLowerCase() :
            null;
        return String.isNotBlank(bestTime) && bestTime.contains(';') ? 'any' : BEST_TIME_MAPPING.get(bestTime);
	}

    /**
     * Get Preferred Contact Method
     * @param bestContactMethod  SFDC best time to contact
     * @return  `String`
     */
    private String getPreferredContactMethod(String bestContactMethod) {
        bestContactMethod = String.isNotBlank(bestContactMethod) ?
			bestContactMethod.toLowerCase() :
            null;
        return  PREFERRED_CONTACT_MAPPING.get(bestContactMethod);
    }
}