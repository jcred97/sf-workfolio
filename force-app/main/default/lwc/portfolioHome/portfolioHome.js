import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getCertifications from '@salesforce/apex/PortfolioController.getCertifications';

import FULLNAME from '@salesforce/schema/Portfolio__c.FullName__c';
import DESIGNATION from '@salesforce/schema/Portfolio__c.Designation__c';
import CAREER_START_DATE from '@salesforce/schema/Portfolio__c.Career_Start_Date__c';
import INTRODUCTION from '@salesforce/schema/Portfolio__c.Introduction__c';
import SUB_INTRODUCTION from '@salesforce/schema/Portfolio__c.Sub_Introduction__c';
import LINKEDIN_URL from '@salesforce/schema/Portfolio__c.LinkedIn_URL__c';
import GITHUB_URL from '@salesforce/schema/Portfolio__c.Github_URL__c';
import TRAILBLAZER_URL from '@salesforce/schema/Portfolio__c.Trailblazer_URL__c';

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
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [
            FULLNAME,
            DESIGNATION,
            CAREER_START_DATE,
            INTRODUCTION,
            SUB_INTRODUCTION,
            LINKEDIN_URL,
            GITHUB_URL,
            TRAILBLAZER_URL
        ]
    })
    wiredPortfolio(result) {
        this.portfolioData = result;

        if (result.data) {
            this.hasError = false;
            this.errorMessage = '';

            const name = getFieldValue(result.data, FULLNAME);

            // Only dispatch when name is available and hasn't been sent yet
            if (name && name !== this._lastSentName) {
                this._lastSentName = name;
                this.dispatchEvent(
                    new CustomEvent('namechange', { detail: name })
                );
            }
        } else if (result.error) {
            this.hasError = true;
            this.errorMessage =
                result.error?.body?.message ||
                result.error?.message ||
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
        return getFieldValue(this.portfolioData.data, FULLNAME);
    }

    get designation() {
        return getFieldValue(this.portfolioData.data, DESIGNATION);
    }

    get introduction() {
        return getFieldValue(this.portfolioData.data, INTRODUCTION);
    }

    get subIntroduction() {
        return getFieldValue(this.portfolioData.data, SUB_INTRODUCTION);
    }

    get linkedinUrl() {
        return getFieldValue(this.portfolioData.data, LINKEDIN_URL);
    }

    get githubUrl() {
        return getFieldValue(this.portfolioData.data, GITHUB_URL);
    }

    get trailblazerUrl() {
        return getFieldValue(this.portfolioData.data, TRAILBLAZER_URL);
    }

    get experienceSummary() {
        const startDate = getFieldValue(
            this.portfolioData.data,
            CAREER_START_DATE
        );
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
