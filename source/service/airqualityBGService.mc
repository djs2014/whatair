import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.System;
import Toybox.Communications;
import Toybox.Time;
import Toybox.Lang;
// Background not allowed to have GPS access, but can get last known position
import Toybox.Position;

(:background) 
class AirQualityBGService extends Toybox.System.ServiceDelegate {
  
  function initialize() {
    System.ServiceDelegate.initialize();
    System.println("AirQualityBGService Initialize");
  }

  function onTemporalEvent() {
    System.println("AirQualityBGService onTemporalEvent");

    var degrees = null as Array;
    // @@ TODO
    // var degrees = Storage.getValue("lastKnownDegrees");
    // if (degrees != null) {
    //   System.println("AirQualityBGService lastKnownDegrees: " + degrees);
    //   Storage.deleteValue("lastKnownDegrees");
    // } else {
      var positionInfo = Position.getInfo();
      if (positionInfo has : position && positionInfo.position != null) {
        var location = positionInfo.position as Position.Location;
        degrees = location.toDegrees();
        System.println("AirQualityBGService location: " + degrees);
      }
    // }
    
    // @@ TODO -- cleanup
    var proxyApiKey = "";
    var proxy = "";
    // var proxy = Storage.getValue("openWeatherProxy");
    // var proxyApiKey = Storage.getValue("openWeatherProxyAPIKey");
    // if (proxyApiKey == null) {
    //   proxyApiKey = "";
    // }


    var apiKey = "" as Lang.String;
    var value = Storage.getValue("openWeatherAPIKey");
    if (value != null) {
      apiKey = value as Lang.String;
    }
    if (apiKey.length() == 0) {
      System.println(Lang.format("AirQualityBGService proxyurl[$1$] location [$2$] apiKey[$3$] -> exit",
                                [ proxy, degrees, apiKey ]));
      Background.exit(BGService.ERROR_BG_NO_API_KEY);
      return;
    }    

    

    if (degrees == null) {
      System.println(Lang.format("AirQualityBGService proxyurl[$1$] location [$2$] apiKey[$3$] -> exit",
                                [ proxy, degrees, apiKey ]));
      Background.exit(BGService.ERROR_BG_NO_POSITION);
      return;
    }
    var lat = degrees[0] as Double;
    var lon = degrees[1] as Double;
    if (lat == 0.0 && lon == 0.0) {
      System.println(Lang.format("AirQualityBGService proxyurl[$1$] location [$2$] apiKey[$3$] -> exit",
                                [ proxy, degrees, apiKey ]));
      Background.exit(BGService.ERROR_BG_NO_POSITION);
      return;
    }
    requestWeatherData(lat, lon, apiKey, proxy, proxyApiKey);
  }

  // OWM APIDOC: https://openweathermap.org/api/air-pollution
  // - current
  // https://api.openweathermap.org/data/2.5/air_pollution?lat={lat}&lon={lon}&appid={API
  // key}
  function requestWeatherData(lat as Double, lon as Double, apiKey as String, proxy as String, proxyApiKey as String) as Void {
    var url = proxy;
    if (proxy.length() == 0) {
      var base = "https://api.openweathermap.org/data/2.5/air_pollution";
      url = Lang.format("$1$?lat=$2$&lon=$3$&appid=$4$",
                        [ base, lat, lon, apiKey ]);
    }
    System.println("AirQualityBGService requestWeatherData url[" + url + "]");

    var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Authorization" => proxyApiKey
                },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON	
        };
    var responseCallBack = self.method(:onReceiveOpenWeatherResponse)
        as Method(responseCode as Number, responseData as Dictionary?) as Void;

    var params = {};
    Communications.makeWebRequest(url, params, options, responseCallBack);
  }

  function onReceiveOpenWeatherResponse(responseCode as String, responseData as Dictionary?) as Void {
    if (responseCode == 200 && responseData != null) {
      try {
        // printJson(responseData);

        //    Background: coord: {lon=>4.853500, lat=>52.353600}
        // Background: list: [{components=>{so2=>4.830000, nh3=>0.840000,
        // pm10=>21.190001, no2=>39.070000, co=>387.190002, no=>16.760000,
        // o3=>1.520000, pm2_5=>18.580000}, main=>{aqi=>2}, dt=>1636639200}]

        Background.exit(responseData as PropertyValueType);
      } catch (ex instanceof Background.ExitDataSizeLimitException) {
        ex.printStackTrace();
        System.println(responseData);
        Background.exit(BGService.ERROR_BG_EXIT_DATA_SIZE_LIMIT);
      } catch (ex) {
        ex.printStackTrace();
        Background.exit(BGService.ERROR_BG_EXCEPTION);
      }
    } else {
      System.println(responseCode);
      Background.exit(responseCode);
    }
  }

  function printJson(data as Dictionary?) as Void{
    if (data == null) {
      System.println("No data!");
      return;
    }
    var keys = data.keys();
    for (var i = 0; i < keys.size(); i++) {
      System.println(Lang.format("$1$: $2$\n", [ keys[i], data[keys[i]] ]));
    }  
  }
}
