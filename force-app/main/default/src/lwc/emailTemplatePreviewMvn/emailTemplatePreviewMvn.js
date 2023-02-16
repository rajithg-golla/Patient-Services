import { LightningElement, api, wire } from "lwc";
import getTemplateByDevelopername from '@salesforce/apex/EmailTemplatePreviewCtrlMVN.getTemplateByDevelopername';
import TEMPLATE_NOT_FOUND from "@salesforce/label/c.Email_Quick_Send_Template_Not_Found_MVN";

export default class EmailTemplatePreviewMvn extends LightningElement {
    @api templateDeveloperName;

    labels = {
        TEMPLATE_NOT_FOUND
    };
    
    emailTemplate
    templateError = false;

    @wire( getTemplateByDevelopername, {developerName: "$templateDeveloperName"})
    handleEmailTemplate({error, data}) {
        if (error) {
            this.emailTemplate = null;
            this.templateError = true;
            this.dispatchEvent(
                new CustomEvent('templatenotfound')
            );
        }
        if (data) {
            this.emailTemplate = data;
            this.templateError = false;
            this.dispatchEvent(
                new CustomEvent('templatefound')
            );
        }
    }

    get header() {
        if (this.emailTemplate && this.emailTemplate.EnhancedLetterhead
                && this.emailTemplate.EnhancedLetterhead.LetterheadHeader) {
            return this.emailTemplate.EnhancedLetterhead.LetterheadHeader;
        }
        return "";
    }

    get body() {
        if (this.emailTemplate && this.emailTemplate.HtmlValue) {
            return this.emailTemplate.HtmlValue;
        }
        return "";
    }

    get footer() {
        if (this.emailTemplate && this.emailTemplate.EnhancedLetterhead
                && this.emailTemplate.EnhancedLetterhead.LetterheadFooter) {
            return this.emailTemplate.EnhancedLetterhead.LetterheadFooter;
        }
        return "";
    }
}