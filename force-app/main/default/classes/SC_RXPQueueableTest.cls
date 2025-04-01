/*************************************************************************************
 * @Name         : SC_RXPQueueableTest.cls
 * @Description  : Unit test class for RXP integration
 * @Created By   : Denys Taldykin
 * @Created Date : January 5, 2022
 * @Modification Log:
 **************************************************************************************
 * Version     Developer      Date        Description
 *-------------------------------------------------------------------------------------
 *************************************************************************************/
@IsTest
private class SC_RXPQueueableTest {
    private static final String EMAIL_ADDRESS_OLD = 'test1@test.com';
    private static final String EMAIL_ADDRESS_CASE = 'test2@test2.com';
    private static final String SEARCH_TYPE = 'SearchType';
    private static final String SEARCH_TYPE_CARD = 'Card';
    private static final String SEARCH_TYPE_EMAIL = 'Email';
    private static final String FIRST_NAME_1 = 'FirstName1';
    private static final String FIRST_NAME_2 = 'FirstName2';
    private static final String LAST_NAME_1 = 'LastName1';
    private static final String LAST_NAME_2 = 'LastName2';
    private static final String CARD_NUMBER = '89396643222082';
    private static final String STORE_1_ID = '20256';
    private static final String ACCESS_TOKEN = '12345678910';
    private static final String RESPONSE_COURSES_U = '{"Individu":{"nom":"' + FIRST_NAME_1 + '","prenom":"' + LAST_NAME_1 + '",' +
            '"canaux":[{"codeCanal":"coursesUCom","statutIndividu": "activated",' +
            '"magasinPrefere":"' + STORE_1_ID + '",' +
            '"contacts":[' +
            '{"typologieContact":"Card","carte":{"numeroCarteU":"' + CARD_NUMBER + '","statutCarte":"' + SC_RXPService.CARD_STATUS_ACTIVE + '",' +
            '"dateActivationCarte": "20230306"}},' +
            '{"typologieContact":"Email","email":{"valeur":"' + EMAIL_ADDRESS_CASE + '"}}]}]}}';
    private static final String RESPONSE_MAGASINS_U = '{"Individu":{"nom":"' + FIRST_NAME_1 + '","prenom":"' + LAST_NAME_1 + '",' +
            '"canaux":[{"codeCanal":"magasinUCom","statutIndividu": "activated","magasinPrefere":"' + STORE_1_ID + '",' +
            '"contacts":[' +
            '{"typologieContact":"Card","carte":{"numeroCarteU":"' + CARD_NUMBER + '","statutCarte":"' + SC_RXPService.CARD_STATUS_ACTIVE + '",' +
            '"dateActivationCarte": "20230306"}},' +
            '{"typologieContact":"Email","email":{"valeur":"' + EMAIL_ADDRESS_CASE + '"}}]}]}}';
    private static final String RESPONSE_MAGASIN_PHISIQUE_EMAIL = '{"Individu":[{"nom":"' + FIRST_NAME_1 + '","prenom":"' + LAST_NAME_1 + '",' +
            '"canaux":[{"codeCanal":"MagasinPhysique","statutIndividu": "activated",' +
            '"magasinPrefere":"' + STORE_1_ID + '",' +
            '"contacts":[' +
            '{"typologieContact":"Card","carte":{"numeroCarteU":"' + CARD_NUMBER + '","statutCarte":"' + SC_RXPService.CARD_STATUS_ACTIVE + '",' +
            '"dateActivationCarte": "20230306"}},' +
            '{"typologieContact":"Email","email":{"valeur":"' + EMAIL_ADDRESS_CASE + '"}}]}]}]}';
    private static final String RESPONSE_MAGASIN_PHISIQUE_CARD = '{"Individu":{"nom":"' + FIRST_NAME_1 + '","prenom":"' + LAST_NAME_1 + '",' +
            '"canaux":[{"codeCanal":"MagasinPhysique","statutIndividu": "activated",' +
            '"magasinPrefere":"' + STORE_1_ID + '",' +
            '"contacts":[{' +
            '"typologieContact":"Card","carte":{"numeroCarteU":"' + CARD_NUMBER + '","statutCarte":"' + SC_RXPService.CARD_STATUS_ACTIVE + '",' +
            '"dateActivationCarte": "20230306"}},' +
            '{"typologieContact":"Email","email":{"valeur":"' + EMAIL_ADDRESS_CASE + '"}}]}]}}';
    private static final String RESPONSE_CLIENT_U = '{"Individu":{"nom":"' + FIRST_NAME_1 + '","prenom":"' + LAST_NAME_1 + '",' +
            '"canaux":[{"codeCanal":"clientU","statutIndividu": "activated","magasinPrefere":"' + STORE_1_ID + '",' +
            '"contacts":[' +
            '{"typologieContact":"Card","carte":{"numeroCarteU":"' + CARD_NUMBER + '","statutCarte":"' + SC_RXPService.CARD_STATUS_ACTIVE + '",' +
            '"dateActivationCarte": "20230306"}},' +
            '{"typologieContact":"Email","email":{"valeur":"' + EMAIL_ADDRESS_CASE + '"}}]}]}}';

