' ================= NWS weather for ZIP 33417 =================

sub setupWeather()
    m.weatherTask = m.top.findNode("weatherTask")
    m.weatherTask.observeField("payload", "onWeatherPayload")
    m.weatherTask.observeField("error", "onWeatherError")
    m.weatherRunning = false
    m.weatherStatus = ""
    m.weatherLastError = ""
    m.weatherPointProps = invalid
end sub

sub startWeatherSync(force as Boolean)
    if m.weatherRunning then return
    nowSec = CreateObject("roDateTime").AsSeconds()
    if not force and m.state.weather.lastSync > 0 then
        if nowSec - m.state.weather.lastSync < 1800 then return
    end if
    m.weatherRunning = true
    m.weatherStatus = "UPDATING"
    m.weatherTask.latitude = "26.7191"
    m.weatherTask.longitude = "-80.1245"
    m.weatherTask.zipCode = "33417"
    if m.weatherPointProps <> invalid then m.weatherTask.pointProps = m.weatherPointProps
    m.weatherTask.control = "STOP"
    m.weatherTask.control = "RUN"
end sub

sub onWeatherPayload()
    data = m.weatherTask.payload
    m.weatherRunning = false
    if data = invalid then return
    ' Keep the NWS grid lookup in memory only; the saved weather cache stays small.
    if data.pointProps <> invalid then
        m.weatherPointProps = data.pointProps
        data.delete("pointProps")
    end if
    m.state.weather.cache = data
    m.state.weather.lastSync = CreateObject("roDateTime").AsSeconds()
    m.weatherStatus = "READY"
    m.weatherLastError = ""
    saveState()
    if m.screen = "hub" or m.screen = "ambient" or m.screen = "diagnostics" then rebuildScreen()
end sub

sub onWeatherError()
    m.weatherRunning = false
    m.weatherLastError = m.weatherTask.error
    m.weatherStatus = "OFFLINE"
    if m.screen = "hub" or m.screen = "ambient" or m.screen = "diagnostics" then rebuildScreen()
end sub

function weatherData() as Object
    if m.state.weather = invalid or m.state.weather.cache = invalid then return {}
    return m.state.weather.cache
end function

function weatherSyncLabel() as String
    if m.state.weather.lastSync <= 0 then return "Not updated yet"
    ago = CreateObject("roDateTime").AsSeconds() - m.state.weather.lastSync
    prefix = ""
    if m.weatherLastError <> invalid and m.weatherLastError <> "" then prefix = "Offline · saved forecast · "
    mins = ago \ 60
    if mins < 1 then return prefix + "Updated just now"
    if mins < 60 then return prefix + "Updated " + mins.toStr() + " min ago"
    return prefix + "Updated " + (mins \ 60).toStr() + " hr ago"
end function

function weatherSummary() as String
    data = weatherData()
    if data.current = invalid then
        if m.weatherRunning then return "WEATHER UPDATING..."
        return "WEATHER UNAVAILABLE"
    end if
    unit = data.current.unit
    if unit = invalid or unit = "" then unit = "F"
    forecast = data.current.forecast
    if forecast = invalid then forecast = ""
    rain = 0
    if data.current.rainChance <> invalid then rain = data.current.rainChance
    return "NWS · " + data.current.temperature.toStr() + "°" + unit + "  ·  " + forecast + "  ·  RAIN " + rain.toStr() + "%"
end function

function weatherAlertText() as String
    data = weatherData()
    if data.alert = invalid or data.alert.count = invalid or data.alert.count <= 0 then return ""
    if data.alert.event <> invalid and data.alert.event <> "" then return data.alert.event
    return "ACTIVE WEATHER ALERT"
end function

function weatherVisualKind() as String
    data = weatherData()
    if data.current = invalid or data.current.forecast = invalid then return "none"
    return weatherKindFor(data.current.forecast, data.current.windMph, data.current.gustMph)
end function

' Picks the sky animation from the NWS wording ("Clear", "Light Rain",
' "Partly Cloudy", ...). Words are matched with weatherHas, see below.
function weatherKindFor(forecast as String, windMph as Dynamic, gustMph as Dynamic) as String
    txt = LCase(forecast)
    if weatherHas(txt, "thunder") or weatherHas(txt, "storm") then return "thunder"
    if weatherHas(txt, "rain") or weatherHas(txt, "shower") or weatherHas(txt, "drizzle") then return "rain"
    if windMph <> invalid and windMph >= 20 then return "wind"
    if gustMph <> invalid and gustMph >= 25 then return "wind"
    if weatherHas(txt, "wind") or weatherHas(txt, "breezy") or weatherHas(txt, "gust") then return "wind"
    if weatherHas(txt, "sunny") then return "sun"
    if weatherHas(txt, "clear") or weatherHas(txt, "fair") then return "clear"
    return "cloud"
end function

' True when word appears in txt. Uses the string method, which returns -1 when
' missing. (The global Instr() returns 0 when missing, so the old ">= 0" test was
' always true and every forecast, even "Clear", drew a thunderstorm with rain.)
function weatherHas(txt as String, word as String) as Boolean
    return txt.Instr(word) >= 0
end function

sub drawHubWeatherSummary(root as Object)
    startWeatherSync(false)
    theme = monthTheme(nowInfo().month)
    mkLabelW(root, weatherSummary(), 610, 138, 700, 22, theme.a, "center")
end sub
