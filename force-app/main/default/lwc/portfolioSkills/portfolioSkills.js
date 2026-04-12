import { LightningElement, api, wire } from 'lwc';
import getSkills from '@salesforce/apex/PortfolioController.getSkills';

export default class PortfolioSkills extends LightningElement {
    @api recordId;
    treeData = [];

    /* =========================================================
       WIRE
    ========================================================= */
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
            this.treeData = this.initializeTree(tree);

            // Set initial open heights - no animation on first load, just snap open
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            requestAnimationFrame(() => {
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                requestAnimationFrame(() => {
                    this.template
                        .querySelectorAll('.card-body.open')
                        .forEach((el) => {
                            el.style.height = 'auto';
                            el.style.overflow = 'visible';
                        });
                });
            });
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

    /* =========================================================
       TOP-LEVEL TOGGLE (card open/close)
    ========================================================= */
    toggleCard(event) {
        if (event.type === 'keydown') {
            if (event.key !== 'Enter' && event.key !== ' ') return;
            if (event.key === ' ') event.preventDefault();
        }

        const id = event?.currentTarget?.dataset?.id;
        if (!id) return;

        this.treeData = this.treeData.map((item) => {
            const isOpen = item.Id === id ? !item.isOpen : item.isOpen;

            return {
                ...item,
                isOpen,
                icon: isOpen ? '-' : '+',
                bodyClass: isOpen ? 'card-body open' : 'card-body',
                cssClass:
                    item.Is_Full_Width__c && isOpen
                        ? 'skill-card full-width'
                        : 'skill-card'
            };
        });

        // Run scrollHeight animation after LWC re-renders
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        requestAnimationFrame(() => {
            this.animateCards([id]);
        });
    }

    /* =========================================================
       SCROLL HEIGHT ANIMATION
       - Opening: set pixel height so transition has a to-value
       - Closing: pin current height first (from-value), then
         animate to 0 in the next frame
       - overflow stays hidden throughout; only flips to visible
         after transitionend so content never bleeds during expand
    ========================================================= */
    animateCards(ids) {
        const cards = ids?.length
            ? ids
                  .map((id) =>
                      this.template.querySelector(`.card-body[data-id="${id}"]`)
                  )
                  .filter(Boolean)
            : this.template.querySelectorAll('.card-body');

        cards.forEach((el) => {
            // Remove any leftover transitionend listener before re-attaching
            if (el._onTransitionEnd) {
                el.removeEventListener('transitionend', el._onTransitionEnd);
            }

            if (el.classList.contains('open')) {
                el.style.overflow = 'hidden';
                el.style.height = el.scrollHeight + 'px';

                // Only unlock overflow once the expand animation is fully done
                el._onTransitionEnd = () => {
                    el.style.overflow = 'visible';
                    el.style.height = 'auto';
                    el.removeEventListener(
                        'transitionend',
                        el._onTransitionEnd
                    );
                };
                el.addEventListener('transitionend', el._onTransitionEnd);
            } else {
                // Lock overflow before collapsing so nothing bleeds during close
                el.style.overflow = 'hidden';
                // Pin to current pixel height so CSS has a from-value
                el.style.height = el.scrollHeight + 'px';

                // eslint-disable-next-line @lwc/lwc/no-async-operation
                requestAnimationFrame(() => {
                    el.style.height = '0px';
                });
            }
        });
    }

    /* =========================================================
       DEEP TOGGLE (child node open/close via event bubble)
       bodyClass is passed down so c-skill-node can drive its
       own scrollHeight animation with the same pattern
    ========================================================= */
    handleToggle(event) {
        const id = event.detail?.id;
        if (!id) return;

        this.treeData = this.toggleNode(this.treeData, id);
    }

    toggleNode(nodes, id) {
        return nodes.map((node) => {
            if (node.Id === id) {
                const isOpen = !node.isOpen;
                return {
                    ...node,
                    isOpen,
                    icon: isOpen ? '-' : '+',
                    bodyClass: isOpen ? 'card-body open' : 'card-body'
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

    /* =========================================================
       TREE INIT
       - Opens all nodes by default
       - Sets full-width class via Is_Full_Width__c field
       - Pre-computes hasChildren + allChildrenAreLeaf flags
       - Fixes bad data (camelCase concat OR comma-separated strings)
         using else-if so only one split strategy runs per node
    ========================================================= */
    initializeTree(nodes) {
        return nodes.map((node) => {
            let children = node.children
                ? this.initializeTree(node.children)
                : [];

            // Bad data fix - only one branch runs per node
            if (children.length === 1 && !children[0].children?.length) {
                const raw = children[0].Name;
                const originalId = children[0].Id;

                if (raw && raw.length > 10 && !raw.includes(' ')) {
                    // CamelCase concatenated string e.g. "ApexVisualforce"
                    const split = raw.match(/[A-Z][a-z]+/g);
                    if (split && split.length > 1) {
                        children = split.map((name, i) => ({
                            Id: `${originalId}-${i}`,
                            Name: name,
                            children: []
                        }));
                    }
                } else if (raw && raw.includes(',')) {
                    // Comma-separated string e.g. "Apex, LWC, Flows"
                    children = raw.split(',').map((name, i) => ({
                        Id: `${originalId}-${i}`,
                        Name: name.trim(),
                        children: []
                    }));
                }
            }

            const isOpen = true;
            const hasChildren = children.length > 0;
            const allChildrenAreLeaf = children.every(
                (child) => !child.children || child.children.length === 0
            );

            return {
                ...node,
                isOpen,
                icon: '-',
                children,
                hasChildren,
                allChildrenAreLeaf,
                bodyClass: 'card-body open',
                cssClass:
                    node.Is_Full_Width__c && isOpen
                        ? 'skill-card full-width'
                        : 'skill-card'
            };
        });
    }

    /* =========================================================
       BUILD TREE
       O(n) parent-child linking via Map
    ========================================================= */
    buildTree(data) {
        const map = new Map();
        const roots = [];

        data.forEach((skill) => {
            map.set(skill.Id, { ...skill, children: [] });
        });

        data.forEach((skill) => {
            if (skill.Parent_Skill__c) {
                map.get(skill.Parent_Skill__c)?.children.push(
                    map.get(skill.Id)
                );
            } else {
                roots.push(map.get(skill.Id));
            }
        });

        return roots;
    }
}
