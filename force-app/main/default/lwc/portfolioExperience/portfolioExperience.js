import { LightningElement, api, wire } from 'lwc';
import getWorkExperiences from '@salesforce/apex/PortfolioController.getWorkExperiences';

export default class PortfolioExperience extends LightningElement {
    @api recordId;
    workExperienceList = [];
    hasError = false;
    errorMessage = '';
    _activeId = null;

    /* =====================================
       WIRE - WORK EXPERIENCE
    ===================================== */
    @wire(getWorkExperiences, { portfolioId: '$recordId' })
    workExperienceHandler({ data, error }) {
        if (data) {
            this.hasError = false;
            this.errorMessage = '';
            this.formatExperience(data);

            // eslint-disable-next-line @lwc/lwc/no-async-operation
            requestAnimationFrame(() => {
                this.animateHeight();
            });
        } else if (error) {
            this.hasError = true;
            this.errorMessage =
                error?.body?.message ||
                error?.message ||
                'Unable to load experience. Please try again later.';
            this.workExperienceList = [];
            console.error(error);
        }
    }

    /* =====================================
       FORMAT
    ===================================== */
    formatExperience(data) {
        this.workExperienceList = data.map((item, index) => {
            const isCurrent = item.IsCurrent__c;
            const endDate = this.formatDate(item.JobEndDate__c);
            const isActive = index === 0;
            const duration = this.calcDuration(
                item.JobStartDate__c,
                item.JobEndDate__c,
                isCurrent
            );

            const allBullets = item.Experience_Bullets__r || [];

            // Group bullets under their parent project
            const projects = (item.Projects__r || []).map((proj) => {
                const projBullets = allBullets
                    .filter((b) => b.Project__c === proj.Id)
                    .map((b) => ({ Id: b.Id, Text: b.Bullet_Text__c }));

                return {
                    Id: proj.Id,
                    Name: proj.Name,
                    TechStack: this.splitTechStack(proj.Tech_Stack__c),
                    Bullets: projBullets,
                    hasBullets: projBullets.length > 0
                };
            });

            // Bullets not linked to any project
            const generalBullets = allBullets
                .filter((b) => !b.Project__c)
                .map((b) => ({ Id: b.Id, Text: b.Bullet_Text__c }));

            const hasContent = generalBullets.length > 0 || projects.length > 0;

            if (isActive) {
                this._activeId = item.Id;
            }

            return {
                id: item.Id,

                JobStartDate: this.formatDate(item.JobStartDate__c),
                displayEnd: isCurrent ? 'Current' : endDate,
                duration,
                isCurrent,

                Role: item.Role__c,
                CompanyName: item.CompanyName__c,
                WorkLocation: item.WorkLocation__c,

                GeneralBullets: generalBullets,
                hasGeneralBullets: generalBullets.length > 0,

                Projects: projects,
                hasProjects: projects.length > 0,
                hasContent,

                /* MOBILE */
                isOpen: isActive,
                icon: isActive ? '-' : '+',
                bodyClass: isActive ? 'node-children open' : 'node-children',

                /* DESKTOP */
                isActive,
                leftClass: `exp-item${isActive ? ' active' : ''}${isCurrent ? ' current' : ''}`,
                rightClass: isActive
                    ? 'detail-content active'
                    : 'detail-content'
            };
        });
    }

    /* =====================================
       DESKTOP - Active detail (single panel)
    ===================================== */
    get activeDetail() {
        return this.workExperienceList.find((w) => w.isActive) || null;
    }

    /* =====================================
       MOBILE
    ===================================== */
    toggleCard(event) {
        if (event.type === 'keydown') {
            if (event.key !== 'Enter' && event.key !== ' ') return;
            if (event.key === ' ') event.preventDefault();
        }

        const id = event.currentTarget.dataset.id;
        const affectedIds = new Set([
            id,
            ...this.workExperienceList
                .filter((item) => item.isOpen)
                .map((item) => item.id)
        ]);

        this.workExperienceList = this.workExperienceList.map((item) => {
            const isOpen = item.id === id ? !item.isOpen : false;

            return {
                ...item,
                isOpen,
                icon: isOpen ? '-' : '+',
                bodyClass: isOpen ? 'node-children open' : 'node-children'
            };
        });

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        requestAnimationFrame(() => {
            this.animateHeight([...affectedIds]);
        });
    }

    /* =====================================
       DESKTOP
    ===================================== */
    selectExperience(event) {
        if (event.type === 'keydown') {
            if (event.key !== 'Enter' && event.key !== ' ') return;
            if (event.key === ' ') event.preventDefault();
        }

        const id = event.currentTarget.dataset.id;
        if (id === this._activeId) return;
        this._activeId = id;

        // Step 1: remove active
        this.workExperienceList = this.workExperienceList.map((item) => ({
            ...item,
            isActive: false,
            leftClass: `exp-item${item.isCurrent ? ' current' : ''}`,
            rightClass: 'detail-content'
        }));

        // Step 2: next frame activate (enables animation)
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        requestAnimationFrame(() => {
            this.workExperienceList = this.workExperienceList.map((item) => {
                const isActive = item.id === id;

                return {
                    ...item,
                    isActive,
                    leftClass: `exp-item${isActive ? ' active' : ''}${item.isCurrent ? ' current' : ''}`,
                    rightClass: isActive
                        ? 'detail-content active'
                        : 'detail-content'
                };
            });
        });
    }

    /* =====================================
       MOBILE ANIMATION
    ===================================== */
    animateHeight(ids) {
        const sections = ids?.length
            ? ids
                  .map((id) =>
                      this.template.querySelector(
                          `.node-children[data-id="${id}"]`
                      )
                  )
                  .filter(Boolean)
            : this.template.querySelectorAll('.node-children');

        sections.forEach((section) => {
            if (section.classList.contains('open')) {
                section.style.height = 'auto';
                const height = section.scrollHeight + 'px';
                section.style.height = '0px';

                // eslint-disable-next-line @lwc/lwc/no-async-operation
                requestAnimationFrame(() => {
                    section.style.height = height;
                });
            } else {
                section.style.height = section.scrollHeight + 'px';

                // eslint-disable-next-line @lwc/lwc/no-async-operation
                requestAnimationFrame(() => {
                    section.style.height = '0px';
                });
            }
        });
    }

    /* =====================================
       HELPERS
    ===================================== */
    splitTechStack(value) {
        if (!value) return null;
        const result = value
            .split(',')
            .map((t) => t.trim())
            .filter(Boolean);
        return result.length ? result : null;
    }

    formatDate(dateStr) {
        if (!dateStr) return null;
        const date = new Date(dateStr + 'T00:00:00');
        return date.toLocaleDateString('en-US', {
            month: 'short',
            year: 'numeric'
        });
    }

    calcDuration(startStr, endStr, isCurrent) {
        if (!startStr) return '';

        const start = new Date(startStr + 'T00:00:00');
        const end = isCurrent
            ? new Date()
            : endStr
              ? new Date(endStr + 'T00:00:00')
              : new Date();

        let months =
            (end.getFullYear() - start.getFullYear()) * 12 +
            (end.getMonth() - start.getMonth());
        if (months < 0) months = 0;

        const yrs = Math.floor(months / 12);
        const mos = months % 12;

        if (yrs === 0) return `${mos} mo${mos !== 1 ? 's' : ''}`;
        if (mos === 0) return `${yrs} yr${yrs !== 1 ? 's' : ''}`;
        return `${yrs} yr${yrs !== 1 ? 's' : ''} ${mos} mo${mos !== 1 ? 's' : ''}`;
    }
}
