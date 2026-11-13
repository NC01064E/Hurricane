sub init()
    m.top.functionName = "fetchWeather"
end sub

function weatherJson(url as String) as Object
    xfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    xfer.SetMessagePort(port)
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.SetUrl(url)
    xfer.AddHeader("Accept", "application/geo+json, application/json")
    xfer.AddHeader("User-Agent", "OurHouseFamilyHub/58 (personal Roku weather display)")
    if not xfer.AsyncGetToString() then return invalid
    response = wait(15000, port)
    if response = invalid or type(response) <> "roUrlEvent" then
        xfer.AsyncCancel()
        return invalid
    end if
    code = response.GetResponseCode()
    if code < 200 or code >= 300 then return invalid
    return ParseJSON(response.GetString())
end function

function chanceValue(period as Object) as Integer
    if period = invalid or period.probabilityOfPrecipitation = invalid then return 0
    value = period.probabilityOfPrecipitation.value
    if value = invalid then return 0
    return value
end function

sub fetchWeather()
    lat = m.top.latitude
    lon = m.top.longitude
    if lat = invalid or lat = "" or lon = invalid or lon = "" then
        m.top.error = "LOCATION"
        return
    end if
    point = weatherJson("https://api.weather.gov/points/" + lat + "," + lon)
    if point = invalid or point.properties = invalid then
        m.top.error = "NWS POINT"
        return
    end if
    forecastUrl = point.properties.forecast
    hourlyUrl = point.properties.forecastHourly
    if forecastUrl = invalid or hourlyUrl = invalid then
        m.top.error = "NWS GRID"
        return
    end if
    forecast = weatherJson(forecastUrl)
    hourly = weatherJson(hourlyUrl)
    if forecast = invalid or forecast.properties = invalid or forecast.properties.periods = invalid then
        m.top.error = "NWS FORECAST"
        return
    end if
    periods = forecast.properties.periods
    if periods.count() = 0 then
        m.top.error = "NO FORECAST"
        return
    end if

    current = periods[0]
    if hourly <> invalid and hourly.properties <> invalid and hourly.properties.periods <> invalid and hourly.properties.periods.count() > 0 then current = hourly.properties.periods[0]
    currentTemp = current.temperature
    currentUnit = current.temperatureUnit
    currentForecast = current.shortForecast
    currentWind = current.windSpeed
    currentRain = chanceValue(current)
    currentWindMph = 0
    currentGustMph = 0
    currentHumidity = 0
    currentObservedAt = ""
    actualObservation = false

    stationsUrl = point.properties.observationStations
    if stationsUrl <> invalid and stationsUrl <> "" then
        stations = weatherJson(stationsUrl)
        if stations <> invalid and stations.features <> invalid and stations.features.count() > 0 then
            stationUrl = stations.features[0].id
            if stationUrl <> invalid and stationUrl <> "" then
                observation = weatherJson(stationUrl + "/observations/latest")
                if observation <> invalid and observation.properties <> invalid then
                    op = observation.properties
                    if op.temperature <> invalid and op.temperature.value <> invalid then
                        currentTemp = Int((op.temperature.value * 1.8) + 32.5)
                        currentUnit = "F"
                        actualObservation = true
                    end if
                    if op.textDescription <> invalid and op.textDescription <> "" then currentForecast = op.textDescription
                    if op.windSpeed <> invalid and op.windSpeed.value <> invalid then
                        currentWindMph = Int((op.windSpeed.value * 0.621371) + 0.5)
                        currentWind = currentWindMph.toStr() + " mph"
                    end if
                    if op.windGust <> invalid and op.windGust.value <> invalid then currentGustMph = Int((op.windGust.value * 0.621371) + 0.5)
                    if op.relativeHumidity <> invalid and op.relativeHumidity.value <> invalid then currentHumidity = Int(op.relativeHumidity.value + 0.5)
                    if op.timestamp <> invalid then currentObservedAt = op.timestamp
                end if
            end if
        end if
    end if

    first = periods[0]
    second = first
    if periods.count() > 1 then second = periods[1]
    third = second
    if periods.count() > 2 then third = periods[2]

    alerts = weatherJson("https://api.weather.gov/alerts/active?point=" + lat + "," + lon)
    alertEvent = ""
    alertHeadline = ""
    alertSeverity = ""
    alertCount = 0
    if alerts <> invalid and alerts.features <> invalid then
        alertCount = alerts.features.count()
        if alertCount > 0 and alerts.features[0].properties <> invalid then
            ap = alerts.features[0].properties
            if ap.event <> invalid then alertEvent = ap.event
            if ap.headline <> invalid then alertHeadline = ap.headline
            if ap.severity <> invalid then alertSeverity = ap.severity
        end if
    end if

    locationName = "West Palm Beach"
    if point.properties.relativeLocation <> invalid and point.properties.relativeLocation.properties <> invalid then
        city = point.properties.relativeLocation.properties.city
        state = point.properties.relativeLocation.properties.state
        if city <> invalid and city <> "" then locationName = city
        if state <> invalid and state <> "" then locationName = locationName + ", " + state
    end if
    m.top.payload = {
        zipCode: m.top.zipCode,
        location: locationName,
        fetchedAt: CreateObject("roDateTime").AsSeconds(),
        current: { temperature: currentTemp, unit: currentUnit, forecast: currentForecast, wind: currentWind, windMph: currentWindMph, gustMph: currentGustMph, humidity: currentHumidity, observedAt: currentObservedAt, actual: actualObservation, rainChance: currentRain },
        nowPeriod: { name: first.name, temperature: first.temperature, unit: first.temperatureUnit, forecast: first.shortForecast, rainChance: chanceValue(first) },
        nextPeriod: { name: second.name, temperature: second.temperature, unit: second.temperatureUnit, forecast: second.shortForecast, rainChance: chanceValue(second) },
        laterPeriod: { name: third.name, temperature: third.temperature, unit: third.temperatureUnit, forecast: third.shortForecast, rainChance: chanceValue(third) },
        alert: { count: alertCount, event: alertEvent, headline: alertHeadline, severity: alertSeverity }
    }
end sub
