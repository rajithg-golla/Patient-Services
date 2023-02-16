public with sharing class PJN_DataTable {
    @auraEnabled 
    public List<Object> data { get; set; }
    @auraEnabled 
    public List<PJN_FieldWrapper> columns { get; set; }
}