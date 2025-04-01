/*--------------------------------------------------------------*/	
/* This class for Slot Booking System in order to connect to	*/
/* to Pardot to send email notification to the customer.    	*/
/* Author: Bachir Kane. - Retail Solution Engineer           	*/
/* Email: bkane@salesforce .com									*/
/*--------------------------------------------------------------*/	
public  class SendNotificationToPardot {
  String m_apikey,m_prospectid;
    //Invokable method from appex
    @InvocableMethod(
        label = 'Confirm Slot booking via email'
        description = 'this is used to send email to customer after booking'
    )
	public static void sendEmailfromApex( List<Request> requests ) {
    	
       
        
        String userkey= requests[0].userkey;
        String useremail= requests[0].useremail;
        String password= requests[0].password;
        String firstname=requests[0].firstname;
        String lastname=requests [0].lastname;
        String shopname=requests [0].shopname;
        String emailaddress=requests[0].emailaddress;
        String bookingnumber=requests[0].bookingnumber;
        Datetime slot=requests[0].slot;
        String qrcodeurl=requests[0].qrcodeurl; 
        String campaignid=requests[0].campaignid; 
        String templateid=requests[0].templateid;
        

 		SendNotificationToPardot.Callout (requests[0].userkey, requests[0].useremail, requests[0].password, requests[0].firstname, requests [0].lastname, requests [0].shopname,requests[0].emailaddress, requests[0].bookingnumber,requests[0].qrcodeurl,requests[0].slot.format('dd-MM-yyyy HH:mm'),requests[0].campaignid, requests[0].templateid,requests[0].sfslotid,requests[0].brand,requests[0].shopaddress,requests[0].shoppostalcode,requests[0].shopcity,requests[0].numberofpeople);
            	

        
    }
    
    
    //  Methode called in asynchronous mode to callout pardot

    @future(callout=true)
 	 public static void Callout (String userkey, String useremail, String password, String firstname, String lastname, String shopname, String emailaddress, String bookingnumber,String qrcodeurl, String slotDateTime, String campaignid, String templateid, String sfslotid, String brand, String shopaddress, String shoppostalcode, String shopcity, Integer numberofpeople) {
         //--------------------------------------------------------
         // Step 1: get APIKEY
         // --------------------------------------------------------
   		HttpRequest req = new HttpRequest();
        req.setEndpoint( 'https://pi.pardot.com/api/login/version/4' );
        req.setMethod( 'POST' );
        req.setBody( 'email=' + useremail + '&password=' + password + '&user_key=' + userkey );
        
        HttpResponse res = new Http().send( req );
        
        System.debug( res );
        System.debug( res.getStatus() );
        System.debug( res.getBody() );
        
        // poor man's parsing to retrieve api key without using xml/dom parser
        String response = res.getBody();
        Integer startIdx = response.indexOf( '<api_key>' ) + 9;
        Integer endIdx = response.indexOf( '</api_key>' );
        String apikey = response.substring( startIdx, endIdx );
        System.debug( '---- api key ok  -->'+apikey );
        
			//--------------------------------------------------------
      	   // Step 2: Create the prospect in Pardot 
       	  // ---------------------------------------------------------             
        HttpRequest req2 = new HttpRequest();
        req2.setEndpoint( 'https://pi.pardot.com/api/prospect/version/4/do/create/email/'+emailaddress );
        req2.setMethod( 'POST' );
        req2.setBody( 'first_name=' + firstname + '&last_name=' + lastname +'&Shop_Name='+shopname+'&Slot_Time_P='+slotDateTime+'&QRCode_url='+qrcodeurl+'&Booking_Number='+bookingnumber+'&SF_Slot_ID='+sfslotid+'&user_key=' + userkey + '&api_key='+apikey+'&Brand='+brand+'&Shop_Address='+shopaddress+'&Shop_City='+shopcity+'&Shop_Postal_Code='+shoppostalcode+'&Number_of_people='+ String.valueOf(numberofpeople));
        
        HttpResponse resp2 = new Http().send( req2 );
        System.debug( resp2 );
        System.debug( resp2.getStatus() );
        System.debug( resp2.getBody() );
       // Get response and parse 
       
        String resbody = resp2.getBody();
        startIdx = resbody.indexOf( '<id>' ) + 4;
        endIdx = resbody.indexOf( '</id>' );
        String prospectid = resbody.substring( startIdx, endIdx );
        System.debug( 'ProspectID:'+prospectid );
         
			//--------------------------------------------------------
      	   // Step 3: Send one2one email to the prospect
       	  // --------------------------------------------------------- 

 		HttpRequest req3 = new HttpRequest();
        req3.setEndpoint( 'https://pi.pardot.com/api/email/version/4/do/send' );
        req3.setMethod( 'POST' );
        req3.setBody( 'campaign_id=' + campaignid + '&prospect_id=' + prospectid +'& email_template_id='+templateid+'&format=json&operational_email=1&user_key=' + userkey + '&api_key='+apikey );
        
        HttpResponse resp3= new Http().send( req3 );
        System.debug( resp3 );
        System.debug( resp3.getStatus() );
        System.debug( resp3.getBody() );         
         
         
    }
    
