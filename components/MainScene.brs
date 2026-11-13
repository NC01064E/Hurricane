' ================= Our House Plan - MainScene =================

sub init()
    m.C = {
        panel: "0x101830FF", row: "0x161E38FF", rowDone: "0x14301EFF",
        accent: "0x2F6BFFFF", text: "0xF2F5FFFF", dim: "0x9FB0DDFF",
        green: "0x7EE2A8FF", gold: "0xE8B93CFF", yellow: "0xFFD97EFF",
        blue: "0x8EC9FFFF", border: "0xFFD97EFF"
    }
    m.kids = ["emily", "max", "anthony"]
    m.players = ["emily", "max", "anthony", "parents"]
    m.screenRoot = m.top.findNode("screenRoot")
    m.menuBar = m.top.findNode("menuBar")
    m.flash = m.top.findNode("flash")
    m.flashT = 0
    m.area = "menu"
    m.menuIdx = 0
    m.focusIdx = 0
    m.screen = "hub"
    m.admin = false
    m.pinBuf = ""
    m.pinPurpose = ""
    m.pinStage = 0
    m.pinFirst = ""
    m.pinMsg = ""
    m.pendingBuy = ""
    m.pinWho = ""
    m.pinReturn = "avatar"
    m.activeKey = ""
    m.adminShortcutKey = ""
    m.adminShortcutScreen = "hub"
    m.adminShortcutArea = "content"
    m.adminShortcutFocus = 0
    m.adminShortcutDestination = "action"
    m.oneShotAdmin = false
    m.shopPage = 0
    m.inventoryPage = 0
    m.inventoryCat = "outfit"
    m.toastT = 0
    m.lastKeySec = 0
    m.lastTodayPhase = ""
    m.ambientOrigin = "hub"
    m.ambientClockLabel = invalid
    m.ambientDateLabel = invalid
    m.ambientAvatarGroup = invalid
    m.ambientWeatherGroup = invalid
    m.ambientLightningGroup = invalid
    m.ambientWeatherKind = "none"
    m.ambientWeatherOffset = 0
    m.ambientSeasonFxGroup = invalid
    m.ambientSeasonKind = "fall"
    m.ambientSeasonOffset = 0
    m.ambientPulse = 0
    m.ambientScrollX = 0
    m.ambientMinute = -1
    m.familyKeyboard = invalid
    m.familyEditId = ""
    m.mealPlanDay = -1
    m.musicTriedBackup = false
    m.recoveredState = false
    m.stateBytes = 0
    m.backupBytes = 0
    m.storageTrimmed = false
    m.menuDefs = [
        { label: "Today", key: "hub" },
        { label: "Calendar", key: "calendar" },
        { label: "Meals", key: "family" },
        { label: "Music", key: "music" },
        { label: "Game", key: "game" },
        { label: "Reset", key: "reset" },
        { label: "Chores", key: "chores" },
        { label: "Crew", key: "crew" },
        { label: "Rhythm", key: "rhythm" },
        { label: "One Surface", key: "surface" },
        { label: "Avatar", key: "avatar" },
        { label: "Shop", key: "shop" },
        { label: "Admin", key: "admin" }
    ]
    m.timers = {
        zone: { total: 1200, left: 1200, running: false },
        family: { total: 600, left: 600, running: false },
        surface: { total: 300, left: 300, running: false }
    }
    m.timerLabels = {}
    loadState()
    m.screenSaverGuard = m.top.findNode("screenSaverGuard")
    if m.screenSaverGuard <> invalid then m.screenSaverGuard.disableScreenSaver = true
    setupCalendar()
    setupWeather()
    setupTickers()
    m.lastDateKey = ""
    ensureWeek()
    buildMenu()
    setupAudio()
    tick = m.top.findNode("tick")
    tick.observeField("fire", "onTick")
    tick.control = "start"
    tickerTick = m.top.findNode("tickerTick")
    tickerTick.observeField("fire", "onTickerTick")
    tickerTick.control = "start"
    dtI = CreateObject("roDateTime")
    m.lastKeySec = dtI.AsSeconds()
    m.toast = CreateObject("roSGNode", "Group")
    m.toast.translation = [310, 972]
    m.toast.visible = false
    mkRect(m.toast, 0, 0, 1300, 62, "0x1D2A55FF")
    m.toastLabel = mkLabel(m.toast, "", 0, 12, 27, m.C.gold)
    m.toastLabel.width = 1300
    m.toastLabel.horizAlign = "center"
    m.top.appendChild(m.toast)
    showScreen("hub")
    if m.recoveredState then showToast("Recovered your family data from the safety backup")
    m.top.setFocus(true)
end sub

' ---------- state ----------

function defaultState() as Object
    return {
        points: { emily: 0, max: 0, anthony: 0, parents: 0, nicky: 0, house: 0 },
        week: { key: "", points: { emily: 0, max: 0, anthony: 0, parents: 0, nicky: 0 }, lastWinner: invalid },
        counts: {},
        checks: {},
        reminded: {},
        zones: {},
        zoneOwner: {},
        pin: "",
        shopPins: {},
        reassign: {},
        streaks: {},
        muted: false,
        musicMode: "theme",
        podiumAvatar: "preset",
        calendar: { pairCode: "", deviceKey: "", cache: {}, lastSync: 0, viewDays: 7, cacheVersion: 2 },
        weather: { cache: {}, lastSync: 0 },
        tickers: { newsEnabled: true, sportsEnabled: true, cache: {}, lastSync: 0, cacheVersion: 3 },
        todayMode: "auto",
        family: {
            meals: ["", "", "", "", "", "", ""],
            mealPlans: [
                { entree: "", side: "", vegetable: "", other: "" },
                { entree: "", side: "", vegetable: "", other: "" },
                { entree: "", side: "", vegetable: "", other: "" },
                { entree: "", side: "", vegetable: "", other: "" },
                { entree: "", side: "", vegetable: "", other: "" },
                { entree: "", side: "", vegetable: "", other: "" },
                { entree: "", side: "", vegetable: "", other: "" }
            ],
            announcements: ["", "", ""],
            reminders: [
                { text: "", expires: 0 }, { text: "", expires: 0 },
                { text: "", expires: 0 }, { text: "", expires: 0 }
            ]
        },
        houseZones: 0,
        schemaVersion: 78
    }
end function

sub loadState()
    sec = CreateObject("roRegistrySection", "ourhouseplan")
    raw = sec.Read("state")
    backupRaw = sec.Read("state_backup")
    if backupRaw <> invalid then m.backupBytes = backupRaw.len()
    st = invalid
    if raw <> invalid and raw <> "" then st = ParseJSON(raw)
    if st = invalid then
        if backupRaw <> invalid and backupRaw <> "" then
            st = ParseJSON(backupRaw)
            if st <> invalid then
                raw = backupRaw
                m.recoveredState = true
            end if
        end if
    end if
    if st = invalid then st = defaultState()
    if st.week = invalid then st.week = { key: "", points: { emily: 0, max: 0, anthony: 0, parents: 0, nicky: 0 }, lastWinner: invalid }
    if st.reminded = invalid then st.reminded = {}
    if st.zoneOwner = invalid then st.zoneOwner = {}
    if st.pin = invalid then st.pin = ""
    if st.shopPins = invalid then st.shopPins = {}
    legacyPin = ""
    if st.shopPin <> invalid then legacyPin = st.shopPin
    for each pk in profileKeys()
        if st.shopPins[pk] = invalid then st.shopPins[pk] = legacyPin
    end for
    if st.podiumAvatar = invalid then st.podiumAvatar = "preset"
    if st.musicMode = "jazz" then st.musicMode = "smoothjazz"
    if st.musicMode = invalid then
        st.musicMode = "theme"
        if st.muted then st.musicMode = "off"
    end if
    st.muted = st.musicMode = "off"
    if st.calendar = invalid then st.calendar = { pairCode: "", deviceKey: "", cache: {}, lastSync: 0 }
    if st.calendar.pairCode = invalid or st.calendar.pairCode.len() <> 6 then
        calNow = CreateObject("roDateTime")
        st.calendar.pairCode = (100000 + (calNow.AsSeconds() mod 900000)).toStr()
    end if
    if st.calendar.deviceKey = invalid then st.calendar.deviceKey = ""
    if st.calendar.cache = invalid then st.calendar.cache = {}
    if st.calendar.lastSync = invalid then st.calendar.lastSync = 0
    if st.calendar.viewDays = invalid then st.calendar.viewDays = 7
    if st.calendar.viewDays <> 3 and st.calendar.viewDays <> 7 and st.calendar.viewDays <> 30 then st.calendar.viewDays = 7
    if st.calendar.cacheVersion = invalid or st.calendar.cacheVersion < 2 then
        st.calendar.cacheVersion = 2
        st.calendar.lastSync = 0
    end if
    if st.weather = invalid then st.weather = { cache: {}, lastSync: 0 }
    if st.weather.cache = invalid then st.weather.cache = {}
    if st.weather.lastSync = invalid then st.weather.lastSync = 0
    if st.tickers = invalid then st.tickers = { newsEnabled: true, sportsEnabled: true, cache: {}, lastSync: 0, cacheVersion: 3 }
    if st.tickers.newsEnabled = invalid then st.tickers.newsEnabled = true
    if st.tickers.sportsEnabled = invalid then
        st.tickers.sportsEnabled = true
        if st.tickers.marketsEnabled <> invalid then st.tickers.sportsEnabled = st.tickers.marketsEnabled
    end if
    if st.tickers.cache = invalid then st.tickers.cache = {}
    if st.tickers.lastSync = invalid then st.tickers.lastSync = 0
    if st.tickers.cacheVersion = invalid or st.tickers.cacheVersion < 3 then
        st.tickers.cacheVersion = 3
        st.tickers.cache = {}
        st.tickers.lastSync = 0
    end if
    if st.todayMode = invalid then st.todayMode = "auto"
    if st.todayMode <> "auto" and st.todayMode <> "morning" and st.todayMode <> "afternoon" and st.todayMode <> "evening" and st.todayMode <> "late" then st.todayMode = "auto"
    if st.points.nicky = invalid then st.points.nicky = 0
    if st.week.points.nicky = invalid then st.week.points.nicky = 0
    if st.family = invalid then st.family = {}
    if st.family.meals = invalid then st.family.meals = ["", "", "", "", "", "", ""]
    while st.family.meals.count() < 7
        st.family.meals.push("")
    end while
    if st.family.mealPlans = invalid then st.family.mealPlans = []
    while st.family.mealPlans.count() < 7
        st.family.mealPlans.push({ entree: "", side: "", vegetable: "", other: "" })
    end while
    for each plan in st.family.mealPlans
        if plan.entree = invalid then plan.entree = ""
        if plan.side = invalid then plan.side = ""
        if plan.vegetable = invalid then plan.vegetable = ""
        if plan.other = invalid then plan.other = ""
    end for
    if st.family.announcements = invalid then st.family.announcements = ["", "", ""]
    while st.family.announcements.count() < 3
        st.family.announcements.push("")
    end while
    if st.family.reminders = invalid then st.family.reminders = []
    while st.family.reminders.count() < 4
        st.family.reminders.push({ text: "", expires: 0 })
    end while
    for each reminder in st.family.reminders
        if reminder.text = invalid then reminder.text = ""
        if reminder.expires = invalid then reminder.expires = 0
    end for
    if st.schemaVersion = invalid or st.schemaVersion < 78 then st.schemaVersion = 78
    m.state = st
    m.sec = sec
    if raw <> invalid then m.stateBytes = raw.len()
    ensureCbState()
end sub

sub saveState()
    m.state.schemaVersion = 78
    storedState = storageSafeState()
    newRaw = FormatJSON(storedState)
    m.sec.Write("state", newRaw)
    recoveryState = ParseJSON(FormatJSON(storedState))
    if recoveryState <> invalid then
        if recoveryState.calendar <> invalid then recoveryState.calendar.cache = {}
        if recoveryState.weather <> invalid then recoveryState.weather.cache = {}
        if recoveryState.tickers <> invalid then recoveryState.tickers.cache = {}
        recoveryDay = nowInfo().dateKey
        recoveryChecks = {}
        recoveryReminders = {}
        recoveryZones = {}
        if recoveryState.checks <> invalid and recoveryState.checks[recoveryDay] <> invalid then recoveryChecks[recoveryDay] = recoveryState.checks[recoveryDay]
        if recoveryState.reminded <> invalid and recoveryState.reminded[recoveryDay] <> invalid then recoveryReminders[recoveryDay] = recoveryState.reminded[recoveryDay]
        if recoveryState.zones <> invalid and recoveryState.zones[recoveryDay] <> invalid then recoveryZones[recoveryDay] = recoveryState.zones[recoveryDay]
        recoveryState.checks = recoveryChecks
        recoveryState.reminded = recoveryReminders
        recoveryState.zones = recoveryZones
    end if
    recoveryRaw = FormatJSON(recoveryState)
    if recoveryRaw.len() <= 12000 then
        m.sec.Write("state_backup", recoveryRaw)
        m.backupBytes = recoveryRaw.len()
    end if
    m.sec.Flush()
    m.stateBytes = newRaw.len()
end sub

function storageSafeState() as Object
    m.storageTrimmed = false
    copy = ParseJSON(FormatJSON(m.state))
    if copy = invalid then return m.state
    raw = FormatJSON(copy)
    if raw.len() > 24000 and copy.calendar <> invalid then
        ' Calendar events can always be fetched again. Purchases, points and avatars cannot.
        copy.calendar.cache = {}
        m.storageTrimmed = true
    end if
    raw = FormatJSON(copy)
    if raw.len() > 26000 and copy.weather <> invalid then
        copy.weather.cache = {}
        m.storageTrimmed = true
    end if
    raw = FormatJSON(copy)
    if raw.len() > 27000 and copy.tickers <> invalid then
        copy.tickers.cache = {}
        m.storageTrimmed = true
    end if
    raw = FormatJSON(copy)
    if raw.len() > 28000 then
        todayKey = nowInfo().dateKey
        compactChecks = {}
        compactReminders = {}
        compactZones = {}
        if copy.checks <> invalid and copy.checks[todayKey] <> invalid then compactChecks[todayKey] = copy.checks[todayKey]
        if copy.reminded <> invalid and copy.reminded[todayKey] <> invalid then compactReminders[todayKey] = copy.reminded[todayKey]
        if copy.zones <> invalid and copy.zones[todayKey] <> invalid then compactZones[todayKey] = copy.zones[todayKey]
        copy.checks = compactChecks
        copy.reminded = compactReminders
        copy.zones = compactZones
        m.storageTrimmed = true
    end if
    return copy
end function

function registryFreeBytes() as Integer
    reg = CreateObject("roRegistry")
    return reg.GetSpaceAvailable()
end function

' ---------- small helpers ----------

function F(size as Integer) as Object
    fontNode = CreateObject("roSGNode", "Font")
    fontNode.uri = "font:SystemFontFile"
    fontNode.size = size
    return fontNode
end function

function mkLabel(parent as Object, txt as String, x as Integer, y as Integer, size as Integer, color as String) as Object
    l = CreateObject("roSGNode", "Label")
    l.text = txt
    l.translation = [x, y]
    l.font = F(size)
    l.color = color
    parent.appendChild(l)
    return l
end function

function mkLabelW(parent as Object, txt as String, x as Integer, y as Integer, w as Integer, size as Integer, color as String, align as String) as Object
    l = mkLabel(parent, txt, x, y, size, color)
    l.width = w
    l.horizAlign = align
    l.wrap = true
    return l
end function

function mkRect(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer, color as String) as Object
    r = CreateObject("roSGNode", "Rectangle")
    r.translation = [x, y]
    r.width = w
    r.height = h
    r.color = color
    parent.appendChild(r)
    return r
end function

function mkPoster(parent as Object, uri as String, x as Integer, y as Integer, w as Integer, h as Integer) as Object
    p = CreateObject("roSGNode", "Poster")
    p.uri = uri
    p.translation = [x, y]
    p.width = w
    p.height = h
    p.loadDisplayMode = "scaleToFit"
    parent.appendChild(p)
    return p
end function

function pad2(n as Integer) as String
    if n < 10 then return "0" + n.toStr()
    return n.toStr()
end function

function formatHubClock() as String
    dt = CreateObject("roDateTime")
    dt.ToLocalTime()
    hour = dt.GetHours()
    suffix = "AM"
    if hour >= 12 then suffix = "PM"
    displayHour = hour mod 12
    if displayHour = 0 then displayHour = 12
    return displayHour.toStr() + ":" + pad2(dt.GetMinutes()) + ":" + pad2(dt.GetSeconds()) + " " + suffix + " ET"
end function

function fmtTime(sec as Integer) as String
    if sec < 0 then sec = 0
    return pad2(sec \ 60) + ":" + pad2(sec mod 60)
end function

function personName(k as String) as String
    if k = "emily" then return "Emily"
    if k = "max" then return "Max"
    if k = "anthony" then return "Anthony"
    if k = "patricia" then return "Trish"
    if k = "nick" then return "Nick"
    if k = "nicky" then return "Nicky"
    if k = "parents" then return "Trish + Nick"
    if k = "house" then return "House"
    if k = "everyone" then return "Everyone"
    if k = "crew" then return "Whole crew"
    return k
end function

function faceUri(k as String) as String
    if k = "house" then return "pkg:/images/faces/house.png"
    if k = "parents" then k = "patricia"
    if k = "everyone" or k = "crew" then k = "nick"
    return "pkg:/images/faces/" + k + ".png"
end function

function bodyUri(k as String) as String
    if k = "parents" then k = "patricia"
    return "pkg:/images/people/" + k + ".png"
end function

function avatarCfgFor(k as String) as Object
    if k = "parents" then k = "patricia"
    if m.state.avatar = invalid then return invalid
    c = m.state.avatar[k]
    if c = invalid then return invalid
    return c
end function

' Draw the person's currently saved avatar in every identity tile. Static face
' art remains only as a safe fallback for house/group records or missing state.
sub drawProfileAvatarFace(parent as Object, k as String, x as Integer, y as Integer, size as Integer)
    cfg = avatarCfgFor(k)
    if cfg = invalid then
        mkPoster(parent, faceUri(k), x, y, size, size)
        return
    end if
    portrait = CreateObject("roSGNode", "Group")
    portrait.translation = [x, y]
    faceScale = size / 100.0
    portrait.scale = [faceScale, faceScale]
    parent.appendChild(portrait)
    drawAvatar(portrait, 0, 0, 1, cfg, "head")
end sub

' ---------- dates and rotations ----------

function daysFromCivil(y as Integer, mo as Integer, d as Integer) as Integer
    yy = y
    if mo <= 2 then yy = yy - 1
    era = yy \ 400
    yoe = yy - era * 400
    mp = (mo + 9) mod 12
    doy = (153 * mp + 2) \ 5 + d - 1
    doe = yoe * 365 + yoe \ 4 - yoe \ 100 + doy
    return era * 146097 + doe - 719468
end function

