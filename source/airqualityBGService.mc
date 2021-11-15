using Toybox.Application.Storage;
using Toybox.Background;
using Toybox.System;
using Toybox.Communications;
using Toybox.Time;
using Toybox.Lang;
// Background not allowed to have GPS access, but can get last known position
using Toybox.Position;

(:background) 
class AirQualityBGService extends Toybox.System.ServiceDelegate {
  
  function initialize() {
    System.ServiceDelegate.initialize();
    System.println("Initialize airquality background service");
  }

  function onTemporalEvent() {
    System.println("onTemporalEvent");

    var location = null;
    var positionInfo = Position.getInfo();
    if (positionInfo has : position && positionInfo.position != null) {
      location = positionInfo.position.toDegrees();
      System.println("onTemporalEvent location: " + location);
    }

    var apiKey = Storage.getValue("openWeatherAPIKey");
    var proxy = Storage.getValue("openWeatherProxy");
    var proxyApiKey = Storage.getValue("openWeatherProxyAPIKey");
    if (proxyApiKey == null) {
      proxyApiKey = "";
    }

    if (location == null || apiKey == null || apiKey.length() == 0) {
      System.println(Lang.format("proxyurl[$1$] location [$2$] apiKey[$3$]",
                                 [ proxy, location, apiKey ]));
      if (location == null) {
        Background.exit(ERROR_BG_NO_POSITION);
        return;
      }
      if (apiKey == null || apiKey.length() == 0) {
        Background.exit(gBGServiceHandler.ERROR_BG_NO_API_KEY);
        return;
      }    
    }
    
    var lat = location[0];
    var lon = location[1];
    requestWeatherData(lat, lon, apiKey, proxy, proxyApiKey);
  }

  // OWM APIDOC: https://openweathermap.org/api/air-pollution
  // - current
  // https://api.openweathermap.org/data/2.5/air_pollution?lat={lat}&lon={lon}&appid={API
  // key}
  function requestWeatherData(lat, lon, apiKey, proxy, proxyApiKey) {
    var url = proxy;
    if (proxy == null || proxy.length() == 0) {
      var base = "https://api.openweathermap.org/data/2.5/air_pollution";
      url = Lang.format("$1$?lat=$2$&lon=$3$&appid=$4$",
                        [ base, lat, lon, apiKey ]);
    }
    System.println("requestWeatherData url[" + url + "]");

    var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Authorization" => proxyApiKey
                },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON	
        };
    var responseCallBack = method( : onReceiveOpenWeatherResponse);
    var params = {};
    Communications.makeWebRequest(url, params, options, responseCallBack);
  }

  function onReceiveOpenWeatherResponse(responseCode, responseData) {
    if (responseCode == 200 && responseData != null) {
      try {
        printJson(responseData);

        //    Background: coord: {lon=>4.853500, lat=>52.353600}
        // Background: list: [{components=>{so2=>4.830000, nh3=>0.840000,
        // pm10=>21.190001, no2=>39.070000, co=>387.190002, no=>16.760000,
        // o3=>1.520000, pm2_5=>18.580000}, main=>{aqi=>2}, dt=>1636639200}]

        Background.exit(responseData);
      } catch (ex instanceof Background.ExitDataSizeLimitException) {
        ex.printStackTrace();
        System.println(responseData);
        Background.exit(gBGServiceHandler.ERROR_BG_EXIT_DATA_SIZE_LIMIT);
      } catch (ex) {
        ex.printStackTrace();
        Background.exit(gBGServiceHandler.ERROR_BG_EXCEPTION);
      }
    } else {
      Background.exit(responseCode);
    }
  }

  function printJson(data) {
    if (data instanceof Lang.Dictionary) {
      var keys = data.keys();
      for (var i = 0; i < keys.size(); i++) {
        System.println(Lang.format("$1$: $2$\n", [ keys[i], data[keys[i]] ]));
      }
    }
  }
}
