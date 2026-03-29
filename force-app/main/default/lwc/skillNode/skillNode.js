import { LightningElement, api } from 'lwc';

export default class SkillNode extends LightningElement {
    @api node;

    get hasChildren() {
        return this.node.children && this.node.children.length > 0;
    }

    get icon() {
        return this.node.isOpen ? '−' : '+';
    }

    toggle(event) {
        if (event.type === 'keydown') {
            if (event.key !== 'Enter' && event.key !== ' ') return;
            if (event.key === ' ') event.preventDefault();
        }

        if (!this.hasChildren) return;

        this.dispatchEvent(
            new CustomEvent('toggle', {
                detail: { id: this.node.Id },
                bubbles: true,
                composed: true
            })
        );
    }

    get allChildrenAreLeaf() {
        return this.node.children?.every(
            child => !child.children || child.children.length === 0
        );
    }

    handleTagClick(event) {
        const skillName = event.currentTarget?.dataset?.name;
        if (!skillName) return;

        this.dispatchEvent(
            new CustomEvent('tagclick', {
                detail: { name: skillName },
                bubbles: true,
                composed: true
            })
        );
    }
}