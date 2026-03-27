@isTest
private class PortfolioLeadEmailActionTest {

    // =========================================================================
    // Test Setup
    // =========================================================================

    @testSetup
    static void setupData() {
        insert new List<Lead>{
            new Lead(
                FirstName                  = 'John',
                LastName                   = 'Doe',
                Company                    = 'Test Company',
                Email                      = 'john@test.com',
                LeadSource                 = 'Website',
                Email_Message__c           = 'Initial inquiry message.',
                Previous_Email_Message__c  = 'Previous inquiry message.'
            ),
            new Lead(
                LastName                   = 'Smith',
                Company                    = 'No First Name Company',
                LeadSource                 = 'Portfolio',
                Email_Message__c           = null,
                Previous_Email_Message__c  = null
            )
        };
    }

    // =========================================================================
    // Test Helpers
    // =========================================================================

    /** Resets all test-seam flags to their defaults before each test. */
    private static void resetTestFlags() {
        PortfolioLeadEmailAction.TEST_OWEA_ADDRESS          = null;
        PortfolioLeadEmailAction.TEST_OWEA_ID               = null;
        PortfolioLeadEmailAction.TEST_SKIP_SET_OWEA         = false;
        PortfolioLeadEmailAction.TEST_USE_DEFAULT_EMAIL     = false;
        PortfolioLeadEmailAction.TEST_FORCE_PREP_EXCEPTION  = false;
        PortfolioLeadEmailAction.TEST_FORCE_SEND_EXCEPTION  = false;
        PortfolioLeadEmailAction.TEST_FORCE_SEND_FAILURE    = false;
        PortfolioLeadEmailAction.TEST_ERROR_MESSAGES        = null;
    }

    private static Lead getPrimaryLead() {
        return [SELECT Id, Email, LastName FROM Lead WHERE Email = 'john@test.com' LIMIT 1];
    }

    private static Lead getFallbackLead() {
        return [SELECT Id, Email, LastName FROM Lead WHERE LastName = 'Smith' LIMIT 1];
    }

    private static PortfolioLeadEmailAction.Request buildRequest(
        Id     leadId,
        String recipientEmail,
        String emailType
    ) {
        PortfolioLeadEmailAction.Request req = new PortfolioLeadEmailAction.Request();
        req.leadId         = leadId;
        req.recipientEmail = recipientEmail;
        req.emailType      = emailType;
        return req;
    }

    // =========================================================================
    // Success Paths
    // =========================================================================

