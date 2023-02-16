/*
 * Utility class to work on business days converted from Business hours
 * Taken from https://www.forcetalks.com/salesforce-topic/what-is-businesshours-class-in-salesforce-apex-and-how-we-can-use-them/
 */
public class BusinessDaysMVN {

    private List<Boolean> businessDay = new Boolean[7];
    private List<Time> startHours = new Time [7];
    private List<Time> endHours = new Time [7];
    private Date knownSunday = date.newInstance(2013, 1, 6);
   
    // Constructor creates businessDay array
    public BusinessDaysMVN() {
   
        BusinessHours bh = [
            SELECT
                SundayStartTime, SundayEndTime,
                MondayStartTime, MondayEndTime,
                TuesdayStartTime, TuesdayEndTime,
                WednesdayStartTime, WednesdayEndTime,
                ThursdayStartTime, ThursdayEndTime,
                FridayStartTime, FridayEndTime,
                SaturdayStartTime, SaturdayEndTime
            FROM 
                BusinessHours 
            WHERE 
                IsDefault=true
        ];
    
        businessDay[0] = (bh.SundayStartTime != null);
        businessDay[1] = (bh.MondayStartTime != null);
        businessDay[2] = (bh.TuesdayStartTime != null);
        businessDay[3] = (bh.WednesdayStartTime != null);
        businessDay[4] = (bh.ThursdayStartTime != null);
        businessDay[5] = (bh.FridayStartTime != null);
        businessDay[6] = (bh.SaturdayStartTime != null);
        
        startHours[0] = bh.SundayStartTime;
        startHours[1] = bh.MondayStartTime;
        startHours[2] = bh.TuesdayStartTime;
        startHours[3] = bh.WednesdayStartTime;
        startHours[4] = bh.ThursdayStartTime;
        startHours[5] = bh.FridayStartTime;
        startHours[6] = bh.SaturdayStartTime;
    
        endHours[0] = bh.SundayEndTime;
        endHours[1] = bh.MondayEndTime;
        endHours[2] = bh.TuesdayEndTime;
        endHours[3] = bh.WednesdayEndTime;
        endHours[4] = bh.ThursdayEndTime;
        endHours[5] = bh.FridayEndTime;
        endHours[6] = bh.SaturdayEndTime;
   
    }
   
    // Check if today is a business day
    public Boolean isBusinessDay(Date inputDate) {
        // index i is index into the businessDay array based on inputDate
        Integer i = Math.mod(Math.abs(this.knownSunday.daysBetween(inputDate)),7);
        return (businessDay[i]);
    }
    
    // Get the start time
    public Time getStartTime(Date inputDate) {
        Integer i = Math.mod(Math.abs(this.knownSunday.daysBetween(inputDate)),7);
        return (startHours[i]);
    }
   
    // Gets next business day, skipping non business days
    public Date nextBusinessDay(Datetime inputDatetime) {
        Integer i = Math.mod(Math.abs(this.knownSunday.daysBetween(inputDatetime.dateGMT())),7);
        DateTime returnDate = inputDatetime;
        while (!businessDay[Math.mod(i, 7)]) {
            i++;
            returnDate = returnDate.addDays(1);
        }
        return returnDate.dateGMT();
    }
   
}