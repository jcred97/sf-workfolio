import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import submitLead from '@salesforce/apex/PortfolioController.submitLead';
import EMAIL from '@salesforce/schema/Portfolio__c.Email__c';

/**
 * PortfolioContact
 * -----------------
 * Public-facing contact component.
 *
 * Responsibilities:
 * - Collect user input (native inputs with floating labels)
 * - Validate client-side
 * - Call Apex to submit lead
 * - Display async state feedback with auto-fade
 * - Render dynamic portfolio email from record
 */
export default class PortfolioContact extends LightningElement {

    /* =========================================================
       PUBLIC API
    ========================================================= */
    @api recordId;
    @api linkedin;
    @api linkedinUrl;
    @api trailblazer;
    @api trailblazerUrl;
    @api github;
    @api githubUrl;

    /* =========================================================
       FORM STATE
    ========================================================= */
    firstName    = '';
    lastName     = '';
    emailAddress = '';
    message      = '';

    /* =========================================================
       UI STATE
    ========================================================= */
    isLoading    = false;
    showSuccess  = false;
    showError    = false;
    errorMessage = '';
    fadeSuccess  = false;
    fadeError    = false;

    /* =========================================================
       WIRE — Portfolio email from record
    ========================================================= */
    @wire(getRecord, { recordId: '$recordId', fields: [EMAIL] })
    portfolioData;

    /* =========================================================
       INPUT HANDLER
       Works for both input and textarea via name attribute
    ========================================================= */
    inputHandler(event) {
        const { name, value } = event.target;
        this[name] = value;
    }

    /* =========================================================
       SUBMIT FLOW
    ========================================================= */
    async sendDataAndEmail() {
        if (this.isLoading) return;
        if (!this.validateInputs()) return;

        this.isLoading = true;
        this.resetBanners();

        try {
            await submitLead({
                firstName:    this.firstName,
                lastName:     this.lastName,
                emailAddress: this.emailAddress,
                message:      this.message
            });

            this.showBanner('success');
            this.resetForm();

        } catch (error) {
            this.errorMessage =
                error?.body?.message ||
                error?.message ||
                'Something went wrong. Please try again.';

            this.showBanner('error');

        } finally {
            this.isLoading = false;
        }
    }

    /* =========================================================
       VALIDATION
       Native inputs use the Constraint Validation API.
       reportValidity() shows browser tooltips on invalid fields.
    ========================================================= */
    validateInputs() {
        const fields = [...this.template.querySelectorAll('input, textarea')];

        // Run all reportValidity calls so all errors show at once
        const results = fields.map(field => {
            field.reportValidity();
            return field.checkValidity();
        });

        return results.every(Boolean);
    }

    /* =========================================================
       BANNER LOGIC
    ========================================================= */
    showBanner(type) {
        if (type === 'success') {
            this.showSuccess  = true;
            this.fadeSuccess  = false;
            setTimeout(() => { this.fadeSuccess = true;  }, 2500);
            setTimeout(() => { this.showSuccess = false; }, 3000);
        }

        if (type === 'error') {
            this.showError  = true;
            this.fadeError  = false;
            setTimeout(() => { this.fadeError = true;  }, 2500);
            setTimeout(() => { this.showError = false; }, 3000);
        }
    }

    resetBanners() {
        this.showSuccess = false;
        this.showError   = false;
        this.fadeSuccess = false;
        this.fadeError   = false;
    }

    /* =========================================================
       FORM RESET
       value= binding handles inputs reactively.
       The textarea also gets a direct DOM clear as a safety net
       since some browsers don't reflect value= updates on textarea.
    ========================================================= */
    resetForm() {
        this.firstName    = '';
        this.lastName     = '';
        this.emailAddress = '';
        this.message      = '';

        // Belt-and-suspenders: directly wipe the textarea DOM value
        const textarea = this.template.querySelector('textarea');
        if (textarea) textarea.value = '';
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
        return this.email ? `mailto:${this.email}` : '#';
    }

    /* =========================================================
       CSS CLASS GETTERS
    ========================================================= */
    get successClass() {
        return this.fadeSuccess ? 'success-banner fade-out' : 'success-banner';
    }

    get errorClass() {
        return this.fadeError ? 'error-banner fade-out' : 'error-banner';
    }
}