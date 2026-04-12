import { LightningElement, api, wire } from 'lwc';
import getPortfolio from '@salesforce/apex/PortfolioController.getPortfolio';
import getCertifications from '@salesforce/apex/PortfolioController.getCertifications';

export default class PortfolioHome extends LightningElement {
    @api recordId;
    @api linkedin;
    @api trailblazer;
    @api github;
    @api profilePicture;

    /* =========================================================
       PRIVATE STATE
    ========================================================= */
    portfolioData = {};
    certifications = [];
    _lastSentName = '';
    hasError = false;
    errorMessage = '';

    /* =========================================================
       WIRE - Portfolio record
    ========================================================= */
    @wire(getPortfolio, { portfolioId: '$recordId' })
    wiredPortfolio({ data, error }) {
        if (data) {
            this.portfolioData = data;
            this.hasError = false;
            this.errorMessage = '';

            const name = data.FullName__c;

            // Only dispatch when name is available and hasn't been sent yet
            if (name && name !== this._lastSentName) {
                this._lastSentName = name;
                this.dispatchEvent(
                    new CustomEvent('namechange', { detail: name })
                );
            }
        } else if (error) {
            this.hasError = true;
            this.errorMessage =
                error?.body?.message ||
                error?.message ||
                'Unable to load profile. Please try again later.';
        }
    }

    /* =========================================================
       WIRE - Certifications from Certification__c
    ========================================================= */
    @wire(getCertifications, { portfolioId: '$recordId' })
    wiredCertifications({ data, error }) {
        if (data) {
            this.certifications = data.map((cert) => ({
                Id: cert.Id,
                name: cert.Name,
                image: cert.Image_URL__c
            }));
        } else if (error) {
            console.error('Certifications load error', error);
            this.certifications = [];
        }
    }

    /* =========================================================
       GETTERS
    ========================================================= */
    get fullName() {
        return this.portfolioData.FullName__c;
    }

    get designation() {
        return this.portfolioData.Designation__c;
    }

    get introduction() {
        return this.portfolioData.Introduction__c;
    }

    get subIntroduction() {
        return this.portfolioData.Sub_Introduction__c;
    }

    get linkedinUrl() {
        return this.portfolioData.LinkedIn_URL__c;
    }

    get githubUrl() {
        return this.portfolioData.Github_URL__c;
    }

    get trailblazerUrl() {
        return this.portfolioData.Trailblazer_URL__c;
    }

    get experienceSummary() {
        const startDate = this.portfolioData.Career_Start_Date__c;
        if (!startDate) return '';

        const start = new Date(startDate);
        const today = new Date();

        let years = today.getFullYear() - start.getFullYear();
        const monthDiff = today.getMonth() - start.getMonth();

        // Adjust if current month is before the anniversary month
        if (
            monthDiff < 0 ||
            (monthDiff === 0 && today.getDate() < start.getDate())
        ) {
            years--;
        }

        return `${years}`;
    }

    handleViewWork() {
        this.dispatchEvent(
            new CustomEvent('sectionchange', {
                detail: 'projects',
                bubbles: true,
                composed: true
            })
        );
    }

    handleContactJump() {
        this.template
            .querySelector('.contact-section')
            ?.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
}
