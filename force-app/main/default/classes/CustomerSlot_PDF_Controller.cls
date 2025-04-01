/**
* @author: Nicolas Greard (salesforce)
* @date: 21/04/2020
* @description: Controller for customer slot pdf generation
*/
public without sharing class CustomerSlot_PDF_Controller {
    
    private final String qrCode;
    private final String qrCodeImg;
    private final String dateformatted;
    private final PDFDataWrapper pdfdata;

    public class PDFException extends Exception {}

    public CustomerSlot_PDF_Controller() {
        
        String data = ApexPages.currentPage().getParameters().get('data');
        System.debug(LoggingLevel.DEBUG,'Data:' + data);
        /*Map<String, String> headers = ApexPages.currentPage().getHeaders();
        for(String key : headers.keySet()){
            System.debug(LoggingLevel.DEBUG,key + ' ' + headers.get(key));
        }
        from salesforce User-Agent headers contains ApexSFDCInternal --> throw error if not ?
        */

        if(String.isNotBlank(data)){
            pdfdata = (PDFDataWrapper) JSON.deserialize(data,PDFDataWrapper.class);
            dateformatted = pdfdata.startdatetime.format('dd/MM/yyyy HH:mm');
            qrCode = 'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=' + pdfdata.uuid;

            //put the qrcode in cache
            HttpRequest request = new HttpRequest(); //Create request object
            String endpoint =  qrCode;
            System.debug(LoggingLevel.DEBUG,'endpoint:' + endpoint );
            request.setEndpoint( endpoint );	// add the endpoint to the request          
            request.setMethod('GET');	// set the method
            //request.setHeader('Content-Type', 'application/json');	// set request Header
            request.setTimeout(2000);	// Set the request timeout         

            HTTPResponse response = (new Http()).send(request);// get the response object

            Integer statusCode = response.getStatusCode();
            System.debug(LoggingLevel.DEBUG,'Connect status code:' + statusCode);
            if(!(statusCode <= 299)){
                throw new PDFException('Error http statusCode: ' + statusCode);
            }
            else{
                System.debug(LoggingLevel.DEBUG,response.getBody());
                //qrCodeImg = 'data:image/PNG;base64,' + EncodingUtil.base64Encode(response.getBodyAsBlob());
            }
        }
        else{
            throw new PDFException('Internal error');
        }
    }

    public PDFDataWrapper getPDFData(){
        return pdfdata;
    }
    public String getQRCode(){
        return qrCode;
    }
    public String getDateformatted(){
        return dateformatted;
    }
    public String getQRCodeImg(){
        return qrCodeImg;
    }
    
}