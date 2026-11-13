' ================= Family Music =================

function musicStations() as Object
    return [
        { id: "theme", name: "Our House Theme", detail: "The familiar family soundtrack", url: "", backup: "", group: "HOME", color: "0xE8B93CFF" },
        { id: "chill", name: "Lofi & Chill", detail: "Groove Salad · ambient downtempo", url: "https://ice5.somafm.com/groovesalad-128-mp3", backup: "https://ice2.somafm.com/groovesalad-128-mp3", group: "CHILL", color: "0x68D6C4FF" },
        { id: "smoothjazz", name: "Smooth Jazz", detail: "181.FM The Breeze", url: "https://listen.181fm.com/181-breeze_128k.mp3", backup: "", group: "JAZZ", color: "0xA98BFFFF" },
        { id: "ambient", name: "Deep Ambient", detail: "Drone Zone · quiet atmospheric music", url: "https://ice5.somafm.com/dronezone-128-mp3", backup: "https://ice2.somafm.com/dronezone-128-mp3", group: "AMBIENT", color: "0x69A7E8FF" },
        { id: "classical", name: "Classical & Chamber", detail: "Orchestral, ensemble and chamber works", url: "https://listen.181fm.com/181-classical_128k.mp3", backup: "", group: "CLASSICAL", color: "0xE8C98BFF" },
        { id: "classicalguitar", name: "Classical Guitar", detail: "Quiet acoustic classical selections", url: "https://listen.181fm.com/181-classicalguitar_128k.mp3", backup: "", group: "CLASSICAL", color: "0xD9A86CFF" },
        { id: "classichits", name: "Classic Hits", detail: "Familiar favorites across the decades", url: "https://listen.181fm.com/181-greatoldies_128k.mp3", backup: "", group: "HITS", color: "0xF08CA8FF" },
        { id: "christmas", name: "Traditional Christmas", detail: "Seasonal standards and carols", url: "https://listen.181fm.com/181-xtraditional_128k.mp3", backup: "", group: "HOLIDAY", color: "0xD94747FF" },
        { id: "christmassmooth", name: "Christmas Smooth Jazz", detail: "A relaxed seasonal jazz mix", url: "https://listen.181fm.com/181-xsmooth_128k.mp3", backup: "", group: "HOLIDAY", color: "0x3FA66CFF" },
        { id: "off", name: "Music Off", detail: "Stop music and enjoy a quiet room", url: "", backup: "", group: "OFF", color: "0x71809BFF" }
    ]
end function

function musicStationById(id as String) as Dynamic
    stations = musicStations()
    for each station in stations
        if station.id = id then return station
    end for
    return invalid
end function

function musicModeName(id as String) as String
    station = musicStationById(id)
    if station = invalid then return "Our House Theme"
    return station.name
end function

function musicModeIsLive(id as String) as Boolean
    station = musicStationById(id)
    if station = invalid then return false
    return station.url <> ""
end function

sub setMusicMode(id as String)
    station = musicStationById(id)
    if station = invalid then return
    m.state.musicMode = id
    m.state.muted = id = "off"
    m.musicTriedBackup = false
    applyMusicMode()
    saveState()
    showToast("Music: " + station.name)
    if m.screen = "music" then rebuildScreen() else buildMenu()
end sub

function musicPlaybackState() as String
    if m.state.musicMode = "off" then return "OFF"
    if m.music = invalid then return "READY"
    if m.music.state = "playing" then return "PLAYING"
    if m.music.state = "buffering" then return "CONNECTING"
    if m.music.state = "paused" then return "PAUSED"
    return "STARTING"
end function

sub buildMusic()
    root = m.screenRoot
    ni = nowInfo()
    theme = monthTheme(ni.month)
    surface = monthSurfaceTheme(ni.month)
    drawSeasonalHub(root, ni.month)

    mkLabel(root, "FAMILY MUSIC", 56, 84, 46, m.C.text)
    mkLabelW(root, "Everyone can change the station · no Admin PIN needed", 760, 102, 1104, 24, m.C.dim, "right")

    active = musicStationById(m.state.musicMode)
    if active = invalid then active = musicStationById("theme")
    mkRect(root, 56, 152, 1808, 104, surface.panel)
    mkRect(root, 56, 152, 10, 104, active.color)
    mkLabel(root, "NOW " + musicPlaybackState(), 88, 172, 20, active.color)
    mkLabel(root, active.name, 88, 202, 34, m.C.text)
    mkLabelW(root, active.detail, 780, 194, 1040, 25, m.C.dim, "right")

    stations = musicStations()
    cardW = 580
    cardH = 158
    gapX = 34
    gapY = 18
    startY = 286
    for i = 0 to stations.count() - 1
        station = stations[i]
        col = i mod 3
        row = i \ 3
        x = 56 + (col * (cardW + gapX))
        y = startY + (row * (cardH + gapY))
        bg = surface.panel
        if station.id = m.state.musicMode then bg = surface.row
        tile = addItem(root, "musicstation", station.id, col, row, x, y, cardW, cardH, bg)
        mkRect(tile.node, 0, 0, 8, cardH, station.color)
        mkLabel(tile.node, station.group, 26, 18, 18, station.color)
        mkLabelW(tile.node, station.name, 26, 50, cardW - 52, 34, m.C.text, "left")
        detail = mkLabelW(tile.node, station.detail, 26, 94, cardW - 52, 23, m.C.dim, "left")
        detail.wrap = false
        detail.ellipsizeOnBoundary = true
        action = "OK TO PLAY"
        if station.id = m.state.musicMode then action = "● " + musicPlaybackState()
        mkLabelW(tile.node, action, 26, 128, cardW - 52, 19, station.color, "right")
    end for

    mkLabelW(root, "Live stations require internet. If a station is unavailable, the app safely returns to the Our House Theme.", 56, 1016, 1808, 20, theme.a, "center")
end sub
