/**
 * @author      Mavens
 * @date        10/2020
 * @description Represents an entry in the results array for a call to the experian health api
 * @group       ExperianHealthAPI
 */
public with sharing class PJN_ExperianHealthApiResult {

    /** Demographic Data **/
    public String addr; // Address information
    public ExperianDate addrEndDate; // The last date the person is shown at an address
    public ExperianDate addrLastVerified; // The last confirmation of a person at this address.
    public ExperianDate addrStartDate; // The earliest date this address was associated with a person.
    public String addressActionCode2; // Compares input address to result address
        /*
            E - the address returned matches the input address exactly (ignores abbreviations
                such as Ave versus Avenue)
            N - the address returned is drastically different than the input address.
            I - the address returned is a ‘fuzzy’ match to the input address. Essentially it’s
                the same address, but there may be slight variations or ‘improvements’ made, such
                as provided the correct city (which wouldn’t have caused it to be undeliverable
                as the post office would have gone against zip).
            X - the address returned is incomplete or known undeliverable
        */
    public List<AlsoKnownAs> aka; // Other names the patient may be known as
    public String area; // Area code of a phone number
    public Boolean cassCorrectedAddress; // Tells if the address has been CASS corrected or not.
    public String city; // City information
    public String county; // County information
    public String dwelling; // The type of dwelling the address is for.
    public ExperianDate dob; // Guarantor’s Date of birth
    public String dobActionCode; // Compares input DOB to result DOB
        /*
            E - The entire result DOB (month, day and year) matches the input DOB
            M - The result Month and Year match the input DOB
            Y - The result Year matches the input DOB
            N - None of the result DOB data points (month, day and year) match the input DOB
            Blank - no DOB entered or returned
        */
    public ExperianDate dod; // Date of Death
    public String dodRange; // Date of Death 10+ day range is an option to provide more detail.
        // It is configured at the profile level and when enabled, replaces the dod field. The
        // range breaks the month into thirds. Format: 12/21-12/31/1996
    public String fname; // First name of the individual or head of household
    public Boolean goodAddr; // Address is known to be good
    public String lname; // Last name of the individual or head of household
    public String mname; // Middle name or initial of the individual or head of household
    public String name; // Full name (first middle last) of an individual or head of household.
    public String nameActionCode; // Indicates that the name sent matches the name found.
        /*
            E – Equal
            N – Not Equal
            M – Only First or Last Name Matches
            (blank) – miss, not found
        */
    public String phone; // Numeric(7) Phone number, no dashes
    public String phoneActionCode; // Set(Char) Indicates whether or not the phone number sent matches the phone number found.
        /*
            E – Equal
            N – Not Equal
            (blank) – miss, not found
        */
    public String phoneType; // C – Cellular; L – Landline; V – VOIP
    public String phoneUse; // Set(Char) Output R – Residential B – Business S – Small Business/Home Office
    //pivResultCode; // (future) Set(Numeric) Output Indicates the result status for the address verification process.
        /*
            S – Success
            M – Address not verified/Miss
            E – Communication Errors (retry-able)
            U – Unspecified Error (not retry-able)
            I – Invalid client request
        */
    public String prefix; // Input/Output - Name prefix for the individual or head of household (e.g., Mr., Mrs., etc.)
    public String redFlagActionCode; // Set Output Comma-separated list of action codes Values: 1 = Name and SSN Discrepancy (or input SSN is invalid) 2 = Name and Address Discrepancy 3 = Address and SSN Discrepancy (or input SSN is invalid) 4, 6 = Deceased 5 = Credit Report Fraud Alert (initial fraud alert, extended fraud alert or active duty fraud alert) 7 = Inquiry SSN Not Issued 8 = Inquiry age < SSN Issue Date 9 = Date Credit Established < SSN Issue Date
    public ExperianDate reporteddate; // Date Output Date the demographic information was last reported to the source.
    public String returnMailActionCode; // Set(char) output N - Result address NEW (or Not Equal) to the one provided E - Result address EQUAL to the one provided T - Possible Name TYPO, Name returned did not match what was provided. X - Incomplete address information returned
    public String sappcode; // Set(Numeric) Input Code assigned by SA to define the reason a client may perform a Permissible Purpose Search.
    public String searchid; // (searchId) String Output Internal identifier assigned by Experian Health. Use this ID to uniquely identify an individual search.
    public String searchType; // Input Customer-defined field used to identify which search to run (e.g. PMA=PaymentAdvisor)
    public String sex; // Set(Char) The gender of the individual or head of household. Values: M; F; <blank if unknown>;
    public List<Spouse> spouses;
    public String ssn; // Numeric(9) Social security number (no dashes)
    public String ssnActionCode2; // Set(char) output Comparison between the input and the given result.
        /*
            Each result record gets its own action code.
            E - Result SSN EQUAL to the SSN provided.
            I - 7 or more digits are in common and the original Input SSN has typos for the person
                provided. Experian Health found CORRECTED the SSN.
            N - 6 or fewer digits are in common and the original Input SSN is not associated with
                the person provided. Experian Health found correct person and CORRECTED the SSN.
            Q - Input SSN is not associated with the person provided. Experian Health could NOT
                CORRECT the SSN and returned information for the SSN provided.
            Blank - Experian Health received a response, but the result set did not include an SSN
                OR there was no input SSN to compare to the result SSN.
            X – Experian Health received a response, but the result contained a response SSN that is
                considered invalid or fraudulent
        */
    public String state; //(2) Input/Output - State code
    public String suffix; // Input/Output - Name suffix for the individual or head of household (e.g., Jr., III, etc.)
    public List<Suggestion> suggestions;
    public String suggestionsText; // Concatenation of all the suggestions messages
    public String zip; // Numeric(5) Zip code
    public String zip4; // Numeric(4) Last 4 digits of a 9-digit zipcode, if available.

    /** Patient Financial Clearance for Pharmacy Hubs **/
    public String assignedTo; // userId of person responsible for this workitem
    public Decimal fplPercentage; // Numeric(3) Output Percentage of income compared to the Federal Poverty Level
    public Integer householdIncomeEstimate; // Yearly income estimate e.g. 15000
    public Integer householdSizeEstimate; // Numeric(2) Output Estimated number of persons living in a household serviceDate Date Input Date of Service

    /** Propensity To Pay **/
    public Boolean paymentAdvisorAdverseAction; // Boolean Output If true, Customer needs to follow adverse action process
    public String paymentAdvisorCategory; // Set Output Customer definable category based on Payment Advisor score
    public String paymentAdvisorCategoryName; // Descriptive name associated with paymentAdvisorCategory
    public String paymentAdvisorSuggestion; // Custom suggestion for proceeding with subject related to payment likelihood

    /**
     * Due to the uncertainty of data that will be returned from the Experian API it is not possible
     * to simply serialize to JSON and deserialize.
     *   - Issue 1: There are keys such as "aka.N.fname" where N could be any positive integer.
     *              It is not understood why something like this woudln't be in an array.
     *   - Issue 2: Dates can be returned as mm/dd/ccyy, mm/ccyy, or ccyy
     * @param result - A Map of String to Object from the Experian API response results array
     */
    public PJN_ExperianHealthApiResult(Map<String, Object> result) {

        // some elements have a key.N.value key to represent multiple of that element
        // list conversions gibs us the ability to convert something like
        // key.0.fname, key.0.lname, key.1.fname, key.1.lname to
        // key => { 0 => { fname, lname}, 1 => {fname, lname }}
        // eventually converting to a list of records. See the ListFromKeyValues interface
        Map<String, Map<Integer, ListFromKeyValues>> listConverions = new Map<String, Map<Integer, ListFromKeyValues>> {
            'aka' => new Map<Integer, AlsoKnownAs>(),
            'spouse' => new Map<Integer, Spouse>(),
            'suggestions' => new Map<Integer, Suggestion>()
        };

        for (String key : result.keySet()) {
            Object value = result.get(key);
            switch on key {
                when 'addr' { addr = (String) value; }
                when 'addrEndDate' { addrEndDate = new ExperianDate(value); }
                when 'addrLastVerified' { addrLastVerified = new ExperianDate(value); }
                when 'addressActionCode2' { addressActionCode2 = (String) value; }
                when 'addrStartDate' { addrStartDate = new ExperianDate(value); }
                when 'area' { area = (String) value; }
                when 'cassCorrectedAddress' { cassCorrectedAddress = Boolean.valueOf((String) value); }
                when 'city' { city = (String) value; }
                when 'county' { county = (String) value; }
                when 'dwelling' { dwelling = (String) value; }
                when 'dob' { dob = new ExperianDate(value); }
                when 'dobActionCode' { dobActionCode = (String) value; }
                when 'dod' { dod = new ExperianDate(value); }
                when 'dodRange' { dodRange = (String) value; }
                when 'fname' { fname = (String) value; }
                when 'goodAddr' { goodAddr = Boolean.valueOf((String) value);}
                when 'lname' { lname = (String) value;}
                when 'mname' { mname = (String) value;}
                when 'name' { name = (String) value; }
                when 'nameActionCode' { nameActionCode = (String) value; }
                when 'phone' { phone = (String) value; }
                when 'phoneActionCode' { phoneActionCode = (String) value; }
                when 'phoneType' { phoneType = (String) value; }
                when 'phoneUse' { phoneUse = (String) value; }
                when 'prefix' { prefix = (String) value; }
                when 'redFlagActionCode' { redFlagActionCode = (String) value; }
                when 'reportedDate' { reportedDate = new ExperianDate(value); }
                when 'returnMailActionCode' { returnMailActionCode = (String) value; }
                when 'sappcode' { sappcode = (String) value; }
                when 'searchid' { searchid = (String) value; }
                when 'sex' { sex = (String) value; }
                when 'ssn' { ssn = (String) value; }
                when 'ssnActionCode2' { ssnActionCode2 = (String) value; }
                when 'state' { state = (String) value; }
                when 'suffix' { suffix = (String) value; }
                when 'suggestionsText' { suggestionsText = (String) value; }
                when 'zip' { zip = (String) value; }
                when 'zip4' { zip4 = (String) value; }

                when 'assignedTo' { assignedTo = (String) value; }
                when 'fplPercentage' { fplPercentage = Decimal.valueOf((String)value); }
                when 'householdIncomeEstimate' { householdIncomeEstimate = Integer.valueOf((String) value); }
                when 'householdSizeEstimate' { householdSizeEstimate = Integer.valueOf((String) value); }

                when 'paymentAdvisorAdverseAction' { paymentAdvisorAdverseAction = Boolean.valueOf((String) value);}
                when 'paymentAdvisorCategory' { paymentAdvisorCategory = (String) value; }
                when 'paymentAdvisorCategoryName' { paymentAdvisorCategoryName = (String) value; }
                when 'paymentAdvisorSuggestion' { paymentAdvisorSuggestion = (String) value; }
            }

            // process any key that represents a part of a larger value using the N syntax
            // e.g. spouse.0.fname is the first name of the first spouse
            if (key.startsWith('aka.') || key.startsWith('spouse.') || key.startsWith('suggestions.')) {
                // e.g. aka.0.fname
                List<String> keyParts = key.split('\\.'); // (aka, 0, fname)

                String listConvKey = keyParts [0]; // aka
                Integer index = Integer.valueOf(keyParts[1]); //0
                String objectKey = keyParts[2]; // fname

                // is this the first time we have seen a param at this index for this type?
                if (!listConverions.get(listConvKey).containsKey(index)) { // e.g. does the
                    ListFromKeyValues lfkv; // instance of the interface, set based on key
                    switch on listConvKey {
                        when 'aka' { lfkv = new AlsoKnownAs(); }
                        when 'spouse' { lfkv = new Spouse(); }
                        when 'suggestions' { lfkv = new Suggestion(); }
                    }
                    listConverions.get(listConvKey).put(index, lfkv);
                }

                listConverions
                    .get(listConvKey)                // pull out the correct object map
                    .get(index)                      // get the current index
                    .add(objectKey, (String) value); // update with the current value
            }
        }

        // update the list variables with the mapped data
        if (!listConverions.get('aka').isEmpty()) {
            this.aka = (List<AlsoKnownAs>) listConverions.get('aka').values();
        }

        if (!listConverions.get('spouse').isEmpty()) {
            this.spouses = (List<Spouse>) listConverions.get('spouse').values();
        }

        if (!listConverions.get('suggestions').isEmpty()) {
            this.suggestions = (List<Suggestion>) listConverions.get('suggestions').values();
        }
    }

    /**
     * The Experian API may return dates in the following formats
     *   - mm/dd/yyyy
     *   - mm/yyyy
     *   - yyyy
     *
     * This class accepts those and puts a 1 in the month and day variables when not available.
     * The variables are publicly available so consuming Apex can put the individual parts
     * into non date fields.
     *
     * hasFullDate will be true if month, day, AND year are all provided
     */
    public class ExperianDate {
        public Integer year { get; private set; }
        public Integer month { get; private set; }
        public Integer day { get; private set; }

        // was the date provided a complete date with month, day, year?
        public Boolean hasFullDate { get; private set; }

        public ExperianDate(Object value) {
            String dateString = (String) value;
            List<String> dateParts = dateString.split('/');
            hasFullDate = false;
            switch on (dateParts.size()) {
                when 3 { // mm/dd/ccyy
                    year = Integer.valueOf(dateParts[2]);
                    month = Integer.valueOf(dateParts[0]);
                    day = Integer.valueOf(dateParts[1]);
                    hasFullDate = true;
                }
                when 2 { // mm/ccyy
                    year = Integer.valueOf(dateParts[1]);
                    month = Integer.valueOf(dateParts[0]);
                    day = 1;
                }
                when 1 {
                    year = Integer.valueOf(dateParts[0]);
                    month = 1;
                    day = 1;
                }
            }
        }

        /**
         * Generate a date from the date parts
         * @returns `Date`
         */
        public Date getFormattedDate() {
            return Date.newInstance(this.year, this.month, this.day);
        }
    }

    /*
     * Interface allowing type.N.key values to be mapped to a list of values
     */
    private interface ListFromKeyValues {
        void add(String key, String value);
    }

    /*
     * Represents an aka.N.message<key> set of values in the response
     */
    public class AlsoKnownAs implements ListFromKeyValues {
        // Another name by which the person is known
        public String fname { get; private set; }
        public String lname { get; private set; }
        public String mname { get; private set; }

        public void add(String key, String value) {
            switch on key {
                when 'fname' { this.fname = value; }
                when 'lname' { this.lname = value; }
                when 'mname' { this.mname = value; }
            }
        }
    }

    /*
     * Represents a spouse.N.<key> set of values in the response
     */
    public class Spouse implements ListFromKeyValues {
        /** Name info for Person’s spouse **/
        public String fname { get; private set; }
        public String lname { get; private set; }
        public String mname { get; private set; }
        public String ssn { get; private set; } //Numeric(9) Output SSN for Person’s spouse

        public void add(String key, String value) {
            switch on key {
                when 'fname' { this.fname = value; }
                when 'lname' { this.lname = value; }
                when 'mname' { this.mname = value; }
                when 'ssn' {this.ssn = value; }
            }
        }
    }

    /*
     * Represents a suggestions.N.message value in the response
     */
    public class Suggestion implements ListFromKeyValues {
        // Recommendation made by Experian Health based upon an analysis of the available data.
        public String message { get; private set; }

        public void add(String key, String value) {
            switch on key {
                when 'message' { this.message = value; }
            }
        }
    }
}