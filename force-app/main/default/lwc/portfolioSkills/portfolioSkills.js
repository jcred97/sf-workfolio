import { LightningElement, api, wire } from 'lwc';
import getSkills from '@salesforce/apex/PortfolioController.getSkills';

export default class PortfolioSkills extends LightningElement {
    @api recordId;
    treeData = [];

    @wire(getSkills, { portfolioId: '$recordId' })
    wiredSkills({ data, error }) {
        if (data) {
            const tree = this.buildTree(data);
            this.treeData = this.initializeTree(tree);
        } else if (error) {
            console.error(error);
        }
    }

    toggleCard(event) {
        const id = event?.currentTarget?.dataset?.id;
        if (!id) return;

        this.treeData = this.treeData.map(item => {
            const isOpen = item.Id === id ? !item.isOpen : item.isOpen;

            return {
                ...item,
                isOpen,
                icon: isOpen ? '−' : '+',
                cssClass: item.Name === 'CRM' && isOpen
                    ? 'skill-card full-width'
                    : 'skill-card'
            };
        });
    }

    // 🔥 FULL INIT (OPEN BY DEFAULT + CRM WIDTH LOGIC)
    initializeTree(nodes) {
        return nodes.map(node => {
            let children = node.children
                ? this.initializeTree(node.children)
                : [];

            // Handle bad data (combined strings)
            if (children.length === 1 && !children[0].children?.length) {
                const raw = children[0].Name;

                if (raw && raw.length > 10 && !raw.includes(' ')) {
                    const split = raw.match(/[A-Z][a-z]+/g);

                    if (split && split.length > 1) {
                        children = split.map((name, i) => ({
                            Id: `${children[0].Id}-${i}`,
                            Name: name,
                            children: []
                        }));
                    }
                }

                if (raw && raw.includes(',')) {
                    children = raw.split(',').map((name, i) => ({
                        Id: `${children[0].Id}-${i}`,
                        Name: name.trim(),
                        children: []
                    }));
                }
            }

            const isOpen = true;

            return {
                ...node,
                isOpen,
                icon: isOpen ? '−' : '+',
                children,
                cssClass: node.Name === 'CRM' && isOpen
                    ? 'skill-card full-width'
                    : 'skill-card',
                allChildrenAreLeaf: children.every(
                    child => !child.children || child.children.length === 0
                )
            };
        });
    }

    buildTree(data) {
        const map = new Map();
        const roots = [];

        data.forEach(skill => {
            map.set(skill.Id, { ...skill, children: [] });
        });

        data.forEach(skill => {
            if (skill.Parent_Skill__c) {
                map.get(skill.Parent_Skill__c)?.children.push(map.get(skill.Id));
            } else {
                roots.push(map.get(skill.Id));
            }
        });

        return roots;
    }

    handleToggle(event) {
        const id = event.detail?.id;
        if (!id) return;

        this.treeData = this.toggleNode(this.treeData, id);
    }

    toggleNode(nodes, id) {
        return nodes.map(node => {
            if (node.Id === id) {
                const isOpen = !node.isOpen;

                return {
                    ...node,
                    isOpen,
                    icon: isOpen ? '−' : '+'
                };
            }

            if (node.children && node.children.length > 0) {
                return {
                    ...node,
                    children: this.toggleNode(node.children, id)
                };
            }

            return node;
        });
    }

    handleTagClick(event) {
        const skillName = event.detail?.name;
        if (!skillName) return;

        console.log('Clicked skill:', skillName);
    }
}