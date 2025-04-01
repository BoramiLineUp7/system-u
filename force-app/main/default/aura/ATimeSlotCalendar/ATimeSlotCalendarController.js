({
    captchaValidated : function(component, event, helper) {

    },
    handleValidateCaptcha: function(component, event, helper){
        component.find("GoogleRecaptcha").validateCaptcha();
    },
    handleReset: function(component, event, helper){
        component.set("v.token",undefined);
        component.find("GoogleRecaptcha").reset();
    },
})