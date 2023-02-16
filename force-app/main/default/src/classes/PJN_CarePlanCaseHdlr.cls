/**
 * @author      Mavens
 * @group       CarePlanHdlr
 * @description CarePlan Case handler to
 *              - create and thereby start a Case
 */
 public inherited sharing class PJN_CarePlanCaseHdlr {
    /**
     * care plan case mapping engine
     */
    @testVisible private PJN_MappingEngine carePlanCaseMappingEngine = new PJN_MappingEngine();

    /**
     * Program Case Query Class
     */
    @testVisible private static PJN_ProgramCaseQuery programCaseQuery = new PJN_ProgramCaseQuery();

    /**
     * CarePlan Problem this Case is related to
     */
    private HealthCloudGA__CarePlanProblem__c carePlanProblem;

    /**
     * Case that is source of creation
     */
    private Case carePlanCase;

    /**
     * Program Case that is source of creation
     */
    private PJN_Program_Case__mdt programCase;

    /**
     * construct CarePlan Case Handler
     * @param   HealthCloudGA__CarePlanProblem__c      carePlanProblem
     */
    public PJN_CarePlanCaseHdlr(HealthCloudGA__CarePlanProblem__c carePlanProblem, String programCaseDeveloperName) {
        this.carePlanProblem = carePlanProblem;
        this.programCase = programCaseQuery.queryByDeveloperName(programCaseDeveloperName);
    }

    public PJN_CarePlanCaseHdlr(HealthCloudGA__CarePlanProblem__c carePlanProblem, PJN_Program_Case__mdt programCase) {
        this.carePlanProblem = carePlanProblem;
        this.programCase = programCase;
    }

    /**
     * construct CarePlan Case Handler
     */
    public PJN_CarePlanCaseHdlr(Case carePlanCase) {
        this.carePlanCase = carePlanCase;
        if(!String.IsBlank(carePlanCase.PJN_Program_Case_DeveloperName__c)) {
            this.programCase = programCaseQuery.queryByDeveloperName(carePlanCase.PJN_Program_Case_DeveloperName__c);
        }
    }

    /**
     * start CarePlan Case
     * @returns  Case
     */
    public Case start() {
        Case carePlanCase = new Case();
        carePlanCase.OwnerId = this.carePlanProblem.HealthCloudGA__CarePlan__r.OwnerId;
        carePlanCase.AccountId = this.carePlanProblem.HealthCloudGA__CarePlan__r.AccountId;
        carePlanCase.PJN_Program_DeveloperName__c = this.carePlanProblem.HealthCloudGA__CarePlan__r.PJN_Program_DeveloperName__c;
        carePlanCase.ParentId = this.carePlanProblem.HealthCloudGA__CarePlan__c;
        carePlanCase.PJN_CarePlan_Problem__c = this.carePlanProblem.Id;
        carePlanCase.PJN_Program_Case_DeveloperName__c = this.programCase.DeveloperName;
        carePlanCase.Subject = this.programCase.Label;
        carePlanCase.Origin = 'Program';
        this.carePlanCaseMappingEngine.initiate(this.programCase.DeveloperName + '_Start');
        carePlanCase = (Case) this.carePlanCaseMappingEngine.run(
            new Map<String, Id> {
                'patient' => this.carePlanProblem.HealthCloudGA__CarePlan__r.AccountId,
                'patientlabels' => this.carePlanProblem.HealthCloudGA__CarePlan__r.AccountId,
                'patientdates' => this.carePlanProblem.HealthCloudGA__CarePlan__r.AccountId,
                'careplan' => this.carePlanProblem.HealthCloudGA__CarePlan__c,
                'careplanlabels' => this.carePlanProblem.HealthCloudGA__CarePlan__c,
                'careplandates' => this.carePlanProblem.HealthCloudGA__CarePlan__c,
                'programcase' => this.programCase.Id,
                'programcaselabels' => this.programCase.Id,
                'programcasedates' => this.programCase.Id
            },
            carePlanCase
        );
        return carePlanCase;
    }

    /**
     * skips CarePlan Case
     * @returns `Case`
     */
    public Case skip() {
        carePlanCase.Status = 'Cancelled';
        if(!String.IsBlank(carePlanCase.PJN_Program_Case_DeveloperName__c)) { // run mapping engine only for activities created by the program
            this.carePlanCaseMappingEngine.initiate(this.programCase.DeveloperName + '_Skip');
            this.carePlanCase = (Case) this.carePlanCaseMappingEngine.run(
                new Map<String, Id> {
                    'patient' => this.carePlanCase.Parent.AccountId,
                    'patientlabels' => this.carePlanCase.Parent.AccountId,
                    'patientdates' => this.carePlanCase.Parent.AccountId,
                    'careplan' => this.carePlanCase.ParentId,
                    'careplanlabels' => this.carePlanCase.ParentId,
                    'careplandates' => this.carePlanCase.ParentId
                },
                this.carePlanCase
            );
        }
        return this.carePlanCase;
    }

    public Case stop() {
        carePlanCase.Status = 'Cancelled';
        if(String.IsBlank(carePlanCase.PJN_Program_Case_DeveloperName__c)) { // run mapping engine only for activities created by the program
            this.carePlanCaseMappingEngine.initiate(this.programCase.DeveloperName + '_Skip');
            this.carePlanCase = (Case) this.carePlanCaseMappingEngine.run(
                new Map<String, Id> {
                    'patient' => this.carePlanCase.Parent.AccountId,
                    'patientlabels' => this.carePlanCase.Parent.AccountId,
                    'patientdates' => this.carePlanCase.Parent.AccountId,
                    'careplan' => this.carePlanCase.ParentId,
                    'careplanlabels' => this.carePlanCase.ParentId,
                    'careplandates' => this.carePlanCase.ParentId
                },
                this.carePlanCase
            );
        }
        return this.carePlanCase;
    }
}