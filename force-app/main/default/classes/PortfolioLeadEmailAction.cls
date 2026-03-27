public without sharing class PortfolioLeadEmailAction {

    // ─── Test Seams ──────────────────────────────────────────────────────────
    @TestVisible private static String  TEST_OWEA_ADDRESS;
    @TestVisible private static Id      TEST_OWEA_ID;
    @TestVisible private static Boolean TEST_SKIP_SET_OWEA       = false;
    @TestVisible private static Boolean TEST_USE_DEFAULT_EMAIL   = false;
    @TestVisible private static Boolean TEST_FORCE_PREP_EXCEPTION = false;
    @TestVisible private static Boolean TEST_FORCE_SEND_EXCEPTION = false;
    @TestVisible private static Boolean TEST_FORCE_SEND_FAILURE  = false;
    @TestVisible private static List<String> TEST_ERROR_MESSAGES;

    // ─── Sender Address ───────────────────────────────────────────────────────
    private static final String DEFAULT_OWEA_ADDRESS = 'john.carlo.d.red@gmail.com';

    // =========================================================================
    // Inner Classes
    // =========================================================================

    public class Request {
        @InvocableVariable(required=true) public Id     leadId;
        @InvocableVariable(required=true) public String recipientEmail;
        @InvocableVariable(required=true) public String emailType; // 'create' or 'update'
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
        description='Sends a portfolio lead notification email for a create or update event'
    )
    public static List<Response> sendEmails(List<Request> requests) {
        List<Response> responses = new List<Response>();

        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        Map<Id, Lead> leadMap     = queryLeads(requests);
        Id            senderOweaId = resolveSenderOweaId();

        List<Messaging.SingleEmailMessage> emailsToSend        = new List<Messaging.SingleEmailMessage>();
        List<Integer>                      emailResponseIndexes = new List<Integer>();

        for (Request req : requests) {
            Response res = initFailureResponse();
            responses.add(res);
            Integer responseIndex = responses.size() - 1;

            try {
                if (Test.isRunningTest() && TEST_FORCE_PREP_EXCEPTION) {
                    throw new EmailSendTestException('Forced test prep exception');
                }

                if (!validateRequest(req, leadMap, res)) {
                    continue;
                }

                Lead   ld   = leadMap.get(req.leadId);
                String body = buildEmailBody(req.emailType, ld);

                Messaging.SingleEmailMessage mail = buildEmailMessage(req, ld, body, senderOweaId);

                emailsToSend.add(mail);
                emailResponseIndexes.add(responseIndex);
                res.message = 'Email prepared successfully.';

            } catch (Exception e) {
                res.success = false;
                res.message = 'Exception while preparing email: ' + e.getMessage();
            }
        }

        if (!emailsToSend.isEmpty()) {
            dispatchEmails(emailsToSend, emailResponseIndexes, responses);
        }

        return responses;
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

    /**
     * Returns the Org-Wide Email Address Id used as the sender.
     * In tests, uses TEST_OWEA_ADDRESS unless TEST_USE_DEFAULT_EMAIL is set.
     */
    private static Id resolveSenderOweaId() {
        String address = (Test.isRunningTest() && !TEST_USE_DEFAULT_EMAIL)
            ? TEST_OWEA_ADDRESS
            : DEFAULT_OWEA_ADDRESS;

        if (String.isBlank(address)) {
            address = DEFAULT_OWEA_ADDRESS;
        }

        return getOrgWideEmailAddressId(address);
    }

    /** Returns a response pre-set to failure so guards only need to set the message. */
    private static Response initFailureResponse() {
        Response res = new Response();
        res.success  = false;
        res.message  = 'Unknown error.';
        return res;
    }

    /**
     * Validates the request fields. Populates res.message on failure and returns false.
     * Returns true when the request is ready to send.
     */
    private static Boolean validateRequest(Request req, Map<Id, Lead> leadMap, Response res) {
        if (req == null) {
            res.message = 'Request is null.';
            return false;
        }
        if (req.leadId == null) {
            res.message = 'Missing Lead Id.';
            return false;
        }
        if (String.isBlank(req.recipientEmail)) {
            res.message = 'Missing recipient email.';
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
        String fullName   = buildFullName(ld.FirstName, ld.LastName);
        String recordUrl  = getLeadRecordUrl(ld.Id);

        String leadInfoBlock =
            'Lead Information:\n'                   +
            '- Name: '    + safe(fullName,    'N/A') + '\n' +
            '- Email: '   + safe(ld.Email,    'N/A') + '\n' +
            '- Company: ' + safe(ld.Company,  'N/A') + '\n' +
            '- Source: '  + safe(ld.LeadSource, 'N/A');

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
            'Message:\n' + safe(ld.Email_Message__c, 'N/A'),
            'Lead Record:\n' + recordUrl,
            'Recommended Action:\nPlease follow up with this lead within 24 hours to maximize engagement.',
            '- Portfolio Lead System'
        }, '\n\n');
    }

    /** Returns the email subject line for the given email type. */
    private static String buildEmailSubject(String emailType) {
        return 'update'.equalsIgnoreCase(emailType)
            ? 'Lead Update Received - Action Required'
            : 'New Portfolio Lead - Action Recommended';
    }

    /** Constructs the SingleEmailMessage, attaching the OWEA Id when available. */
    private static Messaging.SingleEmailMessage buildEmailMessage(
        Request req,
        Lead    ld,
        String  body,
        Id      senderOweaId
    ) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ req.recipientEmail });
        mail.setSubject(buildEmailSubject(req.emailType));
        mail.setPlainTextBody(body);
        mail.setTargetObjectId(ld.Id);
        mail.setTreatTargetObjectAsRecipient(false);
        mail.setSaveAsActivity(true);

        Id oweaId = (Test.isRunningTest() && TEST_OWEA_ID != null)
            ? TEST_OWEA_ID
            : senderOweaId;

        if (oweaId != null && !(Test.isRunningTest() && TEST_SKIP_SET_OWEA)) {
            mail.setOrgWideEmailAddressId(oweaId);
        }

        return mail;
    }

    // =========================================================================
    // Email Dispatch
    // =========================================================================

    /** Sends prepared emails and writes success/failure back into the responses list. */
    private static void dispatchEmails(
        List<Messaging.SingleEmailMessage> emailsToSend,
        List<Integer>                      emailResponseIndexes,
        List<Response>                     responses
    ) {
        try {
            List<EmailSendOutcome> outcomes = sendEmailsInternal(emailsToSend);

            for (Integer i = 0; i < outcomes.size(); i++) {
                Response         res     = responses[emailResponseIndexes[i]];
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
            for (Integer idx : emailResponseIndexes) {
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