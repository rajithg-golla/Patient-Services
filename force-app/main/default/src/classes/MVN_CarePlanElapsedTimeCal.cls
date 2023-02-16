/**
* @author Mavens
* @description Trigger handler for Activites and Program Problems to create events
* @group Events
*/
public without sharing class MVN_CarePlanElapsedTimeCal implements PJN_TriggerDispatcher.HandlerInterface {

    public void handle() {
        BusinessHours dedsiBH = [SELECT Id, Name FROM BusinessHours WHERE name = 'DEDSI BusinessHours'];
        BusinessHours mvnevkBH = [SELECT Id, Name FROM BusinessHours WHERE name = 'Evkeeza Business Hours'];
        BusinessHours mvnlcmBH = [SELECT Id, Name FROM BusinessHours WHERE name = 'Libtayo Consumer Marketing Business Hours'];
        BusinessHours mvnlbtBH = [SELECT Id, Name FROM BusinessHours WHERE name = 'Libtayo Surround Business Hours'];

        Id carePlanRecTypeId = SObjectType.Case
        .getRecordTypeInfosByDeveloperName()
        .get('CarePlan')
        .getRecordTypeId();

        //DEDSI       = DEDSI BusinessHours
        //MVN_EVK     = Evkeeza Business Hours
        //MVN_LCM = Libtayo Consumer Marketing Business Hours	
        //MVN_LBT  = Libtayo Surround Business Hours

       
        for (Case newCase : (List<Case>) Trigger.new) {
            if(newCase.PJN_Program_DeveloperName__c == 'DEDSI' && dedsiBH != null && newCase.Status == 'Closed'){
                newCase.MVN_Elapsed_Time__c = getElapsedTime(newCase, dedsiBH);
            }
            else if(newCase.PJN_Program_DeveloperName__c == 'MVN_EVK' && mvnevkBH != null && newCase.Status == 'Closed'){
                newCase.MVN_Elapsed_Time__c = getElapsedTime(newCase, mvnevkBH);
            }
            else if(newCase.PJN_Program_DeveloperName__c == 'MVN_LCM' && mvnlcmBH != null && newCase.Status == 'Closed'){
                newCase.MVN_Elapsed_Time__c = getElapsedTime(newCase, mvnlcmBH);
            }
            else if(newCase.PJN_Program_DeveloperName__c == 'MVN_LBT' && mvnlbtBH != null && newCase.Status == 'Closed'){
                newCase.MVN_Elapsed_Time__c = getElapsedTime(newCase, mvnlbtBH);
            }
        }
    }

    private static decimal getElapsedTime( Case newCase, BusinessHours defaultBH){
        decimal result = 0.0;
        if(newCase.ClosedDate == null){
            result = BusinessHours.diff(defaultBH.Id, newCase.CreatedDate, System.Datetime.Now());
        }else{
            result = BusinessHours.diff(defaultBH.Id, newCase.CreatedDate, newCase.ClosedDate);
        }
        return  (result/(60*60*1000));
    }

    /*
    private static Integer calculateWorkingDaysBetweenTwoDates(Date date1,Date date2){
        List<Holiday> holidays=[Select h.StartTimeInMinutes, h.Name, h.ActivityDate From Holiday h];

        Integer allDaysBetween = date1.daysBetween(date2);
        Integer allWorkingDays=0;
        for(Integer k=0;k<allDaysBetween ;k++ ){
            if(checkifItisWorkingDay(date1.addDays(k),holidays)){
                allWorkingDays++;
            }
        }

        return allWorkingDays;
    }

    private static boolean checkifItisWorkingDay(Date currentDate,List<Holiday> holidays){
        Date weekStart  = currentDate.toStartofWeek();
        for(Holiday hDay:holidays){
                if(currentDate.daysBetween(hDay.ActivityDate) == 0){
                        return false;
                }
        }
        if(weekStart.daysBetween(currentDate) ==0 || weekStart.daysBetween(currentDate) == 6){
                return false;
        } else
                return true;
    }
    */
}