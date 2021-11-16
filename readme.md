# What air quality

Datafield displaying Air Quality Index and data (in μg/m3) about polluting gases, such as Carbon monoxide (CO), Nitrogen monoxide (NO), Nitrogen dioxide (NO2), Ozone (O3), Sulphur dioxide (SO2), Ammonia (NH3), and particulates (PM2.5 and PM10). 

## Setup

### Open Weather API

Get Open weather API key.

See `https://openweathermap.org/api` for registering and creating an API key.
Put this key in setting `Open weather map API key`.

https://www.iqair.com/air-pollution-data-api

### Settings

Minimal GPS quality level: Usable

Frequency of web request in minutes: 5 min

When an error happens the background scheduling stops. When the error is resolved, the background scheduling is started again.

Errors:
- ApiKey?: No Open Weather api key configured
- Position?: GPS position not available
- Error?: General exception
- Supported?: Not supported
- Memory?: Response of weather request is too big
- Phone?: Phone not connected
- Gps quality?: Gps quality not good enough
- Http[XXX]: Http status code. Example 401 is Not authorized. Then the api key is not valid.

Save settings will reset the error state (if not automatically).


### Info

https://openweathermap.org/api/air-pollution
https://en.wikipedia.org/wiki/Air_quality_index#CAQI
https://www.infomil.nl/onderwerpen/lucht-water/luchtkwaliteit/regelgeving/wet-milieubeheer/beoordelen/grenswaarden/
https://www.ser.nl/nl/thema/arbeidsomstandigheden/Grenswaarden-gevaarlijke-stoffen/Grenswaarden/Ozon    