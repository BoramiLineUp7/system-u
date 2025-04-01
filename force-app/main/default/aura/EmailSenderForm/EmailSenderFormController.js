({
	doInit : function(component, event, helper) {
		//Chargement des Categories
        helper.getCategories(component);
        
        //Chargement des Templates
        helper.getTemplates(component);
	},
    
    doChangeSelected: function (component, event, helper) {
        //Sur changement d'une selection (Template ou Catégorie) - On affiche le warning si les 2 sont renseignés
        $A.util.addClass(component.find("mySuccess"), "slds-hide");
        $A.util.addClass(component.find("myWarning"), "slds-hide");
        $A.util.addClass(component.find("inProcess"), "slds-hide");
        
        if (component.find("selectCategory").get("v.value") != "" && component.find("selectTemplate").get("v.value")!=""){
            helper.showWarning(component);
        }
    },
    
    doSendEmails : function (component, event, helper) {
        //Message de patience
        $A.util.addClass(component.find("mySuccess"), "slds-hide");
        $A.util.addClass(component.find("myWarning"), "slds-hide");
        $A.util.removeClass(component.find("inProcess"), "slds-hide");
        
        //Envoi des messages
        helper.sendEmails(component);
    },
    
    annulation : function (component, event, helper) {
        location.reload(true);
    }
    
})