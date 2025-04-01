/*************************************************************************************
 * @Name         : SC_CalloutService.cls
 * @Description  : Class for handling callouts
 * @Created By   : Denys Taldykin
 * @Created Date : December 3, 2023
 * @Modification Log:
 **************************************************************************************
 * Version     Developer      Date        Description
 *-------------------------------------------------------------------------------------
 *
 *************************************************************************************/
public with sharing class SC_CalloutService {
    public static final String GET_METHOD = 'GET';
    public static final String POST_METHOD = 'POST';
    public static final String PATCH_METHOD = 'PATCH';
    public static final String GRANT_TYPE_CLIENT_CREDENTIALS = 'grant_type=client_credentials';
    public static final String AUTHORIZATION = 'Authorization';
    public static final String CONTENT_TYPE = 'Content-Type';
    public static final String CONTENT_TYPE_JSON = 'application/json;';
    public static final String CONTENT_TYPE_URL = 'application/x-www-form-urlencoded';

    /**
     * @author Denys Taldykin
     * @date December 3, 2023
     * @name executeRequest
     * @description do http request by endpoint, method and body
     * @param method String
     * @param endpoint String
     * @param body String
     * @param headers Map<String, String>
     * @param timeout Integer
     * @return HttpResponse
     */
    public static HttpResponse executeRequest(String method, String endpoint, String body, Map<String, String> headers, Integer timeout) {
        Http https = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res;

        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setTimeout(timeout);

        for (String header : headers.keySet()) {
            req.setHeader(header, headers.get(header));
        }

        req.setBody(body);

        res = https.send(req);

        return res;
    }
}