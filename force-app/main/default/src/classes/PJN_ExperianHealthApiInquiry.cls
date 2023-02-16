/**
 * @author      Mavens
 * @date        10/2020
 * @description Wrapper for an Experian API request
 * @group       ExperianHealthAPI
 */
public class PJN_ExperianHealthApiInquiry {

    public class PJN_ExperianHealthApiInquiryException extends Exception {}

    public String addr; // 64 character limit
    public String area; // 3 digits Set the phone field as well or the areaPhone.
    public String areaPhone; // 10 digits
    public String clientUserId; // 14 character limit Identifier, usually internal to a client, used group requests for tracking, reporting, or billing.
    public String city; // 64 character limit
    public String dob; // mm/dd/yyyy is the most reliable format.
    public String patientResponsibility; // The amount the patients owes, out-of-pocket.
    public String patientFinancialClass; // The patient’s financial class. For example, Self-pay, Medicare, HMO, etc.
    public String patientType; // e.g. ER, Inpatient, Outpatient
    public String patientVisitNumber; // This field is used as a unique reference ID for a given search.
        // The Experian Health Worklist will be indexed and searchable using this value.
        // Generally the value for this field will be the Patient’s account Number.
    public String patientMRN; // Medical Record Number
    public String patientFname; // 64 character limit
    public String patientLname; // 64 character limit
    public String patientAddr; // 64 character limit
    public String patientCity; // 64 character limit
    public String patientState; // 2 character limit
    public String patientZip; // 7 character limit
    public String patientPhone; // 10 digits
    public String patientDob; // mm/dd/yyyy is the most reliable format.
    public String dxCode; // ICD10 coding
    public String procedureCode; // CPT/DRG coding
    public String eligCopayAmount; //
    public String eligCopayPercent; //
    public String eligDeductibleAmount; //
    public String eligPayerId; // Name or ID of insurance company
    public String eligPlanId; // Patient’s plan name or ID
    public String fname; // 64 character limit This should be the guarantor’s name
    public String lname; // 64 character limit This should be the guarantor’s name
    public String mname; // This should be the guarantor’s name
    public String phone; // 7 digits Sending a phone number will help increase the hit rate.
    public String sappcode; // need this if there is no SSN
    public String serviceType; // (i.e. cardio, ob/gyn, surgical)
    public String ssn; // 9 character limit
    public String state; // 2 character limit
    public String validateSsn; // If true ssn must also be sent
    public String zip; // max 5
    public String zip4; // last 4 of zip
    public String zip9; // complete 9 digit zip, no dashes

    public PJN_ExperianHealthApiInquiry(PJN_PAPEligibilityRequest request) {
        validateRequiredParameters(
            request,
            new Map<String, String>{
                'requestId' => 'Request Id',
                'firstName' => 'First Name',
                'lastName' => 'Last Name',
                'address' => 'Address',
                'city' => 'City',
                'state' => 'State',
                'zip' => 'Zip'
            }
        );

        this.patientVisitNumber = request.requestId;
        this.fname = request.firstName;
        this.mname = request.middleName;
        this.lname = request.lastName;
        this.areaPhone = request.phone;
        this.ssn = request.socialSecurityNumber;
        Date dob = request.dateOfBirth;
        if (dob != null) {
            String month = String.valueOf(dob.month());
            if (month.length() == 1) {
                month = '0' + month;
            }
            String day = String.valueOf(dob.day());
            if (day.length() == 1) {
                day = '0' + day;
            }
            String year = String.valueOf(dob.year());
            this.dob = month + '/' + day + '/' + year;
        }
        this.addr = request.address;
        this.city = request.city;
        this.state = request.state;
        this.zip = request.zip.length() >= 5 ? request.zip.substring(0,5) : null;
        this.zip4 = request.zip.length() >= 9 ? request.zip.right(4) : null;
        this.zip9 = request.zip.length() >= 9 ? request.zip.replaceAll('[^0-9]','') : null;
        if(this.ssn == null) {
            this.sappcode = '1';
        }
    }

    private void validateRequiredParameters( PJN_PAPEligibilityRequest request, Map<String, String> requiredParameters ) {
        List<String> missingParameters = new List<String>();

        for (String parameter : requiredParameters.keySet()) {
            if (request.isParameterMissing(parameter)) {
                missingParameters.add(requiredParameters.get(parameter));
            }
        }

        if (!missingParameters.isEmpty()) {
            throw new PJN_ExperianHealthApiInquiryException(
                'Required parameters missing: ' + String.join(missingParameters, ', ') + '.'
            );
        }
    }
}