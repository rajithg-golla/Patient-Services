/**
 * @author      Mavens
 * @date        10/2020
 * @description Unit tests for PJN_ExperianHealthApiResult
 * @group       ExperianHealthAPI
 */
@isTest
public class PJN_ExperianHealthApiResultTest {

    @isTest
    private static void itShouldHandleAResponse() {
        Map<String, Object> response = new Map<String, Object>{
            'fname' => 'James',
            'lname' => 'Dean',
            'addr' => '185 N. Franklin St.',
            'addrEndDate' => '12/31/2019', // test full date
            'addrStartDate' => '03/2004', // test partial date mm/yyyy
            'city' => 'Chicago',
            'state' => 'IL',
            'zip' => '60606',
            'dob' => '2007', // test partial date, year
            'ssn' => '123456789','suggestionsText' => 'Result address has been CASS corrected and meets USPS requirements for certified mailings.',
            'householdSizeEstimate' => '4',
            'householdIncomeEstimate' => '20000',
            'fplPercentage' => '76.33',
            'aka.0.fname' => 'aka0FirstName',
            'aka.0.lname' => 'aka0LastName',
            'aka.0.mname' => 'aka0MilddleName',
            'aka.1.fname' => 'aka1FirstName',
            'aka.1.lname' => 'aka1LastName',
            'aka.1.mname' => 'aka1MilddleName',
            'spouse.0.fname' => 'spouse0FirstName',
            'spouse.0.lname' => 'spouse0LastName',
            'spouse.0.mname' => 'spouse0MilddleName',
            'spouse.0.ssn' => '000000000',
            'spouse.1.fname' => 'spouse1FirstName',
            'spouse.1.lname' => 'spouse1LastName',
            'spouse.1.mname' => 'spouse1MilddleName',
            'spouse.1.ssn' => '111111111',
            'suggestions.0.message' => 'suggestions0Message',
            'suggestions.1.message' => 'suggestions1Message'
        };

        Test.startTest();
        PJN_ExperianHealthApiResult result = new PJN_ExperianHealthApiResult(response);
        Test.stopTest();

        System.assertEquals(Date.newInstance(2019, 12, 31), result.addrEndDate.getFormattedDate());
        System.assertEquals(Date.newInstance(2004, 3, 1), result.addrStartDate.getFormattedDate());
        System.assertEquals(Date.newInstance(2007, 1, 1), result.dob.getFormattedDate());

        System.assertEquals(2, result.aka.size());
        System.assertEquals(2, result.spouses.size());
        System.assertEquals(2, result.suggestions.size());

    }

}