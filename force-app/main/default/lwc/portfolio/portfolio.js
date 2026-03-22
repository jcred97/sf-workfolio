import { LightningElement, api } from 'lwc';
import PortfolioAssets from '@salesforce/resourceUrl/PortfolioAssets';

const BASE_PATH = `${PortfolioAssets}/PortfolioAssets`;

const SECTION = {
    HOME: 'home',
    EXPERIENCE: 'experience',
    SKILLS: 'skills'
};

export default class Portfolio extends LightningElement {

    profilePicture = `${BASE_PATH}/portfolioPicture.jpg`;
    social = {
        linkedin: `${BASE_PATH}/Social/linkedin.svg`,
        trailblazer: `${BASE_PATH}/Social/trailhead2.png`
    };

    certifications = [
        { name: 'Platform Developer 1', image: `${BASE_PATH}/CertificateLogo/platformdeveloper1.png` },
        { name: 'Platform App Builder', image: `${BASE_PATH}/CertificateLogo/platformappbuilder.png` },
        { name: 'Platform Administrator', image: `${BASE_PATH}/CertificateLogo/platformadministrator.png` },
        { name: 'Agentforce Specialist', image: `${BASE_PATH}/CertificateLogo/agentforcespecialist.png` },
        { name: 'Platform Foundations', image: `${BASE_PATH}/CertificateLogo/platformfoundations.png` }
    ];

    @api recordId;
    @api linkedinUrl;
    @api trailblazerUrl;

    // =========================
    // STATE
    // =========================

    activeSection = SECTION.HOME;

    // =========================
    // HELPERS
    // =========================
    isActive(section) {
        return this.activeSection === section;
    }

    // =========================
    // UI STATE
    // =========================
    get showHome() {
        return this.isActive(SECTION.HOME);
    }

    get showExperience() {
        return this.isActive(SECTION.EXPERIENCE);
    }

    get showSkills() {
        return this.isActive(SECTION.SKILLS);
    }

    get homeClass() {
        return this.isActive(SECTION.HOME) ? 'active' : '';
    }

    get experienceClass() {
        return this.isActive(SECTION.EXPERIENCE) ? 'active' : '';
    }

    get skillsClass() {
        return this.isActive(SECTION.SKILLS) ? 'active' : '';
    }

    // =========================
    // NAVIGATION (ONE HANDLER)
    // =========================
    handleNavigation(event) {
        const section = event.target.dataset.section;
        if (section) {
            this.activeSection = section;
        }
    }
}