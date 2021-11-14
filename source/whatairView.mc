import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
using WhatAppBase.Utils;
using WhatAppBase.Types;

class whatairView extends WatchUi.DataField {

    var mNightMode = false;
    var mColor = Graphics.COLOR_WHITE;
    var mBackgroundColor = Graphics.COLOR_BLACK;
    var mLabel = "";
    var mFieldType = Types.WideField;
    var mCurrentLocation = new Utils.CurrentLocation();

    function initialize() {
        DataField.initialize();
        mLabel = Application.loadResource(Rez.Strings.Label) as Lang.String;
        gBGServiceHandler.setCurrentLocation(mCurrentLocation);
    }

    function onLayout(dc as Dc) as Void {
        mFieldType = Utils.getFieldType(dc);        
    }

    function compute(info as Activity.Info) as Void {
        mCurrentLocation.onCompute(info);
        mCurrentLocation.infoLocation();

        gBGServiceHandler.onCompute(info);
        gBGServiceHandler.autoScheduleService(); 
    }
    
    function onUpdate(dc as Dc) as Void {
        renderAirQuality(dc, $.gAirQuality);
    }

    function renderAirQuality(dc, airQuality) {
    if (airQuality == null) {
      return;
    }

    mBackgroundColor = getBackgroundColor();
    mNightMode = (mBackgroundColor == Graphics.COLOR_BLACK);
    dc.setColor(mBackgroundColor, mBackgroundColor);    
    dc.clear();
    
    var hfInfo = dc.getFontHeight(Graphics.FONT_SMALL);
    var airQualityColor = airQuality.airQualityAsColor();
    if (airQualityColor!= null) {
      dc.setColor(airQualityColor, Graphics.COLOR_TRANSPARENT);
      // Fill whole field, background of stats will be background color
      dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
    }

    if (mNightMode && airQualityColor == null) {
      mColor = Graphics.COLOR_WHITE;
      dc.setColor(mColor, Graphics.COLOR_TRANSPARENT);
    } else {
      mColor = Graphics.COLOR_BLACK;
      dc.setColor(mColor, Graphics.COLOR_TRANSPARENT);
    }

    // observation position
    var obsPosition = mCurrentLocation.getRelativeToObservation(airQuality.lat, airQuality.lon);    
    dc.drawText(1, 1, Graphics.FONT_SMALL, obsPosition,Graphics.TEXT_JUSTIFY_LEFT);

    var status = "";
    var x = 0;
    if (obsPosition != null && obsPosition.length() > 0) {
       x = dc.getTextWidthInPixels(obsPosition, Graphics.FONT_SMALL) + 2;
    }
    if (gBGServiceHandler.hasError()) {
      status = gBGServiceHandler.getError();
    } else {
      status = gBGServiceHandler.getStatus();
    }
    // @@ make icons for error/stats
    dc.drawText(x, 1, Graphics.FONT_TINY, status, Graphics.TEXT_JUSTIFY_LEFT);

    // observation time @@ UTC ..??
    var color = mColor;
    var obsTime = Utils.getShortTimeString(airQuality.observationTime);
    if (mFieldType == Types.SmallField) {
      obsTime = "";
    }
    // if (Utils.isDelayedFor(airQuality.observationTime,    
    //                        $.gObservationTimeDelayedMinutesThreshold)) {
    if (gBGServiceHandler.isDataDelayed()){
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
      if (mFieldType == Types.SmallField) {
        obsTime = "!";
      }
    }
    dc.drawText(dc.getWidth()-1, 1, Graphics.FONT_SMALL, obsTime,
                Graphics.TEXT_JUSTIFY_RIGHT);
    dc.setColor(mColor, Graphics.COLOR_TRANSPARENT);

    // air quality
    if (mFieldType == Types.SmallField) {
      dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_MEDIUM,
                  mLabel + " " + airQuality.airQuality(),
                  Graphics.TEXT_JUSTIFY_CENTER| Graphics.TEXT_JUSTIFY_VCENTER);
      return;
    }
    
    if (mFieldType == Types.WideField) {
      renderAirQualityStats_WideField(dc, airQuality);
      return;
    }