function nowInfo() as Object
    dt = CreateObject("roDateTime")
    dt.ToLocalTime()
    days = daysFromCivil(dt.GetYear(), dt.GetMonth(), dt.GetDayOfMonth())
    dow = dt.GetDayOfWeek()
    monNames = ["January","February","March","April","May","June","July","August","September","October","November","December"]
    dowNames = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    return {
        days: days, dow: dow, month: dt.GetMonth(), hour: dt.GetHours(), minute: dt.GetMinutes(),
        dateKey: dt.GetYear().toStr() + "-" + pad2(dt.GetMonth()) + "-" + pad2(dt.GetDayOfMonth()),
        label: dowNames[dow] + ", " + monNames[dt.GetMonth() - 1] + " " + dt.GetDayOfMonth().toStr(),
        weekIdx: (days \ 7) mod 3,
        nightIdx: days mod 3,
        isSaturday: (dow = 6)
    }
end function

function todayAutoPhase() as String
    hour = nowInfo().hour
    if hour >= 5 and hour < 8 then return "early"
    if hour >= 8 and hour < 12 then return "morning"
    if hour >= 12 and hour < 17 then return "afternoon"
    if hour >= 17 and hour < 21 then return "evening"
    return "late"
end function

function todayEffectivePhase() as String
    if m.state.todayMode = invalid or m.state.todayMode = "auto" then return todayAutoPhase()
    return m.state.todayMode
end function

function todayPhaseName(phase as String) as String
    if phase = "early" then return "EARLY MORNING"
    if phase = "morning" then return "MID-MORNING"
    if phase = "afternoon" then return "AFTERNOON"
    if phase = "evening" then return "EVENING"
    return "LATE NIGHT"
end function

function todayModeButtonText() as String
    prefix = "AUTO"
    if m.state.todayMode <> invalid and m.state.todayMode <> "auto" then prefix = "MANUAL"
    return prefix + " · " + todayPhaseName(todayEffectivePhase())
end function

sub cycleTodayMode()
    modes = ["auto", "morning", "afternoon", "evening", "late"]
    current = 0
    for i = 0 to modes.count() - 1
        if modes[i] = m.state.todayMode then current = i
    end for
    m.state.todayMode = modes[(current + 1) mod modes.count()]
    m.lastTodayPhase = todayEffectivePhase()
    saveState()
    rebuildScreen()
    showToast("Today mode: " + todayModeButtonText())
end sub

function todayNextEventSummary() as String
    ev = ambientNextEvent()
    if ev = invalid then return "NO UPCOMING CALENDAR EVENT"
    title = "Untitled event"
    if ev.title <> invalid and ev.title <> "" then title = ev.title
    whenText = "UPCOMING"
    if ev.timeLabel <> invalid and ev.timeLabel <> "" then whenText = ev.timeLabel
    if ev.dayLabel <> invalid and ev.dayLabel <> "" then whenText = ev.dayLabel + " · " + whenText
    return whenText + " · " + title
end function

function todayFocusText() as String
    phase = todayEffectivePhase()
    focus = "Preview tomorrow and settle the house"
    if phase = "early" then focus = "Weather, first event and before-school checklist"
    if phase = "morning" then focus = "Finish morning jobs and watch the next event"
    if phase = "afternoon" then focus = "Pickup, activities, homework and after-school reset"
    if phase = "evening" then focus = "Dinner, house reset and tomorrow's schedule"
    if phase = "late" then focus = "Tomorrow's first event, bedtime and alarms"
    return todayPhaseName(phase) + " FOCUS · " + focus + "  |  NEXT: " + todayNextEventSummary()
end function

function todayRowIsPriority(startHour as Integer) as Boolean
    phase = todayEffectivePhase()
    if phase = "early" or phase = "morning" then return startHour < 12
    if phase = "afternoon" then return startHour >= 12 and startHour < 17
    if phase = "evening" then return startHour >= 17
    return false
end function

function zoneOwner(zone as String, weekIdx as Integer) as String
    table = [
        { kitchen: "max", living: "anthony", dining: "emily" },
        { kitchen: "emily", living: "max", dining: "anthony" },
        { kitchen: "anthony", living: "emily", dining: "max" }
    ]
    return table[weekIdx][zone]
end function

function crewOwner(job as String, nightIdx as Integer) as String
    table = [
        { food: "emily", wipe: "max", sweep: "anthony" },
        { food: "anthony", wipe: "emily", sweep: "max" },
        { food: "max", wipe: "anthony", sweep: "emily" }
    ]
    return table[nightIdx][job]
end function

function curbOwner(job as String, nightIdx as Integer) as String
    table = [
        { trash: "emily", recycle: "max" },
        { trash: "anthony", recycle: "emily" },
        { trash: "max", recycle: "anthony" }
    ]
    return table[nightIdx][job]
end function

' ---------- audio ----------

sub setupAudio()
    m.music = m.top.findNode("music")
    m.music.observeField("state", "onMusicState")
    m.alarm = m.top.findNode("alarm")
    c2 = CreateObject("roSGNode", "ContentNode")
    c2.url = "pkg:/audio/alarm-jingle.mp3"
    c2.streamFormat = "mp3"
    m.alarm.content = c2
    applyMusicMode()
end sub

sub toggleMusic()
    stations = musicStations()
    idx = 0
    for i = 0 to stations.count() - 1
        if stations[i].id = m.state.musicMode then idx = i
    end for
    idx = (idx + 1) mod stations.count()
    setMusicMode(stations[idx].id)
end sub

sub applyMusicMode()
    m.music.control = "stop"
    if m.state.musicMode = "off" then return
    station = musicStationById(m.state.musicMode)
    if station = invalid then
        m.state.musicMode = "theme"
        station = musicStationById("theme")
    end if
    c = CreateObject("roSGNode", "ContentNode")
    c.streamFormat = "mp3"
    if station.id = "theme" then
        c.url = "pkg:/audio/theme-loop.mp3"
        m.music.loop = true
    else
        c.url = station.url
        if m.musicTriedBackup and station.backup <> "" then c.url = station.backup
        m.music.loop = false
    end if
    m.music.content = c
    m.music.control = "play"
end sub

sub onMusicState()
    if m.state = invalid then return
    if m.music.state = "error" then
        station = musicStationById(m.state.musicMode)
        if station <> invalid and station.backup <> "" and not m.musicTriedBackup then
            m.musicTriedBackup = true
            showToast("Station interrupted — trying its backup stream")
            applyMusicMode()
        else
            m.state.musicMode = "theme"
            m.musicTriedBackup = false
            saveState()
            showToast("Station unavailable — playing Our House Theme")
            applyMusicMode()
        end if
        if m.screen = "music" then rebuildScreen() else buildMenu()
        return
    end if
    if m.music.state = "finished" and musicModeIsLive(m.state.musicMode) then applyMusicMode()
    if m.screen = "music" and (m.music.state = "playing" or m.music.state = "buffering") then rebuildScreen()
end sub

' ---------- menu ----------

sub buildMenu()
    while m.menuBar.getChildCount() > 0
        m.menuBar.removeChildIndex(0)
    end while
    mkRect(m.menuBar, 0, 0, 1920, 62, "0x0E1533FF")
    m.menuNodes = []
    x = 30
    for i = 0 to m.menuDefs.count() - 1
        d = m.menuDefs[i]
        w = 88
        if d.label = "One Surface" then w = 125
        if d.label = "Calendar" then w = 100
        bgc = "0x00000000"
        tc = m.C.dim
        if m.screen = d.key then bgc = "0x1D2A55FF" : tc = m.C.text
        if m.area = "menu" and m.menuIdx = i then bgc = m.C.accent : tc = m.C.text
        r = mkRect(m.menuBar, x, 8, w, 46, bgc)
        l = mkLabel(m.menuBar, d.label, x, 18, 22, tc)
        l.width = w
        l.horizAlign = "center"
        m.menuNodes.push(r)
        x = x + w + 10
    end for
    statusPrefix = "VIEWER"
    statusColor = m.C.dim
    if m.admin then statusPrefix = "ADMIN" : statusColor = m.C.gold
    mkLabelW(m.menuBar, statusPrefix + " · " + musicModeName(m.state.musicMode), 1420, 20, 455, 20, statusColor, "right")
end sub

' ---------- screens ----------

sub showScreen(key as String)
    m.screen = key
    for i = 0 to m.menuDefs.count() - 1
        if m.menuDefs[i].key = key then m.menuIdx = i
    end for
    rebuildScreen()
end sub

sub rebuildScreen()
    while m.screenRoot.getChildCount() > 0
        m.screenRoot.removeChildIndex(0)
    end while
    m.timerLabels = {}
    m.timerStates = {}
    m.hubClockLabel = invalid
    m.ambientClockLabel = invalid
    m.ambientDateLabel = invalid
    m.ambientAvatarGroup = invalid
    m.ambientWeatherGroup = invalid
    m.ambientLightningGroup = invalid
    m.ambientSeasonFxGroup = invalid
    m.newsTickerGroup = invalid
    m.sportsTickerGroup = invalid
    m.items = []
    if m.screen = "ambient" then buildAmbient()
    if m.screen = "hub" then buildHub()
    if m.screen = "calendar" then buildCalendar()
    if m.screen = "family" then buildFamily()
    if m.screen = "mealplanner" then buildMealPlanner()
    if m.screen = "music" then buildMusic()
    if m.screen = "game" then buildGame()
    if m.screen = "reset" then buildReset()
    if m.screen = "chores" then buildChores()
    if m.screen = "crew" then buildCrew()
    if m.screen = "rhythm" then buildRhythm()
    if m.screen = "surface" then buildSurface()
    if m.screen = "pin" then buildPin()
    if m.screen = "admin" then buildAdmin()
    if m.screen = "levels" then buildLevels()
    if m.screen = "avatar" then buildAvatar()
    if m.screen = "inventory" then buildInventory()
    if m.screen = "shop" then buildShop()
    if m.screen = "confirmbuy" then buildConfirmBuy()
    if m.screen = "pinpick" then buildPinPick()
    if m.screen = "diagnostics" then buildDiagnostics()
    if m.focusIdx >= m.items.count() then m.focusIdx = m.items.count() - 1
    if m.focusIdx < 0 then m.focusIdx = 0
    if m.screen = "ambient" then
        m.menuBar.visible = false
    else
        m.menuBar.visible = true
        buildMenu()
    end if
    updateHighlight()
end sub

sub enterAmbient()
    if m.screen = "ambient" then return
    m.ambientOrigin = m.screen
    if m.ambientOrigin = "pin" or m.ambientOrigin = "admin" or m.ambientOrigin = "diagnostics" then m.ambientOrigin = "hub"
    m.admin = false
    m.ambientMinute = -1
    m.ambientScrollX = 0
    m.ambientWeatherOffset = 0
    m.ambientSeasonOffset = 0
    m.area = "content"
    showScreen("ambient")
end sub

sub exitAmbient()
    destination = m.ambientOrigin
    if destination = invalid or destination = "" or destination = "ambient" then destination = "hub"
    m.area = "menu"
    showScreen(destination)
end sub

function ambientGreeting() as String
    h = nowInfo().hour
    if h < 12 then return "GOOD MORNING"
    if h < 17 then return "GOOD AFTERNOON"
    return "GOOD EVENING"
end function

function monthTheme(month as Integer) as Object
    themes = [
        { name: "JANUARY · WINTER GLOW", tagline: "A fresh start for the whole house", a: "0x73C7FFFF", b: "0xDDF4FFFF", bg: "0x14304CCC" },
        { name: "FEBRUARY · HEART & HOME", tagline: "Kindness is the family superpower", a: "0xFF6B9DFF", b: "0xFFD0DEFF", bg: "0x43162DCC" },
        { name: "MARCH · SPRING AWAKENS", tagline: "Grow good habits one day at a time", a: "0x59D68BFF", b: "0xB8F2CFFF", bg: "0x123B2ACC" },
        { name: "APRIL · RAIN & RENEWAL", tagline: "Small drops make big gardens", a: "0x4DA3FFFF", b: "0xA8D8FFFF", bg: "0x132D4ACC" },
        { name: "MAY · FAMILY GARDEN", tagline: "What we care for together will grow", a: "0x74C95AFF", b: "0xF6D365FF", bg: "0x25391CCC" },
        { name: "JUNE · SUNSHINE DAYS", tagline: "Bright days, cool plans and summer teamwork", a: "0xFFD34EFF", b: "0xFF9F43FF", bg: "0x4A3412CC" },
        { name: "JULY · STARS & SUMMER", tagline: "Celebrate freedom, family and fun", a: "0xEF4B5FFF", b: "0x4B7BFFFF", bg: "0x2D2045CC" },
        { name: "AUGUST · COASTAL DAYS", tagline: "Easy waves and one last summer adventure", a: "0x32C5D2FF", b: "0xFFD27AFF", bg: "0x123D46CC" },
        { name: "SEPTEMBER · READY TO LEARN", tagline: "New routines, sharp pencils, strong starts", a: "0xE9A23BFF", b: "0x7B5CD6FF", bg: "0x3E2A1ACC" },
        { name: "OCTOBER · SPOOKY HOUSE", tagline: "Treats, teamwork and a little mischief", a: "0xFF8A2AFF", b: "0x8B5CF6FF", bg: "0x321849CC" },
        { name: "NOVEMBER · GRATITUDE", tagline: "Notice the good and gather together", a: "0xFFD2A6FF", b: "0xFFE3A0FF", bg: "0x7A4633CC" },
        { name: "DECEMBER · HOLIDAY MAGIC", tagline: "Warm hearts, bright lights and family traditions", a: "0xE84A5FFF", b: "0x42C67AFF", bg: "0x213524CC" }
    ]
    idx = month - 1
    if idx < 0 or idx >= themes.count() then idx = 0
    return themes[idx]
end function

function monthSurfaceTheme(month as Integer) as Object
    surfaces = [
        { canvas: "0x071827FF", panel: "0x102C46FF", row: "0x173B59FF", done: "0x17483CFF", podium: "0x1C4968FF", line: "0x5795BDFF" },
        { canvas: "0x210D1BFF", panel: "0x39152DFF", row: "0x4A1D39FF", done: "0x244437FF", podium: "0x5A2444FF", line: "0xC35C89FF" },
        { canvas: "0x071F17FF", panel: "0x103426FF", row: "0x174936FF", done: "0x23583DFF", podium: "0x1C5A40FF", line: "0x5BCB8CFF" },
        { canvas: "0x091A2AFF", panel: "0x102E49FF", row: "0x183F5EFF", done: "0x1B4B48FF", podium: "0x1D5276FF", line: "0x61AEE8FF" },
        { canvas: "0x13200DFF", panel: "0x26391AFF", row: "0x354B25FF", done: "0x28533BFF", podium: "0x4B5B25FF", line: "0x9CCB62FF" },
        { canvas: "0x28200BFF", panel: "0x443515FF", row: "0x58451BFF", done: "0x31503AFF", podium: "0x6A4E19FF", line: "0xF2BE45FF" },
        { canvas: "0x10162DFF", panel: "0x1B2850FF", row: "0x253663FF", done: "0x244C45FF", podium: "0x403052FF", line: "0xE85A69FF" },
        { canvas: "0x082326FF", panel: "0x103C42FF", row: "0x175158FF", done: "0x245744FF", podium: "0x17646BFF", line: "0x50D0D6FF" },
        { canvas: "0x24170DFF", panel: "0x3B2819FF", row: "0x503722FF", done: "0x354A31FF", podium: "0x553A35FF", line: "0xD49345FF" },
        { canvas: "0x180C25FF", panel: "0x2D1742FF", row: "0x40215AFF", done: "0x33402CFF", podium: "0x57244BFF", line: "0xF28B31FF" },
        { canvas: "0x75432FFF", panel: "0x2B1931FF", row: "0x3C2442FF", done: "0x2E513FFF", podium: "0x4E2B49FF", line: "0xF0A060FF" },
        { canvas: "0x071B13FF", panel: "0x103326FF", row: "0x174737FF", done: "0x24563CFF", podium: "0x6D1025FF", line: "0xD54E5EFF" }
    ]
    idx = month - 1
    if idx < 0 or idx >= surfaces.count() then idx = 0
    return surfaces[idx]
end function

sub drawSeasonalHub(root as Object, month as Integer)
    theme = monthTheme(month)
    surface = monthSurfaceTheme(month)
    ' Keep the themed canvas below the 62px navigation bar; screenRoot renders above menuBar.
    mkRect(root, 0, 62, 1920, 1018, surface.canvas)
    mkRect(root, 0, 68, 1920, 112, theme.bg)
    mkRect(root, 0, 68, 1920, 6, theme.a)
    mkRect(root, 0, 74, 1920, 3, theme.b)
    mkLabelW(root, theme.name, 56, 148, 520, 19, theme.a, "left")
    mkLabelW(root, theme.tagline, 56, 169, 720, 17, theme.b, "left")
    for i = 0 to 9
        x = 620 + (i * 70)
        c = theme.a
        if i mod 2 = 1 then c = theme.b
        mkRect(root, x, 72 + ((i mod 3) * 4), 8, 8, c)
    end for
end sub

function ambientNextEvent() as Object
    nowSec = CreateObject("roDateTime").AsSeconds()
    best = invalid
    bestSec = 2147483647
    for each ev in calendarEvents()
        if ev.start <> invalid and ev.start <> "" then
            eventTime = CreateObject("roDateTime")
            eventTime.FromISO8601String(ev.start)
            sec = eventTime.AsSeconds()
            if sec >= nowSec - 3600 and sec < bestSec then
                bestSec = sec
                best = ev
            end if
        end if
    end for
    return best
end function

function ambientSkyTheme() as Object
    hour = nowInfo().hour
    if hour >= 5 and hour < 8 then
        return { phase: "EARLY MORNING", top: "0x182B52FF", middle: "0x8B5367FF", bottom: "0xE89B6FFF", glow: "0xFFD7A3FF" }
    end if
    if hour >= 8 and hour < 11 then
        return { phase: "MID MORNING", top: "0x4D8FC8FF", middle: "0x86C4E8FF", bottom: "0xD7ECF7FF", glow: "0xFFF0A8FF" }
    end if
    if hour >= 11 and hour < 17 then
        return { phase: "DAYTIME", top: "0x2878C7FF", middle: "0x5FB4EAFF", bottom: "0xB9E3F7FF", glow: "0xFFE36BFF" }
    end if
    if hour >= 17 and hour < 20 then
        return { phase: "EVENING", top: "0x26345EFF", middle: "0xA04F67FF", bottom: "0xF2A65AFF", glow: "0xFFD18AFF" }
    end if
    if hour >= 20 and hour < 23 then
        return { phase: "NIGHT TIME", top: "0x111A3EFF", middle: "0x33265EFF", bottom: "0x70436BFF", glow: "0xD8C7FFFF" }
    end if
    return { phase: "LATE NIGHT", top: "0x030713FF", middle: "0x08142AFF", bottom: "0x132445FF", glow: "0x91B7E8FF" }
end function

function mkRotRect(parent as Object, x as Integer, y as Integer, w as Integer, h as Integer, color as String, angle as Float) as Object
    r = mkRect(parent, x, y, w, h, color)
    r.rotation = angle
    return r
end function

