/**
* @author Mavens
* @group UUID
* @description tests generating an universal unique identifier
*/
@isTest(isParallel=true) public class PJN_UUIDGeneratorTest {
    /**
    * @description tests generating an universal unique identifier
    */
    @isTest private static void randomUUID_IsGeneratedAndReturned() {
        Test.startTest();
            String actualUUID = PJN_UUIDGenerator.randomUUID();
        Test.stopTest();

        assertUUIDGeneration(actualUUID);
    }

    /**
    * @description asserts that a proper UUID generation has taken place
    */
    public static void assertUUIDGeneration(String actualUUID) {
        System.assertNotEquals(null, actualUUID);
        System.assertNotEquals('', actualUUID);
        System.assertEquals(36, actualUUID.length());
        List<String> actualUUIDParts = actualUUID.split('-');
        System.assertEquals(8, actualUUIDParts.get(0).length());
        System.assertEquals(4, actualUUIDParts.get(1).length());
        System.assertEquals(4, actualUUIDParts.get(2).length());
        System.assertEquals(4, actualUUIDParts.get(3).length());
        System.assertEquals(12, actualUUIDParts.get(4).length());
    }
}