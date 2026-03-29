@IsTest
private class PortfolioControllerTest {

    @testSetup
    static void setupData() {
        // Create Portfolio (if required lookup)
        Portfolio__c portfolio = new Portfolio__c(
                Name = 'Test Portfolio',
                FullName__c = 'Test Portfolio'
            );
        insert portfolio;

        // Create Skills
        List<Skill__c> skills = new List<Skill__c>{
            new Skill__c(
                Name = 'Apex',
                Priority__c = 1,
                Portfolio__c = portfolio.Id
            ),
            new Skill__c(
                Name = 'LWC',
                Priority__c = 2,
                Portfolio__c = portfolio.Id
            )
        };
        insert skills;

        // Create Work Experience
        WorkExperience__c workExp = new WorkExperience__c(
            CompanyName__c = 'Test Company',
            Role__c = 'Software Engineer',
            JobStartDate__c = Date.today().addYears(-2),
            JobEndDate__c = Date.today(),
            WorkLocation__c = 'Remote',
            IsCurrent__c = false,
            Portfolio__c = portfolio.Id
        );
        insert workExp;

        // Create Project
        Project__c project = new Project__c(
            Name = 'Test Project',
            Tech_Stack__c = 'Apex;LWC',
            Display_Order__c = 1,
            Work_Experience__c = workExp.Id
        );
        insert project;

        // Create Experience Bullet
        Experience_Bullet__c bullet = new Experience_Bullet__c(
            Bullet_Text__c = 'Built a cool feature',
            Display_Order__c = 1,
            Include_In_Portfolio__c = true,
            Project__c = project.Id,
            Work_Experience__c = workExp.Id
        );
        insert bullet;

        // Create Personal Project
        Personal_Project__c personalProj = new Personal_Project__c(
            Name = 'My Side Project',
            Description__c = 'A cool side project with a demo',
            Tech_Stack__c = 'LWC, Node.js',
            YouTube_URL__c = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            GitHub_URL__c = 'https://github.com/example/project',
            Display_Order__c = 1,
            Portfolio__c = portfolio.Id
        );
        insert personalProj;

        // Create Certification
        Certification__c cert = new Certification__c(
            Name = 'Platform Developer 1',
            Image_URL__c = 'https://example.com/pd1.png',
            Display_Order__c = 1,
            Portfolio__c = portfolio.Id
        );
        insert cert;

        // Create Portfolio Settings
        Portfolio_Setting__c setting = new Portfolio_Setting__c(
            Primary_Color__c = '#000000',
            Background_Color__c = '#FFFFFF',
            Card_Background__c = '#F5F5F5',
            Border_Color__c = '#CCCCCC',
            Primary_Text_Color__c = '#111111',
            Secondary_Text_Color__c = '#222222',
            Muted_Text_Color__c = '#999999'
        );
        insert setting;
    }

    @IsTest
    static void testSubmitLead_Success() {
        Test.startTest();

        PortfolioController.submitLead(
            'John',
            'Doe',
            'john@test.com',
            'Hello there'
        );

        Test.stopTest();

        // Since this uses Platform Event, we verify no exception was thrown
        System.assert(true, 'Lead submission executed successfully');
    }

    @IsTest
    static void testSubmitLead_BlankEmail() {
        Test.startTest();

        PortfolioController.submitLead(
            'Jane',
            'Doe',
            null,
            'No email case'
        );

        Test.stopTest();

        System.assert(true, 'Handled blank email correctly');
    }

    @IsTest
    static void testGetSkills() {
        Portfolio__c portfolio = [SELECT Id FROM Portfolio__c LIMIT 1];

        Test.startTest();
        List<Skill__c> result = PortfolioController.getSkills(portfolio.Id);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return 2 skills');
        System.assertEquals('Apex', result[0].Name);
    }

    @IsTest
    static void testGetPortfolioSettings() {
        Test.startTest();
        Portfolio_Setting__c setting = PortfolioController.getPortfolioSettings();
        Test.stopTest();

        System.assertNotEquals(null, setting);
        System.assertEquals('#000000', setting.Primary_Color__c);
    }

    @IsTest
    static void testSubmitLead_ExceptionHandling() {
        PortfolioController.forceException = true;

        try {
            Test.startTest();
            PortfolioController.submitLead(
                'Error',
                'Test',
                'error@test.com',
                'Trigger exception'
            );
            Test.stopTest();

            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
            System.assert(true, 'Exception handled correctly');
        }

        PortfolioController.forceException = false;
    }

    @IsTest
    static void testSubmitLead_PublishFailure() {
        PortfolioController.forcePublishFailure = true;

        try {
            Test.startTest();
            PortfolioController.submitLead(
                'Fail',
                'Case',
                'fail@test.com',
                'Force publish failure'
            );
            Test.stopTest();

            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage());
        }

        PortfolioController.forcePublishFailure = false;
    }

    @IsTest
    static void testGetWorkExperiences() {
        Portfolio__c portfolio = [SELECT Id FROM Portfolio__c LIMIT 1];

        Test.startTest();
        List<WorkExperience__c> result = PortfolioController.getWorkExperiences(portfolio.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return 1 work experience');
        System.assertEquals('Test Company', result[0].CompanyName__c);
        System.assertEquals(1, result[0].Experience_Bullets__r.size(), 'Should return 1 experience bullet');
        System.assertEquals('Built a cool feature', result[0].Experience_Bullets__r[0].Bullet_Text__c);
        System.assertEquals(1, result[0].Projects__r.size(), 'Should return 1 project');
        System.assertEquals('Test Project', result[0].Projects__r[0].Name);
    }

    @IsTest
    static void testGetPersonalProjects() {
        Portfolio__c portfolio = [SELECT Id FROM Portfolio__c LIMIT 1];

        Test.startTest();
        List<Personal_Project__c> result = PortfolioController.getPersonalProjects(portfolio.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return 1 personal project');
        System.assertEquals('My Side Project', result[0].Name);
        System.assertEquals('LWC, Node.js', result[0].Tech_Stack__c);
        System.assertNotEquals(null, result[0].YouTube_URL__c);
        System.assertNotEquals(null, result[0].GitHub_URL__c);
    }

    @IsTest
    static void testGetCertifications() {
        Portfolio__c portfolio = [SELECT Id FROM Portfolio__c LIMIT 1];

        Test.startTest();
        List<Certification__c> result = PortfolioController.getCertifications(portfolio.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return 1 certification');
        System.assertEquals('Platform Developer 1', result[0].Name);
        System.assertEquals('https://example.com/pd1.png', result[0].Image_URL__c);
    }

    @IsTest
    static void testGetProjects() {
        Portfolio__c portfolio = [SELECT Id FROM Portfolio__c LIMIT 1];

        Test.startTest();
        List<Project__c> result = PortfolioController.getProjects(portfolio.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return 1 project');
        System.assertEquals('Test Project', result[0].Name);
        System.assertEquals('Test Company', result[0].Work_Experience__r.CompanyName__c);
    }
}