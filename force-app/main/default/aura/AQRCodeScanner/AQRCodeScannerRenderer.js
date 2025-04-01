/**
 * Created by lshriki on 16/05/2018.
 */
({
    // Your renderer method overrides go here
    afterRender: function (component, helper) {
        this.superAfterRender();
        
        const browserCheck = helper.checkIfiOSSafari(component);
        component.set("v.iosWarningMsg", browserCheck ? "" : $A.get("$Label.c.QRCodeiOSWarning"));
        // References to all the element we will need.
        let cmp = component.getElement();
        component.__video = cmp.querySelector('#camera-stream');
        component.__loadingMessage = cmp.querySelector('#loadingmessage');
        component.__canvasElement = cmp.querySelector("canvas");
        component.__canvas = component.__canvasElement.getContext("2d");

        component.__video.setAttribute('playsinline','');
        component.__video.setAttribute('autoplay','');
        component.__video.setAttribute('mute','');

        // Some browsers partially implement mediaDevices. We can't just assign an object
        // with getUserMedia as it would overwrite existing properties.
        // Here, we will just add the getUserMedia property if it's missing.
        if (navigator.mediaDevices.getUserMedia === undefined) {
            navigator.mediaDevices.getUserMedia = function(constraints) {

                // First get a hold of the legacy getUserMedia, if present
                var getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia;

                // Some browsers just don't implement it - return a rejected promise with an error
                // to keep a consistent interface
                if (!getUserMedia) {
                    return Promise.reject(new Error( $A.get("$Label.c.QRCodeBrowserCompatibility")));
                }

                // Otherwise, wrap the call to the old navigator.getUserMedia with a Promise
                return new Promise(function(resolve, reject) {
                    getUserMedia.call(navigator, constraints, resolve, reject);
                });
            }
        }

        let supports = navigator.mediaDevices.getSupportedConstraints();
        if( supports['facingMode'] === true ) {
            //flipBtn.disabled = false;
        }

        component.__shouldFaceUser = false; //Default is the front cam
        component.__defaultsOpts = { audio: false, video: true }

        helper.capture(component);
    },
    unrender: function (component) {
        this.superUnrender();
        component._localstream.getVideoTracks()[0].stop();
    }
});