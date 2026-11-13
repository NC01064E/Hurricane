' ================= NWS weather for ZIP 33417 =================

sub setupWeather()
    m.weatherTask = m.top.findNode("weatherTask")
    m.weatherTask.observeField("payload", "onWeatherPayload")
    m.weatherTask.observeField("error", "onWeatherError")
    m.weatherRunning = false
    m.weatherStatus = ""
    m.weatherLastError = ""
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
    m.weatherTask.control = "STOP"
    m.weatherTask.control = "RUN"
end sub

sub onWeatherPayload()
    data = m.weatherTask.payload
    m.weatherRunning = false
    if data = invalid then return
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
    txt = LCase(data.current.forecast)
    if Instr(0, txt, "thunder") >= 0 or Instr(0, txt, "storm") >= 0 then return "thunder"
    if Instr(0, txt, "rain") >= 0 or Instr(0, txt, "shower") >= 0 or Instr(0, txt, "drizzle") >= 0 then return "rain"
    if data.current.windMph <> invalid and data.current.windMph >= 20 then return "wind"
    if data.current.gustMph <> invalid and data.current.gustMph >= 25 then return "wind"
    if Instr(0, txt, "wind") >= 0 or Instr(0, txt, "breezy") >= 0 or Instr(0, txt, "gust") >= 0 then return "wind"
    if Instr(0, txt, "sunny") >= 0 then return "sun"
    if Instr(0, txt, "clear") >= 0 or Instr(0, txt, "fair") >= 0 then return "clear"
    if Instr(0, txt, "cloud") >= 0 or Instr(0, txt, "overcast") >= 0 or Instr(0, txt, "fog") >= 0 then return "cloud"
    return "cloud"
end function

sub drawHubWeatherSummary(root as Object)
    startWeatherSync(false)
    theme = monthTheme(nowInfo().month)
    mkLabelW(root, weatherSummary(), 610, 138, 700, 22, theme.a, "center")
end sub
