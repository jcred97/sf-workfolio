import { LightningElement, api } from 'lwc';

export default class SkillNode extends LightningElement {
    @api node;

    get hasChildren() {
        return (this.node?.children || []).length > 0;
    }

    get allChildrenAreLeaf() {
        return (
            this.hasChildren &&
            this.node.children.every(
                (child) => !child.children || child.children.length === 0
            )
        );
    }
}
