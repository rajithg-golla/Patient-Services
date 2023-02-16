/**
* @author Mavens
* @date Jan 2019
* @description Class to provide factory methods to create test data for Case object
* @group TestFactory
*/
@isTest(isParallel=true) public class PJN_TestFactoryAccount {

    private PJN_TestFactorySObject objectFactory;

    private Map<String, Object> basicPhysicianValues = new Map<String, Object> {
        'RecordTypeId' => PJN_SObjectUtil.getPhysicianRecordType().getRecordTypeId(),
        'FirstName' => 'Physician',
        'LastName' => 'Account'
    };

    private Map<String, Object> basicHCOValues = new Map<String, Object> {
        'RecordTypeId' => PJN_SObjectUtil.getHCORecordType().getRecordTypeId(),
        'Name' => 'HCO'
    };

    public PJN_TestFactoryAccount() {
        objectFactory = new PJN_TestFactorySObject('Account', new Map<String, Object>());
    }

    public Account construct(Map<String, Object> valuesByField){
        return (Account) objectFactory.constructSObject(valuesByField);
    }

    public Account create(Map<String, Object> valuesByField){
        return (Account) objectFactory.createSObject(valuesByField);
    }

    public List<Account> constructMany(Integer numOfRequests, Map<String,Object> valuesByField) {
        return (List<Account>) objectFactory.constructSObjects(numOfRequests, valuesByField);
    }

    public List<Account> createMany(Integer numOfRequests, Map<String,Object> valuesByField) {
        return (List<Account>) objectFactory.createSObjects(numOfRequests, valuesByField);
    }

    public Account constructPhysician(Map<String, Object> valuesByField){

        basicPhysicianValues.putAll(valuesByField);
        return (Account) construct(basicPhysicianValues);
    }

    public List<Account> constructManyPhysicians(Map<String, Object> valuesByField, Integer numberOfAccounts){
        List<Account> Physicians = new List<Account>();
        basicPhysicianValues.putAll(valuesByField);

        for (Integer index = 0; index < numberOfAccounts; index++) {
            Physicians.add(constructPhysician(basicPhysicianValues));
        }

        return Physicians;
    }

    public Account constructHCO(Map<String, Object> valuesByField){

        basicHCOValues.putAll(valuesByField);
        return (Account) construct(basicHCOValues);
    }

    public List<Account> constructManyHCOs(Map<String, Object> valuesByField, Integer numberOfAccounts){
        List<Account> hcos = new List<Account>();
        basicHCOValues.putAll(valuesByField);

        for (Integer index = 0; index < numberOfAccounts; index++) {
            hcos.add(constructHCO(basicHCOValues));
        }

        return hcos;
    }
}