sub drawPixelCloud(parent as Object, x as Integer, y as Integer, s as Integer, color as String)
    mkRect(parent, x + (34 * s), y, 72 * s, 30 * s, color)
    mkRect(parent, x + (14 * s), y + (18 * s), 130 * s, 42 * s, color)
    mkRect(parent, x, y + (36 * s), 162 * s, 34 * s, color)
end sub

sub drawAmbientStars(parent as Object, color as String)
    stars = [
        [94, 112], [238, 194], [420, 88], [612, 246], [790, 120], [1040, 198],
        [1224, 82], [1406, 234], [1610, 112], [1790, 282], [310, 374], [1510, 410]
    ]
    for each star in stars
        mkRect(parent, star[0], star[1], 5, 18, color)
        mkRect(parent, star[0] - 6, star[1] + 6, 17, 5, color)
    end for
end sub

function moonPhaseInfo() as Object
    ' Reference new moon: 2000-01-06 18:14 UTC. Mean synodic month: 29.53059 days.
    referenceNewMoon = 947182440
    synodicSeconds = 2551443
    nowSec = CreateObject("roDateTime").AsSeconds()
    ageSeconds = (nowSec - referenceNewMoon) mod synodicSeconds
    if ageSeconds < 0 then ageSeconds = ageSeconds + synodicSeconds
    fraction = ageSeconds / synodicSeconds
    idx = Int((fraction * 8.0) + 0.5) mod 8
    names = ["NEW MOON", "WAXING CRESCENT", "FIRST QUARTER", "WAXING GIBBOUS", "FULL MOON", "WANING GIBBOUS", "LAST QUARTER", "WANING CRESCENT"]
    light = [0, 25, 50, 75, 100, 75, 50, 25]
    ageDays = Int((fraction * 29.53059) + 0.5)
    return { index: idx, name: names[idx], illumination: light[idx], ageDays: ageDays }
end function

sub drawMoonGlyph(parent as Object, x as Integer, y as Integer, s as Integer, phaseIndex as Integer, maskColor as String)
    size = 48 * s
    edge = 3 * s
    mkRect(parent, x, y, size, size, "0xF7EEC8DD")
    mkRect(parent, x + edge, y + edge, size - (edge * 2), size - (edge * 2), "0xFFF8D8EE")
    innerX = x + edge
    innerY = y + edge
    innerSize = size - (edge * 2)
    if phaseIndex = 0 then
        mkRect(parent, innerX, innerY, innerSize, innerSize, maskColor)
    else if phaseIndex = 1 then
        mkRect(parent, innerX, innerY, (innerSize * 3) \ 4, innerSize, maskColor)
    else if phaseIndex = 2 then
        mkRect(parent, innerX, innerY, innerSize \ 2, innerSize, maskColor)
    else if phaseIndex = 3 then
        mkRect(parent, innerX, innerY, innerSize \ 4, innerSize, maskColor)
    else if phaseIndex = 5 then
        mkRect(parent, innerX + ((innerSize * 3) \ 4), innerY, innerSize \ 4, innerSize, maskColor)
    else if phaseIndex = 6 then
        mkRect(parent, innerX + (innerSize \ 2), innerY, innerSize \ 2, innerSize, maskColor)
    else if phaseIndex = 7 then
        mkRect(parent, innerX + (innerSize \ 4), innerY, (innerSize * 3) \ 4, innerSize, maskColor)
    end if
end sub

sub drawMoonPhaseBadge(root as Object, sky as Object)
    phase = moonPhaseInfo()
    mkRect(root, 1340, 238, 500, 48, "0x07102088")
    drawMoonGlyph(root, 1352, 242, 1, phase.index, sky.top)
    mkLabelW(root, phase.name + "  ·  " + phase.illumination.toStr() + "% LIT", 1414, 250, 410, 20, "0xF7EEC8FF", "left")
end sub

sub drawAmbientSun(parent as Object, sky as Object)
    mkRect(parent, 1540, 116, 104, 104, "0xFFD85C99")
    mkRect(parent, 1558, 134, 68, 68, "0xFFF1A8CC")
    mkRect(parent, 1588, 62, 8, 38, sky.glow)
    mkRect(parent, 1588, 236, 8, 38, sky.glow)
    mkRect(parent, 1486, 164, 38, 8, sky.glow)
    mkRect(parent, 1660, 164, 38, 8, sky.glow)
    mkRotRect(parent, 1518, 94, 8, 40, sky.glow, -0.78)
    mkRotRect(parent, 1660, 98, 8, 40, sky.glow, 0.78)
    mkRotRect(parent, 1516, 238, 8, 40, sky.glow, 0.78)
    mkRotRect(parent, 1662, 234, 8, 40, sky.glow, -0.78)
end sub

sub drawAmbientWeatherOverlay(root as Object, sky as Object)
    m.ambientWeatherKind = weatherVisualKind()
    m.ambientWeatherGroup = CreateObject("roSGNode", "Group")
    m.ambientWeatherGroup.opacity = 0.55
    root.appendChild(m.ambientWeatherGroup)
    kind = m.ambientWeatherKind
    if kind = "sun" and (sky.phase = "NIGHT TIME" or sky.phase = "LATE NIGHT") then kind = "clear" : m.ambientWeatherKind = "clear"

    if kind = "sun" then
        drawAmbientSun(m.ambientWeatherGroup, sky)
    else if kind = "clear" then
        if sky.phase = "NIGHT TIME" or sky.phase = "LATE NIGHT" then
            drawAmbientStars(m.ambientWeatherGroup, "0xDDEBFFFF")
            phaseSky = moonPhaseInfo()
            drawMoonGlyph(m.ambientWeatherGroup, 1580, 114, 2, phaseSky.index, sky.top)
        else
            drawAmbientSun(m.ambientWeatherGroup, sky)
        end if
    else if kind = "cloud" then
        drawPixelCloud(m.ambientWeatherGroup, 180, 118, 2, "0xE6EEF399")
        drawPixelCloud(m.ambientWeatherGroup, 1370, 202, 2, "0xC9D8E399")
        drawPixelCloud(m.ambientWeatherGroup, 790, 82, 1, "0xF3F7FA88")
    else if kind = "rain" or kind = "thunder" then
        cloudColor = "0xAEBAC799"
        if kind = "thunder" then cloudColor = "0x667182BB"
        drawPixelCloud(m.ambientWeatherGroup, 110, 82, 2, cloudColor)
        drawPixelCloud(m.ambientWeatherGroup, 1260, 118, 2, cloudColor)
        drawPixelCloud(m.ambientWeatherGroup, 690, 42, 2, cloudColor)
        for i = 0 to 23
            rx = 36 + (i * 82)
            ry = 208 + ((i mod 5) * 96)
            mkRotRect(m.ambientWeatherGroup, rx, ry, 5, 38, "0x8ED8FFAA", -0.20)
        end for
        if kind = "thunder" then
            m.ambientLightningGroup = CreateObject("roSGNode", "Group")
            m.ambientLightningGroup.opacity = 0.35
            root.appendChild(m.ambientLightningGroup)
            mkRotRect(m.ambientLightningGroup, 430, 246, 18, 76, "0xFFE95CFF", 0.38)
            mkRotRect(m.ambientLightningGroup, 454, 304, 18, 82, "0xFFE95CFF", -0.48)
            mkRotRect(m.ambientLightningGroup, 1490, 270, 16, 66, "0xFFF39AFF", 0.38)
            mkRotRect(m.ambientLightningGroup, 1510, 322, 16, 70, "0xFFF39AFF", -0.48)
        end if
    else if kind = "wind" then
        for i = 0 to 10
            wy = 116 + (i * 58)
            wx = 40 + ((i mod 4) * 170)
            ww = 240 + ((i mod 3) * 110)
            mkRect(m.ambientWeatherGroup, wx, wy, ww, 5, "0xD9F3FF88")
            mkRect(m.ambientWeatherGroup, wx + ww - 34, wy - 10, 34, 5, "0xD9F3FF66")
        end for
        drawPixelCloud(m.ambientWeatherGroup, 1390, 116, 2, "0xE6EEF388")
    end if
end sub

sub drawAmbientSeasonalGuests(parent as Object, month as Integer, baseX as Integer)
    if month = 11 then
        guests = CreateObject("roSGNode", "Group")
        guests.translation = [baseX, 710]
        guests.scale = [1.3, 1.3]
        parent.appendChild(guests)
        drawNovemberTurkey(guests, 0, 0)
        drawNovemberPilgrimMan(guests, 175, 0)
        drawNovemberPilgrimWoman(guests, 275, 0)
        mkLabelW(parent, "NOVEMBER GUESTS", baseX, 910, 450, 24, "0xFFE3A0FF", "center")
    else if month = 12 then
        guests = CreateObject("roSGNode", "Group")
        guests.translation = [baseX, 730]
        guests.scale = [1.1, 1.1]
        parent.appendChild(guests)
        drawDecemberSceneContent(guests)
        mkLabelW(parent, "CHRISTMAS PARADE", baseX, 910, 580, 24, "0xFFF0A8FF", "center")
    end if
end sub

function ambientParadeSpan() as Integer
    month = nowInfo().month
    ' Six profiles occupy 2,040px at 340px spacing. Seasonal guests follow Nicky.
    if month = 11 then return 2490
    if month = 12 then return 2620
    return 2040
end function

sub buildAmbient()
    root = m.screenRoot
    theme = monthTheme(nowInfo().month)
    sky = ambientSkyTheme()
    mkRect(root, 0, 0, 1920, 360, sky.top)
    mkRect(root, 0, 360, 1920, 360, sky.middle)
    mkRect(root, 0, 720, 1920, 360, sky.bottom)
    mkRect(root, 0, 330, 1920, 60, "0xFFFFFF0D")
    mkRect(root, 0, 690, 1920, 60, "0xFFFFFF0D")
    drawAmbientSeasonalBackground(root, sky, nowInfo().month)
    mkRect(root, 0, 0, 1920, 10, theme.a)
    mkRect(root, 0, 1070, 1920, 10, theme.b)
    mkLabelW(root, ambientGreeting() + "  ·  " + sky.phase, 80, 54, 1760, 25, "0xEEF5FFFF", "center")
    m.ambientClockLabel = mkLabelW(root, formatHubClock(), 80, 92, 1760, 118, m.C.text, "center")
    m.ambientDateLabel = mkLabelW(root, nowInfo().label, 80, 220, 1760, 32, m.C.gold, "center")
    drawMoonPhaseBadge(root, sky)

    mkRect(root, 80, 300, 820, 260, "0x101830E8")
    mkRect(root, 80, 300, 8, 260, "0x2F6BFFFF")
    mkLabel(root, "UP NEXT", 116, 328, 23, m.C.blue)
    ev = ambientNextEvent()
    if ev = invalid then
        mkLabelW(root, "The calendar is clear", 116, 386, 740, 36, m.C.text, "left")
        mkLabelW(root, "No upcoming event is saved on this Roku.", 116, 446, 740, 24, m.C.dim, "left")
    else
        title = "Untitled event"
        if ev.title <> invalid and ev.title <> "" then title = ev.title
        whenText = "UPCOMING"
        if ev.dayLabel <> invalid and ev.dayLabel <> "" then whenText = ev.dayLabel
        if ev.timeLabel <> invalid and ev.timeLabel <> "" then whenText = whenText + "  ·  " + ev.timeLabel
        mkLabelW(root, title, 116, 382, 740, 38, m.C.text, "left")
        mkLabelW(root, whenText, 116, 464, 740, 25, m.C.gold, "left")
    end if

    mkRect(root, 940, 300, 900, 260, "0x101830E8")
    mkRect(root, 1832, 300, 8, 260, "0xB96BFFFF")
    mkLabel(root, "HOUSE STATUS", 976, 328, 23, "0xDCA0FFFF")
    leader = "Everyone starts together"
    bestPoints = -1
    for each pk in profileKeys()
        pts = weekPts(pk)
        if pts > bestPoints then
            bestPoints = pts
            leader = personName(pk) + " leads this week with " + pts.toStr() + " points"
        end if
    end for
    mkLabelW(root, leader, 976, 386, 820, 34, m.C.text, "left")
    mkLabelW(root, "House bucket: " + m.state.points.house.toStr() + "  ·  Calendar " + calendarSyncLabel(), 976, 454, 820, 23, m.C.dim, "left")
    startWeatherSync(false)
    mkLabelW(root, weatherSummary(), 976, 500, 820, 22, theme.a, "left")

    ambientAlert = weatherAlertText()
    if ambientAlert <> "" then
        mkRect(root, 340, 580, 1240, 42, "0x6B1C2BFF")
        mkLabelW(root, "WEATHER ALERT · " + ambientAlert, 360, 590, 1200, 21, "0xFFE0A3FF", "center")
    end if

    m.ambientAvatarGroup = CreateObject("roSGNode", "Group")
    m.ambientAvatarGroup.translation = [m.ambientScrollX, 0]
    root.appendChild(m.ambientAvatarGroup)
    people = profileKeys()
    paradeSpan = ambientParadeSpan()
    for parade = 0 to 1
        for i = 0 to people.count() - 1
            pk = people[i]
            x = 160 + (i * 340) + (parade * paradeSpan)
            if m.state.avatar <> invalid and m.state.avatar[pk] <> invalid then drawAvatar(m.ambientAvatarGroup, x, 626, 1, m.state.avatar[pk], "full")
            mkLabelW(m.ambientAvatarGroup, personName(pk), x - 40, 928, 180, 24, m.C.text, "center")
        end for
        drawAmbientSeasonalGuests(m.ambientAvatarGroup, nowInfo().month, 2100 + (parade * paradeSpan))
    end for
    mkLabelW(root, theme.name + "  ·  Press any button to return", 80, 1014, 1760, 20, theme.b, "center")
end sub

' ---------- focus and items ----------

function addItem(parent as Object, kind as String, id as String, col as Integer, row as Integer, x as Integer, y as Integer, w as Integer, h as Integer, bgColor as String) as Object
    g = CreateObject("roSGNode", "Group")
    g.translation = [x, y]
    parent.appendChild(g)
    border = mkRect(g, -4, -4, w + 8, h + 8, m.C.border)
    border.opacity = 0
    bg = mkRect(g, 0, 0, w, h, bgColor)
    item = { kind: kind, id: id, col: col, row: row, node: g, border: border, bg: bg, w: w, h: h }
    m.items.push(item)
    return item
end function

sub updateHighlight()
    for i = 0 to m.items.count() - 1
        if m.area = "content" and i = m.focusIdx then
            m.items[i].border.opacity = 1
        else
            m.items[i].border.opacity = 0
        end if
    end for
end sub

function moveFocus(dc as Integer, dr as Integer) as Boolean
    if m.items.count() = 0 then return false
    cur = m.items[m.focusIdx]
    best = -1
    bestScore = 9999
    for i = 0 to m.items.count() - 1
        it = m.items[i]
        if dc <> 0 and it.col = cur.col + dc then
            score = abs(it.row - cur.row) * 10
            if dr = 0 and it.row = cur.row then score = 0
            if score < bestScore then bestScore = score : best = i
        end if
        if dr <> 0 and it.row = cur.row + dr and it.col = cur.col then
            best = i
            bestScore = -1
        end if
    end for
    if best < 0 and dr <> 0 then
        ' allow column drift when moving vertically
        for i = 0 to m.items.count() - 1
            it = m.items[i]
            if it.row = cur.row + dr then
                score = abs(it.col - cur.col)
                if score < bestScore then bestScore = score : best = i
            end if
        end for
    end if
    if best >= 0 then
        m.focusIdx = best
        updateHighlight()
        return true
    end if
    return false
end function

' ---------- weekly race ----------

function weekPts(p as String) as Integer
    w = m.state.week
    if w = invalid or w.points = invalid then return 0
    v = w.points[p]
    if v = invalid then return 0
    return v
end function

sub ensureWeek()
    ni = nowInfo()
    offset = (ni.dow + 1) mod 7
    key = (ni.days - offset).toStr()
    w = m.state.week
    if w = invalid then
        m.state.week = { key: key, points: { emily: 0, max: 0, anthony: 0, parents: 0, nicky: 0 }, lastWinner: invalid }
        return
    end if
    if w.key <> key then
        best = 0
        winners = []
        for each p in m.players
            wp = weekPts(p)
            if wp > best then
                best = wp
                winners = [p]
            else if wp = best and best > 0 then
                winners.push(p)
            end if
        end for
        if best > 0 then
            names = ""
            for i = 0 to winners.count() - 1
                if i > 0 then names = names + " + "
                names = names + personName(winners[i])
            end for
            w.lastWinner = { text: names, pts: best }
        end if
        w.key = key
        w.points = { emily: 0, max: 0, anthony: 0, parents: 0, nicky: 0 }
        m.state.week = w
        saveState()
    end if
end sub

' ---------- points, counts, streaks ----------

function todayChecks() as Object
    ni = nowInfo()
    c = m.state.checks[ni.dateKey]
    if c = invalid then c = {}
    return c
end function

function isChecked(id as String) as Boolean
    c = todayChecks()
    return c.doesExist(id)
end function

function todayReminded() as Object
    ni = nowInfo()
    if m.state.reminded = invalid then m.state.reminded = {}
    r = m.state.reminded[ni.dateKey]
    if r = invalid then r = {}
    return r
end function

function isReminded(id as String) as Boolean
    r = todayReminded()
    return r.doesExist(id)
end function

sub toggleReminded(item as Object)
    if isChecked(item.id) then return
    ni = nowInfo()
    r = todayReminded()
    if r.doesExist(item.id) then
        r.delete(item.id)
    else
        r[item.id] = true
    end if
    m.state.reminded[ni.dateKey] = r
    saveState()
    rebuildScreen()
end sub

sub bumpCounts(player as String, cat as String, early as Boolean, delta as Integer, noAsk as Boolean)
    pc = m.state.counts[player]
    if pc = invalid then pc = { total: 0, early: 0, noask: 0, laundry: 0, dinner: 0, trash: 0, zones: 0 }
    if not pc.doesExist("noask") then pc.noask = 0
    pc.total = pc.total + delta
    if early and delta > 0 then pc.early = pc.early + 1
    if early and delta < 0 then pc.early = pc.early - 1
    if noAsk and delta > 0 then pc.noask = pc.noask + 1
    if noAsk and delta < 0 then pc.noask = pc.noask - 1
    if pc.doesExist(cat) then pc[cat] = pc[cat] + delta
    m.state.counts[player] = pc
end sub

sub bumpStreak(player as String)
    ni = nowInfo()
    s = m.state.streaks[player]
    if s = invalid then s = { count: 0, last: -1 }
    if s.last = ni.days then return
    if s.last = ni.days - 1 then
        s.count = s.count + 1
    else
        s.count = 1
    end if
    s.last = ni.days
    m.state.streaks[player] = s
end sub

