/**
 * @author Mavens
 * @description Unit tests for the PJN_ProgramBuilderCtrl class
 * @group Program builder
 */
@isTest
public class PJN_ProgramBuilderCtrlTest {
    static {
        // mock the program metadata query
        PJN_ProgramBuilderCtrl.programQuery = (PJN_ProgramQuery) Test.createStub(PJN_ProgramQuery.class, new PJN_ProgramQueryMock());
        PJN_ProgramBuilderCtrl.programProblemQuery = (PJN_ProgramProblemQuery) Test.createStub(PJN_ProgramProblemQuery.class, new PJN_ProgramProblemMock());
        PJN_ProgramBuilderCtrl.programCaseQuery = (PJN_ProgramCaseQuery)  Test.createStub(PJN_ProgramCaseQuery.class, new PJN_ProgramCaseMock());
        PJN_ProgramBuilderCtrl.programCaseDependQuery = (PJN_ProgramCaseDependencyQuery)  Test.createStub(PJN_ProgramCaseDependencyQuery.class, new PJN_ProgramCaseDependencyMock());
    }

    @isTest
    private static void itShouldReturnPrograms() {
        List<PJN_Program__mdt> programs;
        Test.startTest();
        programs = PJN_ProgramBuilderCtrl.getPrograms();
        Test.stopTest();

        System.assertEquals(2, programs.size());
        System.assertEquals('Alpha Program', programs[0].MasterLabel);
        System.assertEquals('Beta Program', programs[1].MasterLabel);
    }

    @isTest
    private static void itShouldGetProgramVisualizationString() {
        List<Map<string, string>> vizualizationStrings;
        Test.startTest();
        vizualizationStrings = PJN_ProgramBuilderCtrl.getProgramVisualizationString(
            PJN_Program__mdt.SobjectType.getDescribe().getKeyPrefix() + '000000000001'
        );
        Test.stopTest();

        System.assertEquals('standard', vizualizationStrings[0].get('key'));
        System.assertNotEquals(null, vizualizationStrings[0].get('chartDefinition'));
        System.assertNotEquals(0, vizualizationStrings[0].get('chartDefinition').length());
    }
}