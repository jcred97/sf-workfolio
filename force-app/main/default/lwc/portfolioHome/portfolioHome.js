import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import FULLNAME from '@salesforce/schema/Portfolio__c.FullName__c';
import DESIGNATION from '@salesforce/schema/Portfolio__c.Designation__c';
import CAREER_START_DATE from '@salesforce/schema/Portfolio__c.Career_Start_Date__c';
import INTRODUCTION from '@salesforce/schema/Portfolio__c.Introduction__c';
import SUB_INTRODUCTION from '@salesforce/schema/Portfolio__c.Sub_Introduction__c';
import LINKEDIN_URL from '@salesforce/schema/Portfolio__c.LinkedIn_URL__c';
import GITHUB_URL from '@salesforce/schema/Portfolio__c.Github_URL__c';
import TRAILBLAZER_URL from '@salesforce/schema/Portfolio__c.Trailblazer_URL__c';

export default class PortfolioHome extends LightningElement {
    @api recordId;
    @api linkedin;
    @api trailblazer;
    @api github;
    @api profilePicture;
    @api certifications = [];

    @wire(getRecord, {
        recordId: '$recordId', 
        fields:[FULLNAME, 
            DESIGNATION, 
            CAREER_START_DATE, 
            INTRODUCTION,
            SUB_INTRODUCTION,
            LINKEDIN_URL,
            GITHUB_URL,
            TRAILBLAZER_URL
        ]})portfolioData
    
    renderedCallback() {
        if (this.fullName && this._lastSentName !== this.fullName) {
            this._lastSentName = this.fullName;

            this.dispatchEvent(new CustomEvent('namechange', {
                detail: this.fullName
            }));
        }
    }

    get fullName(){
        return getFieldValue(this.portfolioData.data, FULLNAME);
    }

    get designation(){
        return getFieldValue(this.portfolioData.data, DESIGNATION);
    }

    get introduction(){
        return getFieldValue(this.portfolioData.data, INTRODUCTION);
    }

    get subIntroduction(){
        return getFieldValue(this.portfolioData.data, SUB_INTRODUCTION);
    }

    get linkedinUrl(){
        return getFieldValue(this.portfolioData.data, LINKEDIN_URL);
    }

    get githubUrl(){
        return getFieldValue(this.portfolioData.data, GITHUB_URL);
    }

    get trailblazerUrl(){
        return getFieldValue(this.portfolioData.data, TRAILBLAZER_URL);
    }

    get experienceSummary() {
        const startDate = getFieldValue(this.portfolioData.data, CAREER_START_DATE);
        if (!startDate) return '';

        const start = new Date(startDate);
        const today = new Date();

        let years = today.getFullYear() - start.getFullYear();
        const monthDiff = today.getMonth() - start.getMonth();

        // Adjust if current month is before start month
        if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < start.getDate())) {
            years--;
        }

        return `${years}`;
    }
}