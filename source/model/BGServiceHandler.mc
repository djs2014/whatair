import Toybox.Lang;
import Toybox.System;
import Toybox.Activity;
import Toybox.Position;
using Toybox.Time;
using Toybox.Background;
using WhatAppBase.Utils;
(:background)
class BGServiceHandler {
    const ERROR_BG_NONE = 0;      
    const ERROR_BG_NO_API_KEY = -1;
    
    const ERROR_BG_NO_PROXY = -3; // @@ Not yet used
    const ERROR_BG_EXCEPTION = -4;
    const ERROR_BG_EXIT_DATA_SIZE_LIMIT = -5;
    const ERROR_BG_INVALID_BACKGROUND_TIME = -6; // @@ Not yet used
    const ERROR_BG_NOT_SUPPORTED = -7;
    const ERROR_BG_HTTPSTATUS = -10;

    const ERROR_BG_NO_POSITION = -2;
    const ERROR_BG_NO_PHONE = -8;
    const ERROR_BG_GPS_LEVEL = -9;

    const HTTP_OK = 200;
    var mCurrentLocation = null;
    var mError = 0; 
    var mHttpStatus = HTTP_OK;
    var mPhoneConnected = false;    
    var mBGActive = false;
    var mBGDisabled = false;

    var mUpdateFrequencyInMinutes = 5;
    var mRequestCounter = 0; 
    var mObservationTimeDelayedMinutesThreshold = 10;
    var mMinimalGPSLevel = 3;
            
    var mLastRequestMoment = null; 
    var mLastObservationMoment = null; 
    var mData = null;

    // var methodOnBeforeWebrequest = null;

    function initialize() {}
    function setCurrentLocation(currentLocation as Utils.CurrentLocation) {
        mCurrentLocation = currentLocation;
    }

    function setMinimalGPSLevel(level) { mMinimalGPSLevel = level; }
    function setUpdateFrequencyInMinutes(minutes) {mUpdateFrequencyInMinutes = minutes; }
    function Disable() { mBGDisabled = true; }
    function Enable() { mBGDisabled = false;  reset(); }
    function setObservationTimeDelayedMinutes(minutes) { mObservationTimeDelayedMinutesThreshold = minutes; }
    function isDataDelayed() {
        return Utils.isDelayedFor(mLastObservationMoment, mObservationTimeDelayedMinutesThreshold);
    }
    function hasError() { return mError != ERROR_BG_NONE || mHttpStatus != HTTP_OK; }
    function reset() {
        System.println("Reset BG service");
        mError = 0;
        mHttpStatus = HTTP_OK;
    }
    function onCompute(info as Activity.Info) {
        mPhoneConnected = System.getDeviceSettings().phoneConnected;        
    }

    function autoScheduleService() {
        if (mBGDisabled) { return; }
        
        try {
            testOnNonFatalError();            
            
            // @@ disable temporary when position not changed ( less than x km distance) and last call < x minutes?
            if (hasError()) {                
                stopBGservice();
                return;
            }

            startBGservice();            
        } catch (ex) {
            ex.printStackTrace();
        } 
        // Doesnt work!
        // finally {
        //     mError = error;
        //     if (error != ERROR_BG_NONE) {
        //         stopBGservice();
        //     }
        // }      
    }
    
    hidden function testOnNonFatalError() {
        if (mError == ERROR_BG_GPS_LEVEL || mError == ERROR_BG_NO_PHONE || mError == ERROR_BG_NO_POSITION ) {
            mError = ERROR_BG_NONE;
        }
        
        if (!mPhoneConnected) {
            mError = ERROR_BG_NO_PHONE;            
        } else if (mCurrentLocation != null && mCurrentLocation.getAccuracy() < mMinimalGPSLevel) { 
            mError = ERROR_BG_GPS_LEVEL;                
        } else if (mCurrentLocation != null && !mCurrentLocation.hasLocation()) {
            mError = ERROR_BG_NO_POSITION;                
        }
    }

    function stopBGservice() {
        if (!mBGActive) { return; }
        try {
            Background.deleteTemporalEvent();
            mBGActive = false;
            mError = ERROR_BG_NONE;
            System.println("stopBGservice stopped"); 
        } catch (ex) {
            ex.printStackTrace();
            mError = ERROR_BG_EXCEPTION;
            mBGActive = false;
        } 
    }

