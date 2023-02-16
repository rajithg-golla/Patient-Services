/**
 * @author Mavens
 * @date Feb 2019
 * @description Controller used for the Patient Merge Tool. Contains methods for:
 *          - retrieving data change request records to be displayed in the initial screen
 *          - retrieving all the data needed for a specific merge between two patients
 *          - merging two patients
 *          - cancelling a merge
 * @group PatientMerge
 */
public without sharing class PJN_PatientMergeCtrl {

    @TestVisible
    private static PJN_MergeToolSetting mergeToolSetting = new PJN_MergeToolSetting();

    /**
     * Get Data Change Requests records and column names to be displayed in a table
     * @returns PJN_DataTable  Wrapper class with records and columns
     */
    @AuraEnabled
    public static PJN_DataTable getDCRRecords() {
        PJN_DataTable dataTable = new PJN_DataTable();
        List<String> fieldList = PJN_Utilities.getFields('PJN_Data_Change_Request__c', 'PJN_Merge_Tool_DCR_Fields');
        dataTable.data = getDCRRecordList(fieldList);
        dataTable.columns = PJN_Utilities.getColumns(
            'PJN_Data_Change_Request__c',
            fieldList,
            new Map<String,String>{
                Label.PJN_Patient_Merge_Tool_Merge_Action => 'merge',
                Label.PJN_Patient_Merge_Tool_Reject_Action => 'reject'
            }
        );
        System.debug('dataTable::' + dataTable);
        return dataTable;
    }

    /**
     * Run query against PJN_Data_Change_Request__c to retrieve records with
     * Status = Pending and Record Type = Patient Merge
     * @param  fieldList  List of fields to be retrieved
     * @returns List<PJN_Data_Change_Request__c> List of Data Change Request records
     */
    private static List<PJN_Data_Change_Request__c> getDCRRecordList(List<String> fieldList) {
        Id patientMergeRecordTypeId = SObjectType.PJN_Data_Change_Request__c
                                    .getRecordTypeInfosByDeveloperName()
                                    .get('PJN_Patient_Merge')
                                    .getRecordTypeId();
        String queryString = 'SELECT Id, PJN_Patient_1__c, PJN_Patient_2__c';
        if (!fieldList.isEmpty()) {
            queryString += ', ' + String.escapeSingleQuotes(String.join(fieldList, ','));
        }
        queryString += ' FROM PJN_Data_Change_Request__c' +
                       ' WHERE RecordTypeId = :patientMergeRecordTypeId' +
                       ' AND PJN_Status__c = \'Pending\'';
        return Database.query(queryString);
    }

    /**
     * Get the data for the selected patients to be merged.
     * The data retrieved is defined by the fieldset PJN_Merge_Tool_Account_Fields on the Account object
     * @param  accountIdList List of patient ids
     * @returns Map<String, List<Object>> Map containing the list of patient records
     *                                   and the list fo fields to be displayed along the wizard
     */
    @AuraEnabled
    public static Map<String, List<Object>> getAccounts(List<Id> accountIdList){
        List<String> fieldList = PJN_Utilities.getFields('Account', 'PJN_Merge_Tool_Account_Fields');
        String queryString = 'SELECT Id';
        if (!fieldList.isEmpty()) {
            queryString += ', ' + String.escapeSingleQuotes(String.join(fieldList, ','));
        }
        queryString += ' FROM Account' +
                       ' WHERE Id IN :accountIdList';
        List<Account> accList =  Database.query(queryString);
        return new Map<String, List<Object>> {
            'accountList' => accList,
            'fieldList' => fieldList
        };
    }

    /**
     * Get care plan data linked to selected patients
     * @param  accountIdList List of patient ids
     * @returns PJN_ChildObject wrapper containing care plan data; fields to be displayed in table and card;
     *                        label; and record name
     */
    @AuraEnabled
    public static PJN_ChildObject getCarePlanRecords(List<Id> accountIdList){
        PJN_ChildObject childObject = new PJN_ChildObject();
        List<String> tableFieldList = PJN_Utilities.getFields('Case', 'PJN_Merge_Tool_Table_Care_Plan_Fields');
        List<String> cardFieldList = PJN_Utilities.getFields('Case', 'PJN_Merge_Tool_Card_Care_Plan_Fields');
        childObject.recordList = getCarePlanList(accountIdList, tableFieldList, cardFieldList);
        childObject.columns = PJN_Utilities.getColumns(
            'Case',
            tableFieldList,
            new Map<String,String>{
                Label.PJN_Patient_Merge_Tool_View_Record_Action => 'view'
            }
        );

        childObject.childRecordLabel = 'Care Plan';
        childObject.childRecordName = 'Case';
        childObject.fieldList = tableFieldList;
        childObject.cardFieldList = cardFieldList;

        return childObject;
    }

    /**
     * Run query against Case to retrieve care plan records linked to selected patientds
     * @param  List<Id>    List of patient ids
     * @param  fieldList1  List of fields to be retrieved
     * @param  fieldList2  List of fields to be retrieved
     * @returns List<Case>  List of Care Plan records
     */
    private static List<Case> getCarePlanList(List<Id> accountIdList,
                                                List<String> fieldList1,
                                                List<String> fieldList2) {

        Set<String> allFieldsSet = new Set<String>(fieldList1);
        allFieldsSet.addAll(new Set<String>(fieldList2));
        List<String> allFieldsList = new List<String>();
        allFieldsList.addAll(allFieldsSet);

        Id carePlanRecordTypeId = SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId();
        String queryString = 'SELECT Id';
        if (!allFieldsList.isEmpty()) {
            queryString += ', ' + String.escapeSingleQuotes(String.join(allFieldsList, ','));
        }
        queryString += ' FROM Case' +
                        ' WHERE AccountId IN :accountIdList ' +
                        ' AND RecordTypeId = :carePlanRecordTypeId';
        return Database.query(queryString);
    }

    /**
     * Retrieve the list of child records for the selected care plans that are defined
     * in the custom metadata type record PJN_Merge_Tool_Setting__mdt
     * @param  carePlanIdsList      List of care plan ids
     * @returns List<PJN_ChildObject> List of PJN_ChildObject records containing the information for each
     *                              care plan child object
     */
    @AuraEnabled
    public static List<PJN_ChildObject> getChildRecords(List<Id> carePlanIdsList){
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        List<PJN_ChildObject> childObjectList = new List<PJN_ChildObject>();
        for (PJN_Merge_Tool_Setting__mdt setting : mergeToolSetting.getAllSettings()) {
            PJN_ChildObject childObject = new PJN_ChildObject();
            childObject.recordList = getRecordList(setting, carePlanIdsList);
            childObject.columns = PJN_Utilities.getColumns(
                setting.PJN_Child_SObject_API_Name__c,
                setting.PJN_Field_List__c.split(','),
                new Map<String,String>{
                    Label.PJN_Patient_Merge_Tool_View_Record_Action => 'view'
                }
            );

            Schema.DescribeSObjectResult describeSObjResult =
                globalDescribe.get(setting.PJN_Child_SObject_API_Name__c).getDescribe();

            childObject.childRecordLabel = describeSObjResult.getLabel();
            childObject.childRecordName = describeSObjResult.getName();
            childObjectList.add(childObject);

        }
        return childObjectList;
    }

    /**
    * Get records from database as per the custom metadata definition that is passed
    * @param  setting         Custom metadata record containing what info needs to be retrieved from the database
    * @param  carePlanIdsList list of care plan ids
    * @returns List<SObject>   list of records
    */
    private static List<SObject> getRecordList(PJN_Merge_Tool_Setting__mdt setting,
                                                List<Id> carePlanIdsList) {
        String objectName = setting.PJN_Child_SObject_API_Name__c;
        String fieldList = setting.PJN_Field_List__c;
        String carePlanField = setting.PJN_Field_API_Name_To_Care_Plan__c;
        String queryString =
            'SELECT Id, ' + carePlanField + ', ' +
                fieldList +
            ' FROM ' + objectName +
                ' WHERE ' + carePlanField + ' IN :carePlanIdsList'
        ;
        return Database.query(queryString);
    }

    /**
     * Retrieve contact information records associated with account ids
     * @param  accountIdList List of account ids
     * @returns PJN_ChildObject wrapper containing contact information data; fields to be displayed in lightning table;
     *                        label; and record name.
     */
    @AuraEnabled
    public static PJN_ChildObject getContactInformationRecords(List<Id> accountIdList){
        PJN_ChildObject childObject = new PJN_ChildObject();
        List<String> fieldList = PJN_Utilities.getFields('PJN_Contact_Information__c',
                                                        'PJN_Merge_Tool_Contact_Info_Fields');
        childObject.recordList = getContactInfoList(accountIdList, fieldList);
        childObject.columns = PJN_Utilities.getColumns(
            'PJN_Contact_Information__c',
            fieldList,
            new Map<String,String>{
                Label.PJN_Patient_Merge_Tool_Set_As_Primary_Action => 'primary',
                Label.PJN_Patient_Merge_Tool_View_Record_Action => 'view'
            }
        );
        childObject.childRecordLabel = 'Contact Information';
        childObject.childRecordName = 'PJN_Contact_Information__c';

        return childObject;
    }

    /**
     * Run query against PJN_Contact_Information__c object to retrieve records linked to selected patients
     * @param  accountIdList list of patient ids
     * @param  fieldList     list of fields to be retrieved
     * @returns List<PJN_Contact_Informatino__c> list of contact information records
     */
    private static List<PJN_Contact_Information__c> getContactInfoList(List<Id> accountIdList,
                                                                        List<String> fieldList) {
        String queryString = 'SELECT Id, PJN_Account__c';
        if (!fieldList.isEmpty()) {
            queryString += ', ' + String.escapeSingleQuotes(String.join(fieldList, ','));
        }
        queryString += ' FROM PJN_Contact_Information__c' +
                       ' WHERE PJN_Account__c IN :accountIdList';
        return Database.query(queryString);
    }

    /**
     * Merge patient accounts. This method called a @future method to be executed asynchronously
     * since we were hitting CPU time limit.
     */
    @AuraEnabled
    public static void mergeAccounts(Id selectedDCRRecordId,
                                        Id selectedPatientId,
                                        String selectedChildrenRecordMapString,
                                        String selectedAccountChildrenRecordMapString,
                                        List<Id> selectedPrimaryIdList,
                                        List<Account> accountList,
                                        List<Id> carePlanIdsList,
                                        Map<Id, List<Id>> mergedCarePlans
                                        ) {

        Id loserAccountId = accountList.get(0).Id == selectedPatientId ? accountList.get(1).Id : accountList.get(0).Id;

        futureMergeAccounts(selectedDCRRecordId,
                            selectedPatientId,
                            selectedChildrenRecordMapString,
                            selectedAccountChildrenRecordMapString,
                            selectedPrimaryIdList,
                            new List<Id> {accountList.get(0).Id, accountList.get(1).Id},
                            carePlanIdsList,
                            loserAccountId,
                            JSON.serialize(mergedCarePlans)
                            );
    }

    /**
     * Merge patient accounts. Future method.
     *      - Reparents selected care plans to the winner account
     *      - Reparents contact information records to the winner account
     *      - Move contact-2-contact relationships to the winner account
     *      - If two or more care plans are merged then reparents all its child records (Prescription, Consent, etc)
     *          to the winner care plan. These child records are defined via custom metadata record type
     *          It also reparents files and notes
     *      - Deletes all the records that have not been merged or selected to be kept
     *      - Updates Data Change Request status to "Merged" and set the winner patient id
     */
    @future
    private static void futureMergeAccounts(Id selectedDCRRecordId,
                                        Id selectedPatientId,
                                        String selectedChildrenRecordMapString,
                                        String selectedAccountChildrenRecordMapString,
                                        List<Id> selectedPrimaryIdList,
                                        List<Id> accountIdList,
                                        List<Id> carePlanIdsList,
                                        Id loserAccountId,
                                        String mergedCarePlansString
                                        ) {
        Savepoint sp = Database.setSavepoint();

        try {
            Map<Id, Map<String, List<Id>>> selectedChildrenRecordMap = (Map<Id, Map<String, List<Id>>>) JSON.deserialize(
                selectedChildrenRecordMapString,
                Map<Id, Map<String, List<Id>>>.class
            );
            Map<String, List<Id>> selectedAccountChildrenRecordMap = (Map<String, List<Id>>) JSON.deserialize(
                selectedAccountChildrenRecordMapString,
                Map<String, List<Id>>.class
            );
            Map<Id, List<Id>> mergedCarePlans = (Map<Id, List<Id>>) JSON.deserialize(
                mergedCarePlansString,
                Map<Id, List<Id>>.class
            );

            // Move Files and Notes
            moveFilesAndNotes(mergedCarePlans);

            // Reparent selected Care Plans and their child cases to point to selected Patient
            reparentCarePlans(selectedPatientId, selectedAccountChildrenRecordMap);

            // Reparent selected Contact Info records to point to selected Patient. Set Primary flags.
            reparentContactInfo(selectedPatientId, selectedPrimaryIdList, selectedAccountChildrenRecordMap);

            // Update selected Child Records to point to selected Care Plan
            reparentCarePlanChildRecords(selectedPatientId, selectedChildrenRecordMap);

            // Move Contact-to-Contact relationships
            moveContactToContactRelationsips(selectedPatientId, accountIdList);

            // Delete non merged records - child records
            deleteNonMergedChildRecords(carePlanIdsList, selectedChildrenRecordMap);

            // Delete non merged records - contact information
            deleteNonMergedContactInfo(accountIdList, selectedAccountChildrenRecordMap);

            // Delete non merged records - contact information
            deleteLoserCareProgramEnrollee(accountIdList, selectedAccountChildrenRecordMap, loserAccountId);

            // Delete non merged records - Care Plans and Child Cases
            deleteNonMergedCarePlans(carePlanIdsList, selectedAccountChildrenRecordMap, loserAccountId);

            // Delete non merged records - Patient and Individual records
            deleteLoserAccount(loserAccountId);

            // Update DCR record
            PJN_Data_Change_Request__c dcr = new PJN_Data_Change_Request__c(
                Id = selectedDCRRecordId,
                PJN_Status__c = 'Merged',
                PJN_Winner_Patient_Id__c = selectedPatientId
            );
            update dcr;

        } catch (Exception exc) {
            Database.rollback(sp);
            System.debug('### Merge Exception: ' + exc.getMessage() + ' - Stack: ' + exc.getStackTraceString());
            insert new PJN_Log__c(
                PJN_Source__c = 'PJN_PatientMergeCtrl',
                PJN_Logging_Level__c = 'ERROR',
                PJN_Logged_Message__c = 'Merge Exception:: ' + exc.getMessage() + ' - Stack: ' + exc.getStackTraceString()
            );
        }

    }

    /**
     * Reparent care plan records selected by the user. It updates the AccountId field to point to the winner patient
     * @param  selectedPatientId                winner patient id
     * @param  selectedAccountChildrenRecordMap map containing selected list of ids by object name
     */
    private static void reparentCarePlans(Id selectedPatientId, Map<String, List<Id>> selectedAccountChildrenRecordMap) {
        if (selectedAccountChildrenRecordMap.containsKey('Case')) {
            List<Id> caseIds = selectedAccountChildrenRecordMap.get('Case');
            // Retrieve all child cases linked to care plan
            List<Case> casesToMove = [
                SELECT
                    Id
                FROM
                    Case
                WHERE
                    ParentId = :caseIds
                OR
                    Id = :caseIds
            ];
            for (Case thisCase : casesToMove) {
                thisCase.AccountId = selectedPatientId;
            }
            update casesToMove;
        }
    }

    /**
     * Reparent contact information records selected by the user. It updates the PJN_Account__c field
     * to point to the winner patient and updates the PJN_Set_as__Primary__c flag if the record was
     * selected as primary.
     * @param  selectedPatientId                winner patient id
     * @param  selectedPrimaryIdList            list of contact information ids selected as primary
     * @param  selectedAccountChildrenRecordMap map containing selected list of ids by object name
     */
    private static void reparentContactInfo(Id selectedPatientId,
                                            List<Id> selectedPrimaryIdList,
                                            Map<String, List<Id>> selectedAccountChildrenRecordMap) {

        if (selectedAccountChildrenRecordMap.containsKey('PJN_Contact_Information__c')) {
            Map<Id, PJN_Contact_Information__c> contactInfoMapToUpdate = new Map<Id, PJN_Contact_Information__c>();
            for (Id recordId : selectedAccountChildrenRecordMap.get('PJN_Contact_Information__c')) {
                PJN_Contact_Information__c contactInfo = new PJN_Contact_Information__c(
                    Id = recordId,
                    PJN_Account__c = selectedPatientId,
                    PJN_Set_as_Primary__c = false
                );
                contactInfoMapToUpdate.put(recordId, contactInfo);
            }
            for (Id contactInfoId : selectedPrimaryIdList) {
                if (contactInfoMapToUpdate.containsKey(contactInfoId)) {
                    contactInfoMapToUpdate.get(contactInfoId).PJN_Set_as_Primary__c = true;
                }
            }
            update contactInfoMapToUpdate.values();
        }
    }

    /**
     * Reparent care plan child records selected by the user to point to the winner care plan
     * @param  selectedPatientId                winner patient id
     * @param  selectedChildrenRecordMap map with key=winner care plan id;
                                         value=map containing selected list of ids by object name
     */
    private static void reparentCarePlanChildRecords(Id selectedPatientId,
                                                    Map<Id, Map<String, List<Id>>> selectedChildrenRecordMap) {
        Map<String, PJN_Merge_Tool_Setting__mdt> settingsByObjectName = mergeToolSetting.getAllSettingsByObjectName();
        for (Id carePlanId : selectedChildrenRecordMap.keySet()) {
            Map<String, List<Id>> childMap = selectedChildrenRecordMap.get(carePlanId);
            for (String objectName : childMap.keySet()) {
                Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
                List<SObject> objListToUpdate = new List<SObject>();
                for (Id recordId : childMap.get(objectName)) {
                    SObject sObj = objType.newSObject() ;
                    sObj.put('Id', recordId);
                    sObj.put(settingsByObjectName.get(objectName).PJN_Field_API_Name_To_Care_Plan__c, carePlanId);
                    if (settingsByObjectName.get(objectName).PJN_Field_API_Name_To_Account__c != null) {
                        sObj.put(settingsByObjectName.get(objectName).PJN_Field_API_Name_To_Account__c, selectedPatientId);
                    }
                    objListToUpdate.add(sObj);
                }
                update objListToUpdate;
            }
        }
    }

    /**
     * Delete all the cases linked to the loser account and all the care plans non-selected to be kept.
     * @param  carePlanIdsList                  list of all care plan ids associated to all patients
     * @param  selectedAccountChildrenRecordMap map containing selected list of ids by object name
     * @param  loserAccountId                   non-selected account id
     */
    private static void deleteNonMergedCarePlans(List<Id> carePlanIdsList,
                                                Map<String, List<Id>> selectedAccountChildrenRecordMap,
                                                Id loserAccountId) {

        if (!carePlanIdsList.isEmpty()) {
            Set<Id> caseIds = new Set<Id>(carePlanIdsList);
            if (selectedAccountChildrenRecordMap.containsKey('Case')) {
                List<Id> selectedCarePlanIds = selectedAccountChildrenRecordMap.get('Case');
                caseIds.removeAll(selectedCarePlanIds);
            }

            List<Case> casesToDelete = new List<Case> ([
                SELECT
                    Id
                FROM
                    Case
                WHERE
                    ParentId IN :caseIds
                OR
                    Id IN :caseIds
            ]);
            delete casesToDelete;
        } else {
            // Remove Cases associated to loser account
            List<Case> casesToDelete = new List<Case> ([
                SELECT
                    Id
                FROM
                    Case
                WHERE
                    AccountId = :loserAccountId
            ]);
            delete casesToDelete;
        }
    }

    /**
     * Delete all care plan child records non-selected to be kept during the merge of two or more care plans
     * @param  carePlanIdsList           list of all care plan ids
     * @param  selectedChildrenRecordMap map with key=winner care plan id;
                                         value=map containing selected list of ids by object name
     */
    private static void deleteNonMergedChildRecords(List<Id> carePlanIdsList,
                                                Map<Id, Map<String, List<Id>>> selectedChildrenRecordMap) {

        for (PJN_Merge_Tool_Setting__mdt setting : mergeToolSetting.getAllSettings()) {
            for (Map<String, List<Id>> childMap : selectedChildrenRecordMap.values()) {
                if (childMap.containsKey(setting.PJN_Child_SObject_API_Name__c)) {
                    Map<Id, SObject> recordMap = new Map<Id, SObject>(getRecordList(setting, carePlanIdsList));
                    List<Id> selectedIdsList = childMap.get(setting.PJN_Child_SObject_API_Name__c);
                    for (Id recordId : selectedIdsList) {
                        if (recordMap.containsKey(recordId)) {
                            recordMap.remove(recordId);
                        }
                    }
                    delete recordMap.values();
                }
            }
        }
    }

    /**
     * Delete contact information records non-selected to be kept during the merge process
     * @param  accountIdList                    list of patient ids
     * @param  selectedAccountChildrenRecordMap map containing selected list of ids by object name
     */
    private static void deleteNonMergedContactInfo(List<Id> accountIdList,
                                                Map<String, List<Id>> selectedAccountChildrenRecordMap) {

        Map<Id, PJN_Contact_Information__c> contactInfoToDelete = new Map<Id, PJN_Contact_Information__c>([
            SELECT
                Id
            FROM
                PJN_Contact_Information__c
            WHERE
                PJN_Account__c IN :accountIdList
        ]);

        if (selectedAccountChildrenRecordMap.containsKey('PJN_Contact_Information__c')) {
            List<Id> selectedContactInfoIds = selectedAccountChildrenRecordMap.get('PJN_Contact_Information__c');
            for (Id contactInfoId : selectedContactInfoIds) {
                contactInfoToDelete.remove(contactInfoId);
            }
        }
        delete contactInfoToDelete.values();
    }

    /**
     * Delete CareProgramEnrollee for loser Care Program
     * @param accountIdList                     list of patient ids
     * @param selectedAccountChildrenRecordMap  map containing selected list of ids by object name
     * @param loserAccountId                    non-selected account
     */
    private static void deleteLoserCareProgramEnrollee(List<Id> accountIdList,
                                                        Map<String, List<Id>> selectedAccountChildrenRecordMap,
                                                        Id loserAccountId) {
        List<CareProgramEnrollee> loserAccountCPEs = [
            SELECT
                Id,
                AccountId,
                CareProgram.PJN_Program_DeveloperName__c
            FROM
                CareProgramEnrollee
            WHERE
                AccountId = :loserAccountId
        ];

        if (loserAccountCPEs.isEmpty() || !selectedAccountChildrenRecordMap.containsKey('Case')) {
            return;
        }

        // Patient Merge just merge 2 accounts at the same time
        // Initialize winner account id with first account id in accountIdList
        // If first account id is loser account id, initialize with second account id
        Id winnerAccountId = accountIdList[0] != loserAccountId ?
            accountIdList[0] :
            accountIdList[1];

        Set<String> careProgramDevNamesApproved = new Set<String>();
        for (Case winnerAccountCarePlan : [SELECT
                                                PJN_Program__r.PJN_Program_DeveloperName__c
                                            FROM
                                                Case
                                            WHERE
                                                Id IN :selectedAccountChildrenRecordMap.get('Case')
                                            AND
                                                PJN_Program__c != null
                                        ]) {
            careProgramDevNamesApproved.add(winnerAccountCarePlan.PJN_Program__r.PJN_Program_DeveloperName__c);
        }

        Set<String> includedCareProgramDevNames = new Set<String>();
        for (CareProgramEnrollee winnerAccountCPE : [SELECT
                                                        Id,
                                                        AccountId,
                                                        CareProgram.PJN_Program_DeveloperName__c
                                                    FROM
                                                        CareProgramEnrollee
                                                    WHERE
                                                        AccountId = :winnerAccountId
                                                ]) {
            includedCareProgramDevNames.add(winnerAccountCPE.CareProgram.PJN_Program_DeveloperName__c);
        }

        List<CareProgramEnrollee> updateCPEs = new List<CareProgramEnrollee>();
        List<CareProgramEnrollee> deleteCPEs = new List<CareProgramEnrollee>();

        for (CareProgramEnrollee loserAccountCPE : loserAccountCPEs) {
            Boolean reassignCPE = careProgramDevNamesApproved.contains(loserAccountCPE.CareProgram.PJN_Program_DeveloperName__c)
                && !includedCareProgramDevNames.contains(loserAccountCPE.CareProgram.PJN_Program_DeveloperName__c);

            if (reassignCPE) {
                includedCareProgramDevNames.add(loserAccountCPE.CareProgram.PJN_Program_DeveloperName__c);
                loserAccountCPE.AccountId = winnerAccountId;
                updateCPEs.add(loserAccountCPE);
            } else {
                deleteCPEs.add(loserAccountCPE);
            }
        }

        if (updateCPEs != null && !updateCPEs.isEmpty()) {
            update updateCPEs;
        }

        if (deleteCPEs != null && !deleteCPEs.isEmpty()) {
            delete deleteCPEs;
        }
    }

    /**
     * Move existing contact-to-contact relationships from non-selected patient to the winner patient
     * @param  selectedPatientId winner patient id
     * @param  accountIdList     list of patient ids
     */
    private static void moveContactToContactRelationsips(Id selectedPatientId, List<Id> accountIdList) {
        List<Account> accountsWithPersonContact = [
            SELECT
                PersonContactId
            FROM
                Account
            WHERE
                Id IN : accountIdList
        ];
        Set<Id> contactIds = new Set<Id>();
        Id selectedPersonContactId;
        for (Account acc : accountsWithPersonContact) {
            if (acc.Id == selectedPatientId) {
                selectedPersonContactId = acc.PersonContactId;
                continue;
            }
            contactIds.add(acc.PersonContactId);
        }

        List<HealthCloudGA__ContactContactRelation__c> existingRelationships = [
            SELECT
                HealthCloudGA__Active__c,
                HealthCloudGA__Contact__c,
                HealthCloudGA__RelatedContact__c,
                HealthCloudGA__Role__c
            FROM
                HealthCloudGA__ContactContactRelation__c
            WHERE
                HealthCloudGA__Contact__c = :contactIds
        ];
        for (HealthCloudGA__ContactContactRelation__c relation : existingRelationships) {
            relation.HealthCloudGA__Contact__c = selectedPersonContactId;
        }
        update existingRelationships;
    }

    /**
     * Delete non-selected patient and its individual record
     * @param  loserAccountId non-selected acccount id
     */
    private static void deleteLoserAccount(Id loserAccountId) {
        Account acc = [SELECT Id, PersonIndividualId FROM Account WHERE Id = :loserAccountId];
        Id individualId = acc.PersonIndividualId;
        delete acc;
        if (individualId != null) {
            delete new Individual(Id=individualId);
        }
    }

    /**
     * Move files and notes when merging two or more care plans to the winner care plan
     * @param  mergedCarePlans map with the list of merged care plans by winner care plan id
     */
    private static void moveFilesAndNotes(Map<Id, List<Id>> mergedCarePlans) {
        for (Id masterCarePlanId : mergedCarePlans.keySet()) {
            List<Id> carePlanList = mergedCarePlans.get(masterCarePlanId);
            List<ContentDocumentLink> docLinkList = [
                SELECT
                    ContentDocumentId,
                    LinkedEntityId
                FROM
                    ContentDocumentLink
                WHERE
                    LinkedEntityId IN :carePlanList
            ];
            List<ContentDocumentLink> contentDocLinkToCreate = new List<ContentDocumentLink>();
            for (ContentDocumentLink docLink : docLinkList) {
                if (docLink.LinkedEntityId != masterCarePlanId) {
                    contentDocLinkToCreate.add(
                        new ContentDocumentLink(
                            ContentDocumentId = docLink.ContentDocumentId,
                            LinkedEntityId = masterCarePlanId,
                            ShareType = 'I'
                        )
                    );
                }
            }
            try {
                insert contentDocLinkToCreate;
            } catch (Exception e) {
                System.debug('*** Exception *** ' + e.getMessage());
            }
        }
    }

    /**
     * Wrapper class to expose object records to be displayed in lightning tables and cards
     */
    public class PJN_ChildObject {
        @AuraEnabled public List<SObject> recordList;
        @AuraEnabled public List<PJN_FieldWrapper> columns;
        @AuraEnabled public String childRecordLabel;
        @AuraEnabled public String childRecordName;
        @AuraEnabled public List<String> fieldList;
        @AuraEnabled public List<String> cardFieldList;
    }

    /**
     * Update Data Change Request status to "Rejected"
     * @param  recordId Data Change Request record id
     */
    @AuraEnabled
    public static void rejectMerge(Id recordId) {
        PJN_Data_Change_Request__c dcr = new PJN_Data_Change_Request__c(
            Id = recordId,
            PJN_Status__c = 'Rejected'
        );
        update dcr;
    }

}