    if (mFieldType == Types.LargeField || mFieldType == Types.OneField) {
      renderAirQualityStats_LargeField(dc, airQuality);
      return;
    }

    // Stats @@todo NULL CHECK ==> "--"
    
    // https://openweathermap.org/api/air-pollution
    // https://en.wikipedia.org/wiki/Air_quality_index#CAQI
    // https://www.infomil.nl/onderwerpen/lucht-water/luchtkwaliteit/regelgeving/wet-milieubeheer/beoordelen/grenswaarden/
    
  }

  function renderAirQualityStats_WideField(dc, airQuality) {
    var hfInfo = dc.getFontHeight(Graphics.FONT_SMALL);
    dc.drawText(1, hfInfo + 1, Graphics.FONT_MEDIUM, airQuality.airQuality(),
                  Graphics.TEXT_JUSTIFY_LEFT);
    var counter = "#" + gBGServiceHandler.getCounterStats();
    dc.drawText(1, 2 * hfInfo + 1, Graphics.FONT_SMALL, counter, Graphics.TEXT_JUSTIFY_LEFT);
    var next = gBGServiceHandler.getWhenNextRequest();
    if (next != null) {
        var wCounter = dc.getTextWidthInPixels(counter, Graphics.FONT_SMALL);
        next = "(" + next + ")";
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(1 + wCounter + 1, 2 * hfInfo + 1, Graphics.FONT_TINY, next, Graphics.TEXT_JUSTIFY_LEFT);
    }
    // Longest text                  
    var textWidth = dc.getTextWidthInPixels(airQuality.aqiName[5], Graphics.FONT_MEDIUM) + 2;
    var radius = (dc.getWidth() - textWidth) / 16;
    var showValue = false;

    var x = textWidth + radius;
    var y = hfInfo + radius;

    var no2 = airQuality.no2;
    var pm10 = airQuality.pm10;
    var o3 = airQuality.o3;
    var pm2_5 = airQuality.pm2_5;

    var so2 = airQuality.so2;
    var nh3 = airQuality.nh3;
    var co = airQuality.co;
    var no = airQuality.no;

    var marginLeft = 1;
    var marginRight = 1;
    var margin = (dc.getWidth() - textWidth - (10 * radius) - 2) / 3; // 8 * radius

    // Clear background for the stats
    dc.setColor(mBackgroundColor, Graphics.COLOR_TRANSPARENT);
    dc.fillRectangle(textWidth, hfInfo, dc.getWidth() - textWidth, dc.getHeight() - hfInfo);

      // @@DRY
    var fontLabel = Graphics.FONT_TINY;  
    // x,y is center 
    drawCell(dc, x, y, radius, "NO2", no2, 100, showValue, fontLabel);  // microgr per m3 @@ TODO min values in object/settings?
    x = x + margin + 2 * radius;
    drawCell(dc, x, y, radius, "PM10", pm10, 50, showValue, fontLabel);
    x = x + margin + 2 * radius;
    drawCell(dc, x, y, radius, "O3", o3, 120, showValue, fontLabel);
    x = x + margin + 2 * radius;
    drawCell(dc, x, y, radius, "PM2.5", pm2_5, 30, showValue, fontLabel);
    // https://www.ser.nl/nl/thema/arbeidsomstandigheden/Grenswaarden-gevaarlijke-stoffen/Grenswaarden/Ozon
    x = textWidth + 1 + radius;
    y = y + 1 + 2 * radius;
    drawCell(dc, x, y, radius, "SO2", so2, 700, showValue, fontLabel);
    x = x + margin + 2 * radius;
    drawCell(dc, x, y, radius, "NH3", nh3, 14000, showValue, fontLabel);
    x = x + margin + 2 * radius;
    drawCell(dc, x, y, radius, "CO", co, 23000, showValue, fontLabel);
    x = x + margin + 2 * radius;
    drawCell(dc, x, y, radius, "NO", no, 2500, showValue, fontLabel);
    x = x + margin + 2 * radius;  
  }

  function renderAirQualityStats_LargeField(dc, airQuality) {
    // First line is gps info
    var hfl = dc.getFontHeight(Graphics.FONT_SMALL);
    dc.drawText(1, hfl, Graphics.FONT_SMALL,
                  mLabel + " " + airQuality.airQuality(), Graphics.TEXT_JUSTIFY_LEFT);
    var counter = "#" + gBGServiceHandler.getCounterStats();
    dc.drawText(dc.getWidth()-1, hfl, Graphics.FONT_SMALL, counter, Graphics.TEXT_JUSTIFY_RIGHT);                  
    var next = gBGServiceHandler.getWhenNextRequest();
    if (next != null) {
        var wCounter = dc.getTextWidthInPixels(counter, Graphics.FONT_SMALL);
        next = "(" + next + ")";
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()- 1 - wCounter - 1, hfl, Graphics.FONT_TINY, next, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    var showValue = true;
    var radius = Utils.min(dc.getFontHeight(Graphics.FONT_MEDIUM), (dc.getHeight() - 2 * hfl) / 4);

    var hfInfo = 1 + (2 * hfl);
    var x = 1 + radius;
    var y = hfInfo + radius;

    var no2 = airQuality.no2;
    var pm10 = airQuality.pm10;
    var o3 = airQuality.o3;
    var pm2_5 = airQuality.pm2_5;

    var so2 = airQuality.so2;
    var nh3 = airQuality.nh3;
    var co = airQuality.co;
    var no = airQuality.no;
    
    var marginLeft = 3;
    var marginRight = 3;
    var margin = (dc.getWidth() - (8 * radius) - marginLeft - marginRight) / 3;

    // Clear background for the stats
    var textWidth = 0;
    dc.setColor(mBackgroundColor, Graphics.COLOR_TRANSPARENT);
    dc.fillRectangle(textWidth, hfInfo, dc.getWidth() - textWidth, dc.getHeight() - hfInfo);

    // https://openweathermap.org/api/air-pollution
    // https://en.wikipedia.org/wiki/Air_quality_index#CAQI
    // https://www.infomil.nl/onderwerpen/lucht-water/luchtkwaliteit/regelgeving/wet-milieubeheer/beoordelen/grenswaarden/
    var fontLabel = Graphics.FONT_MEDIUM;
    drawCell(dc, x, y, radius, "NO2", no2, 100, showValue, fontLabel);  // microgr per m3
    x = x + margin + 2 * radius;
    drawCell(dc, x, y, radius, "PM10", pm10, 50, showValue, fontLabel);
    x = x + margin + 2 * radius;
    drawCell(dc, x, y, radius, "O3", o3, 120, showValue, fontLabel);
    x = x + margin + 2 * radius;
    drawCell(dc, x, y, radius, "PM2.5", pm2_5, 30, showValue, fontLabel);
    // https://www.ser.nl/nl/thema/arbeidsomstandigheden/Grenswaarden-gevaarlijke-stoffen/Grenswaarden/Ozon
    x = 1 + radius;
    y = y + 1 + 2 * radius;
    drawCell(dc, x, y, radius, "SO2", so2, 700, showValue, fontLabel);
    x = x + margin + 2 * radius;
    drawCell(dc, x, y, radius, "NH3", nh3, 14000, showValue, fontLabel);
    x = x + margin + 2 * radius;
    drawCell(dc, x, y, radius, "CO", co, 23000, showValue, fontLabel);
    x = x + margin + 2 * radius;
    drawCell(dc, x, y, radius, "NO", no, 2500, showValue, fontLabel);
    x = x + margin + 2 * radius;    
  }

  function drawCell(dc, x, y, radius, label, value, max, showValue, fontLabel) {
    var perc = Utils.percentageOf(value, max);
    // System.println("cell: " + label + " value: " + value + " perc: " + perc);

    var color = Utils.percentageToColor(perc);
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    Utils.fillPercentageCircle(dc, x, y, radius, perc);
    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.drawCircle(x, y, radius);

    //var fontLabel = Graphics.FONT_MEDIUM;
    var flh = dc.getFontHeight(fontLabel);
    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.drawText(x, y - flh / 3, fontLabel, label,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

    if (showValue) {
      var text = "--";
      if (value != null) {
        text = value.format("%0.2f");
      } 
      dc.setColor(mColor, Graphics.COLOR_TRANSPARENT);
      dc.drawText(x, y + flh / 3, Graphics.FONT_SMALL, text,
                  Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
  }

}
