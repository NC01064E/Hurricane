' ================= Family Calendar =================

sub setupCalendar()
    m.calendarTask = m.top.findNode("calendarTask")
    m.calendarTask.observeField("payload", "onCalendarPayload")
    m.calendarTask.observeField("error", "onCalendarError")
    info = CreateObject("roAppInfo")
    m.calendarServiceUrl = info.GetValue("calendar_service_url")
    if m.calendarServiceUrl = invalid then m.calendarServiceUrl = ""
    m.calendarRunning = false
    m.calendarStatus = ""
    m.calendarLastError = ""
    m.calendarPairUrl = ""
    m.calendarPage = 0
    m.calendarPageSize = 5
    m.todayEventOffset = 0
    m.tomorrowEventOffset = 0
end sub

sub startCalendarSync(force as Boolean)
    if m.calendarServiceUrl = "" then
        m.calendarStatus = "SETUP"
        return
    end if
    if m.calendarRunning then return
    now = CreateObject("roDateTime").AsSeconds()
    if not force and m.state.calendar.lastSync > 0 then
        if now - m.state.calendar.lastSync < 1800 then return
    end if
    m.calendarRunning = true
    m.calendarStatus = "SYNCING"
    m.calendarTask.serviceUrl = m.calendarServiceUrl
    m.calendarTask.pairCode = m.state.calendar.pairCode
    m.calendarTask.deviceKey = m.state.calendar.deviceKey
    m.calendarTask.control = "STOP"
    m.calendarTask.control = "RUN"
end sub

sub onCalendarPayload()
    data = m.calendarTask.payload
    m.calendarRunning = false
    if data = invalid then return
    if data.deviceKey <> invalid and data.deviceKey <> "" then m.state.calendar.deviceKey = data.deviceKey
    if data.pairUrl <> invalid then m.calendarPairUrl = data.pairUrl
    if data.status = "pairing" then
        m.calendarStatus = "PAIRING"
        saveState()
        if m.screen = "calendar" then rebuildScreen()
        return
    end if
    if data.events <> invalid then
        m.state.calendar.cache = data
        m.state.calendar.lastSync = CreateObject("roDateTime").AsSeconds()
        m.calendarStatus = "READY"
        m.calendarLastError = ""
        saveState()
    end if
    if m.screen = "calendar" or m.screen = "hub" then rebuildScreen()
end sub

sub onCalendarError()
    m.calendarRunning = false
    err = m.calendarTask.error
    m.calendarLastError = err
    if err = "RECONNECT" then
        m.state.calendar.deviceKey = ""
        m.calendarStatus = "RECONNECT"
        saveState()
    else
        m.calendarStatus = err
    end if
    if m.screen = "calendar" or m.screen = "hub" or m.screen = "ambient" then rebuildScreen()
end sub

function calendarEvents() as Object
    cache = m.state.calendar.cache
    if cache = invalid or cache.events = invalid then return []
    return cache.events
end function

function calendarVisibleEvents() as Object
    visible = []
    cutoff = CreateObject("roDateTime").AsSeconds() + (m.state.calendar.viewDays * 86400)
    for each ev in calendarEvents()
        if ev.start <> invalid and ev.start <> "" then
            eventTime = CreateObject("roDateTime")
            eventTime.FromISO8601String(ev.start)
            if eventTime.AsSeconds() <= cutoff then visible.push(ev)
        end if
    end for
    return visible
end function

sub setCalendarView(days as Integer)
    m.state.calendar.viewDays = days
    m.calendarPage = 0
    saveState()
    rebuildScreen()
end sub

sub changeCalendarPage(direction as Integer)
    events = calendarVisibleEvents()
    pageCount = 1
    if events.count() > 0 then pageCount = (events.count() + m.calendarPageSize - 1) \ m.calendarPageSize
    nextPage = m.calendarPage + direction
    if nextPage < 0 then nextPage = 0
    if nextPage >= pageCount then nextPage = pageCount - 1
    m.calendarPage = nextPage
    rebuildScreen()
