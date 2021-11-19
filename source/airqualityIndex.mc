import Toybox.Lang;
import Toybox.System;

// https://www.c40knowledgehub.org/s/article/WHO-Air-Quality-Guidelines?language=en_US
// https://www.ser.nl/nl/thema/arbeidsomstandigheden/Grenswaarden-gevaarlijke-stoffen/Grenswaarden/Ozon    
// @@ make settings
(:background)
class AQIndex {
    // moderate values in microgram per m3: µg/m3 24-hour mean.
    var NO2 as Number = 25;
    var PM10 as Number = 45; 
    var O3 as Number = 100; 
    var PM2_5 as Number = 15; 

    var SO2 as Number = 40; 
    var NH3 as Number = 14000;
    var CO as Number = 7;
    var NO as Number = 2500;

    function initialize() {}    
}