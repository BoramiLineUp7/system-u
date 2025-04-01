/*************************************************************************************
 * @Name         : SC_RXPService.cls
 * @Description  : Service class for RXP integration
 * @Created By   : Denys Taldykin
 * @Created Date : January 5, 2023
 * @Modification Log:
 **************************************************************************************
 * Version     Developer      Date        Description
 *-------------------------------------------------------------------------------------
 *************************************************************************************/
public with sharing class SC_RXPService {
    private static final String SEARCH_CHANNEL_ATTRIBUTE_NAME = 'canalRecherche';
    @TestVisible
    private static final String SEARCH_ATTRIBUTE_NAME = 'Recherche';
    @TestVisible
    private static final String CONTACT_ALIAS_ATTRIBUTE_NAME = 'contactAlias';
    @TestVisible
    private static final String CHANNEL_EMAIL_ATTRIBUTE_NAME = 'canalMail';
    @TestVisible
    private static final String CHANNEL_ATTRIBUTE_NAME = 'canal';
    private static final String EMAIL_ATTRIBUTE_NAME = 'email';
    private static final String CARD_SEARCH_ATTRIBUTE_NAME = 'numeroCarteU';
    private static final String CHANNEL_CODE_ATTRIBUTE_NAME = 'codeCanal';
    @TestVisible
    private static final String MAGASIN_PHISIQUE_SEARCH_CHANNEL = 'MagasinPhysique';
    @TestVisible
    private static final String MAGASINS_U_SEARCH_CHANNEL = 'magasinUCom';
    @TestVisible
    private static final String COURSES_U_SEARCH_CHANNEL = 'coursesUCom';
    @TestVisible
    private static final String CLIENT_U_SEARCH_CHANNEL = 'clientU';
    private static final String REQUEST_STATUS_MESSAGE_ATTRIBUTE_NAME = 'codeRetour';
    private static final String REQUEST_ERROR_STATUS_MESSAGE = 'KO';
    private static final String PERSON_ATTRIBUTE_NAME = 'Individu';
    private static final String FIRST_NAME_ATTRIBUTE_NAME = 'nom';
    private static final String LAST_NAME_ATTRIBUTE_NAME = 'prenom';
    private static final String PREFERRED_STORE_ATTRIBUTE_NAME = 'magasinPrefere';
    private static final String CHANEL_ATTRIBUTE_NAME = 'canaux';
    private static final String CONTACTS_ATTRIBUTE_NAME = 'contacts';
    private static final String CARD_ATTRIBUTE_NAME = 'carte';
    private static final String CONTACT_TYPE_ATTRIBUTE_NAME = 'typologieContact';
    private static final String CARD_ATTRIBUTE_VALUE = 'Card';
    private static final String EMAIL_ATTRIBUTE_VALUE = 'Email';
    private static final String EMAIL_VALUE_ATTRIBUTE_NAME = 'valeur';
    private static final String CARD_U_ATTRIBUTE_NAME = 'numeroCarteU';
    private static final String CARD_ACTIVATION_DATE_ATTRIBUTE_NAME = 'dateActivationCarte';
    private static final String CARD_STATUS_ATTRIBUTE_NAME = 'statutCarte';
    private static final String CONTACT_STATUS_ATTRIBUTE_NAME = 'statutIndividu';
    @TestVisible
    private static final String CARD_STATUS_ACTIVE = 'activated';
    @TestVisible
    private static final String CONTACT_STATUS_ACTIVE = 'activated';
    @TestVisible
    private static SC_RXPConnectionSettings__c SETTINGS = SC_RXPConnectionSettings__c.getOrgDefaults();
    public static final String COMPTE_COURSES_U_CASE_TYPE = 'Compte Courses U';
    public static final String COURSES_U_CASE_TYPE = 'Courses U';
    public static final String MAGASINS_U_CASE_TYPE = 'Magasins U';
    public static final String TICKET_TYPE_U_CENTRAL = 'U Central';
    @TestVisible
    private static final String PERSON_ACCOUNT_RECORDTYPE_DEVELOPER_NAME = 'Client';
    @TestVisible
    private static final String STORE_ACCOUNT_RECORDTYPE_DEVELOPER_NAME = 'Store';
    @TestVisible
    private static final Id PRESON_ACCOUNT_RT_ID = SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PERSON_ACCOUNT_RECORDTYPE_DEVELOPER_NAME).getRecordTypeId();
    @TestVisible
    private static final Id STORE_ACCOUNT_RT_ID = SObjectType.Account.getRecordTypeInfosByDeveloperName().get(STORE_ACCOUNT_RECORDTYPE_DEVELOPER_NAME).getRecordTypeId();
    @TestVisible
    private Boolean authRetry = false;
    @TestVisible
    private static Boolean updateSettings = false;

    /**
     * @author Denys Taldykin
     * @date January 05, 2023
     * @name syncRXPCustomerData
     * @description Method to get data from RXP then update Account and Case with RXP data
     * @param casesToProcess Map<Id, String>
     */
    public void syncRXPCustomerData(Map<Id, String> casesToProcess) {
        List<Case> cases = [
                SELECT
                        Id, Subject, AccountId, Account.FirstName, Account.LastName, Account.LoyaltyCardID__pc, SuppliedEmail, Origin,
                        Account.RecordTypeId, Account.PreferedStore__c, Account.PreferedStore__r.StoreId__c, LoyaltyCardID__c, FirstName__c, LastName__c,
                        Account.Magasin_de_rattachement__c, Account.Magasin_de_rattachement__r.StoreId__c, Account.PersonEmail, Account.LoyaltyCreationDate__pc
                FROM Case
                WHERE Id IN :casesToProcess.keySet()
        ];

        List<Case> casesToUpdate = new List<Case>();
        List<Account> accountsToUpdate = new List<Account>();

        for (Case c : cases) {
            if (c.SuppliedEmail != null) {
                this.updateCustomerInfo(c, casesToProcess.get(c.Id), casesToUpdate, accountsToUpdate);
            }
        }

        if (updateSettings) {
            if (SETTINGS.Id == null) {
                insert SETTINGS;
            } else {
                update SETTINGS;
            }
        }

        update casesToUpdate;

        update accountsToUpdate;
    }

    /**
     * @author Denys Taldykin
     * @date January 05, 2023
     * @name updateCustomerInfo
     * @description Method to Update Account and Case with RXP Data
     * @param c Case
     * @param caseType String
     * @param casesToUpdate List<Case>
     * @param accountsToUpdate List<Account>
     */
    public void updateCustomerInfo(Case c, String caseType, List<Case> casesToUpdate, List<Account> accountsToUpdate) {
        authorizeRXP();
        HttpResponse rxpResponse;
        List<String> searchChannels = getSearchChannels(caseType);
        String loyaltyCardId = c.LoyaltyCardID__c != null ? c.LoyaltyCardID__c : c.AccountId == null ? null : c.Account.LoyaltyCardID__pc;
        RXPCustomerDataWrapper customerData = new RXPCustomerDataWrapper(caseType);
        Boolean searchByCardNumber = false;
        String emailAddress = c.SuppliedEmail;

        for (String searchChannel : searchChannels) {
            rxpResponse = getRXPData(emailAddress, loyaltyCardId, searchChannel);

            if (searchChannel == MAGASIN_PHISIQUE_SEARCH_CHANNEL && loyaltyCardId != null) {
                searchByCardNumber = true;
            } else {
                searchByCardNumber = false;
            }

            if (rxpResponse.getStatusCode() == 200) {
                RXPCustomerSearchResultWrapper searchResult = parseRXPCustomerData(rxpResponse, searchChannel, searchByCardNumber);
                if (searchResult != null) {
                    customerData.searchResults.add(searchResult);
                    if (searchByCardNumber && searchResult.emailAddress != null && searchResult.emailAddress != c.SuppliedEmail) {
                        emailAddress = searchResult.emailAddress;
                    }
                    if (searchChannel == CLIENT_U_SEARCH_CHANNEL && searchResult.customerFound) {
                        break;
                    }
                }
            } else {
                if (rxpResponse.getStatusCode() == 401 && rxpResponse.getStatus() == 'Unauthorized') {
                    if (!this.authRetry) {
                        this.authRetry = true;
                        authorizeRXP();
                        updateCustomerInfo(c, caseType, casesToUpdate, accountsToUpdate);
                    }
                }
            }
        }

        updateCustomerInfoWithRXPData(customerData, c, casesToUpdate, accountsToUpdate);
    }

    /**
     * @author Denys Taldykin
     * @date January 25, 2023
     * @name getSearchChannels
     * @description Method to get list of Search Channels based on Case Type
     * @param caseType String
     * @return List<String>
     */
    private static List<String> getSearchChannels(String caseType) {
        List<String> searchChannels = new List<String>();
        searchChannels.add(MAGASIN_PHISIQUE_SEARCH_CHANNEL);

        if (caseType == MAGASINS_U_CASE_TYPE) {
            searchChannels.add(CLIENT_U_SEARCH_CHANNEL);
            searchChannels.add(MAGASINS_U_SEARCH_CHANNEL);
            searchChannels.add(COURSES_U_SEARCH_CHANNEL);
        } else {
            searchChannels.add(CLIENT_U_SEARCH_CHANNEL);
            searchChannels.add(COURSES_U_SEARCH_CHANNEL);
            searchChannels.add(MAGASINS_U_SEARCH_CHANNEL);
        }

        return searchChannels;
    }


    /**
     * @author Denys Taldykin
     * @date January 05, 2023
     * @name updateCustomerInfoWithRXPData
     * @description Method to Update Account and Case with parsed RXP Data
     * @param customerDataWrapper RXPCustomerSearchResultWrapper
     * @param c Case
     * @param casesToUpdate List<Case>
     * @param accountsToUpdate List<Account>
     * @param searchChannel String
     */
    private static void updateCustomerInfoWithRXPData(RXPCustomerDataWrapper customerDataWrapper, Case c, List<Case> casesToUpdate, List<Account> accountsToUpdate) {
        Account accToUpdate = new Account(Magasin_Course_U__c = false, Magasin_U_com__c = false, Magasin_physique__c = false);
        Case caseToUpdate = new Case(Id = c.Id);
        Boolean updateCase = false;
        Boolean primaryChannelDataUpdated = false;
        Boolean secondaryChannelDataUpdated = false;

        for (RXPCustomerSearchResultWrapper searchResult : customerDataWrapper.searchResults) {
            if (c.AccountId != null) {
                accToUpdate.Id = c.AccountId;

                if (searchResult.searchChannel == COURSES_U_SEARCH_CHANNEL) {
                    accToUpdate.Magasin_Course_U__c = true;
                }
                if (searchResult.searchChannel == MAGASINS_U_SEARCH_CHANNEL) {
                    accToUpdate.Magasin_U_com__c = true;
                }
                if (searchResult.searchChannel == CLIENT_U_SEARCH_CHANNEL) {
                    accToUpdate.Client_unifie_U_fr__c = true;
                }
                if (searchResult.searchChannel == MAGASIN_PHISIQUE_SEARCH_CHANNEL) {
                    accToUpdate.Magasin_physique__c = true;
                }

                if (searchResult.preferredStoreId != null && String.isNotBlank(searchResult.preferredStoreId) && searchResult.searchChannel != MAGASIN_PHISIQUE_SEARCH_CHANNEL) {
                    updateAccountStore(accToUpdate, searchResult.preferredStoreId, searchResult.searchChannel);
                }

                if (searchResult.homeStoreId != null && String.isNotBlank(searchResult.homeStoreId) && searchResult.searchChannel == MAGASIN_PHISIQUE_SEARCH_CHANNEL) {
                    updateAccountStore(accToUpdate, searchResult.homeStoreId, searchResult.searchChannel);
                }
            }

            if (!primaryChannelDataUpdated && !secondaryChannelDataUpdated) {
                if (searchResult.cardNumber != null && String.isNotBlank(searchResult.cardNumber)) {
                    if (c.AccountId != null) {
                        if (c.Account.LoyaltyCardID__pc != searchResult.cardNumber) {
                            accToUpdate.LoyaltyCardID__pc = searchResult.cardNumber;
                        }
                    }

                    if (c.LoyaltyCardID__c != searchResult.cardNumber) {
                        caseToUpdate.LoyaltyCardID__c = searchResult.cardNumber;
                        updateCase = true;
                    }
                }

                if (searchResult.cardActivationDate != null) {
                    if (c.AccountId != null) {
                        if (c.Account.LoyaltyCreationDate__pc != searchResult.cardActivationDate) {
                            accToUpdate.LoyaltyCreationDate__pc = searchResult.cardActivationDate;
                        }
                    }
                }

                if (searchResult.firstName != null && String.isNotBlank(searchResult.firstName)) {
                    if (c.AccountId != null) {
                        if (c.Account.FirstName != searchResult.firstName) {
                            accToUpdate.FirstName = searchResult.firstName;
                        }
                    }

                    if (c.FirstName__c != searchResult.firstName) {
                        caseToUpdate.FirstName__c = searchResult.firstName;
                        updateCase = true;
                    }
                }

                if (searchResult.lastName != null && String.isNotBlank(searchResult.lastName)) {
                    if (c.AccountId != null) {
                        if (c.Account.LastName != searchResult.lastName) {
                            accToUpdate.LastName = searchResult.lastName;
                        }
                    }

                    if (c.LastName__c != searchResult.lastName) {
                        caseToUpdate.LastName__c = searchResult.lastName;
                        updateCase = true;
                    }
                }

                if (searchResult.emailAddress != null && String.isNotBlank(searchResult.emailAddress)) {
                    if (c.AccountId != null) {
                        if (c.Account.PersonEmail != searchResult.emailAddress) {
                            accToUpdate.PersonEmail = searchResult.emailAddress;
                        }
                    }

                    if (c.SuppliedEmail != null) {
                        if (c.SuppliedEmail != searchResult.emailAddress) {
                            c.SuppliedEmail = searchResult.emailAddress;
                            updateCase = true;
                        }
                    }
                }
            }

            if (searchResult.searchChannel == MAGASIN_PHISIQUE_SEARCH_CHANNEL) {
                primaryChannelDataUpdated = true;
            } else {
                secondaryChannelDataUpdated = true;
            }
        }

        if (accToUpdate.Id != null) {
            accountsToUpdate.add(accToUpdate);
        }

        if (updateCase) {
            casesToUpdate.add(caseToUpdate);
        }
    }

    /**
     * @author Denys Taldykin
     * @date January 05, 2023
     * @name updateAccountPreferredStore
     * @description Method to query and update Account Preferred Store
     * @param accToUpdate Account
     * @param storeId String
     * @param searchChannel String
     */
    private static void updateAccountStore(Account accToUpdate, String storeId, String searchChannel) {
        List<Account> stores = [SELECT Id, StoreId__c FROM Account WHERE StoreId__c = :storeId AND RecordTypeId = :STORE_ACCOUNT_RT_ID];
        for (Account s : stores) {
            if (searchChannel == MAGASIN_PHISIQUE_SEARCH_CHANNEL) {
                accToUpdate.Magasin_de_rattachement__c = s.Id;
            } else {
                accToUpdate.PreferedStore__c = s.Id;
            }

            break;
        }
    }

    /**
     * @author Denys Taldykin
     * @date January 05, 2023
     * @name getRXPData
     * @description Method to get data from RXP
     * @param emailAddress String
     * @param cardNumber String
     * @param channel String
     * @return HttpResponse
     */
    public HttpResponse getRXPData(String emailAddress, String cardNumber, String channel) {
        String endpoint = 'callout:RXP_Credentials';
        Map<String, String> headers = new Map<String, String>();
        String requestBody = this.getRequestBody(emailAddress, cardNumber, channel);
        String accessToken = getToken();
        Integer timeout = SETTINGS.Request_Timeout__c != null ? (Integer) SETTINGS.Request_Timeout__c : 2000;

        headers.put(SC_CalloutService.AUTHORIZATION, 'Bearer ' + accessToken);
        headers.put(SC_CalloutService.CONTENT_TYPE, SC_CalloutService.CONTENT_TYPE_JSON);

        return SC_CalloutService.executeRequest(SC_CalloutService.POST_METHOD, endpoint, requestBody, headers, timeout);
    }


    /**
     * @author Denys Taldykin
     * @date January 05, 2023
     * @name getRequestBody
     * @description Method to prepare request body
     * @param emailAddress String
     * @param cardNumber String
     * @param searchChannel String
     * @return String
     */
    private String getRequestBody(String emailAddress, String cardNumber, String searchChannel) {
        Map<String, Object> searchRequest = new Map <String, Object>();
        Map<String, Object> searchParameters = new Map<String, Object>();
        Map<String, String> contactSearchParameters = new Map<String, String>();

        contactSearchParameters.put(CHANNEL_ATTRIBUTE_NAME, searchChannel);

        if (searchChannel == MAGASIN_PHISIQUE_SEARCH_CHANNEL) {
            if (cardNumber != null) {
                contactSearchParameters.put(CARD_SEARCH_ATTRIBUTE_NAME, cardNumber);
                searchParameters.put(CONTACT_ALIAS_ATTRIBUTE_NAME, contactSearchParameters);
            } else {
                contactSearchParameters.put(EMAIL_ATTRIBUTE_NAME, emailAddress);
                searchParameters.put(CHANNEL_EMAIL_ATTRIBUTE_NAME, contactSearchParameters);
            }
        } else {
            contactSearchParameters.put(EMAIL_ATTRIBUTE_NAME, emailAddress);
            searchParameters.put(CONTACT_ALIAS_ATTRIBUTE_NAME, contactSearchParameters);
        }

        searchRequest.put(SEARCH_ATTRIBUTE_NAME, searchParameters);

        return JSON.serialize(searchRequest);
    }

    /**
      * @author Denys Taldykin
      * @date January 05, 2023
      * @name parseRXPCustomerData
      * @description Method to parse RXP response data
      * @param rxpResponse HttpResponse
      * @param searchChannel String
      * @param searchByCardNumber Boolean
      * @return RXPCustomerSearchResultWrapper
      */
    private static RXPCustomerSearchResultWrapper parseRXPCustomerData(HttpResponse rxpResponse, String searchChannel, Boolean searchByCardNumber) {
        String responseBody = rxpResponse.getBody();
        Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        Map<String, Object> personObjMap;
        List<Object> customersList;
        List<Object> chanelObjList;
        Map<String, Object> chanelMap;
        Map<String, Object> contactMap;
        List<Object> contactsObjList;
        Map<String, Object> cardMap;
        Map<String, Object> emailMap;
        String lastName;
        String firstName;
        String cardNumber;
        String emailAddress;
        String preferredStoreId;
        String homeStoreId;
        Date cardActivationDate;
        String cardActivationDateString;
        Boolean customerFound = true;
        String responseMessage;

        if (resMap.containsKey(REQUEST_STATUS_MESSAGE_ATTRIBUTE_NAME)) {
            if (resMap.get (REQUEST_STATUS_MESSAGE_ATTRIBUTE_NAME) != null) {
                responseMessage = (String) resMap.get (REQUEST_STATUS_MESSAGE_ATTRIBUTE_NAME);

                if (responseMessage == REQUEST_ERROR_STATUS_MESSAGE) {
                    customerFound = false;

                    return null;
                }
            } else {
                return null;
            }
        }

        if (resMap.containsKey(PERSON_ATTRIBUTE_NAME)) {
            if (!searchByCardNumber && searchChannel == MAGASIN_PHISIQUE_SEARCH_CHANNEL) {
                customersList = (List<Object>) resMap.get (PERSON_ATTRIBUTE_NAME);
                for (Object personObj : customersList) {
                    personObjMap = (Map<String, Object>) personObj;
                    break;
                }
            } else {
                personObjMap = (Map<String, Object>) resMap.get (PERSON_ATTRIBUTE_NAME);
            }

            if (personObjMap.containsKey(FIRST_NAME_ATTRIBUTE_NAME)) {
                firstName = (String) personObjMap.get (FIRST_NAME_ATTRIBUTE_NAME);
            }
            if (personObjMap.containsKey(LAST_NAME_ATTRIBUTE_NAME)) {
                lastName = (String) personObjMap.get (LAST_NAME_ATTRIBUTE_NAME);
            }

            if (personObjMap.containsKey(CHANEL_ATTRIBUTE_NAME)) {
                chanelObjList = (List<Object>) personObjMap.get (CHANEL_ATTRIBUTE_NAME);

                for (Object chanelObj : chanelObjList) {
                    chanelMap = (Map<String, Object>) chanelObj;

                    if (chanelMap.containsKey(CHANNEL_CODE_ATTRIBUTE_NAME) && chanelMap.containsKey(CONTACT_STATUS_ATTRIBUTE_NAME)) {
                        if ((String) chanelMap.get (CHANNEL_CODE_ATTRIBUTE_NAME) == searchChannel && (String) chanelMap.get(CONTACT_STATUS_ATTRIBUTE_NAME) == CONTACT_STATUS_ACTIVE) {

                            if (chanelMap.containsKey(PREFERRED_STORE_ATTRIBUTE_NAME)) {
                                if (searchChannel == MAGASIN_PHISIQUE_SEARCH_CHANNEL) {
                                    homeStoreId = (String) chanelMap.get (PREFERRED_STORE_ATTRIBUTE_NAME);
                                } else {
                                    preferredStoreId = (String) chanelMap.get (PREFERRED_STORE_ATTRIBUTE_NAME);
                                }
                            }

                            if (chanelMap.containsKey(CONTACTS_ATTRIBUTE_NAME) && chanelMap.get(CONTACTS_ATTRIBUTE_NAME) != null) {
                                contactsObjList = (List<Object>) chanelMap.get(CONTACTS_ATTRIBUTE_NAME);

                                for (Object c : contactsObjList) {
                                    contactMap = (Map<String, Object>) c;
                                    if (contactMap.containsKey(CONTACT_TYPE_ATTRIBUTE_NAME) && contactMap.get(CONTACT_TYPE_ATTRIBUTE_NAME) != null) {
                                        if (contactMap.containsKey(CARD_ATTRIBUTE_NAME) && contactMap.get(CARD_ATTRIBUTE_NAME) != null && (String) contactMap.get(CONTACT_TYPE_ATTRIBUTE_NAME) == CARD_ATTRIBUTE_VALUE) {
                                            cardMap = (Map<String, Object>) contactMap.get(CARD_ATTRIBUTE_NAME);
                                            if (cardMap.containsKey(CARD_STATUS_ATTRIBUTE_NAME) && cardMap.get(CARD_STATUS_ATTRIBUTE_NAME) != null && cardMap.get(CARD_STATUS_ATTRIBUTE_NAME) == CARD_STATUS_ACTIVE) {
                                                if (cardMap.containsKey(CARD_U_ATTRIBUTE_NAME) && cardMap.containsKey(CARD_U_ATTRIBUTE_NAME) != null) {
                                                    cardNumber = (String) cardMap.get(CARD_U_ATTRIBUTE_NAME);
                                                }
                                                if (cardMap.containsKey(CARD_ACTIVATION_DATE_ATTRIBUTE_NAME) && cardMap.get(CARD_ACTIVATION_DATE_ATTRIBUTE_NAME) != null) {
                                                    cardActivationDateString = (String) cardMap.get (CARD_ACTIVATION_DATE_ATTRIBUTE_NAME);
                                                    cardActivationDate = Date.newInstance(Integer.valueOf(cardActivationDateString.left(4)), Integer.valueOf(cardActivationDateString.mid(4, 2)), Integer.valueOf(cardActivationDateString.right(2)));
                                                }
                                            }
                                        }

                                        if (contactMap.containsKey(CONTACT_TYPE_ATTRIBUTE_NAME) && contactMap.get (CONTACT_TYPE_ATTRIBUTE_NAME) != null && (String) contactMap.get (CONTACT_TYPE_ATTRIBUTE_NAME) == EMAIL_ATTRIBUTE_VALUE) {
                                            emailMap = (Map<String, Object>) contactMap.get (EMAIL_ATTRIBUTE_NAME);

                                            if (emailMap.containsKey(EMAIL_VALUE_ATTRIBUTE_NAME) && emailMap.containsKey(EMAIL_VALUE_ATTRIBUTE_NAME) != null) {
                                                emailAddress = (String) emailMap.get (EMAIL_VALUE_ATTRIBUTE_NAME);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        return new RXPCustomerSearchResultWrapper(searchChannel, customerFound, emailAddress, cardNumber, cardActivationDate, firstName, lastName, preferredStoreId, homeStoreId, searchByCardNumber);
    }

    /**
     * @author Denys Taldykin
     * @date January 05, 2023
     * @name authorizeRXP
     * @description Method to make Authorization callout to retrieve Access Token
     */
    @TestVisible
    private static void authorizeRXP() {
        if (SETTINGS.Id == null) {
            SETTINGS = new SC_RXPConnectionSettings__c();
            SETTINGS.SetupOwnerId = UserInfo.getOrganizationId();
            SETTINGS.TokenExpirationDate__c = Datetime.now().addSeconds(-10);
            SETTINGS.Token__c = '';
            SETTINGS.Token_1__c = '';
            SETTINGS.Token_2__c = '';
            SETTINGS.Token_3__c = '';
            SETTINGS.Token_4__c = '';
            SETTINGS.Token_5__c = '';
            SETTINGS.Token_6__c = '';
            SETTINGS.Token_7__c = '';

            SETTINGS.Request_Timeout__c = 2000;
        }

        Integer timeout = SETTINGS.Request_Timeout__c != null ? (Integer) SETTINGS.Request_Timeout__c : 2000;

        if (!tokenIsValid()) {
            String endpoint = 'callout:RXP_Auth';
            Map<String, String> headers = new Map<String, String>();
            HttpResponse res;
            Map<String, Object> jsonMap;
            String token;
            Datetime expiryDate;

            headers.put(SC_CalloutService.CONTENT_TYPE, SC_CalloutService.CONTENT_TYPE_URL);
            res = SC_CalloutService.executeRequest(SC_CalloutService.GET_METHOD, endpoint, SC_CalloutService.GRANT_TYPE_CLIENT_CREDENTIALS, headers, timeout);
            jsonMap = (Map<String, Object>) System.JSON.deserializeUntyped(res.getBody());

            if (res.getStatusCode() == 200) {
                if (jsonMap.containsKey('access_token') && jsonMap.containsKey('expires_in')) {
                    token = (String) jsonMap.get ('access_token');
                    expiryDate = Datetime.now().addSeconds(Integer.valueOf(jsonMap.get ('expires_in')));

                    SETTINGS.TokenExpirationDate__c = expiryDate;
                    setToken(token);

                    updateSettings = true;
                }
            }
        }
    }

    /**
     * @author Denys Taldykin
     * @date December 28, 2023
     * @name getToken
     * @description Method to get Token
     * @return String
     */
    public static String getToken() {
        String token = '';

        if (String.isNotBlank(SETTINGS.Token__c)) {
            token = token + SETTINGS.Token__c;
        }
        if (String.isNotBlank(SETTINGS.Token_1__c)) {
            token = token + SETTINGS.Token_1__c;
        }
        if (String.isNotBlank(SETTINGS.Token_2__c)) {
            token = token + SETTINGS.Token_2__c;
        }
        if (String.isNotBlank(SETTINGS.Token_3__c)) {
            token = token + SETTINGS.Token_3__c;
        }
        if (String.isNotBlank(SETTINGS.Token_4__c)) {
            token = token + SETTINGS.Token_4__c;
        }
        if (String.isNotBlank(SETTINGS.Token_5__c)) {
            token = token + SETTINGS.Token_5__c;
        }
        if (String.isNotBlank(SETTINGS.Token_6__c)) {
            token = token + SETTINGS.Token_6__c;
        }
        if (String.isNotBlank(SETTINGS.Token_7__c)) {
            token = token + SETTINGS.Token_7__c;
        }

        return token;
    }

    /**
     * @author Denys Taldykin
     * @date December 28, 2023
     * @name setToken
     * @description Method to set token
     */
    public static void setToken(String token) {
        Integer fieldSize = 250;
        Integer tokenLength = token.length();
        Decimal numberOfIterations = tokenLength / fieldSize;
        Integer numberOfIterationsInt = numberOfIterations.intValue();
        numberOfIterationsInt = numberOfIterations - Decimal.valueOf(numberOfIterationsInt) > 0 ? numberOfIterationsInt++ : numberOfIterationsInt;

        SETTINGS.Token__c = '';
        SETTINGS.Token_1__c = '';
        SETTINGS.Token_2__c = '';
        SETTINGS.Token_3__c = '';
        SETTINGS.Token_4__c = '';
        SETTINGS.Token_5__c = '';
        SETTINGS.Token_6__c = '';
        SETTINGS.Token_7__c = '';

        for (Integer index = 0; index <= numberOfIterationsInt; index++) {
            switch on index {
                when 0 {
                    SETTINGS.Token__c = token.mid(0, fieldSize);
                }
                when 1 {
                    SETTINGS.Token_1__c = token.mid(index * fieldSize, fieldSize);
                }
                when 2 {
                    SETTINGS.Token_2__c = token.mid(index * fieldSize, fieldSize);
                }
                when 3 {
                    SETTINGS.Token_3__c = token.mid(index * fieldSize, fieldSize);
                }
                when 4 {
                    SETTINGS.Token_4__c = token.mid(index * fieldSize, fieldSize);
                }
                when 5 {
                    SETTINGS.Token_5__c = token.mid(index * fieldSize, fieldSize);
                }
                when 6 {
                    SETTINGS.Token_6__c = token.mid(index * fieldSize, fieldSize);
                }
                when 7 {
                    SETTINGS.Token_7__c = token.mid(index * fieldSize, fieldSize);
                }
            }
        }
    }

    /**
     * @author Denys Taldykin
     * @date January 05, 2023
     * @name tokenIsValid
     * @description Method to check if token is valid
     * @return Boolean
     */
    private static Boolean tokenIsValid() {
        if (SETTINGS.TokenExpirationDate__c == null || SETTINGS.Token__c == null) {
            return false;
        } else {
            if (SETTINGS.TokenExpirationDate__c < Datetime.now()) {
                return false;
            } else {
                return true;
            }
        }
    }

    /**
    * @author Denys Taldykin
    * @date January 05, 2023
    * @name RXPCustomerDataWrapper
    * @description Customer Data Wrapper
    */
    public class RXPCustomerDataWrapper {
        public String caseType;
        public List<RXPCustomerSearchResultWrapper> searchResults;

        public RXPCustomerDataWrapper(String caseType) {
            this.caseType = caseType;
            this.searchResults = new List<RXPCustomerSearchResultWrapper>();
        }
    }

    /**
     * @author Denys Taldykin
     * @date January 05, 2023
     * @name RXPCustomerSearchResultWrapper
     * @description CustomerDataWrapper
     */
    public class RXPCustomerSearchResultWrapper {
        public String searchChannel;
        public Boolean customerFound;
        public Boolean searchByCardNumber = false;
        public String cardNumber;
        public Date cardActivationDate;
        public String emailAddress;
        public String firstName;
        public String lastName;
        public String preferredStoreId;
        public String homeStoreId;

        public RXPCustomerSearchResultWrapper(String searchChannel, Boolean customerFound, String emailAddress, String cardNumber, Date cardActivationDate, String firstName, String lastName, String preferredStoreId, String homeStoreId, Boolean searchByCardNumber) {
            this.searchChannel = searchChannel;
            this.customerFound = customerFound;
            this.cardNumber = cardNumber;
            this.cardActivationDate = cardActivationDate;
            this.emailAddress = emailAddress;
            this.firstName = firstName;
            this.lastName = lastName;
            this.preferredStoreId = preferredStoreId;
            this.homeStoreId = homeStoreId;
            this.searchByCardNumber = searchByCardNumber;
        }
    }
}