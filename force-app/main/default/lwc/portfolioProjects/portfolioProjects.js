import { LightningElement, api, wire } from 'lwc';
import getPersonalProjects from '@salesforce/apex/PortfolioController.getPersonalProjects';

export default class PortfolioProjects extends LightningElement {
    @api recordId;
    projects = [];
    hasError = false;
    errorMessage = '';

    /* =========================================================
       WIRE
    ========================================================= */
    @wire(getPersonalProjects, { portfolioId: '$recordId' })
    wiredProjects({ data, error }) {
        if (data) {
            this.hasError = false;
            this.errorMessage = '';
            this.projects = data.map(proj => ({
                Id: proj.Id,
                Name: proj.Name,
                Description: proj.Description__c,
                TechStack: this.splitTechStack(proj.Tech_Stack__c),
                embedUrl: this.toEmbedUrl(proj.YouTube_URL__c),
                hasVideo: !!this.toEmbedUrl(proj.YouTube_URL__c),
                GitHubUrl: proj.GitHub_URL__c,
                LiveUrl: proj.Live_URL__c,
                hasGitHub: !!proj.GitHub_URL__c,
                hasLive: !!proj.Live_URL__c,
                hasLinks: !!proj.GitHub_URL__c || !!proj.Live_URL__c
            }));
        } else if (error) {
            this.hasError = true;
            this.errorMessage = error?.body?.message || error?.message || 'Unable to load projects. Please try again later.';
            this.projects = [];
            console.error(error);
        }
    }

    /* =========================================================
       GETTERS
    ========================================================= */
    get hasProjects() {
        return this.projects.length > 0;
    }

    /* =========================================================
       HELPERS
    ========================================================= */
    splitTechStack(value) {
        if (!value) return null;
        const result = value.split(',').map(t => t.trim()).filter(Boolean);
        return result.length ? result : null;
    }

    /**
     * Converts any YouTube URL format to an embed URL.
     * Supports:
     *   - https://www.youtube.com/watch?v=VIDEO_ID
     *   - https://youtu.be/VIDEO_ID
     *   - https://www.youtube.com/embed/VIDEO_ID
     */
    toEmbedUrl(url) {
        if (!url) return null;

        let videoId = null;

        // Already an embed URL
        const embedMatch = url.match(/youtube\.com\/embed\/([a-zA-Z0-9_-]+)/);
        if (embedMatch) return url;

        // Standard watch URL
        const watchMatch = url.match(/[?&]v=([a-zA-Z0-9_-]+)/);
        if (watchMatch) videoId = watchMatch[1];

        // Shortened URL
        if (!videoId) {
            const shortMatch = url.match(/youtu\.be\/([a-zA-Z0-9_-]+)/);
            if (shortMatch) videoId = shortMatch[1];
        }

        return videoId ? `https://www.youtube.com/embed/${videoId}` : null;
    }
}
