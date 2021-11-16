import Toybox.Lang;
import Toybox.System;
using Toybox.Time;
using WhatAppBase.Colors;

(:background) 
class AirQuality {
  var lat = 0.0f;
  var lon = 0.0f;
  // Carbon monoxide (CO), Nitrogen monoxide (NO), Nitrogen dioxide (NO2), Ozone
  // (O3), Sulphur dioxide (SO2), Ammonia (NH3), and particulates (PM2.5 and
  // PM10).

  var so2 = null;
  var nh3 = null;
  var pm10 = null;
  var no2 = null;
  var co = null;
  var no = null;
  var o3 = null;
  var pm2_5 = null;
  // Air quality index
  //   Qualitative name 	Index 	Pollutant concentration in μg/m3
  // 	        NO2 	PM10 	O3 	PM25 (optional)
  // Good 	1 	0-50 	0-25 	0-60 	0-15
  // Fair 	2 	50-100 	25-50 	60-120 	15-30
  // Moderate 	3 	100-200 	50-90 	120-180 	30-55
  // Poor 	4 	200-400 	90-180 	180-240 	55-110
  // Very Poor 	5 	>400 	>180 	>240 	>110
  var aqi = 0;
  var aqiName = [ "--", "Good", "Fair", "Moderate", "Poor", "Very poor" ] as Lang.Array<Lang.String>;
  var observationTime = null;

  function initialize() {}

  function reset() {
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

  function updateData(data) {
    //    Background: coord: {lon=>4.853500, lat=>52.353600}
    // Background: list: [{components=>{so2=>4.830000, nh3=>0.840000,
    // pm10=>21.190001, no2=>39.070000, co=>387.190002, no=>16.760000,
    // o3=>1.520000, pm2_5=>18.580000}, main=>{aqi=>2}, dt=>1636639200}]
    try {
      reset();
      if (data == null) {
        return;
      }
      var coord = data["coord"];
      if (coord != null) {
        lat = getValue(coord["lat"], 0.0);
        lon = getValue(coord["lon"], 0.0);
      }
      var list = data["list"][0];
      if (list != null) {
        aqi = getValue(list["main"]["aqi"], 0);

        so2 = getValue(list["components"]["so2"], null);
        nh3 = getValue(list["components"]["nh3"], null);
        pm10 = getValue(list["components"]["pm10"], null);
        no2 = getValue(list["components"]["no2"], null);
        co = getValue(list["components"]["co"], null);
        no = getValue(list["components"]["no"], null);
        o3 = getValue(list["components"]["o3"], null);
        pm2_5 = getValue(list["components"]["pm2_5"], null);

        var dt = getValue(list["dt"], null);
        if (dt != null) {
          observationTime = new Time.Moment(dt);
        }
        //System.println("Observation time[" + observationTime + "] " + dt);
      }

    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function airQuality() as Lang.String {
    if (aqi == null || aqi < 0 || aqi > aqiName.size()) {
      return "--";
    }
    return aqiName[aqi];
  }

function airQualityAsColor() {
    if (aqi == null || aqi <= 0 || aqi > aqiName.size()) {
      return null;
    }
    if (aqi == 1) {
        return Colors.COLOR_WHITE_LT_GREEN_3;
      }
    if (aqi == 2) {
        return Colors.COLOR_WHITE_DK_BLUE_3;
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
  hidden function getValue(value, def) {
    if (value == null) {
      return def;
    }
    return value;
  }
}