sub award(owner as String, pts as Integer, cat as String, early as Boolean, noAsk as Boolean)
    if owner = "everyone" or owner = "crew" or owner = "house" then
        m.state.points.house = m.state.points.house + pts
        return
    end if
    if left(owner, 5) = "pair:" then
        parts = owner.split(",")
        a = parts[0].mid(5)
        b = parts[1]
        m.state.points[a] = m.state.points[a] + pts
        m.state.points[b] = m.state.points[b] + pts
        m.state.week.points[a] = m.state.week.points[a] + pts
        m.state.week.points[b] = m.state.week.points[b] + pts
        bumpCounts(a, cat, early, 1, noAsk)
        bumpCounts(b, cat, early, 1, noAsk)
        bumpStreak(a)
        bumpStreak(b)
        return
    end if
    pk = owner
    if pk = "patricia" or pk = "nick" then pk = "parents"
    m.state.points[pk] = m.state.points[pk] + pts
    m.state.week.points[pk] = m.state.week.points[pk] + pts
    bumpCounts(pk, cat, early, 1, noAsk)
    bumpStreak(pk)
end sub

sub unaward(owner as String, pts as Integer, cat as String, early as Boolean, noAsk as Boolean)
    if owner = "everyone" or owner = "crew" or owner = "house" then
        m.state.points.house = m.state.points.house - pts
        return
    end if
    if left(owner, 5) = "pair:" then
        parts = owner.split(",")
        a = parts[0].mid(5)
        b = parts[1]
        m.state.points[a] = m.state.points[a] - pts
        m.state.points[b] = m.state.points[b] - pts
        wa = m.state.week.points[a] - pts
        if wa < 0 then wa = 0
        m.state.week.points[a] = wa
        wb = m.state.week.points[b] - pts
        if wb < 0 then wb = 0
        m.state.week.points[b] = wb
        bumpCounts(a, cat, early, -1, noAsk)
        bumpCounts(b, cat, early, -1, noAsk)
        return
    end if
    pk = owner
    if pk = "patricia" or pk = "nick" then pk = "parents"
    m.state.points[pk] = m.state.points[pk] - pts
    wp = m.state.week.points[pk] - pts
    if wp < 0 then wp = 0
    m.state.week.points[pk] = wp
    bumpCounts(pk, cat, early, -1, noAsk)
end sub

sub toggleChore(item as Object)
    ensureWeek()
    ni = nowInfo()
    checks = todayChecks()
    id = item.id
    if checks.doesExist(id) then
        rec = checks[id]
        oldNoAsk = false
        if rec.doesExist("noAsk") then oldNoAsk = rec.noAsk
        unaward(rec.owner, rec.pts, rec.cat, rec.early, oldNoAsk)
        oldCb = 0
        if rec.doesExist("cb") then oldCb = rec.cb
        if oldCb <> 0 then payCb(rec.owner, -oldCb)
        checks.delete(id)
    else
        early = ni.hour < item.blockStart
        reminded = isReminded(id)
        noAsk = not reminded
        pts = 2
        bonus = 0
        if noAsk then bonus = 1
        pts = pts + bonus
        award(item.owner, pts, item.cat, early, noAsk)
        cents = cbRate(reminded)
        payCb(item.owner, cents)
        checks[id] = { owner: item.owner, pts: pts, cat: item.cat, early: early, noAsk: noAsk, reminded: reminded, bonus: bonus, cb: cents }
        cbToast(item.owner, cents)
    end if
    m.state.checks[ni.dateKey] = checks
    saveState()
    rebuildScreen()
end sub

sub cycleOwner(item as Object, dir as Integer)
    order = ["house", "emily", "max", "anthony", "patricia", "nick", "nicky"]
    base = item.baseOwner
    if base = invalid then base = item.owner
    if base = "everyone" or base = "crew" or left(base, 5) = "pair:" then
        ord2 = [base]
        for each o in order
            ord2.push(o)
        end for
        order = ord2
    end if
    cur = item.owner
    idx = 0
    for i = 0 to order.count() - 1
        if order[i] = cur then idx = i
    end for
    nxt = order[(idx + dir + order.count()) mod order.count()]
    m.state.reassign[item.id] = nxt
    saveState()
    rebuildScreen()
end sub

' ---------- timers ----------

sub onTick()
    ni = nowInfo()
    phaseNow = todayEffectivePhase()
    if m.lastTodayPhase = "" then
        m.lastTodayPhase = phaseNow
    else if m.screen = "hub" and m.state.todayMode = "auto" and phaseNow <> m.lastTodayPhase then
        m.lastTodayPhase = phaseNow
        rebuildScreen()
    end if
    if m.screen = "hub" and m.hubClockLabel <> invalid then
        m.hubClockLabel.text = formatHubClock()
        startTickerSync(false)
    end if
    if m.screen = "ambient" then
        if m.ambientClockLabel <> invalid then m.ambientClockLabel.text = formatHubClock()
        if m.ambientDateLabel <> invalid then m.ambientDateLabel.text = ni.label
        m.ambientPulse = (m.ambientPulse + 1) mod 4
        if m.ambientAvatarGroup <> invalid then
            bob = 0
            if m.ambientPulse = 1 or m.ambientPulse = 2 then bob = -3
            m.ambientScrollX = m.ambientScrollX - 5.0
            if m.ambientScrollX <= -ambientParadeSpan() then m.ambientScrollX = 0
            m.ambientAvatarGroup.translation = [m.ambientScrollX, bob]
        end if
        animateAmbientSeason()
        if m.ambientMinute <> ni.minute then
            if m.ambientMinute >= 0 then rebuildScreen()
            m.ambientMinute = ni.minute
        end if
    end if
    if m.toastT > 0 then
        m.toastT = m.toastT - 1
        if m.toastT = 0 then m.toast.visible = false
    end if
    if m.admin then
        dtN = CreateObject("roDateTime")
        if dtN.AsSeconds() - m.lastKeySec > 300 then
            m.admin = false
            if m.screen = "admin" or m.screen = "pin" then
                showScreen("hub")
            else
                buildMenu()
            end if
        end if
    end if
    if m.screen <> "ambient" then
        idleNow = CreateObject("roDateTime")
        if idleNow.AsSeconds() - m.lastKeySec >= 300 then enterAmbient()
    end if
    if m.lastDateKey <> "" and m.lastDateKey <> ni.dateKey then
        ensureWeek()
        rebuildScreen()
    end if
    m.lastDateKey = ni.dateKey
    changed = false
    for each k in m.timers
        t = m.timers[k]
        if t.running then
            t.left = t.left - 1
            changed = true
            if t.left <= 0 then
                t.left = 0
                t.running = false
                m.alarm.control = "play"
                m.flashT = 8
                if k = "family" then m.state.points.house = m.state.points.house + 5
                if k = "zone" then m.state.points.house = m.state.points.house + 2
                saveState()
            end if
            m.timers[k] = t
        end if
    end for
    if m.flashT > 0 then
        m.flashT = m.flashT - 1
        if m.flashT mod 2 = 0 then
            m.flash.opacity = 0.22
        else
            m.flash.opacity = 0
        end if
        if m.flashT = 0 then m.flash.opacity = 0
    end if
    for each k in m.timerLabels
        lbl = m.timerLabels[k]
        if lbl <> invalid then lbl.text = fmtTime(m.timers[k].left)
    end for
    if changed then refreshTimerStates()
end sub

sub refreshTimerStates()
    for each k in m.timerLabels
        st = m.timerStates[k]
        if st <> invalid then
            if m.timers[k].running then
                st.text = "RUNNING · OK pause · * reset"
            else if m.timers[k].left = 0 then
                st.text = "DONE! · OK or * resets"
            else if m.timers[k].left < m.timers[k].total then
                st.text = "PAUSED · OK resume · * reset"
            else
                st.text = "OK starts · * resets"
            end if
        end if
    end for
end sub

sub toggleTimer(kind as String)
    t = m.timers[kind]
    if t.left <= 0 then
        t.left = t.total
        t.running = false
    else
        t.running = not t.running
    end if
    m.timers[kind] = t
    refreshTimerStates()
end sub

sub resetTimer(kind as String)
    t = m.timers[kind]
    t.left = t.total
    t.running = false
    m.timers[kind] = t
    if m.alarm <> invalid then m.alarm.control = "stop"
    lbl = m.timerLabels[kind]
    if lbl <> invalid then lbl.text = fmtTime(t.left)
    refreshTimerStates()
end sub

' ---------- admin and PIN ----------

sub showToast(msg as String)
    m.toastLabel.text = msg
    m.toast.visible = true
    m.toastT = 3
end sub

sub denyEdit()
    if m.activeKey <> invalid and m.activeKey <> "" then
        beginAdminShortcut(m.activeKey)
    else
        showToast("This change needs the Admin PIN")
    end if
end sub

sub beginAdminShortcut(key as String)
    allowed = key = "OK" or key = "options" or key = "rewind" or key = "fastforward" or key = "replay" or key = "play" or key = "pause"
    if not allowed then
        showToast("This change needs the Admin PIN")
        return
    end if
    m.adminShortcutKey = key
    m.adminShortcutScreen = m.screen
    m.adminShortcutArea = m.area
    m.adminShortcutFocus = m.focusIdx
    m.adminShortcutDestination = "action"
    if m.state.pin = "" then m.pinPurpose = "shortcutcreate" else m.pinPurpose = "shortcut"
    m.pinStage = 0
    m.pinBuf = ""
    m.pinFirst = ""
    m.pinMsg = ""
    m.focusIdx = 0
    showScreen("pin")
end sub

sub restoreAdminShortcut()
    destination = m.adminShortcutScreen
    if destination = invalid or destination = "" or destination = "pin" or destination = "ambient" then destination = "hub"
    returnArea = m.adminShortcutArea
    returnFocus = m.adminShortcutFocus
    m.pinBuf = ""
    m.pinFirst = ""
    m.pinStage = 0
    m.pinMsg = ""
    m.pinPurpose = ""
    showScreen(destination)
    m.area = returnArea
    m.focusIdx = returnFocus
    if m.focusIdx < 0 then m.focusIdx = 0
    if m.focusIdx >= m.items.count() then m.focusIdx = m.items.count() - 1
    if m.focusIdx < 0 then m.focusIdx = 0
    updateHighlight()
end sub

sub cancelAdminShortcut()
    restoreAdminShortcut()
    m.adminShortcutKey = ""
    m.adminShortcutDestination = "action"
    showToast("Admin action cancelled")
end sub

sub runAdminShortcut()
    replayKey = m.adminShortcutKey
    restoreAdminShortcut()
    m.adminShortcutKey = ""
    if replayKey = invalid or replayKey = "" then return
    m.oneShotAdmin = true
    m.admin = true
    onKeyEvent(replayKey, true)
    m.admin = false
    m.oneShotAdmin = false
    rebuildScreen()
end sub

sub changeToAdminFromShortcut()
    m.admin = true
    restoreAdminShortcut()
    m.adminShortcutKey = ""
    m.adminShortcutDestination = "action"
    showToast("Admin mode — returned to your selection")
end sub

sub openPin()
    if m.state.pin = "" then m.pinPurpose = "create" else m.pinPurpose = "unlock"
    m.pinStage = 0
    m.pinBuf = ""
    m.pinFirst = ""
    m.pinMsg = ""
    m.focusIdx = 0
    showScreen("pin")
end sub

sub beginShopSpend()
    if m.pendingBuy = invalid or m.pendingBuy = "" then
        showScreen("shop")
        return
    end if
    m.pinWho = m.who
    if shopPinFor(m.pinWho) = "" then m.pinPurpose = "shopcreate" else m.pinPurpose = "shoppay"
    m.pinStage = 0
    m.pinBuf = ""
    m.pinFirst = ""
    m.pinMsg = ""
    m.focusIdx = 0
    showScreen("pin")
end sub

sub beginShopPinReset(profileKey as String)
    if not m.admin then
        denyEdit()
        return
    end if
    m.pinWho = profileKey
    m.pinReturn = "pinpick"
    m.pinPurpose = "shopchange"
    m.pinStage = 0
    m.pinBuf = ""
    m.pinFirst = ""
    m.pinMsg = ""
    m.focusIdx = 0
    showScreen("pin")
end sub

sub pinDigit(d as String)
    if m.pinPurpose = "sethouse" then
        if m.pinBuf.len() >= 3 then return
        m.pinBuf = m.pinBuf + d
        rebuildScreen()
        return
    end if
    if m.pinBuf.len() >= 4 then return
    m.pinBuf = m.pinBuf + d
    if m.pinPurpose = "shortcut" or m.pinPurpose = "shortcutcreate" then
        rebuildScreen()
        return
    end if
    if m.pinBuf.len() = 4 then
        pinSubmit()
    else
        rebuildScreen()
    end if
end sub

sub submitHouse()
    if m.pinBuf = "" then return
    v = m.pinBuf.toInt()
    m.state.points.house = v
    saveState()
    m.pinBuf = ""
    showToast("House points set to " + v.toStr())
    showScreen("admin")
end sub

sub pinSubmit()
    if m.pinPurpose = "shortcut" then
        if m.pinBuf.len() <> 4 then
            m.pinMsg = "Enter all four digits, then choose OK"
            rebuildScreen()
        else if m.pinBuf = m.state.pin then
            if m.adminShortcutDestination = "session" then changeToAdminFromShortcut() else runAdminShortcut()
        else
            m.pinMsg = "Wrong PIN — try again or choose Cancel"
            m.pinBuf = ""
            rebuildScreen()
        end if
        return
    end if
    if m.pinPurpose = "shortcutcreate" then
        if m.pinBuf.len() <> 4 then
            m.pinMsg = "Enter all four digits, then choose OK"
            rebuildScreen()
            return
        end if
        if m.pinStage = 0 then
            m.pinFirst = m.pinBuf
            m.pinBuf = ""
            m.pinStage = 1
            m.pinMsg = ""
            rebuildScreen()
        else if m.pinBuf = m.pinFirst then
            m.state.pin = m.pinBuf
            saveState()
            if m.adminShortcutDestination = "session" then changeToAdminFromShortcut() else runAdminShortcut()
        else
            m.pinMsg = "Those did not match — start over"
            m.pinBuf = ""
            m.pinFirst = ""
            m.pinStage = 0
            rebuildScreen()
        end if
        return
    end if
    if m.pinPurpose = "unlock" then
        if m.pinBuf = m.state.pin then
            m.admin = true
            m.pinBuf = ""
            showToast("Admin mode — changes are open")
            showScreen("admin")
        else
            m.pinMsg = "Wrong PIN — try again"
            m.pinBuf = ""
            rebuildScreen()
        end if
        return
    end if
    if m.pinPurpose = "shoppay" then
        if m.pinBuf = shopPinFor(m.pinWho) then
            m.pinBuf = ""
            completePendingPurchase()
        else
            m.pinMsg = "Wrong spending PIN - no C-Bucks were charged"
            m.pinBuf = ""
            rebuildScreen()
        end if
        return
    end if
    if m.pinPurpose = "shopcreate" or m.pinPurpose = "shopchange" then
        if m.pinStage = 0 then
            m.pinFirst = m.pinBuf
            m.pinBuf = ""
            m.pinStage = 1
            m.pinMsg = ""
            rebuildScreen()
            return
        end if
        if m.pinBuf = m.pinFirst then
            m.state.shopPins[m.pinWho] = m.pinBuf
            saveState()
            m.pinBuf = ""
            m.pinStage = 0
            if m.pinPurpose = "shopcreate" then
                completePendingPurchase()
            else
                showToast(personName(m.pinWho) + "'s spending PIN updated")
                showScreen(m.pinReturn)
            end if
        else
            m.pinMsg = "Those did not match - start over"
            m.pinBuf = ""
            m.pinFirst = ""
            m.pinStage = 0
            rebuildScreen()
        end if
        return
    end if
    if m.pinStage = 0 then
        m.pinFirst = m.pinBuf
        m.pinBuf = ""
        m.pinStage = 1
        m.pinMsg = ""
        rebuildScreen()
        return
    end if
    if m.pinBuf = m.pinFirst then
        m.state.pin = m.pinBuf
        saveState()
        m.admin = true
        m.pinBuf = ""
        m.pinStage = 0
        if m.pinPurpose = "change" then
            showToast("PIN changed — you are admin")
            showScreen("admin")
        else
            showToast("PIN set — you are admin")
            showScreen("admin")
        end if
    else
        m.pinMsg = "Those did not match — start over"
        m.pinBuf = ""
        m.pinFirst = ""
        m.pinStage = 0
        rebuildScreen()
    end if
end sub

sub pinBack()
    if m.pinBuf.len() > 0 then
        m.pinBuf = m.pinBuf.left(m.pinBuf.len() - 1)
        rebuildScreen()
    else if m.pinPurpose = "sethouse" then
        showScreen("admin")
    else if m.pinPurpose = "shopchange" then
        showScreen(m.pinReturn)
    else if m.pinPurpose = "shopcreate" or m.pinPurpose = "shoppay" then
        showScreen("confirmbuy")
    else if m.pinPurpose = "shortcut" or m.pinPurpose = "shortcutcreate" then
        cancelAdminShortcut()
    else
        showScreen("hub")
    end if
end sub

sub doAction(id as String)
    if id = "pinok" then
        pinSubmit()
    else if id = "pincancel" then
        cancelAdminShortcut()
    else if id = "pinmakeadmin" then
        m.adminShortcutDestination = "session"
        pinSubmit()
    else if id = "lock" then
        m.admin = false
        showToast("Locked — viewer mode")
        showScreen("hub")
    else if id = "changepin" then
        m.pinPurpose = "change"
        m.pinStage = 0
        m.pinBuf = ""
        m.pinFirst = ""
        m.pinMsg = ""
        m.focusIdx = 0
        showScreen("pin")
    else if id = "sethouse" then
        m.pinPurpose = "sethouse"
        m.pinStage = 0
        m.pinBuf = ""
        m.pinFirst = ""
        m.pinMsg = ""
        m.focusIdx = 0
        showScreen("pin")
    else if id = "musicmode" then
        toggleMusic()
        rebuildScreen()
    else if id = "diagnostics" then
        showScreen("diagnostics")
    else if id = "ambientpreview" then
        m.ambientOrigin = "hub"
        m.admin = false
        m.ambientMinute = -1
        m.ambientScrollX = 0
        m.ambientWeatherOffset = 0
        m.ambientSeasonOffset = 0
        showScreen("ambient")
    else if id = "ambientnow" then
        enterAmbient()
    else if id = "todaymode" then
        cycleTodayMode()
    else if id = "weatherrefresh" then
        startWeatherSync(true)
        showToast("Weather update requested")
    else if id = "newsticker" then
        m.state.tickers.newsEnabled = not m.state.tickers.newsEnabled
        if m.state.tickers.newsEnabled then m.state.tickers.lastSync = 0
        saveState()
        showToast("Today news ticker " + tickerToggleWord(m.state.tickers.newsEnabled))
        rebuildScreen()
    else if id = "sportsticker" then
        m.state.tickers.sportsEnabled = not m.state.tickers.sportsEnabled
        if m.state.tickers.sportsEnabled then m.state.tickers.lastSync = 0
        saveState()
        showToast("Today sports ticker " + tickerToggleWord(m.state.tickers.sportsEnabled))
        rebuildScreen()
    else if id = "familyedit" then
        showScreen("family")
    else if id = "mealplanner" then
        m.mealPlanDay = nowInfo().dow
        showScreen("mealplanner")
    else if id = "avshoppin" then
        if not m.admin then
            denyEdit()
            return
        end if
        m.pinWho = m.who
        m.pinReturn = "avatar"
        m.pinPurpose = "shopchange"
        m.pinStage = 0
        m.pinBuf = ""
        m.pinFirst = ""
        m.pinMsg = ""
        m.focusIdx = 0
        showScreen("pin")
    else if id = "pinpick" then
        showScreen("pinpick")
    else if id = "today" then
        showScreen("hub")
    else if id = "levels" then
        showScreen("levels")
    else if id = "goshop" then
        m.focusIdx = 0
        showScreen("shop")
    else if id = "avinventory" then
        m.inventoryPage = 0
        m.focusIdx = 0
        showScreen("inventory")
    else if id = "avatarback" then
        m.focusIdx = 0
        showScreen("avatar")
    else if id = "calrefresh" then
        startCalendarSync(true)
    else if id = "caldays3" then
        setCalendarView(3)
    else if id = "caldays7" then
        setCalendarView(7)
    else if id = "caldays30" then
        setCalendarView(30)
    else if id = "calprev" then
        changeCalendarPage(-1)
    else if id = "calnext" then
        changeCalendarPage(1)
    else if id = "buyyes" then
        beginShopSpend()
    else if id = "buyno" then
        m.pendingBuy = ""
        showScreen("shop")
    else if id = "podiumsrc" then
        if m.state.podiumAvatar = "built" then
            m.state.podiumAvatar = "preset"
            saveState()
            showToast("Podium shows the preset pictures")
        else
            m.state.podiumAvatar = "built"
            saveState()
            showToast("Podium shows your built looks")
        end if
        showScreen("avatar")
    end if