    @isTest
    static void testSendEmail_Create() {
        resetTestFlags();
        Lead ld = getPrimaryLead();
        PortfolioLeadEmailAction.TEST_OWEA_ADDRESS = 'test@example.com';

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'test@example.com', 'create')
            });
        Test.stopTest();

        System.assertEquals(1,                       responses.size());
        System.assertEquals(true,                    responses[0].success);
        System.assertEquals('Email sent successfully.', responses[0].message);
    }

    @isTest
    static void testSendEmail_Update() {
        resetTestFlags();
        Lead ld = getPrimaryLead();
        PortfolioLeadEmailAction.TEST_OWEA_ADDRESS = 'test@example.com';

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'test@example.com', 'update')
            });
        Test.stopTest();

        System.assertEquals(1,                       responses.size());
        System.assertEquals(true,                    responses[0].success);
        System.assertEquals('Email sent successfully.', responses[0].message);
    }

    @isTest
    static void testSendEmail_DefaultBranch() {
        resetTestFlags();
        Lead ld = getPrimaryLead();
        PortfolioLeadEmailAction.TEST_OWEA_ADDRESS = 'test@example.com';

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'test@example.com', null) // null emailType → create path
            });
        Test.stopTest();

        System.assertEquals(1,    responses.size());
        System.assertEquals(true, responses[0].success);
    }

    @isTest
    static void testCreatePathWithFallbackLeadValues() {
        resetTestFlags();
        Lead ld = getFallbackLead(); // Lead has no FirstName, no Email, null messages
        PortfolioLeadEmailAction.TEST_OWEA_ADDRESS = 'test@example.com';

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'fallback@example.com', 'create')
            });
        Test.stopTest();

        System.assertEquals(1,    responses.size());
        System.assertEquals(true, responses[0].success);
    }

    @isTest
    static void testBlankOrgWideEmailAddressBranch() {
        resetTestFlags();
        Lead ld = getPrimaryLead();
        PortfolioLeadEmailAction.TEST_OWEA_ADDRESS = ''; // blank → falls back to default

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'test@example.com', 'create')
            });
        Test.stopTest();

        System.assertEquals(1,                       responses.size());
        System.assertEquals(true,                    responses[0].success);
        System.assertEquals('Email sent successfully.', responses[0].message);
    }

    @isTest
    static void testUseDefaultEmailBranch() {
        resetTestFlags();
        Lead ld = getPrimaryLead();
        PortfolioLeadEmailAction.TEST_USE_DEFAULT_EMAIL = true; // forces production address path

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'test@example.com', 'create')
            });
        Test.stopTest();

        System.assertEquals(1,    responses.size());
        System.assertEquals(true, responses[0].success);
    }

    @isTest
    static void testSetOrgWideEmailIdBranch() {
        resetTestFlags();
        Lead ld = getPrimaryLead();
        PortfolioLeadEmailAction.TEST_OWEA_ADDRESS  = 'test@example.com';
        PortfolioLeadEmailAction.TEST_OWEA_ID       = '0D2000000000001';
        PortfolioLeadEmailAction.TEST_SKIP_SET_OWEA = true; // exercises the skip-OWEA guard

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'test@example.com', 'create')
            });
        Test.stopTest();

        System.assertEquals(1,    responses.size());
        System.assertEquals(true, responses[0].success);
    }

    // =========================================================================
    // Validation / Guard Clauses
    // =========================================================================

    @isTest
    static void testMissingLeadId() {
        resetTestFlags();

        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(null, 'test@example.com', 'create')
            });

        System.assertEquals(1,                  responses.size());
        System.assertEquals(false,              responses[0].success);
        System.assertEquals('Missing Lead Id.', responses[0].message);
    }

    @isTest
    static void testMissingRecipientEmail_Null() {
        resetTestFlags();
        Lead ld = getPrimaryLead();

        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, null, 'create')
            });

        System.assertEquals(1,                          responses.size());
        System.assertEquals(false,                      responses[0].success);
        System.assertEquals('Missing recipient email.', responses[0].message);
    }

    @isTest
    static void testMissingRecipientEmail_Blank() {
        resetTestFlags();
        Lead ld = getPrimaryLead();

        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, '   ', 'create')
            });

        System.assertEquals(1,                          responses.size());
        System.assertEquals(false,                      responses[0].success);
        System.assertEquals('Missing recipient email.', responses[0].message);
    }

    @isTest
    static void testLeadNotFound() {
        resetTestFlags();

        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest('00Q000000000000AAA', 'test@example.com', 'create')
            });

        System.assertEquals(1,     responses.size());
        System.assertEquals(false, responses[0].success);
        System.assert(responses[0].message.contains('Lead not found'));
    }

    @isTest
    static void testNullRequestInList() {
        resetTestFlags();

        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(
                new List<PortfolioLeadEmailAction.Request>{ null }
            );

        System.assertEquals(1,                   responses.size());
        System.assertEquals(false,               responses[0].success);
        System.assertEquals('Request is null.',  responses[0].message);
    }

    @isTest
    static void testEmptyRequestList() {
        resetTestFlags();

        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>());

        System.assertEquals(0, responses.size());
    }

    @isTest
    static void testNullRequestList() {
        resetTestFlags();

        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(null);

        System.assertEquals(0, responses.size());
    }

    // =========================================================================
    // Bulk / Mixed Scenario
    // =========================================================================

    @isTest
    static void testBulkMixedRequests() {
        resetTestFlags();

        List<Lead> leads = [SELECT Id, Email FROM Lead ORDER BY CreatedDate ASC LIMIT 2];
        PortfolioLeadEmailAction.TEST_OWEA_ADDRESS = 'test@example.com';

        List<PortfolioLeadEmailAction.Request> requests = new List<PortfolioLeadEmailAction.Request>{
            buildRequest(leads[0].Id, 'test1@example.com', 'create'), // valid create
            null,                                                       // null request
            buildRequest(leads[1].Id, 'test2@example.com', 'update'), // valid update
            buildRequest(null,        'test3@example.com', 'create'), // missing leadId
            buildRequest(leads[0].Id, '',                  'create')  // blank recipient
        };

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(requests);
        Test.stopTest();

        System.assertEquals(5,     responses.size());
        System.assertEquals(true,  responses[0].success); // valid create
        System.assertEquals(false, responses[1].success); // null request
        System.assertEquals(true,  responses[2].success); // valid update
        System.assertEquals(false, responses[3].success); // missing leadId
        System.assertEquals(false, responses[4].success); // blank recipient
    }

    // =========================================================================
    // Exception / Failure Paths
    // =========================================================================

    @isTest
    static void testPreparationExceptionBranch() {
        resetTestFlags();
        Lead ld = getPrimaryLead();
        PortfolioLeadEmailAction.TEST_FORCE_PREP_EXCEPTION = true;

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'test@example.com', 'create')
            });
        Test.stopTest();

        System.assertEquals(1,     responses.size());
        System.assertEquals(false, responses[0].success);
        System.assert(responses[0].message.contains('Exception while preparing email:'));
    }

    @isTest
    static void testSendFailureBranch() {
        resetTestFlags();
        Lead ld = getPrimaryLead();
        PortfolioLeadEmailAction.TEST_OWEA_ADDRESS        = 'test@example.com';
        PortfolioLeadEmailAction.TEST_FORCE_SEND_FAILURE  = true;
        PortfolioLeadEmailAction.TEST_ERROR_MESSAGES      = new List<String>{ 'Forced extracted error' };

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'test@example.com', 'create')
            });
        Test.stopTest();

        System.assertEquals(1,                                  responses.size());
        System.assertEquals(false,                              responses[0].success);
        System.assertEquals('Send failed: Forced extracted error', responses[0].message);
    }

    @isTest
    static void testSendExceptionBranch() {
        resetTestFlags();
        Lead ld = getPrimaryLead();
        PortfolioLeadEmailAction.TEST_OWEA_ADDRESS         = 'test@example.com';
        PortfolioLeadEmailAction.TEST_FORCE_SEND_EXCEPTION = true;

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'test@example.com', 'create')
            });
        Test.stopTest();

        System.assertEquals(1,     responses.size());
        System.assertEquals(false, responses[0].success);
        System.assert(responses[0].message.contains('Exception while sending email:'));
    }

    // =========================================================================
    // Direct Helper Coverage
    // =========================================================================

    /**
     * Covers the blank-address early-exit in getOrgWideEmailAddressId (line 346).
     * resolveSenderOweaId() never passes a blank string to it, so we call it directly.
     */
    @isTest
    static void testGetOrgWideEmailAddressId_BlankAddress() {
        Test.startTest();
        Id result = PortfolioLeadEmailAction.getOrgWideEmailAddressId('');
        Test.stopTest();

        System.assertEquals(null, result, 'Blank address should return null immediately.');
    }

    /**
     * Covers the real send-error branch in sendEmailsInternal (lines 301-305).
     * Routes through sendEmails() so we don't reference the private EmailSendOutcome class.
     * Sends to a syntactically invalid address so Salesforce returns isSuccess()=false
     * with a real SendEmailError — without going through the TEST_FORCE_SEND_FAILURE seam.
     */
    @isTest
    static void testSendEmailsInternal_RealSendFailure() {
        resetTestFlags();
        Lead ld = getPrimaryLead();
        PortfolioLeadEmailAction.TEST_OWEA_ADDRESS = 'test@example.com';

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'not-a-valid-email', 'create')
            });
        Test.stopTest();

        System.assertEquals(1,     responses.size());
        System.assertEquals(false, responses[0].success);
        System.assert(
            responses[0].message.startsWith('Send failed:'),
            'Expected a Send failed message, got: ' + responses[0].message
        );
    }

    @isTest
    static void testExtractErrorsDirectly() {
        resetTestFlags();
        PortfolioLeadEmailAction.TEST_ERROR_MESSAGES = new List<String>{ 'Forced extracted error' };

        Test.startTest();
        List<String> errors = PortfolioLeadEmailAction.extractErrors(
            new List<String>{ 'Original error' } // should be replaced by TEST_ERROR_MESSAGES
        );
        Test.stopTest();

        System.assertEquals(1,                       errors.size());
        System.assertEquals('Forced extracted error', errors[0]);
    }
}