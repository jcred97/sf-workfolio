import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import sendContactMessage from '@salesforce/apex/PortfolioController.sendContactMessage';
import EMAIL from '@salesforce/schema/Portfolio__c.Email__c';

/**
 * PortfolioContact
 * -----------------
 * Public-facing contact component.
 *
 * Responsibilities:
 * - Collect user input
 * - Validate client-side
 * - Call Apex to send email
 * - Display async state feedback
 * - Render dynamic portfolio email from record
 */
export default class PortfolioContact extends LightningElement {

    /* =========================================================
       PUBLIC API PROPERTIES (Configured via Experience Builder)
    ========================================================= */

    @api recordId;
    @api linkedin;
    @api linkedinUrl;
    @api trailblazer;
    @api trailblazerUrl;


    /* =========================================================
       FORM STATE (Two-way bound via onchange handler)
    ========================================================= */

    firstName = '';
    lastName = '';
    emailAddress = '';
    message = '';


    /* =========================================================
       UI STATE MANAGEMENT
    ========================================================= */

    isLoading = false;
    showSuccess = false;
    showError = false;
    errorMessage = '';

    fadeSuccess = false;
    fadeError = false;


    /* =========================================================
       DATA WIRING — Fetch Portfolio Email from Record
    ========================================================= */

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [EMAIL]
    })
    portfolioData;


    /* =========================================================
       GENERIC INPUT HANDLER
       Dynamically updates property based on input name
    ========================================================= */

    inputHandler(event) {
        const { name, value } = event.target;
        this[name] = value;
    }


    /* =========================================================
       MAIN SUBMIT FLOW
       - Prevent duplicate submission
       - Validate inputs
       - Call Apex
       - Handle success/error
       - Reset UI state
    ========================================================= */

    async sendDataAndEmail() {

        if (this.isLoading) return; // Prevent double-click submission
        if (!this.validateInputs()) return;

        this.isLoading = true;
        this.resetBanners();

        try {
            await sendContactMessage({
                firstName: this.firstName,
                lastName: this.lastName,
                emailAddress: this.emailAddress,
                message: this.message
            });

            this.showBanner('success');
            this.resetForm();

        } catch (error) {

            this.errorMessage =
                error?.body?.message ||
                error?.message ||
                'Something went wrong.';

            this.showBanner('error');

        } finally {
            this.isLoading = false;
        }
    }


    /* =========================================================
       CLIENT-SIDE VALIDATION
       Uses SLDS validity reporting
    ========================================================= */

    validateInputs() {
        return [...this.template.querySelectorAll('lightning-input, lightning-textarea')]
            .reduce((validSoFar, field) => {
                field.reportValidity();
                return validSoFar && field.checkValidity();
            }, true);
    }


    /* =========================================================
       BANNER DISPLAY + AUTO FADE LOGIC
    ========================================================= */

    showBanner(type) {

        if (type === 'success') {
            this.showSuccess = true;
            this.fadeSuccess = false;

            setTimeout(() => this.fadeSuccess = true, 2500);
            setTimeout(() => this.showSuccess = false, 3000);
        }

        if (type === 'error') {
            this.showError = true;
            this.fadeError = false;

            setTimeout(() => this.fadeError = true, 2500);
            setTimeout(() => this.showError = false, 3000);
        }
    }

    resetBanners() {
        this.showSuccess = false;
        this.showError = false;
        this.fadeSuccess = false;
        this.fadeError = false;
    }


    /* =========================================================
       RESET FORM STATE
    ========================================================= */

    resetForm() {
        this.firstName = '';
        this.lastName = '';
        this.emailAddress = '';
        this.message = '';
    }


    /* =========================================================
       EMAIL UTILITIES
    ========================================================= */

    copyEmail() {
        if (!this.email) return;
        navigator.clipboard.writeText(this.email);
    }

    get email() {
        return this.portfolioData?.data
            ? getFieldValue(this.portfolioData.data, EMAIL)
            : null;
    }

    get mailtoLink() {
        return this.email ? `mailto:${this.email}` : '';
    }


    /* =========================================================
       DYNAMIC CSS CLASS GETTERS
       Used to apply fade animation conditionally
    ========================================================= */

    get successClass() {
        return this.fadeSuccess
            ? 'success-banner fade-out'
            : 'success-banner';
    }

    get errorClass() {
        return this.fadeError
            ? 'error-banner fade-out'
            : 'error-banner';
    }
}