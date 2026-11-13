' ================= House schedule (pkg:/config/house.json) =================
' Who does what, and when, lives in config/house.json instead of in code.
' The file is checked on launch. If it has a problem, the app still runs with
' an empty schedule and says exactly what is wrong on Admin > System Health.

function houseConfigPath() as String
    return "pkg:/config/house.json"
end function

' Everyone a chore can belong to. Names and faces for these live in MainScene.
function houseOwnerKeys() as Object
    return ["emily", "max", "anthony", "patricia", "nick", "nicky", "parents", "everyone", "crew", "house"]
end function

' Point categories understood by the game (badges are built on these).
function houseCategories() as Object
    return ["misc", "laundry", "dinner", "trash", "zones"]
end function

sub loadHouseConfig()
    m.houseConfigError = ""
    cfg = invalid
    raw = ReadAsciiFile(houseConfigPath())
    if raw = invalid or raw = "" then
        m.houseConfigError = "config/house.json is missing from the package"
    else
        cfg = ParseJSON(raw)
        if cfg = invalid then m.houseConfigError = "config/house.json is not valid JSON (check commas and quotes)"
    end if
    if m.houseConfigError = "" then m.houseConfigError = validateHouseConfig(cfg)
    if m.houseConfigError <> "" then cfg = emptyHouseConfig()
    m.house = cfg
end sub

' A schedule with no chores, used when the file cannot be used. Every screen
' still draws; the Today headings point people to System Health.
function emptyHouseConfig() as Object
    return {
        version: 1,
        rotations: {},
        today: {
            morning: { title: "CHORE SCHEDULE NEEDS FIXING", start: 0, rows: [] },
            afterSchool: { title: "SEE ADMIN > SYSTEM HEALTH", start: 0, rows: [] },
            evening: { title: "", start: 0, rows: [] }
        },
        laundryNote: "",
        zoneNames: {},
        zoneJobs: [],
        chart: { subtitle: "The chore schedule file has a problem. Admin > System Health says what to fix.", everyDay: "", weekendTitle: "", weekend: "", noteTitle: "", note: "" },
        crewJobs: [],
        rhythm: [],
        resetZones: []
    }
end function

' ---------- rotations ----------

' Which turn of a rotation is active on a given day number (days since
' 1970-01-01, as nowInfo().days). "day" rotations advance every day; "week"
' rotations advance on their startsOn day (default Thursday, the original rule).
function houseRotationIndex(name as String, days as Integer) as Integer
    rot = m.house.rotations[name]
    if rot = invalid then return 0
    n = rot.turns.count()
    if n = 0 then return 0
    if rot.every = "week" then return ((days + houseWeekShift(rot.startsOn)) \ 7) mod n
    return days mod n
end function

function houseRotationCount(name as String) as Integer
    rot = m.house.rotations[name]
    if rot = invalid then return 0
    return rot.turns.count()
end function

function houseRotationOwner(name as String, slot as String, turnIdx as Integer) as String
    rot = m.house.rotations[name]
    if rot = invalid then return "house"
    if turnIdx < 0 or turnIdx >= rot.turns.count() then return "house"
    v = rot.turns[turnIdx][slot]
    if v = invalid then return "house"
    return v
end function

function houseRotationOwnerToday(name as String, slot as String, days as Integer) as String
    return houseRotationOwner(name, slot, houseRotationIndex(name, days))
end function

' Day 0 (1970-01-01) was a Thursday, so weeks counted as days \ 7 begin on
' Thursday. Shifting the day number moves the boundary to startsOn.
function houseWeekShift(startsOn as Dynamic) as Integer
    d = 4
    if hcIsStr(startsOn) then d = hcDayIndex(startsOn)
    if d < 0 then d = 4
    return (4 - d + 7) mod 7
end function

function hcDayIndex(name as String) as Integer
    names = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
    lname = LCase(name)
    for i = 0 to names.count() - 1
        if names[i] = lname then return i
    end for
    return -1
end function

' Everyone who appears in a rotation: the kids first in their usual order,
' then anyone else in the order they first appear.
function houseRotationPeople(name as String) as Object
    return hcRotationPeople(m.house.rotations[name])
end function

