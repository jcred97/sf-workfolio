import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import FULLNAME from '@salesforce/schema/Portfolio__c.FullName__c';
import DESIGNATION from '@salesforce/schema/Portfolio__c.Designation__c';
import CAREER_START_DATE from '@salesforce/schema/Portfolio__c.Career_Start_Date__c';
import INTRODUCTION from '@salesforce/schema/Portfolio__c.Introduction__c';
import SUB_INTRODUCTION from '@salesforce/schema/Portfolio__c.Sub_Introduction__c';

export default class PortfolioHome extends LightningElement {
    @api recordId;
    @api linkedin;
    @api linkedinUrl;
    @api trailblazer;
    @api trailblazerUrl;
    @api techBackground;

    @wire(getRecord, {
        recordId: '$recordId', 
        fields:[FULLNAME, 
            DESIGNATION, 
            CAREER_START_DATE, 
            INTRODUCTION,
            SUB_INTRODUCTION]})portfolioData
    

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