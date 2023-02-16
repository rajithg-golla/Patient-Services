/**
* @author Mavens
* @date Jan 2019
* @description Class to provide factory methods to create test data for Case object
* @group TestFactory
*/
@isTest(isParallel=true) public class PJN_TestFactoryCase {

    private PJN_TestFactorySObject objectFactory;

    public PJN_TestFactoryCase() {
        objectFactory = new PJN_TestFactorySObject('Case', new Map<String, Object>());
    }

    public Case construct(Map<String, Object> valuesByField){
        return (Case) objectFactory.constructSObject(valuesByField);
    }

    public Case create(Map<String, Object> valuesByField){
        return (Case) objectFactory.createSObject(valuesByField);
    }

    public List<Case> constructMany(Integer numOfRequests, Map<String,Object> valuesByField) {
        return (List<Case>) objectFactory.constructSObjects(numOfRequests, valuesByField);
    }

    public List<Case> createMany(Integer numOfRequests, Map<String,Object> valuesByField) {
        return (List<Case>) objectFactory.createSObjects(numOfRequests, valuesByField);
    }
}