' ================= Today news and sports tickers =================

sub setupTickers()
    m.tickerTask = m.top.findNode("tickerTask")
    m.tickerTask.observeField("payload", "onTickerPayload")
    m.tickerTask.observeField("error", "onTickerError")
    info = CreateObject("roAppInfo")
    m.tickerServiceUrl = info.GetValue("calendar_service_url")
    if m.tickerServiceUrl = invalid then m.tickerServiceUrl = ""
    m.tickerRunning = false
    m.tickerStatus = ""
    m.tickerLastError = ""
    m.tickerLastAttempt = 0
    m.newsTickerGroup = invalid
    m.sportsTickerGroup = invalid
    m.newsTickerX = 1920.0
    m.sportsTickerX = 1480.0
    m.newsTickerWidth = 2200
    m.sportsTickerWidth = 2200
end sub

function tickerToggleWord(enabled as Boolean) as String
    if enabled then return "ON"
    return "OFF"
end function

sub startTickerSync(force as Boolean)
    if m.tickerServiceUrl = "" then m.tickerStatus = "SETUP" : return
    if not m.state.tickers.newsEnabled and not m.state.tickers.sportsEnabled then return
    if m.state.calendar.deviceKey = invalid or m.state.calendar.deviceKey = "" then
        m.tickerStatus = "PAIRING"
        return
    end if
    if m.tickerRunning then return
    now = CreateObject("roDateTime").AsSeconds()
    if not force and m.state.tickers.lastSync > 0 and now - m.state.tickers.lastSync < 600 then return
    if not force and m.tickerLastAttempt > 0 and now - m.tickerLastAttempt < 300 then return
    m.tickerLastAttempt = now
    m.tickerRunning = true
    m.tickerStatus = "UPDATING"
    m.tickerTask.serviceUrl = m.tickerServiceUrl
    m.tickerTask.pairCode = m.state.calendar.pairCode
    m.tickerTask.deviceKey = m.state.calendar.deviceKey
    m.tickerTask.control = "STOP"
    m.tickerTask.control = "RUN"
end sub

sub onTickerPayload()
    data = m.tickerTask.payload
    m.tickerRunning = false
    if data = invalid then return
    cache = m.state.tickers.cache
    if cache = invalid then cache = {}
    if data.news <> invalid and data.news.count() > 0 then cache.news = data.news
    if data.sports <> invalid and data.sports.count() > 0 then cache.sports = data.sports
    if data.generatedAt <> invalid then cache.generatedAt = data.generatedAt
    m.state.tickers.cache = cache
    m.state.tickers.lastSync = CreateObject("roDateTime").AsSeconds()
    m.tickerStatus = "READY"
    if data.status <> invalid and data.status <> "" then m.tickerStatus = UCase(data.status)
    m.tickerLastError = ""
    saveState()
    if m.screen = "hub" then rebuildScreen()
end sub

sub onTickerError()
    m.tickerRunning = false
    err = m.tickerTask.error
    if err = invalid or err = "" then err = "OFFLINE"
    m.tickerLastError = err
    m.tickerStatus = err
    if m.screen = "hub" then rebuildScreen()
end sub

function tickerNewsText() as String
    if not m.state.tickers.newsEnabled then return ""
    cache = m.state.tickers.cache
    if cache <> invalid and cache.news <> invalid and cache.news.count() > 0 then
        out = "LATEST & BREAKING NEWS · MULTI-SOURCE"
        for each story in cache.news
            if story.title <> invalid and story.title <> "" then
                storyFlag = "TOP STORY"
                if story.fresh <> invalid and story.fresh then storyFlag = "NEW"
                source = ""
                if story.source <> invalid and story.source <> "" then source = " · " + UCase(story.source)
                summary = ""
                if story.summary <> invalid and story.summary <> "" then summary = " — " + story.summary
                out = out + "     ◆     " + storyFlag + " · " + story.title + summary + source
            end if
        end for
        return out + "     ◆"
    end if
    if m.tickerStatus = "SETUP" then return "NEWS · COMPANION SERVICE SETUP NEEDED"
    if m.tickerStatus = "PAIRING" or m.tickerStatus = "RECONNECT" then return "NEWS · CONNECT THE CALENDAR SERVICE TO ACTIVATE"
    if m.tickerLastError <> "" then return "NEWS · SAVED HEADLINES UNAVAILABLE · RETRYING AUTOMATICALLY"
    return "LATEST NEWS · UPDATING U.S. TOP STORIES..."