end sub

sub buildLevels()
    root = m.screenRoot
    mkLabel(root, "THE LEVELS", 56, 84, 44, m.C.text)
    mkLabelW(root, "Levels come from your season points, the big number on your Game row. They never reset. The weekly race resets every Saturday; levels do not.", 56, 140, 1750, 26, m.C.dim, "left")
    defs = [
        { name: "Getting Going", at: "STARTS AT 0 POINTS", mean: "Where everyone starts. Your first checks put you on the board." },
        { name: "In the Flow", at: "STARTS AT 15 POINTS", mean: "Helping out is becoming a habit, not a one-time thing." },
        { name: "On Fire", at: "STARTS AT 30 POINTS", mean: "A real streak of showing up. The house runs better because of you." },
        { name: "House Captain", at: "STARTS AT 50 POINTS", mean: "You lead by example, and the younger kids copy what you do." },
        { name: "Legend of the House", at: "STARTS AT 80 POINTS", mean: "The top level. This is the name the house tells stories about." }
    ]
    for i = 0 to 4
        y = 210 + i * 148
        mkRect(root, 56, y, 1808, 132, m.C.panel)
        mkLabel(root, defs[i].name, 84, y + 16, 34, m.C.text)
        mkLabelW(root, defs[i].at, 900, y + 24, 936, 24, m.C.gold, "right")
        mkLabelW(root, defs[i].mean, 84, y + 78, 1750, 26, m.C.dim, "left")
    end for
    mkLabelW(root, "Back returns to the Game page.", 56, 972, 1000, 24, m.C.dim, "left")
end sub

sub buildPin()
    root = m.screenRoot
    title = "ENTER ADMIN PIN"
    if m.pinPurpose = "create" then
        if m.pinStage = 0 then title = "CREATE YOUR ADMIN PIN" else title = "CONFIRM THE PIN"
    else if m.pinPurpose = "change" then
        if m.pinStage = 0 then title = "ENTER A NEW PIN" else title = "CONFIRM THE NEW PIN"
    else if m.pinPurpose = "shopcreate" then
        if m.pinStage = 0 then title = "CREATE " + UCase(personName(m.pinWho)) + "'S SPENDING PIN" else title = "CONFIRM THE SPENDING PIN"
    else if m.pinPurpose = "shopchange" then
        if m.pinStage = 0 then title = "NEW SPENDING PIN FOR " + UCase(personName(m.pinWho)) else title = "CONFIRM THE SPENDING PIN"
    else if m.pinPurpose = "shoppay" then
        title = "ENTER " + UCase(personName(m.pinWho)) + "'S SPENDING PIN"
    else if m.pinPurpose = "shortcut" then
        title = "ADMIN APPROVAL NEEDED"
    else if m.pinPurpose = "shortcutcreate" then
        if m.pinStage = 0 then title = "CREATE AN ADMIN PIN" else title = "CONFIRM THE ADMIN PIN"
    end if
    if m.pinPurpose = "sethouse" then title = "SET HOUSE POINTS"
    mkLabelW(root, title, 560, 130, 800, 44, m.C.text, "center")
    if m.pinPurpose = "sethouse" then
        mkLabelW(root, "Type the number the house bucket should hold, then press SET. It is " + m.state.points.house.toStr() + " now.", 460, 196, 1000, 25, m.C.dim, "center")
        shown = m.pinBuf
        if shown = "" then shown = "—"
        mkLabelW(root, shown, 760, 246, 400, 60, m.C.gold, "center")
    else
        pinHelp = "Four digits. Only an admin can check chores or run timers. Chore names can be reassigned in viewer mode."
        if m.pinPurpose = "shopcreate" then pinHelp = "Choose four digits for " + personName(m.pinWho) + "'s purchases only. This purchase continues after you confirm it."
        if m.pinPurpose = "shopchange" then pinHelp = "Choose a new four-digit spending PIN for " + personName(m.pinWho) + ". Only " + personName(m.pinWho) + "'s purchases will ask for it."
        if m.pinPurpose = "shoppay" then pinHelp = "This purchase is for " + personName(m.pinWho) + ", so it needs " + personName(m.pinWho) + "'s PIN. Nothing is charged until it is correct."
        if m.pinPurpose = "shortcut" then pinHelp = "Enter the Admin PIN, then choose OK. This approves only the selected action."
        if m.pinPurpose = "shortcutcreate" then pinHelp = "Choose four digits, then choose OK. This PIN approves only the selected action right now."
        mkLabelW(root, pinHelp, 460, 196, 1000, 25, m.C.dim, "center")
        for i = 0 to 3
            c = "0x0B1020FF"
            if m.pinBuf.len() > i then c = m.C.gold
            mkRect(root, 836 + i * 64, 262, 44, 44, c)
        end for
    end if
    if m.pinMsg <> "" then mkLabelW(root, m.pinMsg, 460, 330, 1000, 26, "0xFF7777FF", "center")
    digits = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    for i = 0 to 9
        col = i mod 5
        row = i \ 5
        item = addItem(root, "digit", "d" + digits[i], col, row, 560 + col * 160, 400 + row * 160, 128, 128, m.C.panel)
        item.digit = digits[i]
        l = mkLabel(item.node, digits[i], 0, 34, 54, m.C.text)
        l.width = 128
        l.horizAlign = "center"
    end for
    if m.pinPurpose = "sethouse" then
        sitem = addItem(root, "setgo", "setgo", 0, 2, 560, 736, 800, 84, m.C.panel)
        sl = mkLabel(sitem.node, "SET THE NUMBER", 0, 24, 32, m.C.gold)
        sl.width = 800
        sl.horizAlign = "center"
        mkLabelW(root, "OK enters a digit · Back deletes", 460, 852, 1000, 24, m.C.dim, "center")
    else if m.pinPurpose = "shortcut" or m.pinPurpose = "shortcutcreate" then
        okItem = addItem(root, "action", "pinok", 0, 2, 430, 736, 320, 84, m.C.accent)
        mkLabelW(okItem.node, "OK", 0, 24, 320, 30, m.C.text, "center")
        adminItem = addItem(root, "action", "pinmakeadmin", 2, 2, 800, 736, 320, 84, "0x2E6A4BFF")
        mkLabelW(adminItem.node, "CHANGE TO ADMIN", 8, 25, 304, 25, m.C.text, "center")
        cancelItem = addItem(root, "action", "pincancel", 4, 2, 1170, 736, 320, 84, m.C.panel)
        mkLabelW(cancelItem.node, "CANCEL", 0, 24, 320, 30, m.C.text, "center")
        mkLabelW(root, "OK enters digits · Back deletes · choose an action when ready", 460, 852, 1000, 24, m.C.dim, "center")
    else
        mkLabelW(root, "OK enters a digit · Back deletes · the pad submits itself at four digits", 460, 760, 1000, 24, m.C.dim, "center")
    end if
end sub

sub buildAdmin()
    root = m.screenRoot
    mkLabel(root, "ADMIN", 56, 84, 44, m.C.text)
    mkLabel(root, "You are signed in as admin. Changes are open. The app locks itself after 5 quiet minutes, or lock it now.", 56, 140, 26, m.C.dim)
    musicName = musicModeName(m.state.musicMode)
    rows = [
        { id: "lock", text: "Lock now — back to viewer" },
        { id: "changepin", text: "Change the PIN" },
        { id: "pinpick", text: "Reset a spending PIN" },
        { id: "sethouse", text: "Set house points — now " + m.state.points.house.toStr() },
        { id: "musicmode", text: "Music — " + musicName },
        { id: "weatherrefresh", text: "Refresh weather for ZIP 33417" },
        { id: "familyedit", text: "Edit meals and family messages" },
        { id: "ambientpreview", text: "Preview five-minute Ambient Mode" },
        { id: "diagnostics", text: "System health and diagnostics" },
        { id: "today", text: "Back to Today" }
    ]
    for i = 0 to rows.count() - 1
        item = addItem(root, "action", rows[i].id, 0, i, 56, 230 + i * 76, 760, 62, m.C.panel)
        mkLabel(item.node, rows[i].text, 32, 18, 28, m.C.text)
    end for
    mkLabel(root, "BONUS REWARDS   OK ADDS   * REMOVES", 880, 214, 24, m.C.yellow)
    wk = profileKeys()
    for i = 0 to wk.count() - 1
        rewardY = 260 + i * 92
        mkRect(root, 880, rewardY, 310, 76, m.C.panel)
        mkLabel(root, personName(wk[i]), 904, rewardY + 12, 28, m.C.text)
        pointOwner = personName(wk[i])
        if wk[i] = "patricia" or wk[i] = "nick" then pointOwner = "PARENTS"
        mkLabelW(root, pointOwner + " · " + bonusPointTotal(wk[i]).toStr() + " PTS", 904, rewardY + 46, 262, 17, m.C.dim, "left")
        w = addItem(root, "wallet", wk[i], 1, i, 1204, rewardY, 310, 76, "0x182343FF")
        mkLabelW(w.node, "+ C$5", 18, 10, 274, 25, m.C.gold, "center")
        mkLabelW(w.node, fmtCb(m.state.cb[wk[i]]), 18, 42, 274, 20, m.C.dim, "center")
        p = addItem(root, "bonuspoint", wk[i], 2, i, 1528, rewardY, 336, 76, "0x182343FF")
        mkLabelW(p.node, "+ 1 POINT", 18, 10, 300, 25, m.C.green, "center")
        mkLabelW(p.node, "OK ADD · * REMOVE", 18, 43, 300, 18, m.C.dim, "center")
    end for
    mkLabel(root, "TODAY SCREEN TICKERS", 880, 838, 24, m.C.yellow)
    newsState = "OFF"
    if m.state.tickers.newsEnabled then newsState = "ON"
    sportsState = "OFF"
    if m.state.tickers.sportsEnabled then sportsState = "ON"
    newsToggle = addItem(root, "action", "newsticker", 1, 7, 880, 874, 980, 58, m.C.panel)
    mkLabel(newsToggle.node, "Latest & breaking news ticker", 28, 16, 26, m.C.text)
    mkLabelW(newsToggle.node, newsState + " · OK TO TOGGLE", 590, 17, 360, 24, m.C.gold, "right")
    sportsToggle = addItem(root, "action", "sportsticker", 1, 8, 880, 944, 980, 58, m.C.panel)
    mkLabel(sportsToggle.node, "Sports ticker · NFL · NBA · NHL · MLB · NCAA", 28, 16, 24, m.C.text)
    mkLabelW(sportsToggle.node, sportsState + " · OK TO TOGGLE", 590, 17, 360, 24, m.C.gold, "right")
end sub

sub buildDiagnostics()
    root = m.screenRoot
    mkLabel(root, "SYSTEM HEALTH", 56, 84, 44, m.C.text)
    mkLabelW(root, "A read-only snapshot for troubleshooting. Back returns to Admin.", 56, 140, 1500, 25, m.C.dim, "left")

    freeBytes = registryFreeBytes()
    storageColor = m.C.green
    storageState = "HEALTHY"
    if freeBytes < 8192 then storageColor = m.C.gold : storageState = "LOW SPACE"
    if freeBytes < 4096 then storageColor = "0xFF7777FF" : storageState = "CRITICAL"
    eventsN = calendarEvents().count()
    calState = m.calendarStatus
    if calState = invalid or calState = "" then calState = "READY"
    recoveryText = "Primary family data loaded normally"
    if m.recoveredState then recoveryText = "Safety backup was used during this launch"
    trimText = "Nothing removed from the saved copy"
    if m.storageTrimmed then trimText = "Replaceable calendar/weather cache was omitted"
    weatherState = m.weatherStatus
    if weatherState = invalid or weatherState = "" then weatherState = "READY"

    rows = [
        { label: "APP BUILD", value: "v75.2.1r  ·  schema " + m.state.schemaVersion.toStr(), color: m.C.blue },
        { label: "FAMILY DATA", value: m.stateBytes.toStr() + " bytes  ·  safety copy " + m.backupBytes.toStr() + " bytes", color: m.C.text },
        { label: "ROKU STORAGE", value: storageState + "  ·  " + freeBytes.toStr() + " bytes available", color: storageColor },
        { label: "RECOVERY", value: recoveryText, color: m.C.text },
        { label: "STORAGE GUARD", value: trimText, color: m.C.text },
        { label: "CALENDAR", value: calState + "  ·  " + eventsN.toStr() + " saved events", color: m.C.text },
        { label: "CALENDAR SYNC", value: calendarSyncLabel(), color: m.C.text },
        { label: "WEATHER", value: weatherState + "  ·  ZIP 33417", color: m.C.text },
        { label: "WEATHER SYNC", value: weatherSyncLabel(), color: m.C.text },
        { label: "AMBIENT MODE", value: "ON  ·  starts after 5 quiet minutes", color: m.C.green },
        { label: "ROKU SCREENSAVER", value: "SUPPRESSED WHILE FAMILY HUB IS OPEN", color: m.C.green }
    ]
    for i = 0 to rows.count() - 1
        y = 202 + i * 68
        mkRect(root, 56, y, 1808, 56, m.C.panel)
        mkLabel(root, rows[i].label, 84, y + 16, 20, m.C.dim)
        mkLabelW(root, rows[i].value, 520, y + 14, 1300, 23, rows[i].color, "right")
    end for
    mkLabelW(root, "Protection order: forecast and calendar cache first; family points, purchases, owned items and avatar settings are preserved.", 56, 982, 1808, 22, m.C.gold, "center")
end sub

sub buildPinPick()
    root = m.screenRoot
    mkLabel(root, "RESET A SPENDING PIN", 56, 84, 44, m.C.text)
    mkLabel(root, "Pick a person. You set a brand new PIN for them - you do not need their old one. Only that person's PIN changes.", 56, 140, 26, m.C.dim)
    wk = profileKeys()
    for i = 0 to wk.count() - 1
        k = wk[i]
        st = "NOT SET"
        if shopPinFor(k) <> "" then st = "SET"
        item = addItem(root, "pinreset", k, 0, i, 56, 250 + i * 84, 760, 68, m.C.panel)
        mkLabel(item.node, personName(k), 32, 18, 28, m.C.text)
        mkLabelW(item.node, st, 500, 20, 228, 28, m.C.gold, "right")
    end for
    mkLabel(root, "Back returns to Admin.", 56, 250 + wk.count() * 84 + 16, 24, m.C.dim)
end sub

' ---------- keys ----------

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    m.activeKey = key
    dtK = CreateObject("roDateTime")
    m.lastKeySec = dtK.AsSeconds()
    if m.screen = "ambient" then
        exitAmbient()
        return true
    end if
    if m.screen = "pin" and key = "back" then
        pinBack()
        return true
    end if
    if m.screen = "confirmbuy" and key = "back" then
        m.pendingBuy = ""
        showScreen("shop")
        return true
    end if
    if m.screen = "pinpick" and key = "back" then
        showScreen("admin")
        return true
    end if
    if m.screen = "diagnostics" and key = "back" then
        showScreen("admin")
        return true
    end if
    if m.screen = "levels" and key = "back" then
        showScreen("game")
        return true
    end if
    if m.screen = "inventory" and key = "back" then
        showScreen("avatar")
        return true
    end if
    if m.screen = "mealplanner" and key = "back" then
        showScreen("family")
        return true
    end if
    if key = "options" then
        if m.area = "content" and m.items.count() > 0 then
            it = m.items[m.focusIdx]
            if it.kind = "familyfield" then
                if not m.admin then
                    denyEdit()
                else
                    clearFamilyField(it.id)
                end if
                return true
            end if
            if it.kind = "mealchoice" then
                if not m.admin then
                    denyEdit()
                else
                    clearMealPlanChoice(it.id)
                end if
                return true
            end if
            if it.kind = "timer" or it.kind = "zone" then
                if not m.admin then
                    denyEdit()
                    return true
                end if
            end if
            if it.kind = "wallet" then
                adjustWallet(it.id, -500)
                return true
            end if
            if it.kind = "bonuspoint" then
                adjustBonusPoint(it.id, -1)
                return true
            end if
            if it.kind = "chore" then
                cycleOwner(it, 1)
                return true
            end if
            if it.kind = "timer" then
                resetTimer(it.id)
                return true
            end if
            if it.kind = "zone" then
                cycleZoneOwner(it, 1)
                return true
            end if
        end if
        toggleMusic()
        return true
    end if
    if key = "rewind" or key = "fastforward" then
        dir = 1
        if key = "rewind" then dir = -1
        if m.area = "content" and m.items.count() > 0 then
            it = m.items[m.focusIdx]
            if it.kind = "mealchoice" then
                if not m.admin then
                    denyEdit()
                else
                    cycleMealPlanChoice(it.id, dir)
                end if
                return true
            end if
            if it.kind = "familyfield" and left(it.id, 3) = "rem" then
                if not m.admin then
                    denyEdit()
                else
                    adjustFamilyReminderExpiry(it.id, dir)
                end if
                return true
            end if
            if it.kind = "zone" then
                if not m.admin then
                    denyEdit()
                    return true
                end if
            end if
            if it.kind = "zone" then cycleZoneOwner(it, dir)
            if it.kind = "chore" then cycleOwner(it, dir)
        end if
        return true
    end if
    if key = "replay" then
        if m.area = "content" and m.items.count() > 0 then
            it = m.items[m.focusIdx]
            if it.kind = "timer" then
                if not m.admin then
                    denyEdit()
                    return true
                end if
                resetTimer(it.id)
            end if
        end if
        return true
    end if
    if key = "play" or key = "pause" then
        if m.area = "content" and m.items.count() > 0 then
            it = m.items[m.focusIdx]
            if it.kind = "chore" or it.kind = "timer" or it.kind = "zone" then
                if not m.admin then
                    denyEdit()
                    return true
                end if
            end if
            if it.kind = "chore" then toggleReminded(it)
            if it.kind = "timer" then toggleTimer(it.id)
            if it.kind = "zone" then toggleZoneReminded(it)
        end if
        return true
    end if
    if m.area = "menu" then
        if key = "left" and m.menuIdx > 0 then
            m.menuIdx = m.menuIdx - 1
            buildMenu()
            updateHighlight()
            return true
        end if
        if key = "right" and m.menuIdx < m.menuDefs.count() - 1 then
            m.menuIdx = m.menuIdx + 1
            buildMenu()
            updateHighlight()
            return true
        end if
        if key = "OK" or key = "down" then
            k2 = m.menuDefs[m.menuIdx].key
            if k2 = "admin" and not m.admin then
                openPin()
            else
                showScreen(k2)
            end if
            if m.items.count() > 0 then
                m.area = "content"
                m.focusIdx = 0
                updateHighlight()
            end if
            return true
        end if
        if key = "back" then return false
        return true
    end if
    ' content area
    if m.screen = "hub" and m.items.count() > 0 and (key = "up" or key = "down") then
        hubItem = m.items[m.focusIdx]
        if hubItem.kind = "eventcard" then
            scrollDirection = 1
            if key = "up" then scrollDirection = -1
            if scrollHubEventCard(hubItem.id, scrollDirection) then return true
        end if
    end if
    if key = "up" then
        if not moveFocus(0, -1) then
            m.area = "menu"
            buildMenu()
            updateHighlight()
        end if
        return true
    end if
    if key = "down" then moveFocus(0, 1) : return true
    if key = "left" or key = "right" then
        if m.items.count() > 0 then
            itS = m.items[m.focusIdx]
            if itS.kind = "slot" then
                dirS = 1
                if key = "left" then dirS = -1
                cycleSlot(itS.id, dirS)
                return true
            end if
        end if
    end if
    if key = "left" then moveFocus(-1, 0) : return true
    if key = "right" then moveFocus(1, 0) : return true
    if key = "OK" then
        if m.items.count() > 0 then
            it = m.items[m.focusIdx]
            if it.kind = "digit" then pinDigit(it.digit)
            if it.kind = "setgo" then submitHouse()
            if it.kind = "action" then doAction(it.id)
            handleExtraOK(it)
            if it.kind = "chore" or it.kind = "zone" or it.kind = "timer" then
                if not m.admin then
                    denyEdit()
                    return true
                end if
            end if
            if it.kind = "chore" then toggleChore(it)
            if it.kind = "zone" then toggleZone(it)
            if it.kind = "timer" then toggleTimer(it.id)
        end if
        return true
    end if
    if key = "back" then
        m.area = "menu"
        showScreen("hub")
        buildMenu()
        updateHighlight()
        return true
    end if
    return false
