public with sharing class MVN_RecordFileViewerCtrl {
    private static final String CUSTOM_PERMISSION_API_NAME_TEMPLATE = 'MVN_Files_{0}_Access';
    private static final String CUSTOM_PERMISSION_NO_TYPE_API_NAME = 'MVN_Files_NoType_Access';

    @AuraEnabled
    public static ViewerWrapper getRecordFiles(Id recordId) {
        ViewerWrapper viewerWrapper = new ViewerWrapper();
        Set<String> availableDocTypes = getAvailableDocTypes();
        viewerWrapper.hasUserPermissions = !availableDocTypes.isEmpty();

        if (viewerWrapper.hasUserPermissions) {
            List<ContentDocumentLink> files = getDocumentLinks(recordId);
            Set<Id> fileIds = new Set<Id>();
            for (ContentDocumentLink docLink : files) {
                fileIds.add(docLink.ContentDocumentId);
            }

            viewerWrapper.recordFileWrappers = generateRecordFileWrapper(fileIds, availableDocTypes);
            viewerWrapper.countOfFiles = '(' + viewerWrapper.recordFileWrappers.size() + ')';
        }

        return viewerWrapper;
    }

    private static List<RecordFileWrapper> generateRecordFileWrapper(Set<Id> fileIds, Set<String> availableDocTypes) {
        List<RecordFileWrapper> recordFileWrappers = new List<RecordFileWrapper>();
        for (ContentVersion contentVersion : getContentVersions(fileIds, availableDocTypes)) {
            recordFileWrappers.add(new RecordFileWrapper(contentVersion));
        }

        return recordFileWrappers;
    }

    private static Set<String> getAvailableDocTypes() {
        Map<String, String> customPermissionApiNameByPicklistValue = getCustomPermissionApiNameByPicklistValue();
        Set<String> availableDocTypes = new Set<String>();
        for (String picklistValue : customPermissionApiNameByPicklistValue.keySet()) {
            if (FeatureManagement.checkPermission(customPermissionApiNameByPicklistValue.get(picklistValue))) {
                availableDocTypes.add(picklistValue);
            }
        }

        return availableDocTypes;
    }

    private static Map<String, String> getCustomPermissionApiNameByPicklistValue() {
        List<Schema.PicklistEntry> picklistEntries = ContentVersion.MVN_Document_Type__c.getDescribe().getPicklistValues();
        Map<String, String> customPermissionApiNameByPicklistValue = new Map<String, String>();
        for (Schema.PicklistEntry picklistEntry : picklistEntries) {
            customPermissionApiNameByPicklistValue.put(
                picklistEntry.getValue(),
                String.format(
                    CUSTOM_PERMISSION_API_NAME_TEMPLATE,
                    new List<Object> { picklistEntry.getValue() }
                )
            );
        }

        customPermissionApiNameByPicklistValue.put('', CUSTOM_PERMISSION_NO_TYPE_API_NAME);

        return customPermissionApiNameByPicklistValue;
    }

    private static List<ContentDocumentLink> getDocumentLinks(Id recordId) {
        return [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
    }

    private static List<ContentVersion> getContentVersions(Set<Id> fileIds, Set<String> availableDocTypes) {
        return [
            SELECT ContentDocumentId, FileExtension, Title, ContentSize, ContentModifiedDate, MVN_Document_Type__c
            FROM ContentVersion
            WHERE ContentDocumentId IN :fileIds AND MVN_Document_Type__c = :availableDocTypes AND PublishStatus = 'P'
            ORDER BY ContentModifiedDate DESC NULLS LAST
        ];
    }

    public class ViewerWrapper {
        @AuraEnabled public Boolean hasUserPermissions;
        @AuraEnabled public List<RecordFileWrapper> recordFileWrappers;
        @AuraEnabled public String countOfFiles;
    }

    public class RecordFileWrapper {
        @AuraEnabled public Id contentDocumentId;
        @AuraEnabled public String fileTitle;
        @AuraEnabled public String fileExtension;
        @AuraEnabled public String fileDate;
        @AuraEnabled public String fileSize;
        @AuraEnabled public String fileThumbnail;

        private RecordFileWrapper(ContentVersion contentVersion) {
            this.contentDocumentId = contentVersion.ContentDocumentId;
            this.fileTitle = contentVersion.Title;
            this.fileExtension = contentVersion.FileExtension;
            this.fileDate = contentVersion.ContentModifiedDate.format('MMM d, y');
            this.fileSize = String.valueOf(contentVersion.ContentSize) + ' Bytes';
            this.fileThumbnail = '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=' +
                contentVersion.Id + '&operationContext=CHATTER&contentId=' + contentVersion.ContentDocumentId;
        }
    }
}