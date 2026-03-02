import { LightningElement, api, wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class PortfolioExperience extends LightningElement {
    @api recordId;
    workExperienceList;

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'WorkExperience__r',
        sortBy: ['-WorkExperience__c.JobStartDate__c'],
        fields:['WorkExperience__c.JobStartDate__c',
            'WorkExperience__c.JobEndDate__c',
            'WorkExperience__c.Role__c',
            'WorkExperience__c.CompanyName__c',
            'WorkExperience__c.WorkLocation__c',
            'WorkExperience__c.Description__c',
            'WorkExperience__c.IsCurrent__c',
            'WorkExperience__c.CompanyLogo__c',
        ]
    })WorkExperienceHandler({data, error}){
        if (data) {
            console.log("WorkExperience Data", data);
            this.formatExperience(data);
            console.log('Success Response: '+JSON.stringify(data));
        }
        if (error) {
            console.log('Error Response: '+JSON.stringify(error));
        }
    }

    formatExperience(data){
        this.workExperienceList = data.records.map(item => {
            let id = item.id;
            const {JobStartDate__c, JobEndDate__c, Role__c, CompanyName__c, WorkLocation__c, Description__c, IsCurrent__c, CompanyLogo__c} = item.fields;
            let JobStartDate = this.getValue(JobStartDate__c);
            let JobEndDate = this.getValue(JobEndDate__c);
            let Role = this.getValue(Role__c);
            let CompanyName = this.getValue(CompanyName__c);
            let WorkLocation = this.getValue(WorkLocation__c);
            let Description = this.getValue(Description__c);
            let IsCurrent = this.getValue(IsCurrent__c);
            let CompanyLogo = this.getValue(CompanyLogo__c);

            return {id, JobStartDate, JobEndDate, Role, CompanyName, WorkLocation, Description, IsCurrent, CompanyLogo}
        })
        //console.log("workExperienceList", JSON.stringify(this.workExperienceList));
    }

    getValue(data){
        return data && (data.displayValue || data.value);
    }
}