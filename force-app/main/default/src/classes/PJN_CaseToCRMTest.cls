/**
 * Unit tests ffor the PJN_CaseToCRM
 * @author Mavens
 */
@isTest()
public with sharing class PJN_CaseToCRMTest {

    @TestSetup
    private static void makeData() {
        insertHCP('test1234');
        insertPatient();
    }

    static {
        PJN_CaseToCRMHdlr.crmConnectionSettingQuery = (PJN_CRMConnectionSettingQuery) PJN_CRMConnectionSettingMockUtil.createMock(PJN_CRMConnectionSettingQuery.class);
    }

    @isTest
    private static void testCmtMock() {
        System.assertNotEquals(0, PJN_CaseToCRMHdlr.crmConnectionSettingQuery.queryBySettingByType('Case Escalation').size(), 'CMT records not found. This test class won\'t work without CMT records.');
    }

    @isTest
    private static void testCalloutThatReturnSuccess() {
        Account physician = [SELECT Id FROM Account WHERE PJN_NPI__c = 'test1234' LIMIT 1];
        Account patient = [SELECT Id FROM Account WHERE PJN_NPI__c = null LIMIT 1];

        PJN_VeevaCRMMockResponseGenerator mockGenerator = new PJN_VeevaCRMMockResponseGenerator('Suggestion', false);
        Test.setMock(HttpCalloutMock.class, mockGenerator);

        Test.startTest();
        Case c = insertCase(patient, physician);
        Test.stopTest();

        c = [SELECT PJN_Veeva_CRM_Suggestion_External_Id__c FROM Case WHERE Id = :c.Id];
        System.assertNotEquals(NULL, c.PJN_Veeva_CRM_Suggestion_External_Id__c, 'Case external Id should be filled.');
    }

    @isTest
    private static void testCalloutThatReturnsError() {
        Account physician = [SELECT Id FROM Account WHERE PJN_NPI__c = 'test1234' LIMIT 1];
        Account patient = [SELECT Id FROM Account WHERE PJN_NPI__c = null LIMIT 1];

        PJN_VeevaCRMMockResponseGenerator mockGenerator = new PJN_VeevaCRMMockResponseGenerator('Suggestion', true);
        Test.setMock(HttpCalloutMock.class, mockGenerator);

        Test.startTest();
        Case c = insertCase(patient, physician);
        Test.stopTest();

        c = [SELECT PJN_Veeva_CRM_Suggestion_Error__c FROM Case WHERE Id = :c.Id];

        System.assertNotEquals(NULL, c.PJN_Veeva_CRM_Suggestion_Error__c, 'Case error should be filled.');
    }

    private static Case insertCase(Account acct, Account physician) {
        PJN_TestFactoryCase caseFactory = new PJN_TestFactoryCase();
        Case result = caseFactory.construct(new Map<String, Object> {
            'RecordTypeId' => SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PJN_Activity').getRecordTypeId(),
            'OwnerId' => [SELECT Id FROM Group WHERE Type = 'Queue' AND Developername = 'PJN_Escalated_To_CRM'].Id,
            'AccountId' => acct.Id,
            'Description' => 'Test',
            'PJN_Physician__c' => physician.Id,
            'Subject' => 'Test',
            'Status' => 'Open'
        });

        insert result;
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
            'RecordTypeId' => [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PJN_Patient' LIMIT 1].Id
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