    private static final String RESPONSE_CUSTOMER_NOT_FOUND = '{"codeRetour":"KO","Erreur":{"codeErreur":["F_ERR_05"],"libelleErreur":["Individu inexistant."]},"Individu":{}}';
    private static final String AUTH_RESPONSE_SUCCESS = '{"access_token":"' + ACCESS_TOKEN + '","scope":"am_application_scope default","token_type":"Bearer","expires_in":3482}';

    @TestSetup
    private static void createTestSettings() {
        SC_RXPConnectionSettings__c settings = new SC_RXPConnectionSettings__c();
        settings.SetupOwnerId = UserInfo.getOrganizationId();
        settings.TokenExpirationDate__c = Datetime.now().addSeconds(100);
        settings.Token__c = '123456';
        settings.EnableRXPSync__c = true;

        insert settings;
    }

    /**
     * @author Denys Taldykin
     * @date January 07, 2023
     * @name testCaseSyncByCardNumber
     * @description test method for search by Loyalty Card Number
     */
    @IsTest
    private static void testCaseSyncByCardNumber() {
        Account acc = new Account(FirstName = FIRST_NAME_2, LastName = LAST_NAME_2, Email_ID__c = EMAIL_ADDRESS_OLD, PersonEmail = EMAIL_ADDRESS_OLD, RecordTypeId = SC_RXPService.PRESON_ACCOUNT_RT_ID);
        Account store = new Account(Name = 'Store 1', StoreId__c = STORE_1_ID, RecordTypeId = SC_RXPService.STORE_ACCOUNT_RT_ID);
        Case c;
        List<RXP_Case_Subject_Mapping__mdt> caseSubjectMappings = [SELECT Case_Type__c, Case_Subject__c FROM RXP_Case_Subject_Mapping__mdt];
        String caseSubject;

        for (RXP_Case_Subject_Mapping__mdt m : caseSubjectMappings) {
            caseSubject = m.Case_Subject__c;
        }

        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        insert acc;

        insert store;

        c = new Case (
                AccountId = acc.Id,
                Status = 'Nouveau',
                Origin = 'Web',
                Priority = 'Moyen',
                Description = 'My test case',
                SuppliedEmail = EMAIL_ADDRESS_CASE,
                LoyaltyCardID__c = CARD_NUMBER,
                Subject = caseSubject,
                Type = SC_RXPService.COURSES_U_CASE_TYPE
        );

        Test.startTest();

        insert c;

        Test.stopTest();

        c = [SELECT Id, AccountId, FirstName__c, LastName__c, SuppliedEmail, LoyaltyCardID__c FROM Case WHERE Id = :c.Id LIMIT 1];
        acc = [
                SELECT
                        Id, FirstName, LastName, LoyaltyCardID__pc, PreferedStore__c, Magasin_de_rattachement__c, LoyaltyCreationDate__pc,
                        Magasin_Course_U__c, Magasin_U_com__c, Magasin_physique__c, Client_unifie_U_fr__c
                FROM Account
                WHERE Id = :c.AccountId
        ];

        System.assertEquals(FIRST_NAME_1, c.FirstName__c, 'FirstName__c should be updated on Case!');
        System.assertEquals(LAST_NAME_1, c.LastName__c, 'LastName__c should be updated on Case!');
        System.assertEquals(CARD_NUMBER, c.LoyaltyCardID__c, 'LoyaltyCardID__c should be updated on Case!');

        System.assertEquals(FIRST_NAME_1, acc.FirstName, 'FirstName should be updated on Account!');
        System.assertEquals(LAST_NAME_1, acc.LastName, 'LastName should be updated on Account!');
        System.assertEquals(CARD_NUMBER, acc.LoyaltyCardID__pc, 'LoyaltyCardID__pc should be updated on Account!');
        System.assertEquals(store.Id, acc.PreferedStore__c, 'PreferedStore__c should be updated on Account!');
        System.assertEquals(store.Id, acc.Magasin_de_rattachement__c, 'Magasin_de_rattachement__c should be updated on Account!');
        System.assertEquals(Date.newInstance(2023, 3, 6), acc.LoyaltyCreationDate__pc, 'Magasin_de_rattachement__c should be updated on Account!');
        System.assert(!acc.Magasin_Course_U__c, 'Magasin_Course_U__c should be updated on Account!');
        System.assert(!acc.Magasin_U_com__c, 'Magasin_U_com__c should be updated on Account!');
        System.assert(acc.Magasin_physique__c, 'Magasin_physique__c should be updated on Account!');
        System.assert(acc.Client_unifie_U_fr__c , 'Client_unifie_U_fr__c  should be updated on Account!');
    }

