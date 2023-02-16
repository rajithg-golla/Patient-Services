/**
 * @author      Mavens
 * @group       MyRare.com
 * @description Wrapper for the MyRareAPI
 */
@RestResource(urlMapping='/api/myrare')
global without sharing class MVN_MyRareAPI {

    /**
     * MyRare request body when calling this rest resource
     */
    private static Map<String, Object> myRareRequest;

    /**
     * Patient account if exists any match
     */
    private static Account patient;

    /**
     * Care Plan related to the Patient if exists only one
     */
    private static Id caseRequestId;

    /**
     * Request Type mapping from MyRare.com to SFDC
     */
    private static final Map<String, String> ENROLLMENT_TYPE_MAP = new Map<String,String> {
        Label.MVN_MyRare_Enrollment_Consent_Type.toLowerCase() => Label.MVN_MyRare_Enrollment_Consent_Type,
        Label.MVN_MyRare_Enrollment_PAP_Type.toLowerCase() => Label.MVN_MyRare_Enrollment_PAP_Type,
        Label.MVN_MyRare_Enrollment_Copay_Type.toLowerCase() => Label.MVN_MyRare_Enrollment_Copay_Type,
        Label.MVN_MyRare_Enrollment_Supporting_Docs_Type.toLowerCase() => Label.MVN_MyRare_Enrollment_Supporting_Docs_Type,
        '' => Label.MVN_MyRare_Enrollment_Undefined_Type,
        null => Label.MVN_MyRare_Enrollment_Undefined_Type
    };

    /**
     * Request Subject mapping from MyRare.com to SFDC
     */
    private static final Map<String, String> ENROLLMENT_SUBJECT_MAP = new Map<String,String> {
        Label.MVN_MyRare_Enrollment_Consent_Type.toLowerCase() => Label.MVN_MyRare_Enrollment_Consent_Subject,
        Label.MVN_MyRare_Enrollment_PAP_Type.toLowerCase() => Label.MVN_MyRare_Enrollment_PAP_Subject,
        Label.MVN_MyRare_Enrollment_Copay_Type.toLowerCase() => Label.MVN_MyRare_Enrollment_Copay_Subject,
        Label.MVN_MyRare_Enrollment_Supporting_Docs_Type.toLowerCase() => Label.MVN_MyRare_Enrollment_Supporting_Docs_Subject,
        '' => Label.MVN_MyRare_Enrollment_Undefined_Type_Subject,
        null => Label.MVN_MyRare_Enrollment_Undefined_Type_Subject
    };

    /**
     * Request Description mapping from MyRare.com to SFDC
     */
    private static final Map<String, String> ENROLLMENT_DESCRIPTION_MAP = new Map<String,String> {
        Label.MVN_MyRare_Enrollment_Consent_Type.toLowerCase() => Label.MVN_MyRare_Enrollment_Consent_Description,
        Label.MVN_MyRare_Enrollment_PAP_Type.toLowerCase() => Label.MVN_MyRare_Enrollment_PAP_Description,
        Label.MVN_MyRare_Enrollment_Copay_Type.toLowerCase() => Label.MVN_MyRare_Enrollment_Copay_Description,
        Label.MVN_MyRare_Enrollment_Supporting_Docs_Type.toLowerCase() => Label.MVN_MyRare_Enrollment_Supporting_Docs_Description,
        '' => Label.MVN_MyRare_Enrollment_Undefined_Type_Description,
        null => Label.MVN_MyRare_Enrollment_Undefined_Type_Description
    };

    /**
     * Rest Resource POST
     * Create new Request
     * Creates Consents, Copays, PAPs if exists any Care Plan
     * Creates new Attachments relating to the Case Request
     * @return  `MVN_MyRareResponse`
     */
    @HttpPost
    global static MVN_MyRareResponse handleMyRarePostAPI() {
        MVN_MyRareResponse response = new MVN_MyRareResponse();
        String json = RestContext.request.requestBody.toString();
        Savepoint savepoint =  Database.setSavepoint();
        try {
            myRareRequest = (Map<String, Object>) System.JSON.deserializeUntyped(json);
            patient = getPatientIfExists();
            caseRequestId = createRequest();
            createConsents();
            createCopay();
            createPAP();
            createAndAssignFiles();
            response.status = 'success';
            PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(truncateDocumentBodyLog(System.JSON.serializePretty(myRareRequest)), System.JSON.serialize(response));
            PJN_PublishTransactionLog.addDebug(transactionLog);
        } catch(Exception ex) {
            System.debug('### MyRare::Enrollment::Error: ' + ex.getStackTraceString());
            response.status = 'error';
            response.message = ex.getMessage();
            PJN_Transaction_Log__e transactionLog = PJN_PublishTransactionLog.buildCalloutLog(truncateDocumentBodyLog(json), System.JSON.serialize(response));
            PJN_PublishTransactionLog.addError(transactionLog);
            Database.rollback(savepoint);
        } finally {
            PJN_PublishTransactionLog.publish();
        }
        return response;
    }

    /**
     * Get Patient record if find only one which could match the criteria
     * Match criteria: FirstName, LastName, MVN_Birthdate__c
     * Null if none or more than one found
     * @return  `Account`
     */
    private static Account getPatientIfExists() {
        MVN_MyRareObject myRareObject = new MVN_MyRareObject('Account', 'PJN_Patient');
        Account enrollmentPatient = (Account) myRareObject.getMyRareObject(myRareRequest, 'patient');
        //system.debug('patient.Id' + patient.Id);
        if (enrollmentPatient == null) {
            return null;
        }
        Account patient = getPatientUsingSOSL(enrollmentPatient);
        if (patient == null) {
            return null;
        }
        return getPatientAndCarePlanUsingPatientId(patient.Id);
    }

    /**
     * Search all patients matching criteria using SOSL logic
     * Returns null if no matching or more than one
     * @param enrollmentPatient     Enrollment Patient in the Request
     * @return  `Account`
     */
    private static Account getPatientUsingSOSL(Account enrollmentPatient) {
        String soslFilter = String.isNotBlank(enrollmentPatient.FirstName) ? enrollmentPatient.FirstName : '';
        if (String.isNotBlank(enrollmentPatient.LastName)) {
            soslFilter = String.isNotBlank(soslFilter) ? soslFilter + ' ' + enrollmentPatient.LastName : enrollmentPatient.LastName;
        }
        if (String.isBlank(soslFilter)) {
            return null;
        }
        List<List<SObject>> soslResults = [
            FIND
                :soslFilter
            IN ALL FIELDS
            RETURNING Account(Id, FirstName, LastName, MVN_Birthdate__c)
        ];
        Account patient;
        for (Account soslPatient : (List<Account>) soslResults[0]) {
            Boolean firstNameVerification = String.isBlank(enrollmentPatient.FirstName) || soslPatient.FirstName == enrollmentPatient.FirstName;
            Boolean lastNameVerification = soslPatient.LastName == enrollmentPatient.LastName;
            Boolean birthDateVerification = enrollmentPatient.MVN_Birthdate__c == null || soslPatient.MVN_Birthdate__c == enrollmentPatient.MVN_Birthdate__c;

            if (firstNameVerification && lastNameVerification && birthDateVerification && patient == null) {
                patient = soslPatient;
            } else if (firstNameVerification && lastNameVerification && birthDateVerification) {
                return null;
            }
        }
        return patient;
    }

    /**
     * Retrives the Patient and CarePlans related using the patient id found during the SOSL logic
     * @param patientId Account patient id
     * @return  `Account`
     */
    private static Account getPatientAndCarePlanUsingPatientId(Id patientId) {
        return [
            SELECT
                Id,
                (
                    SELECT
                        Id,
                        OwnerId
                    FROM
                        Cases
                    WHERE
                        RecordType.DeveloperName = 'CarePlan'
                )
            FROM
                Account
            WHERE
                Id =: patientId
        ];
    }

    /**
     * Creates Case Request using MyRare Request
     * @return  `Id`
     */
    private static Id createRequest() {
        Id defaultOwnerId = getDefaultRequestOwner();
        String enrollmentRequestType = myRareRequest.containsKey('type') && myRareRequest.get('type') != null && String.isNotBlank(String.valueOf(myRareRequest.get('type'))) ?
            String.valueOf(myRareRequest.get('type')).toLowerCase() :
            String.valueOf(myRareRequest.get('type'));
        Case caseRequest = new Case(
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Request').getRecordTypeId(),
            HealthCloudGA__DueDate__c = System.today(),
            Status = Label.MVN_MyRare_Enrollment_Status_Open,
            Type = ENROLLMENT_TYPE_MAP.containsKey(enrollmentRequestType) ?
                ENROLLMENT_TYPE_MAP.get(enrollmentRequestType) :
                Label.MVN_MyRare_Enrollment_Undefined_Type,
            AccountId = patient != null ? patient.Id : null,
            ParentId = patient != null && patient.Cases != null && patient.Cases.size() == 1 ? patient.Cases[0].Id : null,
            OwnerId = patient != null && patient.Cases != null && patient.Cases.size() == 1 ? patient.Cases[0].OwnerId : defaultOwnerId,
            PJN_Program__r = new CareProgram (
                PJN_Program_DeveloperName__c = Label.MVN_MyRare_Enrollment_ProgramDevName
            ),
            PJN_Program_DeveloperName__c = Label.MVN_MyRare_Enrollment_ProgramDevName
        );

        caseRequest.Subject = ENROLLMENT_SUBJECT_MAP.containsKey(enrollmentRequestType) ?
            ENROLLMENT_SUBJECT_MAP.get(enrollmentRequestType) :
            Label.MVN_MyRare_Enrollment_Undefined_Type_Subject;
        caseRequest.Description = ENROLLMENT_DESCRIPTION_MAP.containsKey(enrollmentRequestType) ?
            ENROLLMENT_DESCRIPTION_MAP.get(enrollmentRequestType) :
            Label.MVN_MyRare_Enrollment_Undefined_Type_Description;
        insert caseRequest;
        return caseRequest.Id;
    }

    /**
     * Gets Default Case Request Owner used if no CarePlan found
     * Gets Queue named as MyRare:Enrollment:Owner Queue label
     * Uses current user if no queue found
     * @return  `Id`
     */
    private static Id getDefaultRequestOwner() {
        List<Group> queues = [
            SELECT
                Id
            FROM
                Group
            WHERE
                Type = 'Queue'
            AND
                DeveloperName = :Label.MVN_MyRare_Enrollment_Owner_Queue
        ];
        if (queues.size() != 1) {
            return UserInfo.getUserId();
        }
        return queues[0].Id;
    }

    /**
     * Creates consents records if CarePlan found
     * Consents update existing CarePlan consents using DataUsePurpose to match them
     */
    private static void createConsents() {
        if (patient == null || patient.Cases == null || patient.Cases.size() != 1) {
            return;
        }
        MVN_MyRareObject myRareObject = new MVN_MyRareObject('PJN_Contact_Point_Type_Consent__c');
        List<PJN_Contact_Point_Type_Consent__c> consents = (List<PJN_Contact_Point_Type_Consent__c>) myRareObject.getMyRareObjects(myRareRequest, 'consents');
        List<Id> dupIds = new List<Id>();
        for (PJN_Contact_Point_Type_Consent__c consent : consents) {
            consent.PJN_Privacy_Consent_Status__c = Label.MVN_MyRare_Enrollment_Consent_Status_Opt_In;
            consent.PJN_Effective_From__c = System.today();
            consent.PJN_Effective_To__c = null;
            consent.PJN_Capture_Source__c = Label.MVN_MyRare_Enrollment_Capture_Source;
            consent.PJN_Care_Plan__c = patient.Cases[0].Id;
            consent.PJN_Patient__c = patient.Id;
            dupIds.add(consent.PJN_Data_Use_Purpose__c);
        }
        List<PJN_Contact_Point_Type_Consent__c> existingConsents = getExistingConsents(patient, dupIds);
        if (!existingConsents.isEmpty()) {
            Map<Id, Id> consentIdByDataUsePurpose = new Map<Id, Id>();
            for (PJN_Contact_Point_Type_Consent__c existingConsent : existingConsents) {
                consentIdByDataUsePurpose.put(existingConsent.PJN_Data_Use_Purpose__c, existingConsent.Id);
            }
            for (PJN_Contact_Point_Type_Consent__c consent : consents) {
                if (consentIdByDataUsePurpose.containsKey(consent.PJN_Data_Use_Purpose__c)) {
                    consent.Id = consentIdByDataUsePurpose.get(consent.PJN_Data_Use_Purpose__c);
                }
            }
        }
        upsert consents;
    }

    /**
     * Retrieves all the consents related to a Patient and Careplan for the specific Data Use Purposes
     * @param patient   Patient account
     * @param dupIds    List of data use purposes
     * @return  `List<PJN_Contact_Point_Type_Consent__c>`
     */
    private static List<PJN_Contact_Point_Type_Consent__c> getExistingConsents(Account patient, List<Id> dupIds) {
        return [
            SELECT
                Id,
                PJN_Data_Use_Purpose__c
            FROM
                PJN_Contact_Point_Type_Consent__c
            WHERE
                PJN_Care_Plan__c = :patient.Cases[0].Id
            AND
                PJN_Patient__c = :patient.Id
            AND
                PJN_Data_Use_Purpose__c IN :dupIds
        ];
    }

    /**
     * Creates Copay record if CarePlan exists
     * Copay update existing CarePlan copay using RecordType Developer Name to match it
     */
    private static void createCopay() {
        if (patient == null || patient.Cases == null || patient.Cases.size() != 1) {
            return;
        }
        MVN_MyRareObject myRareObject = new MVN_MyRareObject('PJN_Assistance_Program__c', 'PJN_Copay');
        PJN_Assistance_Program__c copay = (PJN_Assistance_Program__c) myRareObject.getMyRareObject(myRareRequest, 'insurance');
        if (copay == null) {
            return;
        }
        copay.PJN_Care_Plan__c = patient.Cases[0].Id;
        copay.PJN_Account__c = patient.Id;
        insert copay;
    }

    /**
     * Creates PAP record if CarePlan exists
     * PAP update existing CarePlan PAP using RecordType Developer Name to match it
     * Kishore April 06 2022: Updated the method. getMyRareObjects throwing error message 'nvalid conversion from runtime type Map<String,ANY> to List<ANY>' as there is only singe record for PAP. 
     *                        Replcaed getMyRareObjects with getMyRareObject.
     */
    private static void createPAP() {
        if (patient == null || patient.Cases == null || patient.Cases.size() != 1) {
            return;
        }
        MVN_MyRareObject myRareObject = new MVN_MyRareObject('PJN_Assistance_Program__c', 'PJN_Patient_Assistance_Program');
        //List<PJN_Assistance_Program__c> incomes = (List<PJN_Assistance_Program__c>) myRareObject.getMyRareObjects(myRareRequest, 'income');
        PJN_Assistance_Program__c income = (PJN_Assistance_Program__c) myRareObject.getMyRareObject(myRareRequest, 'income');
        
        //if (incomes.isEmpty()) {
        //    return;
        //}
        //PJN_Assistance_Program__c income = income;
        
        if(income != null){
            income.PJN_Care_Plan__c = patient.Cases[0].Id;
            income.PJN_Account__c = patient.Id;
            insert income;
        }
    }

    /**
     * Creates and Assign all attachments as files into the Case Request created
     */
    private static void createAndAssignFiles() {
        if (myRareRequest == null || myRareRequest.isEmpty() || !myRareRequest.containsKey('attachments')) {
            return;
        }
        List<ContentVersion> files = new List<ContentVersion>();
        for (Object myRareAttachment : (List<Object>) myRareRequest.get('attachments')) {
            Map<String, Object> attachment = (Map<String, Object>) myRareAttachment;
            files.add(
                new ContentVersion(
                    Title = String.valueOf(attachment.get('filename')),
                    Description = String.valueOf(attachment.get('descriptor')),
                    MVN_MyRare_Id__c = String.valueOf(attachment.get('attachmentid')),
                    PathOnClient = String.valueOf(attachment.get('filename')),
                    VersionData = EncodingUtil.base64Decode(String.valueOf(attachment.get('content')))
                )
            );
        }
        insert files;
        List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();
        for (ContentVersion file : getFiles(files)) {
            documentLinks.add(
                new ContentDocumentLink(
                    LinkedEntityId = caseRequestId,
                    Contentdocumentid = file.contentdocumentid,
                    ShareType = 'V'
                )
            );
        }
        insert documentLinks;
    }

    /**
     * Get all files created from the request
     * @param files List of Content Version files
     * @return  `List<ContentVersion>`
     */
    private static List<ContentVersion> getFiles(List<ContentVersion> files) {
        return [
            SELECT
                Id,
                Title,
                ContentDocumentId
            FROM
                ContentVersion
            WHERE
                Id IN :files
        ];
    }

    /**
     * Used to truncate the long blob texts in the attachment MyRare Request in order to store them as transaction logs
     * @param request
     * @return  `String`
     */
    private static String truncateDocumentBodyLog(String request) {
        if (String.isBlank(request)) {
            return request;
        }
        Map<String, Object> jsonMap = (Map<String,Object>) JSON.deserializeUntyped(request);
        for (String jsonMapKey : jsonMap.keySet()) {
            if (jsonMapKey.toLowerCase() == 'attachments') {
                List<Object> attachmentsTrucated = new List<Object>();
                for (Object attachment : (List<Object>) jsonMap.get(jsonMapKey)) {
                    attachmentsTrucated.add(truncatedBody(attachment));
                }
                jsonMap.put(jsonMapKey, attachmentsTrucated);
            }
        }
        return System.JSON.serializePretty(jsonMap);
    }

    /**
     * Truncate text body longer than 10 characters
     * @param document  Document text body to truncate
     * @return  `Object`
     */
    private static Object truncatedBody(Object document) {
        Map<String, Object> documentMap = (Map<String, Object>) document;
        for (String documentKey : documentMap.keySet()) {
            if (documentKey.toLowerCase() == 'content') {
                Integer maxLength = String.valueOf(documentMap.get(documentKey)).length() > 10 ? 10 : String.valueOf(documentMap.get(documentKey)).length();
                documentMap.put(documentKey, String.valueOf(documentMap.get(documentKey)).substring(0,maxLength) + '...');
            }
        }
        return documentMap;
    }

    public class MVN_MyRareAPIException extends System.Exception{}
}