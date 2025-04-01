({
	init: function(a, b, c) {
		window.handleCallback = $A.getCallback(function(token){
			a.set("v.token",token);
			var e = a.getEvent('callback');
        	e.fire();
        });
        
        /*window.handleExpiredCallback = $A.getCallback(function(){
            debugger;
        });

        window.handleErrorCallback = $A.getCallback(function(){
            debugger;
        });*/

	    b = document.createElement("script");
	    b.src = "https://www.google.com/recaptcha/api.js";
	    b.type = "text/javascript";
	    b.async = "true";
	    b.onload = $A.getCallback(function() {
	        a.set("v.scriptLoaded", true);
	    });
	    (document.getElementsByTagName("head")[0] || document.getElementsByTagName("body")[0]).appendChild(b);
	},
	handleExecute : function(a, b, c){
		if(a.get("v.scriptLoaded")){
			grecaptcha.execute();
		}
	},
	handleReset : function(a, b, c){
		grecaptcha.reset();
	}
})