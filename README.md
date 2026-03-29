# sf-workfolio

A personal developer portfolio built entirely on Salesforce, showcasing work experience, projects, skills, and certifications through Lightning Web Components. Includes a lead capture contact form and a job application tracker.

## Tech Stack

- Salesforce DX (API v65.0)
- Lightning Web Components (LWC)
- Apex
- Platform Events
- Custom Metadata Types
- Flows
- Jest (LWC unit testing)
- ESLint + Prettier + Husky (code quality)

## Project Structure

```
force-app/main/default/
  classes/          Apex controllers + tests
  lwc/              6 LWC components
  objects/          7 custom objects + modified standard objects
  flows/            Lead submission automation
  staticresources/  Portfolio assets (images, icons)
  customMetadata/   Email notification config
  permissionsets/   Access control
```

## Custom Objects

| Object | Purpose |
|--------|---------|
| Portfolio\_\_c | Main portfolio record (name, designation, intro, social URLs) |
| Portfolio\_Setting\_\_c | Theme configuration (colors, borders, shadows) |
| WorkExperience\_\_c | Job history entries |
| Experience\_Bullet\_\_c | Bullet points under work experience / projects |
| Project\_\_c | Projects linked to work experiences |
| Skill\_\_c | Hierarchical skill tree (self-referential via Parent\_Skill\_\_c) |
| Job\_Application\_\_c | Job application tracker with stage pipeline |

## LWC Components

| Component | Description |
|-----------|-------------|
| portfolio | Root shell -- navigation, theme loading, section routing |
| portfolioHome | Hero section with profile, social links, certifications, contact form |
| portfolioContact | Contact form (publishes Lead\_Submission\_\_e platform event) + contact details |
| portfolioExperience | Work experience timeline with nested projects and experience bullets |
| portfolioSkills | Hierarchical skill tree with collapsible categories |
| skillNode | Recursive child component for nested skill rendering |

## Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/sf-workfolio.git
   cd sf-workfolio
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. Authorize a Salesforce org:

   ```bash
   sf org login web -a my-org
   ```

4. Deploy source:

   ```bash
   sf project deploy start
   ```

5. Create required data:
   - 1 **Portfolio\_\_c** record (your name, designation, intro text, social URLs)
   - 1 **Portfolio\_Setting\_\_c** record (theme colors, or leave blank for defaults)
   - **WorkExperience\_\_c** records with related **Project\_\_c** and **Experience\_Bullet\_\_c** records
   - **Skill\_\_c** records (use Parent\_Skill\_\_c for hierarchy)

6. Upload static resources:
   - **PortfolioAssets** -- profile picture, social icons, certification logos

7. Configure lead notifications:
   - Create a **Portfolio\_Leads** queue
   - Create **Notification\_Config\_\_mdt** custom metadata records (email templates, recipients)

## Scripts

| Command | Description |
|---------|-------------|
| `npm test` | Run LWC Jest tests |
| `npm run test:unit:watch` | Jest watch mode |
| `npm run test:unit:coverage` | Jest with coverage report |
| `npm run prettier` | Format all code |
| `npm run prettier:verify` | Check formatting without writing |

## License

MIT

## Author

John Carlo Red
