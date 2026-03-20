@IsTest
private class PortfolioControllerTest {

    /* =====================================================
       TEST: Successful Email + Lead Creation
    ===================================================== */
    @IsTest
    static void testSendContactMessage_Success() {

        Test.startTest();

        PortfolioController.sendContactMessage(
            'John',
            'Doe',
            'john@example.com',
            'Hello, this is a test message.'
        );

        Test.stopTest();

        // Verify Lead was created
        List<Lead> leads = [
            SELECT Id, FirstName, LastName, Email
            FROM Lead
            WHERE Email = 'john@example.com'
        ];

        System.assertEquals(1, leads.size(), 'Lead should be created');
        System.assertEquals('John', leads[0].FirstName);
        System.assertEquals('Doe', leads[0].LastName);
    }


    /* =====================================================
       TEST: Validation Failure
    ===================================================== */
    @IsTest
    static void testSendContactMessage_BlankFields() {

        Boolean exceptionThrown = false;

        try {
            PortfolioController.sendContactMessage(
                '', '', '', ''
            );
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown, 'Expected an exception for blank fields.');
    }
}