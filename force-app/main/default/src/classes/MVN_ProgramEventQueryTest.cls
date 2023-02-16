/**
* @author Mavens
* @description Mocks for Program Event Query
* @group Events
*/
@isTest
public class MVN_ProgramEventQueryTest {

    @isTest
    private static void itShouldReturnAMapForProgram() {
        MVN_ProgramEventQuery query = new MVN_ProgramEventQuery();
        Test.startTest();
        Map<String, List<MVN_Program_Event__mdt>> returned = query.forProblems();
        Test.stopTest();

        System.assertNotEquals(null, returned);
    }

    @isTest
    private static void itShouldReturnAMapForActivity() {
        MVN_ProgramEventQuery query = new MVN_ProgramEventQuery();
        Test.startTest();
        Map<String, List<MVN_Program_Event__mdt>> returned = query.forActivities();
        Test.stopTest();

        System.assertNotEquals(null, returned);
    }

    @isTest
    private static void itShouldReturnAMapForFulfillmentRequest() {
        MVN_ProgramEventQuery query = new MVN_ProgramEventQuery();
        Test.startTest();
        Map<String, List<MVN_Program_Event__mdt>> returned = query.forFulfillmentRequests();
        Test.stopTest();

        System.assertNotEquals(null, returned);
    }
}