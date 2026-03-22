import { LightningElement, api } from 'lwc';
import PortfolioAssets from '@salesforce/resourceUrl/PortfolioAssets';

/* =========================================================
   CONSTANTS
========================================================= */

const BASE_PATH = `${PortfolioAssets}/PortfolioAssets`;

const SECTION = {
    HOME: 'home',
    EXPERIENCE: 'experience',
    SKILLS: 'skills'
};

/* =========================================================
   COMPONENT
========================================================= */

export default class Portfolio extends LightningElement {

    /* =========================================================
       PUBLIC API
    ========================================================= */

    @api recordId;
    @api linkedinUrl;
    @api trailblazerUrl;

    /* =========================================================
       ASSETS
    ========================================================= */

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

    /* =========================================================
       STATE
    ========================================================= */

    activeSection = SECTION.HOME;
    isTransitioning = false;

    /* =========================================================
       HELPERS
    ========================================================= */

    isActive(section) {
        return this.activeSection === section;
    }

    /* =========================================================
       UI STATE (GETTERS)
    ========================================================= */

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

    get contentClass() {
        return this.isTransitioning
            ? 'content fade-out'
            : 'content';
    }

    /* =========================================================
       NAVIGATION (SMOOTH TRANSITION)
    ========================================================= */

    handleNavigation(event) {
        const section = event.target.dataset.section;

        if (!section || section === this.activeSection) return;

        this.isTransitioning = true;

        setTimeout(() => {
            this.activeSection = section;
            this.isTransitioning = false;
        }, 250); // Matches CSS timing
    }
}