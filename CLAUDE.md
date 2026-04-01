# SF-Workfolio

Salesforce DX portfolio project — a data-driven personal portfolio site built on Experience Cloud with Lightning Web Components.

## Project Structure

```
force-app/main/default/
  classes/          # Apex controllers + tests
  flows/            # Platform Event & Scheduled flows
  lwc/              # 7 Lightning Web Components
  objects/          # 12 custom objects (including Lead extensions)
  layouts/          # Page layouts for all objects
  permissionsets/   # 2 permission sets (admin + guest)
manifest/
  package.xml       # Deployment manifest
```

## Tech Stack

- **API Version**: 65.0 (Flows at 66.0)
- **LWC**: 7 components — portfolio (shell), portfolioHome, portfolioContact, portfolioExperience, portfolioProjects, portfolioSkills, skillNode
- **Apex**: PortfolioController (data queries + lead submission), PortfolioLeadEmailAction (invocable email with CMT config)
- **Flows**: PE_Lead_Upsert_Portfolio_Submission (Platform Event-driven), Schedule_Lead_Follow_Up (daily scheduled)
- **Platform Events**: Lead_Submission__e for async lead creation from guest form
- **Custom Metadata**: Notification_Config__mdt for email configuration (Lead_Create, Lead_Update, Lead_Follow_Up)

## Data Model

- **Portfolio__c** — root record (profile info, social links, career start date); has Lookup to Portfolio_Setting__c for theme switching
- **Portfolio_Setting__c** — theme/color configuration (15 CSS custom property fields: Primary_Color__c, Secondary_Color__c, Accent_Color__c, Background_Color__c, Card_Background__c, Border_Color__c, Hover_Border__c, Primary_Text_Color__c, Secondary_Text_Color__c, Muted_Text_Color__c, Card_Shadow__c, Card_Radius__c, Section_Spacing__c, Font_Heading__c, Font_Body__c); multiple records can exist, swap theme by changing Portfolio__c.Portfolio_Setting__c lookup
- **WorkExperience__c** → **Project__c** → **Experience_Bullet__c** (3-level hierarchy)
- **Skill__c** — self-referential hierarchy via Parent_Skill__c; Is_Full_Width__c controls card width
- **Certification__c** — data-driven certifications (Image_URL__c, Display_Order__c)
- **Personal_Project__c** → **Project_Image__c** (projects with image gallery)
- **Lead** — extended with Email_Status__c, Email_Log__c, Follow_Up_Date__c, Follow_Up_Sent__c, Follow_Up_Log__c

## Key Patterns

### LWC
- All data fetched via `@wire` adapters calling `@AuraEnabled(cacheable=true)` Apex methods
- Error states: `hasError`/`errorMessage` pattern across all components
- Theme applied via `template.host.style.setProperty()` CSS custom properties; loaded from Portfolio_Setting__c via Portfolio__c lookup using `getPortfolioSettings(portfolioId)`
- All LWC CSS uses `color-mix(in srgb, var(--primary-color) X%, transparent)` for theme-aware opacity colors — no hardcoded color values except `:host` fallback defaults in portfolio.css
- Image gallery: compact thumbnail strip (64x48px) with full lightbox overlay (prev/next arrows, keyboard navigation, image counter)
- Hamburger menu for mobile navigation (slide-in drawer from right)
- YouTube URL parsing supports watch, shortened, and embed formats
- Iframes use `allow="fullscreen"` (bare `allowfullscreen` attribute doesn't work in LWC)
- `aria-live="polite"` for accessibility on dynamic content panels

### Apex
- PortfolioController: all methods take `portfolioId` parameter, return cached queries; `getPortfolioSettings` queries through Portfolio__c → Portfolio_Setting__r relationship; `getPersonalProjects` includes Project_Images__r subquery
- PortfolioLeadEmailAction: invocable method with emailType ('create', 'update', 'follow_up'), config from Notification_Config__mdt, OrgWideEmailAddress resolution, setSaveAsActivity(true)
- Test classes use @TestSetup for shared data; PortfolioLeadEmailAction has test seams (TEST_SKIP_SET_OWEA, TEST_FORCE_PREP_EXCEPTION, etc.)

### Flows
- PE flow: Platform Event trigger → Lead upsert → notification → email → task creation; auto-sets Follow_Up_Date__c to +1 day via formula
- Scheduled flow: daily at 8 AM → queries leads (Follow_Up_Date__c <= TODAY, Follow_Up_Sent__c = false, Status = "Open - Not Contacted") → creates task → sends follow-up email → logs to Follow_Up_Log__c → marks Follow_Up_Sent__c = true

### Permission Sets
- **Workfolio_All_Access**: full CRUD on all custom objects, editable fields
- **Workfolio_Guest_Site_User_Permission**: read-only on data objects, create on Lead_Submission__e

## Common Commands

```bash
# Deploy to org
sf project deploy start --manifest manifest/package.xml --target-org <alias>

# Run tests
sf apex run test --test-level RunLocalTests --target-org <alias>

# Lint
npm run lint

# Format
npm run prettier
```

## Important Notes

- Flow XML requires elements of the same type to be grouped together (e.g., all `recordCreates` adjacent) — splitting them causes deployment errors
- SharingRules section in package.xml should only list objects that have actual sharing rule metadata files; otherwise deployment fails
- Lead fields are on the standard Lead object — no custom object needed
- Guest users access portfolio data through the Experience Cloud site with the guest permission set
- CSP Trusted Sites: Imgur and Imgur_Images (i.imgur.com) for external project images — deployable via cspTrustedSites metadata
- Master-Detail relationships (e.g., Project_Image__c → Personal_Project__c) use ControlledByParent sharing and do not need FLS in permission sets or SharingRules entries
- `renderedCallback` timing: `recordId` may not be available on first render — guard with `&& this.recordId` before calling Apex
