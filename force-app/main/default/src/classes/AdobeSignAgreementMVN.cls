public with sharing class AdobeSignAgreementMVN {
    
    public List<FileInfo> fileInfos;
    public String name;
    public List<ParticipantSetInfo> participantSetsInfo;
    public String signatureType;
    public String state;
    public List<CcInfo> ccs;
    public String createdDate;
    public OfflineDeviceInfo deviceInfo;
    public Boolean documentVisibilityEnabled;
    public EmailOption emailOption;
    public String expirationTime;
    public ExternalId externalId;
    public Integer firstReminderDelay;
    public List<FileInfo> formFieldLayerTemplates;
    public String groupId;
    public Boolean hasFormFieldData;
    public Boolean hasSignerIdentityReport;
    public String id;
    public Boolean isDocumentRetentionApplied;
    public Date lastEventDate;
    public String locale;
    public List<MergeFieldInfo> mergeFieldInfo;
    public String message;
    public String parentId;
    public PostSignOption postSignOption;
    public String reminderFrequency;
    public SecurityOption securityOption;
    public String senderEmail;
    public String status;
    public String type;
    public VaultingInfo vaultingInfo;
    public String workflowId;

    public AdobeSignAgreementMVN(String name, String sigType, String state, String externalId) {
        this.name = name;
        this.signatureType = sigType;
        this.state = state;
        this.externalId = new ExternalId(externalId);
    }
    
    public AdobeSignAgreementMVN addSigners(List<String> emails) {
        if (this.participantSetsInfo == null) {
            this.participantSetsInfo = new List<ParticipantSetInfo>();
        }
        this.participantSetsInfo.add(
            new ParticipantSetInfo(emails, 1, 'SIGNER')
        );
        return this;
    }

    public AdobeSignAgreementMVN addPostSignOption(String redirectUrl, Decimal delay) {
        if (redirectUrl != null) {
            this.postSignOption = new PostSignOption(redirectUrl, delay);
        } else {
            this.postSignOption = null;
        }
        return this;
    }

    public void addLibraryFileInfo(String documentId) {
        if (this.fileInfos == null) {
            this.fileInfos = new List<FileInfo>();
        }
        FileInfo libraryFileInfo = new FileInfo();
        libraryFileInfo.libraryDocumentId = documentId;
        this.fileInfos.add(libraryFileInfo);
    }

    public AdobeSignAgreementMVN addEmailOption(String completionEmails, String inFlightEmails, String initEmails) {
        this.emailOption = new EmailOption(completionEmails, inFlightEmails, initEmails);
        return this;
    }

    public AdobeSignAgreementMVN addMergeField(String fieldName, Object defaultValue) {
        if (this.mergeFieldInfo == null) {
            this.mergeFieldInfo = new List<MergeFieldInfo>();
        }
        this.mergeFieldInfo.add(new MergeFieldInfo(fieldName, defaultValue));
        return this;
    }

    public class FileInfo {
        public Document document;
        public String label;
        public String libraryDocumentId;
        public String transientDocumentId;
        public URLFileInfo urlfileInfo;
    }

    public class Document {
        public Date createdDate;
        public String id;
        public String label;
        public Integer numPages;
        public String mimeType;
        public String name;
    }

    public class URLFileInfo {
        String mimeType;
        String name;
    }

    public class ParticipantSetInfo {
        public List<ParticipantInfo> memberInfos;
        public Integer order;
        public String role;
        public String id;
        public String label;
        public String name;
        public String privateMessage;
        public List<String> visiblePages;

        public ParticipantSetInfo(List<String> emails, Integer order, String role) {
            this.memberInfos = new List<ParticipantInfo>();
            for (String email : emails) {
                this.memberInfos.add(
                    new ParticipantInfo(
                        email
                    )
                );
            }
            this.order = order;
            this.role = role;
        }
    }

    public class ParticipantInfo {
        public String email;
        public String id;

        public ParticipantInfo(String email) {
            this.email = email;
        }
    }

    public class ParticipantSecurityOption {
        public String authenticationMethod;
        public String password;
    }

    public class PhoneInfo {
        public String countryCode;
        public String countryIsoCode;
        public String phone;
    }

    public class CcInfo {
        public String email;
        public String label;
        public List<String> visiblePages;
    }

    public class OfflineDeviceInfo {
        public String applicationDescription;
        public String deviceDescription;
        public String deviceTime;
    }

    public class EmailOption {
        public SendOptions sendOptions;

        public EmailOption(String completionEmails, String inFlightEmails, String initEmails) {
            this.sendOptions = new SendOptions(completionEmails, inFlightEmails, initEmails);
        }
    }

    public class SendOptions {
        public String completionEmails;
        public String inFlightEmails;
        public String initEmails;

        public SendOptions(String completionEmails, String inFlightEmails, String initEmails) {
            this.completionEmails = completionEmails;
            this.inFlightEmails = inFlightEmails;
            this.initEmails = initEmails;
        }
    }

    public class ExternalId {
        public String id;

        public ExternalId(String id) {
            this.id = id;
        }
    }

    public class MergeFieldInfo {
        public Object defaultValue;
        public String fieldName;

        public MergeFieldInfo(String fieldName, Object defaultValue) {
            this.fieldName = fieldName.remove('"');
            this.defaultValue = defaultValue;
        }
    }

    public class PostSignOption {
        public String redirectUrl;
        public Decimal redirectDelay;
        
        public PostSignOption(String redirectUrl, Decimal delay) {
            this.redirectUrl = redirectUrl;
            this.redirectDelay = delay;
        }
    }

    public class SecurityOption {
        public String openPassword;
    }

    public class VaultingInfo {
        public Boolean enabled;
    }
}