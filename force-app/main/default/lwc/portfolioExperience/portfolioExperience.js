import { LightningElement, api, wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class PortfolioExperience extends LightningElement {
    @api recordId;
    workExperienceList = [];

    /* =====================================
       🔌 DATA
    ===================================== */
    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'WorkExperience__r',
        sortBy: ['-WorkExperience__c.JobStartDate__c'],
        fields: [
            'WorkExperience__c.JobStartDate__c',
            'WorkExperience__c.JobEndDate__c',
            'WorkExperience__c.Role__c',
            'WorkExperience__c.CompanyName__c',
            'WorkExperience__c.WorkLocation__c',
            'WorkExperience__c.Description__c',
            'WorkExperience__c.IsCurrent__c',
            'WorkExperience__c.Tech_Stack__c'
        ]
    })
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
        this.workExperienceList = data.records.map((item, index) => {
            const f = item.fields;

            const isCurrent = this.getValue(f.IsCurrent__c);
            const endDate = this.getValue(f.JobEndDate__c);
            const isActive = index === 0;

            return {
                id: item.id,

                JobStartDate: this.getValue(f.JobStartDate__c),
                displayEnd: isCurrent ? 'Current' : endDate,

                Role: this.getValue(f.Role__c),
                CompanyName: this.getValue(f.CompanyName__c),
                WorkLocation: this.getValue(f.WorkLocation__c),
                Description: this.getValue(f.Description__c),

                TechStack: this.getValue(f.Tech_Stack__c)
                    ?.split(',')
                    .map(t => t.trim()),

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
       🖥️ DESKTOP (FIXED ANIMATION)
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
    getValue(field) {
        return field && (field.displayValue || field.value);
    }
}