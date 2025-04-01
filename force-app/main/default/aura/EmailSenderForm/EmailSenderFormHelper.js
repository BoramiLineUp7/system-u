({
    getCategories : function (component){
		//Chargement des Categories
        var action = component.get("c.getListOfEmailCategory");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.listOfCategories", response.getReturnValue());
            }
            else {
                alert('Problème de connexion. Veuillez réessayer.');
                resultsToast.setParams({
                    "title": "Erreur",
                    "message": "Erreur lors du chargement de la liste des catégories : " + JSON.stringify(result.error)
                });
                resultsToast.fire();
                var errors = response.getError();
                console.error(errors);
            }
        });
        $A.enqueueAction(action);
    },
    
    getTemplates : function (component){
        //Chargement des Templates
        var action = component.get("c.getListOfTemplates");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.listOfTemplates", response.getReturnValue());
            }
            else {
                alert('Problème de connexion. Veuillez réessayer.');
                resultsToast.setParams({
                    "title": "Erreur",
                    "message": "Erreur lors du chargement de la liste des modèle : " + JSON.stringify(result.error)
                });
                resultsToast.fire();
                var errors = response.getError();
                console.error(errors);
            }
        });
        $A.enqueueAction(action);
    },
    
    showWarning : function (component){
        //Les 2 paramètres sont saisis, on affiche le warning.
        var selectedCategory = component.find("selectCategory").get("v.value");
        var selectedCategoryIndex = component.get("v.listOfCategories").findIndex(item => item.value == selectedCategory);
        var selectedTemplateId = component.find("selectTemplate").get("v.value");
        var selectedTemplateIdIndex = component.get("v.listOfTemplates").findIndex(item => item.value == selectedTemplateId);
        
        console.log("Categ "+selectedCategory);
        console.log("Categ Label "+component.get("v.listOfCategories")[selectedCategoryIndex].label);
        console.log("Templ ID "+selectedTemplateId);
        console.log("Templ Label "+component.get("v.listOfTemplates")[selectedTemplateIdIndex].label);
        
        var action = component.get("c.getNumberOfCases");
        action.setParams({ emailCategory : selectedCategory });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                document.getElementById("nbSpan").innerHTML = response.getReturnValue().toString();
                document.getElementById("catgSpan").innerHTML = component.get("v.listOfCategories")[selectedCategoryIndex].label;
                document.getElementById("tmpSpan").innerHTML = component.get("v.listOfTemplates")[selectedTemplateIdIndex].label;
                $A.util.removeClass(component.find("myWarning"), "slds-hide");
            }
            else {
                alert('Problème de connexion. Veuillez réessayer.');
                resultsToast.setParams({
                    "title": "Erreur",
                    "message": "Erreur lors du chargement du nombre de tickets : " + JSON.stringify(result.error)
                });
                resultsToast.fire();
                var errors = response.getError();
                console.error(errors);
            }
        });
        $A.enqueueAction(action);
    },
    
    sendEmails : function (component){
        var selectedCategory = component.find("selectCategory").get("v.value");
        var selectedTemplateId = component.find("selectTemplate").get("v.value");
        
        var action = component.get("c.sendEmails");
        action.setParams({ emailCategory : selectedCategory,
                          myTemplateId : selectedTemplateId });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                document.getElementById("okSpan").innerHTML = response.getReturnValue().toString();
                component.find("selectCategory").set("v.value","");
                component.find("selectTemplate").set("v.value","");
                $A.util.addClass(component.find("myWarning"), "slds-hide");
        		$A.util.addClass(component.find("inProcess"), "slds-hide");
                $A.util.removeClass(component.find("mySuccess"), "slds-hide");
            }
            else {
                alert('Problème de connexion. Veuillez réessayer.');
                resultsToast.setParams({
                    "title": "Erreur",
                    "message": "Erreur lors du chargement du nombre de tickets : " + JSON.stringify(result.error)
                });
                resultsToast.fire();
                var errors = response.getError();
                console.error(errors);
            }
        });
        $A.enqueueAction(action);
    }
})