end function

' ---------- hub ----------

sub drawHubRow(root as Object, row as Object, checks as Object, reminded as Object, navCol as Integer, navRow as Integer, x as Integer, y as Integer, w as Integer, rh as Integer, fs as Integer)
    done = checks.doesExist(row.id)
    surface = monthSurfaceTheme(nowInfo().month)
    theme = monthTheme(nowInfo().month)
    priority = todayRowIsPriority(row.start)
    bgc = surface.row
    if not priority then bgc = surface.panel
    if done then bgc = surface.done
    item = addItem(root, "chore", row.id, navCol, navRow, x, y, w, rh, bgc)
    item.owner = row.owner
    item.baseOwner = row.baseOwner
    item.cat = row.cat
    item.blockStart = row.start
    g = item.node
    if priority and not done then mkRect(g, 0, 0, 6, rh, theme.a)
    ty = (rh - fs) \ 2
    faceH = 44
    if rh < 50 then faceH = 36
    drawProfileAvatarFace(g, row.owner, 10, (rh - faceH) \ 2, faceH)
    tl = mkLabel(g, row.text, 66, ty, fs, m.C.text)
    tl.width = w - 210
    tl.wrap = false
    rx = w - 144
    if done then
        rec = checks[row.id]
        if rec.doesExist("bonus") and rec.bonus > 0 then
            l1y = ty - 8
            if l1y < 2 then l1y = 2
            mkLabelW(g, "DONE +" + rec.pts.toStr(), rx, l1y, 134, fs - 2, m.C.green, "right")
            mkLabelW(g, "NO-ASK", rx, l1y + 24, 134, 14, m.C.gold, "right")
        else
            mkLabelW(g, "DONE +" + rec.pts.toStr(), rx, ty, 134, fs, m.C.green, "right")
        end if
    else if reminded.doesExist(row.id) then
        mkLabelW(g, "REMINDED", rx, ty, 134, fs - 3, m.C.gold, "right")
    else
        mkLabelW(g, personName(row.owner), rx, ty, 134, fs, m.C.dim, "right")
    end if
end sub

function todayChores(ni as Object) as Object
    dishOwner = m.kids[ni.days mod 3]
    wk = ni.weekIdx
    nt = ni.nightIdx
    blocks = [
        { title: "MORNING — BEFORE SCHOOL", rows: [
            { id: "dishwasher", text: "Empty the dishwasher", owner: dishOwner, cat: "misc", start: 6, checkable: true },
            { id: "laundryStart", text: "Start today's laundry load", owner: "nick", cat: "laundry", start: 6, checkable: true },
            { id: "beds", text: "Beds made", owner: "everyone", cat: "misc", start: 6, checkable: true },
            { id: "rooms", text: "Rooms reset", owner: "everyone", cat: "misc", start: 6, checkable: true }
        ]},
        { title: "AFTER SCHOOL", rows: [
            { id: "shoes", text: "Shoes on shelf, bags on hooks", owner: "everyone", cat: "misc", start: 14, checkable: true },
            { id: "laundryFold", text: "Move laundry, fold when done", owner: "patricia", cat: "laundry", start: 14, checkable: true }
        ]},
        { title: "EVENING - THE RESET", rows: [
            { id: "zoneKitchen", text: "Kitchen zone: 3 jobs", owner: zoneOwner("kitchen", wk), cat: "dinner", start: 17, checkable: true },
            { id: "zoneLiving", text: "Living Room zone: 3 jobs", owner: zoneOwner("living", wk), cat: "dinner", start: 17, checkable: true },
            { id: "zoneDining", text: "Dining Room zone: 3 jobs", owner: zoneOwner("dining", wk), cat: "dinner", start: 17, checkable: true },
            { id: "crewFood", text: "Crew: Put Away Food", owner: crewOwner("food", nt), cat: "dinner", start: 17, checkable: true },
            { id: "crewWipe", text: "Crew: Wipe table + counters", owner: crewOwner("wipe", nt), cat: "dinner", start: 17, checkable: true },
            { id: "crewSweep", text: "Crew: Sweep / Swiffer", owner: crewOwner("sweep", nt), cat: "dinner", start: 17, checkable: true },
            { id: "trash", text: "Trash to the curb", owner: curbOwner("trash", nt), cat: "trash", start: 17, checkable: true },
            { id: "recycle", text: "Recycling to the curb", owner: curbOwner("recycle", nt), cat: "trash", start: 17, checkable: true }
        ]}
    ]
    if ni.isSaturday then
        blocks.push({ title: "SATURDAY — DEEP CLEAN", rows: [
            { id: "deepclean", text: "Deep Clean — twelve zones", owner: "crew", cat: "zones", start: 14, checkable: true }
        ]})
    end if
    for each b in blocks
        for each r in b.rows
            r.baseOwner = r.owner
            if m.state.reassign.doesExist(r.id) then r.owner = m.state.reassign[r.id]
        end for
    end for
    return blocks
end function

sub drawNovemberTurkey(parent as Object, ox as Integer, oy as Integer)
    ' Layered fan feathers behind the tom.
    featherColors = ["0xA94435FF", "0xD06A3BFF", "0xE5A14AFF", "0x7A342BFF", "0xC45C32FF", "0xE4A244FF", "0xA94435FF"]
    featherHeights = [62, 78, 90, 96, 90, 78, 62]
    for i = 0 to 6
        fx = ox + 4 + (i * 20)
        fh = featherHeights[i]
        fy = oy + 100 - fh
        mkRect(parent, fx, fy, 18, fh, featherColors[i])
        mkRect(parent, fx + 4, fy + 7, 10, 8, "0xF4CC7AFF")
        mkRect(parent, fx + 4, fy + 20, 10, 5, "0x4B2530FF")
    end for
    ' Body, wing, neck and head.
    mkRect(parent, ox + 42, oy + 62, 74, 55, "0x4A2B24FF")
    mkRect(parent, ox + 54, oy + 74, 42, 30, "0x75412DFF")
    mkRect(parent, ox + 61, oy + 80, 26, 18, "0xA65A36FF")
    mkRect(parent, ox + 98, oy + 42, 18, 48, "0x6E3028FF")
    mkRect(parent, ox + 94, oy + 30, 30, 28, "0x35506AFF")
    mkRect(parent, ox + 100, oy + 35, 5, 5, "0xFFFFFFFF")
    mkRect(parent, ox + 102, oy + 36, 3, 3, "0x111111FF")
    mkRect(parent, ox + 124, oy + 42, 14, 9, "0xF2B84BFF")
    mkRect(parent, ox + 108, oy + 56, 9, 25, "0xC53F3FFF")
    ' Legs and feet.
    mkRect(parent, ox + 62, oy + 116, 6, 15, "0xD9A441FF")
    mkRect(parent, ox + 92, oy + 116, 6, 15, "0xD9A441FF")
    mkRect(parent, ox + 52, oy + 129, 22, 4, "0xD9A441FF")
    mkRect(parent, ox + 86, oy + 129, 22, 4, "0xD9A441FF")
end sub

sub drawNovemberPilgrimMan(parent as Object, ox as Integer, oy as Integer)
    skin = "0xD9A07CFF"
    dark = "0x171722FF"
    ' Hat with gold buckle.
    mkRect(parent, ox + 10, oy + 2, 52, 34, dark)
    mkRect(parent, ox, oy + 30, 72, 10, dark)
    mkRect(parent, ox + 10, oy + 25, 52, 7, "0x5A3A2FFF")
    mkRect(parent, ox + 28, oy + 24, 16, 11, "0xE7B64CFF")
    mkRect(parent, ox + 32, oy + 27, 8, 5, dark)
    ' Face, hair and expression.
    mkRect(parent, ox + 16, oy + 40, 40, 34, skin)
    mkRect(parent, ox + 12, oy + 40, 8, 31, "0x593A2FFF")
    mkRect(parent, ox + 52, oy + 40, 8, 31, "0x593A2FFF")
    mkRect(parent, ox + 25, oy + 51, 4, 4, "0x1A1A20FF")
    mkRect(parent, ox + 43, oy + 51, 4, 4, "0x1A1A20FF")
    mkRect(parent, ox + 31, oy + 64, 12, 3, "0x8C4B44FF")
    ' Collar, coat, belt and buttons.
    mkRect(parent, ox + 6, oy + 74, 60, 50, dark)
    mkRect(parent, ox + 12, oy + 74, 22, 11, "0xF5EBD5FF")
    mkRect(parent, ox + 38, oy + 74, 22, 11, "0xF5EBD5FF")
    mkRect(parent, ox + 8, oy + 101, 56, 7, "0x4A3028FF")
    mkRect(parent, ox + 28, oy + 99, 16, 11, "0xE7B64CFF")
    mkRect(parent, ox + 32, oy + 102, 8, 5, dark)
    mkRect(parent, ox + 34, oy + 88, 4, 4, "0xE7B64CFF")
    mkRect(parent, ox + 34, oy + 95, 4, 4, "0xE7B64CFF")
    mkRect(parent, ox + 8, oy + 122, 24, 10, dark)
    mkRect(parent, ox + 40, oy + 122, 24, 10, dark)
end sub

sub drawNovemberPilgrimWoman(parent as Object, ox as Integer, oy as Integer)
    skin = "0xD9A07CFF"
    dress = "0x282038FF"
    cream = "0xF5EBD5FF"
    ' White bonnet framing the face.
    mkRect(parent, ox + 10, oy + 10, 52, 38, cream)
    mkRect(parent, ox + 4, oy + 34, 64, 12, cream)
    mkRect(parent, ox + 17, oy + 23, 38, 32, skin)
    mkRect(parent, ox + 12, oy + 22, 7, 34, "0x5A3A2FFF")
    mkRect(parent, ox + 53, oy + 22, 7, 34, "0x5A3A2FFF")
    mkRect(parent, ox + 25, oy + 34, 4, 4, "0x1A1A20FF")
    mkRect(parent, ox + 43, oy + 34, 4, 4, "0x1A1A20FF")
    mkRect(parent, ox + 31, oy + 47, 12, 3, "0x8C4B44FF")
    ' Dress, collar and apron.
    mkRect(parent, ox + 9, oy + 56, 54, 42, dress)
    mkRect(parent, ox, oy + 94, 72, 32, dress)
    mkRect(parent, ox + 14, oy + 56, 20, 10, cream)
    mkRect(parent, ox + 38, oy + 56, 20, 10, cream)
    mkRect(parent, ox + 23, oy + 72, 28, 48, "0xE7D8BEFF")
    mkRect(parent, ox + 18, oy + 70, 38, 7, cream)
    mkRect(parent, ox + 8, oy + 124, 24, 8, "0x171722FF")
    mkRect(parent, ox + 40, oy + 124, 24, 8, "0x171722FF")
end sub

sub drawNovemberBottomScene(root as Object)
    if nowInfo().month <> 11 then return
    g = CreateObject("roSGNode", "Group")
    g.translation = [1310, 895]
    root.appendChild(g)
    drawNovemberTurkey(g, 10, 0)
    drawNovemberPilgrimMan(g, 210, 0)
    drawNovemberPilgrimWoman(g, 350, 0)
    mkRect(g, 0, 136, 540, 3, "0xF0A060AA")
end sub

sub drawDecemberElf(parent as Object, ox as Integer, oy as Integer, coatColor as String)
    skin = "0xD9A07CFF"
    ' Pointed hat, ears and cheerful face.
    mkRotRect(parent, ox + 22, oy + 2, 30, 10, coatColor, -0.55)
    mkRect(parent, ox + 14, oy + 13, 40, 10, coatColor)
    mkRect(parent, ox + 19, oy + 23, 30, 25, skin)
    mkRect(parent, ox + 11, oy + 29, 9, 10, skin)
    mkRect(parent, ox + 48, oy + 29, 9, 10, skin)
    mkRect(parent, ox + 25, oy + 31, 3, 3, "0x171722FF")
    mkRect(parent, ox + 40, oy + 31, 3, 3, "0x171722FF")
    mkRect(parent, ox + 29, oy + 41, 11, 3, "0x984C47FF")
    ' Collar, tunic, belt and striped legs.
    mkRect(parent, ox + 13, oy + 48, 42, 45, coatColor)
    mkRect(parent, ox + 15, oy + 48, 18, 8, "0xFFF4D8FF")
    mkRect(parent, ox + 35, oy + 48, 18, 8, "0xFFF4D8FF")
    mkRect(parent, ox + 14, oy + 74, 40, 6, "0x30221FFF")
    mkRect(parent, ox + 29, oy + 72, 10, 10, "0xE7B64CFF")
    mkRect(parent, ox + 18, oy + 92, 12, 28, "0xF4F0E5FF")
    mkRect(parent, ox + 38, oy + 92, 12, 28, "0xF4F0E5FF")
    mkRect(parent, ox + 18, oy + 99, 12, 6, "0xD94A4AFF")
    mkRect(parent, ox + 38, oy + 99, 12, 6, "0xD94A4AFF")
    mkRect(parent, ox + 10, oy + 118, 22, 8, "0x30221FFF")
    mkRect(parent, ox + 36, oy + 118, 22, 8, "0x30221FFF")
end sub

sub drawDecemberSceneContent(g as Object)
    ' Christmas tree: layered evergreen boughs, star, ornaments and presents.
    mkRect(g, 42, 0, 5, 18, "0xFFD85CFF")
    mkRect(g, 35, 6, 19, 5, "0xFFD85CFF")
    mkRect(g, 36, 24, 18, 14, "0x2E8A57FF")
    mkRect(g, 26, 36, 38, 18, "0x237348FF")
    mkRect(g, 16, 50, 58, 22, "0x2E8A57FF")
    mkRect(g, 6, 67, 78, 26, "0x1E6740FF")
    mkRect(g, 38, 92, 14, 28, "0x74452FFF")
    ornaments = [[31, 42, "0xE84A5FFF"], [52, 51, "0xFFD85CFF"], [24, 65, "0x4D8FE8FF"], [60, 74, "0xF06AA8FF"], [42, 82, "0xFFD85CFF"]]
    for each ornament in ornaments
        mkRect(g, ornament[0], ornament[1], 7, 7, ornament[2])
    end for
    mkRect(g, 4, 112, 28, 18, "0xD94A4AFF")
    mkRect(g, 16, 112, 5, 18, "0xFFD85CFF")
    mkRect(g, 58, 108, 30, 22, "0x4D78C9FF")
    mkRect(g, 58, 116, 30, 5, "0xFFF4D8FF")

    ' Santa with hat, beard, suit, belt and sack.
    mkRect(g, 104, 16, 48, 15, "0xD93B45FF")
    mkRotRect(g, 128, 2, 34, 12, "0xD93B45FF", 0.45)
    mkRect(g, 154, 10, 10, 10, "0xFFF4D8FF")
    mkRect(g, 111, 31, 35, 30, "0xD9A07CFF")
    mkRect(g, 107, 49, 43, 28, "0xFFF4E6FF")
    mkRect(g, 117, 39, 4, 4, "0x171722FF")
    mkRect(g, 136, 39, 4, 4, "0x171722FF")
    mkRect(g, 123, 52, 12, 4, "0xB9544FFF")
    mkRect(g, 102, 72, 54, 46, "0xD93B45FF")
    mkRect(g, 102, 89, 54, 8, "0x2A2021FF")
    mkRect(g, 122, 87, 15, 12, "0xE7B64CFF")
    mkRect(g, 106, 113, 20, 17, "0x2A2021FF")
    mkRect(g, 134, 113, 20, 17, "0x2A2021FF")
    mkRect(g, 92, 64, 15, 49, "0x8F3A2FFF")
    mkRect(g, 89, 73, 8, 30, "0xB9763CFF")

    ' Two workshop elves.
    drawDecemberElf(g, 162, 4, "0x3D9A5FFF")
    drawDecemberElf(g, 220, 4, "0xC9474FFF")

    ' Manger scene with guiding star, stable roof, cradle and baby.
    mkRect(g, 347, 0, 5, 18, "0xFFF0A8FF")
    mkRect(g, 340, 6, 19, 5, "0xFFF0A8FF")
    mkRotRect(g, 284, 40, 74, 8, "0x84542FFF", -0.42)
    mkRotRect(g, 346, 10, 74, 8, "0x84542FFF", 0.42)
    mkRect(g, 294, 43, 8, 82, "0x71452CFF")
    mkRect(g, 403, 43, 8, 82, "0x71452CFF")
    mkRect(g, 302, 48, 101, 6, "0xA96A3AFF")
    mkRect(g, 317, 96, 72, 12, "0xA96A3AFF")
    mkRotRect(g, 312, 104, 52, 6, "0xD4A24CFF", 0.28)
    mkRotRect(g, 345, 105, 52, 6, "0xD4A24CFF", -0.28)
    mkRect(g, 340, 88, 24, 16, "0xE8B28CFF")
    mkRect(g, 344, 91, 4, 4, "0x2A2021FF")
    mkRect(g, 356, 91, 4, 4, "0x2A2021FF")
    mkRect(g, 326, 108, 57, 14, "0xE7D8BEFF")

    ' Snowman with coal buttons, carrot, scarf and top hat.
    mkRect(g, 447, 64, 56, 58, "0xEAF5FAFF")
    mkRect(g, 455, 28, 42, 42, "0xF5FBFFFF")
    mkRect(g, 458, 12, 36, 18, "0x202532FF")
    mkRect(g, 451, 27, 50, 7, "0x202532FF")
    mkRect(g, 465, 42, 4, 4, "0x202532FF")
    mkRect(g, 484, 42, 4, 4, "0x202532FF")
    mkRect(g, 473, 50, 17, 6, "0xF09A3EFF")
    mkRect(g, 449, 66, 60, 9, "0xD94A4AFF")
    mkRect(g, 493, 72, 8, 28, "0xD94A4AFF")
    mkRect(g, 474, 82, 6, 6, "0x202532FF")
    mkRect(g, 474, 99, 6, 6, "0x202532FF")
    mkRect(g, 449, 120, 24, 9, "0x202532FF")
    mkRect(g, 482, 120, 24, 9, "0x202532FF")

    ' Snow bank grounding the complete scene.
    mkRect(g, 0, 130, 530, 7, "0xDDEFF7DD")
