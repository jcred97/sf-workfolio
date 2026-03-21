@IsTest
private class PortfolioControllerTest {

    // =========================================
    // TEST: Create New Lead
    // =========================================
    @IsTest
    static void testCreateNewLead() {

        Test.startTest();

        PortfolioController.submitContact('John', 'Doe', 'john@test.com', 'Hello, this is a new inquiry');

        Test.stopTest();

        Lead createdLead = [
            SELECT Id, FirstName, LastName, Email, Message__c
            FROM Lead
            WHERE Email = 'john@test.com'
            LIMIT 1
        ];

        System.assertNotEquals(null, createdLead);
        System.assertEquals('John', createdLead.FirstName);
        System.assertEquals('Doe', createdLead.LastName);
        System.assertEquals('Hello, this is a new inquiry', createdLead.Message__c);
    }


    // =========================================
    // TEST: Update Existing Lead
    // =========================================
    @IsTest
    static void testUpdateExistingLead() {

        Lead existing = new Lead(
            FirstName = 'Old',
            LastName = 'Name',
            Email = 'existing@test.com',
            Company = 'Test Co',
            Description = 'Old Message',
            Message__c = 'New Message'
        );
        insert existing;

        Test.startTest();

        PortfolioController.submitContact('New', 'Name', 'existing@test.com', 'New Message');

        Test.stopTest();

        Lead updatedLead = [
            SELECT Id, FirstName, LastName, Description, Message__c
            FROM Lead
            WHERE Email = 'existing@test.com'
            LIMIT 1
        ];

        System.assertEquals('New', updatedLead.FirstName);
        System.assertEquals('Name', updatedLead.LastName);

        System.assert(updatedLead.Description.contains('Old Message'), 'Description should contain previous message');

        System.assertEquals( 'New Message', updatedLead.Message__c, 'Message__c should store latest message');
    }


    // =========================================
    // TEST: Invalid Input (Missing Fields)
    // =========================================
    @IsTest
    static void testMissingFields() {

        Boolean exceptionThrown = false;

        try {
            PortfolioController.submitContact(
                '',
                'Doe',
                'test@test.com',
                'Message'
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown, 'Expected exception was not thrown');
    }


    // =========================================
    // TEST: Invalid Email Format
    // =========================================
    @IsTest
    static void testInvalidEmail() {
        Boolean exceptionThrown = false;

        try {
            PortfolioController.submitContact(
                'John',
                'Doe',
                'invalid-email',
                'Message'
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown, 'Expected exception was not thrown');
    }
}