end sub

function calendarSyncLabel() as String
    if m.state.calendar.lastSync <= 0 then return "Not synced yet"
    ago = CreateObject("roDateTime").AsSeconds() - m.state.calendar.lastSync
    prefix = ""
    if m.calendarLastError <> invalid and m.calendarLastError <> "" then prefix = "Offline · saved schedule · "
    if ago < 60 then return prefix + "Updated just now"
    mins = ago \ 60
    if mins < 60 then return prefix + "Updated " + mins.toStr() + " min ago"
    hrs = mins \ 60
    return prefix + "Updated " + hrs.toStr() + " hr ago"
end function

sub drawCalendarEvent(root as Object, ev as Object, x as Integer, y as Integer, w as Integer, compact as Boolean)
    h = 84
    fs = 27
    if compact then h = 66 : fs = 21
    bg = "0x161E38FF"
    mkRect(root, x, y, w, h, bg)
    color = "0x2F6BFFFF"
    if ev.color <> invalid and ev.color <> "" then color = ev.color
    mkRect(root, x, y, 8, h, color)
    timeText = "ALL DAY"
    if ev.timeLabel <> invalid and ev.timeLabel <> "" then timeText = ev.timeLabel
    mkLabelW(root, timeText, x + 22, y + 12, 155, fs - 3, m.C.gold, "left")
    title = "Untitled event"
    if ev.title <> invalid and ev.title <> "" then title = ev.title
    mkLabelW(root, title, x + 180, y + 10, w - 198, fs, m.C.text, "left")
    if not compact then
        meta = ""
        if ev.calendar <> invalid then meta = ev.calendar
        if ev.location <> invalid and ev.location <> "" then
            if meta <> "" then meta = meta + "  ·  "
            meta = meta + ev.location
        end if
        mkLabelW(root, meta, x + 180, y + 48, w - 198, 20, m.C.dim, "left")
    end if
end sub

