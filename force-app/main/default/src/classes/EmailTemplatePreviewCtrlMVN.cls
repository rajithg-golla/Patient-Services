public with sharing class EmailTemplatePreviewCtrlMVN {
    
    @AuraEnabled(cacheable=true)
    public static EmailTemplate getTemplateByDevelopername(String developerName){
        return [
            SELECT
                EnhancedLetterHead.LetterheadHeader,
                HtmlValue,
                EnhancedLetterHead.LetterheadFooter
            FROM
                EmailTemplate
            WHERE
                DeveloperName = :developerName
            LIMIT 1
        ];
    }
}