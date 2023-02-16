/**
 * @author      Mavens
 * @group       Orsini
 * @description Wrapper for the Orsini Patient API Fulfillment Files
 */
public with sharing class MVN_OrsiniPatientFile {

    /**
     * JSON parameters to response for the Fulfillment File
     */
    public String filename;
    public String title;
    public String description;
    public Integer contentsize;
    public String extension;
    public String type;
    public String content;

    /**
     * Constructor to build the Orsini fulfillment file from SFDC Content Version record
     * @param file  Content Version record
     */
    public MVN_OrsiniPatientFile(ContentVersion file) {
        this.filename = file.Title + '.' + file.FileExtension;
        this.title = file.Title;
        this.contentsize = file.ContentSize;
        this.description = file.Description;
        this.extension = file.FileExtension;
        this.type = file.FileType;
        this.content = EncodingUtil.base64Encode(file.VersionData);
    }
}