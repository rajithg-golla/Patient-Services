/**
 * @author      Mavens
 * @group       TestUtilityMVN
 * @description Testing Utilities
 */
@isTest
public class TestUtilityMVN {
    

    public static User getDRProgramSpecialist() {
        Id programSpecialistProfileId = [SELECT Id FROM Profile WHERE Name = 'Diabetic Retinopathy Program Specialist'].Id;

        return new User(
            Alias = 'progSpec',
            Email='programspecialist@testorg.com',
            EmailEncodingKey='UTF-8', 
            LastName='Specialist', 
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = programSpecialistProfileId,
            TimeZoneSidKey='America/Los_Angeles', 
            UserName='programspecialist@testorg.com'
        );
    }
}