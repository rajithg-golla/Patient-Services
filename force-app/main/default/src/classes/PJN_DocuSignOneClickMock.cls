/**
 * @author Mavens
 * @date May 2019
 * @description Provides mocks for custom settings used by docusign one click in order to easily
 *              test the functionality
 * @group DocuSign One Click
 */
@isTest(isParallel=true) public class PJN_DocuSignOneClickMock implements System.StubProvider {

    public Boolean returnNoResults;
    public PJN_DocuSignOneClickMock() {
        this.returnNoResults = false;
    }

    public PJN_DocuSignOneClickMock(Boolean noResults) {
        this.returnNoResults = noResults;
    }

    public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, Type returnType,
                                List<Type> listOfParamTypes, List<String> listOfParamNames,List<Object> listOfArgs) {
        if (returnNoResults) {
            return new List<sObject>();
        }

        if (stubbedMethodName == 'getSettingsForObject') {
            return new List<PJN_DocuSign_One_Click_Setting__mdt>{
                new PJN_DocuSign_One_Click_Setting__mdt(
                    PJN_SObject__c = 'Case',
                    PJN_Additional_Filter_Field__c = 'Subject',
                    PJN_Additional_Filter_Value__c = 'Test Subject',
                    PJN_Custom_Email_Message__c = 'Test Email Body',
                    PJN_Custom_Email_Subject__c = 'Test Email Subject',
                    PJN_Load_Attachments__c = true,
                    PJN_Load_Files__c = false,
                    PJN_Program_Field__c = 'PJN_Program__r.PJN_Program_DeveloperName__c',
                    PJN_Record_Type__c = 'CarePlan',
                    PJN_Template_Name__c = 'Test Template',
                    PJN_Use_Custom_Recipients__c = true,
                    PJN_Program__r = new PJN_Program__mdt(DeveloperName = 'Cholecap')
                )
            };
        }

        if (stubbedMethodName == 'getRecipients') {
            return new List<PJN_DocuSign_One_Click_Recipient__mdt>{
                new PJN_DocuSign_One_Click_Recipient__mdt(PJN_Type__c = 'Calling Individual')
            };
        }

        if (stubbedMethodName == 'getRecipientFields') {
            return new List<PJN_DocuSign_One_Click_Recipient_Field__mdt> {
                new PJN_DocuSign_One_Click_Recipient_Field__mdt (
                    PJN_Field__c = 'Email',
                    PJN_Source_Field__c = '',
                    PJN_Value__c = 'HardCodedEmail'
                ),
                new PJN_DocuSign_One_Click_Recipient_Field__mdt (
                    PJN_Field__c = 'FirstName',
                    PJN_Source_Field__c = '',
                    PJN_Value__c = 'HardCodedFirstName'
                ),
                new PJN_DocuSign_One_Click_Recipient_Field__mdt (
                    PJN_Field__c = 'LastName',
                    PJN_Source_Field__c = 'Subject', // use subject here just to avoid having to create an account, but Account.FirstName would be an example of what to put here normally
                    PJN_Value__c = ''
                )
            };
        }

        return null;
    }

}