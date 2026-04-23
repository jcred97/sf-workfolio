import { LightningElement, api, wire } from 'lwc';
import getSkills from '@salesforce/apex/PortfolioController.getSkills';

const SALESFORCE_LABELS = ['salesforce'];
const DELIVERY_LABELS = ['devops', 'delivery', 'deployment'];
const TOOLING_LABELS = ['tools', 'tooling'];
const DEFAULT_PRIORITY = Number.MAX_SAFE_INTEGER;

export default class PortfolioSkills extends LightningElement {
    @api recordId;

    treeData = [];
    isLoading = true;
    hasError = false;
    errorMessage = '';

    get showContent() {
        return !this.isLoading && !this.hasError;
    }

    @wire(getSkills, { portfolioId: '$recordId' })
    wiredSkills({ data, error }) {
        if (!this.recordId || (data === undefined && !error)) return;

        this.isLoading = false;

        if (data) {
            this.hasError = false;
            this.errorMessage = '';

            const tree = this.buildTree(data);
            const curatedTree = this.curateSalesforceTree(tree);
            this.treeData = this.initializeNodes(curatedTree);
        } else if (error) {
            this.hasError = true;
            this.errorMessage =
                error?.body?.message ||
                error?.message ||
                'Unable to load skills. Please try again later.';
            this.treeData = [];
            console.error(error);
        }
    }

    initializeNodes(nodes) {
        return [...nodes]
            .sort((leftNode, rightNode) =>
                this.compareNodes(leftNode, rightNode)
            )
            .map((node) => {
                const children = this.normalizeChildren(node.children || []);

                return this.decorateNode({
                    ...node,
                    children: this.initializeNodes(children)
                });
            });
    }

    compareNodes(leftNode, rightNode) {
        const leftPriority = this.normalizePriority(leftNode.Priority__c);
        const rightPriority = this.normalizePriority(rightNode.Priority__c);

        if (leftPriority !== rightPriority) {
            return leftPriority - rightPriority;
        }

        return (leftNode.Name || '').localeCompare(rightNode.Name || '');
    }

    normalizePriority(priority) {
        const parsedPriority = Number(priority);

        return Number.isFinite(parsedPriority)
            ? parsedPriority
            : DEFAULT_PRIORITY;
    }

    decorateNode(node) {
        const children = node.children || [];
        const hasChildren = children.length > 0;
        const allChildrenAreLeaf =
            hasChildren &&
            children.every(
                (child) => !child.children || child.children.length === 0
            );

        return {
            ...node,
            children,
            hasChildren,
            allChildrenAreLeaf,
            cardClass: node.Is_Full_Width__c
                ? 'skill-card skill-card--full'
                : 'skill-card'
        };
    }

    normalizeChildren(children) {
        if (children.length !== 1 || children[0].children?.length) {
            return children;
        }

        const onlyChild = children[0];
        const names = this.splitMalformedSkillNames(onlyChild.Name);

        if (!names) {
            return children;
        }

        return names.map((name, index) => ({
            Id: `${onlyChild.Id}-${index}`,
            Name: name,
            children: []
        }));
    }

    splitMalformedSkillNames(rawName) {
        if (!rawName) return null;

        if (rawName.includes(',')) {
            return rawName
                .split(',')
                .map((name) => name.trim())
                .filter(Boolean);
        }

        if (rawName.length > 10 && !rawName.includes(' ')) {
            const splitNames = rawName.match(/[A-Z][a-z0-9+#&]+/g);
            if (splitNames && splitNames.length > 1) {
                return splitNames;
            }
        }

        return null;
    }

    curateSalesforceTree(roots) {
        const salesforceNode = this.findNodeByLabels(roots, SALESFORCE_LABELS);
        const devopsNode = roots.find((node) =>
            this.includesAnyLabel(node.Name, DELIVERY_LABELS)
        );
        const toolsNode = roots.find((node) =>
            this.includesAnyLabel(node.Name, TOOLING_LABELS)
        );

        const curated = [];

        if (salesforceNode?.children?.length) {
            curated.push({
                ...salesforceNode,
                Name: 'Salesforce Platform',
                Is_Full_Width__c: true
            });
        }

        if (devopsNode) {
            const toolingChildren =
                toolsNode && toolsNode.Id !== devopsNode.Id
                    ? toolsNode.children || []
                    : [];
            const mergedChildren = [
                ...(devopsNode.children || []),
                ...toolingChildren
            ];

            curated.push({
                ...devopsNode,
                Name: 'Delivery, Deployment & Tooling',
                Is_Full_Width__c: true,
                children: mergedChildren
            });
        }

        if (toolsNode && !devopsNode) {
            curated.push({
                ...toolsNode,
                Name: 'Delivery, Deployment & Tooling',
                Is_Full_Width__c: true
            });
        }

        return curated.length ? curated : roots;
    }

    findNodeByLabels(nodes, labels) {
        for (const node of nodes) {
            if (this.includesAnyLabel(node.Name, labels)) {
                return node;
            }

            if (node.children?.length) {
                const match = this.findNodeByLabels(node.children, labels);
                if (match) {
                    return match;
                }
            }
        }

        return null;
    }

    includesAnyLabel(value, labels) {
        const normalizedValue = value?.toLowerCase() || '';

        return labels.some((label) => normalizedValue.includes(label));
    }

    buildTree(data) {
        const map = new Map();
        const roots = [];

        data.forEach((skill) => {
            map.set(skill.Id, { ...skill, children: [] });
        });

        data.forEach((skill) => {
            const node = map.get(skill.Id);

            if (skill.Parent_Skill__c) {
                map.get(skill.Parent_Skill__c)?.children.push(node);
            } else {
                roots.push(node);
            }
        });

        return roots;
    }
}
