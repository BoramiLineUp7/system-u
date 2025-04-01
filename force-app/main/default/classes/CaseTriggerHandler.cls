public with sharing class CaseTriggerHandler {

    public static final String PERSON_ACCOUNT_RECORDTYPE_DEVELOPER_NAME = 'Client';

    public static void beforeInsert(List<Case> cases) {
        //If no Contact/Account provided, it's populated is populated from based on SuppliedEmail. If no Contact found (Personal Account), new created
        Set<String> emailAddressesToParseCaseDescription = new Set<String>();
        emailAddressesToParseCaseDescription.addAll(Label.EMAIL_TO_CASE_EMAIL_ADDRESSES.split(';'));
        system.debug('Start point = '+cases.size());
        //Contains Supplied Emails for cases without Accounts + the list of Cases Id concerned by that email
        Map<String, Case> suppliedEmails = new Map<String, Case>();
        //We retrieve the record type for Personal Account
        Id pAccountRecordType = getPersonAccountRecordTypeId();
        system.debug('Account Record Type = '+pAccountRecordType);
        List<Account> accountsToUpdate = new List<Account>();
        Set<String> storeIds = new Set<String>();
        Map<String, Id> storesByStoreId = new Map<String, Id>();

        for (Case c : cases) {
            if (emailAddressesToParseCaseDescription.contains(c.SuppliedEmail) && c.Subject.endsWith('Demande liée au site') && !String.isEmpty(c.Description)) {
                String storeId = findStoreIdAttributeValue('Code du magasin : ', c.Description);
                if (storeId != ''){
                    storeIds.add(storeId);
                }
            }
        }

        if (!storeIds.isEmpty()) {
            storesByStoreId = getStoreIdsByExtStoreIds(storeIds);
        }

        for (Case c : cases){
            system.debug('Case = '+c.SuppliedEmail);
            String originalSuppliedEmail = c.SuppliedEmail;
            Boolean emailToCaseSourced = false;

            //manage email forwarding
            if(c.SuppliedEmail == Label.FORWARDING_SENDER_EMAIL && c.Subject == 'Contact au formulaire' && !String.isEmpty(c.Description)) {
                String senderEmail = c.Description.substringBetween('Adresse email de l\'émetteur : ', 'Nom et prénom de l\'émetteur :');
                String senderName = c.Description.substringBetween('Nom et prénom de l\'émetteur : ', 'Numéro de carte U de l\'émetteur :');
                String senderCard = c.Description.substringBetween('Numéro de carte U de l\'émetteur :', 'Téléphone :');
                String senderPhone = c.Description.substringBetween('Téléphone :', 'Objet du message :');
                String senderSubject = c.Description.substringBetween('Objet du message : ', 'Corps du message :');
                String senderDesc= c.Description.substringAfter('Corps du message :');

                if(!String.isEmpty(senderEmail)) c.SuppliedEmail = senderEmail.trim().replaceAll('(\\r|\\n)+', '');
                if(!String.isEmpty(senderName)) c.SuppliedName = senderName.trim().replaceAll('(\\r|\\n)+', '');
                if(!String.isEmpty(senderCard)) c.LoyaltyCardID__c = senderCard.trim().replaceAll('(\\r|\\n)+', '');
                if(!String.isEmpty(senderPhone)) c.SuppliedPhone = senderPhone.trim().replaceAll('(\\r|\\n)+', '');
                if(!String.isEmpty(senderSubject)) c.Subject = senderSubject.trim().replaceAll('(\\r|\\n)+', '');
                if(!String.isEmpty(senderDesc)) c.Description = senderDesc;
            } else if(emailAddressesToParseCaseDescription.contains(c.SuppliedEmail) && c.Subject.endsWith('Demande liée à la carte U') && !String.isEmpty(c.Description)) {
                String senderName = c.Description.substringBetween('Nom = ', 'E-mail = ');
                String senderEmail = c.Description.substringBetween('E-mail = ', 'Téléphone =');
                String senderPhone = c.Description.substringBetween('Téléphone = ', 'Commentaire =');
                String ip = c.Description.substringBetween('IP : ', 'User agent :');
                String UserAgent = c.Description.substringBetween('User agent : ', 'Code du magasin :');


                if(!String.isEmpty(senderEmail)) c.SuppliedEmail = senderEmail.trim().replaceAll('(\\r|\\n)+', '');
                if(!String.isEmpty(senderName)) c.SuppliedName = senderName.trim().replaceAll('(\\r|\\n)+', '');
                if(!String.isEmpty(senderPhone)) c.SuppliedPhone = senderPhone.trim().replaceAll('(\\r|\\n)+', '');
                if(!String.isEmpty(ip)) c.IP__c = ip.trim().replaceAll('(\\r|\\n)+', '');
                if(!String.isEmpty(UserAgent)) c.UserAgent__c = UserAgent.trim().replaceAll('(\\r|\\n)+', '');
            } else if(emailAddressesToParseCaseDescription.contains(c.SuppliedEmail) && c.Subject.endsWith('Demande liée au site') && !String.isEmpty(c.Description)) {
                String senderName = c.Description.substringBetween('Nom = ', 'E-mail = ');
                String senderEmail = c.Description.substringBetween('E-mail = ', 'Téléphone =');
                String senderPhone = c.Description.substringBetween('Téléphone = ', 'Commentaire =');
                String ip = c.Description.substringBetween('IP : ', 'User agent :');
                String UserAgent = c.Description.substringBetween('User agent : ', 'Code du magasin :');
                String storeId = findStoreIdAttributeValue('Code du magasin : ', c.Description);

                if(!String.isEmpty(senderEmail)) c.SuppliedEmail = senderEmail.trim().replaceAll('(\\r|\\n)+', '');
                if(!String.isEmpty(senderName)) c.SuppliedName = senderName.trim().replaceAll('(\\r|\\n)+', '');
                if(!String.isEmpty(senderPhone)) c.SuppliedPhone = senderPhone.trim().replaceAll('(\\r|\\n)+', '');
                if(!String.isEmpty(ip)) c.IP__c = ip.trim().replaceAll('(\\r|\\n)+', '');
                if(!String.isEmpty(UserAgent)) c.UserAgent__c = UserAgent.trim().replaceAll('(\\r|\\n)+', '');
                if(!String.isEmpty(storeId)){
                    if(storesByStoreId.containsKey(storeId)){
                        c.Store__c = storesByStoreId.get(storeId);
                    }
                }

                c.AccountId = null;
                c.ContactId = null;
                emailToCaseSourced = true;
            }

            //Retrive list of emails to lookup in Personal Account List
            if ((c.AccountId == null && c.ContactId == null && c.SuppliedEmail != '') || emailToCaseSourced)
            {
                if (!suppliedEmails.containsKey(c.SuppliedEmail)){
                    //We add the first case encountered (required, when we need to create the Client)
                    suppliedEmails.put(c.SuppliedEmail, c);
                }
            }
        }

        //Retrive Matching Personal Accounts form Database
        Map<String,Account> myClients = getAccountByEmail(suppliedEmails.keySet(), pAccountRecordType);
        system.debug('myClients initial Size = '+myClients.size());
        //List of new Clients (the ones missing for "myClients")
        List<Account> newClients = new List<Account>();

        //Check missing emails (define new Personal Accounts to create) + get case information with it
        for (String emailValue : suppliedEmails.keySet()){
            if (myClients.get(emailValue) == null){
                //We retrieve the first occurence of that email to create the new Account
                Account theClient = createNewAccountFromCase(suppliedEmails.get(emailValue), pAccountRecordType);

                //Add to the list of New clients
                newClients.add(theClient);
            }
        }
        system.debug('NewClients Size = '+newClients.size());
        //We create the new clients
        database.insert(newClients,false);

        //We retrieve information we are missing --update our list of Clients by upserting the new Clients
        myClients = getAccountByEmail(suppliedEmails.keySet(), pAccountRecordType);
        system.debug('myClients final Size = '+myClients.size());

        //We update Cases with missing informations
        for (Case c : cases){
            if (c.AccountId == null && c.ContactId == null && c.SuppliedEmail != '' && myClients.containsKey(c.SuppliedEmail))
            {
                //Update PersonAccount (client) and associated Contact
                c.AccountId = myClients.get(c.SuppliedEmail).Id;
                c.ContactId = myClients.get(c.SuppliedEmail).PersonContactId;
            }

            if (myClients.containsKey(c.SuppliedEmail)) {
                if (myClients.get(c.SuppliedEmail).LoyaltyCardID__pc == null && c.LoyaltyCardID__c != null) {
                    accountsToUpdate.add(new Account(Id = myClients.get(c.SuppliedEmail).Id, LoyaltyCardID__pc = c.LoyaltyCardID__c));
                }
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    private static Map<String, Account> getAccountByEmail(Set<String> listOfEmails, Id recordTypeOfAccount){
        //Retrive Matching Personal Accounts form Database
        Map<String,Account> finalList = new Map<String,Account>();
        Map<Id,Account> databaseAccounts = new Map<Id, Account>([SELECT Id, Email_ID__c, PersonContactId, LoyaltyCardID__pc
        FROM Account WHERE Email_ID__c IN :listOfEmails AND RecordTypeId = :recordTypeOfAccount]);
        //Populate our map of Email -> Account
        for (Id vId : databaseAccounts.keySet()){
            finalList.put(databaseAccounts.get(vId).Email_ID__c, databaseAccounts.get(vId));
        }

        return finalList;
    }

    private static Account createNewAccountFromCase(Case c, Id accountRecordType){
        system.debug('c.Origin = '+string.valueOf(c.Origin));
        system.debug('c.FullName__c = '+string.valueOf(c.FullName__c));
        system.debug('c.LastName__c = '+string.valueOf(c.LastName__c));
        system.debug('c.FirstName__c = '+string.valueOf(c.FirstName__c));
        system.debug('c.SuppliedName = '+string.valueOf(c.SuppliedName));

        if (c.Origin == 'Email') {
            // Pour le email-2-case on est forcement en guest.
            c.ContactasGuest__c = true;

            //Cas specifique du Email-to-case (et non pas à la reprise de données)
            if (String.isBlank(c.FullName__c) && !String.isBlank(c.SuppliedName)){
                c.FullName__c = c.SuppliedName;
            }
        }

        Account myAccount = new Account (
                CDV__pc=c.CDV__c,
                CommerceCloudId__pc=c.CommerceCloudId__c,
                FirstName=c.FirstName__c,
                LastName=c.ContactasGuest__c ? c.FullName__c : c.LastName__c,
                LoyaltyBirthdate__pc=c.LoyaltyBirthdate__c,
                LoyaltyCardID__pc=c.LoyaltyCardID__c,
                LoyaltyCreationDate__pc=c.LoyaltyCreationDate__c,
                LoyaltyFirstName__pc=c.LoyaltyFirstName__c,
                LoyaltyLastName__pc=c.LoyaltyLastName__c,
                NewsletterStatus__pc=c.NewsletterStatus__c,
                PersonEmail=c.SuppliedEmail,
                PersonMobilePhone=c.MobilePhone__c,
                PersonHomePhone=c.HomePhone__c,
                Phone=c.Phone__c,
                //PreferedStore__c='SessionStoreId__c base',
                RFM__pc=c.RFM__c,
                RecordTypeId=accountRecordType,
                SDC__pc=c.SDC__c,
                Salutation=c.Salutation__c,
                VCA__pc=c.VCA__c,
                WorldlineId__pc=c.WorldlineId__c
        );

        return myAccount;
    }

    /**
     * @author Denys Taldykin
     * @date April 27, 2023
     * @name findStoreIdAttributeValue
     * @description method to extract StoreId attribute value
     * @param startText String
     * @param searchString String
     * @return String
     */
    public static String findStoreIdAttributeValue(String startText, String searchString) {
        String textFound = '';
        Integer startIndex;
        Integer endIndex = 6 + startText.length();

        if (searchString.contains(startText)) {
            startIndex = searchString.indexOf(startText);

            textFound = searchString.mid(startIndex, endIndex);
            textFound = textFound.replace(startText, '').trim();
        }

        return textFound;
    }

    /**
     * @author Denys Taldykin
     * @date April 27, 2023
     * @name getStoreIdsByExtStoreIds
     * @description method to query Account Ids by ext StoreId__c map
     * @param storeIds Set<String>
     * @return Map<String, Id>
     */
    public static Map<String, Id> getStoreIdsByExtStoreIds(Set<String> storeIds) {
        Map<String, Id> storeIdsByExtStoreIds = new Map<String, Id>();
        Set<String> storeExtIds = new Set<String>();
        List<Account> storeAccounts;

        storeAccounts = [SELECT Id, StoreId__c FROM Account WHERE StoreId__c IN :storeIds AND StoreId__c != NULL];

        for (Account a : storeAccounts) {
            storeIdsByExtStoreIds.put(a.StoreId__c, a.Id);
        }

        return storeIdsByExtStoreIds;
    }

    private static Id getPersonAccountRecordTypeId(){
        return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PERSON_ACCOUNT_RECORDTYPE_DEVELOPER_NAME).getRecordTypeId();
    }
}