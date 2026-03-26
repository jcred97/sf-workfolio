public without sharing class PortfolioLeadEmailAction {
    public class Request {
        @InvocableVariable(required=true)
        public Id leadId;

        @InvocableVariable(required=true)
        public String recipientEmail;

        @InvocableVariable(required=true)
        public String emailType; // create or update
    }

    public class Response {
        @InvocableVariable
        public Boolean success;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(
        label='Send Portfolio Lead Email'
        description='Sends portfolio lead email for create or update'
    )
    public static List<Response> sendEmails(List<Request> requests) {
        List<Response> responses = new List<Response>();

        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        Set<Id> leadIds = new Set<Id>();
        for (Request req : requests) {
            if (req != null && req.leadId != null) {
                leadIds.add(req.leadId);
            }
        }

        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        if (!leadIds.isEmpty()) {
            leadMap = new Map<Id, Lead>([
                SELECT Id,
                       FirstName,
                       LastName,
                       Email,
                       Company,
                       LeadSource,
                       Email_Message__c,
                       Previous_Email_Message__c
                FROM Lead
                WHERE Id IN :leadIds
            ]);
        }

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<Integer> responseIndexesForEmails = new List<Integer>();

        for (Request req : requests) {
            Response res = new Response();
            res.success = false;
            res.message = 'Unknown error.';

            responses.add(res);
            Integer responseIndex = responses.size() - 1;

            try {
                if (req == null) {
                    res.message = 'Request is null.';
                    continue;
                }

                if (req.leadId == null) {
                    res.message = 'Missing Lead Id.';
                    continue;
                }

                if (String.isBlank(req.recipientEmail)) {
                    res.message = 'Missing recipient email.';
                    continue;
                }

                Lead ld = leadMap.get(req.leadId);
                if (ld == null) {
                    res.message = 'Lead not found for Id: ' + String.valueOf(req.leadId);
                    continue;
                }

                String fullName = (safe(ld.FirstName) + ' ' + safe(ld.LastName)).trim();
                String subject;
                String body;

                if (!String.isBlank(req.emailType) && req.emailType.toLowerCase() == 'update') {
                    subject = 'Existing Portfolio Lead Updated – Action Required';
                    body =
                        'Hi,' + '\n\n' +
                        'An existing lead has submitted an update through the portfolio.' + '\n\n' +
                        'Lead Details:' + '\n' +
                        'Name: ' + safe(fullName) + '\n' +
                        'Email: ' + safe(ld.Email) + '\n' +
                        'Company: ' + safe(ld.Company) + '\n' +
                        'Lead Source: ' + safe(ld.LeadSource) + '\n\n' +
                        'Previous Message:' + '\n' +
                        safe(ld.Previous_Email_Message__c) + '\n\n' +
                        'New Message:' + '\n' +
                        safe(ld.Email_Message__c) + '\n\n' +
                        'Please review the update and follow up accordingly.' + '\n\n' +
                        'Thanks,' + '\n' +
                        'Salesforce';
                } else {
                    subject = 'New Lead from Portfolio – Action Required';
                    body =
                        'Hi,' + '\n\n' +
                        'A new lead has been created through the portfolio.' + '\n\n' +
                        'Lead Details:' + '\n' +
                        'Name: ' + safe(fullName) + '\n' +
                        'Email: ' + safe(ld.Email) + '\n' +
                        'Company: ' + safe(ld.Company) + '\n' +
                        'Lead Source: ' + safe(ld.LeadSource) + '\n\n' +
                        'Message:' + '\n' +
                        safe(ld.Email_Message__c) + '\n\n' +
                        'Please review and follow up accordingly.' + '\n\n' +
                        'Thanks,' + '\n' +
                        'Salesforce';
                }

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{ req.recipientEmail });
                mail.setSubject(subject);
                mail.setPlainTextBody(body);
                mail.setTargetObjectId(ld.Id);
                mail.setTreatTargetObjectAsRecipient(false);
                mail.setSaveAsActivity(true);

                emailsToSend.add(mail);
                responseIndexesForEmails.add(responseIndex);

                res.message = 'Prepared successfully.';
            } catch (Exception e) {
                res.success = false;
                res.message = 'Exception: ' + e.getMessage();
            }
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(emailsToSend, false);

            for (Integer i = 0; i < sendResults.size(); i++) {
                Integer responseIndex = responseIndexesForEmails[i];
                Response res = responses[responseIndex];
                Messaging.SendEmailResult result = sendResults[i];

                if (result.isSuccess()) {
                    res.success = true;
                    res.message = 'Email sent successfully.';
                } else {
                    List<String> errors = new List<String>();
                    for (Messaging.SendEmailError err : result.getErrors()) {
                        errors.add(err.getMessage());
                    }
                    res.success = false;
                    res.message = 'Send failed: ' + String.join(errors, ' | ');
                }
            }
        }

        return responses;
    }

    private static String safe(String value) {
        return String.isBlank(value) ? '' : value;
    }
}