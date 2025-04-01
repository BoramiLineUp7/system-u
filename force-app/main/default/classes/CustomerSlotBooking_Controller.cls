/**
* @author : Nicolas Greard(Salesforce)
* @date : 20/04/2020
* @description : class to handle the CustomerSlots
* @last modified date/comments :
*/
public without sharing class CustomerSlotBooking_Controller {
    //without sharing due to usage as guest user (better than open sharing)

    /**
    * @description searchTodayCustomerSlotByEmail
    * @param searchTerm : searchTerm (must be the email)
    * @return list of CustomerSlot__c
    */
    @AuraEnabled
    public static ResponseWrapper insertCS(String slotId,String lastName, String firstName, String email, String confirmEmail, Integer numPlaces,String token){
        System.debug(LoggingLevel.DEBUG,'slotId: ' + slotId + ' lastName: ' + lastName + ' firstName: '  + firstName + ' email: ' + email + ' numPlaces: ' + numPlaces);
        if(String.isNotBlank(slotId) && String.isNotBlank(email) && String.isNotBlank(confirmEmail)){
            if(!confirmEmail.equalsIgnoreCase(email)){
                throw new AuraHandledException(Label.CSCheckEmailsError);
            }

            String strStatus;
            try{
                reCaptcha__c captchaConfig = reCaptcha__c.getInstance();
                if(captchaConfig.isReCaptchaEnabled__c && !reCaptchaUtils.validateToken(captchaConfig.SecretKey__c,token)){
                    strStatus = Label.reCaptchaVerifFailed;
                }
            }
            catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
                System.debug(LoggingLevel.ERROR, ex.getMessage());
                System.debug(LoggingLevel.ERROR, ex.getTypeName());
                strStatus = Label.reCaptchaGenericError;
            }
            if (null!=strStatus){
                throw new AuraHandledException(strStatus);
            }

            //Get slot account
            List<Slot__c> sList = [SELECT Id,Account__c,StartDatetime__c,AvailablePositions__c,BookedPositions__c,RemainingPositions__c,
                                    Account__r.Name,Account__r.BillingStreet,Account__r.BillingPostalCode,Account__r.BillingCity,Account__r.StoreId__c
                                   FROM Slot__c 
                                   WHERE Id = :slotId];

            if(sList.isEmpty()){
                //do nothing as no slot found
                throw new AuraHandledException(Label.CSCreateUnknownSlotError);
            }
            else{
                Slot__c selectedSlot = sList[0];
                System.debug(LoggingLevel.DEBUG,'AccountId: ' + selectedSlot.Account__c);

                if(QueueBustingConfig__c.getInstance().isCheckCustomerSlotDaysEnabled__c){
                    //He/she can book up for a new slot (no more than 1 slot in a timeframe xx days)
                    Datetime startDate = selectedSlot.StartDatetime__c;
                    Datetime prevDays = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day()).addDays(Integer.valueOf( QueueBustingConfig__c.getInstance().NumberOfDaysBeforeToCheck__c));
                    Datetime nextDays = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day()).addDays(Integer.valueOf( QueueBustingConfig__c.getInstance().NumberOfDaysAfterToCheck__c));
                    List<CustomerSlot__c> currentCSSlots = [SELECT Id,Account__c,ProvidedEmail__c,Status__c,StartDatetime__c FROM CustomerSlot__c WHERE ProvidedEmail__c = :email AND Status__c IN ('Booked','Checked-In') AND StartDatetime__c >= :prevDays AND StartDatetime__c < :nextDays];
                    System.debug(LoggingLevel.DEBUG,'currentCSSlots: ' + currentCSSlots.size());
                    if(!currentCSSlots.isEmpty()){
                        throw new AuraHandledException(Label.CSCheckQuotaError);
                    }
                }

                //slot offset : increment by 10min
                //ex 40 position for 1 hour -> 17 position booked : resulting number = 20
                //Decimal timeOffsetMinutes = Math.ceil(60 * selectedSlot.BookedPositions__c / (selectedSlot.AvailablePositions__c * 10))*10;
                //System.debug(LoggingLevel.DEBUG,'timeOffsetMinutes: ' + timeOffsetMinutes);
                CustomerSlot__c toCreateCS = new CustomerSlot__c( 
                    Account__c = selectedSlot.Account__c,
                    TECH_StoreId__c = selectedSlot.Account__r.StoreId__c,
                    Slot__c = slotId,
                    ProvidedLastName__c = lastName,
                    ProvidedFirstName__c = firstName,
                    ProvidedEmail__c = email,
                    ProvidedNumberOfPersons__c = numPlaces,
                    Status__c = 'Booked',
                    ExpectedStartDatetime__c = selectedSlot.StartDatetime__c,
                    Position__c = selectedSlot.BookedPositions__c,
                    UUID__c = GuidUtil.NewGuid());

                String pdf = '';
                //render pdf with heroku
                if(QueueBustingConfig__c.getInstance().isGeneratePdfEnabled__c && 'Heroku'.equalsIgnoreCase(QueueBustingConfig__c.getInstance().PdfEngine__c) ){
                    System.debug(LoggingLevel.DEBUG,'PDF generated with Heroku');
                    pdf = Heroku_Utils.generatePDF(toCreateCS);
                }

                insert toCreateCS;

                //render with visualforce
                if(QueueBustingConfig__c.getInstance().isGeneratePdfEnabled__c && !'Heroku'.equalsIgnoreCase(QueueBustingConfig__c.getInstance().PdfEngine__c) ){
                    //data needed
                    System.debug(LoggingLevel.DEBUG,'PDF generated with Visualforce/Salesforce');
                    PDFDataWrapper pdfwrp = new PDFDataWrapper();
                    pdfwrp.uuid = toCreateCS.UUID__c;
                    pdfwrp.firstname = toCreateCS.ProvidedFirstName__c;
                    pdfwrp.lastname = toCreateCS.ProvidedLastName__c;
                    pdfwrp.startdatetime = selectedSlot.StartDatetime__c;
                    pdfwrp.numofpers = numPlaces;
                    pdfwrp.storename = selectedSlot.Account__r.Name;
                    pdfwrp.storestreet = selectedSlot.Account__r.BillingStreet;
                    pdfwrp.storepostalcode = selectedSlot.Account__r.BillingPostalCode;
                    pdfwrp.storecity = selectedSlot.Account__r.BillingCity;
                    String data = JSON.serialize(pdfwrp);
                    if(!Test.isRunningTest()){
                        Blob pdfAsBlob = new PageReference('/apex/CustomerSlotPdfGenerate?data=' + data).getContentAsPDF();
                        pdf = EncodingUtil.base64Encode(pdfAsBlob);
                    }
                }

                ResponseWrapper rw = new ResponseWrapper();
                rw.filename = QueueBustingConfig__c.getInstance().isGeneratePdfEnabled__c ? 'resa-creneaux-' + selectedSlot.StartDatetime__c.format('yyyy-MM-dd_HH-mm') + '.pdf' : '';
                rw.id = toCreateCS.UUID__c;
                System.debug(LoggingLevel.DEBUG,'pdf: ' + pdf.length());
                rw.pdf = pdf;
                return rw;
            }
        }
        else{
            throw new AuraHandledException(Label.CSCheckRequiredFieldsError);
        }
    }

    public class ResponseWrapper{
        @AuraEnabled
        public String filename;
        @AuraEnabled
        public String pdf;
        @AuraEnabled
        public String id;
    }
}