/**
 * Unit tests ffor the PJN_EventToCRM
 * @author Mavens
 */
@isTest(isParallel=false)
public with sharing class PJN_EventToCRMTest {
    @testSetup
    static void makeData() {
        Account oldDoctor = insertHCP('test2345');
        Account newDoctor = insertHCP('test1234');
        Account patient = insertPatient();
        Case c = insertCase(patient, newDoctor);
    }

    static {
        PJN_EventToCRMHdlr.crmConnectionSettingQuery = (PJN_CRMConnectionSettingQuery) PJN_CRMConnectionSettingMockUtil.createMock(PJN_CRMConnectionSettingQuery.class);
    }

    @isTest
    private static void testCmtMock() {
        System.assertNotEquals(0, PJN_EventToCRMHdlr.crmConnectionSettingQuery.queryBySettingByType('Case Escalation').size(), 'CMT records not found. This test class won\'t work without CMT records.');
    }

    @isTest static void testCalloutThatReturnSuccess() {
        Account oldDoctor = [SELECT Id FROM Account WHERE PJN_NPI__c = 'test2345'];
        Account newDoctor = [SELECT Id FROM Account WHERE PJN_NPI__c = 'test1234'];
        Account patient = [SELECT Id FROM Account WHERE RecordTypeId = :SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId() LIMIT 1];
        Case c = [SELECT Id, PJN_Veeva_CRM_Enrollment_External_Id__c FROM Case WHERE RecordTypeId = :SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId() LIMIT 1];
        PJN_Event__c event = constructEvent(
            new Map<String, Id>{
                'PJN_New_Physician__c' => newDoctor.Id,
                'PJN_Patient__c' => patient.Id,
                'PJN_Previous_Physician__c' => oldDoctor.Id
            }, c);

        PJN_VeevaCRMMockResponseGenerator mockGenerator = new PJN_VeevaCRMMockResponseGenerator('Event', c.PJN_Veeva_CRM_Enrollment_External_Id__c, false);
        Test.setMock(HttpCalloutMock.class, mockGenerator);

        setEventOnlyTriggers();

        Test.startTest();
            insert event;
        Test.stopTest();

        c = [SELECT PJN_Veeva_CRM_Enrollment_External_Id__c FROM Case WHERE Id = :c.Id];
        System.assertNotEquals(NULL, c.PJN_Veeva_CRM_Enrollment_External_Id__c, 'Case external Id should be filled.');
        resetTriggers();
    }

    @isTest static void testCalloutThatReturnsError() {
        Account oldDoctor = [SELECT Id FROM Account WHERE PJN_NPI__c = 'test2345'];
        Account newDoctor = [SELECT Id FROM Account WHERE PJN_NPI__c = 'test1234'];
        Account patient = [SELECT Id FROM Account WHERE RecordTypeId = :SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId() LIMIT 1];
        Case c = [SELECT Id, PJN_Veeva_CRM_Enrollment_External_Id__c FROM Case WHERE RecordTypeId = :SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId() LIMIT 1];
        PJN_Event__c event = constructEvent(
            new Map<String, Id>{
                'PJN_New_Physician__c' => newDoctor.Id,
                'PJN_Patient__c' => patient.Id,
                'PJN_Previous_Physician__c' => oldDoctor.Id
            }, c);

        PJN_VeevaCRMMockResponseGenerator mockGenerator = new PJN_VeevaCRMMockResponseGenerator('Event', c.PJN_Veeva_CRM_Enrollment_External_Id__c, true);
        Test.setMock(HttpCalloutMock.class, mockGenerator);

        setEventOnlyTriggers();

        Test.startTest();
        insert event;
        Test.stopTest();

        c = [SELECT PJN_Veeva_CRM_Enrollment_Error__c FROM Case WHERE Id = :c.Id];
        //System.assertNotEquals(NULL, c.PJN_Veeva_CRM_Enrollment_Error__c, 'Case error should be filled.');

        resetTriggers();
    }

    private static void setEventOnlyTriggers() {
        // query for all settings for this object and mock the ones we need turned on
        List<PJN_Trigger_Handler_Setting__mdt> caseSettings = new List<PJN_Trigger_Handler_Setting__mdt>();
        List<PJN_Trigger_Handler_Setting__mdt> allCaseObjSettings = [
            SELECT PJN_Class__c, PJN_Event__c, PJN_Active__c
            FROM PJN_Trigger_Handler_Setting__mdt
            WHERE PJN_SObject_API_Name__c = 'Case'
            ORDER BY PJN_Order__c ASC
        ];
        // already active? keep it. If not active but is the class we care about then treat as active
        for (PJN_Trigger_Handler_Setting__mdt setting : allCaseObjSettings) {
            if (setting.PJN_Active__c) {
                setting.PJN_Active__c = false;
                caseSettings.add(setting);
            }
        }
        PJN_TriggerHandlerSettingQuery.triggerHandlerSettingBySObjectType.put(
            Case.getSObjectType(),
            caseSettings
        );

        List<PJN_Trigger_Handler_Setting__mdt> eventSettings = new List<PJN_Trigger_Handler_Setting__mdt>();
        List<PJN_Trigger_Handler_Setting__mdt> allEventObjSettings = [
            SELECT PJN_Class__c, PJN_Event__c, PJN_Active__c
            FROM PJN_Trigger_Handler_Setting__mdt
            WHERE PJN_SObject_API_Name__c = 'PJN_Event__c'
            ORDER BY PJN_Order__c ASC
        ];

        // already active? keep it. If not active but is the class we care about then treat as active
        for (PJN_Trigger_Handler_Setting__mdt setting : allEventObjSettings) {
            if (setting.PJN_Active__c || setting.PJN_Class__c == 'PJN_EventToCRM') {
                eventSettings.add(setting);
            }
        }
        PJN_TriggerHandlerSettingQuery.triggerHandlerSettingBySObjectType.put(
            PJN_Event__c.getSObjectType(),
            eventSettings
        );
    }

    private static void resetTriggers() {
        PJN_TriggerHandlerSettingQuery.triggerHandlerSettingBySObjectType.remove(Case.getSObjectType());
        PJN_TriggerHandlerSettingQuery.triggerHandlerSettingBySObjectType.remove(PJN_Event__c.getSObjectType());
    }

    private static PJN_Event__c constructEvent(Map<String, Id> idMap, Case c) {
        return new PJN_Event__c(
            RecordTypeId = SObjectType.PJN_Event__c.getRecordTypeInfosByDeveloperName().get('PJN_Therapy_Status_Update').getRecordTypeId(),
            PJN_New_Physician__c = idMap.get('PJN_New_Physician__c'),
            PJN_Patient__c = idMap.get('PJN_Patient__c'),
            PJN_Case__c = c.Id,
            PJN_Previous_Physician__c = idMap.get('PJN_Previous_Physician__c'));
    }

    private static Case insertCase(Account patient, Account physician) {
        PJN_TestFactoryCase caseFactory = new PJN_TestFactoryCase();
        Case result = caseFactory.construct(new Map<String, Object>{
            'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByDeveloperName().get('CarePlan').getRecordTypeId(),
            'AccountId' => patient.Id,
            'PJN_Physician__c' => physician.Id,
            'Subject' => 'Test',
            'Description' => 'Test'
        });

        insert result;
        result.PJN_Veeva_CRM_Enrollment_External_Id__c = result.Id;
        update result;
        return result;
    }

    private static Account insertHCP(String networkId) {
        PJN_TestFactoryAccount accountFactory = new PJN_TestFactoryAccount();
        Account acct = accountFactory.constructPhysician(new Map<String, Object>{'PJN_NPI__c' => networkId});

        insert acct;
        return acct;
    }

    private static Account insertPatient() {
        PJN_TestFactoryAccount accountFactory = new PJN_TestFactoryAccount();
        Account acct = accountFactory.construct(new Map<String, Object>{
            'FirstName' => getRandomFirstName(),
            'LastName' => getRandomLastName(),
            'RecordTypeId' => SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PJN_Patient').getRecordTypeId()
        });

        insert acct;
        return acct;
    }

    private static String getRandomFirstName() {
        List<String> firstNames = new List<String> {'Aaliyah', 'Abigail', 'Addison', 'Alexa', 'Alexandra', 'Alexis', 'Alice', 'Allison', 'Alyssa', 'Amelia', 'Anna', 'Annabelle', 'Aria', 'Ariana', 'Arianna', 'Ashley', 'Aubree', 'Aubrey', 'Audrey', 'Autumn', 'Ava', 'Avery', 'Bella', 'Brianna', 'Brooklyn', 'Camila', 'Caroline', 'Charlotte', 'Chloe', 'Claire', 'Eleanor', 'Elizabeth', 'Ella', 'Ellie', 'Emily', 'Emma', 'Eva', 'Evelyn', 'Faith', 'Florian', 'Gabriella', 'Genesis', 'Gianna', 'Grace', 'Hadley', 'Hailey', 'Hannah', 'Harper', 'Isabella', 'Isabelle', 'Jasmine', 'Jen', 'Jennifer', 'Julia', 'Katherine', 'Kaylee', 'Kennedy', 'Khloe', 'Kylie', 'Lauren', 'Layla', 'Leah', 'Lillian', 'Lily', 'London', 'Lucy', 'Lydia', 'Mackenzie', 'Madeline', 'Madelyn', 'Madison', 'Maya', 'Melanie', 'Mia', 'Mila', 'Naomi', 'Natalie', 'Nevaeh', 'Nora', 'Olivia', 'Paisley', 'Penelope', 'Peyton', 'Piper', 'Riley', 'Ruby', 'Sadie', 'Samantha', 'Sarah', 'Savannah', 'Scarlett', 'Serenity', 'Skylar', 'Sofia', 'Sophia', 'Sophie', 'Stella', 'Taylor', 'Victoria', 'Violet', 'Vivian', 'Zoe', 'Zoey', 'Aaron', 'Adam', 'Adrian', 'Aiden', 'Alexander', 'Andrew', 'Angel', 'Anthony', 'Asher', 'Austin', 'Ayden', 'Benjamin', 'Bentley', 'Blake', 'Brandon', 'Brayden', 'Brody', 'Caleb', 'Camden', 'Cameron', 'Carson', 'Carter', 'Charles', 'Chase', 'Christian', 'Christopher', 'Colton', 'Connor', 'Cooper', 'Daniel', 'David', 'Dominic', 'Dylan', 'Easton', 'Eli', 'Elijah', 'Ethan', 'Evan', 'Gabriel', 'Gavin', 'Grayson', 'Henry', 'Hudson', 'Hunter', 'Ian', 'Isaac', 'Isaiah', 'Jace', 'Jack', 'Jackson', 'Jacob', 'James', 'Jason', 'Jaxon', 'Jaxson', 'Jayden', 'Jeremiah', 'John', 'Jonathan', 'Jordan', 'Jose', 'Joseph', 'Joshua', 'Josiah', 'Juan', 'Julian', 'Justin', 'Kayden', 'Kevin', 'Landon', 'Leo', 'Levi', 'Liam', 'Lincoln', 'Logan', 'Lucas', 'Luis', 'Luke', 'Mason', 'Matthew', 'Michael', 'Nathan', 'Nathaniel', 'Nicholas', 'Noah', 'Nolan', 'Oliver', 'Owen', 'Parker', 'Rhonda', 'Robert', 'Ryan', 'Richard', 'Rick', 'Ryder', 'Samuel', 'Sebastian', 'Thomas', 'Tristan', 'Tyler', 'William', 'Wyatt', 'Xavier', 'Zachary'};
        Integer firstNameIndex = (Integer)(Math.random() * firstNames.size());
        string firstNameSelected = firstNames[firstNameIndex];
        return firstNameSelected;
    }

    private static String getRandomLastName() {
        List<String> lastNames = new List<String> {'Adams', 'Alexander', 'Allen', 'Alvarez', 'Anderson', 'Arnold', 'Bailey', 'Baker', 'Barnes', 'Bell', 'Bennett', 'Black', 'Boyd', 'Bradley', 'Brooks', 'Brown', 'Bryant', 'Burns', 'Butler', 'Campbell', 'Carter', 'Castillo', 'Castro', 'Chavez', 'Clark', 'Cole', 'Coleman', 'Collins', 'Cook', 'Cooper', 'Cox', 'Crawford', 'Cruz', 'Cunningham', 'Daniels', 'Davis', 'Diaz', 'Dixon', 'Dunn', 'Edwards', 'Elliott', 'Ellis', 'Evans', 'Ferguson', 'Fernandez', 'Fisher', 'Flores', 'Ford', 'Foster', 'Fox', 'Freeman', 'Garcia', 'Gardner', 'Gibson', 'Gomez', 'Gonzales', 'Gonzalez', 'Gordon', 'Graham', 'Grant', 'Gray', 'Green', 'Griffin', 'Gutierrez', 'Hajcak', 'Hall', 'Hamilton', 'Hansen', 'Harris', 'Harrison', 'Hart', 'Hawkins', 'Hayes', 'Helmer', 'Henderson', 'Henry', 'Hernandez', 'Herrera', 'Hicks', 'Hill', 'Hoehn', 'Hoffman', 'Holmes', 'Howard', 'Hughes', 'Hunt', 'Hunter', 'Jackson', 'James', 'Jenkins', 'Jimenez', 'Johnson', 'Jones', 'Jordan', 'Kelley', 'Kelly', 'Kennedy', 'Kim', 'King', 'Knight', 'Lee', 'Lewis', 'Locke', 'Long', 'Lopez', 'Marshall', 'Martin', 'Martinez', 'Mason', 'Mcdonald', 'Medina', 'Mendoza', 'Meyer', 'Miller', 'Mills', 'Mitchell', 'Moore', 'Morales', 'Moreno', 'Morgan', 'Morris', 'Murphy', 'Murray', 'Myers', 'Nelson', 'Nguyen', 'Nichols', 'Olson', 'Ortiz', 'Owens', 'Palmer', 'Parker', 'Patel', 'Patterson', 'Payne', 'Perez', 'Perry', 'Peters', 'Peterson', 'Phillips', 'Pierce', 'Porter', 'Powell', 'Price', 'Ramirez', 'Ramos', 'Reed', 'Reyes', 'Reynolds', 'Rice', 'Richardson', 'Rivera', 'Roberts', 'Robertson', 'Robinson', 'Rodriguez', 'Rogers', 'Romero', 'Rose', 'Ross', 'Ruiz', 'Russell', 'Ryan', 'Sanchez', 'Sanders', 'Schmidt', 'Scott', 'Shaw', 'Simmons', 'Simpson', 'Smith', 'Snyder', 'Spencer', 'Stephens', 'Stevens', 'Stewart', 'Stone', 'Sullivan', 'Taylor', 'Thomas', 'Thompson', 'Torres', 'Tran', 'Tucker', 'Turner', 'Vasquez', 'Wagner', 'Walker', 'Wallace', 'Ward', 'Warren', 'Washington', 'Watson', 'Weaver', 'Webb', 'Wells', 'West', 'White', 'Williams', 'Wilson', 'Wood', 'Woods', 'Wright', 'Wyher', 'Young'};
        Integer lastNameIndex = (Integer)(Math.random() * lastNames.size());
        string lastNameSelected = lastNames[lastNameIndex];
        return lastNameSelected;
    }
}