end function

function tickerSportsText() as String
    if not m.state.tickers.sportsEnabled then return ""
    cache = m.state.tickers.cache
    if cache <> invalid and cache.sports <> invalid and cache.sports.count() > 0 then
        out = "SPORTS · ESPN SCORES"
        for each game in cache.sports
            league = game.league
            if league = invalid then league = "SPORTS"
            gameText = game.text
            if gameText = invalid then gameText = ""
            out = out + "     ◆     " + league + " · " + gameText
        end for
        return out + "     ◆"
    end if
    if m.tickerStatus = "PAIRING" or m.tickerStatus = "RECONNECT" then return "SPORTS · CONNECT THE CALENDAR SERVICE TO ACTIVATE"
    if m.tickerLastError <> "" then return "SPORTS · SAVED SCORES UNAVAILABLE · RETRYING AUTOMATICALLY"
    return "SPORTS · UPDATING NFL · NBA · NHL · MLB · COLLEGE SCORES..."
end function

sub drawOneTicker(root as Object, textValue as String, y as Integer, bg as String, color as String, tickerKind as String)
    if textValue = "" then return
    mkRect(root, 0, y, 1920, 24, bg)
    group = CreateObject("roSGNode", "Group")
    root.appendChild(group)
    label = mkLabelW(group, textValue, 0, 1, 12000, 18, color, "left")
    label.wrap = false
    width = textValue.len() * 11 + 120
    if width < 2200 then width = 2200
    if tickerKind = "news" then
        m.newsTickerGroup = group
        m.newsTickerWidth = width
        group.translation = [m.newsTickerX, y]
    else
        m.sportsTickerGroup = group
        m.sportsTickerWidth = width
        group.translation = [m.sportsTickerX, y]
    end if
end sub

sub drawHubTickers(root as Object)
    startTickerSync(false)
    m.newsTickerGroup = invalid
    m.sportsTickerGroup = invalid
    if m.state.tickers.newsEnabled and m.state.tickers.sportsEnabled then
        drawOneTicker(root, tickerNewsText(), 1032, "0x071226F8", "0xF2F5FFFF", "news")
        drawOneTicker(root, tickerSportsText(), 1056, "0x15112AF8", "0xFFD97EFF", "sports")
    else if m.state.tickers.newsEnabled then
        drawOneTicker(root, tickerNewsText(), 1050, "0x071226F8", "0xF2F5FFFF", "news")
    else if m.state.tickers.sportsEnabled then
        drawOneTicker(root, tickerSportsText(), 1050, "0x15112AF8", "0xFFD97EFF", "sports")
    end if
end sub

sub onTickerTick()
    if m.screen <> "hub" then return
    if m.newsTickerGroup <> invalid then
        m.newsTickerX = m.newsTickerX - 1.4
        if m.newsTickerX <= -m.newsTickerWidth then m.newsTickerX = 1920.0
        m.newsTickerGroup.translation = [m.newsTickerX, m.newsTickerGroup.translation[1]]
    end if
    if m.sportsTickerGroup <> invalid then
        m.sportsTickerX = m.sportsTickerX - 1.2
        if m.sportsTickerX <= -m.sportsTickerWidth then m.sportsTickerX = 1920.0
        m.sportsTickerGroup.translation = [m.sportsTickerX, m.sportsTickerGroup.translation[1]]
    end if
end sub
