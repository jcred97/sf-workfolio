import { LightningElement, wire, api } from 'lwc';

import PortfolioAssets from '@salesforce/resourceUrl/PortfolioAssets';

export default class Portfolio extends LightningElement {
    profilePicture = `${PortfolioAssets}/PortfolioAssets/portfolioPicture.jpg`;
    techBackground = `${PortfolioAssets}/PortfolioAssets/techBackground.png`;
    linkedin = `${PortfolioAssets}/PortfolioAssets/Social/linkedin.svg`;
    trailblazer = `${PortfolioAssets}/PortfolioAssets/Social/trailhead2.png`;

    showHome = true;
    showAbout = false;
    showSkills = false;
    showExperience = false;
    projects = false;
    showContact = false;

    @api recordId; //a005g00003NV3ktAAD
    @api linkedinUrl; //https://www.linkedin.com/in/jcdred/
    @api trailblazerUrl; //https://www.salesforce.com/trailblazer/u4v1u2g1fp3ifg4eh4

    handleDisplayHome(){
        this.showHome = true;
        this.showAbout = false;
        this.showSkills = false;
        this.showExperience = false;
        this.projects = false;
        this.showContact = false;
    }

    handleDisplayAbout(){
        this.showHome = false;
        this.showAbout = true;
        this.showSkills = false;
        this.showExperience = false;
        this.projects = false;
        this.showContact = false;
    }

    handleDisplaySkills(){
        this.showHome = false;
        this.showAbout = false;
        this.showSkills = true;
        this.showExperience = false;
        this.projects = false;
        this.showContact = false;
    }

    handleDisplayExperience(){
        this.showHome = false;
        this.showAbout = false;
        this.showSkills = false;
        this.showExperience = true;
        this.projects = false;
        this.showContact = false;
    }

    handleDisplayProjects(){
        this.showHome = false;
        this.showAbout = false;
        this.showExperience = false;
        this.projects = true;
        this.showContact = false;
    }

    handleDisplayContact(){
        this.showHome = false;
        this.showAbout = false;
        this.showExperience = false;
        this.projects = false;
        this.showContact = true;
    }
}