import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import FULLNAME from '@salesforce/schema/Portfolio__c.FullName__c';
import DESIGNATION from '@salesforce/schema/Portfolio__c.Designation__c';
import NICKNAME from '@salesforce/schema/Portfolio__c.Nickname__c';
import INTRODUCTION from '@salesforce/schema/Portfolio__c.Introduction__c';

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
            NICKNAME, 
            INTRODUCTION]})portfolioData
    

    get fullName(){
        return getFieldValue(this.portfolioData.data, FULLNAME);
    }

    get nickname(){
        return getFieldValue(this.portfolioData.data, NICKNAME);
    }

    get designation(){
        return getFieldValue(this.portfolioData.data, DESIGNATION);
    }

    get introduction(){
        return getFieldValue(this.portfolioData.data, INTRODUCTION);
    }
}