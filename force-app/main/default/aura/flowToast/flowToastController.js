({
    showToast: function(component, event, helper) {
        var toastParams = {
            title: component.get("v.title"),
            message: component.get("v.message"),
            type: component.get("v.type")
        };
        component.find('notifLib').showToast(toastParams);
    }
})