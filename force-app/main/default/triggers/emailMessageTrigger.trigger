trigger emailMessageTrigger on EmailMessage (before insert) {
    for(EmailMessage em : Trigger.new) {
        if(em.Incoming == true && em.fromAddress == Label.FORWARDING_SENDER_EMAIL && em.Subject == 'Contact au formulaire') {
            String senderEmail = em.textbody.substringBetween('Adresse email de l\'émetteur : ', 'Nom et prénom de l\'émetteur :');
            String senderName = em.textbody.substringBetween('Nom et prénom de l\'émetteur : ', 'Numéro de carte U de l\'émetteur :');
            
            if(!String.isEmpty(senderEmail)) em.fromAddress = senderEmail.trim().replaceAll('(\\r|\\n)+', '');
            if(!String.isEmpty(senderName)) em.fromName = senderName.trim().replaceAll('(\\r|\\n)+', '');
        } else if(em.Incoming == true && em.fromAddress == 'no-reply@coursesu.com' && em.Subject.endsWith('Demande liée à la carte U')) {
            String senderEmail = em.textbody.substringBetween('E-mail = ', 'Téléphone =');
            String senderName = em.textbody.substringBetween('Nom = ', 'E-mail = ');
            
            if(!String.isEmpty(senderEmail)) em.fromAddress = senderEmail.trim().replaceAll('(\\r|\\n)+', '');
            if(!String.isEmpty(senderName)) em.fromName = senderName.trim().replaceAll('(\\r|\\n)+', '');
        }
    }
}