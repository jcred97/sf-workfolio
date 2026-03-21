public with sharing class PortfolioController {

    @TestVisible private static Boolean forceEmailFailure = false;
    @TestVisible private static Boolean forceNoEmailResult = false;
    @TestVisible private static Boolean forceException = false;

    @AuraEnabled
    public static void sendContactMessage(String firstName, String lastName, String emailAddress, String message) {

        validateInput(firstName, lastName, emailAddress, message);

        firstName    = firstName.trim();
        lastName     = String.isBlank(lastName) ? 'Unknown' : lastName.trim();
        emailAddress = emailAddress.trim();
        message      = message.trim();

        String fullName = firstName + ' ' + lastName;

        Boolean emailSent = false;
        String errorMsg;

        try {
            emailSent = sendEmail(fullName, emailAddress, message);

            if (!emailSent) {
                errorMsg = 'Email sending failed';
            }

        } catch (Exception e) {
            emailSent = false;
            errorMsg = e.getMessage();
        }

        insert new Lead(
            FirstName = firstName,
            LastName = lastName,
            Email = emailAddress,
            Company = 'Website Inquiry',
            LeadSource = 'Website',
            Status = 'Open - Not Contacted',
            Email_Status__c  = emailSent ? 'Sent' : 'Failed',
            Email_Error__c   = emailSent ? null : errorMsg,
            Email_Message__c = message
        );
    }

    private static void validateInput(String firstName, String lastName, String emailAddress, String message) {
        if (String.isBlank(firstName) || String.isBlank(lastName) || String.isBlank(emailAddress) || String.isBlank(message)) {
            throw new AuraHandledException('Please complete all required fields.');
        }
    }

    private static Boolean sendEmail(String fullName, String emailAddress, String message) {
        if (forceException) {
            throw new AuraHandledException('Forced exception for testing');
        }

        if (forceEmailFailure) {
            return false;
        }

        if (forceNoEmailResult) {
            return false;
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { 'john.carlo.d.red@gmail.com' });
        email.setReplyTo(emailAddress);
        email.setSenderDisplayName(fullName);
        email.setSubject('New Portfolio Inquiry from ' + fullName);
        email.setPlainTextBody(message);

        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

        return (results != null && results.size() > 0 && results[0].isSuccess());
    }
}