public with sharing class PJN_CaseFilesPreviewLightningUtil {
    @AuraEnabled
    public static List<FileOption> getFileOptions(Id caseId) {

        Set<Id> documentIds = new Set<Id>();

        List<ContentDocumentLink> cdls = [
            SELECT
                ContentDocumentId
            FROM
                ContentDocumentLink
            WHERE
                LinkedEntityId = :caseId
            AND
                ContentDocument.FileType != 'SNOTE'
        ];
        for (ContentDocumentLink cdl : cdls) {
            documentIds.add(cdl.ContentDocumentId);
        }

        List<ContentVersion> cvs = [
            SELECT
                Id,
                Title,
                FileExtension
            FROM
                ContentVersion
            WHERE
                ContentDocumentId IN :documentIds
            AND
                IsLatest = true
        ];

        List<FileOption> fileOptions = new List<FileOption>();
        for (ContentVersion cv : cvs) {
            fileOptions.add(
                new FileOption(cv)
            );
        }

        if (fileOptions.size() > 1) {
            fileOptions.add(
                0,
                new FileOption(new ContentVersion(Id=null, Title='Select a File'))
            );
        }
        return fileOptions;
    }

    public class FileOption {
        @AuraEnabled public String documentId;
        @AuraEnabled public String fileName;

        public FileOption(ContentVersion cv) {
            this.documentId = cv.Id;
            if (this.documentId == null) {
                this.documentId = '';
            }

            this.fileName = cv.Title;
            if (cv.FileExtension != null) {
                this.fileName += '.' + cv.FileExtension;
            }
        }
    }
}