    /**
     * @author Denys Taldykin
     * @date March 16, 2023
     * @name testCaseSyncByEmail
     * @description test method for MagasinsU Cases
     */
    @IsTest
    private static void testCaseSyncByEmail() {
        Account acc = new Account(FirstName = FIRST_NAME_2, LastName = LAST_NAME_2, Email_ID__c = EMAIL_ADDRESS_OLD, PersonEmail = EMAIL_ADDRESS_OLD, RecordTypeId = SC_RXPService.PRESON_ACCOUNT_RT_ID);
        Account store = new Account(Name = 'Store 1', StoreId__c = STORE_1_ID, RecordTypeId = SC_RXPService.STORE_ACCOUNT_RT_ID);
        Case c;
        List<RXP_Case_Subject_Mapping__mdt> caseSubjectMappings = [SELECT Case_Type__c, Case_Subject__c FROM RXP_Case_Subject_Mapping__mdt];
        String caseSubject;

        for (RXP_Case_Subject_Mapping__mdt m : caseSubjectMappings) {
            caseSubject = m.Case_Subject__c;
        }

        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        insert acc;

        insert store;

        c = new Case (
                AccountId = acc.Id,
                Status = 'Nouveau',
                Origin = 'Web',
                Priority = 'Moyen',
                Description = 'My test case',
                SuppliedEmail = EMAIL_ADDRESS_CASE,
                Subject = caseSubject,
                Type = SC_RXPService.COURSES_U_CASE_TYPE
        );

        Test.startTest();

        insert c;

        Test.stopTest();

        c = [SELECT Id, AccountId, FirstName__c, LastName__c, SuppliedEmail, LoyaltyCardID__c FROM Case WHERE Id = :c.Id LIMIT 1];
        acc = [
                SELECT Id, FirstName, LastName, LoyaltyCardID__pc, PreferedStore__c, Magasin_de_rattachement__c, LoyaltyCreationDate__pc,
                        Magasin_Course_U__c, Magasin_U_com__c, Magasin_physique__c, Client_unifie_U_fr__c
                FROM Account
                WHERE Id = :c.AccountId
        ];

        System.assertEquals(FIRST_NAME_1, c.FirstName__c, 'FirstName__c should be updated on Case!');
        System.assertEquals(LAST_NAME_1, c.LastName__c, 'LastName__c should be updated on Case!');
        System.assertEquals(CARD_NUMBER, c.LoyaltyCardID__c, 'LoyaltyCardID__c should be updated on Case!');

        System.assertEquals(FIRST_NAME_1, acc.FirstName, 'FirstName should be updated on Account!');
        System.assertEquals(LAST_NAME_1, acc.LastName, 'LastName should be updated on Account!');
        System.assertEquals(CARD_NUMBER, acc.LoyaltyCardID__pc, 'LoyaltyCardID__pc should be updated on Account!');
        System.assertEquals(store.Id, acc.PreferedStore__c, 'PreferedStore__c should be updated on Account!');
        System.assertEquals(store.Id, acc.Magasin_de_rattachement__c, 'Magasin_de_rattachement__c should be updated on Account!');
        System.assertEquals(Date.newInstance(2023, 3, 6), acc.LoyaltyCreationDate__pc, 'Magasin_de_rattachement__c should be updated on Account!');
        System.assert(!acc.Magasin_Course_U__c, 'Magasin_Course_U__c should be updated on Account!');
        System.assert(!acc.Magasin_U_com__c, 'Magasin_U_com__c should be updated on Account!');
        System.assert(acc.Magasin_physique__c, 'Magasin_physique__c should be updated on Account!');
        System.assert(acc.Client_unifie_U_fr__c , 'Client_unifie_U_fr__c  should be updated on Account!');
    }

