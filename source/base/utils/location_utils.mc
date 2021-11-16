import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Position;
module WhatAppBase {
  (:Utils) 
  module Utils {
    class CurrentLocation {
      hidden var mLocation = null as Position.Location?; 
      hidden var mAccuracy = Position.QUALITY_NOT_AVAILABLE as Position.Quality;

      function initialize() {}

      function hasLocation() { return mLocation != null; } //&& self.lat != 0 && self.lon != 0; }

      function infoLocation() {
        if (!hasLocation()) { return "No location"; }
        return "Current location: " + mLocation.toDegrees();
      }

      function getAccuracy() as Position.Quality {
        return mAccuracy;
      }
      function getLocation() as Position.Location? {
        return mLocation;
      }
      function onCompute(info as Activity.Info) {
        try {
          var location = null;
          mAccuracy = Position.QUALITY_NOT_AVAILABLE;
          if (info != null) {
            if (info has :currentLocation && info.currentLocation != null) {
              location = info.currentLocation;
              if (info has :currentLocationAccuracy && info.currentLocationAccuracy != null) {
                mAccuracy = info.currentLocationAccuracy;
              }
              if (locationChanged(location)) {
                System.println("Activity location lat/lon: " + location.toDegrees() + " accuracy: " + mAccuracy);
              }
            }
          }
          if (location == null) {
            var posnInfo = Position.getInfo();
            if (posnInfo != null && posnInfo has :position && posnInfo.position != null) {              
              location = posnInfo.position;
              if (posnInfo has :accuracy && posnInfo.accuracy != null) {
                mAccuracy = posnInfo.accuracy;                
              }
              if (locationChanged(location)) {
                System.println("Position location lat/lon: " + location.toDegrees() + " accuracy: " + mAccuracy);
              }
            }
          }
          if (location != null) {
            mLocation = location;
          } else if (mLocation != null) {
            mAccuracy = Position.QUALITY_LAST_KNOWN;
          }
        } catch (ex) {
          ex.printStackTrace();
        }
      }     

      hidden function locationChanged(location as Position.location?) {
        if (mLocation == null && location == null ){ return false; }
        if ( (mLocation != null && location == null) || (mLocation == null && location != null) ){ return true; }

        var degrees = location.toDegrees();
        var currentDegrees = mLocation.toDegrees();
        return degrees[0] != currentDegrees[0] && degrees[1] != currentDegrees[1];        
      }

      function getRelativeToObservation(latObservation, lonObservation) as Lang.String {
        if (!hasLocation()) {
          return "";
        }

        var degrees = mLocation.toDegrees();
        var latCurrent = degrees[0];
        var lonCurrent = degrees[1];

        var distanceMetric = "km";
        var distance =
            Utils.getDistanceFromLatLonInKm(latCurrent, lonCurrent, latObservation, lonObservation);

        var deviceSettings = System.getDeviceSettings();
        if (deviceSettings.distanceUnits == System.UNIT_STATUTE) {
          distance = Utils.kilometerToMile(distance);
          distanceMetric = "m";
        }
        var bearing = Utils.getRhumbLineBearing(latCurrent, lonCurrent, latObservation, lonObservation);
        var compassDirection = Utils.getCompassDirection(bearing);

        return Lang.format("$1$ $2$ ($3$)",[ distance.format("%.2f"), distanceMetric, compassDirection ]);
      }
    }
  }
}
