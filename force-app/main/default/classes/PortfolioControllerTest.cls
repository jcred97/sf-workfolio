@IsTest
private class PortfolioControllerTest {

    private static String uniqueEmail(String prefix) {
        return prefix + Datetime.now().getTime() + '@test.com';
    }

    @IsTest
    static void testSuccess() {
        String email = uniqueEmail('success');

        Test.startTest();
        PortfolioController.sendContactMessage('John', 'Doe', email, 'Hello');
        Test.stopTest();

        Lead lead = [
            SELECT FirstName, LastName, Email_Status__c
            FROM Lead
            WHERE Email = :email
            LIMIT 1
        ];

        System.assertEquals('John', lead.FirstName);
        System.assertEquals('Doe', lead.LastName);
        System.assertEquals('Sent', lead.Email_Status__c);
    }

    @IsTest
    static void testBlankFields() {
        Boolean exceptionThrown = false;

        try {
            PortfolioController.sendContactMessage('', '', '', '');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown, 'Expected AuraHandledException to be thrown');
    }

    @IsTest
    static void testEmailFailure() {
        String email = uniqueEmail('fail');

        PortfolioController.forceEmailFailure = true;

        Test.startTest();
        PortfolioController.sendContactMessage('Jane', 'Doe', email, 'Failure');
        Test.stopTest();

        Lead lead = [
            SELECT Email_Status__c
            FROM Lead
            WHERE Email = :email
            LIMIT 1
        ];

        System.assertEquals('Failed', lead.Email_Status__c);

        PortfolioController.forceEmailFailure = false;
    }

    @IsTest
    static void testExceptionPath() {
        String email = uniqueEmail('exception');

        PortfolioController.forceException = true;

        Test.startTest();
        PortfolioController.sendContactMessage('Error', 'Case', email, 'Exception');
        Test.stopTest();

        Lead lead = [
            SELECT Email_Status__c, Email_Error__c
            FROM Lead
            WHERE Email = :email
            LIMIT 1
        ];

        System.assertEquals('Failed', lead.Email_Status__c);
        System.assertNotEquals(null, lead.Email_Error__c);

        PortfolioController.forceException = false;
    }

    @IsTest
    static void testNoEmailResult() {
        String email = uniqueEmail('noresult');

        PortfolioController.forceNoEmailResult = true;

        Test.startTest();
        PortfolioController.sendContactMessage('Edge', 'Case', email, 'Test');
        Test.stopTest();

        Lead lead = [
            SELECT Email_Status__c
            FROM Lead
            WHERE Email = :email
            LIMIT 1
        ];

        System.assertEquals('Failed', lead.Email_Status__c);

        PortfolioController.forceNoEmailResult = false;
    }

    @IsTest
    static void testGetSkills() {
        // Create Portfolio
        Portfolio__c portfolio = new Portfolio__c(
            Name = 'Test Portfolio',
            FullName__c = 'Test Test'
        );
        insert portfolio;

        // Create Skills
        Skill__c skill1 = new Skill__c(
            Name = 'Apex',
            Portfolio__c = portfolio.Id,
            Priority__c = 1
        );

        Skill__c skill2 = new Skill__c(
            Name = 'LWC',
            Portfolio__c = portfolio.Id,
            Priority__c = 2
        );

        insert new List<Skill__c>{ skill1, skill2 };

        Test.startTest();
        List<Skill__c> result = PortfolioController.getSkills(portfolio.Id);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return 2 skills');
        System.assertEquals('Apex', result[0].Name);
        System.assertEquals('LWC', result[1].Name);
    }
}