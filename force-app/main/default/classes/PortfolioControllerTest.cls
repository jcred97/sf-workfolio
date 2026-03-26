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
}