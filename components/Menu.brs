' ================= Top menu =================
' Six tabs instead of thirteen. "Chores" and "Fun" are groups: choosing one
' opens the page you used last in it, and while you are on one of its pages
' the group's pages are shown beside it so you can hop between them.

function menuGroups() as Object
    return [
        { label: "Today", key: "hub" },
        { label: "Calendar", key: "calendar" },
        { label: "Meals", key: "family" },
        { label: "Chores", id: "chores", pages: [
            { label: "Reset", key: "reset" },
            { label: "Chart", key: "chores" },
            { label: "Crew", key: "crew" },
            { label: "Rhythm", key: "rhythm" },
            { label: "One Surface", key: "surface" }
        ] },
        { label: "Fun", id: "fun", pages: [
            { label: "Game", key: "game" },
            { label: "Avatar", key: "avatar" },
            { label: "Shop", key: "shop" },
            { label: "Music", key: "music" }
        ] },
        { label: "Admin", key: "admin" }
    ]
end function

' Screens opened from inside a page keep that page lit in the menu.
function menuParentScreen(key as String) as String
    if key = "levels" then return "game"
    if key = "inventory" then return "avatar"
    if key = "confirmbuy" then return "shop"
    if key = "mealplanner" then return "family"
    if key = "pinpick" or key = "diagnostics" then return "admin"
    return key
end function

' The group id holding a screen ("" for a plain tab), or invalid when the
' screen is not in the menu (PIN pad, ambient) so the menu is left as it was.
function menuGroupForScreen(key as String) as Dynamic
    for each g in m.menuGroupDefs
        if g.pages = invalid then
            if g.key = key then return ""
        else
            for each p in g.pages
                if p.key = key then return g.id
            end for
        end if
    end for
    return invalid
end function

sub initMenu()
    m.menuGroupDefs = menuGroups()
    m.menuGroupOpen = ""
    m.menuGroupLast = {}
    rebuildMenuDefs()
end sub

' m.menuDefs is the flat row of entries the remote walks with left/right.
' Each entry's key is the screen OK opens; a group entry opens its last page.
sub rebuildMenuDefs()
    defs = []
    for each g in m.menuGroupDefs
        if g.pages = invalid then
            defs.push({ label: g.label, key: g.key, kind: "tab", group: "" })
        else
            target = m.menuGroupLast[g.id]
            if target = invalid then target = g.pages[0].key
            defs.push({ label: g.label, key: target, kind: "group", group: g.id })
            if m.menuGroupOpen = g.id then
                for each p in g.pages
                    defs.push({ label: p.label, key: p.key, kind: "page", group: g.id })
                end for
            end if
        end if
    end for
    m.menuDefs = defs
    if m.menuIdx >= defs.count() then m.menuIdx = defs.count() - 1
    if m.menuIdx < 0 then m.menuIdx = 0
end sub

' Called by showScreen: opens the right group and points the menu at the page.
sub syncMenuToScreen(key as String)
    navKey = menuParentScreen(key)
    gid = menuGroupForScreen(navKey)
    if gid = invalid then return
    m.menuGroupOpen = gid
    if gid <> "" then m.menuGroupLast[gid] = navKey
    rebuildMenuDefs()
    for i = 0 to m.menuDefs.count() - 1
        d = m.menuDefs[i]
        if d.kind <> "group" and d.key = navKey then m.menuIdx = i
    end for
end sub

function menuTabWidth(label as String) as Integer
    w = len(label) * 12 + 28
    if w < 88 then w = 88
    return w
end function

sub buildMenu()
    while m.menuBar.getChildCount() > 0
        m.menuBar.removeChildIndex(0)
    end while
    mkRect(m.menuBar, 0, 0, 1920, 62, "0x0E1533FF")
    m.menuNodes = []
    navKey = menuParentScreen(m.screen)
    ' Lay out first so the strip behind an open group's pages can go underneath.
    xs = []
    ws = []
    x = 30
    stripX0 = -1
    stripX1 = -1
    for i = 0 to m.menuDefs.count() - 1
        d = m.menuDefs[i]
        w = menuTabWidth(d.label)
        xs.push(x)
        ws.push(w)
        if d.kind = "page" then
            if stripX0 < 0 then stripX0 = x - 8
            stripX1 = x + w + 8
        end if
        x = x + w + 10
    end for
    if stripX0 >= 0 then mkRect(m.menuBar, stripX0, 4, stripX1 - stripX0, 54, "0x18234EFF")
    for i = 0 to m.menuDefs.count() - 1
        d = m.menuDefs[i]
        bgc = "0x00000000"
        tc = m.C.dim
        size = 22
        if d.kind = "page" then size = 20
        current = false
        if d.kind = "group" then
            current = (m.menuGroupOpen = d.group)
        else
            current = (d.key = navKey)
        end if
        if current then
            bgc = "0x1D2A55FF"
            tc = m.C.text
        end if
        if m.area = "menu" and m.menuIdx = i then
            bgc = m.C.accent
            tc = m.C.text
        end if
        r = mkRect(m.menuBar, xs[i], 8, ws[i], 46, bgc)
        l = mkLabel(m.menuBar, d.label, xs[i], 31 - (size \ 2) - 2, size, tc)
        l.width = ws[i]
        l.horizAlign = "center"
        m.menuNodes.push(r)
    end for
    statusPrefix = "VIEWER"
    statusColor = m.C.dim
    if m.admin then
        statusPrefix = "ADMIN"
        statusColor = m.C.gold
    end if
    mkLabelW(m.menuBar, statusPrefix + " · " + musicModeName(m.state.musicMode), 1420, 20, 455, 20, statusColor, "right")
end sub
