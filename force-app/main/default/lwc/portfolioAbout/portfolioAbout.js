import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import ABOUT from '@salesforce/schema/Portfolio__c.About__c';

export default class PortfolioAbout extends LightningElement {
    @api recordId;
    @api profilePicture;

    @wire(getRecord, {
        recordId: '$recordId', 
        fields:[ABOUT]})portfolioData

    get about(){
        return getFieldValue(this.portfolioData.data, ABOUT);
    }
}