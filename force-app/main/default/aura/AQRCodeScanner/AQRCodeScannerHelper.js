({
    checkIfiOSSafari : function(component) {
        //webcam only works with Safari on mobile iOS Mobile device 
        //We need to be sure that user use it, if not show a warning message
        //return true if ok else false
        const uagent = navigator.userAgent;
        component.set("v.uagent",uagent);

        //test if apple mobile device
        if((/(iPad|iPhone|iPod)/gi).test(uagent)){
            return !(/CriOS/).test(uagent) && !(/FxiOS/).test(uagent) && !(/OPiOS/).test(uagent) && !(/mercury/).test(uagent);
        }
        
        return true;
    },
    showVideo : function(component) {
        component.__video.classList.remove("slds-hide");
        component.getElement().querySelector('#snap').classList.add("slds-hide");
    },
    capture : function(component){
        let that = this;
        component.__defaultsOpts.video = { facingMode: component.__shouldFaceUser ? 'user' : 'environment' }
        navigator.mediaDevices.getUserMedia(component.__defaultsOpts)
        // navigator.mediaDevices.getUserMedia({ audio: false, video: { width: 454, height: 340 } })
            .then(function(stream) {
                let video = document.querySelector('video');
                // Older browsers may not have srcObject
                if ("srcObject" in video) {
                    video.srcObject = stream;
                    component._localstream = stream;
                } else {
                    // Avoid using this in new browsers, as it is going away.
                    video.src = window.URL.createObjectURL(stream);
                }
                // video.onloadedmetadata = function(e) {
                //     video.play();
                // };
                video.onplay = $A.getCallback(function () {
                    component.set("v.canPlay",!video.paused);
                    that.showVideo(component);
                    requestAnimationFrame(function() {that.tick(component);});
                });
            })
            .catch(function(err) {
                //displayErrorMessage("There was an error with accessing the camera stream: " + err.name, err);
            });
    },
    //function to capture image from the webcam & process it with QRCode decoder
    tick: function (component) {
        if (component.__video.readyState === component.__video.HAVE_ENOUGH_DATA) {
            component.__loadingMessage.hidden = true;
            component.__canvasElement.hidden = false;
    
            component.__canvasElement.height = component.__video.videoHeight;
            component.__canvasElement.width = component.__video.videoWidth;
            component.__canvas.drawImage(component.__video, 0, 0, component.__canvasElement.width, component.__canvasElement.height);
            let imageData = component.__canvas.getImageData(0, 0, component.__canvasElement.width, component.__canvasElement.height);
            let code = jsQR(imageData.data, imageData.width, imageData.height, {inversionAttempts: "dontInvert"});
            //component.set("v.count",component.get("v.count")+1);
            if (code && code.data != '') {
                component.set("v.code",code.data);
            } else {
            //requestAnimationFrame(tick);
            }
        }
        let that = this;
        requestAnimationFrame(function() {that.tick(component);});
    }
})