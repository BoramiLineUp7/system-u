({
    afterLoad : function(component, event, helper) {
        //console.log('jqsrloaded');
    },
    handleClickStart: function(component, event, helper) {
        event.preventDefault();
        // Start video playback manually.
        component.__video.play();
        helper.showVideo(component);
        component.set("v.canPlay",true);
    },
    handleClickPause: function(component, event, helper) {
        event.preventDefault();
        component.__video.pause();
    },
    handleClickFlip: function(component, event, helper) {
        // we need to flip, stop everything
        component.__video.pause()
        component.__video.srcObject = null
        // toggle \ flip
        shouldFaceUser = !shouldFaceUser;
        helper.capture(component);
    },
    handleClickStop: function(component, event, helper) {
        event.preventDefault();
        component.__video.pause();
        component.__video.src = "";
        component._localstream.getVideoTracks()[0].stop();
    },
    handleClickReset: function(component, event, helper) {
        event.preventDefault();
        component.set("v.code","");
        component.__video.pause();
        component.__video.src = "";
        component._localstream.getVideoTracks()[0].stop();
        helper.capture(component);
    },
})