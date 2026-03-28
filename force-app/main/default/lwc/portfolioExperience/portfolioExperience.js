import { LightningElement, api, wire } from 'lwc';
import getWorkExperiences from '@salesforce/apex/PortfolioController.getWorkExperiences';

export default class PortfolioExperience extends LightningElement {
    @api recordId;
    workExperienceList = [];

    /* =====================================
       🔌 WIRE — WORK EXPERIENCE
    ===================================== */
    @wire(getWorkExperiences, { portfolioId: '$recordId' })
    workExperienceHandler({ data, error }) {
        if (data) {
            this.formatExperience(data);

            requestAnimationFrame(() => {
                this.animateHeight();
            });

        } else if (error) {
            console.error(error);
        }
    }

    /* =====================================
       🧠 FORMAT
    ===================================== */
    formatExperience(data) {
        this.workExperienceList = data.map((item, index) => {
            const isCurrent = item.IsCurrent__c;
            const endDate = this.formatDate(item.JobEndDate__c);
            const isActive = index === 0;

            const allBullets = item.Experience_Bullets__r || [];

            // Group bullets under their parent project
            const projects = (item.Projects__r || []).map(proj => {
                const projBullets = allBullets
                    .filter(b => b.Project__c === proj.Id)
                    .map(b => ({ Id: b.Id, Text: b.Bullet_Text__c }));

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
                .filter(b => !b.Project__c)
                .map(b => ({ Id: b.Id, Text: b.Bullet_Text__c }));

            return {
                id: item.Id,

                JobStartDate: this.formatDate(item.JobStartDate__c),
                displayEnd: isCurrent ? 'Current' : endDate,

                Role: item.Role__c,
                CompanyName: item.CompanyName__c,
                WorkLocation: item.WorkLocation__c,

                GeneralBullets: generalBullets,
                hasGeneralBullets: generalBullets.length > 0,

                Projects: projects,
                hasProjects: projects.length > 0,

                /* MOBILE */
                isOpen: isActive,
                icon: isActive ? '−' : '+',
                bodyClass: isActive ? 'node-children open' : 'node-children',

                /* DESKTOP */
                isActive,
                leftClass: isActive ? 'exp-item active' : 'exp-item',
                rightClass: isActive ? 'detail-content active' : 'detail-content'
            };
        });
    }

    /* =====================================
       📱 MOBILE
    ===================================== */
    toggleCard(event) {
        const id = event.currentTarget.dataset.id;

        this.workExperienceList = this.workExperienceList.map(item => {
            const isOpen = item.id === id ? !item.isOpen : false;

            return {
                ...item,
                isOpen,
                icon: isOpen ? '−' : '+',
                bodyClass: isOpen ? 'node-children open' : 'node-children'
            };
        });

        requestAnimationFrame(() => {
            this.animateHeight();
        });
    }

    /* =====================================
       🖥️ DESKTOP
    ===================================== */
    selectExperience(event) {
        const id = event.currentTarget.dataset.id;

        // Step 1: remove active
        this.workExperienceList = this.workExperienceList.map(item => ({
            ...item,
            isActive: false,
            leftClass: 'exp-item',
            rightClass: 'detail-content'
        }));

        // Step 2: next frame activate (enables animation)
        requestAnimationFrame(() => {
            this.workExperienceList = this.workExperienceList.map(item => {
                const isActive = item.id === id;

                return {
                    ...item,
                    isActive,
                    leftClass: isActive ? 'exp-item active' : 'exp-item',
                    rightClass: isActive ? 'detail-content active' : 'detail-content'
                };
            });
        });
    }

    /* =====================================
       🎬 MOBILE ANIMATION
    ===================================== */
    animateHeight() {
        const sections = this.template.querySelectorAll('.node-children');

        sections.forEach(section => {
            if (section.classList.contains('open')) {
                section.style.height = 'auto';
                const height = section.scrollHeight + 'px';
                section.style.height = '0px';

                requestAnimationFrame(() => {
                    section.style.height = height;
                });

            } else {
                section.style.height = section.scrollHeight + 'px';

                requestAnimationFrame(() => {
                    section.style.height = '0px';
                });
            }
        });
    }

    /* =====================================
       🧩 HELPERS
    ===================================== */
    splitTechStack(value) {
        if (!value) return null;
        const result = value.split(',').map(t => t.trim()).filter(Boolean);
        return result.length ? result : null;
    }

    formatDate(dateStr) {
        if (!dateStr) return null;
        const date = new Date(dateStr + 'T00:00:00');
        return date.toLocaleDateString('en-US', { month: 'short', year: 'numeric' });
    }
}
