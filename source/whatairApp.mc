import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.System;
using Toybox.Application.Storage;
using Toybox.Background;
using WhatAppBase.Utils;
using Toybox.Math;

var gBGServiceHandler = new BGServiceHandler();

// Default false, n the background process, I set it to true.
// (getServiceDelegate()), globals are not shared between foreground and
// background process
var gInBackground = false;
var gAirQuality = new AirQuality();
var gDemo = false;

(:background) 
class whatairApp extends Application.AppBase {
    var mPreviousAirQuality = null;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    //! Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        loadUserSettings();
        return [ new whatairView() ] as Array<Views or InputDelegates>;
    }

    function onSettingsChanged() { loadUserSettings(); }

    function getServiceDelegate() as Lang.Array<System.ServiceDelegate> {
      $.gInBackground = true;
      return [new AirQualityBGService()] as Lang.Array<System.ServiceDelegate>;
    }

    function loadUserSettings() {
      try {
        System.println("Load usersettings background:" + $.gInBackground);
        
        // @@ TODO different providers?
        Storage.setValue("openWeatherAPIKey", Utils.getStringProperty("openWeatherAPIKey", ""));

        if (gBGServiceHandler == null) {gBGServiceHandler = new BGServiceHandler(); }

        gBGServiceHandler.setObservationTimeDelayedMinutes(Utils.getNumberProperty("observationTimeDelayedMinutesThreshold", 10));
        gBGServiceHandler.setMinimalGPSLevel(Utils.getNumberProperty("minimalGPSquality", 3));
        gBGServiceHandler.setUpdateFrequencyInMinutes(Utils.getNumberProperty("updateFrequencyWebReq", 5));
        
        // Storage.setValue("openWeatherProxy",
        //            getStringProperty("openWeatherProxy", ""));
        // Storage.setValue("openWeatherProxyAPIKey",
        //            getStringProperty("openWeatherProxyAPIKey", ""));
              
        $.gDemo = Utils.getBooleanProperty("demo", false); // @@ TODO demo force aqi level
        if ($.gDemo) {
          gBGServiceHandler.stopBGservice(); 
          gBGServiceHandler.Disable();                    
          setDemoData();          
        } else {
          restoreData();
          gBGServiceHandler.Enable();          
        }

        System.println("loadUserSettings loaded");
      } catch (ex) {
        ex.printStackTrace();
      }
    }

    function setBackgroundUpdate(minutes) {
      if (Toybox.System has : ServiceDelegate) {
        System.println("setBackgroundUpdate registerForTemporalEvent " + minutes + " minutes");
        Background.registerForTemporalEvent(new Time.Duration(minutes * 60));
      } else {
        System.println("Unable to register for TemporalEvent");
        System.exit();
      }
    }

    // called in foreground
    function onBackgroundData(data) {
      System.println("Background data recieved background:" + $.gInBackground);
      gBGServiceHandler.onBackgroundData(data, gAirQuality, :updateData);
      gBGServiceHandler.setLastObservationMoment(gAirQuality.observationTime);      

      WatchUi.requestUpdate();
    }

    function setDemoData() {
      if (mPreviousAirQuality == null) {
        mPreviousAirQuality = gAirQuality;
        Math.srand(System.getTimer());
      }
      gAirQuality = new AirQuality();
      var aqi =  1 + Math.rand() % 5;
      var data = {
                    "coord" => {"lat" => 4.853500, "lon" => 52.353600},
                    "list" => [{
                        "main" => {
                            "aqi" => aqi} ,
                            "components"=> { 
                                "so2"=>4.830000, "nh3"=>0.840000,
                                "pm10"=>50.190001, "no2"=>39.070000, "co"=>387.190002, "no"=>16.760000,
                                "o3"=>1.520000, "pm2_5-"=>18.580000, "pm2_5"=>null 
                            },
                            "dt" => 1636639200 
                        }
                    ]
                };

      gAirQuality.updateData(data);
    }

    function restoreData() {
      if (mPreviousAirQuality != null) {
        gAirQuality = mPreviousAirQuality;
        mPreviousAirQuality = null;
      }
    }

}

function getApp() as whatairApp {
    return Application.getApp() as whatairApp;
}