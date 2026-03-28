@isTest
private class PortfolioLeadEmailActionTest {

    // =========================================================================
    // Test Setup
    // =========================================================================

    @testSetup
    static void setupData() {
        insert new List<Lead>{
            new Lead(
                FirstName                 = 'John',
                LastName                  = 'Doe',
                Company                   = 'Test Company',
                Email                     = 'john@test.com',
                LeadSource                = 'Website',
                Email_Message__c          = 'Initial inquiry message.',
                Previous_Email_Message__c = 'Previous inquiry message.'
            ),
            new Lead(
                LastName                  = 'Smith',
                Company                   = 'No First Name Company',
                LeadSource                = 'Portfolio',
                Email_Message__c          = null,
                Previous_Email_Message__c = null
            )
        };
    }

    // =========================================================================
    // Test Helpers
    // =========================================================================

    /** Resets all test-seam flags to their defaults before each test. */
    private static void resetTestFlags() {
        PortfolioLeadEmailAction.TEST_OWEA_ID             = null;
        PortfolioLeadEmailAction.TEST_SKIP_SET_OWEA       = false;
        PortfolioLeadEmailAction.TEST_FORCE_PREP_EXCEPTION = false;
        PortfolioLeadEmailAction.TEST_FORCE_SEND_EXCEPTION = false;
        PortfolioLeadEmailAction.TEST_FORCE_SEND_FAILURE  = false;
        PortfolioLeadEmailAction.TEST_ERROR_MESSAGES      = null;
        PortfolioLeadEmailAction.TEST_CONFIG_OVERRIDE     = null;
    }

    /**
     * Builds a standard active config override.
     * Injects this via TEST_CONFIG_OVERRIDE so no real CMT query fires in tests.
     */
    private static Notification_Config__mdt buildConfig(
        String recipientEmail,
        String senderEmail,
        String displayName,
        String subject
    ) {
        Notification_Config__mdt config = new Notification_Config__mdt();
        config.Recipient_Email__c      = recipientEmail;
        config.Sender_Email__c         = senderEmail;
        config.Sender_Display_Name__c  = displayName;
        config.Email_Subject__c        = subject;
        config.Is_Active__c            = true;
        return config;
    }

    /** Default config used by most success-path tests. */
    private static Notification_Config__mdt defaultConfig() {
        return buildConfig(
            'recipient@example.com',
            'sender@example.com',
            'Portfolio Lead System',
            'New Portfolio Lead - Action Recommended'
        );
    }

    private static Lead getPrimaryLead() {
        return [SELECT Id, Email, LastName FROM Lead WHERE Email = 'john@test.com' LIMIT 1];
    }

    private static Lead getFallbackLead() {
        return [SELECT Id, Email, LastName FROM Lead WHERE LastName = 'Smith' LIMIT 1];
    }

    /**
     * recipientEmail removed from Request — buildRequest now takes leadId + emailType only.
     * Recipient is resolved from Notification_Config__mdt inside Apex.
     */
    private static PortfolioLeadEmailAction.Request buildRequest(
        Id     leadId,
        String emailType
    ) {
        PortfolioLeadEmailAction.Request req = new PortfolioLeadEmailAction.Request();
        req.leadId    = leadId;
        req.emailType = emailType;
        return req;
    }

    // =========================================================================
    // Success Paths
    // =========================================================================