sub buildCalendar()
    root = m.screenRoot
    mkLabel(root, "FAMILY CALENDAR", 56, 88, 46, m.C.text)
    mkLabelW(root, "Google Calendar · read-only family schedule", 56, 146, 900, 24, m.C.dim, "left")
    refresh = addItem(root, "action", "calrefresh", 5, 0, 1570, 92, 294, 70, "0x3E63DDFF")
    refreshText = "REFRESH NOW"
    if m.calendarRunning then refreshText = "REFRESHING..."
    mkLabelW(refresh.node, refreshText, 0, 19, 294, 28, m.C.text, "center")

    if m.calendarServiceUrl = "" then
        mkRect(root, 250, 260, 1420, 520, "0x182343FF")
        mkLabelW(root, "CALENDAR SERVICE SETUP REQUIRED", 320, 318, 1280, 38, m.C.gold, "center")
        mkLabelW(root, "Your Roku calendar page is installed. Deploy the companion service, then set calendar_service_url in the manifest.", 380, 396, 1160, 28, m.C.text, "center")
        mkLabelW(root, "PAIRING CODE", 760, 510, 400, 22, m.C.dim, "center")
        mkLabelW(root, m.state.calendar.pairCode, 760, 548, 400, 62, m.C.gold, "center")
        mkLabelW(root, "The Google credentials remain on the secure service, never inside the Roku ZIP.", 380, 672, 1160, 24, m.C.green, "center")
        return
    end if

    if m.state.calendar.deviceKey = "" then
        startCalendarSync(false)
        mkRect(root, 250, 250, 1420, 540, "0x182343FF")
        mkLabelW(root, "PAIR GOOGLE CALENDAR", 350, 300, 1220, 40, m.C.text, "center")
        mkLabelW(root, "On your phone or computer, open the pairing page and enter:", 350, 378, 1220, 26, m.C.dim, "center")
        if m.calendarPairUrl <> "" then mkLabelW(root, m.calendarPairUrl, 350, 430, 1220, 28, m.C.blue, "center")
        mkLabelW(root, m.state.calendar.pairCode, 720, 500, 480, 76, m.C.gold, "center")
        help = "Authorize read-only Google Calendar access once. This page will connect automatically afterward."
        if m.calendarStatus = "RECONNECT" then help = "Google access expired or was revoked. Pair again to reconnect."
        mkLabelW(root, help, 350, 630, 1220, 26, m.C.green, "center")
        return
    end if

    startCalendarSync(false)
    mkLabelW(root, calendarSyncLabel(), 1050, 150, 490, 22, m.C.dim, "right")
    viewDays = m.state.calendar.viewDays
    dayChoices = [3, 7, 30]
    for i = 0 to dayChoices.count() - 1
        days = dayChoices[i]
        bg = m.C.panel
        if days = viewDays then bg = m.C.accent
        button = addItem(root, "action", "caldays" + days.toStr(), i, 0, 56 + (i * 164), 190, 150, 54, bg)
        mkLabelW(button.node, days.toStr() + " DAYS", 0, 14, 150, 23, m.C.text, "center")
    end for
    prev = addItem(root, "action", "calprev", 3, 0, 1190, 190, 150, 54, m.C.panel)
    mkLabelW(prev.node, "< PREV", 0, 14, 150, 23, m.C.text, "center")
    nextButton = addItem(root, "action", "calnext", 4, 0, 1354, 190, 150, 54, m.C.panel)
    mkLabelW(nextButton.node, "NEXT >", 0, 14, 150, 23, m.C.text, "center")

    events = calendarVisibleEvents()
    if events.count() = 0 then
        mkRect(root, 250, 300, 1420, 300, "0x182343FF")
        mkLabelW(root, "No upcoming events", 350, 386, 1220, 40, m.C.text, "center")
        mkLabelW(root, "Your connected calendars are clear for the next " + viewDays.toStr() + " days.", 350, 458, 1220, 25, m.C.dim, "center")
        return
    end if
    pageCount = (events.count() + m.calendarPageSize - 1) \ m.calendarPageSize
    if m.calendarPage >= pageCount then m.calendarPage = pageCount - 1
    if m.calendarPage < 0 then m.calendarPage = 0
    firstIndex = m.calendarPage * m.calendarPageSize
    lastIndex = firstIndex + m.calendarPageSize - 1
    if lastIndex >= events.count() then lastIndex = events.count() - 1
    displayFirst = firstIndex + 1
    displayLast = lastIndex + 1
    displayPage = m.calendarPage + 1
    mkLabelW(root, "EVENTS " + displayFirst.toStr() + "-" + displayLast.toStr() + " OF " + events.count().toStr() + "  ·  PAGE " + displayPage.toStr() + " OF " + pageCount.toStr(), 700, 204, 440, 22, m.C.dim, "center")
    y = 275
    lastDay = ""
    for i = firstIndex to lastIndex
        ev = events[i]
        dayLabel = "UPCOMING"
        if ev.dayLabel <> invalid and ev.dayLabel <> "" then dayLabel = ev.dayLabel
        if dayLabel <> lastDay then
            mkLabel(root, dayLabel, 56, y, 24, m.C.yellow)
            y = y + 38
            lastDay = dayLabel
        end if
        drawCalendarEvent(root, ev, 56, y, 1808, false)
        y = y + 94
        if y > 970 then exit for
    end for
end sub

function hubDayEvents(flagName as String) as Object
    result = []
    for each ev in calendarEvents()
        matches = false
        if ev[flagName] <> invalid then matches = ev[flagName]
        if matches then result.push(ev)
    end for
    return result
end function

