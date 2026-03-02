import { LightningElement, wire, api } from 'lwc';
import { getRecord  } from 'lightning/uiRecordApi';
import TECH_FIELD from '@salesforce/schema/Portfolio__c.TechnicalSkills__c';
import SOFT_SKILLS_FIELD from '@salesforce/schema/Portfolio__c.SoftSkills__c';
import SOFTWARE_FIELD from '@salesforce/schema/Portfolio__c.SoftwareTools__c';
import METHODOLOGIES_FIELD from '@salesforce/schema/Portfolio__c.Methodologies__c';

export default class PortfolioSkills extends LightningElement {
    @api recordId;

    techSkills = [];
    softSkills = [];
    methodologies = [];
    toolSkills = [];

    @wire(getRecord, {
        recordId: '$recordId',
        fields:[TECH_FIELD, SOFT_SKILLS_FIELD, SOFTWARE_FIELD, METHODOLOGIES_FIELD]
    })skillHandler({data, error}) {
        if (data) {
            console.log("Skills Data", JSON.stringify(data));
        }

        if (error) {
            console.error("Skills Error", error);
        }
    }

    formatSkills(data) {
        const {SoftSkills__c, TechnicalSkills__c, SoftwareTools__c, Methodologies__c} = data.fields;
        this.techSkills = TechnicalSkills__c ? TechnicalSkills__c.value.split(',') : [];
        this.softSkills = SoftSkills__c ? SoftSkills__c.value.split(',') : [];
        this.methodologies = Methodologies__c ? Methodologies__c.value.split(',') : [];
        this.toolSkills = SoftwareTools__c ? SoftwareTools__c.value.split(',') : [];
    }
}