    function startBGservice() {
        //mError = ERROR_BG_NONE; ??
        if (mBGDisabled) {
            System.println("startBGservice Service is disabled, no scheduling"); 
            return;
        }
        if (mBGActive) {
            System.println("startBGservice already active"); 
            return;
        }
        
        try {
            if (Toybox.System has :ServiceDelegate) {
                Background.registerForTemporalEvent(new Time.Duration(mUpdateFrequencyInMinutes * 60));
                mBGActive = true;
                mError = ERROR_BG_NONE;
                mHttpStatus = HTTP_OK;
                System.println("startBGservice registerForTemporalEvent [" +
                            mUpdateFrequencyInMinutes + "] minutes scheduled");
            } else {
                System.println("Unable to start BGservice (no registerForTemporalEvent)");
                mBGActive = false;
                mError = ERROR_BG_NOT_SUPPORTED;
                System.exit(); // @@ ??
            }
        } catch (ex) {
            ex.printStackTrace();
            mError = ERROR_BG_EXCEPTION;
            mBGActive = false;
        } 
    }

    function getWhenNextRequest() {
        if (hasError()) { return null; }
        var lastTime = Background.getLastTemporalEventTime();
        if (lastTime == null) { return null; }
        var elapsedSeconds = Time.now().value() - lastTime.value();
        var secondsToNext = (mUpdateFrequencyInMinutes * 60) - elapsedSeconds;
        return Utils.secondsToShortTimeString(secondsToNext, "{m}:{s}");
    }

    // function setOnBeforeWebrequest(obj, callback) {
    //     if (callback == null) { 
    //         methodOnBeforeWebrequest = null;
    //         return;
    //     }
    //     methodOnBeforeWebrequest = new Lang.Method(obj, callback);
    // }

    // function onBeforeWebrequest() {
    //     if (methodOnBeforeWebrequest==null) { return; }
    //     methodOnBeforeWebrequest.invoke(self);
    // }

    function onBackgroundData(data, obj, cbProcessData) {                
        mLastRequestMoment = Time.now();
        if (data instanceof Number) {
            mHttpStatus = data;
            mError = ERROR_BG_HTTPSTATUS;
            System.println("onBackgroundData error responsecode: " + data);
        } else {
            mHttpStatus = HTTP_OK;
            mData = data;
            mError = ERROR_BG_NONE;
            mRequestCounter = mRequestCounter + 1;
            if (obj != null) {
                var processData = new Lang.Method(obj, cbProcessData);
                processData.invoke(data);
            }
        }    
    }
    function setLastObservationMoment(moment) {
        mLastObservationMoment = moment;
    }

    function getStatus() as Lang.String {
        // @@ enum/const
        if (mBGDisabled) { return "Disabled"; }
        if (mBGActive) { return "Active"; }
        // @@ + countdown minutes?
        if (!mBGActive) { return "Inactive"; }
        return "";
    }
    
    function getCounterStats() as Lang.String {
        return mRequestCounter.format("%0d");
    }

    function getError() as Lang.String {
        if (mHttpStatus != HTTP_OK) {
             return "Http [" + mHttpStatus.format("%0d") + "]";    
        }
        if (mError == ERROR_BG_NONE) {
            return "";
        }
        if (mError == ERROR_BG_NO_API_KEY) {
            return "ApiKey?";
        }
        if (mError == ERROR_BG_NO_POSITION) {
            return "Position?";
        }
        if (mError == ERROR_BG_NO_PROXY) {
            return "Proxy?";
        }
        if (mError == ERROR_BG_EXCEPTION) {
            return "Error?";
        }
        if (mError == ERROR_BG_EXIT_DATA_SIZE_LIMIT) {
            return "Memory?";
        }
        if (mError == ERROR_BG_INVALID_BACKGROUND_TIME) {
            return "ScheduleTime?";
        }
        if (mError == ERROR_BG_NOT_SUPPORTED) {
            return "Supported?";
        }
        if (mError == ERROR_BG_NO_PHONE) {
            return "Phone?";
        }
        if (mError == ERROR_BG_GPS_LEVEL) {
            return "Gps quality?";
        }
        if (mError == ERROR_BG_HTTPSTATUS) {
            return "Http [" + mHttpStatus.format("%0d") + "]";
        }
        return "";
    }
}
