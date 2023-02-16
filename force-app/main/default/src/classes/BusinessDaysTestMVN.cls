/**
 * @author      Mavens
 * @group       BusinesDaysMVN
 * @description Unit tests for BusinesDaysMVN 
 */
@isTest(isParallel=true)
public class BusinessDaysTestMVN {
    
    @isTest
    private static void itShouldIndicateIfADayIsABusinessDay() {
        Date knownSunday = date.newInstance(2013, 1, 6);

        BusinessDaysMVN businessDays = new BusinessDaysMVN();
        Test.startTest();
        System.assertEquals(false, businessDays.isBusinessDay(knownSunday));
        System.assert(businessDays.isBusinessDay(knownSunday.addDays(1)));
        System.assert(businessDays.isBusinessDay(knownSunday.addDays(2)));
        System.assert(businessDays.isBusinessDay(knownSunday.addDays(3)));
        System.assert(businessDays.isBusinessDay(knownSunday.addDays(4)));
        System.assert(businessDays.isBusinessDay(knownSunday.addDays(5)));
        System.assertEquals(false, businessDays.isBusinessDay(knownSunday.addDays(6)));
        Test.stopTest();
    }

    @isTest
    private static void itShouldReturnStartTime() {
        Date knownSunday = date.newInstance(2013, 1, 6);

        BusinessDaysMVN businessDays = new BusinessDaysMVN();
        Test.startTest();
        System.assertEquals(Time.newInstance(0,0,0,0), businessDays.getStartTime(knownSunday.addDays(1)));
        Test.stopTest();
    }

    @isTest
    private static void itShouldReturnNextBusinessDay() {
        Date knownSunday = date.newInstance(2013, 1, 6);

        BusinessDaysMVN businessDays = new BusinessDaysMVN();
        Test.startTest();
        System.assertEquals(Date.newInstance(2013, 1, 7), businessDays.nextBusinessDay(knownSunday));
        System.assertEquals(Date.newInstance(2013, 1, 7), businessDays.nextBusinessDay(knownSunday.addDays(1)));
        System.assertEquals(Date.newInstance(2013, 1, 8), businessDays.nextBusinessDay(knownSunday.addDays(2)));
        System.assertEquals(Date.newInstance(2013, 1, 9), businessDays.nextBusinessDay(knownSunday.addDays(3)));
        System.assertEquals(Date.newInstance(2013, 1, 10), businessDays.nextBusinessDay(knownSunday.addDays(4)));
        System.assertEquals(Date.newInstance(2013, 1, 11), businessDays.nextBusinessDay(knownSunday.addDays(5)));
        System.assertEquals(Date.newInstance(2013, 1, 14), businessDays.nextBusinessDay(knownSunday.addDays(7)));
        Test.stopTest();
    }
}