sub drawHubEventCard(root as Object, x as Integer, heading as String, flagName as String, itemId as String, navCol as Integer, accent as String, emptyText as String)
    visibleCount = 3
    theme = monthTheme(nowInfo().month)
    surface = monthSurfaceTheme(nowInfo().month)
    localAccent = theme.a
    if navCol = 1 then localAccent = theme.b
    events = hubDayEvents(flagName)
    offset = m.todayEventOffset
    if itemId = "tomorrowevents" then offset = m.tomorrowEventOffset
    maxOffset = events.count() - visibleCount
    if maxOffset < 0 then maxOffset = 0
    if offset > maxOffset then offset = maxOffset
    if offset < 0 then offset = 0
    if itemId = "todayevents" then
        m.todayEventOffset = offset
    else
        m.tomorrowEventOffset = offset
    end if

    card = addItem(root, "eventcard", itemId, navCol, -1, x, 190, 284, 330, surface.panel)
    g = card.node
    mkRect(g, 0, 0, 284, 6, localAccent)
    mkLabelW(g, heading, 16, 20, 252, 22, theme.b, "center")

    if events.count() = 0 then
        msg = emptyText
        if m.state.calendar.deviceKey = "" then msg = "Connect on the Calendar page"
        if m.calendarRunning then msg = "Loading calendar..."
        mkLabelW(g, msg, 22, 115, 232, 20, m.C.dim, "center")
    else
        rowY = 64
        lastIndex = offset + visibleCount - 1
        if lastIndex >= events.count() then lastIndex = events.count() - 1
        for i = offset to lastIndex
            ev = events[i]
            timeText = "ALL DAY"
            if ev.timeLabel <> invalid and ev.timeLabel <> "" then timeText = ev.timeLabel
            mkLabelW(g, timeText, 16, rowY + 4, 78, 17, theme.a, "left")
            title = "Untitled"
            if ev.title <> invalid and ev.title <> "" then title = ev.title
            titleLabel = mkLabelW(g, title, 96, rowY, 166, 18, m.C.text, "left")
            titleLabel.maxLines = 2
            titleLabel.ellipsizeOnBoundary = true
            mkRect(g, 16, rowY + 74, 246, 1, surface.line)
            rowY = rowY + 82
        end for
    end if

    if events.count() > visibleCount then
        trackY = 64
        trackH = 238
        mkRect(g, 274, trackY, 4, trackH, surface.line)
        thumbH = (trackH * visibleCount) \ events.count()
        if thumbH < 34 then thumbH = 34
        thumbY = trackY
        if maxOffset > 0 then thumbY = trackY + ((trackH - thumbH) * offset) \ maxOffset
        mkRect(g, 271, thumbY, 10, thumbH, localAccent)
        mkLabelW(g, "UP/DOWN TO SCROLL", 30, 306, 224, 14, m.C.dim, "center")
    end if
end sub

sub drawHubCalendarSnippet(root as Object)
    drawHubEventCard(root, 56, "TODAY'S EVENTS", "isToday", "todayevents", 0, "0x2F6BFFFF", "No events today")
end sub

sub drawHubTomorrowSnippet(root as Object)
    drawHubEventCard(root, 1580, "TOMORROW'S EVENTS", "isTomorrow", "tomorrowevents", 1, "0xB96BFFFF", "No events tomorrow")
end sub

function scrollHubEventCard(itemId as String, direction as Integer) as Boolean
    flagName = "isToday"
    offset = m.todayEventOffset
    if itemId = "tomorrowevents" then
        flagName = "isTomorrow"
        offset = m.tomorrowEventOffset
    end if
    maxOffset = hubDayEvents(flagName).count() - 3
    if maxOffset < 0 then maxOffset = 0
    nextOffset = offset + direction
    if nextOffset < 0 or nextOffset > maxOffset then return false
    if itemId = "todayevents" then
        m.todayEventOffset = nextOffset
    else
        m.tomorrowEventOffset = nextOffset
    end if
    rebuildScreen()
    return true
end function
