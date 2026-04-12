import { LightningElement, api, wire } from 'lwc';
import getPersonalProjects from '@salesforce/apex/PortfolioController.getPersonalProjects';

export default class PortfolioProjects extends LightningElement {
    @api recordId;
    projects = [];
    isLoading = true;
    hasError = false;
    errorMessage = '';

    /* =========================================================
       WIRE
    ========================================================= */
    get showContent() {
        return !this.isLoading && !this.hasError;
    }

    @wire(getPersonalProjects, { portfolioId: '$recordId' })
    wiredProjects({ data, error }) {
        if (!this.recordId || (data === undefined && !error)) return;

        this.isLoading = false;

        if (data) {
            this.hasError = false;
            this.errorMessage = '';
            this.projects = data.map((proj) => {
                const images = (proj.Project_Images__r || []).map((img) => ({
                    Id: img.Id,
                    url: img.Image_URL__c,
                    caption: img.Caption__c || img.Name,
                    isActive: false
                }));

                const THUMB_LIMIT = 6;
                const visibleImages = images.slice(0, THUMB_LIMIT);
                const extraCount =
                    images.length > THUMB_LIMIT
                        ? images.length - THUMB_LIMIT
                        : 0;
                const firstExtraId =
                    extraCount > 0 ? images[THUMB_LIMIT].Id : null;
                const embedUrl = this.toEmbedUrl(proj.YouTube_URL__c);

                return {
                    Id: proj.Id,
                    Name: proj.Name,
                    Description: proj.Description__c,
                    TechStack: this.splitTechStack(proj.Tech_Stack__c),
                    embedUrl,
                    hasVideo: !!embedUrl,
                    GitHubUrl: proj.GitHub_URL__c,
                    LiveUrl: proj.Live_URL__c,
                    hasGitHub: !!proj.GitHub_URL__c,
                    hasLive: !!proj.Live_URL__c,
                    hasLinks: !!proj.GitHub_URL__c || !!proj.Live_URL__c,
                    images,
                    visibleImages,
                    extraCount,
                    firstExtraId,
                    hasExtra: extraCount > 0,
                    hasImages: images.length > 0
                };
            });
        } else if (error) {
            this.hasError = true;
            this.errorMessage =
                error?.body?.message ||
                error?.message ||
                'Unable to load projects. Please try again later.';
            this.projects = [];
            console.error(error);
        }
    }

    /* =========================================================
       LIGHTBOX STATE
    ========================================================= */
    _lightboxOpen = false;
    _lightboxImages = [];
    _lightboxIndex = 0;

    get lightboxOpen() {
        return this._lightboxOpen;
    }
    get lightboxUrl() {
        return this._lightboxImages.length
            ? this._lightboxImages[this._lightboxIndex].url
            : '';
    }
    get lightboxCaption() {
        return this._lightboxImages.length
            ? this._lightboxImages[this._lightboxIndex].caption
            : '';
    }
    get lightboxCounter() {
        return `${this._lightboxIndex + 1} / ${this._lightboxImages.length}`;
    }
    get hasPrev() {
        return this._lightboxIndex > 0;
    }
    get hasNext() {
        return this._lightboxIndex < this._lightboxImages.length - 1;
    }
    get hasMultipleImages() {
        return this._lightboxImages.length > 1;
    }

    _keyHandler = null;

    openLightbox(event) {
        const imageId = event.currentTarget.dataset.id;
        const projectId = event.currentTarget.dataset.projectid;
        const proj = this.projects.find((p) => p.Id === projectId);
        if (!proj) return;

        this._lightboxImages = proj.images;
        this._lightboxIndex = proj.images.findIndex(
            (img) => img.Id === imageId
        );
        if (this._lightboxIndex < 0) this._lightboxIndex = 0;
        this._lightboxOpen = true;

        this._keyHandler = (e) => {
            if (e.key === 'ArrowLeft') this.prevImage();
            else if (e.key === 'ArrowRight') this.nextImage();
            else if (e.key === 'Escape') this.closeLightbox();
        };
        document.addEventListener('keydown', this._keyHandler);
    }

    closeLightbox() {
        this._lightboxOpen = false;
        this._lightboxImages = [];
        this._lightboxIndex = 0;

        if (this._keyHandler) {
            document.removeEventListener('keydown', this._keyHandler);
            this._keyHandler = null;
        }
    }

    prevImage() {
        if (this.hasPrev) this._lightboxIndex--;
    }

    nextImage() {
        if (this.hasNext) this._lightboxIndex++;
    }

    handleLightboxBackdrop(event) {
        if (event.target === event.currentTarget) {
            this.closeLightbox();
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
        const result = value
            .split(',')
            .map((t) => t.trim())
            .filter(Boolean);
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
