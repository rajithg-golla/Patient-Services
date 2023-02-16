/**
 * @author      Mavens
 * @group       Program
 * @description Program Queries
 */
public with sharing class PJN_ProgramQuery {
    /**
     * fields to query
     */
    public static Set<String> fields = new Set<String>{
        'Id',
        'Label',
        'MasterLabel',
        'DeveloperName'
    };

    /**
     * query for all programs*
     * @returns  List<PJN_Program__mdt>
     */
    public List<PJN_Program__mdt> getAllPrograms() {
        return Database.query(
            'SELECT ' + String.join(new List<String>(fields), ', ') + ' ' +
            'FROM PJN_Program__mdt ' +
            'ORDER BY MasterLabel'
        );
    }

    /**
     * query Program by Developer Name
     * @param   String      programDeveloperName
     * @returns  PJN_Program__mdt
     */
    public PJN_Program__mdt queryByDeveloperName(String programDeveloperName) {
        return Database.query(
            'SELECT ' +
                String.join(new List<String>(fields), ', ') + ', ' +
                '( ' +
                    'SELECT ' +
                        String.join(new List<String>((new PJN_ProgramProblemQuery()).fields), ', ') + ' ' +
                    'FROM ' +
                        'PJN_Program_Problems__r ' +
                    'WHERE ' +
                        'PJN_Is_Standard__c = true ' +
                ') '+
            'FROM ' +
                'PJN_Program__mdt ' +
            'WHERE ' +
                'DeveloperName = :programDeveloperName'
        );
    }
}