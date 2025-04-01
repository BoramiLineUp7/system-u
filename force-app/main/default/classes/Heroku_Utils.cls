/**
* @author : Nicolas Greard(Salesforce)
* @date : 20/04/2020
* @description : class to handle the CustomerSlots
* @last modified date/comments :
*/
public class Heroku_Utils {
    
    /**
    * @description custom exception
    */
    public class HerokuException extends Exception {}

    /**
    * @description     computeFlowchart : used to call the Compute Methode
    * @param    cs : the customer slot
    * @return   String: the Request Id 
    */
    public static String generatePDF(CustomerSlot__c cs){
        String result;

        try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Heroku' + '/api/pdf' );
            request.setMethod('POST');
            request.setTimeout(10000);
            request.setHeader('Accept', 'application/json;charset=UTF-8');
            request.setHeader('Content-Type', 'application/json');

            DataWrapper data = new DataWrapper('resa-creneaux', cs);
            //Request
            request.setBody(JSON.serialize(data));
			System.debug(LoggingLevel.DEBUG,'request: ' + request);

            HttpResponse response = http.send(request);
            // If the request is successful, parse the JSON response.
            if (response.getStatusCode() <= 299) {
                //Success
                //System.debug(LoggingLevel.DEBUG,'Response: ' + response.getBody());
                System.debug(LoggingLevel.DEBUG,'Response: ' + response.getBody().length());
                result = response.getBody();
            }
            else{
                //Error
                System.debug(LoggingLevel.DEBUG,'Response: ' + response.getBody());
                throw new HerokuException('Error generating PDF');
            }
        }
        catch(Exception e){
            throw e;
        }

        return result;
    }

    private class DataWrapper{
        String filename;
        String storeName;
        String address;
        String firstName;
        String lastName;
        String startDate;
        Integer numPers;
        String id;
        String type;

        public DataWrapper(String filename, CustomerSlot__c cs){
            //get account info
            Account a = [SELECT Name,BillingStreet,BillingPostalCode,BillingCity,BillingCountry FROM Account WHERE Id = :cs.Account__c LIMIT 1];

            this.filename = filename;
            this.storeName = a.Name;
            this.address = '' + a.BillingStreet + ' ' + a.BillingPostalCode + ' ' + a.BillingCity;
            this.firstName = cs.ProvidedFirstname__c;
            this.lastName = cs.ProvidedLastname__c;
            this.startDate = cs.ExpectedStartDatetime__c.format('dd/MM/yyyy HH:mm');
            this.numPers = Integer.valueOf(cs.ProvidedNumberOfPersons__c);
            this.id = cs.UUID__c;
            this.type = 'base64';
        }
    }
}