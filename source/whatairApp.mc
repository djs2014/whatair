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
// var gAirQuality as AirQuality?;// = new AirQuality();
var gAQIndex as AQIndex?;// = new AQIndex();

(:background) 
class whatairApp extends Application.AppBase {
    var mPreviousAirQuality as AirQuality?;
    var mBGServiceHandler as BGServiceHandler?; 
    var mAirQuality as AirQuality?;
    function initialize() { AppBase.initialize(); }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as Array<Views or InputDelegates>? {
        loadUserSettings();
        return [ new whatairView() ] as Array<Views or InputDelegates>;
    }

    function onSettingsChanged() { loadUserSettings(); }

    function getServiceDelegate() as Lang.Array<System.ServiceDelegate> {
      return [new AirQualityBGService()] as Lang.Array<System.ServiceDelegate>;
    }

    function loadUserSettings() as Void {
      try {
        System.println("Load usersettings");
        
        Storage.setValue("openWeatherAPIKey", Utils.getStringProperty("openWeatherAPIKey", ""));

        if ($.gAQIndex == null) {$.gAQIndex = new AQIndex(); }
        if (mAirQuality == null) {mAirQuality = new AirQuality(); }
        if (mBGServiceHandler == null) {mBGServiceHandler = new BGServiceHandler(); }
        mBGServiceHandler.setObservationTimeDelayedMinutes(Utils.getNumberProperty("observationTimeDelayedMinutesThreshold", 10));
        mBGServiceHandler.setMinimalGPSLevel(Utils.getNumberProperty("minimalGPSquality", 3));
        mBGServiceHandler.setUpdateFrequencyInMinutes(Utils.getNumberProperty("updateFrequencyWebReq", 5));
        
        // Storage.setValue("openWeatherProxy",
        //            getStringProperty("openWeatherProxy", ""));
        // Storage.setValue("openWeatherProxyAPIKey",
        //            getStringProperty("openWeatherProxyAPIKey", ""));
        
        $.gAQIndex.NO2 = Utils.getNumberProperty("pollutionLimitNO2", $.gAQIndex.NO2);
        $.gAQIndex.PM10 = Utils.getNumberProperty("pollutionLimitPM10", $.gAQIndex.PM10);
        $.gAQIndex.O3 = Utils.getNumberProperty("pollutionLimitO3", $.gAQIndex.O3);
        $.gAQIndex.PM2_5 = Utils.getNumberProperty("pollutionLimitPM2_5", $.gAQIndex.PM2_5);
        $.gAQIndex.SO2 = Utils.getNumberProperty("pollutionLimitSO2", $.gAQIndex.SO2);
        $.gAQIndex.NH3 = Utils.getNumberProperty("pollutionLimitNH3", $.gAQIndex.NH3);
        $.gAQIndex.CO = Utils.getNumberProperty("pollutionLimitCO", $.gAQIndex.CO);
        $.gAQIndex.NO = Utils.getNumberProperty("pollutionLimitNO", $.gAQIndex.NO);    

        // @@ TODO demo force aqi level
        var demo = Utils.getBooleanProperty("demo", false) as Boolean; 
        if (demo) {
          mBGServiceHandler.stopBGservice(); 
          mBGServiceHandler.Disable();                    
          setDemoData();          
        } else {
          restoreData();
          mBGServiceHandler.Enable();          
        }

        System.println("loadUserSettings loaded");
      } catch (ex) {
        ex.printStackTrace();
      }
    }

    function setBackgroundUpdate(minutes as Number) as Void {
      if (Toybox.System has : ServiceDelegate) {
        System.println("setBackgroundUpdate registerForTemporalEvent " + minutes + " minutes");
        Background.registerForTemporalEvent(new Time.Duration(minutes * 60));
      } else {
        System.println("Unable to register for TemporalEvent");
        System.exit();
      }
    }

    // called in foreground
    function onBackgroundData(data as PersistableType) {
      System.println("Background data recieved");
      if (mBGServiceHandler == null) {mBGServiceHandler = new BGServiceHandler(); }
      mBGServiceHandler.onBackgroundData(data, mAirQuality, :updateData);
      // mBGServiceHandler.setLastObservationMoment(mAirQuality.observationTime);      

      // WatchUi.requestUpdate();
    }

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

      mAirQuality.updateData(null, data);
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
