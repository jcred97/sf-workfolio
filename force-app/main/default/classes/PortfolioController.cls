public with sharing class PortfolioController {

    @TestVisible private static Boolean forceEmailFailure = false;
    @TestVisible private static Boolean forceNoEmailResult = false;
    @TestVisible private static Boolean forceException = false;
    @TestVisible private static Boolean forcePublishFailure = false;

    @AuraEnabled
    public static void submitLead(String firstName, String lastName, String emailAddress, String message) {
        try {
            if (forceException) {
                throw new AuraHandledException('Forced exception for testing');
            }
            String externalId = generateExternalId(emailAddress);
            Lead_Submission__e eventRecord = new Lead_Submission__e(
                First_Name__c = firstName,
                Last_Name__c = lastName,
                Email__c = emailAddress,
                Message__c = message,
                Company__c = 'Website Inquiry',
                Lead_Source__c = 'Website',
                Email_Status__c = 'Pending',
                Status__c = 'Open - Not Contacted',
                External_Id__c = externalId
            );

            Database.SaveResult result = EventBus.publish(eventRecord);

            if (forcePublishFailure || !result.isSuccess()) {
                throw new AuraHandledException('Failed to submit lead.');
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static String generateExternalId(String emailAddress) {
        if (String.isBlank(emailAddress)) {
            return String.valueOf(Crypto.getRandomLong());
        }

        Blob hash = Crypto.generateDigest('SHA-256', Blob.valueOf(emailAddress.toLowerCase().trim()));
        return EncodingUtil.convertToHex(hash);
    }

    @AuraEnabled(cacheable=true)
    public static List<Skill__c> getSkills(Id portfolioId) {
        return [
            SELECT Id, Name, Priority__c, Parent_Skill__c
            FROM Skill__c
            WHERE Portfolio__c = :portfolioId
            ORDER BY Priority__c ASC NULLS LAST
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Portfolio_Setting__c getPortfolioSettings() {
        return [
            SELECT 
                Primary_Color__c,
                Background_Color__c,
                Card_Background__c,
                Border_Color__c,
                Primary_Text_Color__c,
                Secondary_Text_Color__c,
                Muted_Text_Color__c
            FROM Portfolio_Setting__c
            LIMIT 1
        ];
    }
}