    /**
     * @author Denys Taldykin
     * @date March 16, 2023
     * @name testCaseSyncByEmailNotClientU
     * @description test method for MagasinsU Cases
     */
    @IsTest
    private static void testCaseSyncByEmailNotClientU() {
        Account acc = new Account(FirstName = FIRST_NAME_2, LastName = LAST_NAME_2, Email_ID__c = EMAIL_ADDRESS_OLD, PersonEmail = EMAIL_ADDRESS_OLD, RecordTypeId = SC_RXPService.PRESON_ACCOUNT_RT_ID);
        Account store = new Account(Name = 'Store 1', StoreId__c = STORE_1_ID, RecordTypeId = SC_RXPService.STORE_ACCOUNT_RT_ID);
        Case c;
        List<RXP_Case_Subject_Mapping__mdt> caseSubjectMappings = [SELECT Case_Type__c, Case_Subject__c FROM RXP_Case_Subject_Mapping__mdt];
        String caseSubject;

        for (RXP_Case_Subject_Mapping__mdt m : caseSubjectMappings) {
            caseSubject = m.Case_Subject__c;
        }

        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        insert acc;

        insert store;

        c = new Case (
                AccountId = acc.Id,
                Status = 'Nouveau',
                Origin = 'Web',
                Priority = 'Moyen',
                Description = 'My test case',
                SuppliedEmail = EMAIL_ADDRESS_CASE,
                Subject = caseSubject,
                Type = SC_RXPService.COURSES_U_CASE_TYPE
        );

        Test.startTest();

        insert c;

        Test.stopTest();

        c = [SELECT Id, AccountId, FirstName__c, LastName__c, SuppliedEmail, LoyaltyCardID__c FROM Case WHERE Id = :c.Id LIMIT 1];
        acc = [
                SELECT Id, FirstName, LastName, LoyaltyCardID__pc, PreferedStore__c, Magasin_de_rattachement__c, LoyaltyCreationDate__pc,
                        Magasin_Course_U__c, Magasin_U_com__c, Magasin_physique__c, Client_unifie_U_fr__c
                FROM Account
                WHERE Id = :c.AccountId
        ];

        System.assertEquals(FIRST_NAME_1, c.FirstName__c, 'FirstName__c should be updated on Case!');
        System.assertEquals(LAST_NAME_1, c.LastName__c, 'LastName__c should be updated on Case!');
        System.assertEquals(CARD_NUMBER, c.LoyaltyCardID__c, 'LoyaltyCardID__c should be updated on Case!');

        System.assertEquals(FIRST_NAME_1, acc.FirstName, 'FirstName should be updated on Account!');
        System.assertEquals(LAST_NAME_1, acc.LastName, 'LastName should be updated on Account!');
        System.assertEquals(CARD_NUMBER, acc.LoyaltyCardID__pc, 'LoyaltyCardID__pc should be updated on Account!');
        System.assertEquals(store.Id, acc.PreferedStore__c, 'PreferedStore__c should be updated on Account!');
        System.assertEquals(store.Id, acc.Magasin_de_rattachement__c, 'Magasin_de_rattachement__c should be updated on Account!');
        System.assertEquals(Date.newInstance(2023, 3, 6), acc.LoyaltyCreationDate__pc, 'Magasin_de_rattachement__c should be updated on Account!');
        System.assert(!acc.Magasin_Course_U__c, 'Magasin_Course_U__c should be updated on Account!');
        System.assert(!acc.Magasin_U_com__c, 'Magasin_U_com__c should be updated on Account!');
        System.assert(acc.Magasin_physique__c, 'Magasin_physique__c should be updated on Account!');
        System.assert(acc.Client_unifie_U_fr__c , 'Client_unifie_U_fr__c should be updated on Account!');
    }
    /**
     * @author Denys Taldykin
     * @date March 16, 2023
     * @name testCustomerNotFound
     * @description test method for MagasinsU Cases
     */
    @IsTest
    private static void testCustomerNotFound() {
        Account acc = new Account(FirstName = FIRST_NAME_2, LastName = LAST_NAME_2, Email_ID__c = EMAIL_ADDRESS_OLD, PersonEmail = EMAIL_ADDRESS_OLD, RecordTypeId = SC_RXPService.PRESON_ACCOUNT_RT_ID);
        Account store = new Account(Name = 'Store 1', StoreId__c = STORE_1_ID, RecordTypeId = SC_RXPService.STORE_ACCOUNT_RT_ID);
        Case c;
        List<RXP_Case_Subject_Mapping__mdt> caseSubjectMappings = [SELECT Case_Type__c, Case_Subject__c FROM RXP_Case_Subject_Mapping__mdt];
        String caseSubject;

        for (RXP_Case_Subject_Mapping__mdt m : caseSubjectMappings) {
            caseSubject = m.Case_Subject__c;
        }

        Test.setMock(HttpCalloutMock.class, new MockNoCustomerFound());

        insert acc;

        insert store;

        c = new Case (
                AccountId = acc.Id,
                Status = 'Nouveau',
                Origin = 'Web',
                Priority = 'Moyen',
                Description = 'My test case',
                SuppliedEmail = EMAIL_ADDRESS_CASE,
                Subject = caseSubject,
                Type = SC_RXPService.COURSES_U_CASE_TYPE,
                FirstName__c = FIRST_NAME_1,
                LastName__c = LAST_NAME_1,
                LoyaltyCardID__c = CARD_NUMBER

        );

        Test.startTest();

        insert c;

        Test.stopTest();

        c = [SELECT Id, AccountId, FirstName__c, LastName__c, SuppliedEmail, LoyaltyCardID__c FROM Case WHERE Id = :c.Id LIMIT 1];
        acc = [
                SELECT Id, FirstName, LastName, LoyaltyCardID__pc, PreferedStore__c, Magasin_de_rattachement__c, LoyaltyCreationDate__pc,
                        Magasin_Course_U__c, Magasin_U_com__c, Magasin_physique__c, Client_unifie_U_fr__c
                FROM Account
                WHERE Id = :c.AccountId
        ];

        System.assertEquals(FIRST_NAME_1, c.FirstName__c, 'FirstName__c should be updated on Case!');
        System.assertEquals(LAST_NAME_1, c.LastName__c, 'LastName__c should be updated on Case!');
        System.assertEquals(CARD_NUMBER, c.LoyaltyCardID__c, 'LoyaltyCardID__c should be updated on Case!');
        System.assertEquals(FIRST_NAME_2, acc.FirstName, 'FirstName should not be updated on Account!');
        System.assertEquals(LAST_NAME_2, acc.LastName, 'LastName should not be updated on Account!');
        System.assertEquals(null, acc.PreferedStore__c, 'PreferedStore__c should not be updated on Account!');
        System.assertEquals(null, acc.Magasin_de_rattachement__c, 'Magasin_de_rattachement__c should null be updated on Account!');
        System.assert(!acc.Magasin_Course_U__c, 'Magasin_Course_U__c should be false on Account!');
        System.assert(!acc.Magasin_U_com__c, 'Magasin_U_com__c should be false on Account!');
        System.assert(!acc.Magasin_physique__c, 'Magasin_physique__c should be false on Account!');
        System.assert(!acc.Client_unifie_U_fr__c , 'Client_unifie_U_fr__c should be false on Account!');

    }

