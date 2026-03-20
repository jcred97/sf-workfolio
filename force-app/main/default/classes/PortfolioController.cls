/**
 * PortfolioController
 * -----------------------------------------------------
 * Handles portfolio contact form submissions.
 *
 * Responsibilities:
 * - Validate incoming request
 * - Construct outbound email
 * - Send notification to portfolio owner
 *
 * Security:
 * - with sharing enforced
 * - No DML operations
 * - Input validation required before execution
 */
public with sharing class PortfolioController {

    /**
     * Sends contact form submission via email.
     *
     * @param fullName     Name entered by user
     * @param emailAddress User's reply-to email
     * @param message      User's message body
     *
     * @throws AuraHandledException if validation fails
     */
    @AuraEnabled
    public static void sendContactMessage(String firstName, String lastName, String emailAddress, String message) {
        /* =====================================================
           INPUT VALIDATION
           Prevents blank submissions & unnecessary email usage
        ===================================================== */
        if (String.isBlank(firstName) ||
            String.isBlank(lastName) ||
            String.isBlank(emailAddress) ||
            String.isBlank(message)) {

            throw new AuraHandledException('Please complete all required fields.');
        }

        /* =====================================================
           DERIVE FULL NAME (FIX)
        ===================================================== */
        String fullName = firstName + ' ' + lastName;

        /* =====================================================
           EMAIL CONSTRUCTION
           Using SingleEmailMessage for direct notification
        ===================================================== */
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        // Destination (Portfolio Owner)
        email.setToAddresses(new String[] { 'john.carlo.d.red@gmail.com' });

        // Allow direct reply to sender
        email.setReplyTo(emailAddress);

        // Display sender name in email header
        email.setSenderDisplayName(fullName);

        // Subject Line
        email.setSubject('New Portfolio Inquiry from ' + fullName);

        // Email Body (Plain Text)
        email.setPlainTextBody(
            'New message from your portfolio website\n\n' +
            'Name: ' + fullName + '\n' +
            'Email: ' + emailAddress + '\n\n' +
            'Message:\n' + message
        );

        /* =====================================================
           SEND EMAIL
           Wrapped in array to support bulk-safe structure
        ===================================================== */
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

        createLead(firstName, lastName, emailAddress, message);
    }

    /* =========================================================
       LEAD CREATION (Reusable Method)
    ========================================================= */
    private static void createLead(String firstName, String lastName, String emailAddress, String message) {
        Lead newLead = new Lead(
            FirstName = firstName,
            LastName = String.isBlank(lastName) ? 'Unknown' : lastName,
            Email = emailAddress,
            Description = message,
            Company = 'Website Inquiry',
            LeadSource = 'Website',
            Status = 'Open - Not Contacted'
        );

        insert newLead;
    }
}