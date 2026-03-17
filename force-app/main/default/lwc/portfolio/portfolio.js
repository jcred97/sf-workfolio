import { LightningElement, api } from 'lwc';
import PortfolioAssets from '@salesforce/resourceUrl/PortfolioAssets';

export default class Portfolio extends LightningElement {

    profilePicture = `${PortfolioAssets}/PortfolioAssets/portfolioPicture.jpg`;
    techBackground = `${PortfolioAssets}/PortfolioAssets/techBackground.png`;
    linkedin = `${PortfolioAssets}/PortfolioAssets/Social/linkedin.svg`;
    trailblazer = `${PortfolioAssets}/PortfolioAssets/Social/trailhead2.png`;

    @api recordId;
    @api linkedinUrl;
    @api trailblazerUrl;

    // 🔥 single source of truth
    activeSection = 'home';

    // computed visibility
    get showHome() {
        return this.activeSection === 'home';
    }

    get showExperience() {
        return this.activeSection === 'experience';
    }

    get showContact() {
        return this.activeSection === 'contact';
    }

    // active classes
    get homeClass() {
        return this.activeSection === 'home' ? 'active' : '';
    }

    get experienceClass() {
        return this.activeSection === 'experience' ? 'active' : '';
    }

    get contactClass() {
        return this.activeSection === 'contact' ? 'active' : '';
    }

    // handlers
    handleDisplayHome() {
        this.activeSection = 'home';
    }

    handleDisplayExperience() {
        this.activeSection = 'experience';
    }

    handleDisplayContact() {
        this.activeSection = 'contact';
    }
}