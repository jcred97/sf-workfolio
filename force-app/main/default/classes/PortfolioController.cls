public with sharing class PortfolioController {
    @TestVisible
    private static Boolean forceEmailFailure = false;
    @TestVisible
    private static Boolean forceNoEmailResult = false;
    @TestVisible
    private static Boolean forceException = false;
    @TestVisible
    private static Boolean forcePublishFailure = false;
    private static final Pattern EMAIL_PATTERN = Pattern.compile(
        '^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$'
    );

    @AuraEnabled
    public static void submitLead(
        String firstName,
        String lastName,
        String emailAddress,
        String message
    ) {
        try {
            if (forceException) {
                throw new AuraHandledException('Forced exception for testing');
            }

            String normalizedFirstName = normalizeInput(firstName);
            String normalizedLastName = normalizeInput(lastName);
            String normalizedEmail = normalizeInput(emailAddress);
            String normalizedMessage = normalizeInput(message);

            validateLeadSubmission(
                normalizedLastName,
                normalizedEmail,
                normalizedMessage
            );

            String externalId = generateExternalId(normalizedEmail);
            Lead_Submission__e eventRecord = new Lead_Submission__e(
                First_Name__c = normalizedFirstName,
                Last_Name__c = normalizedLastName,
                Email__c = normalizedEmail,
                Message__c = normalizedMessage,
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
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static String generateExternalId(String emailAddress) {
        if (String.isBlank(emailAddress)) {
            return String.valueOf(Crypto.getRandomLong());
        }

        Blob hash = Crypto.generateDigest(
            'SHA-256',
            Blob.valueOf(emailAddress.toLowerCase().trim())
        );
        return EncodingUtil.convertToHex(hash);
    }

    @TestVisible
    private static void validateLeadSubmission(
        String lastName,
        String emailAddress,
        String message
    ) {
        if (String.isBlank(lastName)) {
            throw new AuraHandledException('Last name is required.');
        }

        if (String.isBlank(emailAddress)) {
            throw new AuraHandledException('Email address is required.');
        }

        if (!EMAIL_PATTERN.matcher(emailAddress).matches()) {
            throw new AuraHandledException('Enter a valid email address.');
        }

        if (String.isBlank(message)) {
            throw new AuraHandledException('Message is required.');
        }
    }

    private static String normalizeInput(String value) {
        return value == null ? null : value.trim();
    }

    @AuraEnabled(cacheable=true)
    public static Portfolio__c getPortfolio(Id portfolioId) {
        List<Portfolio__c> portfolios = [
            SELECT
                Id,
                FullName__c,
                Designation__c,
                Career_Start_Date__c,
                Email__c,
                Introduction__c,
                Sub_Introduction__c,
                LinkedIn_URL__c,
                Github_URL__c,
                Trailblazer_URL__c
            FROM Portfolio__c
            WHERE Id = :portfolioId
            LIMIT 1
        ];

        return portfolios.isEmpty() ? null : portfolios[0];
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
    public static Portfolio_Setting__c getPortfolioSettings(Id portfolioId) {
        List<Portfolio__c> portfolios = [
            SELECT
                Portfolio_Setting__r.Primary_Color__c,
                Portfolio_Setting__r.Secondary_Color__c,
                Portfolio_Setting__r.Accent_Color__c,
                Portfolio_Setting__r.Background_Color__c,
                Portfolio_Setting__r.Card_Background__c,
                Portfolio_Setting__r.Border_Color__c,
                Portfolio_Setting__r.Primary_Text_Color__c,
                Portfolio_Setting__r.Secondary_Text_Color__c,
                Portfolio_Setting__r.Muted_Text_Color__c,
                Portfolio_Setting__r.Button_Gradient_Start__c,
                Portfolio_Setting__r.Button_Gradient_End__c,
                Portfolio_Setting__r.Button_Text_Color__c,
                Portfolio_Setting__r.Card_Border_Radius__c,
                Portfolio_Setting__r.Card_Shadow__c,
                Portfolio_Setting__r.Hover_Border_Color__c
            FROM Portfolio__c
            WHERE Id = :portfolioId AND Portfolio_Setting__c != NULL
            LIMIT 1
        ];

        if (portfolios.isEmpty()) {
            return null;
        }

        return portfolios[0].Portfolio_Setting__r;
    }

    @AuraEnabled(cacheable=true)
    public static List<WorkExperience__c> getWorkExperiences(Id portfolioId) {
        return [
            SELECT
                Id,
                CompanyName__c,
                Role__c,
                JobStartDate__c,
                JobEndDate__c,
                WorkLocation__c,
                IsCurrent__c,
                (
                    SELECT Id, Bullet_Text__c, Display_Order__c, Project__c
                    FROM Experience_Bullets__r
                    WHERE Include_In_Portfolio__c = TRUE
                    ORDER BY Display_Order__c ASC NULLS LAST
                ),
                (
                    SELECT Id, Name, Tech_Stack__c, Display_Order__c
                    FROM Projects__r
                    ORDER BY Display_Order__c ASC NULLS LAST
                )
            FROM WorkExperience__c
            WHERE Portfolio__c = :portfolioId
            ORDER BY JobStartDate__c DESC NULLS LAST
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Personal_Project__c> getPersonalProjects(
        Id portfolioId
    ) {
        return [
            SELECT
                Id,
                Name,
                Description__c,
                Tech_Stack__c,
                YouTube_URL__c,
                GitHub_URL__c,
                Live_URL__c,
                Display_Order__c,
                (
                    SELECT Id, Name, Image_URL__c, Caption__c, Display_Order__c
                    FROM Project_Images__r
                    ORDER BY Display_Order__c ASC NULLS LAST
                )
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
            SELECT
                Id,
                Name,
                Description__c,
                Tech_Stack__c,
                Display_Order__c,
                Work_Experience__c,
                Work_Experience__r.CompanyName__c
            FROM Project__c
            WHERE Work_Experience__r.Portfolio__c = :portfolioId
            ORDER BY Display_Order__c ASC NULLS LAST
        ];
    }
}
