import { LightningElement, api } from 'lwc';
import PortfolioAssets from '@salesforce/resourceUrl/PortfolioAssets';

export default class Portfolio extends LightningElement {

    profilePicture = `${PortfolioAssets}/PortfolioAssets/portfolioPicture.jpg`;
    linkedin = `${PortfolioAssets}/PortfolioAssets/Social/linkedin.svg`;
    trailblazer = `${PortfolioAssets}/PortfolioAssets/Social/trailhead2.png`;

    certifications = [
        {
            name: 'Platform Developer 1',
            image: `${PortfolioAssets}/PortfolioAssets/CertificateLogo/platformdeveloper1.png`
        },
        {
            name: 'Platform App Builder',
            image: `${PortfolioAssets}/PortfolioAssets/CertificateLogo/platformappbuilder.png`
        },
        {
            name: 'Platform Administrator',
            image: `${PortfolioAssets}/PortfolioAssets/CertificateLogo/platformadministrator.png`
        },
        {
            name: 'Agentforce Specialist',
            image: `${PortfolioAssets}/PortfolioAssets/CertificateLogo/agentforcespecialist.png`
        },
        {
            name: 'Platform Foundations',
            image: `${PortfolioAssets}/PortfolioAssets/CertificateLogo/platformfoundations.png`
        }
    ];

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
}