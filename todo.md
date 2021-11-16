Widget ..
sync location utils
- set concentration limit using settings
  - docu etc.
 - show last known location if no gps on screen
- refactor draw stats code
- alert / beep

- status
    phone|gps|active|error
    - gBGActive 
        -> scheduled
    - canActivate()
        phone/gps/not active/location
    - stopBGService -> no phone/no location/no gps
    - pauseBGService (pause web request?)
        - distance last obs loc - current loc < x km &&
            last obs time < 1 hour. (@@ UTC check)
    
-> display scheduling remaining time --> over x min..
@@ handle wifi connected + status   || ble connected == phone connected? -> yes done
@@ show status

dots on small field

stop background when paused?
save gps-location when app stopped / pause
    - in property
on start check property
    - distance within < 1km, schedule bg service
    - else when activity started
layout large field, airq label position
    - circle radius dynamic on field height
    - fonts label/value dynamic ..
show call counter
check BlueT connection - stop/restart BG service (also via demo)
create on watch 
? create own LKI score based on https://www.luchtmeetnet.nl/informatie/luchtkwaliteit/klassen-luchtkwaliteit

check values compare to https://www.iqair.com/air-pollution-data-api
- option to choose the source OWM or iqair


https://aqicn.org/api/
https://aqicn.org/json-api/doc/#api-Geolocalized_Feed-GetGeolocFeed


Alternative: formula 'LKI', 'NO2', 'O3', 'PM10'.
https://api.luchtmeetnet.nl/open_api
{{base_url}}/open_api/concentrations?formula=no2&longitude=4.458807&latitude=51.924452
https://api.luchtmeetnet.nl/open_api/concentrations?formula=no2&longitude=4.458807&latitude=51.924452

{"data": [{"formula": "NO2", "value": 57.0, "timestamp_measured": "2021-11-12T07:00:00+00:00"}, {"formula": "NO2", "value": 57.0, "timestamp_measured": "2021-11-12T08:00:00+00:00"}, {"formula": "NO2", "value": 43.0, "timestamp_measured": "2021-11-12T09:00:00+00:00"}, {"formula": "NO2", "value": 43.0, "timestamp_measured": "2021-11-12T10:00:00+00:00"}, {"formula": "NO2", "value": 43.0, "timestamp_measured": "2021-11-12T11:00:00+00:00"}, {"formula": "NO2", "value": 28.0, "timestamp_measured": "2021-11-12T12:00:00+00:00"}, {"formula": "NO2", "value": 28.0, "timestamp_measured": "2021-11-12T13:00:00+00:00"}, {"formula": "NO2", "value": 28.0, "timestamp_measured": "2021-11-12T14:00:00+00:00"}, {"formula": "NO2", "value": 30.0, "timestamp_measured": "2021-11-12T15:00:00+00:00"}, {"formula": "NO2", "value": 30.0, "timestamp_measured": "2021-11-12T16:00:00+00:00"}, {"formula": "NO2", "value": 30.0, "timestamp_measured": "2021-11-12T17:00:00+00:00"}, {"formula": "NO2", "value": 29.0, "timestamp_measured": "2021-11-12T18:00:00+00:00"}, {"formula": "NO2", "value": 29.0, "timestamp_measured": "2021-11-12T19:00:00+00:00"}, {"formula": "NO2", "value": 29.0, "timestamp_measured": "2021-11-12T20:00:00+00:00"}, {"formula": "NO2", "value": 22.0, "timestamp_measured": "2021-11-12T21:00:00+00:00"}, {"formula": "NO2", "value": 22.0, "timestamp_measured": "2021-11-12T22:00:00+00:00"}, {"formula": "NO2", "value": 22.0, "timestamp_measured": "2021-11-12T23:00:00+00:00"}, {"formula": "NO2", "value": 18.0, "timestamp_measured": "2021-11-13T00:00:00+00:00"}, {"formula": "NO2", "value": 18.0, "timestamp_measured": "2021-11-13T01:00:00+00:00"}, {"formula": "NO2", "value": 18.0, "timestamp_measured": "2021-11-13T02:00:00+00:00"}, {"formula": "NO2", "value": 21.0, "timestamp_measured": "2021-11-13T03:00:00+00:00"}]}

https://api.luchtmeetnet.nl/open_api/concentrations?formula=no2&longitude=4.458807&latitude=51.924452&start=2021-11-12T09:00:00Z&end=2021-11-12T11:00:00Z
-> also big json result :-( 