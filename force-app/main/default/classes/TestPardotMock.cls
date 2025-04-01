/**
* @author : Nicolas Greard (ngreard@salesforce.com)
* @date : 23/04/2020
* @description : global heroku mock class
* @history : 
*/
@isTest
public class TestPardotMock implements HttpCalloutMock {
    private Integer HttpCode = 200;

    public TestPardotMock() {}

    public TestPardotMock(Integer HttpCode) {
        this.HttpCode = HttpCode;
    }

    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type','application/json');
        response.setStatusCode(this.HttpCode);

        String endpoint = request.getEndpoint();
        System.debug(LoggingLevel.DEBUG,'endpoint: ' + endpoint);
        String str = '';

        if(endpoint.contains('pardot.com/api/login')){
            str = '<api_key>AZERTYUIOPQSDFGHJKLMWXCVBN</api_key>';
        }
        else if(endpoint.contains('pardot.com/api/prospect')){
            str = '<id>1234567890</id>';
        }
        else if(endpoint.contains('pardot.com/api/email')){
            str = '<res>OK</rest>';
        }
        else if(endpoint.contains('Heroku')){
            str = '';
        }
        else if(endpoint.contains('reCaptcha')){
            reCaptchaUtils.GoogleResponse resp = new reCaptchaUtils.GoogleResponse();
            resp.success = true;
            str = JSON.serialize(resp);
        }
        
        response.setBody(str);
        return response;

    }
}