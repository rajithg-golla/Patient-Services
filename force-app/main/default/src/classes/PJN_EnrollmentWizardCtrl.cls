/**
 * @author Mavens
 * @date Jan 2019
 * @description Creates the care plan case and retrieves the steps linked to a given program for
 * the enrollment wizard.
 * @group EnrollmentWizard
 */
public without sharing class PJN_EnrollmentWizardCtrl {

    @TestVisible
    private static PJN_EnrollmentWizardSettingQuery enrollmentSettingQuery = new PJN_EnrollmentWizardSettingQuery();
    @TestVisible
    private static PJN_EnrollmentWizardStepQuery enrollmentStepQuery = new PJN_EnrollmentWizardStepQuery();
    @TestVisible
    private static PJN_EnrollmentWizardComponentQuery enrollmentComponentQuery = new PJN_EnrollmentWizardComponentQuery();

    /**
     * Create Care Plan copying over fields coming from the enrollment case and update the enrollment
     * case setting the program dev name and pointing the parentId to the new care plan.
     * @param  programDeveloperName Program Developer Name
     * @param  patientId            patient id
     * @param  sourceCaseId         enrollment case id
     * @return Id                   care plan id
     */
    @auraEnabled
    public static Id createCarePlan(String programDeveloperName, Id patientId, Id sourceCaseId) {
        Savepoint sp = Database.setSavepoint();
        try {
            if (enrollmentSettingQuery.getAllSettingsByProgram().containsKey(programDeveloperName)) {
                Case sourceCase = new Case();
                if (sourceCaseId != null) {
                    sourceCase = getSourceCase(sourceCaseId);
                }
                Case carePlan = createAndInsertCarePlan(programDeveloperName, sourceCase, patientId);
                updateSourceCase(sourceCase, carePlan.Id, programDeveloperName);
                return carePlan.Id;
            } else {
                throw new PJN_EnrollmentWizardException('No enrollment settings found for program ' + programDeveloperName);
            }
        } catch (Exception exc) {
            Database.rollback(sp);
            AuraHandledException auraException = new AuraHandledException(exc.getMessage());
            auraException.setMessage(exc.getMessage());
            throw auraException;
        }
    }

    /**
     * getEnrollmentWizardSteps Retrieve Enrollment Wizard Steps defined for a specific program
     * @param  programDeveloperName                     program developer name
     * @return List<PJN_Enrollment_Wizard_Step__mdt>    list of enrollment wizard steps
     */
    @auraEnabled
    public static List<PJN_Enrollment_Wizard_Step__mdt> getEnrollmentWizardSteps(String programDeveloperName) {
        try {
            return enrollmentStepQuery.getEnrollmentStepsByProgram(programDeveloperName);
        } catch (Exception exc) {
            String msg = 'No enrollment settings found. Please contact your administrator';
            AuraHandledException auraException = new AuraHandledException(msg);
            auraException.setMessage(msg);
            throw auraException;
        }
    }

    /**
     * getEnrollmentWizardComponents Retrieve Enrollment Wizard Components for a specific step Id
     * @param  stepId                                        Enrollment Wizard Step Id
     * @return List<PJN_Enrollment_Wizard_Component__mdt>    list of enrollment wizard steps
     */
    @auraEnabled
    public static List<PJN_Enrollment_Wizard_Component__mdt> getEnrollmentWizardComponents(Id stepId) {
        try {
            return enrollmentComponentQuery.getEnrollmentComponentsByStep(stepId);
        } catch (Exception exc) {
            String msg = 'No enrollment settings found. Please contact your administrator';
            AuraHandledException auraException = new AuraHandledException(msg);
            auraException.setMessage(msg);
            throw auraException;
        }
    }

    /**
     * Add Initial Enrollment Complete Date to the care plan created
     * @param carePlanId    Care Plan id
     */
    @auraEnabled
    public static void addInitialEnrollmentCompleteDate(Id carePlanId) {
        Savepoint sp = Database.setSavepoint();
        try {
            update new Case(
                Id = carePlanId,
                PJN_Enrollment_Completed__c = true
            );
        } catch (Exception exc) {
            Database.rollback(sp);
            AuraHandledException auraException = new AuraHandledException(exc.getMessage());
            auraException.setMessage(exc.getMessage());
            throw auraException;
        }
    }

    /**
     * query source case
     * @param  sourceCaseId source case id
     * @return Case
     */
    private static Case getSourceCase(Id sourceCaseId) {
        return [
            SELECT
                Id,
                PJN_Physician__c,
                PJN_Staff__c,
                PJN_Caregiver__c,
                MVN_Consumer__c,
                MVN_Treatment_Site__c,
                MVN_Organization__c,
                PJN_Enrollment_Address__c,
                RecordTypeId
            FROM
                Case
            WHERE
                Id = :sourceCaseId
        ];
    }

    /**
     * create and insert care plan
     * @param  programDevName program developer name
     * @param  sourceCase     source case
     * @param  patientId      patient id
     * @return Case
     */
    private static Case createAndInsertCarePlan(String programDevName, Case sourceCase, Id patientId) {
        Case carePlan = (Case) SobjectType.Case.getSobjectType().newSObject(
            Schema.SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId(),
            true
        );
        carePlan.PJN_Program_DeveloperName__c = programDevName;
        carePlan.AccountId = patientId;
        carePlan.PJN_Physician__c = sourceCase.PJN_Physician__c;
        carePlan.PJN_Staff__c = sourceCase.PJN_Staff__c;
        carePlan.PJN_Caregiver__c = sourceCase.PJN_Caregiver__c;
        carePlan.MVN_Consumer__c = sourceCase.MVN_Consumer__c;
        carePlan.MVN_Treatment_Site__c = sourceCase.MVN_Treatment_Site__c;
        carePlan.MVN_Organization__c = sourceCase.MVN_Organization__c;
        carePlan.PJN_Enrollment_Address__c = sourceCase.PJN_Enrollment_Address__c;
        carePlan.PJN_Enrollment_Activity__c = sourceCase.Id;
        carePlan.PJN_Care_Plan_Start_Status__c = 'PJN_Initiate';

        insert carePlan;
        return carePlan;
    }

    /**
     * update source case
     * @param  sourceCase     source case
     * @param  carePlanId     care plan id
     * @param  programDevName program developer name
     */
    private static void updateSourceCase(Case sourceCase, Id carePlanId, String programDevName) {
        sourceCase.ParentId = carePlanId;
        sourceCase.PJN_Program_DeveloperName__c = programDevName;
        update sourceCase;
    }
}