import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
using WhatAppBase.Utils;
using WhatAppBase.Types;
using Toybox.Application.Storage;

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
        // gBGServiceHandler.setOnBeforeWebrequest(self, :onBeforeBGSchedule);
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
    
    // function onBeforeBGSchedule() {
    //     System.println("onBeforeBGSchedule");
    //     var location = mCurrentLocation.getLocation();
    //     if (location != null) {
    //       Storage.setValue("currentDegrees", location.toDegrees());
    //     else {
    //       Storage.deleteValue("currentDegrees");                  
    //     }
    // }

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
      var margin = (dc.getWidth() - (8 * 10)) / 8;
      drawStats(dc, airQuality, 6, dc.getHeight() - 10, 5, null, null, margin, false);                    
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
    // Longest text @@
    var textWidth = dc.getTextWidthInPixels(airQuality.aqiName[5], Graphics.FONT_MEDIUM) + 2;
    var radius = (dc.getWidth() - textWidth) / 16;    
    var x = textWidth + radius;
    var y = hfInfo + radius;
    var marginLeft = 1;
    var marginRight = 1;
    var margin = (dc.getWidth() - textWidth - (10 * radius) - 2) / 3; // 8 * radius

    // Clear background for the stats
    dc.setColor(mBackgroundColor, Graphics.COLOR_TRANSPARENT);
    dc.fillRectangle(textWidth, hfInfo, dc.getWidth() - textWidth, dc.getHeight() - hfInfo);

    var fontLabel = Graphics.FONT_TINY;  
    var fontValue = null;
    drawStats(dc, airQuality, x, y, radius, fontLabel, fontValue, margin, true);    
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

    var hfInfo = 1 + (2 * hfl);
    var radius = Utils.min(dc.getFontHeight(Graphics.FONT_MEDIUM), (dc.getHeight() - 2 * hfl) / 4);
    var x = 1 + radius;
    var y = hfInfo + radius;
    
    var marginLeft = 3;
    var marginRight = 3;
    var margin = (dc.getWidth() - (8 * radius) - marginLeft - marginRight) / 3;

    // Clear background for the stats
    var textWidth = 0;
    dc.setColor(mBackgroundColor, Graphics.COLOR_TRANSPARENT);
    dc.fillRectangle(textWidth, hfInfo, dc.getWidth() - textWidth, dc.getHeight() - hfInfo);

    var fontLabel = Graphics.FONT_MEDIUM;
    var fontValue = Graphics.FONT_SMALL;
    drawStats(dc, airQuality, x, y, radius, fontLabel, fontValue, margin, true);    
  }

  // x,y center of circle
  function drawStats(dc, airQuality, x, y, radius, fontLabel, fontValue, margin, newline) {
    var no2 = airQuality.no2;
    var pm10 = airQuality.pm10;
    var o3 = airQuality.o3;
    var pm2_5 = airQuality.pm2_5;

    var so2 = airQuality.so2;
    var nh3 = airQuality.nh3;
    var co = airQuality.co;
    var no = airQuality.no;

    var startX = x;
    drawCell(dc, x, y, radius, "NO2", no2, gAQIndex.NO2, fontLabel, fontValue);
    x = x + margin + 2 * radius;
    drawCell(dc, x, y, radius, "PM10", pm10, gAQIndex.PM10, fontLabel, fontValue);
    x = x + margin + 2 * radius;
    drawCell(dc, x, y, radius, "O3", o3, gAQIndex.O3, fontLabel, fontValue);
    x = x + margin + 2 * radius;
    drawCell(dc, x, y, radius, "PM2.5", pm2_5, gAQIndex.PM2_5, fontLabel, fontValue);
    // new line
    if (newline) {
      x = startX; // radius already included
      y = y + 1 + 2 * radius;
    } else {
      x = x + margin + 2 * radius;
    }    
    drawCell(dc, x, y, radius, "SO2", so2, gAQIndex.SO2, fontLabel, fontValue);
    x = x + margin + 2 * radius;
    drawCell(dc, x, y, radius, "NH3", nh3, gAQIndex.NH3, fontLabel, fontValue);
    x = x + margin + 2 * radius;
    drawCell(dc, x, y, radius, "CO", co, gAQIndex.CO, fontLabel, fontValue);
    x = x + margin + 2 * radius;
    drawCell(dc, x, y, radius, "NO", no, gAQIndex.NO, fontLabel, fontValue);

  }

  function drawCell(dc, x, y, radius, label, value, max, fontLabel, fontValue) {
    var perc = Utils.percentageOf(value, max);
    var color = Utils.percentageToColor(perc);
    
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    Utils.fillPercentageCircle(dc, x, y, radius, perc);

    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
    dc.drawCircle(x, y, radius);
    
    var labelHeight = 0;
    // var valueHeight = 0;    
    // if (fontValue != null) {
    //   valueHeight = dc.getFontHeight(fontValue);
      
    // }
    if (fontLabel != null) {
      labelHeight = dc.getFontHeight(fontLabel);
      var yLabel = y;
      if (fontValue != null) { yLabel = yLabel - labelHeight / 3; }
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.drawText(x, yLabel , fontLabel, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    if (fontValue != null) {
      var text = "--";
      if (value != null) {
        text = value.format("%0.2f");
      } 
      dc.setColor(mColor, Graphics.COLOR_TRANSPARENT);
      dc.drawText(x, y + labelHeight / 3, fontValue, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
  }

}
