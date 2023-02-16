/**
 * Test for PJN_ObjectFieldContactInfoMappingsQuery
 * @author  Mavens
 * @group   Network
 */
@IsTest
public with sharing class PJN_ObjFieldContactInfoMappingsQueryTest {

    @IsTest
    static void testQueryObjectFieldContactInfoMappings() {
        List<PJN_Object_Field_Contact_Info_Mapping__mdt> objectFieldContactInfoMappings;

        Test.startTest();
        PJN_ObjectFieldContactInfoMappingsQuery objectFieldContactInfoMappingsQuery = new PJN_ObjectFieldContactInfoMappingsQuery();
        objectFieldContactInfoMappings = objectFieldContactInfoMappingsQuery.queryAll();
        Test.stopTest();

        System.assert(objectFieldContactInfoMappings != null, 'Object Field Contact Info mappings cannot be null.');
    }
}