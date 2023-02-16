/**
 * @author      Mavens
 * @group       CarePlanHdlr
 * @description CarePlan Problems handler to
 *              - create CarePlan Problems
 *              - start CarePlan Problem
 */
public inherited sharing class PJN_CarePlanProblemHdlr {
    /**
     * program problem query
     */
    @testVisible private static PJN_ProgramProblemQuery programProblemQuery = new PJN_ProgramProblemQuery();

    /**
     * care plan problem mapping engine
     */
    @testVisible private static PJN_MappingEngine carePlanProblemMappingEngine = new PJN_MappingEngine();

    /**
     * CarePlan Problem that is handled
     */
    private HealthCloudGA__CarePlanProblem__c carePlanProblem;

    /**
     * Program Problem that is source of creation
     */
    public PJN_Program_Problem__mdt programProblem;

    /**
     * (empty) construct CarePlan Problem Handler
     */
    public PJN_CarePlanProblemHdlr() {
        // empty constructor for static usage
    }

    /**
     * construct CarePlan Problem Handler
     * @param   PJN_Program_Problem__mdt      programProblem
     */
    public PJN_CarePlanProblemHdlr(PJN_Program_Problem__mdt programProblem) {
        this.programProblem = programProblem;
    }

    /**
     * construct CarePlan Problem Handler
     * @param   HealthCloudGA__CarePlanProblem__c        carePlanProblem
     */
    public PJN_CarePlanProblemHdlr(HealthCloudGA__CarePlanProblem__c carePlanProblem) {
        this.carePlanProblem = carePlanProblem;
        this.programProblem = programProblemQuery.queryByDeveloperName(this.carePlanProblem.PJN_Program_Problem_DeveloperName__c);
    }

    /**
     * create CarePlan Problem from Program Problem
     * @param   Case        carePlan
     * @returns  HealthCloudGA__CarePlanProblem__c
     */
    public HealthCloudGA__CarePlanProblem__c create(Case carePlan) {
        return this.create(new List<Case>{ carePlan })[0];
    }

    public List<HealthCloudGA__CarePlanProblem__c> create(List<Case> carePlans) {
        List<HealthCloudGA__CarePlanProblem__c> carePlanProblems = new List<HealthCloudGA__CarePlanProblem__c>();
        carePlanProblemMappingEngine.initiate(this.programProblem.DeveloperName + '_Create');

        Map<String, List<Id>> sourceObjectIds = new Map<String, List<Id>> {
            'careplan' => new List<Id>(),
            'careplanlabels' => new List<Id>(),
            'careplandates' => new List<Id>(),
            'programproblem' => new List<Id>(),
            'programproblemlabels' => new List<Id>(),
            'programproblemdates' => new List<Id>()
        };
        List<HealthCloudGA__CarePlanProblem__c> targetObjects = new List<HealthCloudGA__CarePlanProblem__c>();

        for (Case careplan : carePlans) {
            targetObjects.add(
                new HealthCloudGA__CarePlanProblem__c (
                    OwnerId = carePlan.OwnerId,
                    HealthCloudGA__CarePlan__c = carePlan.Id,
                    HealthCloudGA__SortOrder__c = (this.programProblem.PJN_Order__c != null ? this.programProblem.PJN_Order__c : this.getLastCarePlanProblem(carePlan.Id) + 1),
                    PJN_Program_Problem_DeveloperName__c = this.programProblem.DeveloperName,
                    Name = this.programProblem.Label
                )
            );

            sourceObjectIds.get('careplan').add( carePlan.Id);
            sourceObjectIds.get('careplanlabels').add( carePlan.Id);
            sourceObjectIds.get('careplandates').add( carePlan.Id);
            sourceObjectIds.get('programproblem').add( this.programProblem.Id);
            sourceObjectIds.get('programproblemlabels').add( this.programProblem.Id);
            sourceObjectIds.get('programproblemdates').add( this.programProblem.Id);
        }

        // overwrite the field used for returning the map since Id (default) doesn't exist yet
        carePlanProblemMappingEngine.identifier = 'HealthCloudGA__CarePlan__c';
        List<HealthCloudGA__CarePlanProblem__c> mappedTargets = (List<HealthCloudGA__CarePlanProblem__c>) carePlanProblemMappingEngine.run(sourceObjectIds, targetObjects).values();

        return mappedTargets;
    }

    /**
     * start CarePlan Problem
     * @returns  Map<HealthCloudGA__CarePlanProblem__c, List<PJN_Program_Case__mdt>>
     */
    public Map<HealthCloudGA__CarePlanProblem__c, List<PJN_Program_Case__mdt>> start(Case carePlan) {
        List<PJN_Program_Case__mdt> nextProgramCases = PJN_ProgramCase.getNextProgramCasesByProgramProblemDeveloperName(this.programProblem.DeveloperName, null);
        this.carePlanProblem.PJN_Status__c = 'Open';
        this.carePlanProblem.HealthCloudGA__SortOrder__c = this.getLastOpenCarePlanProblem(carePlan);
        carePlanProblemMappingEngine.initiate(this.programProblem.DeveloperName + '_Start');
        this.carePlanProblem = (HealthCloudGA__CarePlanProblem__c) carePlanProblemMappingEngine.run(
            new Map<String, Id> {
                'careplan' => carePlan.Id,
                'careplanlabels' => carePlan.Id,
                'careplandates' => carePlan.Id,
                'programproblem' => this.programProblem.Id,
                'programproblemlabels' => this.programProblem.Id,
                'programproblemdates' => this.programProblem.Id
            },
            this.carePlanProblem
        );
        return new Map<HealthCloudGA__CarePlanProblem__c, List<PJN_Program_Case__mdt>> {
            this.carePlanProblem => nextProgramCases
        };
    }

    /**
     * skip CarePlan Problem
     * @returns  Map<HealthCloudGA__CarePlanProblem__c, List<Case>>
     */
    public Map<HealthCloudGA__CarePlanProblem__c, List<Case>> skip() {
        List<Case> carePlanCasesToSkip = new List<Case>();
        for(Case thisCarePlanCase : PJN_CarePlanCaseQuery.queryOpenCasesByProblem(this.carePlanProblem.Id)) {
            thisCarePlanCase = (new PJN_CarePlanCaseHdlr(thisCarePlanCase)).skip();
            carePlanCasesToSkip.add(thisCarePlanCase);
        }
        this.carePlanProblem.PJN_Status__c = 'Cancelled';
        this.carePlanProblem.HealthCloudGA__SortOrder__c = this.getLastClosedCarePlanProblem(this.carePlanProblem.HealthCloudGA__CarePlan__c);
        carePlanProblemMappingEngine.initiate(this.programProblem.DeveloperName + '_Skip');
        this.carePlanProblem = (HealthCloudGA__CarePlanProblem__c) carePlanProblemMappingEngine.run(
            new Map<String, Id> {
                'careplan' => this.carePlanProblem.HealthCloudGA__CarePlan__c,
                'careplanlabels' => this.carePlanProblem.HealthCloudGA__CarePlan__c,
                'careplandates' => this.carePlanProblem.HealthCloudGA__CarePlan__c,
                'programproblem' => this.programProblem.Id,
                'programproblemlabels' => this.programProblem.Id,
                'programproblemdates' => this.programProblem.Id
            },
            this.carePlanProblem
        );
        return new Map<HealthCloudGA__CarePlanProblem__c, List<Case>> {
            this.carePlanProblem => carePlanCasesToSkip
        };
    }

    /**
     * close CarePlan Problem
     * @returns  List<Case>
     */
    public HealthCloudGA__CarePlanProblem__c close() {
        this.carePlanProblem.PJN_Status__c = 'Closed';
        this.carePlanProblem.HealthCloudGA__SortOrder__c = this.getLastClosedCarePlanProblem(this.carePlanProblem.HealthCloudGA__CarePlan__c);
        carePlanProblemMappingEngine.initiate(this.programProblem.DeveloperName + '_Close');
        this.carePlanProblem = (HealthCloudGA__CarePlanProblem__c) carePlanProblemMappingEngine.run(
            new Map<String, Id> {
                'careplan' => this.carePlanProblem.HealthCloudGA__CarePlan__c,
                'careplanlabels' => this.carePlanProblem.HealthCloudGA__CarePlan__c,
                'careplandates' => this.carePlanProblem.HealthCloudGA__CarePlan__c,
                'programproblem' => this.programProblem.Id,
                'programproblemlabels' => this.programProblem.Id,
                'programproblemdates' => this.programProblem.Id
            },
            this.carePlanProblem
        );
        return this.carePlanProblem;
    }

    /**
     * stop CarePlan Problem
     * @returns  Map<HealthCloudGA__CarePlanProblem__c, List<Case>>
     */
    public Map<HealthCloudGA__CarePlanProblem__c, List<Case>> stop() {
        List<Case> carePlanCasesToStop = new List<Case>();
        for(Case thisCarePlanCase : PJN_CarePlanCaseQuery.queryOpenCasesByProblem(this.carePlanProblem.Id)) {
            thisCarePlanCase = (new PJN_CarePlanCaseHdlr(thisCarePlanCase)).Stop();
            carePlanCasesToStop.add(thisCarePlanCase);
        }
        this.carePlanProblem.PJN_Status__c = 'Cancelled';
        this.carePlanProblem.HealthCloudGA__SortOrder__c = this.getLastClosedCarePlanProblem(this.carePlanProblem.HealthCloudGA__CarePlan__c);
        carePlanProblemMappingEngine.initiate(this.programProblem.DeveloperName + '_Skip');
        this.carePlanProblem = (HealthCloudGA__CarePlanProblem__c) carePlanProblemMappingEngine.run(
            new Map<String, Id> {
                'careplan' => this.carePlanProblem.HealthCloudGA__CarePlan__c,
                'careplanlabels' => this.carePlanProblem.HealthCloudGA__CarePlan__c,
                'careplandates' => this.carePlanProblem.HealthCloudGA__CarePlan__c,
                'programproblem' => this.programProblem.Id,
                'programproblemlabels' => this.programProblem.Id,
                'programproblemdates' => this.programProblem.Id
            },
            this.carePlanProblem
        );
        return new Map<HealthCloudGA__CarePlanProblem__c, List<Case>> {
            this.carePlanProblem => carePlanCasesToStop
        };
    }

    /**
     * get next CarePlan Problem
     * @returns  HealthCloudGA__CarePlanProblem__c
     */
    public HealthCloudGA__CarePlanProblem__c getNextCarePlanProblem(Case carePlan, HealthCloudGA__CarePlanProblem__c carePlanProblem) {
        HealthCloudGA__CarePlanProblem__c nextCarePlanProblem;
        for(HealthCloudGA__CarePlanProblem__c thisCarePlanProblem : carePlan.HealthCloudGA__CarePlanProblems__r) {
            if(thisCarePlanProblem.Id != carePlanProblem.Id
                    && thisCarePlanProblem.HealthCloudGA__SortOrder__c > carePlanProblem.HealthCloudGA__SortOrder__c
                    && nextCarePlanProblem == null) {
                nextCarePlanProblem = thisCarePlanProblem;
            }
        }
        return nextCarePlanProblem;
    }

    /**
     * get open careplan problem Order
     * @returns  Decimal
     */
    public Decimal getLastOpenCarePlanProblem(Case carePlan) {
        HealthCloudGA__CarePlanProblem__c lastCurrentCarePlanProblem;
        HealthCloudGA__CarePlanProblem__c lastClosedCarePlanProblem;
        HealthCloudGA__CarePlanProblem__c nextUpCarePlanProblem;
        for(HealthCloudGA__CarePlanProblem__c thisCarePlanProblem : carePlan.HealthCloudGA__CarePlanProblems__r) {
            if(thisCarePlanProblem.PJN_CarePlan_Path_Status__c == 'current') {
                lastCurrentCarePlanProblem = thisCarePlanProblem;
            }
            if(thisCarePlanProblem.PJN_CarePlan_Path_Status__c == 'complete') {
                lastClosedCarePlanProblem = thisCarePlanProblem;
            }
        }
        if(lastCurrentCarePlanProblem != null) {
            nextUpCarePlanProblem = this.getNextCarePlanProblem(carePlan, lastCurrentCarePlanProblem);
            if(nextUpCarePlanProblem != null) {
                return (lastCurrentCarePlanProblem.HealthCloudGA__SortOrder__c + nextUpCarePlanProblem.HealthCloudGA__SortOrder__c)/2;
            }
            return lastCurrentCarePlanProblem.HealthCloudGA__SortOrder__c + 0.01;
        } else if(lastClosedCarePlanProblem != null) {
            nextUpCarePlanProblem = this.getNextCarePlanProblem(carePlan, lastClosedCarePlanProblem);
            if(nextUpCarePlanProblem != null) {
                return (lastClosedCarePlanProblem.HealthCloudGA__SortOrder__c + nextUpCarePlanProblem.HealthCloudGA__SortOrder__c)/2;
            }
            return lastClosedCarePlanProblem.HealthCloudGA__SortOrder__c + 0.01;
        }
        return 0;
    }

    /**
     * get open careplan problem Order
     * @returns  Decimal
     */
    public Decimal getLastClosedCarePlanProblem(Id carePlanId) {
        Case carePlan = PJN_CarePlanQuery.queryById(carePlanId);
        HealthCloudGA__CarePlanProblem__c lastClosedCarePlanProblem;
        HealthCloudGA__CarePlanProblem__c nextUpCarePlanProblem;
        for(HealthCloudGA__CarePlanProblem__c thisCarePlanProblem : carePlan.HealthCloudGA__CarePlanProblems__r) {
            if(thisCarePlanProblem.PJN_CarePlan_Path_Status__c == 'complete') {
                lastClosedCarePlanProblem = thisCarePlanProblem;
            }
        }
        if(lastClosedCarePlanProblem != null) {
            nextUpCarePlanProblem = this.getNextCarePlanProblem(carePlan, lastClosedCarePlanProblem);
            if(nextUpCarePlanProblem != null) {
                return (lastClosedCarePlanProblem.HealthCloudGA__SortOrder__c + nextUpCarePlanProblem.HealthCloudGA__SortOrder__c)/2;
            }
            return lastClosedCarePlanProblem.HealthCloudGA__SortOrder__c + 0.01;
        }
        return 0;
    }

    /**
     * get last CarePlan Problem Order
     * @returns  Decimal
     */
    public Decimal getLastCarePlanProblem(Id carePlanId) {
        Case carePlan = PJN_CarePlanQuery.queryById(carePlanId);
        HealthCloudGA__CarePlanProblem__c lastCarePlanProblem = carePlan.HealthCloudGA__CarePlanProblems__r.get(carePlan.HealthCloudGA__CarePlanProblems__r.size() - 1);
        return lastCarePlanProblem.HealthCloudGA__SortOrder__c;
    }
}