import { LightningElement, api } from 'lwc';
import PortfolioAssets from '@salesforce/resourceUrl/PortfolioAssets';
import getPortfolioSettings from '@salesforce/apex/PortfolioController.getPortfolioSettings';

/* =========================================================
   CONSTANTS
========================================================= */

const BASE_PATH = `${PortfolioAssets}/PortfolioAssets`;

const SECTION = {
    HOME: 'home',
    EXPERIENCE: 'experience',
    PROJECTS: 'projects',
    SKILLS: 'skills'
};

const TRANSITION_DURATION = 250;

/* =========================================================
   COMPONENT
========================================================= */

export default class Portfolio extends LightningElement {
    /* =========================================================
       PUBLIC API
    ========================================================= */
    @api recordId;

    /* =========================================================
       STATE
    ========================================================= */
    activeSection = SECTION.HOME;
    isTransitioning = false;
    menuOpen = false;
    fullName = '';
    currentYear = new Date().getFullYear();
    hasLoadedHome = true;
    hasLoadedExperience = false;
    hasLoadedProjects = false;
    hasLoadedSkills = false;

    // Guard - ensures theme is only loaded once, after template is ready
    _themeApplied = false;

    /* =========================================================
       ASSETS
    ========================================================= */
    profilePicture = `${BASE_PATH}/portfolioPicture.jpg`;

    social = {
        linkedin: `${BASE_PATH}/Social/linkedin.svg`,
        trailblazer: `${BASE_PATH}/Social/trailhead2.png`,
        github: `${BASE_PATH}/Social/github-white.svg`
    };

    /* =========================================================
       LIFECYCLE
       renderedCallback guarantees this.template.host exists
       before we try to set CSS custom properties on it.
       The _themeApplied guard prevents repeated Apex calls
       on subsequent renders.
    ========================================================= */
    renderedCallback() {
        if (!this._themeApplied && this.recordId) {
            this._themeApplied = true;
            this.loadSettings();
        }
    }

    async loadSettings() {
        try {
            const data = await getPortfolioSettings({
                portfolioId: this.recordId
            });

            if (data) {
                this.applyTheme(data);
            }
        } catch (error) {
            console.error('Theme load error', error);
        }
    }

    applyTheme(settings) {
        const style = this.template.host.style;

        // COLORS
        style.setProperty(
            '--primary-color',
            settings.Primary_Color__c || '#3b82f6'
        );
        style.setProperty(
            '--secondary-color',
            settings.Secondary_Color__c || '#1e40af'
        );
        style.setProperty(
            '--accent-color',
            settings.Accent_Color__c || '#60a5fa'
        );

        style.setProperty(
            '--background-color',
            settings.Background_Color__c || '#020617'
        );
        style.setProperty(
            '--card-bg-color',
            settings.Card_Background__c || '#111827'
        );
        style.setProperty(
            '--border',
            settings.Border_Color__c || 'rgba(255,255,255,0.08)'
        );

        // TEXT
        style.setProperty(
            '--text-primary',
            settings.Primary_Text_Color__c || '#ffffff'
        );
        style.setProperty(
            '--text-secondary',
            settings.Secondary_Text_Color__c || '#cbd5f5'
        );
        style.setProperty(
            '--text-muted',
            settings.Muted_Text_Color__c || '#94a3b8'
        );

        // BUTTON
        style.setProperty(
            '--btn-gradient-start',
            settings.Button_Gradient_Start__c || '#3b82f6'
        );
        style.setProperty(
            '--btn-gradient-end',
            settings.Button_Gradient_End__c || '#1d4ed8'
        );
        style.setProperty(
            '--btn-text',
            settings.Button_Text_Color__c || '#ffffff'
        );

        // EFFECTS
        style.setProperty(
            '--card-radius',
            settings.Card_Border_Radius__c || '14px'
        );
        style.setProperty(
            '--card-shadow',
            settings.Card_Shadow__c || '0 10px 30px rgba(0,0,0,0.4)'
        );
        style.setProperty(
            '--hover-border',
            settings.Hover_Border_Color__c || '#3b82f6'
        );
    }

    /* =========================================================
       HELPERS
    ========================================================= */
    isActive(section) {
        return this.activeSection === section;
    }

    markSectionLoaded(section) {
        if (section === SECTION.EXPERIENCE) this.hasLoadedExperience = true;
        if (section === SECTION.PROJECTS) this.hasLoadedProjects = true;
        if (section === SECTION.SKILLS) this.hasLoadedSkills = true;
    }

    getSectionClass(section) {
        return `section-panel${this.isActive(section) ? ' active' : ''}`;
    }

    getAriaHidden(section) {
        return this.isActive(section) ? 'false' : 'true';
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

    get showProjects() {
        return this.isActive(SECTION.PROJECTS);
    }

    get showSkills() {
        return this.isActive(SECTION.SKILLS);
    }

    get homeClass() {
        return this.showHome ? 'active' : '';
    }

    get experienceClass() {
        return this.showExperience ? 'active' : '';
    }

    get projectsClass() {
        return this.showProjects ? 'active' : '';
    }

    get skillsClass() {
        return this.showSkills ? 'active' : '';
    }

    get homeSectionClass() {
        return this.getSectionClass(SECTION.HOME);
    }

    get experienceSectionClass() {
        return this.getSectionClass(SECTION.EXPERIENCE);
    }

    get projectsSectionClass() {
        return this.getSectionClass(SECTION.PROJECTS);
    }

    get skillsSectionClass() {
        return this.getSectionClass(SECTION.SKILLS);
    }

    get homeAriaHidden() {
        return this.getAriaHidden(SECTION.HOME);
    }

    get experienceAriaHidden() {
        return this.getAriaHidden(SECTION.EXPERIENCE);
    }

    get projectsAriaHidden() {
        return this.getAriaHidden(SECTION.PROJECTS);
    }

    get skillsAriaHidden() {
        return this.getAriaHidden(SECTION.SKILLS);
    }

    get contentClass() {
        return `content ${this.isTransitioning ? 'fade-out' : ''}`;
    }

    get navLinksClass() {
        return `nav-links${this.menuOpen ? ' open' : ''}`;
    }

    get hamburgerClass() {
        return `hamburger${this.menuOpen ? ' active' : ''}`;
    }

    /* =========================================================
       EVENTS
    ========================================================= */
    handleNameChange(event) {
        const newName = event.detail ? event.detail.toUpperCase() : '';

        // Prevent unnecessary rerender
        if (newName !== this.fullName) {
            this.fullName = newName;
        }
    }

    handleHomeSectionChange(event) {
        this.navigateToSection(event.detail);
    }

    /* =========================================================
       NAVIGATION (SMOOTH TRANSITION)
    ========================================================= */
    toggleMenu() {
        this.menuOpen = !this.menuOpen;
    }

    handleNavigation(event) {
        const section = event.target.dataset.section;

        this.navigateToSection(section);
    }

    navigateToSection(section) {
        if (!section || section === this.activeSection) return;

        this.menuOpen = false;
        this.markSectionLoaded(section);
        this.isTransitioning = true;

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this.activeSection = section;
            this.isTransitioning = false;
        }, TRANSITION_DURATION);
    }
}
