/**
* @author : Nicolas Greard (ngreard@salesforce.com)
* @date : 23/04/2020
* @description : global heroku mock class
* @history : 
*/
@isTest
public class TestGoogleMock implements HttpCalloutMock {
    private Integer HttpCode = 200;

    public TestGoogleMock() {}

    public TestGoogleMock(Integer HttpCode) {
        this.HttpCode = HttpCode;
    }

    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type','application/json');
        response.setStatusCode(this.HttpCode);

        String endpoint = request.getEndpoint();
        System.debug(LoggingLevel.DEBUG,'endpoint: ' + endpoint);
        reCaptchaUtils.GoogleResponse resp = new reCaptchaUtils.GoogleResponse();
        resp.success = true;
        String str = JSON.serialize(resp);

        /*if(endpoint.contains('callout')){
            str = ;
        }*/
        
        response.setBody(str);
        return response;

    }
}