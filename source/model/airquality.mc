import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Graphics; // @@ TEST in background process
using WhatAppBase.Colors;

class AirQuality {
  var lat as Float = 0.0f;
  var lon as Float = 0.0f;
  // Carbon monoxide (CO), Nitrogen monoxide (NO), Nitrogen dioxide (NO2), Ozone
  // (O3), Sulphur dioxide (SO2), Ammonia (NH3), and particulates (PM2.5 and
  // PM10).

  var so2 as Float?;
  var nh3 as Float?;
  var pm10 as Float?;
  var no2 as Float?;
  var co as Float?;
  var no as Float?;
  var o3 as Float?;
  var pm2_5 as Float?;
  // Air quality index
  //   Qualitative name 	Index 	Pollutant concentration in μg/m3
  // 	        NO2 	PM10 	O3 	PM25 (optional)
  // Good 	1 	0-50 	0-25 	0-60 	0-15
  // Fair 	2 	50-100 	25-50 	60-120 	15-30
  // Moderate 	3 	100-200 	50-90 	120-180 	30-55
  // Poor 	4 	200-400 	90-180 	180-240 	55-110
  // Very Poor 	5 	>400 	>180 	>240 	>110
  var aqi as Number = 0;
  var aqiName as Array = [ "--", "Good", "Fair", "Moderate", "Poor", "Very poor" ];
  var observationTime as Time.Moment?;

  function initialize() {}

  function reset()  as Void {
    lat = 0.0f;
    lon = 0.0f;
    //
    so2 = null;
    nh3 = null;
    pm10 = null;
    no2 = null;
    co = null;
    no = null;
    o3 = null;
    pm2_5 = null;
    //
    aqi = 0;
    observationTime = null;
  }

  
  // Returns observation time
  function updateData(handler as BGServiceHandler?, data as Dictionary) as Void {
    //    Background: coord: {lon=>4.853500, lat=>52.353600}
    // Background: list: [{components=>{so2=>4.830000, nh3=>0.840000,
    // pm10=>21.190001, no2=>39.070000, co=>387.190002, no=>16.760000,
    // o3=>1.520000, pm2_5=>18.580000}, main=>{aqi=>2}, dt=>1636639200}]
    try {
      reset();
      if (data == null) { return; }
      var coord = data["coord"] as Dictionary; //<String, Float>;
      if (coord != null) {
        // lat = getValue(coord["lat"], 0.0) as Float;
        // lon = getValue(coord["lon"], 0.0) as Float;
        lat = getValueAsFloat(coord, "lat", 0.0f) as Float;
        lon = getValueAsFloat(coord, "lon", 0.0f) as Float;
      }
      // var list = data["list"][0] as Dictionary;
      var list = data["list"] as Array;
      if (list != null) {
        var item = list[0] as Dictionary;
        // aqi = getValue(list["main"]["aqi"], 0) as Number;
        var main = item["main"] as Dictionary;
        if (main != null) { aqi = getValueAsNumber(main, "aqi", 0); }
        var components = item["components"] as Dictionary;
        so2 = getValueAsFloat(components,"so2", null);
        nh3 = getValueAsFloat(components,"nh3", null);
        pm10 = getValueAsFloat(components,"pm10", null);
        no2 = getValueAsFloat(components,"no2", null);
        co = getValueAsFloat(components,"co", null);
        no = getValueAsFloat(components,"no", null);
        o3 = getValueAsFloat(components,"o3", null);
        pm2_5 = getValueAsFloat(components,"pm2_5", null);
        
        // so2 = getValue(list["components"]["so2"], null) as Float;
        // nh3 = getValue(list["components"]["nh3"], null) as Float;
        // pm10 = getValue(list["components"]["pm10"], null) as Float;
        // no2 = getValue(list["components"]["no2"], null) as Float;
        // co = getValue(list["components"]["co"], null) as Float;
        // no = getValue(list["components"]["no"], null) as Float;
        // o3 = getValue(list["components"]["o3"], null) as Float;
        // pm2_5 = getValue(list["components"]["pm2_5"], null) as Float;

        var dt = getValueAsNumber(item, "dt", 0);
        // var dt = getValue(list["dt"], null) as Number;
        if (dt > 0) { observationTime = new Time.Moment(dt); }
        // @@ TODO UTC to local time
        //System.println("Observation time[" + observationTime + "] " + dt);
      }      
    } catch (ex) {
      ex.printStackTrace();
    }
    if (handler != null) {
      handler.setLastObservationMoment(observationTime);
    }     
  }

  function airQuality() as String {
    if (aqi == null || aqi < 0 || aqi > aqiName.size()) {
      return "--";
    }
    return aqiName[aqi] as String;
  }

function airQualityAsColor() as ColorType? {
    if (aqi == null || aqi <= 0 || aqi > aqiName.size()) {
      return null;
    }
    if (aqi == 1) {
      return Colors.COLOR_WHITE_DK_BLUE_3;
    }
    if (aqi == 2) {
      return Colors.COLOR_WHITE_LT_GREEN_3;
    }
    if (aqi == 3) {
      return Colors.COLOR_WHITE_ORANGERED_2;
    }
    if (aqi == 4) {
      return Colors.COLOR_WHITE_RED_3;
    }
    if (aqi == 5) {
      return Colors.COLOR_WHITE_PURPLE_3;
    }
    return null;
}
  hidden function getValue(value as Numeric?, def as Numeric?) as Numeric? {
    if (value == null) {
      return def;
    }
    return value;
  }

  hidden function getValueAsFloat(data as Dictionary, key as String, defaultValue as Float?) as Float? {
    var value = data.get(key);
    if (value == null) { return defaultValue; }
    return value as Float;
  }

  hidden function getValueAsNumber(data as Dictionary, key as String, defaultValue as Number) as Number {
    var value = data.get(key);
    if (value == null) { return defaultValue; }
    return value as Number;
  }
}