function hcRotationPeople(rot as Dynamic) as Object
    out = []
    if rot = invalid then return out
    seen = {}
    others = []
    for each turn in rot.turns
        for each slot in turn
            v = turn[slot]
            if not seen.doesExist(v) then
                seen[v] = true
                others.push(v)
            end if
        end for
    end for
    for each k in m.kids
        if seen.doesExist(k) then out.push(k)
    end for
    for each v in others
        if not hcInList(v, m.kids) then out.push(v)
    end for
    return out
end function

' The slot (e.g. "kitchen") a person holds in a given turn, or "" if none.
function houseRotationSlotFor(name as String, turnIdx as Integer, person as String) as String
    rot = m.house.rotations[name]
    if rot = invalid then return ""
    if turnIdx < 0 or turnIdx >= rot.turns.count() then return ""
    turn = rot.turns[turnIdx]
    for each slot in turn
        if turn[slot] = person then return slot
    end for
    return ""
end function

' ---------- today ----------

' One Today block with owners resolved for the given day. Returns fresh rows,
' so callers may change them (todayChores applies reassignments).
function houseTodayBlock(b as Object, days as Integer) as Object
    rows = []
    for each r in b.rows
        owner = "house"
        if r.rotation <> invalid then
            owner = houseRotationOwnerToday(r.rotation, r.slot, days)
        else
            owner = r.owner
        end if
        start = b.start
        if r.start <> invalid then start = r.start
        rows.push({ id: r.id, text: r.text, owner: owner, cat: r.cat, start: start, checkable: true })
    end for
    return { title: b.title, rows: rows }
end function

function houseChoreCount() as Integer
    n = 0
    for each blockName in ["morning", "afterSchool", "evening", "saturday"]
        b = m.house.today[blockName]
        if b <> invalid then n = n + b.rows.count()
    end for
    return n
end function

function houseResetZoneCount() as Integer
    return m.house.resetZones.count()
end function

function houseZoneName(slot as String) as String
    v = m.house.zoneNames[slot]
    if v = invalid then return slot
    return v
end function

' 12 -> "twelve" (or "Twelve"), so screens keep reading naturally; digits past 20.
function houseCountWord(n as Integer, capitalized as Boolean) as String
    words = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen", "twenty"]
    if n < 0 or n >= words.count() then return n.toStr()
    w = words[n]
    if capitalized then w = UCase(Left(w, 1)) + Mid(w, 2)
    return w
end function

' "Emily", "Emily and Max", "Emily, Max, and Anthony"
function joinPersonNames(keys as Object) as String
    n = keys.count()
    if n = 0 then return ""
    if n = 1 then return personName(keys[0])
    if n = 2 then return personName(keys[0]) + " and " + personName(keys[1])
    txt = ""
    for i = 0 to n - 1
        if i = n - 1 then
            txt = txt + "and " + personName(keys[i])
        else
            txt = txt + personName(keys[i]) + ", "
        end if
    end for
    return txt
end function

' ---------- validation ----------
' Each check returns "" when fine, or one sentence naming the exact field.
' Values that are case-insensitive by nature (people, categories, days) are
' lower-cased in place so the rest of the app sees one spelling.

function hcIsStr(v as Dynamic) as Boolean
    t = Type(v)
    return t = "String" or t = "roString"
end function

function hcIsInt(v as Dynamic) as Boolean
    t = Type(v)
    return t = "Integer" or t = "roInt" or t = "roInteger" or t = "LongInteger" or t = "roLongInteger"
end function

function hcIsObj(v as Dynamic) as Boolean
    return Type(v) = "roAssociativeArray"
end function

function hcIsList(v as Dynamic) as Boolean
    return Type(v) = "roArray"
end function

function hcInList(v as String, list as Object) as Boolean
    for each x in list
        if x = v then return true
    end for
    return false
end function

function hcIsOwner(v as Dynamic) as Boolean
    if not hcIsStr(v) then return false
    return hcInList(LCase(v), houseOwnerKeys())
end function

function hcOwnerHelp() as String
    txt = ""
    keys = houseOwnerKeys()
    for i = 0 to keys.count() - 1
        if i > 0 then txt = txt + ", "
        txt = txt + keys[i]
    end for
    return txt
end function

