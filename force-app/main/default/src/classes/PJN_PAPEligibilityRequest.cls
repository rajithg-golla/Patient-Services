/**
 * @author      Mavens
 * @date        10/2020
 * @description Provides functionality to make a PJN_PAPEligibility request
 * @group       AssistanceProgramEligibilty
 */
public with sharing class PJN_PAPEligibilityRequest {

    public class PJN_PAPEligibilityRequestException extends Exception {}

    public String requestId;

    public String firstName;
    public String middleName;
    public String lastName;

    public String phone {
        get;
        set {
            // +1 (555) 666-7777 >> 5556667777
            String validate = value.replaceAll('[^0-9]','').removeStart('1');
            if (validate.length() != 10) {
                throw new PJN_PAPEligibilityRequestException(Label.PJN_Eval_PAP_Invalid_Phone);
            }
            phone = validate;
        }
    }

    public String socialSecurityNumber {
        get;
        set {
            String validateSocial = value.replaceAll('[^0-9]','');
            if (validateSocial.length() != 9) {
                throw new PJN_PAPEligibilityRequestException(Label.PJN_Eval_PAP_Invalid_SSN);
            }
            socialSecurityNumber = validateSocial;
        }
    }

    public Date dateOfBirth;

    public String address;
    public String city;
    public String state {
        get;
        set {
            if (value.length() != 2) {
                throw new PJN_PAPEligibilityRequestException(Label.PJN_Eval_PAP_Invalid_State);
            }
            state = value;
        }
    }
    public String zip;

    public Boolean isParameterMissing(String key) {
        switch on(key) {
            when 'requestId' { return String.isBlank(requestId); }
            when 'firstName' { return String.isBlank(firstName); }
            when 'middleName' { return String.isBlank(middleName); }
            when 'lastName' { return String.isBlank(lastName); }
            when 'phone' { return String.isBlank(phone); }
            when 'socialSecurityNumber' { return String.isBlank(socialSecurityNumber); }
            when 'dateOfBirth' { return dateOfBirth == null; }
            when 'address' { return String.isBlank(address); }
            when 'city' { return String.isBlank(city); }
            when 'state' { return String.isBlank(state); }
            when 'zip' { return String.isBlank(zip); }
        }
        return true;
    }

    public PJN_PAPEligibilityRequest(){}

    public PJN_PAPEligibilityRequest(PJN_Assistance_Program__c papRecord) {
        this.requestId = papRecord.Id;
        this.firstName = papRecord.PJN_First_Name__c;
        this.middleName = papRecord.PJN_Middle_Name__c;
        this.lastName = papRecord.PJN_Last_Name__c;
        if (String.isNotBlank(papRecord.PJN_Phone__c)) {
            this.phone = papRecord.PJN_Phone__c;
        }
        if (String.isNotBlank(papRecord.PJN_Social_Security_Number__c)) {
            this.socialSecurityNumber = papRecord.PJN_Social_Security_Number__c;
        }
        this.dateOfBirth = papRecord.PJN_Date_of_Birth__c;
        this.address = papRecord.PJN_Address__c;
        this.city = papRecord.PJN_City__c;
        if (String.isNotBlank(papRecord.PJN_State__c)) {
            this.state = papRecord.PJN_State__c;
        }
        this.zip = papRecord.PJN_zip__c;
    }
}