end sub

sub drawDecemberBottomScene(root as Object)
    if nowInfo().month <> 12 then return
    g = CreateObject("roSGNode", "Group")
    g.translation = [1310, 895]
    root.appendChild(g)
    drawDecemberSceneContent(g)
end sub

sub buildHub()
    root = m.screenRoot
    ni = nowInfo()
    drawSeasonalHub(root, ni.month)
    mkLabel(root, "OUR HOUSE PLAN", 56, 84, 54, m.C.text)
    todayTheme = monthTheme(ni.month)
    todaySurface = monthSurfaceTheme(ni.month)
    ambientButton = addItem(root, "action", "ambientnow", 2, -2, 520, 90, 190, 46, todayTheme.bg)
    mkRect(ambientButton.node, 0, 0, 6, 46, todayTheme.a)
    mkLabelW(ambientButton.node, "AMBIENT NOW", 10, 11, 170, 21, m.C.text, "center")
    modeButton = addItem(root, "action", "todaymode", 3, -2, 1450, 138, 414, 40, todayTheme.bg)
    mkRect(modeButton.node, 0, 0, 6, 40, todayTheme.b)
    mkLabelW(modeButton.node, todayModeButtonText(), 12, 9, 390, 20, m.C.text, "center")
    mkLabelW(root, ni.label, 1250, 100, 614, 30, m.C.dim, "right")
    m.hubClockLabel = mkLabelW(root, formatHubClock(), 760, 94, 400, 34, todayTheme.b, "center")
    startCalendarSync(false)
    drawHubWeatherSummary(root)
    drawHubCalendarSnippet(root)
    drawHubTomorrowSnippet(root)
    ' podium: sort players by points
    ranked = []
    for each p in m.players
        ranked.push(p)
    end for
    for i = 0 to ranked.count() - 2
        for j = 0 to ranked.count() - 2 - i
            if m.state.points[ranked[j]] < m.state.points[ranked[j + 1]] then
                tmp = ranked[j] : ranked[j] = ranked[j + 1] : ranked[j + 1] = tmp
            end if
        end for
    end for
    spots = [
        { x: 800, w: 320, imgY: 168, imgH: 252, bh: 78, medal: "1" },
        { x: 380, w: 280, imgY: 208, imgH: 212, bh: 58, medal: "2" },
        { x: 1260, w: 280, imgY: 208, imgH: 212, bh: 46, medal: "3" }
    ]
    for r = 0 to 2
        p = ranked[r]
        s = spots[r]
        drewBuilt = false
        if m.state.podiumAvatar = "built" then
            acfg = avatarCfgFor(p)
            if acfg <> invalid then
                grp = CreateObject("roSGNode", "Group")
                gy = s.imgY + 4
                if r = 0 then gy = s.imgY + 24
                grp.translation = [s.x + (s.w - 100) / 2, gy]
                root.appendChild(grp)
                drawAvatar(grp, 0, 0, 1, acfg, "full")
                drewBuilt = true
            end if
        end if
        if not drewBuilt then mkPoster(root, bodyUri(p), s.x, s.imgY, s.w, s.imgH)
        block = mkRect(root, s.x, 496 - s.bh, s.w, s.bh, todaySurface.podium)
        mkLabelW(root, s.medal, s.x, 496 - s.bh + 4, s.w, 44, todayTheme.b, "center")
        mkLabelW(root, personName(p) + " · " + m.state.points[p].toStr() + " pts total", s.x - 20, 506, s.w + 40, 27, m.C.text, "center")
    end for
    alertText = weatherAlertText()
    if alertText <> "" then
        mkRect(root, 460, 542, 1000, 38, "0x6B1C2BFF")
        mkLabelW(root, "WEATHER ALERT · " + alertText, 480, 550, 960, 22, "0xFFE0A3FF", "center")
    else
        focusLabel = mkLabelW(root, todayFocusText(), 260, 548, 1400, 20, todayTheme.a, "center")
        focusLabel.wrap = false
        focusLabel.ellipsizeOnBoundary = true
    end if
    ' columns
    blocks = todayChores(ni)
    checks = todayChecks()
    reminded = todayReminded()
    if ni.isSaturday and blocks.count() > 3 then
        buildHubSaturday(blocks, checks, reminded)
        drawHubTickers(root)
        return
    end if
    ' left column: Morning stacked over After School
    leftBlocks = [
        { b: blocks[0], headerY: 592, rowY: 630, navRow0: 0 },
        { b: blocks[1], headerY: 880, rowY: 912, navRow0: 4 }
    ]
    for li = 0 to 1
        lb = leftBlocks[li]
        mkLabel(root, lb.b.title, 56, lb.headerY, 26, todayTheme.b)
        y = lb.rowY
        for r = 0 to lb.b.rows.count() - 1
            row = lb.b.rows[r]
            drawHubRow(root, row, checks, reminded, 0, lb.navRow0 + r, 56, y, 540, 54, 24)
            y = y + 60
        end for
    end for
    ' right two-thirds: Evening in two sub-columns
    mkLabel(root, blocks[2].title, 690, 592, 26, todayTheme.b)
    ev = blocks[2].rows
    subX = [690, 1300]
    subW = [572, 564]
    for s = 0 to 1
        y = 630
        for r = 0 to 3
            idx = s * 4 + r
            if idx < ev.count() then drawHubRow(root, ev[idx], checks, reminded, 1 + s, r, subX[s], y, subW[s], 58, 25)
            y = y + 66
        end for
    end for
    drawNovemberBottomScene(root)
    drawDecemberBottomScene(root)
    mkRect(root, 56, 1036, 1808, 2, todaySurface.line)
    mkLabelW(root, "LAUNDRY — one load a day, start to finish: Nick starts it · Trish moves it and folds · a missed load goes first tomorrow", 56, 1046, 1808, 24, todayTheme.a, "center")
    drawHubTickers(root)
end sub

sub buildHubSaturday(blocks as Object, checks as Object, reminded as Object)
    root = m.screenRoot
    saturdayTheme = monthTheme(nowInfo().month)
    ' band 1: Morning | After School | Deep Clean, three columns
    mkLabel(root, blocks[0].title, 56, 592, 26, saturdayTheme.b)
    y = 630
    for r = 0 to blocks[0].rows.count() - 1
        drawHubRow(root, blocks[0].rows[r], checks, reminded, 0, r, 56, y, 572, 50, 23)
        y = y + 54
    end for
    mkLabel(root, blocks[1].title, 690, 592, 26, saturdayTheme.b)
    y = 630
    for r = 0 to blocks[1].rows.count() - 1
        drawHubRow(root, blocks[1].rows[r], checks, reminded, 1, r, 690, y, 572, 50, 23)
        y = y + 54
    end for
    mkLabelW(root, "LAUNDRY — one load a day, start to finish: Nick starts it · Trish moves it and folds · a missed load goes first tomorrow", 690, 752, 572, 19, saturdayTheme.a, "left")
    mkLabel(root, blocks[3].title, 1300, 592, 26, saturdayTheme.b)
    drawHubRow(root, blocks[3].rows[0], checks, reminded, 2, 0, 1300, 630, 564, 50, 23)
    mkLabel(root, "Twelve zones · 20:00 a zone", 1300, 700, 23, saturdayTheme.a)
    mkLabel(root, "Run them on the Reset page", 1300, 736, 23, m.C.dim)
    mkLabel(root, "All twelve = Deep Clean Crew", 1300, 772, 23, saturdayTheme.b)
    ' band 2: Evening across the full width, two sub-columns
    mkLabel(root, blocks[2].title, 56, 854, 26, saturdayTheme.b)
    ev = blocks[2].rows
    subX = [56, 992]
    for s = 0 to 1
        y = 882
        for r = 0 to 3
            idx = s * 4 + r
            if idx < ev.count() then drawHubRow(root, ev[idx], checks, reminded, s, 4 + r, subX[s], y, 872, 42, 22)
            y = y + 48
        end for
    end for
end sub

function gamePlayers() as Object
    list = []
    for each p in m.players
        list.push(p)
    end for
    np = m.state.points.nicky
    if np <> invalid and np > 0 then list.push("nicky")
    return list
end function

' ---------- game ----------

function levelFor(pts as Integer) as Object
    lv = [
        { at: 0, name: "Getting Going" },
        { at: 15, name: "In the Flow" },
        { at: 30, name: "On Fire" },
        { at: 50, name: "House Captain" },
        { at: 80, name: "Legend of the House" }
    ]
    cur = lv[0]
    nxt = invalid
    for i = 0 to lv.count() - 1
        if pts >= lv[i].at then
            cur = lv[i]
            if i + 1 < lv.count() then nxt = lv[i + 1] else nxt = invalid
        end if
    end for
    return { name: cur.name, next: nxt }
end function

function badgesFor(player as String) as String
    pc = m.state.counts[player]
    if pc = invalid then return "No badges yet — first check earns your start"
    out = []
    na = 0
    if pc.doesExist("noask") then na = pc.noask
    if pc.early >= 3 then out.push("Early Bird")
    if na >= 5 then out.push("No-Ask Pro")
    if pc.laundry >= 5 then out.push("Laundry Legend")
    if pc.dinner >= 5 then out.push("Reset Closer")
    if pc.trash >= 3 then out.push("Curb Crew")
    if pc.zones >= 10 then out.push("Deep Clean Crew")
    s = m.state.streaks[player]
    if s <> invalid and s.count >= 5 then out.push("Streak Master")
    if player = "parents" and pc.total >= 10 then out.push("Anchor")
    if out.count() = 0 then return "No badges yet — first check earns your start"
    txt = ""
    for i = 0 to out.count() - 1
        if i > 0 then txt = txt + " · "
        txt = txt + out[i]
    end for
    return txt
end function

function houseCountTotal(cat as String) as Integer
    tot = 0
    for each p in m.players
        pc = m.state.counts[p]
        if pc <> invalid and pc.doesExist(cat) then tot = tot + pc[cat]
    end for
    return tot
end function

sub buildGame()
    root = m.screenRoot
    total = m.state.points.house
    for each p in m.players
        total = total + m.state.points[p]
    end for
    if m.state.points.nicky <> invalid then total = total + m.state.points.nicky
    famPts = total - m.state.points.house
    goal = 450
    mkLabel(root, "THE HOUSE GAME", 56, 84, 46, m.C.text)
    mkLabelW(root, "Season 1 · the 3-week rotation", 1250, 100, 614, 28, m.C.dim, "right")
    mkRect(root, 56, 150, 1808, 168, m.C.panel)
    mkLabel(root, "HOUSE METER — everyone fills it together", 84, 168, 30, m.C.blue)
    mkRect(root, 84, 214, 1300, 30, "0x0B1020FF")
    fw = 1300 * total \ goal
    if fw > 1300 then fw = 1300
    if fw > 0 then mkRect(root, 84, 214, fw, 30, m.C.accent)
    mkLabel(root, total.toStr() + " / " + goal.toStr() + " pts", 1420, 206, 38, m.C.text)
    mkLabel(root, "House points: " + m.state.points.house.toStr() + " · Family points: " + famPts.toStr() + " — fill the meter and the house unlocks a Family Pick Night.", 84, 252, 24, m.C.dim)
    wranked = []
    for each p in m.players
        wranked.push(p)
    end for
    for i = 0 to wranked.count() - 2
        for j = 0 to wranked.count() - 2 - i
            if weekPts(wranked[j]) < weekPts(wranked[j + 1]) then
                wtmp = wranked[j] : wranked[j] = wranked[j + 1] : wranked[j + 1] = wtmp
            end if
        end for
    end for
    race = "WEEKLY RACE · RESETS SATURDAY: "
    for i = 0 to wranked.count() - 1
        if i > 0 then race = race + " · "
        race = race + personName(wranked[i]) + " " + weekPts(wranked[i]).toStr()
    end for
    lw = m.state.week.lastWinner
    if lw <> invalid then race = race + "   |   Last week: " + lw.text + " · " + lw.pts.toStr() + " pts"
    mkLabel(root, race, 84, 282, 25, m.C.gold)
    gp = gamePlayers()
    rowH = 100
    rowStep = 112
    faceS = 82
    nameY = 12
    nameFs = 32
    lvY = 54
    lvFs = 24
    badgeY = 16
    badgeFs = 25
    barY = 58
    toY = 50
    ptsY = 32
    ptsFs = 30
    if gp.count() > 4 then
        rowH = 80
        rowStep = 92
        faceS = 64
        nameY = 8
        nameFs = 28
        lvY = 42
        lvFs = 21
        badgeY = 10
        badgeFs = 21
        barY = 46
        toY = 40
        ptsY = 24
        ptsFs = 26
    end if
    y = 338
    for each p in gp
        pts = m.state.points[p]
        lv = levelFor(pts)
        mkRect(root, 56, y, 1808, rowH, m.C.panel)
        drawProfileAvatarFace(root, p, 76, y + (rowH - faceS) \ 2, faceS)
        mkLabel(root, personName(p), 180, y + nameY, nameFs, m.C.text)
        mkLabel(root, lv.name, 180, y + lvY, lvFs, m.C.gold)
        mkLabelW(root, badgesFor(p), 560, y + badgeY, 800, badgeFs, m.C.dim, "left")
        if lv.next <> invalid then
            curBase = 0
            lvAll = [0, 15, 30, 50, 80]
            for i = 0 to lvAll.count() - 1
                if pts >= lvAll[i] then curBase = lvAll[i]
            end for
            bw = 420 * (pts - curBase) \ (lv.next.at - curBase)
            mkRect(root, 560, y + barY, 420, 14, "0x0B1020FF")
            if bw > 0 then mkRect(root, 560, y + barY, bw, 14, m.C.green)
            mkLabel(root, (lv.next.at - pts).toStr() + " pts to " + lv.next.name, 1000, y + toY, 24, m.C.dim)
        else
            mkLabel(root, "Top level reached. Legend status.", 560, y + barY - 6, 24, m.C.green)
        end if
        s = m.state.streaks[p]
        sc = 0
        if s <> invalid then sc = s.count
        mkLabelW(root, pts.toStr() + " season · " + weekPts(p).toStr() + " wk · streak " + sc.toStr(), 1300, y + ptsY, 520, ptsFs, m.C.text, "right")
        y = y + rowStep
    end for
    cy = 792
    cw = 592
    for i = 0 to 2
        mkRect(root, 56 + i * 624, cy, cw, 232, m.C.panel)
    end for
    mkLabel(root, "WEEKLY QUESTS", 84, cy + 18, 28, m.C.yellow)
    mkLabel(root, "Same-day folds: " + houseCountTotal("laundry").toStr() + " / 10 loads", 84, cy + 66, 26, m.C.text)
    mkLabel(root, "No-ask finishes: " + houseCountTotal("noask").toStr() + " / 15", 84, cy + 108, 26, m.C.text)
    mkLabel(root, "Reset checks at dinner: " + houseCountTotal("dinner").toStr() + " / 20", 84, cy + 150, 26, m.C.text)
    mkLabel(root, "SATURDAY BOSS", 708, cy + 18, 28, m.C.yellow)
    mkLabelW(root, "Deep Clean morning: all twelve zones, double points, level-ups count twice. Zones cleared so far: " + m.state.houseZones.toStr(), 708, cy + 66, 536, 26, m.C.text, "left")
    mkLabel(root, "FRIDAY REWARDS", 1332, cy + 18, 28, m.C.yellow)
    mkLabelW(root, "The week's leader picks: dessert, the weekend movie, Saturday breakfast, game-night first pick, or +30 min Friday. Everyone over 25: the reward is a family pick.", 1332, cy + 66, 536, 26, m.C.text, "left")
    litem = addItem(root, "action", "levels", 0, 0, 56, 1032, 1808, 40, m.C.panel)
    ll = mkLabel(litem.node, "WHAT THE LEVELS MEAN · OK TO OPEN", 0, 7, 22, m.C.blue)
    ll.width = 1808
    ll.horizAlign = "center"
end sub

' ---------- reset ----------

function zonesData() as Object
    return [
        { name: "1 · Dining table", done: "Bare wood except the flowers. Everything else has a home or goes in the family inbox basket." },
        { name: "2 · Dining Room Organize", done: "Sideboard and shelves straight. Chairs in place. Nothing stored on the table or under it." },
        { name: "3 · Kitchen bar counter", done: "Clear except the coffee maker. Cups back in the cabinet, keep 6 out." },
        { name: "4 · Sink + dishwasher", done: "Sink empty. Dishwasher loaded and running. Drying rack clear." },
        { name: "5 · Entryway", done: "Boxes broken down and out. One pair of shoes per person. Backpacks on hooks. Floor clear." },
        { name: "6 · Living room", done: "Coffee table: remotes and one book only. Blankets folded on the couch. Piano top clear." },
        { name: "7 · Laundry zone", done: "One load in the machine. Sorter bags not overflowing. No laundry on the floor." },
        { name: "8 · Utility Room", done: "Machine tops clear. Supplies in the cabinet, doors shut. Brooms and dustpan in their corner. Floor swept, walkway clear." },
        { name: "9 · Bedroom", done: "Bed made. Floor clear. Dresser top clear except the lamp. Shoes put away." },
        { name: "10 · Linen closet", done: "Linens only, folded. One shelf per kind: towels, sheets, blankets. Clothes out." },
        { name: "11 · Closet floor", done: "You can see the floor. Clothes hanging or in drawers. One donate bag lives here." },
        { name: "12 · Bathroom", done: "Sink and counter wiped, mirror spotless, trash out. Towels hanging straight, floor clear, spare roll in sight." }
    ]