function validateHouseConfig(cfg as Dynamic) as String
    if not hcIsObj(cfg) then return "config/house.json must hold one JSON object"
    if not hcIsInt(cfg.version) then return "version must be 1"
    if cfg.version <> 1 then return "version must be 1"

    rots = cfg.rotations
    if not hcIsObj(rots) then return "rotations is missing"
    for each name in rots
        err = hcCheckRotation(name, rots[name])
        if err <> "" then return err
    end for
    if rots.zones = invalid then return "rotations.zones is missing (the chore chart shows it)"
    if rots.crew = invalid then return "rotations.crew is missing (the Crew page shows it)"
    if rots.zones.turns.count() > 3 then return "rotations.zones has more than 3 turns; the chore chart fits 3"
    if rots.crew.turns.count() > 3 then return "rotations.crew has more than 3 turns; the Crew page fits 3"

    t = cfg.today
    if not hcIsObj(t) then return "today is missing"
    ids = {}
    blockNames = ["morning", "afterSchool", "evening", "saturday"]
    blockLimits = [4, 2, 8, 1]
    for bi = 0 to blockNames.count() - 1
        blockName = blockNames[bi]
        b = t[blockName]
        if b = invalid then
            if blockName <> "saturday" then return "today." + blockName + " is missing"
        else
            err = hcCheckBlock("today." + blockName, b, blockLimits[bi], rots, ids)
            if err <> "" then return err
        end if
    end for

    if not hcIsStr(cfg.laundryNote) then return "laundryNote must be text (use """" for none)"

    zn = cfg.zoneNames
    if not hcIsObj(zn) then return "zoneNames is missing"
    for each slot in zn
        if not hcIsStr(zn[slot]) then return "zoneNames." + slot + " must be text"
    end for
    for i = 0 to rots.zones.turns.count() - 1
        turn = rots.zones.turns[i]
        for each slot in turn
            if zn[slot] = invalid then return "rotations.zones uses """ + slot + """ but zoneNames has no name for it"
        end for
    end for
    if hcRotationPeople(rots.zones).count() > 3 then return "rotations.zones involves more than 3 people; the chore chart fits 3 columns"

    zj = cfg.zoneJobs
    if not hcIsList(zj) then return "zoneJobs must be a list"
    if zj.count() > 3 then return "zoneJobs has more than 3 zones; the chore chart fits 3"
    for i = 0 to zj.count() - 1
        p = "zoneJobs[" + i.toStr() + "]"
        z = zj[i]
        if not hcIsObj(z) then return p + " must be an object"
        if not hcIsStr(z.zone) then return p + ".zone must be text"
        if zn[z.zone] = invalid then return p + ".zone """ + z.zone + """ is not in zoneNames"
        if not hcIsList(z.lines) then return p + ".lines must be a list"
        if z.lines.count() > 3 then return p + ".lines has more than 3 jobs; the panel fits 3"
        for each line in z.lines
            if not hcIsStr(line) then return p + ".lines must all be text"
        end for
    end for

    ch = cfg.chart
    if not hcIsObj(ch) then return "chart is missing"
    for each field in ["subtitle", "everyDay", "weekendTitle", "weekend", "noteTitle", "note"]
        if not hcIsStr(ch[field]) then return "chart." + field + " must be text"
    end for

    cj = cfg.crewJobs
    if not hcIsList(cj) then return "crewJobs must be a list"
    if cj.count() > 3 then return "crewJobs has more than 3 jobs; the Crew page fits 3"
    for i = 0 to cj.count() - 1
        p = "crewJobs[" + i.toStr() + "]"
        j = cj[i]
        if not hcIsObj(j) then return p + " must be an object"
        for each field in ["id", "slot", "title", "desc"]
            if not hcIsStr(j[field]) then return p + "." + field + " must be text"
        end for
        for each turn in rots.crew.turns
            if turn[j.slot] = invalid then return p + ".slot """ + j.slot + """ is missing from a rotations.crew turn"
        end for
    end for

    rh = cfg.rhythm
    if not hcIsList(rh) then return "rhythm must be a list"
    if rh.count() <> 7 then return "rhythm needs exactly 7 days, Monday first"
    for i = 0 to 6
        p = "rhythm[" + i.toStr() + "]"
        r = rh[i]
        if not hcIsObj(r) then return p + " must be an object"
        if not hcIsStr(r.day) then return p + ".day must be text"
        if not hcIsStr(r.job) then return p + ".job must be text"
        if not hcIsOwner(r.owner) then return p + ".owner must be one of: " + hcOwnerHelp()
        r.owner = LCase(r.owner)
    end for

    rz = cfg.resetZones
    if not hcIsList(rz) then return "resetZones must be a list"
    if rz.count() = 0 then return "resetZones needs at least one zone"
    if rz.count() > 12 then return "resetZones has more than 12 zones; the Reset page fits 12"
    for i = 0 to rz.count() - 1
        p = "resetZones[" + i.toStr() + "]"
        z = rz[i]
        if not hcIsObj(z) then return p + " must be an object"
        if not hcIsStr(z.name) then return p + ".name must be text"
        if not hcIsStr(z.done) then return p + ".done must be text"
    end for
    return ""
end function

function hcCheckRotation(name as String, rot as Dynamic) as String
    p = "rotations." + name
    if not hcIsObj(rot) then return p + " must be an object"
    if not hcIsStr(rot.every) then return p + ".every must be ""day"" or ""week"""
    rot.every = LCase(rot.every)
    if rot.every <> "day" and rot.every <> "week" then return p + ".every must be ""day"" or ""week"""
    if rot.startsOn <> invalid then
        if not hcIsStr(rot.startsOn) then return p + ".startsOn must be a day name such as ""monday"""
        if hcDayIndex(rot.startsOn) < 0 then return p + ".startsOn must be a day name such as ""monday"""
        rot.startsOn = LCase(rot.startsOn)
    end if
    if not hcIsList(rot.turns) then return p + ".turns must be a list"
    if rot.turns.count() = 0 then return p + ".turns needs at least one turn"
    for i = 0 to rot.turns.count() - 1
        turn = rot.turns[i]
        tp = p + ".turns[" + i.toStr() + "]"
        if not hcIsObj(turn) then return tp + " must be an object"
        for each slot in turn.Keys()
            if not hcIsOwner(turn[slot]) then return tp + "." + slot + " must be one of: " + hcOwnerHelp()
            turn[slot] = LCase(turn[slot])
        end for
    end for
    return ""
