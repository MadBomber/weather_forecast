## Using NWS API
### Requires LatLon
The API is free with no key required.
requires LatLon not ZipCode
I have a LatLon to ZipCode database but I don't want to use it for this task


## Using OpenWeatherMap API
### How It Works
- **Endpoint**: `https://api.openweathermap.org/data/2.5/weather`
- **Key Parameter for ZIP Code**: `zip` – Specify the ZIP code (as a string), optionally followed by a comma and country code (e.g., `{zip code},{country code}`). If no country code is provided, it defaults to the US.
- **Required**: Include your API key via the `appid` parameter (sign up for a free key at openweathermap.org).
- **Optional Parameters**:
  - `units`: `metric` (Celsius/km/h), `imperial` (Fahrenheit/mph), or `standard` (default, Kelvin/m/s).
  - `lang`: Language for the weather condition description (e.g., `en` for English).
- **Response Format**: JSON by default (includes temperature, humidity, wind speed, weather description, etc.).

### Example API Call
For ZIP code 94040 (Mountain View, CA, US):
`https://api.openweathermap.org/data/2.5/weather?zip=94040,us&appid={YOUR_API_KEY}&units=imperial`

This returns data like:
```json
{
  "main": { "temp": 72.5, "humidity": 65 },
  "weather": [{ "description": "clear sky" }],
  "wind": { "speed": 5.1 }
}
```

For best accuracy, use latitude/longitude directly if possible, or chain with their Geocoding API for ZIP-to-coordinates conversion.


### 5-Day Forecast (3-Hourly Intervals)
This is the most commonly used multi-day forecast, returning up to 40 timestamps (every 3 hours for 5 days).

- **Endpoint**: `https://api.openweathermap.org/data/2.5/forecast`
- **Key Parameter for ZIP Code**: `zip` – Specify the ZIP code (as a string), optionally followed by a comma and country code (e.g., `{zip code},{country code}`). If no country code is provided, it defaults to the US.
- **Required**: Include your API key via the `appid` parameter (sign up for a free key at openweathermap.org).
- **Optional Parameters**:
  - `units`: `metric` (Celsius/km/h), `imperial` (Fahrenheit/mph), or `standard` (default, Kelvin/m/s).
  - `cnt`: Number of timestamps to return (e.g., 10 for fewer results).
  - `lang`: Language for the weather condition description (e.g., `en` for English).
- **Response Format**: JSON by default (includes timestamps, temperature, humidity, wind, precipitation probability, etc., in a `list` array).

#### Example API Call
For ZIP code 94040 (Mountain View, CA, US), in imperial units:
`https://api.openweathermap.org/data/2.5/forecast?zip=94040,us&appid={YOUR_API_KEY}&units=imperial`

This returns data like (excerpt):
```json
{
  "cod": "200",
  "message": 0,
  "cnt": 40,
  "list": [
    {
      "dt": 1647345600,
      "main": {
        "temp": 57.8,
        "feels_like": 57.2,
        "temp_min": 57.8,
        "temp_max": 58.3,
        "pressure": 1023,
        "humidity": 70
      },
      "weather": [{ "description": "light rain", "icon": "10n" }],
      "wind": { "speed": 0.5 },
      "pop": 0.24,
      "rain": { "3h": 0.12 },
      "dt_txt": "2022-03-15 12:00:00"
    }
    // Additional 39 entries...
  ],
  "city": { "name": "Mountain View", "coord": { "lat": 37.3855, "lon": -122.088 } }
}
```

### 16-Day Daily Forecast
This provides daily summaries (one per day) for up to 16 days ahead.

- **Endpoint**: `https://api.openweathermap.org/data/2.5/forecast/daily`
- **Key Parameter for ZIP Code**: `zip` – Same format as above.
- **Required**: `appid`.
- **Optional Parameters**:
  - `cnt`: Number of days to return (1–16; defaults to 16).
  - `units`: Same as above.
  - `lang`: Same as above.
- **Response Format**: JSON by default (includes daily temp breakdowns like day/night/min/max, humidity, wind, precipitation, etc., in a `list` array).

#### Example API Call
For ZIP code 94040 (Mountain View, CA, US), for 7 days:
`https://api.openweathermap.org/data/2.5/forecast/daily?zip=94040,us&cnt=7&appid={YOUR_API_KEY}&units=imperial`

This returns data like (excerpt):
```json
{
  "cod": "200",
  "message": 2.1505307,
  "cnt": 7,
  "list": [
    {
      "dt": 1519070400,
      "temp": {
        "day": 51.18,
        "min": 41.15,
        "max": 51.18,
        "night": 41.15,
        "eve": 45.34,
        "morn": 47.59
      },
      "pressure": 989.94,
      "humidity": 52,
      "weather": [{ "description": "light rain", "icon": "10d" }],
      "speed": 3.36,
      "clouds": 20,
      "rain": 0.31
    }
    // Additional days...
  ],
  "city": { "name": "Mountain View", "coord": { "lat": 37.3855, "lon": -122.088 } }
}
```

For best accuracy with ZIP codes, chain with the Geocoding API (e.g., first convert ZIP to lat/lon, then use those in the forecast endpoint). Both APIs require a free account for the key, and paid plans unlock higher limits.
