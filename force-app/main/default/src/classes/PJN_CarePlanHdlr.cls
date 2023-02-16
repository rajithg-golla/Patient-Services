/**
 * @author      Mavens
 * @group       CarePlanHdlr
 * @description CarePlan handler to
 *              - create CarePlan
 *              - start CarePlan
 */
public inherited sharing class PJN_CarePlanHdlr {
    /**
     * care plan mapping engine
     */
    @testVisible private PJN_MappingEngine carePlanMappingEngine = new PJN_MappingEngine();

    /**
     * program and program problem queries
     */
    @testVisible private static PJN_ProgramQuery programQuery = new PJN_ProgramQuery();
    @testVisible private static PJN_ProgramProblemQuery programProblemQuery = new PJN_ProgramProblemQuery();

    /**
     * CarePlan
     */
    public List<Case> carePlans;

    /**
     * Source Program
     */
    private PJN_Program__mdt program;

    /**
     * construct CarePlan Handler
     * @param   String      programDeveloperName
     * @param   Id      patientId
     */
    public PJN_CarePlanHdlr(List<Case> carePlans, String programDeveloperName) {
        this.carePlans = carePlans;
        this.program = this.getProgram(programDeveloperName);
    }

    /**
     * create CarePlan from Program
     * @return   Case
     */
    public List<Case> initialize() {
        this.carePlanMappingEngine.initiate(this.program.DeveloperName + '_Create');

        Map<String, List<Id>> sourceObjectIds = new Map<String, List<Id>> {
            'patient' => new List<Id>(),
            'patientlabels' => new List<Id>(),
            'patientdates' => new List<Id>(),
            'program' => new List<Id>(),
            'programlabels' => new List<Id>(),
            'programdates' => new List<Id>()
        };
        for (Case carePlan : carePlans) {
            sourceObjectIds.get('patient').add(carePlan.AccountId);
            sourceObjectIds.get('patientlabels').add(carePlan.AccountId);
            sourceObjectIds.get('patientdates').add(carePlan.AccountId);
            sourceObjectIds.get('program').add(this.program.Id);
            sourceObjectIds.get('programlabels').add(this.program.Id);
            sourceObjectIds.get('programdates').add(this.program.Id);
        }

        carePlans = (List<Case>) this.carePlanMappingEngine.run(
            sourceObjectIds,
            this.carePlans
        ).values();

        for (Case carePlan : carePlans) {
            carePlan.PJN_Care_Plan_Start_Status__c = 'PJN_Started';
        }
        return carePlans;
    }

    /**
     * create CarePlan problems from Program
     * @return   List<HealthCloudGA__CarePlanProblem__c>
     */
    public List<HealthCloudGA__CarePlanProblem__c> createProblems() {
        List<HealthCloudGA__CarePlanProblem__c> problems = new List<HealthCloudGA__CarePlanProblem__c>();

        for(PJN_Program_Problem__mdt thisProgramProblem : this.program.PJN_Program_Problems__r) {
            PJN_CarePlanProblemHdlr problemHandler = new PJN_CarePlanProblemHdlr(thisProgramProblem);
            problems.addAll(
                problemHandler.create(this.carePlans)
            );
        }
        return problems;
    }

    /**
     * create CareProgram Enrollee
     * @return   CareProgramEnrollee
     */
    public List<CareProgramEnrollee> createCareProgramEnrollees() {
        List<CareProgramEnrollee> enrollees = new List<CareProgramEnrollee>();

        for (Case carePlan : this.carePlans) {
            enrollees.add(
                new CareProgramEnrollee(
                    Name = this.program.DeveloperName + '|' + carePlan.AccountId,
                    PJN_External_Id__c = this.program.DeveloperName + '|' + carePlan.AccountId,
                    AccountId = carePlan.AccountId,
                    CareProgram = new CareProgram(
                        PJN_Program_DeveloperName__c = this.program.DeveloperName
                    )
                )
            );
        }
        return enrollees;
    }

    /**
     * get Program from program developer name
     * @param   String      programDeveloperName
     * @return  PJN_Program__mdt
     */
    private PJN_Program__mdt getProgram(String programDeveloperName) {
        return programQuery.queryByDeveloperName(programDeveloperName);
    }
}