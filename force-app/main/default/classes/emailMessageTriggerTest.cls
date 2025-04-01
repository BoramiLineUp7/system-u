@isTest
private class emailMessageTriggerTest {
    @isTest static void testTrigger(){
        insert new EmailMessage(
            Incoming = true,
            fromAddress = Label.FORWARDING_SENDER_EMAIL,
            Subject = 'Contact au formulaire',
            textBody = 'Adresse email de l\'émetteur : alexandrinegalmar@gmail.com.test\n'+
            'Nom et prénom de l\'émetteur : GALMAR Alexandrine\n'+
            'Numéro de carte U de l\'émetteur : 89393924933065\n'+
            'Téléphone : javascript:;\n'+
            'Objet du message : Problème de connexion\n'+
            'Corps du message :\n'+
            'Bonjour, J\'ai change de téléphone et j\'ai réinstallé l\'application mais c\'est impossible ld\'enregistrer ma carte U au numéro suivant : 89393924933065 Merci de vérifier le problème Cordialement'
        );
        
        insert new EmailMessage(
            Incoming = true,
            fromAddress = 'no-reply@coursesu.com',
            Subject = 'SU BELZ Demande liée à la carte U',
            textBody = 'Super U BELZ\n'+
            '\n'+
            'Nom = alain deruaz\n'+
            '\n'+
            'E-mail = alainderuaz@hotmail.fr\n'+
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
    }
}