    /**
      * @author Denys Taldykin
      * @date January 07, 2023
      * @name testAuthError
      * @description test method for Auth error
      */
    @IsTest
    private static void testAuthError() {
        Account acc = new Account(FirstName = FIRST_NAME_2, LastName = LAST_NAME_2, Email_ID__c = EMAIL_ADDRESS_OLD, PersonEmail = EMAIL_ADDRESS_OLD, RecordTypeId = SC_RXPService.PRESON_ACCOUNT_RT_ID);
        Account store = new Account(Name = 'Store 1', StoreId__c = STORE_1_ID, RecordTypeId = SC_RXPService.STORE_ACCOUNT_RT_ID);
        Case c;

        Test.setMock(HttpCalloutMock.class, new MockAuthError());

        insert acc;
        insert store;

        c = new Case (
                AccountId = acc.Id,
                Status = 'Nouveau',
                Origin = 'Web',
                Priority = 'Moyen',
                Description = 'My test case',
                SuppliedEmail = EMAIL_ADDRESS_OLD,
                Subject = 'Problème sur le site',
                Type = SC_RXPService.MAGASINS_U_CASE_TYPE
        );

        Test.startTest();

        insert c;

        Test.stopTest();

        c = [SELECT Id, AccountId, FirstName__c, LastName__c, SuppliedEmail, LoyaltyCardID__c FROM Case WHERE Id = :c.Id LIMIT 1];
        acc = [SELECT Id, FirstName, LastName, LoyaltyCardID__pc, PreferedStore__c, Client_unifie_U_fr__c FROM Account WHERE Id = :c.AccountId];

        System.assertEquals(FIRST_NAME_2, acc.FirstName, 'FirstName should not be updated on Account!');
        System.assertEquals(LAST_NAME_2, acc.LastName, 'LastName should not be updated on Account!');
    }

