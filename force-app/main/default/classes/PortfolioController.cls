public with sharing class PortfolioController {

    @AuraEnabled
    public static void submitContact(String firstName, String lastName, String emailAddress, String message) {
        if (String.isBlank(firstName) || String.isBlank(lastName) || String.isBlank(emailAddress) || String.isBlank(message)) {
            throw new AuraHandledException('All fields are required.');
        }

        if (!Pattern.matches('^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$',emailAddress)) {
            throw new AuraHandledException('Invalid email format.');
        }
    
        List<Lead> leads = [
            SELECT Id, FirstName, LastName, Email, Description, Message__c
            FROM Lead
            WHERE Email = :emailAddress
            LIMIT 1
        ];

        List<Lead> leadsToUpsert = new List<Lead>();

        if (!leads.isEmpty()) {
            for (Lead l : leads) {
                l.FirstName = firstName;
                l.LastName = lastName;
                l.Description = 'Old Message:\n' + l.Message__c;
                l.Message__c = message;

                leadsToUpsert.add(l);
            }

        } else {
            leadsToUpsert.add(new Lead(
                FirstName = firstName,
                LastName = lastName,
                Email = emailAddress,
                Company = 'Portfolio Contact',
                Message__c = message,
                LeadSource = 'Website'
            ));
        }

        upsert leadsToUpsert;
    }
}