end function

function hcCheckBlock(p as String, b as Dynamic, maxRows as Integer, rots as Object, ids as Object) as String
    if not hcIsObj(b) then return p + " must be an object"
    if not hcIsStr(b.title) then return p + ".title must be text"
    if not hcIsInt(b.start) then return p + ".start must be an hour from 0 to 23"
    if b.start < 0 or b.start > 23 then return p + ".start must be an hour from 0 to 23"
    if not hcIsList(b.rows) then return p + ".rows must be a list"
    if b.rows.count() > maxRows then return p + " has " + b.rows.count().toStr() + " chores; the Today screen fits " + maxRows.toStr()
    for i = 0 to b.rows.count() - 1
        r = b.rows[i]
        rp = p + ".rows[" + i.toStr() + "]"
        if not hcIsObj(r) then return rp + " must be an object"
        if not hcIsStr(r.id) then return rp + ".id must be text"
        if r.id = "" then return rp + ".id must not be empty"
        if LCase(r.id) = "rhythm" then return rp + ": id ""rhythm"" is reserved for the Rhythm page"
        if ids.doesExist(r.id) then return rp + ": id """ + r.id + """ is already used"
        ids[r.id] = true
        if not hcIsStr(r.text) then return rp + ".text must be text"
        if not hcIsStr(r.cat) then return rp + ".cat must be one of: misc, laundry, dinner, trash, zones"
        r.cat = LCase(r.cat)
        if not hcInList(r.cat, houseCategories()) then return rp + ".cat must be one of: misc, laundry, dinner, trash, zones"
        if r.start <> invalid then
            if not hcIsInt(r.start) then return rp + ".start must be an hour from 0 to 23"
            if r.start < 0 or r.start > 23 then return rp + ".start must be an hour from 0 to 23"
        end if
        if r.rotation <> invalid then
            if not hcIsStr(r.rotation) then return rp + ".rotation must be text"
            if rots[r.rotation] = invalid then return rp + ".rotation """ + r.rotation + """ is not in rotations"
            if not hcIsStr(r.slot) then return rp + ".slot must be text"
            for each turn in rots[r.rotation].turns
                if turn[r.slot] = invalid then return rp + ": a rotations." + r.rotation + " turn has no """ + r.slot + """"
            end for
        else
            if not hcIsOwner(r.owner) then return rp + " needs an owner (one of: " + hcOwnerHelp() + ") or a rotation and slot"
            r.owner = LCase(r.owner)
        end if
    end for
    return ""
end function