    @isTest
    static void testSendEmail_Create() {
        resetTestFlags();
        Lead ld = getPrimaryLead();
        PortfolioLeadEmailAction.TEST_CONFIG_OVERRIDE = defaultConfig();

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'create')
            });
        Test.stopTest();

        System.assertEquals(1,                        responses.size());
        System.assertEquals(true,                     responses[0].success);
        System.assertEquals('Email sent successfully.', responses[0].message);
    }

    @isTest
    static void testSendEmail_Update() {
        resetTestFlags();
        Lead ld = getPrimaryLead();
        PortfolioLeadEmailAction.TEST_CONFIG_OVERRIDE = defaultConfig();

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'update')
            });
        Test.stopTest();

        System.assertEquals(1,                        responses.size());
        System.assertEquals(true,                     responses[0].success);
        System.assertEquals('Email sent successfully.', responses[0].message);
    }

    @isTest
    static void testCreatePathWithFallbackLeadValues() {
        resetTestFlags();
        Lead ld = getFallbackLead(); // no FirstName, no Email, null messages
        PortfolioLeadEmailAction.TEST_CONFIG_OVERRIDE = defaultConfig();

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'create')
            });
        Test.stopTest();

        System.assertEquals(1,    responses.size());
        System.assertEquals(true, responses[0].success);
    }

    @isTest
    static void testSkipOweaBranch() {
        resetTestFlags();
        Lead ld = getPrimaryLead();
        PortfolioLeadEmailAction.TEST_CONFIG_OVERRIDE = defaultConfig();
        PortfolioLeadEmailAction.TEST_OWEA_ID         = '0D2000000000001'; // fake OWEA Id
        PortfolioLeadEmailAction.TEST_SKIP_SET_OWEA   = true;              // exercises skip-OWEA guard

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'create')
            });
        Test.stopTest();

        System.assertEquals(1,    responses.size());
        System.assertEquals(true, responses[0].success);
    }

    @isTest
    static void testDisplayNameUsedWhenNoOwea() {
        resetTestFlags();
        Lead ld = getPrimaryLead();

        // Config with blank sender email — OWEA will resolve to null,
        // so setSenderDisplayName branch should be exercised
        PortfolioLeadEmailAction.TEST_CONFIG_OVERRIDE = buildConfig(
            'recipient@example.com',
            '',                          // blank → OWEA resolves null
            'Portfolio Lead System',
            'Test Subject'
        );

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'create')
            });
        Test.stopTest();

        System.assertEquals(1,    responses.size());
        System.assertEquals(true, responses[0].success);
    }

    @isTest
    static void testReplyToIsApplied() {
        resetTestFlags();
        Lead ld = getPrimaryLead();

        Notification_Config__mdt config = defaultConfig();
        config.Reply_To__c = 'replyto@example.com';
        PortfolioLeadEmailAction.TEST_CONFIG_OVERRIDE = config;

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'create')
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
        PortfolioLeadEmailAction.TEST_CONFIG_OVERRIDE = defaultConfig();

        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(null, 'create')
            });

        System.assertEquals(1,                  responses.size());
        System.assertEquals(false,              responses[0].success);
        System.assertEquals('Missing Lead Id.', responses[0].message);
    }

    @isTest
    static void testMissingConfig() {
        resetTestFlags();
        Lead ld = getPrimaryLead();
        // TEST_CONFIG_OVERRIDE stays null → resolveConfig returns null → validation fails
        PortfolioLeadEmailAction.TEST_CONFIG_OVERRIDE = null;

        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'create')
            });

        System.assertEquals(1,     responses.size());
        System.assertEquals(false, responses[0].success);
        System.assert(
            responses[0].message.contains('No active Notification_Config__mdt found'),
            'Expected config-not-found message, got: ' + responses[0].message
        );
    }

    @isTest
    static void testConfigMissingRecipientEmail() {
        resetTestFlags();
        Lead ld = getPrimaryLead();

        // Config present but Recipient_Email__c is blank
        PortfolioLeadEmailAction.TEST_CONFIG_OVERRIDE = buildConfig(
            '',                     // blank recipient
            'sender@example.com',
            'Portfolio Lead System',
            'Test Subject'
        );

        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'create')
            });

        System.assertEquals(1,     responses.size());
        System.assertEquals(false, responses[0].success);
        System.assert(
            responses[0].message.contains('missing Recipient_Email__c'),
            'Expected missing recipient message, got: ' + responses[0].message
        );
    }

    @isTest
    static void testLeadNotFound() {
        resetTestFlags();
        PortfolioLeadEmailAction.TEST_CONFIG_OVERRIDE = defaultConfig();

        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest('00Q000000000000AAA', 'create')
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

        System.assertEquals(1,                  responses.size());
        System.assertEquals(false,              responses[0].success);
        System.assertEquals('Request is null.', responses[0].message);
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

        List<Lead> leads = [SELECT Id FROM Lead ORDER BY CreatedDate ASC LIMIT 2];
        PortfolioLeadEmailAction.TEST_CONFIG_OVERRIDE = defaultConfig();

        List<PortfolioLeadEmailAction.Request> requests = new List<PortfolioLeadEmailAction.Request>{
            buildRequest(leads[0].Id, 'create'),  // [0] valid create
            null,                                  // [1] null request
            buildRequest(leads[1].Id, 'update'),  // [2] valid update
            buildRequest(null,        'create'),  // [3] missing leadId
            buildRequest(leads[0].Id, 'create')   // [4] valid — recipient comes from config now
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
        System.assertEquals(true,  responses[4].success); // valid — config supplies recipient
    }

    // =========================================================================
    // Exception / Failure Paths
    // =========================================================================

    @isTest
    static void testPreparationExceptionBranch() {
        resetTestFlags();
        Lead ld = getPrimaryLead();
        PortfolioLeadEmailAction.TEST_CONFIG_OVERRIDE     = defaultConfig();
        PortfolioLeadEmailAction.TEST_FORCE_PREP_EXCEPTION = true;

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'create')
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
        PortfolioLeadEmailAction.TEST_CONFIG_OVERRIDE    = defaultConfig();
        PortfolioLeadEmailAction.TEST_FORCE_SEND_FAILURE = true;
        PortfolioLeadEmailAction.TEST_ERROR_MESSAGES     = new List<String>{ 'Forced extracted error' };

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'create')
            });
        Test.stopTest();

        System.assertEquals(1,                                   responses.size());
        System.assertEquals(false,                               responses[0].success);
        System.assertEquals('Send failed: Forced extracted error', responses[0].message);
    }

    @isTest
    static void testSendExceptionBranch() {
        resetTestFlags();
        Lead ld = getPrimaryLead();
        PortfolioLeadEmailAction.TEST_CONFIG_OVERRIDE      = defaultConfig();
        PortfolioLeadEmailAction.TEST_FORCE_SEND_EXCEPTION = true;

        Test.startTest();
        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'create')
            });
        Test.stopTest();

        System.assertEquals(1,     responses.size());
        System.assertEquals(false, responses[0].success);
        System.assert(responses[0].message.contains('Exception while sending email:'));
    }

    // =========================================================================
    // Direct Helper Coverage
    // =========================================================================

    @isTest
    static void testGetOrgWideEmailAddressId_BlankAddress() {
        Test.startTest();
        Id result = PortfolioLeadEmailAction.getOrgWideEmailAddressId('');
        Test.stopTest();

        System.assertEquals(null, result, 'Blank address should return null immediately.');
    }

    @isTest
    static void testResolveConfig_ReturnsOverrideInTest() {
        resetTestFlags();
        Notification_Config__mdt config = defaultConfig();
        PortfolioLeadEmailAction.TEST_CONFIG_OVERRIDE = config;

        Test.startTest();
        Notification_Config__mdt result = PortfolioLeadEmailAction.resolveConfig('create');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return the TEST_CONFIG_OVERRIDE.');
        System.assertEquals('recipient@example.com', result.Recipient_Email__c);
    }

    @isTest
    static void testResolveConfig_ReturnsNullWhenNoOverride() {
        resetTestFlags();
        // No override set + no real CMT record in test org → should return null
        PortfolioLeadEmailAction.TEST_CONFIG_OVERRIDE = null;

        Test.startTest();
        Notification_Config__mdt result = PortfolioLeadEmailAction.resolveConfig('create');
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null when no CMT record exists.');
    }

    @isTest
    static void testExtractErrorsDirectly() {
        resetTestFlags();
        PortfolioLeadEmailAction.TEST_ERROR_MESSAGES = new List<String>{ 'Forced extracted error' };

        Test.startTest();
        List<String> errors = PortfolioLeadEmailAction.extractErrors(
            new List<String>{ 'Original error' }
        );
        Test.stopTest();

        System.assertEquals(1,                        errors.size());
        System.assertEquals('Forced extracted error', errors[0]);
    }

    @isTest
    static void testBuildOutcome_Success() {
        Test.startTest();
        // Access via sendEmailsInternal with TEST_FORCE_SEND_FAILURE=false
        // to exercise the isSuccess() = true branch indirectly
        PortfolioLeadEmailAction.TEST_CONFIG_OVERRIDE = defaultConfig();
        Lead ld = getPrimaryLead();

        List<PortfolioLeadEmailAction.Response> responses =
            PortfolioLeadEmailAction.sendEmails(new List<PortfolioLeadEmailAction.Request>{
                buildRequest(ld.Id, 'create')
            });
        Test.stopTest();

        System.assertEquals(true, responses[0].success);
    }
}