end function

function todayZones() as Object
    ni = nowInfo()
    z = m.state.zones[ni.dateKey]
    if z = invalid then z = {}
    return z
end function

function playerBucket(nameKey as String) as String
    if nameKey = "patricia" or nameKey = "nick" then return "parents"
    return nameKey
end function

function zoneOwnerKey(idx as Integer) as String
    if m.state.zoneOwner = invalid then return "house"
    v = m.state.zoneOwner[idx.toStr()]
    if v = invalid then return "house"
    return v
end function

function zoneRecOwner(rec as Object) as String
    if rec = invalid then return "house"
    t = Type(rec)
    if t = "String" or t = "roString" then return rec
    if t = "roAssociativeArray" then
        if rec.owner = invalid then return "house"
        return rec.owner
    end if
    return "house"
end function

function zoneRecPts(rec as Object) as Integer
    if Type(rec) = "roAssociativeArray" and rec.pts <> invalid then return rec.pts
    return 2
end function

function zoneRecNoAsk(rec as Object) as Boolean
    if Type(rec) = "roAssociativeArray" and rec.noAsk <> invalid then return rec.noAsk
    return false
end function

function zoneReminded(idx as Integer) as Boolean
    return todayReminded().doesExist("zone" + idx.toStr())
end function

sub toggleZoneReminded(item as Object)
    z = todayZones()
    if z.doesExist(item.zoneIdx.toStr()) then return
    ni = nowInfo()
    r = todayReminded()
    k = "zone" + item.zoneIdx.toStr()
    if r.doesExist(k) then
        r.delete(k)
    else
        r[k] = true
    end if
    m.state.reminded[ni.dateKey] = r
    saveState()
    rebuildScreen()
end sub

sub cycleZoneOwner(item as Object, dir as Integer)
    order = ["house", "emily", "max", "anthony", "patricia", "nick", "nicky"]
    cur = zoneOwnerKey(item.zoneIdx)
    idx = 0
    for i = 0 to order.count() - 1
        if order[i] = cur then idx = i
    end for
    if m.state.zoneOwner = invalid then m.state.zoneOwner = {}
    m.state.zoneOwner[item.zoneIdx.toStr()] = order[(idx + dir + order.count()) mod order.count()]
    saveState()
    rebuildScreen()
end sub

sub toggleZone(item as Object)
    ensureWeek()
    ni = nowInfo()
    z = todayZones()
    k = item.zoneIdx.toStr()
    if z.doesExist(k) then
        rec = z[k]
        owner = zoneRecOwner(rec)
        pts = zoneRecPts(rec)
        wasNoAsk = zoneRecNoAsk(rec)
        payCb(owner, -zoneRecCb(rec))
        z.delete(k)
        m.state.houseZones = m.state.houseZones - 1
        if owner = "house" then
            m.state.points.house = m.state.points.house - pts
        else
            pk = playerBucket(owner)
            m.state.points[pk] = m.state.points[pk] - pts
            wp = m.state.week.points[pk] - pts
            if wp < 0 then wp = 0
            m.state.week.points[pk] = wp
            bumpCounts(pk, "zones", false, -1, wasNoAsk)
        end if
    else
        owner = zoneOwnerKey(item.zoneIdx)
        noAsk = not zoneReminded(item.zoneIdx)
        pts = 2
        if noAsk then pts = 3
        cents = cbRate(not noAsk)
        z[k] = { owner: owner, pts: pts, noAsk: noAsk, cb: cents }
        payCb(owner, cents)
        cbToast(owner, cents)
        m.state.houseZones = m.state.houseZones + 1
        if owner = "house" then
            m.state.points.house = m.state.points.house + pts
        else
            pk = playerBucket(owner)
            m.state.points[pk] = m.state.points[pk] + pts
            m.state.week.points[pk] = m.state.week.points[pk] + pts
            bumpCounts(pk, "zones", false, 1, noAsk)
            bumpStreak(pk)
        end if
    end if
    m.state.zones[ni.dateKey] = z
    saveState()
    rebuildScreen()
end sub

sub buildReset()
    root = m.screenRoot
    z = todayZones()
    doneCount = 0
    for each k in z
        doneCount = doneCount + 1
    end for
    mkLabel(root, "THE RESET — TWELVE ZONES", 56, 84, 44, m.C.text)
    mkLabelW(root, doneCount.toStr() + " of 12 zones done today", 1250, 100, 614, 28, m.C.dim, "right")
    tcards = [
        { kind: "zone", title: "ZONE TIMER · 20:00 PER ZONE", x: 56 },
        { kind: "family", title: "FAMILY RESET · 10:00 AFTER DINNER", x: 974 }
    ]
    for i = 0 to 1
        tc = tcards[i]
        item = addItem(root, "timer", tc.kind, i, 0, tc.x, 148, 890, 168, m.C.panel)
        g = item.node
        mkLabel(g, tc.title, 28, 16, 26, m.C.blue)
        tl = mkLabel(g, fmtTime(m.timers[tc.kind].left), 28, 48, 84, m.C.text)
        m.timerLabels[tc.kind] = tl
        st = mkLabel(g, "", 420, 84, 28, m.C.gold)
        st.width = 440
        m.timerStates[tc.kind] = st
    end for
    refreshTimerStates()
    zd = zonesData()
    colX = [56, 664, 1272]
    for idx = 0 to zd.count() - 1
        c = idx mod 3
        r = idx \ 3
        x = colX[c]
        y = 336 + r * 164
        done = z.doesExist(idx.toStr())
        bgc = m.C.panel
        if done then bgc = m.C.rowDone
        item = addItem(root, "zone", "zone" + idx.toStr(), c, r + 1, x, y, 592, 152, bgc)
        item.zoneIdx = idx
        g = item.node
        mkLabel(g, zd[idx].name, 24, 13, 27, m.C.text)
        shown = zoneOwnerKey(idx)
        if done then shown = zoneRecOwner(z[idx.toStr()])
        ownName = "House"
        oc = m.C.dim
        if shown <> "house" then
            ownName = personName(shown)
            oc = m.C.blue
        end if
        mkLabelW(g, "WHO: " + ownName, 330, 15, 238, 21, oc, "right")
        mkLabelW(g, zd[idx].done, 24, 50, 544, 20, m.C.dim, "left")
        if done then
            zpts = zoneRecPts(z[idx.toStr()])
            zna = zoneRecNoAsk(z[idx.toStr()])
            suffix = ""
            if zna then suffix = " · NO-ASK"
            if shown = "house" then
                mkLabel(g, "DONE · +" + zpts.toStr() + " HOUSE PTS" + suffix, 24, 122, 20, m.C.green)
            else
                mkLabel(g, "DONE · +" + zpts.toStr() + " " + UCase(ownName) + suffix, 24, 122, 20, m.C.green)
            end if
        else if zoneReminded(idx) then
            mkLabel(g, "REMINDED · OK pays +2 · Play clears", 24, 122, 20, m.C.gold)
        else
            mkLabel(g, "OK when it looks like that · << >> pick who", 24, 122, 20, m.C.dim)
        end if
    end for
end sub

' ---------- chores ----------

sub buildChores()
    root = m.screenRoot
    ni = nowInfo()
    mkLabel(root, "THE CHORE CHART — EVERYONE OWNS A ZONE", 56, 84, 42, m.C.text)
    mkLabel(root, "Zones rotate every Monday. Three jobs each. Missed chores roll to the next reset, never a punishment cleanup.", 56, 140, 26, m.C.dim)
    mkRect(root, 56, 196, 880, 452, m.C.panel)
    mkLabel(root, "THE 3-WEEK ROTATION", 84, 214, 28, m.C.yellow)
    emZ = ["Dining Room", "Kitchen", "Living Room"]
    mxZ = ["Kitchen", "Living Room", "Dining Room"]
    anZ = ["Living Room", "Dining Room", "Kitchen"]
    heads = ["WEEK", "EMILY", "MAX", "ANTHONY"]
    colW = [150, 235, 235, 235]
    x = 84
    for i = 0 to 3
        mkLabel(root, heads[i], x, 262, 24, m.C.dim)
        x = x + colW[i]
    end for
    for w = 0 to 2
        y = 306 + w * 64
        if w = ni.weekIdx then mkRect(root, 76, y - 6, 840, 54, "0x1D2A55FF")
        wk = "Week " + (w + 1).toStr()
        if w = ni.weekIdx then wk = wk + " · now"
        mkLabel(root, wk, 84, y, 26, m.C.text)
        mkLabel(root, emZ[w], 234, y, 26, m.C.text)
        mkLabel(root, mxZ[w], 469, y, 26, m.C.text)
        mkLabel(root, anZ[w], 704, y, 26, m.C.text)
    end for
    mkLabel(root, "EVERY DAY, EVERYONE:", 84, 522, 26, m.C.yellow)
    mkLabel(root, "Clear your plate · shoes on the shelf · laundry in the hamper · 5-minute tidy before bed", 84, 560, 25, m.C.text)
    jobs = [
        { zone: "KITCHEN", lines: ["1 · Wipe down the fridge, microwave, dishwasher, and oven", "2 · Load or unload the dishwasher — and take the kitchen trash out if it is full", "3 · Sweep the kitchen floor"] },
        { zone: "LIVING ROOM", lines: ["1 · Tidy: blankets folded, coffee table clear", "2 · Entryway check: shoes, backpacks, boxes", "3 · Sweep the living room floor"] },
        { zone: "DINING ROOM", lines: ["1 · Chairs in + placemats straight — or wipe the table when there are none", "2 · Clear the table bare except the flowers", "3 · Sweep the dining floor"] }
    ]
    for i = 0 to 2
        y = 196 + i * 162
        mkRect(root, 968, y, 896, 146, m.C.panel)
        mkLabel(root, jobs[i].zone, 996, y + 14, 28, m.C.blue)
        for li = 0 to 2
            mkLabel(root, jobs[i].lines[li], 996, y + 56 + li * 30, 24, m.C.text)
        end for
    end for
    mkRect(root, 56, 680, 880, 320, m.C.panel)
    mkLabel(root, "THE WEEKEND", 84, 698, 28, m.C.yellow)
    mkLabelW(root, "Saturday morning is Deep Clean: the twelve zones, one at a time, 20 minutes each, on the Reset page. Sunday is rest, plus ten minutes to empty the family inbox basket by the front door.", 84, 744, 824, 27, m.C.text, "left")
    mkRect(root, 968, 680, 896, 320, m.C.panel)
    mkLabel(root, "START WITH THE BASKET", 996, 698, 28, m.C.yellow)
    mkLabelW(root, "Everything with no home lands in the family inbox basket by the front door. If you do not know where something goes, it goes in the basket, not on a counter.", 996, 744, 840, 27, m.C.text, "left")
end sub

' ---------- crew ----------

sub buildCrew()
    root = m.screenRoot
    ni = nowInfo()
    checks = todayChecks()
    reminded = todayReminded()
    mkLabel(root, "AFTER DINNER CREW — TONIGHT", 56, 84, 44, m.C.text)
    mkLabel(root, "Three jobs, three kids, every night. The jobs move each night, so nobody gets stuck with the same one.", 56, 140, 26, m.C.dim)
    jobs = [
        { id: "crewFood", key: "food", title: "PUT AWAY FOOD", desc: "Leftovers into containers, containers into the fridge. Nothing lives on the counter overnight." },
        { id: "crewWipe", key: "wipe", title: "WIPE IT DOWN", desc: "Table, stove, and countertops wiped. The kitchen you leave is the kitchen you get tomorrow." },
        { id: "crewSweep", key: "sweep", title: "SWEEP / SWIFFER", desc: "Dining room and kitchen floors, swept or Swiffered. Chairs back where they belong." }
    ]
    colX = [56, 664, 1272]
    for i = 0 to 2
        j = jobs[i]
        owner = crewOwner(j.key, ni.nightIdx)
        baseOwner = owner
        if m.state.reassign.doesExist(j.id) then owner = m.state.reassign[j.id]
        done = checks.doesExist(j.id)
        bgc = m.C.panel
        if done then bgc = m.C.rowDone
        item = addItem(root, "chore", j.id, i, 0, colX[i], 196, 592, 420, bgc)
        item.owner = owner
        item.baseOwner = baseOwner
        item.cat = "dinner"
        item.blockStart = 17
        g = item.node
        mkLabelW(g, j.title, 28, 22, 536, 34, m.C.yellow, "center")
        drawProfileAvatarFace(g, owner, 221, 78, 150)
        mkLabelW(g, personName(owner), 28, 240, 536, 40, m.C.text, "center")
        mkLabelW(g, j.desc, 40, 292, 512, 24, m.C.dim, "center")
        if done then
            rec = checks[j.id]
            if rec.doesExist("bonus") and rec.bonus > 0 then
                mkLabelW(g, "DONE +" + rec.pts.toStr() + " · NO-ASK BONUS", 28, 366, 536, 28, m.C.green, "center")
            else
                mkLabelW(g, "DONE +" + rec.pts.toStr(), 28, 366, 536, 30, m.C.green, "center")
            end if
        else if reminded.doesExist(j.id) then
            mkLabelW(g, "REMINDED · NO NO-ASK BONUS", 28, 366, 536, 26, m.C.gold, "center")
        end if
    end for
    mkLabel(root, "HOW THE JOBS MOVE", 56, 656, 28, m.C.yellow)
    heads = ["", "PUT AWAY FOOD", "WIPE IT DOWN", "SWEEP / SWIFFER"]
    colW = [220, 380, 380, 380]
    x = 56
    for i = 0 to 3
        mkLabel(root, heads[i], x, 700, 24, m.C.dim)
        x = x + colW[i]
    end for
    for n = 0 to 2
        y = 744 + n * 58
        if n = ni.nightIdx then mkRect(root, 48, y - 6, 1420, 50, "0x1D2A55FF")
        nl = "Night " + (n + 1).toStr()
        if n = ni.nightIdx then nl = nl + " · tonight"
        mkLabel(root, nl, 56, y, 26, m.C.text)
        mkLabel(root, personName(crewOwner("food", n)), 276, y, 26, m.C.text)
        mkLabel(root, personName(crewOwner("wipe", n)), 656, y, 26, m.C.text)
        mkLabel(root, personName(crewOwner("sweep", n)), 1036, y, 26, m.C.text)
    end for
    mkLabel(root, "Trash and recycling rotate nightly among Emily, Max, and Anthony — see Today for tonight's assignments.", 56, 950, 26, m.C.blue)
end sub

' ---------- rhythm ----------

sub buildRhythm()
    root = m.screenRoot
    ni = nowInfo()
    mkLabel(root, "WEEKLY RHYTHM", 56, 84, 44, m.C.text)
    mkLabel(root, "The grown-up jobs: one small thing a day keeps the weekend free. Tap OK on today's row when it is done.", 56, 140, 26, m.C.dim)
    rows = [
        { day: "MONDAY", job: "Laundry catch-up: one extra load", owner: "parents" },
        { day: "TUESDAY", job: "Bathroom quick wipe (10 minutes)", owner: "parents" },
        { day: "WEDNESDAY", job: "Sweep the entryway and the laundry hallway", owner: "parents" },
        { day: "THURSDAY", job: "Fridge and pantry check: toss expired, do one shelf", owner: "parents" },
        { day: "FRIDAY", job: "Fresh sheets on the beds", owner: "parents" },
        { day: "SATURDAY", job: "20-minute family reset, a little deeper (Deep Clean)", owner: "crew" },
        { day: "SUNDAY", job: "Rest. Empty the family inbox basket (10 minutes)", owner: "parents" }
    ]
    todayIdx = (ni.dow + 6) mod 7
    checks = todayChecks()
    y = 196
    for i = 0 to 6
        r = rows[i]
        isToday = (i = todayIdx)
        bgc = m.C.panel
        if isToday then bgc = "0x1D2A55FF"
        if isToday and checks.doesExist("rhythm") then bgc = m.C.rowDone
        if isToday then
            item = addItem(root, "chore", "rhythm", 0, 0, 56, y, 1808, 84, bgc)
            item.owner = r.owner
            item.cat = "misc"
            item.blockStart = 0
            g = item.node
        else
            g = CreateObject("roSGNode", "Group")
            g.translation = [56, y]
            root.appendChild(g)
            mkRect(g, 0, 0, 1808, 84, bgc)
        end if
        mkLabel(g, r.day, 28, 24, 30, m.C.yellow)
        mkLabel(g, r.job, 330, 26, 28, m.C.text)
        if isToday and checks.doesExist("rhythm") then
            rec = checks["rhythm"]
            if rec.doesExist("bonus") and rec.bonus > 0 then
                mkLabelW(g, "DONE +" + rec.pts.toStr() + " · NO-ASK", 1450, 24, 320, 28, m.C.green, "right")
            else
                mkLabelW(g, "DONE +" + rec.pts.toStr(), 1450, 24, 320, 30, m.C.green, "right")
            end if
        else if isToday and isReminded("rhythm") then
            mkLabelW(g, "TODAY · REMINDED", 1450, 24, 320, 30, m.C.gold, "right")
        else if isToday then
            mkLabelW(g, "TODAY · " + personName(r.owner), 1450, 24, 320, 30, m.C.blue, "right")
        else
            mkLabelW(g, personName(r.owner), 1450, 24, 320, 30, m.C.dim, "right")
        end if
        y = y + 98
    end for
    mkLabel(root, "Trash and recycling rotate nightly: one kid takes trash, one takes recycling, and one rests. The week runs on this page; the day runs on Today.", 56, 920, 26, m.C.blue)
end sub

' ---------- one surface ----------

sub buildSurface()
    root = m.screenRoot
    mkLabelW(root, "WHEN THE HOUSE FEELS LIKE TOO MUCH", 460, 150, 1000, 30, m.C.blue, "center")
    mkLabelW(root, "ONE SURFACE", 460, 196, 1000, 76, m.C.text, "center")
    mkLabelW(root, "Pick ONE surface — the table, the bar, one counter. Set the timer. Race it.", 360, 300, 1200, 30, m.C.dim, "center")
    item = addItem(root, "timer", "surface", 0, 0, 560, 380, 800, 320, m.C.panel)
    g = item.node
    tl = mkLabelW(g, fmtTime(m.timers["surface"].left), 0, 56, 800, 170, m.C.text, "center")
    m.timerLabels["surface"] = tl
    st = mkLabelW(g, "", 0, 246, 800, 30, m.C.gold, "center")
    m.timerStates["surface"] = st
    refreshTimerStates()
    mkLabelW(root, "Everything on that surface gets a home, the basket, or the trash. Nothing migrates to another surface.", 360, 748, 1200, 28, m.C.text, "center")
    mkLabelW(root, "When the timer sings, stop. Done or not, the loop is broken.", 360, 792, 1200, 28, m.C.green, "center")
end sub
