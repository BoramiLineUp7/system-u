@isTest
private class CaseTriggerHandlerTest {
    private static List<Case> createBulkCase(Integer nbOfCase) {
        List<Case> myCases = new List<Case>();
        // Set all Cases values
        for (Integer i=0; i<nbOfCase; i++){
            Case c = new Case(Status='Nouveau', Origin='Email', Priority='Moyen', FullName__c='Jean Dupond', SuppliedEmail='dupon.jean.test@salesforce.com',Description='My test case');
            myCases.add(c);
        }

        return myCases;
    }

    @isTest static void testCaseClientNotBulk(){
        //Creating first Case
        List<Case> myFirstCase = createBulkCase(1);
        //Creating 2nd one with same informations
        List<Case> mySecondCase = createBulkCase(1);

        //Inserting
        Test.startTest();
        insert myFirstCase;
        insert mySecondCase;
        Test.stopTest();
        
        //Verify Case and PersonalAccount
        List<Case> verifyFirstCase = [SELECT Id, ContactEmail, AccountId FROM Case WHERE Id IN :myFirstCase];
        System.assertEquals(1, verifyFirstCase.size());
        System.assertEquals('dupon.jean.test@salesforce.com', verifyFirstCase[0].ContactEmail);

        //Verify that second Case got same informations
        List<Case> verifySecondCase = [SELECT Id, ContactEmail, AccountId FROM Case WHERE Id IN :mySecondCase];
        System.assertEquals(1, verifySecondCase.size());
        System.assertEquals('dupon.jean.test@salesforce.com', verifySecondCase[0].ContactEmail);
        System.assertEquals(verifyFirstCase[0].AccountId, verifySecondCase[0].AccountId);
    }

    @isTest static void testCaseClientBulk(){
        //Creating first Case
        List<Case> myCases = createBulkCase(200);
        Test.startTest();
        insert myCases;
        Test.stopTest();
        
        //Verify Case and PersonalAccount
        List<Case> verifyCaseList = [SELECT Id, ContactEmail, AccountId FROM Case WHERE Id IN :myCases];
        System.assertEquals(200, verifyCaseList.size());
        for (Integer i=0; i<200; i++){
            //Check email address
            System.assertEquals('dupon.jean.test@salesforce.com', verifyCaseList[i].ContactEmail);
            //Check account Id
            System.assertEquals(verifyCaseList[0].AccountId, verifyCaseList[i].AccountId);
        }
    }
    
    @isTest static void testCaseForwarded1(){
        Test.startTest();
        Case c = new Case (
            SuppliedEmail = Label.FORWARDING_SENDER_EMAIL,
            Subject = 'Contact au formulaire',
            Origin = 'Email',
            description = 'Adresse email de l\'émetteur : alexandrinegalmar@gmail.com.test\n'+
            'Nom et prénom de l\'émetteur : GALMAR Alexandrine\n'+
            'Numéro de carte U de l\'émetteur : 89393924933065\n'+
            'Téléphone : javascript:;\n'+
            'Objet du message : Problème de connexion\n'+
            'Corps du message :\n'+
            'Bonjour, J\'ai change de téléphone et j\'ai réinstallé l\'application mais c\'est impossible ld\'enregistrer ma carte U au numéro suivant : 89393924933065 Merci de vérifier le problème Cordialement'
        );
        insert c;
        Test.stopTest();
        
        Case verifyCase = [SELECT Id, SuppliedEmail FROM Case WHERE Id = :c.Id];
        System.assertEquals('alexandrinegalmar@gmail.com.test', verifyCase.SuppliedEmail);
    }
    
    @isTest static void testCaseForwarded2(){
        Test.startTest();
        Case c = new Case (
            Origin = 'Email',
            SuppliedEmail = 'no-reply@coursesu.com',
            Subject = 'SU BELZ Demande liée à la carte U',
            description = 'Super U BELZ\n'+
            '\n'+
            'Nom = alain deruaz\n'+
            '\n'+
            'E-mail = alainderuaz@hotmail.fr.test\n'+
            '\n'+
            'Téléphone = 0620783138\n'+
            '\n'+
            'Commentaire = je ne me rappelle plus de mon code (avant il n y en avait pas je l ai fait reactiver et je n avais pas de code )bonne journée\n'+
            '\n'+
            'Informations techniques :\n'+
            '\n'+
            'IP : 78.221.72.81\n'+
            '\n'+
            'User agent : Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.67 Safari/537.36 Edg/87.0.664.47\n'+
            '\n'+
            'Code du magasin : 32895'
        );
        insert c;
        Test.stopTest();
        
        Case verifyCase = [SELECT Id, SuppliedEmail FROM Case WHERE Id = :c.Id];
        System.assertEquals('alainderuaz@hotmail.fr.test', verifyCase.SuppliedEmail);
    }
}