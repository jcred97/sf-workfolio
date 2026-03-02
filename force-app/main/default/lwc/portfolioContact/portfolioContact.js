import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import sendDataAndEmail from '@salesforce/apex/PortfolioController.sendDataAndEmail';

import EMAIL from '@salesforce/schema/Portfolio__c.Email__c';

export default class PortfolioContact extends LightningElement {
    @api recordId;
    @api linkedin;
    @api linkedinUrl;
    @api trailblazer;
    @api trailblazerUrl;

    @track firstName = '';
    @track lastName = '';
    @track emailAddress = '';
    @track subject = '';
    @track message = '';

    @wire(getRecord, {
        recordId: '$recordId', 
        fields:[EMAIL]})portfolioData

    get email(){
        return getFieldValue(this.portfolioData.data, EMAIL);
    }

    inputHandler(event){
        const {name, value} = event.target;

        if(name === 'firstName'){
            this.firstName = value;
        }

        if(name === 'lastName'){
            this.lastName = value;
        }

        if(name === 'emailAddress'){
            this.emailAddress = value;
        }

        if(name === 'subject'){
            this.subject = value;
        }

        if(name === 'message'){
            this.message = value;
        }
    }

    sendDataAndEmail() {
        sendDataAndEmail({ 
            inputFirstName: this.firstName,
            inputLastName: this.lastName,
            inputEmail: this.emailAddress,
            inputSubject: this.subject, 
            inputMessage: this.message 
        })
        .then(result => {
            console.log('Data sent and email sent successfully:', result);
        })
        .catch(error => {
            console.error('Error sending data and email:', error);
            this.showToast();
        });
    }
}