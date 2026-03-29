public without sharing class PortfolioLeadEmailAction {

    // ─── Test Seams ──────────────────────────────────────────────────────────
    @TestVisible private static Boolean                    TEST_SKIP_SET_OWEA        = false;
    @TestVisible private static Boolean                    TEST_FORCE_PREP_EXCEPTION = false;
    @TestVisible private static Boolean                    TEST_FORCE_SEND_EXCEPTION = false;
    @TestVisible private static Boolean                    TEST_FORCE_SEND_FAILURE   = false;
    @TestVisible private static List<String>               TEST_ERROR_MESSAGES;
    @TestVisible private static Id                         TEST_OWEA_ID;

    // Inject a full config override in tests so no real CMT/OWEA query is needed
    @TestVisible private static Notification_Config__mdt   TEST_CONFIG_OVERRIDE;

    // =========================================================================
    // Inner Classes
    // =========================================================================

    public class Request {
        @InvocableVariable(required=true) public Id     leadId;
        @InvocableVariable(required=true) public String emailType; // 'create', 'update', or 'follow_up'
        // recipientEmail removed — sourced from Notification_Config__mdt
    }

    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String  message;
    }

    private class EmailSendOutcome {
        public Boolean      success;
        public List<String> errors = new List<String>();

        public EmailSendOutcome(Boolean success) {
            this.success = success;
        }

        public EmailSendOutcome(Boolean success, List<String> errors) {
            this.success = success;
            this.errors  = (errors != null) ? errors : new List<String>();
        }
    }

    private class EmailSendTestException extends Exception {}

    // =========================================================================
    // Invocable Entry Point
    // =========================================================================

    @InvocableMethod(
        label='Send Portfolio Lead Email'
        description='Sends a portfolio lead notification email for a create or update event. Recipient, sender, subject, and display name are all sourced from Notification_Config__mdt.'
    )
    public static List<Response> sendEmails(List<Request> requests) {
        List<Response> responses = new List<Response>();

        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        Map<Id, Lead>                      leadMap      = queryLeads(requests);
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<Integer>                      emailIndexes = new List<Integer>();

        for (Request req : requests) {
            Response res = initFailureResponse();
            responses.add(res);
            Integer responseIndex = responses.size() - 1;

            try {
                if (Test.isRunningTest() && TEST_FORCE_PREP_EXCEPTION) {
                    throw new EmailSendTestException('Forced test prep exception');
                }

                // Resolve config first — fail fast if missing
                Notification_Config__mdt config = resolveConfig(req.emailType);

                if (!validateRequest(req, leadMap, config, res)) {
                    continue;
                }

                Lead   ld   = leadMap.get(req.leadId);
                String body = buildEmailBody(req.emailType, ld);

                Messaging.SingleEmailMessage mail = buildEmailMessage(req, ld, body, config);

                emailsToSend.add(mail);
                emailIndexes.add(responseIndex);
                res.message = 'Email prepared successfully.';

            } catch (Exception e) {
                res.success = false;
                res.message = 'Exception while preparing email: ' + e.getMessage();
            }
        }

        if (!emailsToSend.isEmpty()) {
            dispatchEmails(emailsToSend, emailIndexes, responses);
        }

        return responses;
    }

    // =========================================================================
    // Config Resolution
    // =========================================================================

    /**
     * Returns the Notification_Config__mdt record matching the given emailType.
     * In tests, returns TEST_CONFIG_OVERRIDE if set so no real CMT query fires.
     * DeveloperName convention: Lead_Create → emailType 'create'
     *                           Lead_Update → emailType 'update'
     */
    @TestVisible
    private static Notification_Config__mdt resolveConfig(String emailType) {
        if (Test.isRunningTest() && TEST_CONFIG_OVERRIDE != null) {
            return TEST_CONFIG_OVERRIDE;
        }

        // DeveloperName format: Lead_Create, Lead_Update, Lead_Follow_Up
        String developerName;
        if ('follow_up'.equalsIgnoreCase(emailType)) {
            developerName = 'Lead_Follow_Up';
        } else {
            developerName = 'Lead_' + emailType.substring(0, 1).toUpperCase()
                          + emailType.substring(1).toLowerCase();
        }

        List<Notification_Config__mdt> configs = [
            SELECT Sender_Display_Name__c,
                   Sender_Email__c,
                   Recipient_Email__c,
                   Reply_To__c,
                   Email_Subject__c,
                   Is_Active__c
            FROM   Notification_Config__mdt
            WHERE  DeveloperName = :developerName
            AND    Is_Active__c  = true
            LIMIT  1
        ];

        return configs.isEmpty() ? null : configs[0];
    }

    // =========================================================================
    // Email Preparation Helpers
    // =========================================================================

    /** Collects all non-null lead IDs from requests and queries them in bulk. */
    private static Map<Id, Lead> queryLeads(List<Request> requests) {
        Set<Id> leadIds = new Set<Id>();
        for (Request req : requests) {
            if (req != null && req.leadId != null) {
                leadIds.add(req.leadId);
            }
        }

        if (leadIds.isEmpty()) {
            return new Map<Id, Lead>();
        }

        return new Map<Id, Lead>([
            SELECT Id, FirstName, LastName, Email, Company, LeadSource,
                   Email_Message__c, Previous_Email_Message__c
            FROM   Lead
            WHERE  Id IN :leadIds
        ]);
    }

    /** Returns a response pre-set to failure so guards only need to set the message. */
    private static Response initFailureResponse() {
        Response res = new Response();
        res.success  = false;
        res.message  = 'Unknown error.';
        return res;
    }

    /**
     * Validates the request. Populates res.message on failure and returns false.
     * Config null check replaces the old recipientEmail blank check.
     */
    private static Boolean validateRequest(
        Request                  req,
        Map<Id, Lead>            leadMap,
        Notification_Config__mdt config,
        Response                 res
    ) {
        if (req == null) {
            res.message = 'Request is null.';
            return false;
        }
        if (req.leadId == null) {
            res.message = 'Missing Lead Id.';
            return false;
        }
        if (config == null) {
            res.message = 'No active Notification_Config__mdt found for emailType: ' + req.emailType;
            return false;
        }
        if (String.isBlank(config.Recipient_Email__c)) {
            res.message = 'Notification config is missing Recipient_Email__c for emailType: ' + req.emailType;
            return false;
        }
        if (!leadMap.containsKey(req.leadId)) {
            res.message = 'Lead not found for Id: ' + String.valueOf(req.leadId);
            return false;
        }
        return true;
    }

    /** Assembles the plain-text email body based on whether this is a create or update. */
    private static String buildEmailBody(String emailType, Lead ld) {
        String fullName  = buildFullName(ld.FirstName, ld.LastName);
        String recordUrl = getLeadRecordUrl(ld.Id);

        String leadInfoBlock =
            'Lead Information:\n'                      +
            '- Name: '    + safe(fullName,       'N/A') + '\n' +
            '- Email: '   + safe(ld.Email,       'N/A') + '\n' +
            '- Company: ' + safe(ld.Company,     'N/A') + '\n' +
            '- Source: '  + safe(ld.LeadSource,  'N/A');

        if ('follow_up'.equalsIgnoreCase(emailType)) {
            return String.join(new List<String>{
                'Hi,',
                'This is a follow-up reminder for an uncontacted lead from your portfolio website.',
                leadInfoBlock,
                'Original Message:\n' + safe(ld.Email_Message__c, 'N/A'),
                'Lead Record:\n'      + recordUrl,
                'Recommended Action:\nThis lead has not been contacted yet. Please follow up as soon as possible.',
                '- Portfolio Lead System'
            }, '\n\n');
        }

        if ('update'.equalsIgnoreCase(emailType)) {
            return String.join(new List<String>{
                'Hi,',
                'You have received an update from an existing lead via your portfolio website.',
                leadInfoBlock,
                'Previous Message:\n' + safe(ld.Previous_Email_Message__c, 'N/A'),
                'New Message:\n'      + safe(ld.Email_Message__c,          'N/A'),
                'Lead Record:\n'      + recordUrl,
                'Recommended Action:\nReview the update and follow up accordingly to maintain engagement.',
                '- Portfolio Lead System'
            }, '\n\n');
        }

        // Default: 'create' (or any unrecognised type)
        return String.join(new List<String>{
            'Hi,',
            'You have received a new lead from your portfolio website.',
            leadInfoBlock,
            'Message:\n'      + safe(ld.Email_Message__c, 'N/A'),
            'Lead Record:\n'  + recordUrl,
            'Recommended Action:\nPlease follow up with this lead within 24 hours to maximize engagement.',
            '- Portfolio Lead System'
        }, '\n\n');
    }

    /**
     * Constructs the SingleEmailMessage.
     * Recipient, subject, sender OWEA, display name, and reply-to
     * all sourced from Notification_Config__mdt — nothing hardcoded.
     */
    private static Messaging.SingleEmailMessage buildEmailMessage(
        Request                  req,
        Lead                     ld,
        String                   body,
        Notification_Config__mdt config
    ) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(new List<String>{ config.Recipient_Email__c });
        mail.setSubject(safe(config.Email_Subject__c, 'Portfolio Lead Notification'));
        mail.setPlainTextBody(body);
        mail.setTargetObjectId(ld.Id);
        mail.setTreatTargetObjectAsRecipient(false);
        mail.setSaveAsActivity(true);

        // Reply-To — optional field on CMT
        if (String.isNotBlank(config.Reply_To__c)) {
            mail.setReplyTo(config.Reply_To__c);
        }

        // Resolve OWEA — test seam allows injecting a fake Id
        Id oweaId = (Test.isRunningTest() && TEST_OWEA_ID != null)
            ? TEST_OWEA_ID
            : getOrgWideEmailAddressId(config.Sender_Email__c);

        if (oweaId != null && !(Test.isRunningTest() && TEST_SKIP_SET_OWEA)) {
            mail.setOrgWideEmailAddressId(oweaId);
        }

        // Display name — applied when no OWEA is set (OWEA overrides display name)
        if (oweaId == null && String.isNotBlank(config.Sender_Display_Name__c)) {
            mail.setSenderDisplayName(config.Sender_Display_Name__c);
        }

        return mail;
    }

    // =========================================================================
    // Email Dispatch
    // =========================================================================

    /** Sends prepared emails and writes success/failure back into the responses list. */
    private static void dispatchEmails(
        List<Messaging.SingleEmailMessage> emailsToSend,
        List<Integer>                      emailIndexes,
        List<Response>                     responses
    ) {
        try {
            List<EmailSendOutcome> outcomes = sendEmailsInternal(emailsToSend);

            for (Integer i = 0; i < outcomes.size(); i++) {
                Response         res     = responses[emailIndexes[i]];
                EmailSendOutcome outcome = outcomes[i];

                if (outcome.success) {
                    res.success = true;
                    res.message = 'Email sent successfully.';
                } else {
                    res.success = false;
                    res.message = 'Send failed: ' + String.join(outcome.errors, ' | ');
                }
            }
        } catch (Exception e) {
            for (Integer idx : emailIndexes) {
                responses[idx].success = false;
                responses[idx].message = 'Exception while sending email: ' + e.getMessage();
            }
        }
    }

    @TestVisible
    private static List<EmailSendOutcome> sendEmailsInternal(
        List<Messaging.SingleEmailMessage> emailsToSend
    ) {
        if (Test.isRunningTest() && TEST_FORCE_SEND_EXCEPTION) {
            throw new EmailSendTestException('Forced test send exception');
        }

        if (Test.isRunningTest() && TEST_FORCE_SEND_FAILURE) {
            List<EmailSendOutcome> outcomes = new List<EmailSendOutcome>();
            for (Integer i = 0; i < emailsToSend.size(); i++) {
                outcomes.add(buildOutcome(false, new List<String>{ 'Forced send failure' }));
            }
            return outcomes;
        }

        List<EmailSendOutcome> outcomes = new List<EmailSendOutcome>();
        for (Messaging.SendEmailResult result : Messaging.sendEmail(emailsToSend, false)) {
            if (result.isSuccess()) {
                outcomes.add(buildOutcome(true, null));
            } else {
                List<String> rawErrors = new List<String>();
                for (Messaging.SendEmailError err : result.getErrors()) {
                    rawErrors.add(err.getMessage());
                }
                outcomes.add(buildOutcome(false, rawErrors));
            }
        }
        return outcomes;
    }

    // =========================================================================
    // Private Utility Methods
    // =========================================================================

    @TestVisible
    private static List<String> extractErrors(List<String> sourceErrors) {
        if (Test.isRunningTest() && TEST_ERROR_MESSAGES != null) {
            sourceErrors = TEST_ERROR_MESSAGES;
        }
        return (sourceErrors != null) ? sourceErrors.clone() : new List<String>();
    }

    @TestVisible
    private static EmailSendOutcome buildOutcome(Boolean isSuccess, List<String> rawErrors) {
        return isSuccess
            ? new EmailSendOutcome(true)
            : new EmailSendOutcome(false, extractErrors(rawErrors));
    }

    private static String buildFullName(String firstName, String lastName) {
        String full = ((firstName == null ? '' : firstName) + ' ' +
                       (lastName  == null ? '' : lastName)).trim();
        return String.isBlank(full) ? 'N/A' : full;
    }

    private static String safe(String value, String fallback) {
        return String.isBlank(value) ? fallback : value;
    }

    private static String getLeadRecordUrl(Id leadId) {
        return URL.getOrgDomainUrl().toExternalForm() + '/' + leadId;
    }

    @TestVisible
    private static Id getOrgWideEmailAddressId(String address) {
        if (String.isBlank(address)) {
            return null;
        }
        List<OrgWideEmailAddress> results = [
            SELECT Id FROM OrgWideEmailAddress
            WHERE  Address = :address
            LIMIT  1
        ];
        return results.isEmpty() ? null : results[0].Id;
    }
}