# sf-workfolio

A personal developer portfolio built entirely on Salesforce, showcasing work experience, projects, skills, and certifications through Lightning Web Components. Includes a lead capture contact form and a job application tracker.

## Tech Stack

- Salesforce DX (API v65.0)
- Lightning Web Components (LWC)
- Apex
- Platform Events
- Custom Metadata Types
- Flows
- ESLint + Prettier + Husky (code quality)

## Project Structure

```
force-app/main/default/
  classes/          Apex controllers + tests
  lwc/              7 LWC components
  objects/          12 custom and standard object folders
  flows/            Lead submission and follow-up automation
  staticresources/  Portfolio assets (images, icons)
  customMetadata/   Email notification config
  permissionsets/   Access control
```

## Custom Objects

| Object                 | Purpose                                                          |
| ---------------------- | ---------------------------------------------------------------- |
| Portfolio\_\_c         | Main portfolio record (name, designation, intro, social URLs)    |
| Portfolio_Setting\_\_c | Theme configuration (colors, borders, shadows)                   |
| WorkExperience\_\_c    | Job history entries                                              |
| Experience_Bullet\_\_c | Bullet points under work experience / projects                   |
| Project\_\_c           | Projects linked to work experiences                              |
| Skill\_\_c             | Hierarchical skill tree (self-referential via Parent_Skill\_\_c) |
| Certification\_\_c     | Data-driven certification badges shown on the portfolio          |
| Personal_Project\_\_c  | Portfolio project cards with descriptions, links, and demos      |
| Project_Image\_\_c     | Ordered image gallery records for personal projects              |
| Lead_Submission\_\_e   | Platform event used for async guest-safe lead submission         |
| Job_Application\_\_c   | Job application tracker with stage pipeline                      |
| Lead                   | Standard object extended for email and follow-up tracking        |

## LWC Components

| Component           | Description                                                                    |
| ------------------- | ------------------------------------------------------------------------------ |
| portfolio           | Root shell -- navigation, theme loading, section routing                       |
| portfolioHome       | Hero section with profile, social links, certifications, contact form          |
| portfolioContact    | Contact form (publishes Lead_Submission\_\_e platform event) + contact details |
| portfolioExperience | Work experience timeline with nested projects and experience bullets           |
| portfolioProjects   | Personal projects with video embeds and image lightbox gallery                 |
| portfolioSkills     | Hierarchical skill tree with collapsible categories                            |
| skillNode           | Recursive child component for nested skill rendering                           |

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
    - 1 **Portfolio_Setting\_\_c** record (theme colors, or leave blank for defaults)
    - **WorkExperience\_\_c** records with related **Project\_\_c** and **Experience_Bullet\_\_c** records
    - **Personal_Project\_\_c** records with related **Project_Image\_\_c** gallery records
    - **Certification\_\_c** records for badge display
    - **Skill\_\_c** records (use Parent_Skill\_\_c for hierarchy)

6. Upload static resources:
    - **PortfolioAssets** -- profile picture, social icons, certification logos

7. Configure lead notifications:
    - Create a **Portfolio_Leads** queue
    - Create **Notification_Config\_\_mdt** custom metadata records (email templates, recipients)

## Scripts

| Command                   | Description                         |
| ------------------------- | ----------------------------------- |
| `npm run lint`            | Lint JavaScript in Aura/LWC bundles |
| `npm run prettier`        | Format all code                     |
| `npm run prettier:verify` | Check formatting without writing    |

## License

MIT

## Author

John Carlo Red
