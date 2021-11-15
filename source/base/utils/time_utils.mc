import Toybox.Time;
import Toybox.Application;
import Toybox.System;
import Toybox.Lang;

using Toybox.Time.Gregorian as Calendar;
module WhatAppBase {
  (:Utils) 
  module Utils {
    function isDelayedFor(timevalue, minutesDelayed) {
      //! True if timevalue is later than now + minutesDelayed
      if (timevalue == null || minutesDelayed <= 0) {
        return false;
      }

      if (timevalue instanceof Lang.Number) {
        return (Time.now().value() - timevalue) > (minutesDelayed * 60);
      } else if (timevalue instanceof Time.Moment) {
        return Time.now().compare(timevalue) > (minutesDelayed * 60);
      }

      return false;
    }

    function ensureXSecondsPassed(previousMomentInSeconds as Lang.Number,
                                  seconds as Lang.Number) as Lang.Boolean {
      if (previousMomentInSeconds == null || previousMomentInSeconds <= 0) {
        return true;
      }
      var diff = Time.now().value() - previousMomentInSeconds;
      System.println("ensureXSecondsPassed difference: " + diff);
      return diff >= seconds;
    }

    function getDateTimeString(moment) {
      if (moment != null && moment instanceof Time.Moment) {
        var date = Calendar.info(moment, Time.FORMAT_SHORT);
        return date.day.format("%02d") + "-" + date.month.format("%02d") + "-" +
               date.year.format("%d") + " " + date.hour.format("%02d") + ":" +
               date.min.format("%02d") + ":" + date.sec.format("%02d");
      }
      return "";
    }

    function getTimeString(moment) {
      if (moment != null && moment instanceof Time.Moment) {
        var date = Calendar.info(moment, Time.FORMAT_SHORT);
        return date.hour.format("%02d") + ":" + date.min.format("%02d") + ":" +
               date.sec.format("%02d");
      }
       return "";
    }

    function getShortTimeString(moment) {
      if (moment != null && moment instanceof Time.Moment) {
        var date = Calendar.info(moment, Time.FORMAT_SHORT);
        return date.hour.format("%02d") + ":" + date.min.format("%02d");
      }
       return "";
    }

    // template: "{h}:{m}:{s}"
    function millisecondsToShortTimeString(totalMilliSeconds, template as Lang.String) {
      if (totalMilliSeconds != null && totalMilliSeconds instanceof Lang.Number) {
        var hours = (totalMilliSeconds / (1000.0 * 60 * 60)).toNumber() % 24;
        var minutes = (totalMilliSeconds / (1000.0 * 60.0)).toNumber() % 60;
        var seconds = (totalMilliSeconds / 1000.0).toNumber() % 60;
        var mseconds = (totalMilliSeconds).toNumber() % 1000;

        if (template == null) { template = "{h}:{m}:{s}:{ms}"; }
        var time = stringReplace(template,"{h}", hours.format("%01d"));
        time = stringReplace(time,"{m}", minutes.format("%02d"));
        time = stringReplace(time,"{s}", seconds.format("%02d"));
        time = stringReplace(time,"{ms}", mseconds.format("%03d"));

        return time;  
      }
      return "";
    }
    // template: "{h}:{m}:{s}"
    function secondsToShortTimeString(totalSeconds, template as Lang.String) {
      if (totalSeconds != null && totalSeconds instanceof Lang.Number) {
        var hours = (totalSeconds / (60 * 60)).toNumber() % 24;
        var minutes = (totalSeconds / 60.0).toNumber() % 60;
        var seconds = (totalSeconds.toNumber() % 60);

        if (template == null) { template = "{h}:{m}:{s}"; }
        var time = stringReplace(template,"{h}", hours.format("%01d"));
        time = stringReplace(time,"{m}", minutes.format("%02d"));
        time = stringReplace(time,"{s}", seconds.format("%02d"));

        return time;  
      }
      return "";
    }

    function stringReplace(str, oldString, newString) {
      var result = str;
      if (str == null || oldString == null || newString == null) { return str; }

      var index = result.find(oldString);
      var count = 0;
      while (index != null && count < 30)
      {
        var indexEnd = index + oldString.length();
        result = result.substring(0, index) + newString + result.substring(indexEnd, result.length());
        index = result.find(oldString);
        count = count + 1;
      }

      return result;
    } 
  }
}