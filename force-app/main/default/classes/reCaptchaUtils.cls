/**
* @author: Nicolas Greard (salesforce.com)
* @date: 21/04/2020
* @description: to validate recaptcha token provided by user interface
*/
public with sharing class reCaptchaUtils {

	public class GoogleResponse {
		public Boolean success;
		public String challenge_ts;
		public String hostname;
		public List<String> errorcodes;		
	}

	public class GoogleException extends Exception {}
	
	public static GoogleResponse parse(String json) {
		return (GoogleResponse) System.JSON.deserialize(json, GoogleResponse.class);
	}

	public static Boolean validateToken(String secretKey, String token){
		Boolean success = false;
		try {
            HttpRequest request = new HttpRequest(); //Create request object
            String endpoint = 'callout:reCaptcha' ;
            endpoint += '?secret=' + secretKey;
            endpoint += '&response=' + token;
            System.debug(LoggingLevel.DEBUG,'endpoint:' + endpoint );
            request.setEndpoint( endpoint );	// add the endpoint to the request          
            request.setMethod('GET');	// set the method
            request.setHeader('Content-Type', 'application/json');	// set request Header
            request.setTimeout(2000);	// Set the request timeout         

            HTTPResponse response = (new Http()).send(request);// get the response object

            Integer statusCode = response.getStatusCode();
            System.debug(LoggingLevel.DEBUG,'Connect status code:' + statusCode);
            if(!(statusCode <= 299)){
                throw new GoogleException('Erreur appel Google http statusCode: ' + statusCode);
            }

            if (null!=response && null != response.getBody()) {
            	String body = response.getBody();
            	System.debug(LoggingLevel.DEBUG,body);
            	GoogleResponse r = parse(body);
            	return r.success;
            }
        }
        catch (Exception excptn) {
            System.debug(LoggingLevel.DEBUG,excptn.getMessage());
        }

        return success;

	}

}