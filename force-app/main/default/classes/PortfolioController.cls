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
            SELECT Id, Name, Priority__c, Parent_Skill__c, Is_Full_Width__c
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
                Secondary_Color__c,
                Accent_Color__c,
                Background_Color__c,
                Card_Background__c,
                Border_Color__c,
                Primary_Text_Color__c,
                Secondary_Text_Color__c,
                Muted_Text_Color__c,
                Button_Gradient_Start__c,
                Button_Gradient_End__c,
                Button_Text_Color__c,
                Card_Border_Radius__c,
                Card_Shadow__c,
                Hover_Border_Color__c
            FROM Portfolio_Setting__c
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<WorkExperience__c> getWorkExperiences(Id portfolioId) {
        return [
            SELECT Id, CompanyName__c, Role__c, JobStartDate__c, JobEndDate__c,
                   WorkLocation__c, IsCurrent__c,
                   (SELECT Id, Bullet_Text__c, Display_Order__c, Project__c
                    FROM Experience_Bullets__r
                    WHERE Include_In_Portfolio__c = true
                    ORDER BY Display_Order__c ASC NULLS LAST),
                   (SELECT Id, Name, Tech_Stack__c, Display_Order__c
                    FROM Projects__r
                    ORDER BY Display_Order__c ASC NULLS LAST)
            FROM WorkExperience__c
            WHERE Portfolio__c = :portfolioId
            ORDER BY JobStartDate__c DESC NULLS LAST
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Personal_Project__c> getPersonalProjects(Id portfolioId) {
        return [
            SELECT Id, Name, Description__c, Tech_Stack__c,
                   YouTube_URL__c, GitHub_URL__c, Live_URL__c, Display_Order__c,
                   (SELECT Id, Name, Image_URL__c, Caption__c, Display_Order__c
                    FROM Project_Images__r
                    ORDER BY Display_Order__c ASC NULLS LAST)
            FROM Personal_Project__c
            WHERE Portfolio__c = :portfolioId
            ORDER BY Display_Order__c ASC NULLS LAST
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Certification__c> getCertifications(Id portfolioId) {
        return [
            SELECT Id, Name, Image_URL__c, Display_Order__c
            FROM Certification__c
            WHERE Portfolio__c = :portfolioId
            ORDER BY Display_Order__c ASC NULLS LAST
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Project__c> getProjects(Id portfolioId) {
        return [
            SELECT Id, Name, Description__c, Tech_Stack__c, Display_Order__c,
                   Work_Experience__c, Work_Experience__r.CompanyName__c
            FROM Project__c
            WHERE Work_Experience__r.Portfolio__c = :portfolioId
            ORDER BY Display_Order__c ASC NULLS LAST
        ];
    }
}
