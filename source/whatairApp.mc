import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.System;
import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Math;
using WhatAppBase.Types;
using WhatAppBase.Utils;

// !! no global objects!
(:background) 
class whatairApp extends Application.AppBase {    
    var mPreviousAirQuality as AirQuality?;
    var mAirQuality as AirQuality?;
    var mAQIndex as AQIndex?;
    var mBGServiceHandler as BGServiceHandler?; 

    function initialize() { AppBase.initialize(); }
    
    function onStart(state as Dictionary?) as Void { }
    
    function onStop(state as Dictionary?) as Void { }

    (:typecheck(disableBackgroundCheck))
    function getInitialView() as Array<Views or InputDelegates>? {
      loadUserSettings();
      return [ new whatairView() ] as Array<Views or InputDelegates>;
    }

    (:typecheck(disableBackgroundCheck))
    function onSettingsChanged() { loadUserSettings(); }

    (:typecheck(disableBackgroundCheck))
    function getServiceDelegate() as Lang.Array<System.ServiceDelegate> {
      return [new AirQualityBGService()] as Lang.Array<System.ServiceDelegate>;
    }

    (:typecheck(disableBackgroundCheck))
    function getBGServiceHandler() as BGServiceHandler {
      if (mBGServiceHandler == null) { mBGServiceHandler = new BGServiceHandler(); }
      return mBGServiceHandler;
    }

    (:typecheck(disableBackgroundCheck))
    function getAQIndex() as AQIndex { 
      if (mAQIndex == null) { mAQIndex = new AQIndex(); }
      return mAQIndex;
    }

     (:typecheck(disableBackgroundCheck))
    function getAirQuality() as AirQuality {
      if (mAirQuality == null) { mAirQuality = new AirQuality(); }
      return mAirQuality;
    }

    (:typecheck(disableBackgroundCheck))
    function loadUserSettings() as Void {
      try {
        System.println("Load usersettings");
        
        Storage.setValue("openWeatherAPIKey", Utils.getApplicationPropertyAsString("openWeatherAPIKey", ""));

        if (mAQIndex == null) {mAQIndex = new AQIndex(); }
        if (mAirQuality == null) {mAirQuality = new AirQuality(); }
        var handler =  getBGServiceHandler();        
        handler.setObservationTimeDelayedMinutes(Utils.getApplicationPropertyAsNumber("observationTimeDelayedMinutesThreshold", 10));
        handler.setMinimalGPSLevel(Utils.getApplicationPropertyAsNumber("minimalGPSquality", 3));
        handler.setUpdateFrequencyInMinutes(Utils.getApplicationPropertyAsNumber("updateFrequencyWebReq", 5));
                
        var AQIdx = getAQIndex();
        AQIdx.NO2 = Utils.getApplicationPropertyAsNumber("pollutionLimitNO2", AQIdx.NO2);
        AQIdx.PM10 = Utils.getApplicationPropertyAsNumber("pollutionLimitPM10", AQIdx.PM10);
        AQIdx.O3 = Utils.getApplicationPropertyAsNumber("pollutionLimitO3", AQIdx.O3);
        AQIdx.PM2_5 = Utils.getApplicationPropertyAsNumber("pollutionLimitPM2_5", AQIdx.PM2_5);
        AQIdx.SO2 = Utils.getApplicationPropertyAsNumber("pollutionLimitSO2", AQIdx.SO2);
        AQIdx.NH3 = Utils.getApplicationPropertyAsNumber("pollutionLimitNH3", AQIdx.NH3);
        AQIdx.CO = Utils.getApplicationPropertyAsNumber("pollutionLimitCO", AQIdx.CO);
        AQIdx.NO = Utils.getApplicationPropertyAsNumber("pollutionLimitNO", AQIdx.NO);    
        mAQIndex = AQIdx;

        // @@ TODO demo force aqi level
        var demo = Utils.getApplicationPropertyAsBoolean("demo", false); 
        if (demo) {
          handler.stopBGservice(); 
          handler.Disable();                    
          setDemoData();          
        } else {
          restoreData();
          handler.Enable();          
        }

        System.println("loadUserSettings loaded");
      } catch (ex) {
        ex.printStackTrace();
      }
    }

    (:typecheck(disableBackgroundCheck))
    function setBackgroundUpdate(minutes as Number) as Void {
      if (Toybox.System has :ServiceDelegate) {
        System.println("setBackgroundUpdate registerForTemporalEvent " + minutes + " minutes");
        Background.registerForTemporalEvent(new Time.Duration(minutes * 60));
      } else {
        System.println("Unable to register for TemporalEvent");
        System.exit();
      }
    }

    // called in foreground
    (:typecheck(disableBackgroundCheck))
    function onBackgroundData(data as PersistableType) {
      System.println("Background data recieved");
      System.println(data);
      var handler = getBGServiceHandler();      
      handler.onBackgroundData(data, getAirQuality(), :updateData);
      
      WatchUi.requestUpdate();
    }

    (:typecheck(disableBackgroundCheck))
    function setDemoData() as Void {
      if (mPreviousAirQuality == null) {
        mPreviousAirQuality = mAirQuality;
        Math.srand(System.getTimer());
      }
      mAirQuality = new AirQuality();
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

      getAirQuality().updateData(null, data);
    }

    function restoreData()  as Void {
      if (mPreviousAirQuality != null) {
        mAirQuality = mPreviousAirQuality;
        mPreviousAirQuality = null;
      }
    }

}

function getApp() as whatairApp {
    return Application.getApp() as whatairApp;
}