    // Invocable Variable
    public class Request {

        /*
         * Each @InvocableVariable defined in this class
         * is an input variable you can populate when calling
         * this from Process Builder or Flow.
         **/
		//0- user key 
        @InvocableVariable(
            label = 'User key'
            description = 'userkey'
            required = true
        )
        public String userkey;
        
        //1-user email
         @InvocableVariable(
            label = 'User email'
            description = 'Technical user email account to connect to pardot'
            required = true
        )
        public String useremail;
        
        //2-user password
         @InvocableVariable(
            label = 'User password'
            description = 'Technical user password  to connect to pardot'
            required = true
        )
        public String password;        
 //3-First name
         @InvocableVariable(
            label = 'first name'
            description = 'first name'
            required = false
        )
        public String firstname;
   
  	  //4-last name
         @InvocableVariable(
            label = 'last name'
            description = 'last name'
            required = false
        )
        public String lastname;
        
		//5-Shop name
         @InvocableVariable(
            label = 'Shop name'
            description = 'Shop name'
            required = false
        )
        public  String shopname;
        
        //6- customer email address
         @InvocableVariable(
            label = 'customer email address'
            description = 'Customer email address'
            required = false
        )
        public  String emailaddress;
         
         //7- booking number
         @InvocableVariable(
            label = 'booking number'
            description = 'booking number'
            required = true
        )
        public  String bookingnumber;
        
         //8-Time slot
         @InvocableVariable(
            label = 'Tome slot'
            description = 'timesolt'
            required = false
        )
        public  Datetime slot;    
  		//9-QRCode URL
         @InvocableVariable(
            label = 'QRcode'
            description = 'QCode'
            required = false
        )
        public  String qrcodeurl;  

         //10-Campaign ID
         @InvocableVariable(
            label = 'Pardot Campaign ID'
            description = 'Pardot Campaign ID'
            required = false
        )
        public  String campaignid;  
  
          //11-Email template ID
         @InvocableVariable(
            label = 'Template ID'
            description = 'Email template ID in Pardot'
            required = true
        )
        public   String templateid;  
        
         //12-SF Slot ID
         @InvocableVariable(
            label = 'SF Slot ID'
            description = 'record ID of customer slot record'
            required = true
        )
        public   String sfslotid;  
        
        //13-Brand
         @InvocableVariable(
            label = 'Brand'
            description = 'Commercial Brand'
            required = false
        )
        public   String brand;  
        
         //14-Shop Address
         @InvocableVariable(
            label = 'Shop address'
            description = 'Shop Address'
            required = false
        )
        public   String shopaddress;  
 
        //15-Chop City
         @InvocableVariable(
            label = 'Shop city'
            description = 'Shop City'
            required = false
        )
        public   String shopcity;  
        
  		 //15-Shop Postal code
         @InvocableVariable(
            label = 'Shop Postal Code'
            description = 'Shop Postal Code'
            required = false
        )
        public   String shoppostalcode; 
        
      //Number of people
         @InvocableVariable(
            label = 'Number of people'
            description = 'number of people'
            required = false
        )
        public   Integer numberofpeople;
    }
    
    
}