    /**
      * @author Denys Taldykin
      * @date January 07, 2023
      * @name testAuthSuccess
      * @description test method for MagasinsU Cases
      */
    @IsTest
    private static void testAuthSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockAuthSuccess());
        Boolean exceptionThrown = false;
        SC_RXPConnectionSettings__c s = [SELECT Id, Token__c FROM SC_RXPConnectionSettings__c];

        delete s;

        Test.startTest();

        try {
            SC_RXPService.authorizeRXP();
        } catch (Exception exc) {
            exceptionThrown = true;
            System.debug(exc.getMessage());
        }

        Test.stopTest();

        System.assertEquals(false, exceptionThrown, 'No errors should be thrown on Auth Callout!');
    }

    /**
      * @author Denys Taldykin
      * @date March 16, 2023
      * @name getSearchInfoMap
      * @description method to get Search Channel from the HTTP Request body
      * @param requestBody String
      * @return Map<String, String>
      */
    private static Map<String, String> getSearchInfoMap(String requestBody) {
        Map<String, Object> reqBodyMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        Map<String, Object> searchParamsMap;
        Map<String, Object> searchParamsValuesMap;
        String searchChannelValue;
        Map<String, String> searchInfoMap = new Map<String, String>();

        if (reqBodyMap.containsKey(SC_RXPService.SEARCH_ATTRIBUTE_NAME)) {
            searchParamsMap = (Map<String, Object>) reqBodyMap.get(SC_RXPService.SEARCH_ATTRIBUTE_NAME);

            if (searchParamsMap.containsKey(SC_RXPService.CONTACT_ALIAS_ATTRIBUTE_NAME)) {
                searchParamsValuesMap = (Map<String, Object>) searchParamsMap.get(SC_RXPService.CONTACT_ALIAS_ATTRIBUTE_NAME);
                searchChannelValue = (String) searchParamsValuesMap.get(SC_RXPService.CHANNEL_ATTRIBUTE_NAME);

                if (searchChannelValue == SC_RXPService.COURSES_U_SEARCH_CHANNEL) {
                    searchInfoMap.put(SC_RXPService.CHANNEL_ATTRIBUTE_NAME, SC_RXPService.COURSES_U_SEARCH_CHANNEL);
                    searchInfoMap.put(SEARCH_TYPE, SEARCH_TYPE_EMAIL);
                }

                if (searchChannelValue == SC_RXPService.MAGASINS_U_SEARCH_CHANNEL) {
                    searchInfoMap.put(SC_RXPService.CHANNEL_ATTRIBUTE_NAME, SC_RXPService.MAGASINS_U_SEARCH_CHANNEL);
                    searchInfoMap.put(SEARCH_TYPE, SEARCH_TYPE_EMAIL);
                }

                if (searchChannelValue == SC_RXPService.CLIENT_U_SEARCH_CHANNEL) {
                    searchInfoMap.put(SC_RXPService.CHANNEL_ATTRIBUTE_NAME, SC_RXPService.CLIENT_U_SEARCH_CHANNEL);
                    searchInfoMap.put(SEARCH_TYPE, SEARCH_TYPE_EMAIL);
                }

                if (searchChannelValue == SC_RXPService.MAGASIN_PHISIQUE_SEARCH_CHANNEL) {
                    searchInfoMap.put(SC_RXPService.CHANNEL_ATTRIBUTE_NAME, SC_RXPService.MAGASIN_PHISIQUE_SEARCH_CHANNEL);
                    searchInfoMap.put(SEARCH_TYPE, SEARCH_TYPE_CARD);
                }

            } else {
                if (searchParamsMap.containsKey(SC_RXPService.CHANNEL_EMAIL_ATTRIBUTE_NAME)) {
                    searchInfoMap.put(SC_RXPService.CHANNEL_ATTRIBUTE_NAME, SC_RXPService.MAGASIN_PHISIQUE_SEARCH_CHANNEL);
                    searchInfoMap.put(SEARCH_TYPE, SEARCH_TYPE_EMAIL);
                }
            }
        }

        return searchInfoMap;
    }

    /**
     * @author Denys Taldykin
     * @date March 16, 2023
     * @name MockSuccess
     * @description Callout Mock with success response
     */
    public class MockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            Map<String, String> searchInfoMap = getSearchInfoMap(req.getBody());
            res.setHeader('Content-Type', 'application/json');

            if (searchInfoMap.get(SC_RXPService.CHANNEL_ATTRIBUTE_NAME) == SC_RXPService.COURSES_U_SEARCH_CHANNEL) {
                res.setBody(RESPONSE_COURSES_U);
            }

            if (searchInfoMap.get(SC_RXPService.CHANNEL_ATTRIBUTE_NAME) == SC_RXPService.MAGASINS_U_SEARCH_CHANNEL) {
                res.setBody(RESPONSE_MAGASINS_U);
            }

            System.debug('searchInfoMap'+searchInfoMap);
            if (searchInfoMap.get(SC_RXPService.CHANNEL_ATTRIBUTE_NAME) == SC_RXPService.CLIENT_U_SEARCH_CHANNEL) {
                System.debug('searchInfoMap'+searchInfoMap);
                res.setBody(RESPONSE_CLIENT_U);
            }

            if (searchInfoMap.get(SC_RXPService.CHANNEL_ATTRIBUTE_NAME) == SC_RXPService.MAGASIN_PHISIQUE_SEARCH_CHANNEL) {
                if (searchInfoMap.get(SEARCH_TYPE) == SEARCH_TYPE_EMAIL) {
                    res.setBody(RESPONSE_MAGASIN_PHISIQUE_EMAIL);
                } else {
                    res.setBody(RESPONSE_MAGASIN_PHISIQUE_CARD);
                }
            }

            res.setStatusCode(200);

            return res;
        }
    }

    /**
     * @author Denys Taldykin
     * @date March 16, 2023
     * @name MockSuccess
     * @description Callout Mock with success response
     */
    public class MockSuccessNotClientU implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            Map<String, String> searchInfoMap = getSearchInfoMap(req.getBody());
            res.setHeader('Content-Type', 'application/json');

            if (searchInfoMap.get(SC_RXPService.CHANNEL_ATTRIBUTE_NAME) == SC_RXPService.COURSES_U_SEARCH_CHANNEL) {
                res.setBody(RESPONSE_COURSES_U);
            }

            if (searchInfoMap.get(SC_RXPService.CHANNEL_ATTRIBUTE_NAME) == SC_RXPService.MAGASINS_U_SEARCH_CHANNEL) {
                res.setBody(RESPONSE_MAGASINS_U);
            }

            System.debug('searchInfoMap'+searchInfoMap);
            if (searchInfoMap.get(SC_RXPService.CHANNEL_ATTRIBUTE_NAME) == SC_RXPService.CLIENT_U_SEARCH_CHANNEL) {
                System.debug('searchInfoMap'+searchInfoMap);
                res.setBody(RESPONSE_CUSTOMER_NOT_FOUND);
            }

            if (searchInfoMap.get(SC_RXPService.CHANNEL_ATTRIBUTE_NAME) == SC_RXPService.MAGASIN_PHISIQUE_SEARCH_CHANNEL) {
                if (searchInfoMap.get(SEARCH_TYPE) == SEARCH_TYPE_EMAIL) {
                    res.setBody(RESPONSE_MAGASIN_PHISIQUE_EMAIL);
                } else {
                    res.setBody(RESPONSE_MAGASIN_PHISIQUE_CARD);
                }
            }

            res.setStatusCode(200);

            return res;
        }
    }

    /**
     * @author Denys Taldykin
     * @date March 16, 2023
     * @name MockNoCustomerFound
     * @description Callout Mock with success response
     */
    public class MockNoCustomerFound implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();

            res.setHeader('Content-Type', 'application/json');
            res.setBody(RESPONSE_CUSTOMER_NOT_FOUND);
            res.setStatusCode(200);

            return res;
        }
    }

    /**
     * @author  Denys Taldykin
     * @date January 07, 2023
     * @name MockAuthError
     * @description Callout Mock with authentication error
     */
    public class MockAuthError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();

            res.setHeader('Content-Type', 'application/json');
            res.setBody(RESPONSE_COURSES_U);
            res.setStatusCode(401);
            res.setStatus('Unauthorized');

            return res;
        }
    }

    /**
     * @author Denys Taldykin
     * @date January 07, 2023
     * @name MockAuthSuccess
     * @description Callout Mock with auth data
     */
    public class MockAuthSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();

            res.setHeader('Content-Type', 'application/json');
            res.setBody(AUTH_RESPONSE_SUCCESS);
            res.setStatusCode(200);

            return res;
        }
    }
}