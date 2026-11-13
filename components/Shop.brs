' ================= C-Bucks, avatars and the shop =================
' Money is stored in whole cents (500 = C$5). Avatars are stored as a small
' settings object (ids only), so a website can later draw and edit the same one.

function profileKeys() as Object
    return ["emily", "max", "anthony", "patricia", "nick", "nicky"]
end function

' ---------- earning rules ----------

' Full rate when nobody had to remind them, half rate when they were reminded.
function cbRate(reminded as Boolean) as Integer
    if reminded then return 250
    return 500
end function

function walletKeys(owner as String) as Object
    if owner = "everyone" or owner = "crew" or owner = "house" then return []
    if left(owner, 5) = "pair:" then
        parts = owner.split(",")
        return [parts[0].mid(5), parts[1]]
    end if
    if owner = "parents" then return ["patricia", "nick"]
    return [owner]
end function

sub payCb(owner as String, cents as Integer)
    for each k in walletKeys(owner)
        if m.state.cb.doesExist(k) then
            m.state.cb[k] = m.state.cb[k] + cents
        end if
    end for
end sub

sub cbToast(owner as String, cents as Integer)
    keys = walletKeys(owner)
    if keys.count() = 0 then return
    who = personName(keys[0])
    if keys.count() > 1 then who = who + " + " + personName(keys[1])
    showToast("+" + fmtCb(cents) + " C-Bucks for " + who)
end sub

function zoneRecCb(rec as Object) as Integer
    if rec <> invalid and Type(rec) = "roAssociativeArray" and rec.cb <> invalid then return rec.cb
    return 0
end function

function fmtCb(c as Integer) as String
    neg = ""
    v = c
    if v < 0 then
        neg = "-"
        v = -v
    end if
    d = v \ 100
    r = v mod 100
    s = neg + "C$" + d.toStr()
    if r <> 0 then s = s + "." + pad2(r)
    return s
end function

sub adjustWallet(k as String, delta as Integer)
    if not m.state.cb.doesExist(k) then return
    m.state.cb[k] = m.state.cb[k] + delta
    saveState()
    showToast(personName(k) + " now has " + fmtCb(m.state.cb[k]))
    rebuildScreen()
end sub

function bonusPointBucket(k as String) as String
    if k = "patricia" or k = "nick" then return "parents"
    return k
end function

function bonusPointTotal(k as String) as Integer
    bucket = bonusPointBucket(k)
    if not m.state.points.doesExist(bucket) then return 0
    return m.state.points[bucket]
end function

sub adjustBonusPoint(k as String, delta as Integer)
    ensureWeek()
    bucket = bonusPointBucket(k)
    if not m.state.points.doesExist(bucket) or not m.state.week.points.doesExist(bucket) then return
    oldTotal = m.state.points[bucket]
    newTotal = oldTotal + delta
    if newTotal < 0 then newTotal = 0
    applied = newTotal - oldTotal
    m.state.points[bucket] = newTotal
    newWeek = m.state.week.points[bucket] + applied
    if newWeek < 0 then newWeek = 0
    m.state.week.points[bucket] = newWeek
    saveState()
    who = personName(k)
    if bucket = "parents" then who = "Trish + Nick"
    if applied > 0 then
        showToast("+1 bonus point for " + who)
    else if applied < 0 then
        showToast("Removed 1 bonus point from " + who)
    else
        showToast(who + " already has 0 points")
    end if
    rebuildScreen()
end sub

' ---------- palettes ----------

function skinColors() as Object
    return ["0xFFDBB4FF", "0xF1C27DFF", "0xE0AC69FF", "0xC68642FF", "0x8D5524FF", "0x5C3A21FF", "0x64B446FF"]
end function

function skinColorNames() as Object
    return ["Porcelain", "Warm", "Golden", "Bronze", "Deep", "Espresso", "Gamma Green"]
end function

function hairColors() as Object
    return ["0x2B1B12FF", "0x6B3E1FFF", "0xC8A15AFF", "0xB5381EFF", "0x1C1C1CFF", "0xD9D9D9FF"]
end function

function hairColorNames() as Object
    return ["Espresso", "Brown", "Blonde", "Ginger", "Black", "Silver"]
end function

function eyeColors() as Object
    return ["0x26324AFF", "0x4B2E1FFF", "0x2F6B9AFF", "0x3D7A55FF", "0x6B5538FF", "0x2B2B2BFF"]
end function

function eyeColorNames() as Object
    return ["Slate", "Brown", "Blue", "Green", "Hazel", "Dark"]
end function

function petColorNames() as Object
    return ["Natural", "Chocolate", "Snow", "Midnight", "Fantasy"]
end function

' ---------- catalog ----------

function mkI(id as String, cat as String, name as String, price as Integer) as Object
    return { id: id, cat: cat, name: name, price: price, tab: "" }
end function

function mkS(id as String, cat as String, name as String, price as Integer) as Object
    it = mkI(id, cat, name, price)
    it.tab = "season"
    return it
end function

function mkT(id as String, name as String, price as Integer, topC as String, trimC as String, style as String) as Object
    sleeves = "short"
    if style = "basket" then sleeves = "tank"
    return { id: id, cat: "top", name: name, price: price, top: topC, trim: trimC, style: style, sleeves: sleeves, tab: "sports" }
end function

function mkB(id as String, name as String, price as Integer, botC as String, trimC as String) as Object
    return { id: id, cat: "bottom", name: name, price: price, bottom: botC, trim: trimC, shorts: false, tab: "sports" }
end function

function mkBB(id as String, name as String, price as Integer, botC as String, trimC as String) as Object
    return { id: id, cat: "bottom", name: name, price: price, bottom: botC, trim: trimC, shorts: true, tab: "sports" }
end function

function mkO(id as String, name as String, price as Integer, topC as String, botC as String, trimC as String, style as String, sleeves as String, robe as Boolean) as Object
    return { id: id, cat: "outfit", name: name, price: price, top: topC, bottom: botC, trim: trimC, style: style, sleeves: sleeves, robe: robe, tab: "" }
end function

function catalog() as Object
    if m.catList <> invalid then return m.catList
    c = []
    ' outfits: free tees first
    c.push(mkO("o_blue", "Blue Tee", 0, "0x2F6BFFFF", "0x34425FFF", "0x000000FF", "none", "short", false))
    c.push(mkO("o_red", "Red Tee", 0, "0xD6322EFF", "0x34425FFF", "0x000000FF", "none", "short", false))
    c.push(mkO("o_green", "Green Tee", 0, "0x3FAE5AFF", "0x34425FFF", "0x000000FF", "none", "short", false))
    c.push(mkO("o_purple", "Purple Tee", 0, "0x8A55D6FF", "0x34425FFF", "0x000000FF", "none", "short", false))
    c.push(mkO("o_yellow", "Yellow Tee", 0, "0xF2C230FF", "0x34425FFF", "0x000000FF", "none", "short", false))
    ' Additive illustrated pilot items. Existing outfit ids and ownership stay intact.
    c.push(mkO("o_pilot_child_blue", "Illustrated Pilot: Child Blue", 0, "0x355B91FF", "0xB59B72FF", "0xF3E5C7FF", "pilot", "long", false))
    c.push(mkO("o_pilot_preteen_purple", "Illustrated Pilot: Preteen Purple", 0, "0x9B70C7FF", "0x34313FFF", "0xFFFFFFFF", "pilot", "long", false))
    c.push(mkO("o_pilot_adult_green", "Illustrated Pilot: Adult Green", 0, "0x4A5635FF", "0x28344CFF", "0xE8E5DEFF", "pilot", "long", false))
    ' outfits: shop
    c.push(mkO("o_hoodie", "Red Hoodie", 2000, "0xC0283CFF", "0x3A3A44FF", "0xFFFFFFFF", "stripe", "long", false))
    c.push(mkO("o_soccer", "Soccer Kit", 2500, "0xFFFFFFFF", "0x1F8F4AFF", "0x1F8F4AFF", "vstripe", "short", false))
    c.push(mkO("o_overalls", "Overalls", 2500, "0xF2C230FF", "0x2F5FA8FF", "0x2F5FA8FF", "emblem", "long", false))
    c.push(mkO("o_pirate", "Pirate Shirt", 3500, "0xF2F2F2FF", "0x1E1E24FF", "0xC0283CFF", "stripe", "long", false))
    c.push(mkO("o_ninja", "Ninja Suit", 3500, "0x1E1E24FF", "0x1E1E24FF", "0xC0283CFF", "emblem", "long", false))
    c.push(mkO("o_hero", "Superhero", 4000, "0x2F6BFFFF", "0xC0283CFF", "0xFFD97EFF", "emblem", "long", false))
    c.push(mkO("o_space", "Astronaut", 4500, "0xEDEFF5FF", "0xEDEFF5FF", "0x2F6BFFFF", "emblem", "long", false))
    c.push(mkO("o_robe", "Wizard Robe", 5000, "0x5B3FA8FF", "0x5B3FA8FF", "0xFFD97EFF", "stripe", "long", true))
    c.push(mkO("o_arcarmor", "Red-Gold Tech Armor", 6000, "0xB21F2DFF", "0x8D1722FF", "0xE8B93CFF", "armor", "long", false))
    c.push(mkO("o_doomarmor", "Emerald Sovereign Armor", 6000, "0x1F6B45FF", "0x183D2CFF", "0xC9D0DAFF", "armor", "long", true))
    c.push(mkO("o_ultron", "Ultron-Inspired Machine Skin", 7000, "0x4B535FFF", "0x252B35FF", "0xD51F3CFF", "armor", "long", false))
    c.push(mkO("o_starcaptain", "Star Sentinel", 6000, "0x244C9AFF", "0x244C9AFF", "0xFFFFFFFF", "armor", "long", false))
    c.push(mkO("o_webhero", "Red-Blue Web Hero", 6000, "0xC6283BFF", "0x214D9AFF", "0x17213BFF", "web", "long", false))
    c.push(mkO("o_jeans_white", "Denim: White Tee", 1800, "0xFFFFFFFF", "0x7FA3D1FF", "0x000000FF", "none", "short", false))
    c.push(mkO("o_jeans_pink", "Denim: Pink Tee", 1800, "0xF59AB8FF", "0x7FA3D1FF", "0x000000FF", "none", "short", false))
    c.push(mkO("o_jeans_mint", "Denim: Mint Tee", 1800, "0x7EDDB8FF", "0x3F5F94FF", "0x000000FF", "none", "short", false))
    c.push(mkO("o_jeans_sun", "Denim: Yellow Tee", 1800, "0xFFD24AFF", "0x3F5F94FF", "0x000000FF", "none", "short", false))
    ' football (school colors only, no logos) and cheer
    fb = mkO("o_um_orange", "Miami Orange", 4500, "0xF47321FF", "0xF4F4F4FF", "0x005030FF", "jersey", "short", false)
    fb.tab = "sports"
    c.push(fb)
    fb = mkO("o_um_green", "Miami Green", 4500, "0x005030FF", "0x005030FF", "0xF47321FF", "jersey", "short", false)
    fb.tab = "sports"
    c.push(fb)
    fb = mkO("o_um_white", "Miami White", 4500, "0xFFFFFFFF", "0xF47321FF", "0x005030FF", "jersey", "short", false)
    fb.tab = "sports"
    c.push(fb)
    c.push(mkT("t_none", "Outfit's own top", 0, "0x000000FF", "0x000000FF", "none"))
    c.push(mkB("p_none", "Outfit's own bottom", 0, "0x000000FF", "0x000000FF"))
    c.push(mkT("t_um_orange", "Orange Jersey", 2500, "0xF47321FF", "0x005030FF", "jersey"))
    c.push(mkT("t_um_green", "Green Jersey", 2500, "0x005030FF", "0xF47321FF", "jersey"))
    c.push(mkT("t_um_white", "White Jersey", 2500, "0xFFFFFFFF", "0x005030FF", "jersey"))
    c.push(mkB("p_um_white", "White Pants", 2000, "0xF4F4F4FF", "0xF47321FF"))
    c.push(mkB("p_um_green", "Green Pants", 2000, "0x005030FF", "0xF47321FF"))
    c.push(mkB("p_um_orange", "Orange Pants", 2000, "0xF47321FF", "0x005030FF"))
    ' Florida football: orange-and-blue sets, with number 04 only on UF jerseys
    uf = mkO("o_uf_blue", "Florida Blue Football", 4500, "0x0021A5FF", "0xFFFFFFFF", "0xFA4616FF", "jersey", "short", false)
    uf.tab = "sports" : uf.num = "04" : c.push(uf)
    ufTop = mkT("t_uf_blue", "Florida Blue Jersey", 2500, "0x0021A5FF", "0xFA4616FF", "jersey")
    ufTop.num = "04" : c.push(ufTop)
    c.push(mkB("p_uf_white", "Florida White Pants", 2000, "0xFFFFFFFF", "0x0021A5FF"))
    uf = mkO("o_uf_orange", "Florida Orange Football", 4500, "0xFA4616FF", "0x0021A5FF", "0xFFFFFFFF", "jersey", "short", false)
    uf.tab = "sports" : uf.num = "04" : c.push(uf)
    ufTop = mkT("t_uf_orange", "Florida Orange Jersey", 2500, "0xFA4616FF", "0xFFFFFFFF", "jersey")
    ufTop.num = "04" : c.push(ufTop)
    c.push(mkB("p_uf_blue", "Florida Blue Pants", 2000, "0x0021A5FF", "0xFA4616FF"))
    ' basketball uniforms: full combo plus reusable jersey and shorts pieces
    heat = mkO("o_heat", "Miami Heat Uniform", 5000, "0x98002EFF", "0x000000FF", "0xF9A01BFF", "basket", "tank", false)
    heat.tab = "sports" : c.push(heat)
    c.push(mkT("t_heat", "Miami Heat Jersey", 3000, "0x98002EFF", "0xF9A01BFF", "basket"))
    c.push(mkBB("p_heat", "Miami Heat Shorts", 2500, "0x000000FF", "0xF9A01BFF"))
    lakers = mkO("o_lakers", "LA Lakers Uniform", 5000, "0x552583FF", "0xFDB927FF", "0xFDB927FF", "basket", "tank", false)
    lakers.tab = "sports" : c.push(lakers)
    c.push(mkT("t_lakers", "LA Lakers Jersey", 3000, "0x552583FF", "0xFDB927FF", "basket"))
    c.push(mkBB("p_lakers", "LA Lakers Shorts", 2500, "0xFDB927FF", "0x552583FF"))
    bulls = mkO("o_bulls", "Chicago Bulls Uniform", 5000, "0xCE1141FF", "0x000000FF", "0xFFFFFFFF", "basket", "tank", false)
    bulls.tab = "sports" : c.push(bulls)
    c.push(mkT("t_bulls", "Chicago Bulls Jersey", 3000, "0xCE1141FF", "0xFFFFFFFF", "basket"))
    c.push(mkBB("p_bulls", "Chicago Bulls Shorts", 2500, "0x000000FF", "0xCE1141FF"))
    warriors = mkO("o_warriors", "Golden State Uniform", 5000, "0x1D428AFF", "0xFFC72CFF", "0xFFC72CFF", "basket", "tank", false)
    warriors.tab = "sports" : c.push(warriors)
    c.push(mkT("t_warriors", "Warriors Jersey", 3000, "0x1D428AFF", "0xFFC72CFF", "basket"))
    c.push(mkBB("p_warriors", "Warriors Shorts", 2500, "0xFFC72CFF", "0x1D428AFF"))
    knicks = mkO("o_knicks", "New York Knicks Uniform", 5000, "0x006BB6FF", "0xF58426FF", "0xF58426FF", "basket", "tank", false)
    knicks.tab = "sports" : c.push(knicks)
    c.push(mkT("t_knicks", "Knicks Jersey", 3000, "0x006BB6FF", "0xF58426FF", "basket"))
    c.push(mkBB("p_knicks", "Knicks Shorts", 2500, "0xF58426FF", "0x006BB6FF"))
    ch = mkO("o_cheer_orange", "Cheer: Orange", 3500, "0xF47321FF", "0x005030FF", "0xFFFFFFFF", "stripe", "short", false)
    ch.tab = "cheer"
    c.push(ch)
    ch = mkO("o_cheer_white", "Cheer: White", 3500, "0xFFFFFFFF", "0xF47321FF", "0x005030FF", "stripe", "short", false)
    ch.tab = "cheer"
    c.push(ch)
    ct = mkT("t_cheer_orange", "Orange Cheer Top", 2200, "0xF47321FF", "0xFFFFFFFF", "stripe") : ct.tab = "cheer" : c.push(ct)
    cb = mkBB("p_cheer_green", "Green Cheer Bottom", 1800, "0x005030FF", "0xFFFFFFFF") : cb.tab = "cheer" : c.push(cb)
    ct = mkT("t_cheer_white", "White Cheer Top", 2200, "0xFFFFFFFF", "0x005030FF", "stripe") : ct.tab = "cheer" : c.push(ct)
    cb = mkBB("p_cheer_orange", "Orange Cheer Bottom", 1800, "0xF47321FF", "0x005030FF") : cb.tab = "cheer" : c.push(cb)
    ufCheer = mkO("o_cheer_uf_blue", "Florida Blue Cheer", 3800, "0x0021A5FF", "0xFA4616FF", "0xFFFFFFFF", "stripe", "short", false)
    ufCheer.tab = "cheer" : c.push(ufCheer)
    ct = mkT("t_cheer_uf_blue", "Florida Blue Cheer Top", 2200, "0x0021A5FF", "0xFFFFFFFF", "stripe") : ct.tab = "cheer" : c.push(ct)
    cb = mkBB("p_cheer_uf_orange", "Florida Orange Cheer Bottom", 1800, "0xFA4616FF", "0x0021A5FF") : cb.tab = "cheer" : c.push(cb)
    ufCheer = mkO("o_cheer_uf_orange", "Florida Orange Cheer", 3800, "0xFA4616FF", "0x0021A5FF", "0xFFFFFFFF", "stripe", "short", false)
    ufCheer.tab = "cheer" : c.push(ufCheer)
    ct = mkT("t_cheer_uf_orange", "Florida Orange Cheer Top", 2200, "0xFA4616FF", "0xFFFFFFFF", "stripe") : ct.tab = "cheer" : c.push(ct)
    cb = mkBB("p_cheer_uf_blue", "Florida Blue Cheer Bottom", 1800, "0x0021A5FF", "0xFA4616FF") : cb.tab = "cheer" : c.push(cb)
    sw = mkO("o_xmas", "Holiday Sweater", 3000, "0xC0283CFF", "0x34425FFF", "0x1F8F4AFF", "stripe", "long", false)
    sw.tab = "season"
    c.push(sw)
    ' Classic Nutcracker Suite collection: complete looks plus reusable pieces.
    nc = mkO("o_nutcracker_prince", "Nutcracker Prince", 6500, "0xB52332FF", "0xF2F0E8FF", "0xE8B93CFF", "nutcracker", "long", false)
    nc.tab = "season" : c.push(nc)
    nc = mkO("o_clara", "Clara's Party Dress", 5800, "0x78B9E8FF", "0xA8D8F0FF", "0xF7F3E8FF", "clara", "short", true)
    nc.tab = "season" : c.push(nc)
    nc = mkO("o_sugarplum", "Sugar Plum Fairy", 6500, "0xA85A9EFF", "0xE8A6C8FF", "0xF2D36BFF", "sugarplum", "short", false)
    nc.tab = "season" : c.push(nc)
    nc = mkO("o_mouseking", "Mouse King", 6500, "0x49315FFF", "0x252431FF", "0xC8CDD8FF", "mouseking", "long", true)
    nc.tab = "season" : c.push(nc)
    nc = mkO("o_toysoldier", "Classic Toy Soldier", 6000, "0x213B72FF", "0xF1F1EAFF", "0xD52D3CFF", "soldier", "long", false)
    nc.tab = "season" : c.push(nc)
    nc = mkO("o_snowqueen", "Snow Queen", 7000, "0x75CBE8FF", "0xC9ECF5FF", "0xF5FCFFFF", "snowqueen", "long", true)
    nc.tab = "season" : c.push(nc)

    nt = mkT("t_nutcracker_prince", "Prince Parade Jacket", 3600, "0xB52332FF", "0xE8B93CFF", "nutcracker") : nt.sleeves = "long" : nt.tab = "season" : c.push(nt)
    nb = mkB("p_nutcracker_prince", "Prince White Trousers", 2600, "0xF2F0E8FF", "0xE8B93CFF") : nb.tab = "season" : c.push(nb)
    nt = mkT("t_clara", "Clara Blue Bodice", 3200, "0x78B9E8FF", "0xF7F3E8FF", "clara") : nt.tab = "season" : c.push(nt)
    nb = mkB("p_clara", "Clara Blue Skirt", 2600, "0xA8D8F0FF", "0xF7F3E8FF") : nb.tab = "season" : nb.cut = "skirt" : c.push(nb)
    nt = mkT("t_sugarplum", "Sugar Plum Bodice", 3600, "0xA85A9EFF", "0xF2D36BFF", "sugarplum") : nt.tab = "season" : c.push(nt)
    nb = mkB("p_sugarplum", "Sugar Plum Tutu", 2800, "0xE8A6C8FF", "0xF2D36BFF") : nb.tab = "season" : nb.cut = "tutu" : c.push(nb)
    nt = mkT("t_mouseking", "Mouse King Tunic", 3600, "0x49315FFF", "0xC8CDD8FF", "mouseking") : nt.sleeves = "long" : nt.tab = "season" : c.push(nt)
    nb = mkB("p_mouseking", "Mouse King Robe", 2800, "0x252431FF", "0x8E6AACFF") : nb.tab = "season" : nb.cut = "robe" : c.push(nb)
    nt = mkT("t_toysoldier", "Toy Soldier Jacket", 3400, "0x213B72FF", "0xD52D3CFF", "soldier") : nt.sleeves = "long" : nt.tab = "season" : c.push(nt)
    nb = mkB("p_toysoldier", "Toy Soldier Trousers", 2500, "0xF1F1EAFF", "0xD52D3CFF") : nb.tab = "season" : c.push(nb)
    nt = mkT("t_snowqueen", "Snow Queen Bodice", 3800, "0x75CBE8FF", "0xF5FCFFFF", "snowqueen") : nt.sleeves = "long" : nt.tab = "season" : c.push(nt)
    nb = mkB("p_snowqueen", "Snow Queen Gown", 3000, "0xC9ECF5FF", "0xF5FCFFFF") : nb.tab = "season" : nb.cut = "robe" : c.push(nb)
    ' hats
    c.push(mkI("h_none", "hat", "No hat", 0))
    c.push(mkI("h_band", "hat", "Headband", 800))
    c.push(mkI("h_cap", "hat", "Ball Cap", 1000))
    c.push(mkI("h_beanie", "hat", "Beanie", 1000))
    c.push(mkI("h_cowboy", "hat", "Cowboy Hat", 2500))
    c.push(mkI("h_pirate", "hat", "Pirate Tricorn", 3000))
    c.push(mkI("h_astronaut", "hat", "Gold-Visor Space Helmet", 4000))
    c.push(mkI("h_top", "hat", "Top Hat", 3500))
    c.push(mkI("h_wizard", "hat", "Wizard Hat", 4000))
    c.push(mkI("h_crown", "hat", "Gold Crown", 6000))
    hm = mkI("h_helm_orange", "hat", "Orange Helmet", 2500)
    hm.tab = "sports"
    c.push(hm)
    hm = mkI("h_helm_green", "hat", "Green Helmet", 2500)
    hm.tab = "sports"
    c.push(hm)
    hm = mkI("h_helm_white", "hat", "White Helmet", 2500)
    hm.tab = "sports"
    c.push(hm)
    hm = mkI("h_bow", "hat", "Cheer Bow", 1000)
    hm.tab = "cheer"
    c.push(hm)
    hm = mkI("h_helm_uf_blue", "hat", "Florida Blue Helmet", 2500) : hm.tab = "sports" : c.push(hm)
    hm = mkI("h_helm_uf_orange", "hat", "Florida Orange Helmet", 2500) : hm.tab = "sports" : c.push(hm)
    hm = mkI("h_bow_uf", "hat", "Florida Cheer Bow", 1000) : hm.tab = "cheer" : c.push(hm)
    c.push(mkS("h_santa", "hat", "Santa Hat", 2000))
    c.push(mkS("h_elf", "hat", "Elf Hat", 2000))
    c.push(mkS("h_reindeer", "hat", "Reindeer Antlers", 2000))
    c.push(mkS("h_turkey", "hat", "Turkey Hat", 2500))
    c.push(mkS("h_pilgrim", "hat", "Pilgrim Hat", 2000))
    c.push(mkS("h_nutcracker", "hat", "Nutcracker Prince Shako", 2600))
    c.push(mkS("h_clara", "hat", "Clara Satin Bow", 1600))
    c.push(mkS("h_sugarplum", "hat", "Sugar Plum Tiara", 2600))
    c.push(mkS("h_mouseking", "hat", "Mouse King Crown", 3000))
    c.push(mkS("h_toysoldier", "hat", "Toy Soldier Shako", 2400))
    c.push(mkS("h_snowqueen", "hat", "Snow Crystal Crown", 3200))
    ' hair
    c.push(mkI("r_short", "hair", "Short", 0))
    c.push(mkI("r_long", "hair", "Long", 0))
    c.push(mkI("r_buzz", "hair", "Buzz Cut", 0))
    c.push(mkI("r_bald", "hair", "Bald", 0))
    c.push(mkI("r_bangs", "hair", "Curtain Bangs", 1500))
    c.push(mkI("r_bob", "hair", "Soft Bob", 1500))
    c.push(mkI("r_waves", "hair", "Long Waves", 1800))
    c.push(mkI("r_braids", "hair", "Twin Braids", 2000))
    c.push(mkI("r_spiky", "hair", "Spiky", 1200))
    c.push(mkI("r_pigtails", "hair", "Pigtails", 1500))
    c.push(mkI("r_mohawk", "hair", "Mohawk", 1500))
    c.push(mkI("r_afro", "hair", "Big Afro", 2000))
    ' face gear
    c.push(mkI("g_glow", "gear", "Natural Glow", 1000))
    c.push(mkI("g_glam", "gear", "Glam Makeup", 1800))
    c.push(mkI("g_stache", "gear", "Mustache", 800))
    c.push(mkI("g_glasses", "gear", "Glasses", 800))
    c.push(mkI("g_patch", "gear", "Eye Patch", 1000))
    c.push(mkI("g_shades", "gear", "Sunglasses", 1200))
    c.push(mkI("g_mask", "gear", "Ninja Mask", 1500))
    c.push(mkI("g_phones", "gear", "Headphones", 2500))
    c.push(mkI("g_freckles", "gear", "Freckles", 600))
    c.push(mkI("g_earrings", "gear", "Gold Earrings", 1200))
    c.push(mkI("g_goatee", "gear", "Goatee", 1400))
    c.push(mkI("g_emerald_mask_slot", "gear", "Riveted Slot Mask", 1800))
    c.push(mkI("g_emerald_mask_mystic", "gear", "Emerald Mystic Mask", 2200))
    c.push(mkI("g_star_sentinel_cowl", "gear", "Star Sentinel Cowl", 2200))
    c.push(mkI("g_star_sentinel_harness", "gear", "Star Sentinel Leather Rig", 2600))
    c.push(mkI("g_emerald_magic", "hand", "Emerald Hand Magic", 2800))
    c.push(mkI("g_space_magic_gauntlet_right", "hand", "Space Magic Gauntlet · Right", 5000))
    c.push(mkI("g_space_magic_gauntlet_left", "hand", "Space Magic Gauntlet · Left", 5000))
    c.push(mkI("g_star_sentinel_shield", "hand", "Star Sentinel Shield", 4200))
    c.push(mkS("g_rudolph", "gear", "Red Nose", 800))
    c.push(mkS("g_santabeard", "gear", "Santa Beard", 1500))
    ' arm tattoos render whenever the current outfit leaves the arms exposed
    c.push(mkI("tat_none", "tattoo", "No tattoo", 0))
    tattoo = mkI("tat_stars", "tattoo", "Star Trail", 1400) : tattoo.tab = "tattoos" : c.push(tattoo)
    tattoo = mkI("tat_heart", "tattoo", "Heart Ink", 1400) : tattoo.tab = "tattoos" : c.push(tattoo)
    tattoo = mkI("tat_lightning", "tattoo", "Lightning Ink", 1600) : tattoo.tab = "tattoos" : c.push(tattoo)
    tattoo = mkI("tat_bands", "tattoo", "Double Bands", 1800) : tattoo.tab = "tattoos" : c.push(tattoo)
    tattoo = mkI("tat_sleeve", "tattoo", "Pattern Sleeve", 2500) : tattoo.tab = "tattoos" : c.push(tattoo)
    ' back
    c.push(mkI("b_none", "back", "Nothing", 0))
    c.push(mkI("b_pack", "back", "Backpack", 2000))
    c.push(mkI("b_cape", "back", "Hero Cape", 3000))
    c.push(mkI("b_jet", "back", "Jetpack", 4500))
    c.push(mkI("b_wings", "back", "Angel Wings", 5000))
    c.push(mkI("b_emerald_cape", "back", "Emerald Hooded Cape", 3200))
    ' pets stay beside the avatar and can be swapped like any other slot
    c.push(mkI("pet_none", "pet", "No pet", 0))
    c.push(mkI("pet_pilot_dog", "pet", "Illustrated Pilot: Golden Pup", 0))
    pet = mkI("pet_dog", "pet", "Golden Pup", 2500) : pet.tab = "pets" : c.push(pet)
    pet = mkI("pet_cat", "pet", "Tuxedo Cat", 2500) : pet.tab = "pets" : c.push(pet)
    pet = mkI("pet_bunny", "pet", "Snow Bunny", 2200) : pet.tab = "pets" : c.push(pet)
    pet = mkI("pet_dragon", "pet", "Tiny Dragon", 4500) : pet.tab = "pets" : c.push(pet)
    pet = mkI("pet_robot", "pet", "Robo Buddy", 4000) : pet.tab = "pets" : c.push(pet)
    m.catList = c
    return c
end function

function itemById(id as String) as Object
    if m.catIdx = invalid then
        idx = {}
        for each it in catalog()
            idx[it.id] = it
        end for
        m.catIdx = idx
    end if
    return m.catIdx[id]
end function

function comboParts(id as String) as Object
    if id = "o_um_orange" then return ["t_um_orange", "p_um_white", "h_helm_orange"]
    if id = "o_um_green" then return ["t_um_green", "p_um_green", "h_helm_green"]
    if id = "o_um_white" then return ["t_um_white", "p_um_orange", "h_helm_white"]
    if id = "o_uf_blue" then return ["t_uf_blue", "p_uf_white", "h_helm_uf_blue"]
    if id = "o_uf_orange" then return ["t_uf_orange", "p_uf_blue", "h_helm_uf_orange"]
    if id = "o_heat" then return ["t_heat", "p_heat"]
    if id = "o_lakers" then return ["t_lakers", "p_lakers"]
    if id = "o_bulls" then return ["t_bulls", "p_bulls"]
    if id = "o_warriors" then return ["t_warriors", "p_warriors"]
    if id = "o_knicks" then return ["t_knicks", "p_knicks"]
    if id = "o_cheer_orange" then return ["t_cheer_orange", "p_cheer_green", "h_bow"]
    if id = "o_cheer_white" then return ["t_cheer_white", "p_cheer_orange", "h_bow"]
    if id = "o_cheer_uf_blue" then return ["t_cheer_uf_blue", "p_cheer_uf_orange", "h_bow_uf"]
    if id = "o_cheer_uf_orange" then return ["t_cheer_uf_orange", "p_cheer_uf_blue", "h_bow_uf"]
    if id = "o_nutcracker_prince" then return ["t_nutcracker_prince", "p_nutcracker_prince", "h_nutcracker"]
    if id = "o_clara" then return ["t_clara", "p_clara", "h_clara"]
    if id = "o_sugarplum" then return ["t_sugarplum", "p_sugarplum", "h_sugarplum"]
    if id = "o_mouseking" then return ["t_mouseking", "p_mouseking", "h_mouseking"]
    if id = "o_toysoldier" then return ["t_toysoldier", "p_toysoldier", "h_toysoldier"]
    if id = "o_snowqueen" then return ["t_snowqueen", "p_snowqueen", "h_snowqueen"]
    if id = "o_doomarmor" then return ["b_emerald_cape"]
    if id = "o_starcaptain" then return ["g_star_sentinel_cowl", "g_star_sentinel_harness", "g_star_sentinel_shield"]
    return []
end function

function outfitDefaultHat(id as String) as String
    if id = "o_nutcracker_prince" then return "h_nutcracker"
    if id = "o_clara" then return "h_clara"
    if id = "o_sugarplum" then return "h_sugarplum"
    if id = "o_mouseking" then return "h_mouseking"
    if id = "o_toysoldier" then return "h_toysoldier"
    if id = "o_snowqueen" then return "h_snowqueen"
    return ""
end function

function outfitDefaultBack(id as String) as String
    if id = "o_doomarmor" then return "b_emerald_cape"
    return ""
end function

function isNbaHeightSkin(id as String) as Boolean
    return id = "o_hero" or id = "o_arcarmor" or id = "o_doomarmor" or id = "o_ultron" or id = "o_starcaptain" or id = "o_webhero" or id = "o_pirate" or id = "o_ninja" or id = "o_space" or id = "o_robe" or id = "o_nutcracker_prince" or id = "o_clara" or id = "o_sugarplum" or id = "o_mouseking" or id = "o_toysoldier" or id = "o_snowqueen"
end function

sub applyOutfitDefaults(cfg as Object, id as String, owned as Object)
    if id = "o_ultron" then
        cfg.baseSkin = "robot"
    else if id = "o_doomarmor" then
        cfg.baseSkin = "emerald"
    else if id = "o_starcaptain" then
        cfg.baseSkin = "sentinel"
    else
        cfg.baseSkin = "human"
    end if
    if isNbaHeightSkin(id) then cfg.height = "nba"
    defaultHat = outfitDefaultHat(id)
    if defaultHat <> "" then
        if owned = invalid then
            cfg.hat = defaultHat
        else if owned.doesExist(defaultHat) then
            cfg.hat = defaultHat
        end if
    end if
    defaultBack = outfitDefaultBack(id)
    if defaultBack <> "" then
        if owned = invalid then
            cfg.back = defaultBack
        else if owned.doesExist(defaultBack) then
            cfg.back = defaultBack
        end if
    end if
    if id = "o_starcaptain" then
        if owned = invalid then
            setGear(cfg, "g_star_sentinel_cowl", true)
            setGear(cfg, "g_star_sentinel_harness", true)
            setHandItem(cfg, "g_star_sentinel_shield", true)
        else
            if owned.doesExist("g_star_sentinel_cowl") then setGear(cfg, "g_star_sentinel_cowl", true)
            if owned.doesExist("g_star_sentinel_harness") then setGear(cfg, "g_star_sentinel_harness", true)
            if owned.doesExist("g_star_sentinel_shield") then setHandItem(cfg, "g_star_sentinel_shield", true)
        end if
    end if
end sub

sub grantComboParts(who as String, id as String)
    for each partId in comboParts(id)
        m.state.owned[who][partId] = true
    end for
end sub

function isOwned(k as String, it as Object) as Boolean
    if it.price = 0 then return true
    o = m.state.owned[k]
    if o = invalid then return false
    return o.doesExist(it.id)
end function

function ownedList(k as String, cat as String) as Object
    out = []
    for each it in catalog()
        if it.cat = cat and isOwned(k, it) then out.push(it)
    end for
    return out
end function

' ---------- profile state ----------

function defaultAvatar(k as String) as Object
    presentation = "male"
    if k = "emily" or k = "patricia" then presentation = "female"
    a = { ageGroup: "22-27", presentation: presentation, shape: "std", height: "average", top: "t_none", bottom: "p_none", skin: 2, baseSkin: "human", hcol: 1, ecol: 0, hair: "r_short", outfit: "o_blue", hat: "h_none", gears: [], handItems: [], back: "b_none", tattoo: "tat_none", pet: "pet_none", petColor: 0 }
    if k = "emily" then
        a.hair = "r_long"
        a.hcol = 2
        a.outfit = "o_purple"
        a.skin = 1
    else if k = "max" then
        a.outfit = "o_green"
        a.hcol = 1
    else if k = "anthony" then
        a.hair = "r_buzz"
        a.hcol = 4
        a.outfit = "o_red"
    else if k = "patricia" then
        a.hair = "r_long"
        a.hcol = 1
        a.outfit = "o_yellow"
        a.skin = 1
    else if k = "nick" then
        a.hcol = 4
        a.outfit = "o_blue"
    else if k = "nicky" then
        a.hcol = 0
        a.outfit = "o_green"
    end if
    return a
end function

function copyCfg(a as Object) as Object
    gc = []
    for each g in a.gears
        gc.push(g)
    end for
    hc = []
    if a.handItems <> invalid then
        for each h in a.handItems
            hc.push(h)
        end for
    end if
    return { ageGroup: a.ageGroup, presentation: a.presentation, shape: a.shape, height: a.height, top: a.top, bottom: a.bottom, skin: a.skin, baseSkin: a.baseSkin, hcol: a.hcol, ecol: a.ecol, hair: a.hair, outfit: a.outfit, hat: a.hat, gears: gc, handItems: hc, back: a.back, tattoo: a.tattoo, pet: a.pet, petColor: a.petColor }
end function

function ageGroupIds() as Object
    return ["9-11", "12-14", "15-18", "18-21", "22-27", "45-55", "60+"]
end function

function ageGroupName(id as String) as String
    if id = "9-11" then return "9–11 · Child"
    if id = "12-14" then return "12–14 · Preteen"
    if id = "15-18" then return "15–18 · Teen"
    if id = "18-21" then return "18–21 · Young adult"
    if id = "45-55" then return "45–55 · Mature adult"
    if id = "60+" then return "60+ · Seasoned adult"
    return "22–27 · Adult"
end function

function ageHeightScale(id as String) as Float
    if id = "9-11" then return 0.78
    if id = "12-14" then return 0.86
    if id = "15-18" then return 0.94
    if id = "18-21" then return 0.99
    if id = "45-55" then return 0.98
    if id = "60+" then return 0.94
    return 1.0
end function

function ageWidthScale(id as String) as Float
    if id = "9-11" then return 0.82
    if id = "12-14" then return 0.88
    if id = "15-18" then return 0.95
    if id = "18-21" then return 0.98
    if id = "45-55" then return 1.03
    if id = "60+" then return 1.00
    return 1.0
end function

function isYouthAge(id as String) as Boolean
    return id = "9-11" or id = "12-14" or id = "15-18"
end function

function presentationIds() as Object
    return ["male", "female"]
end function

function presentationName(id as String) as String
    if id = "female" then return "Female"
    return "Male"
end function

function shapeIds() as Object
    return ["std", "fem", "skinny", "muscle"]
end function

function shapeName(id as String) as String
    if id = "fem" then return "Feminine"
    if id = "skinny" then return "Skinny"
    if id = "muscle" then return "Muscular"
    return "Classic"
end function

function heightIds() as Object
    return ["short", "medium", "average", "tall", "nba"]
end function

function heightName(id as String) as String
    if id = "short" then return "Short"
    if id = "medium" then return "Medium"
    if id = "tall" then return "Tall"
    if id = "nba" then return "NBA"
    return "Average"
end function

function heightScale(id as String) as Float
    if id = "short" then return 0.90
    if id = "medium" then return 0.95
    if id = "tall" then return 1.05
    if id = "nba" then return 1.10
    return 1.0
end function

function gearGroup(id as String) as String
    if id = "g_glasses" or id = "g_shades" or id = "g_patch" then return "eyes"
    if id = "g_glow" or id = "g_glam" then return "makeup"
    if id = "g_stache" or id = "g_goatee" or id = "g_santabeard" then return "facial"
    if id = "g_emerald_mask_slot" or id = "g_emerald_mask_mystic" then return "fullmask"
    if id = "g_star_sentinel_cowl" then return "headcover"
    if id = "g_star_sentinel_harness" then return "torso-rig"
    return ""
end function

function hasGear(cfg as Object, id as String) as Boolean
    for each g in cfg.gears
        if g = id then return true
    end for
    return false
end function

function hasHandItem(cfg as Object, id as String) as Boolean
    if cfg.handItems = invalid then return false
    for each itemId in cfg.handItems
        if itemId = id then return true
    end for
    return false
end function

sub setHandItem(cfg as Object, id as String, on as Boolean)
    out = []
    if cfg.handItems <> invalid then
        for each itemId in cfg.handItems
            if itemId <> id then out.push(itemId)
        end for
    end if
    if on then out.push(id)
    cfg.handItems = out
end sub

' Turn an accessory on or off. Items in the same target group replace each
' other; independent target groups can be worn together.
sub setGear(cfg as Object, id as String, on as Boolean)
    out = []
    grp = gearGroup(id)
    for each g in cfg.gears
        keep = (g <> id)
        if on and grp <> "" and gearGroup(g) = grp then keep = false
        if keep then out.push(g)
    end for
    if on then out.push(id)
    cfg.gears = out
end sub

sub migrateGears(a as Object)
    out = []
    hands = []
    if a.handItems <> invalid then
        for each h in a.handItems
            if itemById(h) <> invalid then hands.push(h)
        end for
    end if
    if a.gears <> invalid then
        for each g in a.gears
            if g = "g_emerald_magic" then
                hands.push(g)
            else if itemById(g) <> invalid then
                out.push(g)
            end if
        end for
    end if
    if a.gear <> invalid then
        if itemById(a.gear) <> invalid then out.push(a.gear)
        a.delete("gear")
    end if
    a.gears = out
    a.handItems = hands
end sub

function shopPinFor(k as String) as String
    if m.state.shopPins = invalid then return ""
    v = m.state.shopPins[k]
    if v = invalid then return ""
    return v
end function

sub ensureCbState()
    st = m.state
    if st.cb = invalid then st.cb = {}
    if st.avatar = invalid then st.avatar = {}
    if st.owned = invalid then st.owned = {}
    for each k in profileKeys()
        if st.cb[k] = invalid then st.cb[k] = 0
        if st.owned[k] = invalid then st.owned[k] = {}
        for each comboId in ["o_um_orange", "o_um_green", "o_um_white", "o_uf_blue", "o_uf_orange", "o_heat", "o_lakers", "o_bulls", "o_warriors", "o_knicks", "o_cheer_orange", "o_cheer_white", "o_cheer_uf_blue", "o_cheer_uf_orange", "o_nutcracker_prince", "o_clara", "o_sugarplum", "o_mouseking", "o_toysoldier", "o_snowqueen", "o_doomarmor"]
            if st.owned[k].doesExist(comboId) then
                if st.owned[k][comboId] then grantComboParts(k, comboId)
            end if
        end for
        d = defaultAvatar(k)
        a = st.avatar[k]
        if a = invalid then
            a = d
        else
            if a.skin = invalid then a.skin = d.skin
            ' Older saves used the outfit slot for the robot. Preserve that
            ' choice when adding an independent base layer.
            if a.baseSkin = invalid then
                a.baseSkin = "human"
                if a.outfit = "o_ultron" then a.baseSkin = "robot"
                if a.outfit = "o_doomarmor" then a.baseSkin = "emerald"
            end if
            if a.baseSkin <> "human" and a.baseSkin <> "robot" and a.baseSkin <> "emerald" then a.baseSkin = "human"
            if a.hcol = invalid then a.hcol = d.hcol
            if a.ecol = invalid then a.ecol = d.ecol
            if a.shape = invalid then a.shape = d.shape
            if a.height = invalid then a.height = d.height
            if isNbaHeightSkin(a.outfit) then a.height = "nba"
            if a.ageGroup = invalid then a.ageGroup = d.ageGroup
            if a.presentation = invalid then a.presentation = d.presentation
            if a.petColor = invalid then a.petColor = 0
            for each fld in ["hair", "outfit", "hat", "back", "top", "bottom", "tattoo", "pet"]
                if a[fld] = invalid then
                    a[fld] = d[fld]
                else if itemById(a[fld]) = invalid then
                    a[fld] = d[fld]
                end if
            end for
        end if
        migrateGears(a)
        ok = false
        for each sid in shapeIds()
            if a.shape = sid then ok = true
        end for
        if not ok then a.shape = "std"
        heightOk = false
        for each hid in heightIds()
            if a.height = hid then heightOk = true
        end for
        if not heightOk then a.height = "average"
        ageOk = false
        for each aid in ageGroupIds()
            if a.ageGroup = aid then ageOk = true
        end for
        if not ageOk then a.ageGroup = "22-27"
        presentationOk = false
        for each pid in presentationIds()
            if a.presentation = pid then presentationOk = true
        end for
        if not presentationOk then a.presentation = d.presentation
        if a.petColor < 0 or a.petColor >= petColorNames().count() then a.petColor = 0
        st.avatar[k] = a
    end for
end sub

sub ensureWho()
    if m.who = invalid then m.who = "emily"
end sub

' ---------- HD illustrated avatar renderer ----------
' Figure box is 100 units wide x 204 tall (hats rise above the head).
' Roku OS 16 shader effects soften the modular geometry at preview scale while
' older devices safely retain the same complete mix-and-match renderer.
' mode "full" draws everything; mode "head" draws head and shoulders only.

sub applyAvatarHdEffect(node as Object, s as Integer, uw as Integer, uh as Integer)
    if node = invalid or s < 1 then return
    ' Effects are intentionally limited to one large full-body preview. Shop
    ' and inventory pages can draw many thumbnails at once; attaching shader
    ' nodes to every modular piece there can exhaust Roku SceneGraph resources.
    if m.avatarEffectsEnabled <> true then return
    area = uw * uh
    ' At tile/parade scale, round only foundational pieces to keep moving and
    ' multi-item screens light. Large previews also smooth facial components.
    if s = 1 and area < 300 then return
    if s >= 2 and area < 48 then return
    fields = node.getFields()
    if fields = invalid or not fields.doesExist("effect") then return
    ' Keep the node name dynamic so legacy validators and Roku OS versions can
    ' safely fall through without treating the OS 16 component as mandatory.
    effectNodeName = "Effect"
    fx = CreateObject("roSGNode", effectNodeName)
    if fx = invalid then return
    minSide = uw
    if uh < minSide then minSide = uh
    maxSide = uw
    if uh > maxSide then maxSide = uh
    ' A small radius softens corners without turning long limbs into capsules.
    ' The previous 0.42–0.45 ratios approached a half-circle on each end.
    radiusRatio = 0.08
    if minSide > 0 and maxSide / minSide >= 1.8 then
        radiusRatio = 0.06
    else if uw <= 45 and uh <= 45 then
        radiusRatio = 0.12
    else if uw >= 30 and uh >= 30 then
        radiusRatio = 0.08
    end if
    radius = minSide * s * radiusRatio
    if radius < 1 then radius = 1
    maxRadius = minSide * s * 0.16
    if radius > maxRadius then radius = maxRadius
    fx.borderRadius = [radius]
    node.effect = fx
end sub

sub ur(p as Object, ox as Integer, oy as Integer, s as Integer, ux as Integer, uy as Integer, uw as Integer, uh as Integer, color as String)
    piece = mkRect(p, ox + ux * s, oy + uy * s, uw * s, uh * s, color)
    applyAvatarHdEffect(piece, s, uw, uh)
end sub

function petPalette(id as String, variant as Integer) as Object
    if variant = 1 then return ["0x8A5A2BFF", "0x5E3C1BFF", "0xD9B48FFF"]
    if variant = 2 then return ["0xF4F7FFFF", "0xCFD8E8FF", "0x8EC9FFFF"]
    if variant = 3 then return ["0x20263AFF", "0x3A4568FF", "0xFFD66BFF"]
    if variant = 4 then return ["0x5B3FA8FF", "0x8A6BD6FF", "0x7EE2A8FF"]
    if id = "pet_dog" then return ["0xD9A24BFF", "0x8A5A2BFF", "0xE5B85FFF"]
    if id = "pet_cat" then return ["0x20232AFF", "0x15171CFF", "0x7EE2A8FF"]
    if id = "pet_bunny" then return ["0xF1F3F7FF", "0xFFFFFFFF", "0xF59AB8FF"]
    if id = "pet_dragon" then return ["0x4AAF72FF", "0x2F7D50FF", "0xFFD66BFF"]
    return ["0x7E8CA3FF", "0xAEB9C9FF", "0x2F6BFFFF"]
end function

function modularPilotOutfitUri(id as String) as String
    if id = "o_pilot_child_blue" then return "pkg:/images/avatar_modular/outfit_blue.png"
    if id = "o_pilot_preteen_purple" then return "pkg:/images/avatar_modular/outfit_purple.png"
    if id = "o_pilot_adult_green" then return "pkg:/images/avatar_modular/outfit_green.png"
    if id = "o_ultron" then return "pkg:/images/avatar_modular/outfit_ultron.png"
    return ""
end function

function modularHairUri(id as String) as String
    if id = "r_bald" then return ""
    name = id
    if left(name, 2) = "r_" then name = mid(name, 2)
    return "pkg:/images/avatar_modular/hair_" + name + ".png"
end function

function mkTintedAvatarPoster(parent as Object, uri as String, x as Integer, y as Integer, w as Integer, h as Integer, color as String) as Object
    poster = mkPoster(parent, uri, x, y, w, h)
    poster.blendColor = color
    return poster
end function

function mkFittedClothingPoster(parent as Object, uri as String, x as Integer, y as Integer, w as Integer, h as Integer) as Object
    poster = mkPoster(parent, uri, x, y, w, h)
    ' The asset is pre-sized to this body-specific anchor box. Preserve its
    ' aspect ratio; scaleToFill would crop the differently proportioned art.
    poster.loadDisplayMode = "scaleToFit"
    return poster
end function

' The clothing sprites use body-relative anchors. The armor art has a higher
' shoulder and waist than the illustrated human, so it uses its own anchors.
sub drawIllustratedClothes(parent as Object, s as Integer, cfg as Object, robot as Boolean, outfitUri as String, standardPose as Boolean)
    o = itemById(cfg.outfit)
    tp = itemById(cfg.top)
    bt = itemById(cfg.bottom)
    upperOverride = tp <> invalid and cfg.top <> "t_none"
    lowerOverride = bt <> invalid and cfg.bottom <> "p_none"
    upperY = 68 : upperH = 69 : lowerY = 137 : lowerH = 67
    if standardPose then upperY = 36 : upperH = 76 : lowerY = 111 : lowerH = 93
    ' The armor itself is the base, not a second garment over itself.
    armorOnly = robot and cfg.outfit = "o_ultron"
    if not armorOnly and outfitUri <> "" then
        stem = left(outfitUri, len(outfitUri) - 4)
        suffix = ""
        if robot then suffix = "_robot"
        if not upperOverride then mkFittedClothingPoster(parent, stem + "_upper" + suffix + ".png", 0, upperY * s, 100 * s, upperH * s)
        if not lowerOverride then mkFittedClothingPoster(parent, stem + "_lower" + suffix + ".png", 0, lowerY * s, 100 * s, lowerH * s)
    else if not armorOnly and o <> invalid then
        ' Existing non-pilot outfits use their catalog colors and silhouette
        ' when layered over armor. The legacy human renderer stays unchanged.
        if not upperOverride then drawIllustratedTop(parent, s, upperY, upperH, o, robot)
        if not lowerOverride then drawIllustratedBottom(parent, s, lowerY, lowerH, o, robot)
    end if
    if upperOverride then drawIllustratedTop(parent, s, upperY, upperH, tp, robot)
    if lowerOverride then drawIllustratedBottom(parent, s, lowerY, lowerH, bt, robot)
end sub

sub drawIllustratedTop(parent as Object, s as Integer, y as Integer, h as Integer, it as Object, robot as Boolean)
    sleeve = it.sleeves
    asset = "upper-short.png"
    if sleeve = "long" then asset = "upper-long.png"
    if sleeve = "tank" then asset = "upper-tank.png"
    if robot and sleeve = "short" then asset = "upper-short-fabric.png"
    if robot then asset = left(asset, len(asset) - 4) + "_robot.png"
    topLayer = mkFittedClothingPoster(parent, "pkg:/images/avatar_modular/" + asset, 0, y * s, 100 * s, h * s)
    topLayer.blendColor = it.top
    if it.num <> invalid then
        mkLabelW(parent, it.num, 32 * s, (y + h * 0.24) * s, 36 * s, 11 * s, it.trim, "center")
    end if
end sub

sub drawIllustratedBottom(parent as Object, s as Integer, y as Integer, h as Integer, it as Object, robot as Boolean)
    asset = "lower-pants.png"
    if it.shorts = true or it.style = "basket" then asset = "lower-shorts.png"
    if it.cut = "skirt" or it.cut = "tutu" or it.cut = "robe" or it.robe = true then asset = "lower-skirt.png"
    if robot and asset = "lower-pants.png" then asset = "lower-pants-fabric.png"
    if robot then asset = left(asset, len(asset) - 4) + "_robot.png"
    bottomLayer = mkFittedClothingPoster(parent, "pkg:/images/avatar_modular/" + asset, 0, y * s, 100 * s, h * s)
    bottomLayer.blendColor = it.bottom
end sub

sub drawModularPilotBack(parent as Object, s as Integer, cfg as Object)
    if cfg.back = "b_cape" then
        ur(parent, 0, 0, s, 17, 78, 66, 112, "0xB9233FFF")
        ur(parent, 0, 0, s, 20, 82, 6, 102, "0xE85A69FF")
    else if cfg.back = "b_wings" then
        ur(parent, 0, 0, s, -12, 72, 30, 62, "0xEDF5FFFF")
        ur(parent, 0, 0, s, 82, 72, 30, 62, "0xD9E8FAFF")
    else if cfg.back = "b_pack" then
        ur(parent, 0, 0, s, 13, 88, 74, 56, "0x754627FF")
        ur(parent, 0, 0, s, 18, 96, 64, 38, "0x9A6237FF")
    else if cfg.back = "b_jet" then
        ur(parent, 0, 0, s, 10, 86, 18, 66, "0x657080FF")
        ur(parent, 0, 0, s, 72, 86, 18, 66, "0x657080FF")
        ur(parent, 0, 0, s, 15, 148, 8, 18, "0xFFB234FF")
        ur(parent, 0, 0, s, 77, 148, 8, 18, "0xFFB234FF")
    end if
end sub

sub drawModularPilotTattoo(parent as Object, s as Integer, cfg as Object)
    if cfg.tattoo = invalid or cfg.tattoo = "tat_none" then return
    ink = "0x27324AFF"
    if cfg.tattoo = "tat_heart" then ink = "0xB8324FFF"
    if cfg.tattoo = "tat_stars" then
        ur(parent, 0, 0, s, 13, 104, 5, 5, ink) : ur(parent, 0, 0, s, 15, 115, 4, 4, ink)
    else if cfg.tattoo = "tat_lightning" then
        ur(parent, 0, 0, s, 14, 104, 5, 10, ink) : ur(parent, 0, 0, s, 11, 111, 5, 10, ink)
    else if cfg.tattoo = "tat_bands" then
        ur(parent, 0, 0, s, 10, 111, 12, 3, ink) : ur(parent, 0, 0, s, 10, 117, 12, 3, ink)
    else if cfg.tattoo = "tat_sleeve" then
        ur(parent, 0, 0, s, 10, 100, 12, 27, "0x354563AA")
        ur(parent, 0, 0, s, 13, 104, 6, 4, "0x8090B0CC")
        ur(parent, 0, 0, s, 12, 114, 7, 4, "0x8090B0CC")
    else
        ur(parent, 0, 0, s, 13, 110, 7, 6, ink)
    end if
end sub

sub drawModularPilotGear(parent as Object, s as Integer, cfg as Object)
    for each gid in cfg.gears
        if gid = "g_glasses" then
            ur(parent, 0, 0, s, 31, 43, 17, 12, "0x202532FF") : ur(parent, 0, 0, s, 52, 43, 17, 12, "0x202532FF") : ur(parent, 0, 0, s, 47, 47, 6, 3, "0x202532FF")
        else if gid = "g_shades" then
            ur(parent, 0, 0, s, 31, 43, 17, 11, "0x17213BEE") : ur(parent, 0, 0, s, 52, 43, 17, 11, "0x17213BEE") : ur(parent, 0, 0, s, 47, 46, 6, 3, "0x17213BFF")
        else if gid = "g_patch" then
            ur(parent, 0, 0, s, 53, 43, 16, 12, "0x171722FF") : ur(parent, 0, 0, s, 29, 39, 42, 2, "0x171722FF")
        else if gid = "g_freckles" then
            ur(parent, 0, 0, s, 35, 57, 3, 2, "0xA56B4CFF") : ur(parent, 0, 0, s, 41, 59, 2, 2, "0xA56B4CFF") : ur(parent, 0, 0, s, 62, 57, 3, 2, "0xA56B4CFF")
        else if gid = "g_glow" then
            ur(parent, 0, 0, s, 34, 49, 13, 3, "0x5B355FCC") : ur(parent, 0, 0, s, 53, 49, 13, 3, "0x5B355FCC")
            ur(parent, 0, 0, s, 35, 59, 9, 5, "0xF18AA5AA") : ur(parent, 0, 0, s, 56, 59, 9, 5, "0xF18AA5AA")
            ur(parent, 0, 0, s, 44, 66, 12, 4, "0xC65370EE")
        else if gid = "g_glam" then
            ur(parent, 0, 0, s, 33, 47, 15, 5, "0x8D4FA8DD") : ur(parent, 0, 0, s, 52, 47, 15, 5, "0x8D4FA8DD")
            ur(parent, 0, 0, s, 35, 51, 12, 2, "0x1A1823FF") : ur(parent, 0, 0, s, 53, 51, 12, 2, "0x1A1823FF")
            ur(parent, 0, 0, s, 43, 65, 14, 5, "0xB7224AFF") : ur(parent, 0, 0, s, 47, 65, 6, 1, "0xF58AA3FF")
        else if gid = "g_stache" then
            ur(parent, 0, 0, s, 41, 60, 18, 5, hairColors()[cfg.hcol])
        else if gid = "g_goatee" then
            ur(parent, 0, 0, s, 45, 68, 10, 8, hairColors()[cfg.hcol])
        else if gid = "g_rudolph" then
            ur(parent, 0, 0, s, 47, 55, 7, 7, "0xD83B45FF")
        else if gid = "g_earrings" then
            ur(parent, 0, 0, s, 24, 55, 4, 7, "0xE8B93CFF") : ur(parent, 0, 0, s, 72, 55, 4, 7, "0xE8B93CFF")
        else if gid = "g_phones" then
            ur(parent, 0, 0, s, 20, 38, 8, 28, "0x3E63DDFF") : ur(parent, 0, 0, s, 72, 38, 8, 28, "0x3E63DDFF") : ur(parent, 0, 0, s, 25, 28, 50, 5, "0x27365EFF")
        else if gid = "g_mask" then
            ur(parent, 0, 0, s, 29, 55, 42, 17, "0x171722EE")
        else if gid = "g_santabeard" then
            ur(parent, 0, 0, s, 31, 58, 38, 22, "0xF7F3E8FF")
        end if
    end for
end sub

sub drawModularPilotHat(parent as Object, s as Integer, cfg as Object)
    hid = cfg.hat
    if hid = invalid or hid = "h_none" then return
    if hid = "h_band" or hid = "h_bow" or hid = "h_bow_uf" or hid = "h_clara" then
        c = "0xE85A69FF"
        if hid = "h_bow_uf" then c = "0xFA4616FF"
        ur(parent, 0, 0, s, 27, 25, 46, 7, c) : ur(parent, 0, 0, s, 66, 18, 12, 12, c)
    else if hid = "h_cap" then
        ur(parent, 0, 0, s, 27, 16, 46, 18, "0x3E63DDFF") : ur(parent, 0, 0, s, 66, 29, 22, 6, "0x27365EFF")
    else if hid = "h_beanie" then
        ur(parent, 0, 0, s, 27, 14, 46, 22, "0xB96BFFFF") : ur(parent, 0, 0, s, 43, 7, 14, 10, "0xDCA0FFFF")
    else if left(hid, 6) = "h_helm" or hid = "h_astronaut" then
        hc = "0xEDEFF5FF"
        if instr(1, hid, "orange") > 0 then
            hc = "0xFA4616FF"
        else if instr(1, hid, "blue") > 0 then
            hc = "0x0021A5FF"
        else if instr(1, hid, "green") > 0 then
            hc = "0x005030FF"
        end if
        ur(parent, 0, 0, s, 22, 9, 56, 54, hc) : ur(parent, 0, 0, s, 29, 24, 42, 29, "0xD9B35CAA")
    else if hid = "h_crown" or hid = "h_sugarplum" or hid = "h_snowqueen" or hid = "h_mouseking" then
        ur(parent, 0, 0, s, 30, 13, 40, 19, "0xE8B93CFF") : ur(parent, 0, 0, s, 30, 5, 8, 14, "0xE8B93CFF") : ur(parent, 0, 0, s, 46, 2, 8, 17, "0xE8B93CFF") : ur(parent, 0, 0, s, 62, 5, 8, 14, "0xE8B93CFF")
    else if hid = "h_wizard" or hid = "h_elf" or hid = "h_santa" then
        hc = "0x5B3FA8FF"
        if hid = "h_elf" then
            hc = "0x2F8F52FF"
        else if hid = "h_santa" then
            hc = "0xD93B45FF"
        end if
        ur(parent, 0, 0, s, 23, 27, 58, 8, hc) : ur(parent, 0, 0, s, 35, 2, 30, 28, hc) : ur(parent, 0, 0, s, 58, 0, 12, 10, "0xFFF4D8FF")
    else if hid = "h_reindeer" then
        ur(parent, 0, 0, s, 31, 8, 6, 26, "0x8A5A2BFF") : ur(parent, 0, 0, s, 63, 8, 6, 26, "0x8A5A2BFF") : ur(parent, 0, 0, s, 22, 8, 16, 5, "0x8A5A2BFF") : ur(parent, 0, 0, s, 62, 8, 16, 5, "0x8A5A2BFF")
    else
        hc = "0x252431FF"
        if hid = "h_cowboy" then
            hc = "0x9A6237FF"
        else if hid = "h_pirate" then
            hc = "0x1E1E24FF"
        end if
        ur(parent, 0, 0, s, 22, 25, 60, 9, hc) : ur(parent, 0, 0, s, 30, 7, 44, 22, hc)
        if hid = "h_pirate" then ur(parent, 0, 0, s, 42, 10, 16, 10, "0xF4F4F4FF")
    end if
end sub

' Attachment profiles describe the visible target, not the avatar's overall
' height. Every wearable is a separate transparent node, so equipping or
' removing it cannot crop, erase, or otherwise mutate the base skin.
' Measured alpha bounds in the normalized 100 x 204 logical canvas. These are
' the visible avatar edges, not the file/canvas edges. Age and shape transforms
' apply later to the fully assembled layer tree.
function avatarSilhouetteBounds(cfg as Object) as Object
    if cfg.baseSkin = "sentinel" or cfg.outfit = "o_starcaptain" then return [11.5, 1.5, 76.0, 201.5]
    if cfg.baseSkin = "emerald" or cfg.outfit = "o_doomarmor" then return [0.0, 3.0, 90.5, 201.0]
    if cfg.baseSkin = "robot" or cfg.outfit = "o_ultron" then return [4.5, 2.5, 91.0, 198.5]
    youthBase = cfg.ageGroup = "9-11" or cfg.ageGroup = "12-14"
    if cfg.presentation = "female" then
        if youthBase then return [14.5, 2.5, 70.5, 189.5]
        return [13.5, 3.5, 73.0, 187.5]
    end if
    if youthBase then return [11.5, 3.5, 76.5, 189.5]
    return [11.5, 4.5, 76.5, 188.0]
end function

' relBox values are normalized to the avatar's visible edges: [u, v, uw, vh].
' Ratios may extend slightly below 0 or above 1 for capes, hats, and effects.
function edgeRelativeBox(bounds as Object, relBox as Object) as Object
    return [bounds[0] + bounds[2] * relBox[0], bounds[1] + bounds[3] * relBox[1], bounds[2] * relBox[2], bounds[3] * relBox[3]]
end function

' Alpha edges establish the outer silhouette, but fitted wearables need an
' anatomical unit as well. Chest-to-crown is measured from the visible crown
' edge to the upper-sternum landmark for the active base. Every head, hood,
' shoulder, and forearm measurement below is expressed in that one unit.
function avatarAnatomy(cfg as Object, bounds as Object) as Object
    chestRel = 0.286
    if cfg.baseSkin = "robot" or cfg.outfit = "o_ultron" then chestRel = 0.270
    if cfg.baseSkin = "emerald" or cfg.outfit = "o_doomarmor" then chestRel = 0.276
    if cfg.baseSkin = "sentinel" or cfg.outfit = "o_starcaptain" then chestRel = 0.270
    crownY = bounds[1]
    chestY = bounds[1] + bounds[3] * chestRel
    axisX = bounds[0] + bounds[2] * 0.5
    ' Doom's extended viewer-left hand makes its full alpha bounds asymmetric.
    ' Use the measured torso centerline rather than the outer-bounds midpoint.
    if cfg.baseSkin = "emerald" or cfg.outfit = "o_doomarmor" then axisX = 50.0
    return {
        axisX: axisX,
        crownY: crownY,
        chestY: chestY,
        chestToCrown: chestY - crownY
    }
end function

' relBox is [x-from-body-axis, y-from-crown, width, height], with every value
' expressed as a multiple of the active avatar's chest-to-crown distance.
function anatomyRelativeBox(anatomy as Object, relBox as Object) as Object
    u = anatomy.chestToCrown
    return [anatomy.axisX + u * relBox[0], anatomy.crownY + u * relBox[1], u * relBox[2], u * relBox[3]]
end function

' Upper-torso landmarks are resolved independently from headwear and total
' avatar height. They give collars, suspenders, capes, necklaces, and future
' shoulder accessories explicit edges to attach to on every standardized pose.
function avatarTorsoRig(cfg as Object, bounds as Object, anatomy as Object) as Object
    u = anatomy.chestToCrown
    ax = anatomy.axisX
    cy = anatomy.crownY
    neckY = cy + u * 0.49
    shoulderInnerY = cy + u * 0.51
    shoulderOuterY = cy + u * 0.57
    waistY = bounds[1] + bounds[3] * 0.445
    return {
        necklineLeft: [ax - u * 0.16, neckY],
        necklineRight: [ax + u * 0.16, neckY],
        shoulderLeftInner: [ax - u * 0.22, shoulderInnerY],
        shoulderLeftOuter: [ax - u * 0.50, shoulderOuterY],
        shoulderRightInner: [ax + u * 0.22, shoulderInnerY],
        shoulderRightOuter: [ax + u * 0.50, shoulderOuterY],
        waistLeft: [ax - bounds[2] * 0.37, waistY],
        waistRight: [ax + bounds[2] * 0.37, waistY],
        waistCenter: [ax, waistY]
    }
end function

' Nine-point face rig. These landmarks are independent of the outer avatar
' silhouette, so masks fit the face itself rather than the cape, helmet, or an
' extended hand that happens to widen the alpha bounds.
function avatarFaceRig(cfg as Object, anatomy as Object) as Object
    u = anatomy.chestToCrown
    sideK = 0.19 : eyeK = 0.11 : crownK = 0.03 : chinK = 0.54
    eyeY = 0.23 : centerY = 0.31 : mouthY = 0.43 : jawY = 0.50
    if cfg.baseSkin = "robot" or cfg.outfit = "o_ultron" then
        sideK = 0.24 : eyeK = 0.15 : crownK = 0.02 : chinK = 0.62
        eyeY = 0.25 : centerY = 0.34 : mouthY = 0.49 : jawY = 0.57
    else if cfg.baseSkin = "emerald" or cfg.outfit = "o_doomarmor" then
        sideK = 0.20 : eyeK = 0.12 : crownK = 0.04 : chinK = 0.56
        eyeY = 0.24 : centerY = 0.31 : mouthY = 0.44 : jawY = 0.51
    else if cfg.baseSkin = "sentinel" or cfg.outfit = "o_starcaptain" then
        sideK = 0.20 : eyeK = 0.105 : crownK = 0.02 : chinK = 0.55
        eyeY = 0.22 : centerY = 0.30 : mouthY = 0.43 : jawY = 0.51
    end if
    ax = anatomy.axisX : cy = anatomy.crownY
    return {
        crown: [ax, cy + u * crownK],
        chin: [ax, cy + u * chinK],
        leftEye: [ax - u * eyeK, cy + u * eyeY],
        rightEye: [ax + u * eyeK, cy + u * eyeY],
        center: [ax, cy + u * centerY],
        leftSide: [ax - u * sideK, cy + u * centerY],
        rightSide: [ax + u * sideK, cy + u * centerY],
        mouth: [ax, cy + u * mouthY],
        jaw: [ax, cy + u * jawY]
    }
end function

function emeraldMaskSourceFaceRig() as Object
    return {
        crown: [50.0, 11.0],
        chin: [50.0, 38.0],
        leftEye: [44.5, 20.0],
        rightEye: [55.5, 20.0],
        center: [50.0, 24.5],
        leftSide: [39.5, 24.5],
        rightSide: [60.5, 24.5],
        mouth: [50.0, 32.5],
        jaw: [50.0, 36.0]
    }
end function

' Measured forearm/hand envelopes from the alpha silhouette of each base.
' Width and length are independent of chest-to-crown and total avatar height.
function avatarArmMetrics(cfg as Object, side as String) as Object
    leftX = 70.0 : topY = 70.0 : armWidth = 18.0 : armLength = 51.0
    if cfg.baseSkin = "robot" or cfg.outfit = "o_ultron" then
        armWidth = 25.5 : armLength = 55.0
    else if cfg.baseSkin = "emerald" or cfg.outfit = "o_doomarmor" then
        armWidth = 20.0 : armLength = 53.0
    else if cfg.baseSkin = "sentinel" or cfg.outfit = "o_starcaptain" then
        leftX = 68.5 : topY = 69.0 : armWidth = 20.0 : armLength = 54.0
    else
        youthBase = cfg.ageGroup = "9-11" or cfg.ageGroup = "12-14"
        if cfg.presentation = "female" then
            armWidth = 16.0 : armLength = 49.0
            if youthBase then armWidth = 15.0 : armLength = 48.0
        else if youthBase then
            leftX = 71.0 : armWidth = 17.0 : armLength = 49.5
        end if
    end if
    x = leftX
    if side = "right" then x = 100.0 - leftX - armWidth
    return [x, topY, armWidth, armLength]
end function

' Hand wearables snap to a rig, not to a generic forearm rectangle. The rig is
' resolved from the active base's measured arm envelope, so both position and
' scale follow the actual elbow-to-fingertip length and forearm/wrist width.
function avatarHandRig(cfg as Object, side as String) as Object
    armBox = avatarArmMetrics(cfg, side)
    x = armBox[0] : y = armBox[1] : w = armBox[2] : h = armBox[3]
    dir = 1.0
    if side = "right" then dir = -1.0
    elbow = [x + w * 0.50, y]
    wristSideK = 0.22
    ' The Sentinel's standardized relaxed pose carries both forearms slightly
    ' outward. Register its wrist from the visible arm edges so cuffs, shields,
    ' and gauntlets meet the actual wrist instead of the torso-side estimate.
    if cfg.baseSkin = "sentinel" or cfg.outfit = "o_starcaptain" then wristSideK = 0.35
    wrist = [elbow[0] + dir * w * wristSideK, y + h * 0.58]
    handCenter = [wrist[0] + dir * w * 0.10, y + h * 0.78]
    thumbX = x + w * 0.20
    if side = "right" then thumbX = x + w * 0.80
    thumbTip = [thumbX, y + h * 0.82]
    knuckles = [wrist[0] + dir * w * 0.08, y + h * 0.72]
    fingertip = [wrist[0] + dir * w * 0.18, y + h]
    wristY = wrist[1]
    bleed = w * 0.08
    if bleed < 1.5 then bleed = 1.5
    baseAngle = 0.12
    if cfg.baseSkin = "robot" or cfg.outfit = "o_ultron" then
        baseAngle = 0.17
    else if cfg.baseSkin = "emerald" or cfg.outfit = "o_doomarmor" then
        baseAngle = 0.15
    else if cfg.presentation = "female" then
        baseAngle = 0.10
    end if
    forearmAngle = -dir * baseAngle
    handAngle = forearmAngle
    forearmSize = [w + bleed * 2.0, wristY - y + 4.5]
    handSize = [w + bleed * 2.0, y + h - wristY + 6.0]
    ' Whole-gauntlet source artwork has transparent padding. These coverage
    ' fractions convert the measured target limb envelope into canvas size
    ' while preserving one continuous gauntlet layer.
    wholeSize = [(w + bleed * 2.0) / 0.78, (h + 2.0) / 0.83]
    elbowInner = [elbow[0] - w * 0.5, elbow[1]]
    elbowOuter = [elbow[0] + w * 0.5, elbow[1]]
    wristInner = [wrist[0] - w * 0.225, wrist[1]]
    wristOuter = [wrist[0] + w * 0.225, wrist[1]]
    sourceRig = {
        elbow: [0.50, 0.042],
        elbowInner: [0.11, 0.042],
        elbowOuter: [0.89, 0.042],
        wrist: [0.50, 0.42],
        handCenter: [0.52, 0.60],
        thumbTip: [0.13, 0.66],
        knuckles: [0.53, 0.64],
        fingertip: [0.49, 0.87]
    }
    return {
        elbow: elbow,
        elbowInner: elbowInner,
        elbowOuter: elbowOuter,
        wrist: wrist,
        wristInner: wristInner,
        wristOuter: wristOuter,
        handCenter: handCenter,
        thumbTip: thumbTip,
        knuckles: knuckles,
        fingertip: fingertip,
        wristWidth: w * 0.45,
        handWidth: w * 0.85,
        bounds: armBox,
        forearmPivot: elbow,
        handPivot: wrist,
        forearmSize: forearmSize,
        handSize: handSize,
        forearmAngle: forearmAngle,
        handAngle: handAngle,
        wholePivot: elbow,
        wholeSize: wholeSize,
        wholeAngle: forearmAngle,
        wholeSourceRig: sourceRig,
        forearmBounds: [x - bleed, y - 1.5, w + bleed * 2.0, wristY - y + 4.5],
        handBounds: [x - bleed, wristY - 3.0, w + bleed * 2.0, y + h - wristY + 6.0]
    }
end function

function avatarAttachmentProfile(cfg as Object) as Object
    bounds = avatarSilhouetteBounds(cfg)
    anatomy = avatarAnatomy(cfg, bounds)
    torsoRig = avatarTorsoRig(cfg, bounds, anatomy)
    rightHandRig = avatarHandRig(cfg, "right")
    leftHandRig = avatarHandRig(cfg, "left")
    ' Head and limb boxes use chest-to-crown anatomy, not total silhouette
    ' height. The silhouette remains authoritative for capes and rear items.
    headRel = [-0.30, 0.0, 0.60, 0.75]
    faceRel = [-0.28, 0.06, 0.56, 0.67]
    gearRel = [-0.57, -0.05, 1.14, 0.96]
    hairRel = [-0.57, 0.05, 1.14, 1.20]
    hoodRel = [-0.52, -0.05, 1.04, 1.32]
    shoulderLeftRel = [-0.93, 0.34, 0.82, 0.89]
    shoulderRightRel = [0.11, 0.34, 0.82, 0.89]
    capeRel = [0.0055, -0.0126, 0.9890, 1.0277]
    ' Doom keeps the standard NBA-height baseline, but its cape-free armor has
    ' a narrower head/shoulder envelope than Ultron. Fit the garment to that
    ' anatomy instead of reusing the robot-sized hood and mantle targets.
    if cfg.baseSkin = "emerald" or cfg.outfit = "o_doomarmor" then
        hoodRel = [-0.45, -0.08, 0.90, 1.20]
        shoulderLeftRel = [-0.72, 0.42, 0.64, 0.72]
        shoulderRightRel = [0.08, 0.42, 0.64, 0.72]
        capeRel = [0.06, -0.0126, 0.88, 1.0277]
    else if cfg.baseSkin <> "robot" and cfg.outfit <> "o_ultron" then
        ' Human heads and shoulders are narrower than either armor base.
        hoodRel = [-0.38, -0.04, 0.76, 0.98]
        shoulderLeftRel = [-0.62, 0.38, 0.56, 0.64]
        shoulderRightRel = [0.06, 0.38, 0.56, 0.64]
    end if
    backRel = [-0.1813, 0.2393, 1.3626, 0.5945]
    handsRel = [-0.0275, 0.4106, 1.0549, 0.2015]
    hatRel = [0.1703, -0.0479, 0.6593, 0.2217]
    headShape = "round"
    if cfg.baseSkin = "robot" or cfg.outfit = "o_ultron" then headShape = "helmet"
    if cfg.baseSkin = "emerald" or cfg.outfit = "o_doomarmor" then headShape = "armored"
    capeBox = edgeRelativeBox(bounds, capeRel)
    if cfg.baseSkin = "emerald" or cfg.outfit = "o_doomarmor" then
        capeBox[0] = anatomy.axisX - capeBox[2] * 0.5
    end if
    faceRig = avatarFaceRig(cfg, anatomy)
    eyeMidY = (faceRig.leftEye[1] + faceRig.rightEye[1]) * 0.5
    hoodPeak = [faceRig.center[0], faceRig.crown[1] + (eyeMidY - faceRig.crown[1]) * 0.82]
    ' The leather harness uses five independent anatomical targets instead of
    ' one full-canvas scale. Shoulder width, torso length, waist width, and
    ' both wrist sizes can therefore change without pulling the other pieces
    ' out of registration.
    harnessTopY = torsoRig.shoulderLeftOuter[1]
    harnessBeltY = torsoRig.waistCenter[1]
    harnessStrapW = torsoRig.shoulderLeftInner[0] - torsoRig.shoulderLeftOuter[0]
    harnessStrapH = harnessBeltY + anatomy.chestToCrown * 0.39 - harnessTopY
    harnessLeftX = torsoRig.shoulderLeftOuter[0]
    harnessRightX = torsoRig.shoulderRightInner[0]
    harnessBeltW = torsoRig.waistRight[0] - torsoRig.waistLeft[0]
    harnessBeltH = anatomy.chestToCrown * 0.39
    leftCuffW = leftHandRig.wristWidth * 1.25
    rightCuffW = rightHandRig.wristWidth * 1.25
    cuffH = anatomy.chestToCrown * 0.13
    return {
        bounds: bounds,
        anatomy: anatomy,
        torsoRig: torsoRig,
        edgeScaleX: bounds[2] / 91.0,
        edgeScaleY: bounds[3] / 198.5,
        headBox: anatomyRelativeBox(anatomy, headRel),
        headShape: headShape,
        face: anatomyRelativeBox(anatomy, faceRel),
        faceRig: faceRig,
        gear: anatomyRelativeBox(anatomy, gearRel),
        hair: anatomyRelativeBox(anatomy, hairRel),
        hoodCenter: anatomyRelativeBox(anatomy, hoodRel),
        hoodPeak: hoodPeak,
        shoulderLeft: anatomyRelativeBox(anatomy, shoulderLeftRel),
        shoulderRight: anatomyRelativeBox(anatomy, shoulderRightRel),
        cape: capeBox,
        back: edgeRelativeBox(bounds, backRel),
        hands: edgeRelativeBox(bounds, handsRel),
        rightHandRig: rightHandRig,
        leftHandRig: leftHandRig,
        rightForearm: rightHandRig.bounds,
        leftForearm: leftHandRig.bounds,
        rightArmAngle: 0,
        leftArmAngle: 0,
        hat: edgeRelativeBox(bounds, hatRel),
        sentinelCowl: anatomyRelativeBox(anatomy, [-0.275, 0.0, 0.55, 0.61]),
        sentinelHarness: anatomyRelativeBox(anatomy, [-0.92, 0.30, 1.84, 1.69]),
        sentinelHarnessLeft: [harnessLeftX, harnessTopY, harnessStrapW, harnessStrapH],
        sentinelHarnessRight: [harnessRightX, harnessTopY, harnessStrapW, harnessStrapH],
        sentinelHarnessBelt: [anatomy.axisX - harnessBeltW * 0.5, harnessBeltY, harnessBeltW, harnessBeltH],
        sentinelHarnessLeftCuff: [leftHandRig.wrist[0] - leftCuffW * 0.5, leftHandRig.wrist[1] - cuffH * 0.5, leftCuffW, cuffH],
        sentinelHarnessRightCuff: [rightHandRig.wrist[0] - rightCuffW * 0.5, rightHandRig.wrist[1] - cuffH * 0.5, rightCuffW, cuffH]
    }
end function

' Garments that wrap a body are assembled from independent panels. Each panel
' fits its own semantic target instead of inheriting one scale from the full
' avatar or from the hood. This is what lets the same cape wrap a robot,
' armored villain, or human body without exposing shoulder plates or clipping.
sub drawGarmentPanel(parent as Object, uri as String, s as Integer, targetBox as Object)
    mkPoster(parent, uri, targetBox[0] * s, targetBox[1] * s, targetBox[2] * s, targetBox[3] * s)
end sub

' Cropped accessory art keeps its authored aspect ratio while scaling to the
' active semantic rig. This is the universal fit path for panels/effects that
' are not registered to a full 100 x 204 avatar canvas.
sub drawRiggedCroppedPoster(parent as Object, uri as String, s as Integer, sourceW as Float, sourceH as Float, targetBox as Object)
    sc = targetBox[2] / sourceW
    sy = targetBox[3] / sourceH
    if sy < sc then sc = sy
    fittedW = sourceW * sc
    fittedH = sourceH * sc
    fittedX = targetBox[0] + (targetBox[2] - fittedW) * 0.5
    fittedY = targetBox[1] + (targetBox[3] - fittedH) * 0.5
    mkPoster(parent, uri, fittedX * s, fittedY * s, fittedW * s, fittedH * s)
end sub

' Vector-rigged panels pivot at a joint and rotate toward the next landmark.
' Their local Y axis is the limb segment; width scales independently to the
' measured target limb without forcing the segment back onto the canvas axes.
sub drawRiggedVectorPanel(parent as Object, uri as String, s as Integer, pivot as Object, panelSize as Object, angle as Float, sourceAnchor as Object)
    g = CreateObject("roSGNode", "Group")
    g.translation = [pivot[0] * s, pivot[1] * s]
    g.rotation = angle
    parent.appendChild(g)
    localX = panelSize[0] * s * sourceAnchor[0] * -1.0
    localY = panelSize[1] * s * sourceAnchor[1] * -1.0
    mkPoster(g, uri, localX, localY, panelSize[0] * s, panelSize[1] * s)
end sub

function anchoredLayerGroup(parent as Object, s as Integer, sourceBox as Object, targetBox as Object) as Object
    sx = targetBox[2] / sourceBox[2]
    sy = targetBox[3] / sourceBox[3]
    sc = sx
    if sy < sc then sc = sy
    g = CreateObject("roSGNode", "Group")
    g.translation = [(targetBox[0] - sourceBox[0] * sc) * s, (targetBox[1] - sourceBox[1] * sc) * s]
    g.scale = [sc, sc]
    parent.appendChild(g)
    return g
end function

sub drawAnchoredFullPoster(parent as Object, uri as String, s as Integer, sourceBox as Object, targetBox as Object)
    g = anchoredLayerGroup(parent, s, sourceBox, targetBox)
    mkPoster(g, uri, 0, 0, 100 * s, 204 * s)
end sub

' Cape length follows avatar height while cape width follows shoulder/body
' width. Independent axes let a narrow Doom cape still reach the floor.
sub drawAnchoredFullPosterXY(parent as Object, uri as String, s as Integer, sourceBox as Object, targetBox as Object)
    sx = targetBox[2] / sourceBox[2]
    sy = targetBox[3] / sourceBox[3]
    g = CreateObject("roSGNode", "Group")
    g.translation = [(targetBox[0] - sourceBox[0] * sx) * s, (targetBox[1] - sourceBox[1] * sy) * s]
    g.scale = [sx, sy]
    parent.appendChild(g)
    mkPoster(g, uri, 0, 0, 100 * s, 204 * s)
end sub

' Fit an atomic mask from nine landmarks. Side/eye widths determine X scale;
' crown/chin and eye/mouth distances determine Y scale. Center alignment then
' keeps the eyes, mouth, jaw, and crown in the same anatomical frame.
sub drawFaceRiggedPoster(parent as Object, uri as String, s as Integer, sourceRig as Object, targetRig as Object)
    sourceSideW = sourceRig.rightSide[0] - sourceRig.leftSide[0]
    targetSideW = targetRig.rightSide[0] - targetRig.leftSide[0]
    sourceEyeW = sourceRig.rightEye[0] - sourceRig.leftEye[0]
    targetEyeW = targetRig.rightEye[0] - targetRig.leftEye[0]
    sx = (targetSideW / sourceSideW) * 0.70 + (targetEyeW / sourceEyeW) * 0.30

    sourceFaceH = sourceRig.chin[1] - sourceRig.crown[1]
    targetFaceH = targetRig.chin[1] - targetRig.crown[1]
    sourceEyeY = (sourceRig.leftEye[1] + sourceRig.rightEye[1]) * 0.5
    targetEyeY = (targetRig.leftEye[1] + targetRig.rightEye[1]) * 0.5
    sourceEyeMouth = sourceRig.mouth[1] - sourceEyeY
    targetEyeMouth = targetRig.mouth[1] - targetEyeY
    sy = (targetFaceH / sourceFaceH) * 0.75 + (targetEyeMouth / sourceEyeMouth) * 0.25

    g = CreateObject("roSGNode", "Group")
    g.translation = [targetRig.center[0] * s, targetRig.center[1] * s]
    g.scale = [sx, sy]
    parent.appendChild(g)
    mkPoster(g, uri, sourceRig.center[0] * s * -1.0, sourceRig.center[1] * s * -1.0, 100 * s, 204 * s)
end sub

' Preserve the hood's fitted size, but register its authored inner peak to the
' active forehead center. This avoids the offset caused by transparent canvas
' bounds and keeps the point above the mask instead of over an eye.
sub drawHoodPeakAnchoredPoster(parent as Object, uri as String, s as Integer, sourceW as Float, sourceH as Float, targetBox as Object, targetPeak as Object)
    sc = targetBox[2] / sourceW
    sy = targetBox[3] / sourceH
    if sy < sc then sc = sy
    fittedW = sourceW * sc
    fittedH = sourceH * sc
    sourcePeakX = 135.0
    sourcePeakY = 90.0
    fittedX = targetPeak[0] - (sourcePeakX / sourceW) * fittedW
    fittedY = targetPeak[1] - (sourcePeakY / sourceH) * fittedH
    mkPoster(parent, uri, fittedX * s, fittedY * s, fittedW * s, fittedH * s)
end sub

sub drawAnchoredModularHat(parent as Object, s as Integer, cfg as Object, targetBox as Object)
    sourceBox = [22, 0, 60, 44]
    g = anchoredLayerGroup(parent, s, sourceBox, targetBox)
    drawModularPilotHat(g, s, cfg)
end sub

sub drawAnchoredModularGear(parent as Object, s as Integer, cfg as Object, targetBox as Object)
    g = anchoredLayerGroup(parent, s, [20, 28, 60, 52], targetBox)
    drawModularPilotGear(g, s, cfg)
end sub

sub drawAnchoredModularBack(parent as Object, s as Integer, cfg as Object, targetBox as Object)
    if cfg.back = "b_emerald_cape" then return
    g = anchoredLayerGroup(parent, s, [-12, 72, 124, 118], targetBox)
    drawModularPilotBack(g, s, cfg)
end sub

sub drawEmeraldWearables(parent as Object, s as Integer, cfg as Object, phase as String)
    profile = avatarAttachmentProfile(cfg)
    if phase = "back" then
        if cfg.back = "b_emerald_cape" then
            drawAnchoredFullPosterXY(parent, "pkg:/images/avatar_modular/outfit_emerald_sovereign_cape.png", s, [5, 0, 90, 204], profile.cape)
        end if
        return
    end if
    if phase = "front" then
        if hasGear(cfg, "g_emerald_mask_slot") then
            drawFaceRiggedPoster(parent, "pkg:/images/avatar_modular/gear_emerald_mask_slot.png", s, emeraldMaskSourceFaceRig(), profile.faceRig)
        else if hasGear(cfg, "g_emerald_mask_mystic") then
            drawFaceRiggedPoster(parent, "pkg:/images/avatar_modular/gear_emerald_mask_mystic.png", s, emeraldMaskSourceFaceRig(), profile.faceRig)
        end if
        if cfg.back = "b_emerald_cape" then
            ' Shoulder panels render first and overlap the active base skin.
            ' The center hood/collar renders last so its clasps and folds hide
            ' the panel seams and the garment reads as one fitted cape.
            drawRiggedCroppedPoster(parent, "pkg:/images/avatar_modular/outfit_emerald_sovereign_shoulder_left_v3.png", s, 292.0, 296.0, profile.shoulderLeft)
            drawRiggedCroppedPoster(parent, "pkg:/images/avatar_modular/outfit_emerald_sovereign_shoulder_right_v3.png", s, 292.0, 296.0, profile.shoulderRight)
            drawHoodPeakAnchoredPoster(parent, "pkg:/images/avatar_modular/outfit_emerald_sovereign_hood_center_v5.png", s, 260.0, 336.0, profile.hoodCenter, profile.hoodPeak)
        end if
        return
    end if
    if phase = "effect" then
        if hasHandItem(cfg, "g_space_magic_gauntlet_right") then
            ' Character-right is viewer-left in the standard front pose.
            ' The gauntlet includes the forearm cuff through fingertips and
            ' binds to the shared neutral right-forearm target.
            ' The source artwork is registered to the same full avatar canvas.
            ' Uniform landmark fitting preserves its elbow/wrist/hand pose.
            drawRiggedVectorPanel(parent, "pkg:/images/avatar_modular/gauntlet_right_whole_v9.png", s, profile.rightHandRig.wholePivot, profile.rightHandRig.wholeSize, profile.rightHandRig.wholeAngle, profile.rightHandRig.wholeSourceRig.elbow)
        end if
        if hasHandItem(cfg, "g_space_magic_gauntlet_left") then
            drawRiggedVectorPanel(parent, "pkg:/images/avatar_modular/gauntlet_left_whole_v9.png", s, profile.leftHandRig.wholePivot, profile.leftHandRig.wholeSize, profile.leftHandRig.wholeAngle, profile.leftHandRig.wholeSourceRig.elbow)
        end if
        if hasHandItem(cfg, "g_emerald_magic") then
            ' The effect artwork is a paired, hand-local strip. Its target ends
            ' just above the wrists and never scales from the avatar's height.
            drawRiggedCroppedPoster(parent, "pkg:/images/avatar_modular/gear_emerald_magic.png", s, 384.0, 192.0, profile.hands)
        end if
    end if
end sub

sub drawEmeraldWearablesAt(parent as Object, ox as Integer, oy as Integer, s as Integer, cfg as Object, phase as String)
    g = CreateObject("roSGNode", "Group")
    g.translation = [ox, oy]
    parent.appendChild(g)
    drawEmeraldWearables(g, s, cfg, phase)
end sub

' Star Sentinel pieces remain independent from the base skin. The cowl and
' leather rig fit semantic anatomy boxes; the shield follows the active left
' wrist/hand rig. The same assets therefore remain usable on every base that
' obeys the shared neutral-pose landmarks.
sub drawStarSentinelWearables(parent as Object, s as Integer, cfg as Object, phase as String)
    profile = avatarAttachmentProfile(cfg)
    if phase = "front" then
        if hasGear(cfg, "g_star_sentinel_harness") then
            ' Source-side names describe the photographed strap, not the viewer side.
            ' Cross-map them so each curved strap follows the avatar's chest contour.
            drawGarmentPanel(parent, "pkg:/images/avatar_modular/gear_star_sentinel_harness_right_v2.png", s, profile.sentinelHarnessLeft)
            drawGarmentPanel(parent, "pkg:/images/avatar_modular/gear_star_sentinel_harness_left_v2.png", s, profile.sentinelHarnessRight)
            drawGarmentPanel(parent, "pkg:/images/avatar_modular/gear_star_sentinel_harness_belt_v2.png", s, profile.sentinelHarnessBelt)
            drawGarmentPanel(parent, "pkg:/images/avatar_modular/gear_star_sentinel_harness_cuff_right_v2.png", s, profile.sentinelHarnessLeftCuff)
            drawGarmentPanel(parent, "pkg:/images/avatar_modular/gear_star_sentinel_harness_cuff_left_v2.png", s, profile.sentinelHarnessRightCuff)
        end if
        if hasGear(cfg, "g_star_sentinel_cowl") then
            if cfg.baseSkin = "sentinel" or cfg.outfit = "o_starcaptain" then
                mkPoster(parent, "pkg:/images/avatar_modular/gear_star_sentinel_cowl_ballistic_v3.png", 0, 0, 100 * s, 204 * s)
            else
                drawAnchoredFullPoster(parent, "pkg:/images/avatar_modular/gear_star_sentinel_cowl_ballistic_v3.png", s, [36.5, 0.0, 27.0, 32.0], profile.sentinelCowl)
            end if
        end if
        return
    end if
    if phase = "hand" and hasHandItem(cfg, "g_star_sentinel_shield") then
        rig = profile.leftHandRig
        shieldD = rig.bounds[3] * 1.38
        ' The shield is strapped to the wrist but its broad face rests inward
        ' across the torso. Keeping the center near the outer hand clipped most
        ' of every size increase at the avatar canvas edge.
        shieldCX = rig.handCenter[0] - rig.bounds[2] * 0.85
        shieldCY = rig.wrist[1] + rig.bounds[3] * 0.12
        mkPoster(parent, "pkg:/images/avatar_modular/hand_star_sentinel_shield_v1.png", (shieldCX - shieldD * 0.5) * s, (shieldCY - shieldD * 0.5) * s, shieldD * s, shieldD * s)
    end if
end sub

function drawModularPilotAvatar(parent as Object, ox as Integer, oy as Integer, s as Integer, cfg as Object, mode as String) as Boolean
    outfitUri = modularPilotOutfitUri(cfg.outfit)
    robot = cfg.baseSkin = "robot" or cfg.outfit = "o_ultron"
    emerald = cfg.baseSkin = "emerald" or cfg.outfit = "o_doomarmor"
    sentinel = cfg.baseSkin = "sentinel" or cfg.outfit = "o_starcaptain"
    armored = robot or emerald or sentinel
    if not armored and outfitUri = "" then return false
    if armored and (cfg.outfit = "o_ultron" or cfg.outfit = "o_doomarmor") then outfitUri = ""

    viewport = CreateObject("roSGNode", "Group")
    parent.appendChild(viewport)
    layer = CreateObject("roSGNode", "Group")
    viewport.appendChild(layer)
    if mode = "head" then
        viewport.translation = [ox, oy]
        viewport.clippingRect = [0, 0, 100 * s, 100 * s]
        layer.translation = [-30 * s, -12 * s]
        layer.scale = [1.6, 1.6]
        if armored and cfg.hat <> invalid and cfg.hat <> "h_none" then
            layer.translation = [-20 * s, 26 * s]
            layer.scale = [1.4, 1.4]
        end if
    else
        hs = heightScale(cfg.height) * ageHeightScale(cfg.ageGroup)
        ws = ageWidthScale(cfg.ageGroup)
        if cfg.shape = "skinny" then ws = ws * 0.90
        if cfg.shape = "fem" then ws = ws * 0.96
        if cfg.shape = "muscle" then ws = ws * 1.08
        if armored and cfg.hat <> invalid and cfg.hat <> "h_none" then
            ' Reserve space above the high helmet for a separately worn hat.
            ws = ws * 0.90
            hs = hs * 0.90
        end if
        layer.translation = [ox + (50 * s * (1.0 - ws)), oy + (204 * s * (1.0 - hs))]
        layer.scale = [ws, hs]
    end if

    oldEffects = m.avatarEffectsEnabled : m.avatarEffectsEnabled = false
    ' Premium full-armor skins keep their existing catalog IDs but supply the
    ' illustrated base figure. All wearable layers remain independent so an
    ' owned skin never locks out hair, hats, makeup, glasses, tattoos, or pets.
    if armored then
        backLayer = CreateObject("roSGNode", "Group")
        layer.appendChild(backLayer)
        drawEmeraldWearables(backLayer, s, cfg, "back")
        profile = avatarAttachmentProfile(cfg)
        drawAnchoredModularBack(backLayer, s, cfg, profile.back)
        armorUri = "pkg:/images/avatar_modular/outfit_ultron.png"
        if emerald then armorUri = "pkg:/images/avatar_modular/outfit_emerald_sovereign_body.png"
        if sentinel then armorUri = "pkg:/images/avatar_modular/outfit_star_sentinel_body_v12.png"
        mkPoster(layer, armorUri, 0, 0, 100 * s, 204 * s)
        if not sentinel then drawIllustratedClothes(layer, s, cfg, true, outfitUri, true)
        hairUri = modularHairUri(cfg.hair)
        if hairUri <> "" and not sentinel then
            hairLayer = anchoredLayerGroup(layer, s, [20, 20, 60, 65], profile.hair)
            mkTintedAvatarPoster(hairLayer, hairUri, 0, 0, 100 * s, 204 * s, hairColors()[cfg.hcol])
        end if
        drawModularPilotTattoo(layer, s, cfg)
        drawAnchoredModularGear(layer, s, cfg, profile.gear)
        drawEmeraldWearables(layer, s, cfg, "front")
        drawStarSentinelWearables(layer, s, cfg, "front")
        ' Hats are attached to the active head profile, so Santa hats,
        ' antlers, and future headwear remain usable on either armor skin.
        hatLayer = CreateObject("roSGNode", "Group")
        layer.appendChild(hatLayer)
        drawAnchoredModularHat(hatLayer, s, cfg, avatarAttachmentProfile(cfg).hat)
        drawEmeraldWearables(layer, s, cfg, "effect")
        drawStarSentinelWearables(layer, s, cfg, "hand")
        if mode = "full" then drawPet(layer, 0, 0, s, cfg.pet, cfg.petColor)
        m.avatarEffectsEnabled = oldEffects
        return true
    end if
    profile = avatarAttachmentProfile(cfg)
    drawEmeraldWearables(layer, s, cfg, "back")
    drawModularPilotBack(layer, s, cfg)
    youthBase = cfg.ageGroup = "9-11" or cfg.ageGroup = "12-14"
    humanBodyUri = "pkg:/images/avatar_modular/body_skin_standard_v3.png"
    if cfg.presentation = "female" then
        humanBodyUri = "pkg:/images/avatar_modular/body_skin_standard_female_v1.png"
        if youthBase then humanBodyUri = "pkg:/images/avatar_modular/body_skin_standard_child_female_v1.png"
    else if youthBase then
        humanBodyUri = "pkg:/images/avatar_modular/body_skin_standard_child_v1.png"
    end if
    mkTintedAvatarPoster(layer, humanBodyUri, 0, 0, 100 * s, 204 * s, skinColors()[cfg.skin])
    drawIllustratedClothes(layer, s, cfg, false, outfitUri, true)
    faceLayer = anchoredLayerGroup(layer, s, [30, 38, 40, 44], profile.face)
    mkPoster(faceLayer, "pkg:/images/avatar_modular/face_features.png", 0, 0, 100 * s, 204 * s)
    mkTintedAvatarPoster(faceLayer, "pkg:/images/avatar_modular/eye_iris.png", 0, 0, 100 * s, 204 * s, eyeColors()[cfg.ecol])
    hairUri = modularHairUri(cfg.hair)
    if hairUri <> "" then
        hairLayer = anchoredLayerGroup(layer, s, [20, 20, 60, 65], profile.hair)
        mkTintedAvatarPoster(hairLayer, hairUri, 0, 0, 100 * s, 204 * s, hairColors()[cfg.hcol])
    end if
    drawModularPilotTattoo(layer, s, cfg)
    drawAnchoredModularGear(layer, s, cfg, profile.gear)
    drawEmeraldWearables(layer, s, cfg, "front")
    drawStarSentinelWearables(layer, s, cfg, "front")
    drawAnchoredModularHat(layer, s, cfg, avatarAttachmentProfile(cfg).hat)
    drawEmeraldWearables(layer, s, cfg, "effect")
    drawStarSentinelWearables(layer, s, cfg, "hand")
    if mode = "full" then drawPet(layer, 0, 0, s, cfg.pet, cfg.petColor)
    m.avatarEffectsEnabled = oldEffects
    return true
end function

sub drawPet(p as Object, ox as Integer, oy as Integer, s as Integer, id as String, variant as Integer)
    if id = invalid or id = "pet_none" then return
    if id = "pet_pilot_dog" then
        mkPoster(p, "pkg:/images/avatar_pilot/pilot_dog.png", ox + 86 * s, oy + 140 * s, 54 * s, 64 * s)
        return
    end if
    ' Map the existing natural-color cat to pilot art without changing its id,
    ' ownership, or equipped state. Other color variants retain the fallback.
    if id = "pet_cat" and variant = 0 then
        mkPoster(p, "pkg:/images/avatar_pilot/pilot_cat.png", ox + 86 * s, oy + 140 * s, 54 * s, 64 * s)
        return
    end if
    pal = petPalette(id, variant)
    pc = pal[0]
    ps = pal[1]
    pa = pal[2]
    ' grounded shadow and layered highlights keep every pet readable beside the
    ' smoother avatar at both Studio and inventory-preview sizes
    ur(p, ox, oy, s, 92, 201, 43, 4, "0x05081270")
    if id = "pet_dog" then
        ur(p, ox, oy, s, 94, 174, 30, 20, pc)
        ur(p, ox, oy, s, 98, 176, 20, 4, "0xFFFFFF24")
        ur(p, ox, oy, s, 100, 185, 19, 6, ps)
        ur(p, ox, oy, s, 112, 158, 22, 22, pa)
        ur(p, ox, oy, s, 110, 155, 7, 13, ps)
        ur(p, ox, oy, s, 130, 155, 7, 13, ps)
        ur(p, ox, oy, s, 114, 171, 16, 7, "0xFFFFFF35")
        ur(p, ox, oy, s, 128, 169, 7, 5, "0x3B2314FF")
        ur(p, ox, oy, s, 116, 164, 3, 3, "0x1B1B1BFF")
        ur(p, ox, oy, s, 126, 164, 3, 3, "0x1B1B1BFF")
        ur(p, ox, oy, s, 117, 164, 1, 1, "0xFFFFFFFF")
        ur(p, ox, oy, s, 127, 164, 1, 1, "0xFFFFFFFF")
        ur(p, ox, oy, s, 115, 178, 17, 3, "0xD6322EFF")
        ur(p, ox, oy, s, 122, 179, 4, 4, "0xFFD66BFF")
        ur(p, ox, oy, s, 98, 192, 7, 12, ps)
        ur(p, ox, oy, s, 116, 192, 7, 12, ps)
        ur(p, ox, oy, s, 97, 201, 9, 3, "0x3B2314FF")
        ur(p, ox, oy, s, 115, 201, 9, 3, "0x3B2314FF")
        ur(p, ox, oy, s, 88, 166, 7, 4, pc)
        ur(p, ox, oy, s, 86, 163, 5, 5, pa)
    else if id = "pet_cat" then
        ur(p, ox, oy, s, 98, 174, 26, 20, pc)
        ur(p, ox, oy, s, 102, 176, 17, 4, "0xFFFFFF20")
        ur(p, ox, oy, s, 103, 184, 17, 5, ps)
        ur(p, ox, oy, s, 112, 158, 20, 20, pc)
        ur(p, ox, oy, s, 112, 152, 7, 9, pc)
        ur(p, ox, oy, s, 125, 152, 7, 9, pc)
        ur(p, ox, oy, s, 114, 154, 3, 5, pa)
        ur(p, ox, oy, s, 127, 154, 3, 5, pa)
        ur(p, ox, oy, s, 117, 165, 4, 4, pa)
        ur(p, ox, oy, s, 126, 165, 4, 4, pa)
        ur(p, ox, oy, s, 118, 165, 1, 2, "0xFFFFFFFF")
        ur(p, ox, oy, s, 127, 165, 1, 2, "0xFFFFFFFF")
        ur(p, ox, oy, s, 120, 171, 6, 3, "0xF4F7FFFF")
        ur(p, ox, oy, s, 122, 169, 3, 3, "0xF59AB8FF")
        ur(p, ox, oy, s, 110, 171, 10, 1, "0xFFFFFF80")
        ur(p, ox, oy, s, 127, 171, 10, 1, "0xFFFFFF80")
        ur(p, ox, oy, s, 110, 174, 10, 1, "0xFFFFFF60")
        ur(p, ox, oy, s, 127, 174, 10, 1, "0xFFFFFF60")
        ur(p, ox, oy, s, 101, 192, 6, 12, ps)
        ur(p, ox, oy, s, 116, 192, 6, 12, ps)
        ur(p, ox, oy, s, 100, 201, 8, 3, "0x15171CFF")
        ur(p, ox, oy, s, 115, 201, 8, 3, "0x15171CFF")
        ur(p, ox, oy, s, 91, 166, 5, 26, pc)
        ur(p, ox, oy, s, 89, 162, 5, 7, pa)
    else if id = "pet_bunny" then
        ur(p, ox, oy, s, 98, 176, 28, 19, pc)
        ur(p, ox, oy, s, 102, 178, 18, 4, "0xFFFFFF45")
        ur(p, ox, oy, s, 112, 158, 21, 21, ps)
        ur(p, ox, oy, s, 114, 140, 7, 22, ps)
        ur(p, ox, oy, s, 125, 140, 7, 22, ps)
        ur(p, ox, oy, s, 116, 144, 3, 13, pa)
        ur(p, ox, oy, s, 127, 144, 3, 13, pa)
        ur(p, ox, oy, s, 117, 166, 3, 3, "0x26324AFF")
        ur(p, ox, oy, s, 127, 166, 3, 3, "0x26324AFF")
        ur(p, ox, oy, s, 118, 166, 1, 1, "0xFFFFFFFF")
        ur(p, ox, oy, s, 128, 166, 1, 1, "0xFFFFFFFF")
        ur(p, ox, oy, s, 129, 172, 4, 4, pa)
        ur(p, ox, oy, s, 122, 176, 9, 2, "0xD889A2FF")
        ur(p, ox, oy, s, 94, 178, 8, 8, ps)
        ur(p, ox, oy, s, 92, 180, 5, 5, "0xFFFFFFFF")
        ur(p, ox, oy, s, 102, 192, 9, 11, ps)
        ur(p, ox, oy, s, 116, 192, 9, 11, ps)
        ur(p, ox, oy, s, 101, 201, 11, 3, pa)
        ur(p, ox, oy, s, 115, 201, 11, 3, pa)
    else if id = "pet_dragon" then
        ur(p, ox, oy, s, 96, 174, 30, 21, pc)
        ur(p, ox, oy, s, 100, 176, 20, 4, "0xFFFFFF25")
        ur(p, ox, oy, s, 101, 185, 20, 6, ps)
        ur(p, ox, oy, s, 112, 157, 23, 22, pc)
        ur(p, ox, oy, s, 115, 151, 5, 8, pa)
        ur(p, ox, oy, s, 126, 149, 5, 10, pa)
        ur(p, ox, oy, s, 119, 145, 4, 8, pa)
        ur(p, ox, oy, s, 129, 168, 8, 5, ps)
        ur(p, ox, oy, s, 117, 164, 3, 3, "0x1B1B1BFF")
        ur(p, ox, oy, s, 127, 164, 3, 3, "0x1B1B1BFF")
        ur(p, ox, oy, s, 118, 164, 1, 1, "0xFFFFFFFF")
        ur(p, ox, oy, s, 128, 164, 1, 1, "0xFFFFFFFF")
        ur(p, ox, oy, s, 132, 174, 4, 2, pa)
        ur(p, ox, oy, s, 90, 166, 9, 19, ps)
        ur(p, ox, oy, s, 84, 171, 10, 6, ps)
        ur(p, ox, oy, s, 86, 173, 5, 2, pa)
        ur(p, ox, oy, s, 95, 166, 9, 5, pa)
        ur(p, ox, oy, s, 101, 193, 6, 11, ps)
        ur(p, ox, oy, s, 117, 193, 6, 11, ps)
        ur(p, ox, oy, s, 99, 201, 9, 3, "0x26324AFF")
        ur(p, ox, oy, s, 115, 201, 9, 3, "0x26324AFF")
    else if id = "pet_robot" then
        ur(p, ox, oy, s, 99, 173, 28, 25, pc)
        ur(p, ox, oy, s, 103, 176, 20, 4, "0xFFFFFF45")
        ur(p, ox, oy, s, 104, 190, 18, 4, "0x151A22FF")
        ur(p, ox, oy, s, 104, 154, 23, 20, ps)
        ur(p, ox, oy, s, 107, 157, 17, 3, "0xFFFFFF55")
        ur(p, ox, oy, s, 108, 160, 5, 5, pa)
        ur(p, ox, oy, s, 119, 160, 5, 5, pa)
        ur(p, ox, oy, s, 109, 161, 2, 2, "0xFFFFFFFF")
        ur(p, ox, oy, s, 120, 161, 2, 2, "0xFFFFFFFF")
        ur(p, ox, oy, s, 114, 149, 3, 6, pa)
        ur(p, ox, oy, s, 111, 148, 9, 2, "0x4E5763FF")
        ur(p, ox, oy, s, 110, 170, 11, 2, "0x303741FF")
        ur(p, ox, oy, s, 110, 181, 7, 7, pa)
        ur(p, ox, oy, s, 112, 183, 3, 3, "0xFFFFFFFF")
        ur(p, ox, oy, s, 101, 198, 7, 6, ps)
        ur(p, ox, oy, s, 118, 198, 7, 6, ps)
        ur(p, ox, oy, s, 100, 201, 9, 3, "0x303741FF")
        ur(p, ox, oy, s, 117, 201, 9, 3, "0x303741FF")
    end if
end sub

sub drawAvatar(p as Object, ox as Integer, oy0 as Integer, s as Integer, cfg as Object, mode as String)
    priorAvatarEffects = m.avatarEffectsEnabled
    m.avatarEffectsEnabled = (mode = "full" and s >= 2)
    oy = oy0
    full = (mode = "full")
    if drawModularPilotAvatar(p, ox, oy, s, cfg, mode) then
        m.avatarEffectsEnabled = priorAvatarEffects
        return
    end if
    if not full then oy = oy0 - 14 * s
    if full then
        hs = heightScale(cfg.height) * ageHeightScale(cfg.ageGroup)
        ws = ageWidthScale(cfg.ageGroup)
        avatarLayer = CreateObject("roSGNode", "Group")
        avatarLayer.translation = [ox + (50 * s * (1.0 - ws)), oy + (205 * s * (1.0 - hs))]
        avatarLayer.scale = [ws, hs]
        p.appendChild(avatarLayer)
        p = avatarLayer
        ox = 0
        oy = 0
    end if
    sk = skinColors()
    skin = sk[cfg.skin]
    hcs = hairColors()
    hair = hcs[cfg.hcol]
    ecs = eyeColors()
    eye = ecs[cfg.ecol]
    o = itemById(cfg.outfit)
    if o = invalid then o = itemById("o_blue")
    topC = o.top
    botC = o.bottom
    styleN = o.style
    trimC = o.trim
    jerseyNum = ""
    if o.num <> invalid then jerseyNum = o.num
    sleeves = o.sleeves
    robe = o.robe
    shorts = (left(o.id, 8) = "o_jeans_" or o.style = "basket")
    cheer = (left(o.id, 7) = "o_cheer")
    legTrim = ""
    if styleN = "jersey" or styleN = "basket" then legTrim = trimC
    tp = itemById(cfg.top)
    topOverride = false
    if tp <> invalid then
        if tp.id <> "t_none" then
            topOverride = true
            topC = tp.top
            styleN = tp.style
            trimC = tp.trim
            sleeves = tp.sleeves
            jerseyNum = ""
            if tp.num <> invalid then jerseyNum = tp.num
        end if
    end if
    bt = itemById(cfg.bottom)
    bottomOverride = false
    bottomCut = ""
    if bt <> invalid then
        if bt.id <> "p_none" then
            bottomOverride = true
            botC = bt.bottom
            legTrim = bt.trim
            shorts = false
            if bt.shorts <> invalid then shorts = bt.shorts
            if bt.cut <> invalid then bottomCut = bt.cut
            cheer = false
            robe = false
        end if
    end if
    shape = cfg.shape
    ' Keep child, preteen and teen silhouettes age-appropriate. Presentation
    ' remains visible through the face and styling rather than adult curves.
    if isYouthAge(cfg.ageGroup) and shape = "fem" then shape = "skinny"
    if not isYouthAge(cfg.ageGroup) and cfg.presentation = "female" and shape = "std" then shape = "fem"
    alx = 6
    arw = 16
    arx = 78
    llx = 22
    lrx = 52
    lw = 26
    if shape = "fem" then
        alx = 10
        arw = 14
        arx = 76
        llx = 24
        lw = 24
    else if shape = "skinny" then
        alx = 12
        arw = 11
        arx = 77
        llx = 27
        lrx = 53
        lw = 20
    else if shape = "muscle" then
        alx = -4
        arw = 20
        arx = 84
        llx = 20
        lw = 28
    end if
    back = cfg.back
    hid = cfg.hair

    ' soft block shadow gives the figure a stage instead of a floating pose
    if full then
        ur(p, ox, oy, s, 16, 201, 68, 5, "0x070B16A0")
        ur(p, ox, oy, s, 25, 198, 50, 5, "0x070B16A0")
    end if

    ' things behind the body
    if full then
        drawEmeraldWearablesAt(p, ox, oy, s, cfg, "back")
        if back = "b_cape" then
            ur(p, ox, oy, s, 18, 80, 64, 104, "0xC0283CFF")
            ur(p, ox, oy, s, 18, 80, 5, 102, "0xFFFFFF24")
            ur(p, ox, oy, s, 77, 80, 5, 102, "0x00000028")
            ur(p, ox, oy, s, 43, 78, 14, 7, "0xFFD66BFF")
        end if
        if back = "b_wings" then
            ur(p, ox, oy, s, -14, 66, 28, 52, "0xF4F7FFFF")
            ur(p, ox, oy, s, 86, 66, 28, 52, "0xF4F7FFFF")
            ur(p, ox, oy, s, -14, 66, 28, 6, "0xCFD8F0FF")
            ur(p, ox, oy, s, 86, 66, 28, 6, "0xCFD8F0FF")
            ur(p, ox, oy, s, -8, 78, 18, 5, "0xCFD8F0FF")
            ur(p, ox, oy, s, -4, 92, 14, 5, "0xCFD8F0FF")
            ur(p, ox, oy, s, 90, 78, 18, 5, "0xCFD8F0FF")
            ur(p, ox, oy, s, 90, 92, 14, 5, "0xCFD8F0FF")
        end if
        if back = "b_jet" then
            ur(p, ox, oy, s, 10, 84, 14, 48, "0x8A8F9CFF")
            ur(p, ox, oy, s, 76, 84, 14, 48, "0x8A8F9CFF")
            ur(p, ox, oy, s, 13, 132, 8, 12, "0xFF8A2AFF")
            ur(p, ox, oy, s, 79, 132, 8, 12, "0xFF8A2AFF")
            ur(p, ox, oy, s, 15, 136, 4, 12, "0xFFD66BFF")
            ur(p, ox, oy, s, 81, 136, 4, 12, "0xFFD66BFF")
            ur(p, ox, oy, s, 12, 94, 10, 5, "0xD8E2F0FF")
            ur(p, ox, oy, s, 78, 94, 10, 5, "0xD8E2F0FF")
        end if
        if back = "b_pack" then
            ur(p, ox, oy, s, 12, 90, 12, 44, "0x8A5A2BFF")
            ur(p, ox, oy, s, 76, 90, 12, 44, "0x8A5A2BFF")
            ur(p, ox, oy, s, 12, 112, 12, 14, "0x6E431FFF")
            ur(p, ox, oy, s, 76, 112, 12, 14, "0x6E431FFF")
            ur(p, ox, oy, s, 16, 116, 4, 4, "0xFFD66BFF")
            ur(p, ox, oy, s, 80, 116, 4, 4, "0xFFD66BFF")
        end if
    end if
    if hid = "r_afro" then ur(p, ox, oy, s, 22, 22, 56, 52, hair)

    ' legs and shoes
    if full then
        if shorts then
            ur(p, ox, oy, s, llx, 144, lw, 52, skin)
            ur(p, ox, oy, s, lrx, 144, lw, 52, skin)
            ur(p, ox, oy, s, llx, 144, lw, 26, botC)
            ur(p, ox, oy, s, lrx, 144, lw, 26, botC)
            ur(p, ox, oy, s, llx, 168, lw, 2, "0xFFFFFF55")
            ur(p, ox, oy, s, lrx, 168, lw, 2, "0xFFFFFF55")
        else if cheer then
            ur(p, ox, oy, s, llx, 144, lw, 52, skin)
            ur(p, ox, oy, s, lrx, 144, lw, 52, skin)
            ur(p, ox, oy, s, llx, 172, lw, 24, "0xFFFFFFFF")
            ur(p, ox, oy, s, lrx, 172, lw, 24, "0xFFFFFFFF")
        else
            ur(p, ox, oy, s, llx, 144, lw, 52, botC)
            ur(p, ox, oy, s, lrx, 144, lw, 52, botC)
            if legTrim <> "" and not robe then
                ur(p, ox, oy, s, llx, 144, 3, 52, legTrim)
                ur(p, ox, oy, s, lrx + lw - 3, 144, 3, 52, legTrim)
            end if
        end if
        if robe then ur(p, ox, oy, s, 20, 144, 60, 52, topC)
        if bottomCut = "skirt" then
            ur(p, ox, oy, s, llx, 166, lw, 30, skin)
            ur(p, ox, oy, s, lrx, 166, lw, 30, skin)
            ur(p, ox, oy, s, 20, 140, 60, 30, botC)
            ur(p, ox, oy, s, 16, 164, 68, 8, legTrim)
        else if bottomCut = "tutu" then
            ur(p, ox, oy, s, llx, 158, lw, 38, skin)
            ur(p, ox, oy, s, lrx, 158, lw, 38, skin)
            ur(p, ox, oy, s, 12, 138, 76, 14, botC)
            ur(p, ox, oy, s, 18, 152, 64, 10, "0xF4C6DCFF")
            ur(p, ox, oy, s, 24, 162, 52, 5, legTrim)
        else if bottomCut = "robe" then
            ur(p, ox, oy, s, 18, 140, 64, 56, botC)
            ur(p, ox, oy, s, 18, 140, 5, 56, legTrim)
            ur(p, ox, oy, s, 77, 140, 5, 56, "0x00000022")
        end if
        ur(p, ox, oy, s, llx, 196, lw, 8, "0x2B2B2BFF")
        ur(p, ox, oy, s, lrx, 196, lw, 8, "0x2B2B2BFF")
        ' soles, toe caps and trouser seams add readable depth
        ur(p, ox, oy, s, llx, 202, lw + 3, 3, "0x101218FF")
        ur(p, ox, oy, s, lrx, 202, lw + 3, 3, "0x101218FF")
        ur(p, ox, oy, s, llx + lw - 7, 198, 7, 3, "0x555A66FF")
        ur(p, ox, oy, s, lrx + lw - 7, 198, 7, 3, "0x555A66FF")
        if not shorts and not cheer and not robe then
            ur(p, ox, oy, s, llx + 2, 176, lw - 4, 2, "0x00000020")
            ur(p, ox, oy, s, lrx + 2, 176, lw - 4, 2, "0x00000020")
        end if
        if not bottomOverride and (o.id = "o_nutcracker_prince" or o.id = "o_toysoldier") then
            stripe = "0xE8B93CFF"
            if o.id = "o_toysoldier" then stripe = "0xD52D3CFF"
            ur(p, ox, oy, s, llx, 144, 4, 47, stripe)
            ur(p, ox, oy, s, lrx + lw - 4, 144, 4, 47, stripe)
            ur(p, ox, oy, s, llx + 3, 174, lw - 6, 5, stripe)
            ur(p, ox, oy, s, lrx + 3, 174, lw - 6, 5, stripe)
            ur(p, ox, oy, s, llx, 181, lw, 15, "0x20232AFF")
            ur(p, ox, oy, s, lrx, 181, lw, 15, "0x20232AFF")
            ur(p, ox, oy, s, llx + 4, 183, lw - 8, 4, "0x4E535EFF")
            ur(p, ox, oy, s, lrx + 4, 183, lw - 8, 4, "0x4E535EFF")
        else if not bottomOverride and o.id = "o_clara" then
            ur(p, ox, oy, s, llx + 2, 190, lw - 4, 7, "0xF7F3E8FF")
            ur(p, ox, oy, s, lrx + 2, 190, lw - 4, 7, "0xF7F3E8FF")
            ur(p, ox, oy, s, llx + 6, 196, lw - 6, 6, "0x78B9E8FF")
            ur(p, ox, oy, s, lrx + 6, 196, lw - 6, 6, "0x78B9E8FF")
        else if not bottomOverride and o.id = "o_sugarplum" then
            ur(p, ox, oy, s, llx + 7, 194, lw - 10, 8, "0xC879B1FF")
            ur(p, ox, oy, s, lrx + 7, 194, lw - 10, 8, "0xC879B1FF")
            ur(p, ox, oy, s, llx + 3, 182, lw - 6, 3, "0xF2D36BFF")
            ur(p, ox, oy, s, lrx + 3, 182, lw - 6, 3, "0xF2D36BFF")
        else if not bottomOverride and o.id = "o_ultron" then
            ' segmented hip, knee and shin armor with exposed mechanical joints
            ur(p, ox, oy, s, llx + 2, 145, lw - 4, 18, "0x626B78FF")
            ur(p, ox, oy, s, lrx + 2, 145, lw - 4, 18, "0x626B78FF")
            ur(p, ox, oy, s, llx + 5, 148, lw - 10, 3, "0x929AA5FF")
            ur(p, ox, oy, s, lrx + 5, 148, lw - 10, 3, "0x929AA5FF")
            ur(p, ox, oy, s, llx + 4, 163, lw - 8, 9, "0x151A22FF")
            ur(p, ox, oy, s, lrx + 4, 163, lw - 8, 9, "0x151A22FF")
            ur(p, ox, oy, s, llx + 7, 165, lw - 14, 5, "0xD51F3CFF")
            ur(p, ox, oy, s, lrx + 7, 165, lw - 14, 5, "0xD51F3CFF")
            ur(p, ox, oy, s, llx + 2, 172, lw - 4, 22, "0x505966FF")
            ur(p, ox, oy, s, lrx + 2, 172, lw - 4, 22, "0x505966FF")
            ur(p, ox, oy, s, llx + 5, 176, 4, 15, "0x89929EFF")
            ur(p, ox, oy, s, lrx + lw - 9, 176, 4, 15, "0x89929EFF")
            ur(p, ox, oy, s, llx + lw - 6, 174, 3, 18, "0x202630FF")
            ur(p, ox, oy, s, lrx + 3, 174, 3, 18, "0x202630FF")
            ur(p, ox, oy, s, llx + 9, 181, lw - 18, 3, "0xD51F3CFF")
            ur(p, ox, oy, s, lrx + 9, 181, lw - 18, 3, "0xD51F3CFF")
            ur(p, ox, oy, s, llx, 194, lw + 2, 8, "0x303741FF")
            ur(p, ox, oy, s, lrx, 194, lw + 2, 8, "0x303741FF")
        end if
    end if

    ' torso (shape changes the outline)
    if not full then
        if shape = "fem" then
            ur(p, ox, oy, s, 24, 80, 52, 10, topC)
        else if shape = "skinny" then
            ur(p, ox, oy, s, 30, 80, 40, 10, topC)
        else if shape = "muscle" then
            ur(p, ox, oy, s, 16, 80, 68, 10, topC)
        else
            ur(p, ox, oy, s, 22, 80, 56, 10, topC)
        end if
    else
        sx = 22
        sw2 = 56
        if shape = "fem" then
            hipC = botC
            if robe then hipC = topC
            ur(p, ox, oy, s, 24, 80, 52, 16, topC)
            ur(p, ox, oy, s, 28, 96, 44, 26, topC)
            ur(p, ox, oy, s, 23, 122, 54, 22, hipC)
            sx = 28
            sw2 = 44
        else if shape = "skinny" then
            ur(p, ox, oy, s, 30, 80, 40, 64, topC)
            ur(p, ox, oy, s, 30, 80, 3, 60, "0xFFFFFF20")
            ur(p, ox, oy, s, 30, 138, 40, 6, "0x00000024")
            sx = 30
            sw2 = 40
        else if shape = "muscle" then
            ur(p, ox, oy, s, 16, 80, 68, 28, topC)
            ur(p, ox, oy, s, 24, 108, 52, 36, topC)
            ur(p, ox, oy, s, 49, 86, 2, 20, "0x0000002A")
            ur(p, ox, oy, s, 49, 108, 2, 28, "0x0000002A")
            ur(p, ox, oy, s, 38, 114, 24, 2, "0x0000002A")
            ur(p, ox, oy, s, 38, 122, 24, 2, "0x0000002A")
            ur(p, ox, oy, s, 38, 130, 24, 2, "0x0000002A")
            sx = 24
            sw2 = 52
        else
            ur(p, ox, oy, s, 22, 80, 56, 64, topC)
            ' subtle fabric highlight and hem make outfits feel less flat
            ur(p, ox, oy, s, 22, 80, 4, 60, "0xFFFFFF20")
            ur(p, ox, oy, s, 22, 138, 56, 6, "0x00000024")
        end if
        if styleN = "stripe" then ur(p, ox, oy, s, sx, 104, sw2, 8, trimC)
        if styleN = "vstripe" then ur(p, ox, oy, s, 46, 80, 8, 64, trimC)
        if styleN = "emblem" then ur(p, ox, oy, s, 42, 98, 16, 16, trimC)
        if styleN = "jersey" then
            if jerseyNum = "04" then
                ' UF-only number 04
                ur(p, ox, oy, s, 36, 96, 14, 22, trimC)
                ur(p, ox, oy, s, 40, 100, 6, 14, topC)
                ur(p, ox, oy, s, 58, 96, 5, 22, trimC)
                ur(p, ox, oy, s, 51, 107, 14, 5, trimC)
                ur(p, ox, oy, s, 51, 96, 5, 16, trimC)
            else
                ur(p, ox, oy, s, 43, 96, 5, 22, trimC)
                ur(p, ox, oy, s, 39, 98, 5, 4, trimC)
                ur(p, ox, oy, s, 52, 96, 12, 22, trimC)
                ur(p, ox, oy, s, 55, 99, 6, 16, topC)
            end if
        end if
        if styleN = "basket" then
            ur(p, ox, oy, s, sx, 80, 5, 64, trimC)
            ur(p, ox, oy, s, sx + sw2 - 5, 80, 5, 64, trimC)
            ur(p, ox, oy, s, 43, 80, 14, 5, trimC)
            ur(p, ox, oy, s, 46, 94, 8, 18, trimC)
            ur(p, ox, oy, s, 48, 97, 4, 12, topC)
        end if
        if styleN = "nutcracker" then
            ' high military collar, gold shoulder boards, braided chest bars and buttons
            ur(p, ox, oy, s, 34, 80, 32, 8, trimC)
            ur(p, ox, oy, s, 22, 82, 15, 7, trimC)
            ur(p, ox, oy, s, 63, 82, 15, 7, trimC)
            ur(p, ox, oy, s, 28, 94, 44, 4, trimC)
            ur(p, ox, oy, s, 28, 106, 44, 4, trimC)
            ur(p, ox, oy, s, 28, 118, 44, 4, trimC)
            ur(p, ox, oy, s, 48, 88, 4, 48, "0x7B1823FF")
            for each by in [94, 106, 118, 130]
                ur(p, ox, oy, s, 38, by, 5, 5, "0xF4D66FFF")
                ur(p, ox, oy, s, 57, by, 5, 5, "0xF4D66FFF")
            end for
            ur(p, ox, oy, s, 25, 134, 50, 7, trimC)
        else if styleN = "soldier" then
            ' contrasting collar, crossed parade straps and symmetrical brass buttons
            ur(p, ox, oy, s, 34, 80, 32, 8, trimC)
            mkRotRect(p, (ox + (31 * s)), (oy + (89 * s)), 6 * s, 49 * s, "0xF2F0E8FF", -0.42)
            mkRotRect(p, (ox + (63 * s)), (oy + (89 * s)), 6 * s, 49 * s, "0xF2F0E8FF", 0.42)
            ur(p, ox, oy, s, 47, 86, 6, 51, "0x152A55FF")
            for each by in [92, 104, 116, 128]
                ur(p, ox, oy, s, 38, by, 5, 5, "0xE8B93CFF")
                ur(p, ox, oy, s, 57, by, 5, 5, "0xE8B93CFF")
            end for
            ur(p, ox, oy, s, 24, 136, 52, 6, "0xD52D3CFF")
        else if styleN = "clara" then
            ' white lace collar, fitted bodice, satin center panel and waist ribbon
            ur(p, ox, oy, s, 34, 80, 32, 6, trimC)
            ur(p, ox, oy, s, 40, 86, 20, 44, "0x91C9ECFF")
            ur(p, ox, oy, s, 47, 88, 6, 37, "0xE8F6FDFF")
            for each by in [92, 104, 116]
                ur(p, ox, oy, s, 49, by, 3, 3, "0xFFFFFFEE")
            end for
            ur(p, ox, oy, s, 24, 126, 52, 8, "0xF7F3E8FF")
            ur(p, ox, oy, s, 64, 123, 16, 14, "0x5A91BDFF")
        else if styleN = "sugarplum" then
            ' jeweled neckline, gold corset seams and a faceted sugar-plum centerpiece
            ur(p, ox, oy, s, 34, 80, 32, 7, trimC)
            ur(p, ox, oy, s, 28, 86, 5, 42, "0xF2D36BFF")
            ur(p, ox, oy, s, 67, 86, 5, 42, "0xF2D36BFF")
            ur(p, ox, oy, s, 39, 90, 4, 38, "0xD899C4FF")
            ur(p, ox, oy, s, 57, 90, 4, 38, "0xD899C4FF")
            ur(p, ox, oy, s, 45, 94, 10, 10, "0xF4C4E1FF")
            ur(p, ox, oy, s, 48, 97, 4, 4, "0xFFF4B0FF")
            ur(p, ox, oy, s, 25, 128, 50, 7, trimC)
        else if styleN = "mouseking" then
            ' royal silver collar, diagonal purple sash, medal and dark fur-edged tunic
            ur(p, ox, oy, s, 32, 80, 36, 9, trimC)
            mkRotRect(p, (ox + (31 * s)), (oy + (87 * s)), 10 * s, 51 * s, "0x8E6AACFF", -0.38)
            ur(p, ox, oy, s, 44, 98, 13, 13, "0xC8CDD8FF")
            ur(p, ox, oy, s, 47, 101, 7, 7, "0x7D263CFF")
            ur(p, ox, oy, s, 25, 128, 50, 8, "0x181822FF")
            ur(p, ox, oy, s, 24, 136, 52, 5, "0x8E6AACFF")
        else if styleN = "snowqueen" then
            ' crystalline collar, icy vertical facets, snowflake jewel and silver waistline
            ur(p, ox, oy, s, 28, 80, 44, 9, "0xF5FCFFFF")
            ur(p, ox, oy, s, 22, 82, 12, 9, "0xD9F5FFFF")
            ur(p, ox, oy, s, 66, 82, 12, 9, "0xD9F5FFFF")
            ur(p, ox, oy, s, 35, 90, 5, 40, "0xA9E2F2FF")
            ur(p, ox, oy, s, 60, 90, 5, 40, "0xA9E2F2FF")
            ur(p, ox, oy, s, 47, 92, 6, 28, "0xE9FAFFFF")
            ur(p, ox, oy, s, 43, 102, 14, 5, "0xF5FCFFFF")
            ur(p, ox, oy, s, 48, 97, 4, 17, "0xF5FCFFFF")
            ur(p, ox, oy, s, 46, 101, 8, 8, "0x86D9EDFF")
            ur(p, ox, oy, s, 24, 130, 52, 7, "0xF5FCFFFF")
        end if
        ' outfit-specific micro details stay hidden when a separate top is worn
        if not topOverride then
            if o.id = "o_hoodie" then
                ur(p, ox, oy, s, 38, 81, 2, 18, "0xFFFFFFFF")
                ur(p, ox, oy, s, 60, 81, 2, 18, "0xFFFFFFFF")
                ur(p, ox, oy, s, 37, 120, 26, 12, "0xA82032FF")
                ur(p, ox, oy, s, 48, 120, 4, 12, "0x7D1827FF")
            else if o.id = "o_overalls" then
                ur(p, ox, oy, s, 32, 80, 7, 32, botC)
                ur(p, ox, oy, s, 61, 80, 7, 32, botC)
                ur(p, ox, oy, s, 36, 104, 28, 34, botC)
                ur(p, ox, oy, s, 47, 114, 12, 9, "0x244A82FF")
                ur(p, ox, oy, s, 34, 88, 4, 4, "0xFFD66BFF")
                ur(p, ox, oy, s, 62, 88, 4, 4, "0xFFD66BFF")
            else if o.id = "o_pirate" then
                ur(p, ox, oy, s, 28, 118, 44, 7, "0x5E321BFF")
                ur(p, ox, oy, s, 46, 117, 8, 9, "0xFFD66BFF")
                ur(p, ox, oy, s, 48, 88, 4, 4, "0x222222FF")
                ur(p, ox, oy, s, 48, 98, 4, 4, "0x222222FF")
            else if o.id = "o_ninja" then
                ur(p, ox, oy, s, 22, 120, 56, 8, trimC)
                ur(p, ox, oy, s, 70, 126, 14, 5, trimC)
            else if o.id = "o_hero" then
                ur(p, ox, oy, s, 34, 126, 32, 7, "0xFFD66BFF")
                ur(p, ox, oy, s, 45, 96, 10, 4, trimC)
                ur(p, ox, oy, s, 41, 100, 18, 8, trimC)
                ur(p, ox, oy, s, 45, 108, 10, 4, trimC)
            else if o.id = "o_space" then
                ur(p, ox, oy, s, 35, 96, 30, 18, "0xBCC8D8FF")
                ur(p, ox, oy, s, 39, 100, 7, 5, "0x2F6BFFFF")
                ur(p, ox, oy, s, 48, 100, 7, 5, "0xE8473FFF")
                ur(p, ox, oy, s, 57, 100, 4, 5, "0x3FAE5AFF")
                ur(p, ox, oy, s, 39, 108, 22, 3, "0x56657AFF")
            else if o.id = "o_robe" then
                ur(p, ox, oy, s, 34, 94, 4, 4, trimC)
                ur(p, ox, oy, s, 61, 115, 5, 5, trimC)
                ur(p, ox, oy, s, 44, 132, 3, 3, trimC)
            else if o.id = "o_xmas" then
                ur(p, ox, oy, s, 30, 92, 6, 6, "0xFFFFFFFF")
                ur(p, ox, oy, s, 64, 92, 6, 6, "0xFFFFFFFF")
                ur(p, ox, oy, s, 46, 116, 8, 8, "0xFFFFFFFF")
            else if o.id = "o_clara" then
                ' full bell skirt with stepped lace, satin folds and a tied side bow
                ur(p, ox, oy, s, 18, 136, 64, 14, "0x78B9E8FF")
                ur(p, ox, oy, s, 15, 148, 70, 16, "0x8EC8EAFF")
                ur(p, ox, oy, s, 12, 162, 76, 18, "0xA8D8F0FF")
                ur(p, ox, oy, s, 16, 178, 68, 12, "0x91C9ECFF")
                ur(p, ox, oy, s, 18, 188, 64, 7, "0xF7F3E8FF")
                ur(p, ox, oy, s, 32, 142, 5, 44, "0xD7EDF8AA")
                ur(p, ox, oy, s, 63, 142, 5, 44, "0x6AAAD288")
                ur(p, ox, oy, s, 72, 130, 12, 12, "0xF7F3E8FF")
                ur(p, ox, oy, s, 82, 132, 9, 9, "0xF7F3E8FF")
            else if o.id = "o_sugarplum" then
                ' layered classical tutu with gold piping and alternating translucent-looking tiers
                ur(p, ox, oy, s, 12, 134, 76, 11, "0xF2D36BFF")
                ur(p, ox, oy, s, 8, 145, 84, 10, "0xC879B1FF")
                ur(p, ox, oy, s, 14, 155, 72, 9, "0xE8A6C8FF")
                ur(p, ox, oy, s, 20, 164, 60, 8, "0xF4C6DCFF")
                for each tx in [18, 32, 46, 60, 74]
                    ur(p, ox, oy, s, tx, 144, 4, 18, "0xF8DDEB99")
                end for
                ur(p, ox, oy, s, llx, 172, lw, 24, "0xF4DDEAFF")
                ur(p, ox, oy, s, lrx, 172, lw, 24, "0xF4DDEAFF")
            else if o.id = "o_mouseking" then
                ' segmented royal robe, silver edging, fur blocks and a trailing pointed tail
                ur(p, ox, oy, s, 18, 140, 64, 56, "0x252431FF")
                ur(p, ox, oy, s, 18, 140, 6, 56, "0xC8CDD8FF")
                ur(p, ox, oy, s, 76, 140, 6, 56, "0x8E6AACFF")
                ur(p, ox, oy, s, 26, 148, 48, 6, "0x49315FFF")
                ur(p, ox, oy, s, 26, 184, 48, 6, "0x49315FFF")
                ur(p, ox, oy, s, 82, 178, 14, 8, "0x5C5B68FF")
                ur(p, ox, oy, s, 92, 184, 14, 7, "0x5C5B68FF")
            else if o.id = "o_snowqueen" then
                ' long frost gown with descending ice panels, crystal hem and pale cape points
                ur(p, ox, oy, s, 18, 138, 64, 58, "0xC9ECF5FF")
                ur(p, ox, oy, s, 22, 142, 8, 48, "0xE9FAFFFF")
                ur(p, ox, oy, s, 46, 140, 8, 54, "0x9EDDEEFF")
                ur(p, ox, oy, s, 70, 142, 8, 48, "0xE9FAFFFF")
                ur(p, ox, oy, s, 16, 188, 68, 8, "0xF5FCFFFF")
                for each ix in [18, 30, 42, 54, 66, 78]
                    ur(p, ox, oy, s, ix, 184, 6, 10, "0xA7E4F3FF")
                end for
            else if o.id = "o_arcarmor" then
                ur(p, ox, oy, s, 30, 84, 40, 8, trimC)
                ur(p, ox, oy, s, 38, 94, 24, 24, "0x7A1520FF")
                ur(p, ox, oy, s, 43, 99, 14, 14, "0x8EC9FFFF")
                ur(p, ox, oy, s, 46, 102, 8, 8, "0xF4F7FFFF")
                ur(p, ox, oy, s, 28, 124, 44, 8, trimC)
                ur(p, ox, oy, s, 22, 136, 56, 5, "0xE8B93CFF")
            else if o.id = "o_doomarmor" then
                ur(p, ox, oy, s, 31, 84, 38, 18, trimC)
                ur(p, ox, oy, s, 35, 88, 30, 10, "0x9099A6FF")
                ur(p, ox, oy, s, 46, 102, 8, 24, "0xC9D0DAFF")
                ur(p, ox, oy, s, 28, 126, 44, 8, "0x8A6A2FFF")
                ur(p, ox, oy, s, 46, 126, 8, 8, "0xE8B93CFF")
            else if o.id = "o_ultron" then
                ' layered collar, pectoral shells, reactor and articulated abdominal ribs
                ur(p, ox, oy, s, 25, 80, 50, 8, "0x6E7783FF")
                ur(p, ox, oy, s, 31, 84, 16, 18, "0x858E99FF")
                ur(p, ox, oy, s, 53, 84, 16, 18, "0x858E99FF")
                ur(p, ox, oy, s, 34, 88, 11, 3, "0xB6BDC6FF")
                ur(p, ox, oy, s, 55, 88, 11, 3, "0xB6BDC6FF")
                ur(p, ox, oy, s, 47, 84, 6, 12, "0x202630FF")
                ur(p, ox, oy, s, 42, 96, 16, 17, "0x252B35FF")
                ur(p, ox, oy, s, 45, 99, 10, 11, "0xD51F3CFF")
                ur(p, ox, oy, s, 48, 102, 4, 5, "0xFF7084FF")
                ur(p, ox, oy, s, 28, 104, 15, 5, "0x5E6773FF")
                ur(p, ox, oy, s, 57, 104, 15, 5, "0x5E6773FF")
                ur(p, ox, oy, s, 31, 111, 17, 5, "0x737C88FF")
                ur(p, ox, oy, s, 52, 111, 17, 5, "0x737C88FF")
                ur(p, ox, oy, s, 34, 118, 14, 4, "0x525B67FF")
                ur(p, ox, oy, s, 52, 118, 14, 4, "0x525B67FF")
                ur(p, ox, oy, s, 37, 124, 11, 4, "0x6F7884FF")
                ur(p, ox, oy, s, 52, 124, 11, 4, "0x6F7884FF")
                ur(p, ox, oy, s, 40, 130, 8, 4, "0x4B535FFF")
                ur(p, ox, oy, s, 52, 130, 8, 4, "0x4B535FFF")
                ur(p, ox, oy, s, 48, 113, 4, 25, "0x151A22FF")
                ur(p, ox, oy, s, 49, 116, 2, 18, "0xD51F3CFF")
                ur(p, ox, oy, s, 27, 136, 46, 6, "0x303741FF")
                ur(p, ox, oy, s, 31, 138, 14, 2, "0x8B949FFF")
                ur(p, ox, oy, s, 55, 138, 14, 2, "0x8B949FFF")
            else if o.id = "o_starcaptain" then
                ur(p, ox, oy, s, 38, 88, 24, 24, "0x244C9AFF")
                ur(p, ox, oy, s, 46, 91, 8, 18, "0xFFFFFFFF")
                ur(p, ox, oy, s, 41, 96, 18, 8, "0xFFFFFFFF")
                ur(p, ox, oy, s, 28, 114, 44, 5, "0xFFFFFFFF")
                ur(p, ox, oy, s, 28, 121, 44, 5, "0xC52B3AFF")
                ur(p, ox, oy, s, 28, 128, 44, 5, "0xFFFFFFFF")
                ur(p, ox, oy, s, 28, 135, 44, 6, "0xC52B3AFF")
                ur(p, ox, oy, s, 22, 141, 56, 5, "0x8A5A2BFF")
            else if o.id = "o_webhero" then
                ur(p, ox, oy, s, 22, 80, 10, 64, "0x214D9AFF")
                ur(p, ox, oy, s, 68, 80, 10, 64, "0x214D9AFF")
                ur(p, ox, oy, s, 42, 96, 16, 20, "0x17213BFF")
                ur(p, ox, oy, s, 48, 92, 4, 32, "0x17213BFF")
                ur(p, ox, oy, s, 36, 104, 28, 3, "0x17213BFF")
                ur(p, ox, oy, s, 39, 98, 3, 5, "0x17213BFF")
                ur(p, ox, oy, s, 58, 98, 3, 5, "0x17213BFF")
                ur(p, ox, oy, s, 34, 122, 32, 3, "0x17213BFF")
                ur(p, ox, oy, s, 30, 134, 40, 3, "0x17213BFF")
            end if
        end if
        if cheer then
            ur(p, ox, oy, s, 20, 134, 60, 28, botC)
            ur(p, ox, oy, s, 20, 158, 60, 4, trimC)
        end if
        if back = "b_pack" then
            ur(p, ox, oy, s, 30, 80, 6, 44, "0x5E3C1BFF")
            ur(p, ox, oy, s, 64, 80, 6, 44, "0x5E3C1BFF")
        end if
        ' arms
        shoulderC = topC
        if sleeves = "tank" then shoulderC = skin
        ' Small underlapping shoulder bridges hide the join between the torso
        ' and modular arms without changing any equipped item geometry.
        ur(p, ox, oy, s, alx + arw - 3, 84, 7, 18, shoulderC)
        ur(p, ox, oy, s, arx - 4, 84, 7, 18, shoulderC)
        if sleeves = "long" then
            ur(p, ox, oy, s, alx, 80, arw, 48, topC)
            ur(p, ox, oy, s, arx, 80, arw, 48, topC)
            ur(p, ox, oy, s, alx, 128, arw, 8, skin)
            ur(p, ox, oy, s, arx, 128, arw, 8, skin)
        else if sleeves = "tank" then
            ur(p, ox, oy, s, alx, 80, arw, 56, skin)
            ur(p, ox, oy, s, arx, 80, arw, 56, skin)
            ur(p, ox, oy, s, alx + arw - 4, 80, 4, 12, trimC)
            ur(p, ox, oy, s, arx, 80, 4, 12, trimC)
        else
            ur(p, ox, oy, s, alx, 80, arw, 22, topC)
            ur(p, ox, oy, s, arx, 80, arw, 22, topC)
            ur(p, ox, oy, s, alx, 102, arw, 34, skin)
            ur(p, ox, oy, s, arx, 102, arw, 34, skin)
        end if
        ur(p, ox, oy, s, alx + 3, 130, arw - 6, 4, "0x00000016")
        ur(p, ox, oy, s, arx + 3, 130, arw - 6, 4, "0x00000016")
        tattoo = cfg.tattoo
        if sleeves <> "long" and tattoo <> invalid and tattoo <> "tat_none" then
            ink = "0x27324AFF"
            if tattoo = "tat_stars" then
                ur(p, ox, oy, s, alx + 5, 108, 5, 5, ink)
                ur(p, ox, oy, s, alx + 9, 116, 4, 4, ink)
                ur(p, ox, oy, s, alx + 4, 124, 3, 3, ink)
            else if tattoo = "tat_heart" then
                ur(p, ox, oy, s, alx + 4, 112, 4, 4, "0xB8324FFF")
                ur(p, ox, oy, s, alx + 9, 112, 4, 4, "0xB8324FFF")
                ur(p, ox, oy, s, alx + 6, 116, 5, 5, "0xB8324FFF")
            else if tattoo = "tat_lightning" then
                ur(p, ox, oy, s, alx + 7, 106, 5, 9, ink)
                ur(p, ox, oy, s, alx + 3, 113, 7, 5, ink)
                ur(p, ox, oy, s, alx + 4, 117, 4, 10, ink)
            else if tattoo = "tat_bands" then
                ur(p, ox, oy, s, alx + 2, 110, arw - 4, 3, ink)
                ur(p, ox, oy, s, alx + 2, 117, arw - 4, 3, ink)
                ur(p, ox, oy, s, arx + 2, 110, arw - 4, 3, ink)
                ur(p, ox, oy, s, arx + 2, 117, arw - 4, 3, ink)
            else if tattoo = "tat_sleeve" then
                for each ty in [104, 111, 118, 125]
                    ur(p, ox, oy, s, alx + 2, ty, arw - 4, 3, ink)
                    ur(p, ox, oy, s, arx + 2, ty, arw - 4, 3, ink)
                end for
            end if
        end if
        if shape = "muscle" then
            bc = skin
            if sleeves = "long" then bc = topC
            ur(p, ox, oy, s, alx - 2, 100, arw + 2, 18, bc)
            ur(p, ox, oy, s, arx, 100, arw + 2, 18, bc)
        end if
        if styleN = "nutcracker" or styleN = "soldier" then
            shoulderC = "0xE8B93CFF"
            if styleN = "soldier" then shoulderC = "0xD52D3CFF"
            ur(p, ox, oy, s, alx - 3, 80, arw + 6, 8, shoulderC)
            ur(p, ox, oy, s, arx - 3, 80, arw + 6, 8, shoulderC)
            ur(p, ox, oy, s, alx, 121, arw, 7, shoulderC)
            ur(p, ox, oy, s, arx, 121, arw, 7, shoulderC)
            ur(p, ox, oy, s, alx + 3, 128, arw - 6, 7, "0xF2F0E8FF")
            ur(p, ox, oy, s, arx + 3, 128, arw - 6, 7, "0xF2F0E8FF")
        else if styleN = "clara" then
            ur(p, ox, oy, s, alx - 3, 80, arw + 6, 17, "0xA8D8F0FF")
            ur(p, ox, oy, s, arx - 3, 80, arw + 6, 17, "0xA8D8F0FF")
            ur(p, ox, oy, s, alx, 96, arw, 5, "0xF7F3E8FF")
            ur(p, ox, oy, s, arx, 96, arw, 5, "0xF7F3E8FF")
        else if styleN = "sugarplum" then
            ur(p, ox, oy, s, alx - 2, 80, arw + 4, 10, "0xE8A6C8FF")
            ur(p, ox, oy, s, arx - 2, 80, arw + 4, 10, "0xE8A6C8FF")
            ur(p, ox, oy, s, alx, 89, arw, 4, "0xF2D36BFF")
            ur(p, ox, oy, s, arx, 89, arw, 4, "0xF2D36BFF")
        else if styleN = "mouseking" then
            ur(p, ox, oy, s, alx - 2, 80, arw + 4, 12, "0xC8CDD8FF")
            ur(p, ox, oy, s, arx - 2, 80, arw + 4, 12, "0xC8CDD8FF")
            ur(p, ox, oy, s, alx, 124, arw, 9, "0x181822FF")
            ur(p, ox, oy, s, arx, 124, arw, 9, "0x181822FF")
        else if styleN = "snowqueen" then
            ur(p, ox, oy, s, alx - 3, 80, arw + 6, 11, "0xE9FAFFFF")
            ur(p, ox, oy, s, arx - 3, 80, arw + 6, 11, "0xE9FAFFFF")
            ur(p, ox, oy, s, alx, 123, arw, 10, "0xF5FCFFFF")
            ur(p, ox, oy, s, arx, 123, arw, 10, "0xF5FCFFFF")
            ur(p, ox, oy, s, alx + 4, 126, arw - 8, 4, "0x86D9EDFF")
            ur(p, ox, oy, s, arx + 4, 126, arw - 8, 4, "0x86D9EDFF")
        end if
        if not topOverride and o.id = "o_ultron" then
            ' shoulder caps, elbow actuators, forearm rails and armored hands
            ur(p, ox, oy, s, alx - 3, 80, arw + 6, 13, "0x6C7581FF")
            ur(p, ox, oy, s, arx - 3, 80, arw + 6, 13, "0x6C7581FF")
            ur(p, ox, oy, s, alx - 1, 82, arw + 2, 3, "0xA5ADB7FF")
            ur(p, ox, oy, s, arx - 1, 82, arw + 2, 3, "0xA5ADB7FF")
            ur(p, ox, oy, s, alx + 2, 94, arw - 4, 15, "0x4E5763FF")
            ur(p, ox, oy, s, arx + 2, 94, arw - 4, 15, "0x4E5763FF")
            ur(p, ox, oy, s, alx + 4, 98, arw - 8, 3, "0xD51F3CFF")
            ur(p, ox, oy, s, arx + 4, 98, arw - 8, 3, "0xD51F3CFF")
            ur(p, ox, oy, s, alx + 2, 109, arw - 4, 8, "0x151A22FF")
            ur(p, ox, oy, s, arx + 2, 109, arw - 4, 8, "0x151A22FF")
            ur(p, ox, oy, s, alx + 5, 111, arw - 10, 4, "0xD51F3CFF")
            ur(p, ox, oy, s, arx + 5, 111, arw - 10, 4, "0xD51F3CFF")
            ur(p, ox, oy, s, alx + 1, 117, arw - 2, 14, "0x5E6773FF")
            ur(p, ox, oy, s, arx + 1, 117, arw - 2, 14, "0x5E6773FF")
            ur(p, ox, oy, s, alx + 4, 120, 3, 9, "0x9DA5AFFF")
            ur(p, ox, oy, s, arx + arw - 7, 120, 3, 9, "0x9DA5AFFF")
            ur(p, ox, oy, s, alx, 130, arw, 7, "0x303741FF")
            ur(p, ox, oy, s, arx, 130, arw, 7, "0x303741FF")
            ur(p, ox, oy, s, alx + 4, 132, arw - 8, 2, "0xD51F3CFF")
            ur(p, ox, oy, s, arx + 4, 132, arw - 8, 2, "0xD51F3CFF")
        end if
    end if

    ' gear set, built early so the face can defer to makeup
    gs = {}
    for each gk in cfg.gears
        gs[gk] = true
    end for

    ' head, ears and neck
    if full then ur(p, ox, oy, s, 43, 76, 14, 8, skin)
    ur(p, ox, oy, s, 26, 52, 5, 16, skin)
    ur(p, ox, oy, s, 69, 52, 5, 16, skin)
    ur(p, ox, oy, s, 28, 57, 2, 6, "0x00000018")
    ur(p, ox, oy, s, 70, 57, 2, 6, "0x00000018")
    ur(p, ox, oy, s, 30, 40, 40, 40, skin)
    ur(p, ox, oy, s, 30, 40, 4, 36, "0xFFFFFF18")
    ' eyebrows, bright eyes, nose, cheeks and a friendly smile
    ' (the makeup looks draw their own brow line, so plain brows step aside)
    if not gs.doesExist("g_glow") and not gs.doesExist("g_glam") then
        ur(p, ox, oy, s, 36, 51, 10, 2, hair)
        ur(p, ox, oy, s, 54, 51, 10, 2, hair)
    end if
    ur(p, ox, oy, s, 37, 54, 8, 7, "0xF8FBFFFF")
    ur(p, ox, oy, s, 55, 54, 8, 7, "0xF8FBFFFF")
    ur(p, ox, oy, s, 40, 55, 4, 5, eye)
    ur(p, ox, oy, s, 56, 55, 4, 5, eye)
    ur(p, ox, oy, s, 40, 55, 2, 2, "0xFFFFFFFF")
    ur(p, ox, oy, s, 56, 55, 2, 2, "0xFFFFFFFF")
    ur(p, ox, oy, s, 48, 59, 4, 5, "0x00000018")
    ur(p, ox, oy, s, 34, 64, 5, 3, "0xE78B8B50")
    ur(p, ox, oy, s, 61, 64, 5, 3, "0xE78B8B50")
    ur(p, ox, oy, s, 43, 68, 4, 2, "0x7A2E2EFF")
    ur(p, ox, oy, s, 47, 70, 10, 2, "0x7A2E2EFF")
    ur(p, ox, oy, s, 57, 68, 4, 2, "0x7A2E2EFF")
    ur(p, ox, oy, s, 48, 72, 6, 1, "0xFFFFFF55")
    if cfg.presentation = "female" then
        ur(p, ox, oy, s, 35, 53, 3, 2, hair)
        ur(p, ox, oy, s, 62, 53, 3, 2, hair)
        ur(p, ox, oy, s, 48, 70, 7, 1, "0xE98A9AFF")
    end if
    if cfg.ageGroup = "45-55" or cfg.ageGroup = "60+" then
        ur(p, ox, oy, s, 38, 48, 8, 1, "0x00000020")
        ur(p, ox, oy, s, 54, 48, 8, 1, "0x00000020")
        ur(p, ox, oy, s, 34, 62, 4, 1, "0x00000018")
        ur(p, ox, oy, s, 62, 62, 4, 1, "0x00000018")
        if cfg.ageGroup = "60+" then
            ur(p, ox, oy, s, 39, 61, 7, 1, "0x00000018")
            ur(p, ox, oy, s, 54, 61, 7, 1, "0x00000018")
        end if
    end if

    ' hair
    if hid = "r_short" then
        ur(p, ox, oy, s, 30, 36, 40, 10, hair)
        ur(p, ox, oy, s, 30, 46, 4, 6, hair)
        ur(p, ox, oy, s, 66, 46, 4, 6, hair)
    else if hid = "r_long" then
        ur(p, ox, oy, s, 30, 36, 40, 10, hair)
        ur(p, ox, oy, s, 26, 40, 6, 40, hair)
        ur(p, ox, oy, s, 68, 40, 6, 40, hair)
    else if hid = "r_bangs" then
        ur(p, ox, oy, s, 30, 36, 40, 8, hair)
        ur(p, ox, oy, s, 26, 40, 6, 40, hair)
        ur(p, ox, oy, s, 68, 40, 6, 40, hair)
        ur(p, ox, oy, s, 30, 44, 14, 10, hair)
        ur(p, ox, oy, s, 30, 54, 8, 4, hair)
        ur(p, ox, oy, s, 56, 44, 14, 10, hair)
        ur(p, ox, oy, s, 62, 54, 8, 4, hair)
    else if hid = "r_bob" then
        ur(p, ox, oy, s, 28, 34, 44, 11, hair)
        ur(p, ox, oy, s, 24, 42, 8, 42, hair)
        ur(p, ox, oy, s, 68, 42, 8, 42, hair)
        ur(p, ox, oy, s, 28, 76, 10, 8, hair)
        ur(p, ox, oy, s, 62, 76, 10, 8, hair)
    else if hid = "r_waves" then
        ur(p, ox, oy, s, 28, 34, 44, 10, hair)
        ur(p, ox, oy, s, 24, 42, 9, 16, hair)
        ur(p, ox, oy, s, 27, 58, 9, 14, hair)
        ur(p, ox, oy, s, 24, 72, 9, 12, hair)
        ur(p, ox, oy, s, 67, 42, 9, 16, hair)
        ur(p, ox, oy, s, 64, 58, 9, 14, hair)
        ur(p, ox, oy, s, 67, 72, 9, 12, hair)
    else if hid = "r_braids" then
        ur(p, ox, oy, s, 29, 35, 42, 9, hair)
        ur(p, ox, oy, s, 24, 42, 8, 18, hair)
        ur(p, ox, oy, s, 68, 42, 8, 18, hair)
        for each by in [60, 68, 76]
            ur(p, ox, oy, s, 25, by, 7, 6, hair)
            ur(p, ox, oy, s, 68, by, 7, 6, hair)
        end for
    else if hid = "r_buzz" then
        ur(p, ox, oy, s, 30, 38, 40, 5, hair)
    else if hid = "r_spiky" then
        ur(p, ox, oy, s, 30, 36, 40, 8, hair)
        ur(p, ox, oy, s, 31, 26, 8, 10, hair)
        ur(p, ox, oy, s, 40, 22, 8, 14, hair)
        ur(p, ox, oy, s, 49, 24, 8, 12, hair)
        ur(p, ox, oy, s, 58, 28, 8, 8, hair)
    else if hid = "r_mohawk" then
        ur(p, ox, oy, s, 44, 20, 12, 24, hair)
    else if hid = "r_afro" then
        ur(p, ox, oy, s, 30, 36, 40, 8, hair)
    else if hid = "r_pigtails" then
        ur(p, ox, oy, s, 30, 36, 40, 8, hair)
        ur(p, ox, oy, s, 22, 44, 8, 28, hair)
        ur(p, ox, oy, s, 70, 44, 8, 28, hair)
        ur(p, ox, oy, s, 22, 44, 8, 4, "0xE8473FFF")
        ur(p, ox, oy, s, 70, 44, 8, 4, "0xE8473FFF")
    end if
    if hid <> "r_bald" then
        ur(p, ox, oy, s, 35, 38, 13, 2, "0xFFFFFF2F")
        if hid = "r_long" or hid = "r_bangs" or hid = "r_bob" or hid = "r_waves" or hid = "r_braids" then ur(p, ox, oy, s, 28, 48, 2, 20, "0xFFFFFF24")
        if hid = "r_afro" then ur(p, ox, oy, s, 29, 30, 8, 4, "0xFFFFFF24")
    end if

    ' face items (several can be worn together)
    if gs.doesExist("g_glow") then
        ur(p, ox, oy, s, 36, 52, 8, 2, "0x1B1B1BFF")
        ur(p, ox, oy, s, 56, 52, 8, 2, "0x1B1B1BFF")
        ur(p, ox, oy, s, 34, 51, 2, 2, "0x1B1B1BFF")
        ur(p, ox, oy, s, 64, 51, 2, 2, "0x1B1B1BFF")
        ur(p, ox, oy, s, 33, 62, 9, 5, "0xF59AA8FF")
        ur(p, ox, oy, s, 58, 62, 9, 5, "0xF59AA8FF")
        ur(p, ox, oy, s, 45, 68, 10, 3, "0xE06A8AFF")
    end if
    if gs.doesExist("g_glam") then
        ur(p, ox, oy, s, 35, 49, 11, 3, "0xB77CD6FF")
        ur(p, ox, oy, s, 54, 49, 11, 3, "0xB77CD6FF")
        ur(p, ox, oy, s, 35, 52, 9, 2, "0x1B1B1BFF")
        ur(p, ox, oy, s, 56, 52, 9, 2, "0x1B1B1BFF")
        ur(p, ox, oy, s, 33, 50, 2, 3, "0x1B1B1BFF")
        ur(p, ox, oy, s, 65, 50, 2, 3, "0x1B1B1BFF")
        ur(p, ox, oy, s, 32, 62, 10, 6, "0xF27D93FF")
        ur(p, ox, oy, s, 58, 62, 10, 6, "0xF27D93FF")
        ur(p, ox, oy, s, 44, 67, 12, 4, "0xC41E3AFF")
        ur(p, ox, oy, s, 47, 67, 6, 1, "0xF2788CFF")
    end if
    if gs.doesExist("g_stache") then ur(p, ox, oy, s, 42, 63, 16, 4, "0x3B2314FF")
    if gs.doesExist("g_goatee") then
        ur(p, ox, oy, s, 44, 67, 12, 3, hair)
        ur(p, ox, oy, s, 46, 72, 8, 6, hair)
    end if
    if gs.doesExist("g_freckles") then
        for each fx in [35, 39, 43, 57, 61, 65]
            ur(p, ox, oy, s, fx, 63, 2, 2, "0x9A5B3FFF")
        end for
    end if
    if gs.doesExist("g_earrings") then
        ur(p, ox, oy, s, 25, 65, 5, 6, "0xFFD66BFF")
        ur(p, ox, oy, s, 70, 65, 5, 6, "0xFFD66BFF")
        ur(p, ox, oy, s, 26, 66, 2, 2, "0xFFFFFFFF")
        ur(p, ox, oy, s, 71, 66, 2, 2, "0xFFFFFFFF")
    end if
    if gs.doesExist("g_santabeard") then
        ur(p, ox, oy, s, 32, 62, 36, 22, "0xF4F7FFFF")
        ur(p, ox, oy, s, 38, 58, 24, 5, "0xF4F7FFFF")
    end if
    if gs.doesExist("g_rudolph") then ur(p, ox, oy, s, 46, 60, 8, 7, "0xD6322EFF")
    if gs.doesExist("g_glasses") then
        for each lx in [34, 52]
            ur(p, ox, oy, s, lx, 52, 14, 2, "0x1B1B1BFF")
            ur(p, ox, oy, s, lx, 60, 14, 2, "0x1B1B1BFF")
            ur(p, ox, oy, s, lx, 52, 2, 10, "0x1B1B1BFF")
            ur(p, ox, oy, s, lx + 12, 52, 2, 10, "0x1B1B1BFF")
        end for
        ur(p, ox, oy, s, 48, 55, 4, 2, "0x1B1B1BFF")
    end if
    if gs.doesExist("g_shades") then
        ur(p, ox, oy, s, 34, 52, 14, 10, "0x111111FF")
        ur(p, ox, oy, s, 52, 52, 14, 10, "0x111111FF")
        ur(p, ox, oy, s, 48, 54, 4, 3, "0x111111FF")
        ur(p, ox, oy, s, 30, 53, 4, 2, "0x111111FF")
        ur(p, ox, oy, s, 66, 53, 4, 2, "0x111111FF")
    end if
    if gs.doesExist("g_patch") then
        ur(p, ox, oy, s, 30, 50, 40, 2, "0x111111FF")
        ur(p, ox, oy, s, 35, 51, 14, 11, "0x111111FF")
    end if
    if gs.doesExist("g_mask") then ur(p, ox, oy, s, 30, 62, 40, 18, "0x1A1A1AFF")
    if gs.doesExist("g_phones") then
        ur(p, ox, oy, s, 28, 36, 44, 4, "0x2E2E3AFF")
        ur(p, ox, oy, s, 24, 48, 8, 18, "0x2E2E3AFF")
        ur(p, ox, oy, s, 68, 48, 8, 18, "0x2E2E3AFF")
        ur(p, ox, oy, s, 26, 50, 4, 14, "0xC0283CFF")
        ur(p, ox, oy, s, 70, 50, 4, 14, "0xC0283CFF")
    end if

    ' built-in armor masks appear only with the complete outfit selected
    if not topOverride and o.id = "o_arcarmor" then
        ur(p, ox, oy, s, 29, 37, 42, 43, "0xB21F2DFF")
        ur(p, ox, oy, s, 34, 43, 32, 34, "0xE8B93CFF")
        ur(p, ox, oy, s, 37, 54, 10, 5, "0x8EC9FFFF")
        ur(p, ox, oy, s, 53, 54, 10, 5, "0x8EC9FFFF")
        ur(p, ox, oy, s, 46, 68, 8, 3, "0x7A5520FF")
        ur(p, ox, oy, s, 29, 37, 42, 5, "0x7A1520FF")
    else if not topOverride and o.id = "o_doomarmor" then
        ur(p, ox, oy, s, 27, 34, 46, 48, "0x154A32FF")
        ur(p, ox, oy, s, 31, 39, 38, 41, "0xC9D0DAFF")
        ur(p, ox, oy, s, 34, 43, 32, 4, "0x8A949FFF")
        ur(p, ox, oy, s, 36, 54, 11, 5, "0x20242AFF")
        ur(p, ox, oy, s, 53, 54, 11, 5, "0x20242AFF")
        ur(p, ox, oy, s, 47, 48, 6, 19, "0x8A949FFF")
        ur(p, ox, oy, s, 40, 70, 20, 4, "0x707984FF")
    else if not topOverride and o.id = "o_ultron" then
        ' angular machine crown, layered face plates, red optics and vented jaw
        ur(p, ox, oy, s, 26, 34, 48, 46, "0x252B35FF")
        ur(p, ox, oy, s, 30, 36, 40, 42, "0x626B77FF")
        ur(p, ox, oy, s, 34, 32, 7, 8, "0x59626EFF")
        ur(p, ox, oy, s, 59, 32, 7, 8, "0x59626EFF")
        ur(p, ox, oy, s, 43, 29, 14, 11, "0x737C88FF")
        ur(p, ox, oy, s, 47, 25, 6, 8, "0x8E97A2FF")
        ur(p, ox, oy, s, 32, 39, 36, 8, "0x7B8490FF")
        ur(p, ox, oy, s, 36, 41, 28, 3, "0xB2B9C1FF")
        ur(p, ox, oy, s, 47, 38, 6, 11, "0x303741FF")
        ur(p, ox, oy, s, 31, 48, 17, 15, "0x414955FF")
        ur(p, ox, oy, s, 52, 48, 17, 15, "0x414955FF")
        ur(p, ox, oy, s, 34, 50, 13, 4, "0x202630FF")
        ur(p, ox, oy, s, 53, 50, 13, 4, "0x202630FF")
        ur(p, ox, oy, s, 36, 53, 11, 5, "0xD51F3CFF")
        ur(p, ox, oy, s, 53, 53, 11, 5, "0xD51F3CFF")
        ur(p, ox, oy, s, 38, 54, 8, 2, "0xFF7187FF")
        ur(p, ox, oy, s, 54, 54, 8, 2, "0xFF7187FF")
        ur(p, ox, oy, s, 47, 49, 6, 18, "0x838C97FF")
        ur(p, ox, oy, s, 49, 52, 2, 12, "0xC1C7CEFF")
        ur(p, ox, oy, s, 29, 59, 12, 12, "0x505966FF")
        ur(p, ox, oy, s, 59, 59, 12, 12, "0x505966FF")
        ur(p, ox, oy, s, 33, 62, 8, 4, "0x89929DFF")
        ur(p, ox, oy, s, 59, 62, 8, 4, "0x89929DFF")
        ur(p, ox, oy, s, 38, 66, 24, 13, "0x303741FF")
        ur(p, ox, oy, s, 42, 67, 16, 3, "0xD51F3CFF")
        ur(p, ox, oy, s, 41, 72, 18, 5, "0x151A22FF")
        for each gx in [43, 47, 51, 55]
            ur(p, ox, oy, s, gx, 72, 2, 5, "0x8A939EFF")
        end for
        ur(p, ox, oy, s, 26, 47, 5, 18, "0x353D47FF")
        ur(p, ox, oy, s, 69, 47, 5, 18, "0x353D47FF")
        ur(p, ox, oy, s, 27, 51, 3, 8, "0xD51F3CFF")
        ur(p, ox, oy, s, 70, 51, 3, 8, "0xD51F3CFF")
    else if not topOverride and o.id = "o_starcaptain" then
        ur(p, ox, oy, s, 29, 37, 42, 26, "0x244C9AFF")
        ur(p, ox, oy, s, 29, 40, 7, 30, "0x244C9AFF")
        ur(p, ox, oy, s, 64, 40, 7, 30, "0x244C9AFF")
        ur(p, ox, oy, s, 37, 54, 10, 5, "0xF4F7FFFF")
        ur(p, ox, oy, s, 53, 54, 10, 5, "0xF4F7FFFF")
        ur(p, ox, oy, s, 47, 40, 6, 12, "0xFFFFFFFF")
        ur(p, ox, oy, s, 43, 44, 14, 5, "0xFFFFFFFF")
    else if not topOverride and o.id = "o_webhero" then
        ur(p, ox, oy, s, 29, 37, 42, 43, "0xC6283BFF")
        ur(p, ox, oy, s, 34, 50, 13, 14, "0x17213BFF")
        ur(p, ox, oy, s, 53, 50, 13, 14, "0x17213BFF")
        ur(p, ox, oy, s, 37, 52, 8, 10, "0xF4F7FFFF")
        ur(p, ox, oy, s, 55, 52, 8, 10, "0xF4F7FFFF")
        ur(p, ox, oy, s, 48, 39, 3, 39, "0x17213BFF")
        ur(p, ox, oy, s, 31, 48, 38, 2, "0x17213BFF")
        ur(p, ox, oy, s, 31, 66, 38, 2, "0x17213BFF")
        ur(p, ox, oy, s, 38, 40, 2, 38, "0x17213BFF")
        ur(p, ox, oy, s, 60, 40, 2, 38, "0x17213BFF")
    else if not topOverride and o.id = "o_nutcracker_prince" then
        ' painted wooden cheeks, curled parade moustache and signature square teeth
        ur(p, ox, oy, s, 32, 63, 10, 7, "0xE88979AA")
        ur(p, ox, oy, s, 58, 63, 10, 7, "0xE88979AA")
        ur(p, ox, oy, s, 39, 64, 10, 5, "0x3A251CFF")
        ur(p, ox, oy, s, 51, 64, 10, 5, "0x3A251CFF")
        ur(p, ox, oy, s, 35, 67, 10, 4, "0x3A251CFF")
        ur(p, ox, oy, s, 55, 67, 10, 4, "0x3A251CFF")
        ur(p, ox, oy, s, 42, 69, 16, 10, "0xF7F3E8FF")
        ur(p, ox, oy, s, 49, 69, 2, 10, "0xA8A8A0FF")
        ur(p, ox, oy, s, 42, 74, 16, 2, "0xA8A8A0FF")
    else if not topOverride and o.id = "o_mouseking" then
        ' silver-grey muzzle, triangular nose, whiskers and two royal incisors
        ur(p, ox, oy, s, 35, 60, 30, 15, "0xB7BAC3FF")
        ur(p, ox, oy, s, 46, 58, 8, 7, "0x3A3038FF")
        ur(p, ox, oy, s, 48, 63, 4, 5, "0xE5B4C5FF")
        ur(p, ox, oy, s, 27, 64, 17, 2, "0xD8DCE4FF")
        ur(p, ox, oy, s, 56, 64, 17, 2, "0xD8DCE4FF")
        ur(p, ox, oy, s, 29, 69, 15, 2, "0xD8DCE4FF")
        ur(p, ox, oy, s, 56, 69, 15, 2, "0xD8DCE4FF")
        ur(p, ox, oy, s, 44, 71, 6, 9, "0xF5F1E7FF")
        ur(p, ox, oy, s, 51, 71, 6, 9, "0xF5F1E7FF")
    else if not topOverride and o.id = "o_toysoldier" then
        ur(p, ox, oy, s, 36, 66, 11, 4, "0x4A3023FF")
        ur(p, ox, oy, s, 53, 66, 11, 4, "0x4A3023FF")
        ur(p, ox, oy, s, 41, 70, 18, 7, "0xF7F3E8FF")
        ur(p, ox, oy, s, 49, 70, 2, 7, "0xA8A8A0FF")
    else if not topOverride and o.id = "o_sugarplum" then
        ur(p, ox, oy, s, 31, 61, 8, 4, "0xD97DAEFF")
        ur(p, ox, oy, s, 61, 61, 8, 4, "0xD97DAEFF")
        ur(p, ox, oy, s, 47, 69, 7, 4, "0xB95B88FF")
        ur(p, ox, oy, s, 69, 48, 4, 4, "0xF2D36BFF")
    else if not topOverride and o.id = "o_snowqueen" then
        ur(p, ox, oy, s, 31, 61, 8, 4, "0x75CBE8FF")
        ur(p, ox, oy, s, 61, 61, 8, 4, "0x75CBE8FF")
        ur(p, ox, oy, s, 47, 68, 7, 4, "0x79BFD4FF")
        ur(p, ox, oy, s, 68, 48, 4, 4, "0xF5FCFFFF")
        ur(p, ox, oy, s, 72, 52, 3, 3, "0x86D9EDFF")
    end if

    ' Face masks and the hood use landmark targets. The cape is already
    ' behind the body, so this front pass makes the garment wrap the wearer.
    drawEmeraldWearablesAt(p, ox, oy, s, cfg, "front")

    ' hats
    hat = cfg.hat
    if hat = "h_cap" then
        ur(p, ox, oy, s, 30, 34, 40, 10, "0xD6322EFF")
        ur(p, ox, oy, s, 28, 42, 44, 4, "0xA32622FF")
    else if hat = "h_beanie" then
        ur(p, ox, oy, s, 28, 32, 44, 14, "0x3B7DD8FF")
        ur(p, ox, oy, s, 46, 26, 8, 6, "0xFFFFFFFF")
    else if hat = "h_band" then
        ur(p, ox, oy, s, 29, 44, 42, 5, "0xE8473FFF")
    else if hat = "h_cowboy" then
        ur(p, ox, oy, s, 18, 36, 64, 5, "0x8A5A2BFF")
        ur(p, ox, oy, s, 33, 24, 34, 13, "0x8A5A2BFF")
        ur(p, ox, oy, s, 33, 34, 34, 3, "0x5E3C1BFF")
    else if hat = "h_pirate" then
        ur(p, ox, oy, s, 18, 34, 64, 8, "0x171A22FF")
        ur(p, ox, oy, s, 28, 22, 44, 16, "0x20242EFF")
        ur(p, ox, oy, s, 22, 28, 14, 10, "0x20242EFF")
        ur(p, ox, oy, s, 64, 28, 14, 10, "0x20242EFF")
        ur(p, ox, oy, s, 30, 34, 40, 4, "0xC6283BFF")
        ur(p, ox, oy, s, 46, 25, 8, 8, "0xF4F7FFFF")
        ur(p, ox, oy, s, 43, 31, 14, 3, "0xF4F7FFFF")
        ur(p, ox, oy, s, 40, 28, 4, 3, "0xF4F7FFFF")
        ur(p, ox, oy, s, 56, 28, 4, 3, "0xF4F7FFFF")
    else if hat = "h_astronaut" then
        ' white pressure shell with a layered reflective gold visor
        ur(p, ox, oy, s, 22, 24, 56, 58, "0xD8DEE8FF")
        ur(p, ox, oy, s, 26, 20, 48, 10, "0xF4F7FFFF")
        ur(p, ox, oy, s, 18, 38, 8, 34, "0xAEB8C8FF")
        ur(p, ox, oy, s, 74, 38, 8, 34, "0xAEB8C8FF")
        ur(p, ox, oy, s, 28, 34, 44, 38, "0xA96E16FF")
        ur(p, ox, oy, s, 31, 37, 38, 32, "0xE8B93CFF")
        ur(p, ox, oy, s, 34, 39, 14, 5, "0xFFF0A8D0")
        ur(p, ox, oy, s, 34, 45, 8, 15, "0xFFD66B90")
        ur(p, ox, oy, s, 57, 59, 9, 6, "0x8A5517A0")
        ur(p, ox, oy, s, 24, 72, 52, 10, "0xF4F7FFFF")
        ur(p, ox, oy, s, 30, 78, 40, 5, "0x8A95A6FF")
    else if hat = "h_top" then
        ur(p, ox, oy, s, 24, 38, 52, 4, "0x1E1E24FF")
        ur(p, ox, oy, s, 34, 16, 32, 23, "0x1E1E24FF")
        ur(p, ox, oy, s, 34, 32, 32, 4, "0xC0283CFF")
    else if hat = "h_wizard" then
        ur(p, ox, oy, s, 24, 38, 52, 4, "0x5B3FA8FF")
        ur(p, ox, oy, s, 32, 28, 36, 11, "0x5B3FA8FF")
        ur(p, ox, oy, s, 38, 20, 24, 9, "0x5B3FA8FF")
        ur(p, ox, oy, s, 43, 14, 14, 7, "0x5B3FA8FF")
        ur(p, ox, oy, s, 46, 30, 5, 5, "0xFFD97EFF")
    else if hat = "h_crown" then
        ur(p, ox, oy, s, 30, 32, 40, 8, "0xE8B93CFF")
        ur(p, ox, oy, s, 30, 24, 8, 9, "0xE8B93CFF")
        ur(p, ox, oy, s, 46, 22, 8, 11, "0xE8B93CFF")
        ur(p, ox, oy, s, 62, 24, 8, 9, "0xE8B93CFF")
        ur(p, ox, oy, s, 47, 34, 6, 4, "0xC0283CFF")
    else if hat = "h_helm_orange" or hat = "h_helm_green" or hat = "h_helm_white" or hat = "h_helm_uf_blue" or hat = "h_helm_uf_orange" then
        shell = "0xF47321FF"
        stripeC = "0xFFFFFFFF"
        if hat = "h_helm_green" then
            shell = "0x005030FF"
            stripeC = "0xF47321FF"
        else if hat = "h_helm_white" then
            shell = "0xF4F4F4FF"
            stripeC = "0x005030FF"
        else if hat = "h_helm_uf_blue" then
            shell = "0x0021A5FF"
            stripeC = "0xFA4616FF"
        else if hat = "h_helm_uf_orange" then
            shell = "0xFA4616FF"
            stripeC = "0x0021A5FF"
        end if
        ur(p, ox, oy, s, 28, 30, 44, 22, shell)
        ur(p, ox, oy, s, 28, 52, 6, 14, shell)
        ur(p, ox, oy, s, 66, 52, 6, 14, shell)
        ur(p, ox, oy, s, 47, 28, 6, 24, stripeC)
        ur(p, ox, oy, s, 34, 49, 32, 2, "0xC9CED8FF")
        ur(p, ox, oy, s, 34, 60, 32, 2, "0xC9CED8FF")
        ur(p, ox, oy, s, 34, 66, 32, 2, "0xC9CED8FF")
        ur(p, ox, oy, s, 34, 49, 2, 19, "0xC9CED8FF")
        ur(p, ox, oy, s, 64, 49, 2, 19, "0xC9CED8FF")
        ur(p, ox, oy, s, 49, 49, 2, 19, "0xC9CED8FF")
    else if hat = "h_bow" then
        ur(p, ox, oy, s, 34, 32, 10, 10, "0xF47321FF")
        ur(p, ox, oy, s, 56, 32, 10, 10, "0xF47321FF")
        ur(p, ox, oy, s, 44, 34, 12, 6, "0x005030FF")
    else if hat = "h_bow_uf" then
        ur(p, ox, oy, s, 32, 31, 13, 12, "0xFA4616FF")
        ur(p, ox, oy, s, 55, 31, 13, 12, "0x0021A5FF")
        ur(p, ox, oy, s, 43, 33, 14, 8, "0xFFFFFFFF")
        ur(p, ox, oy, s, 47, 34, 6, 6, "0xFA4616FF")
    else if hat = "h_nutcracker" then
        ' tall black parade shako with red crown, gold badge, braid and white plume
        ur(p, ox, oy, s, 27, 12, 46, 30, "0x171A22FF")
        ur(p, ox, oy, s, 30, 9, 40, 7, "0xB52332FF")
        ur(p, ox, oy, s, 27, 35, 46, 8, "0xE8B93CFF")
        ur(p, ox, oy, s, 44, 19, 12, 12, "0xE8B93CFF")
        ur(p, ox, oy, s, 47, 22, 6, 6, "0xF7E7A1FF")
        ur(p, ox, oy, s, 31, 29, 38, 3, "0xC69A2FFF")
        ur(p, ox, oy, s, 65, 1, 8, 14, "0xF5FCFFFF")
        ur(p, ox, oy, s, 70, 5, 7, 16, "0xE4EDF5FF")
    else if hat = "h_clara" then
        ' layered satin bow with center jewel and trailing ribbons
        ur(p, ox, oy, s, 27, 26, 19, 14, "0x78B9E8FF")
        ur(p, ox, oy, s, 54, 26, 19, 14, "0x78B9E8FF")
        ur(p, ox, oy, s, 43, 29, 14, 9, "0xF7F3E8FF")
        ur(p, ox, oy, s, 31, 37, 12, 13, "0xA8D8F0FF")
        ur(p, ox, oy, s, 57, 37, 12, 13, "0xA8D8F0FF")
        ur(p, ox, oy, s, 47, 31, 6, 5, "0xE8B93CFF")
    else if hat = "h_sugarplum" then
        ' gold ballet tiara with plum stones and a tall central sugar crystal
        ur(p, ox, oy, s, 29, 34, 42, 7, "0xF2D36BFF")
        ur(p, ox, oy, s, 31, 25, 8, 11, "0xF2D36BFF")
        ur(p, ox, oy, s, 46, 18, 8, 18, "0xF2D36BFF")
        ur(p, ox, oy, s, 61, 25, 8, 11, "0xF2D36BFF")
        ur(p, ox, oy, s, 33, 28, 4, 5, "0xC879B1FF")
        ur(p, ox, oy, s, 48, 22, 4, 8, "0xF4C4E1FF")
        ur(p, ox, oy, s, 63, 28, 4, 5, "0xC879B1FF")
        ur(p, ox, oy, s, 42, 34, 16, 5, "0xFFF4B0FF")
    else if hat = "h_mouseking" then
        ' rounded mouse ears beneath a crooked five-point royal crown
        ur(p, ox, oy, s, 20, 26, 20, 20, "0x5C5B68FF")
        ur(p, ox, oy, s, 60, 26, 20, 20, "0x5C5B68FF")
        ur(p, ox, oy, s, 25, 31, 10, 10, "0xC98DA4FF")
        ur(p, ox, oy, s, 65, 31, 10, 10, "0xC98DA4FF")
        ur(p, ox, oy, s, 30, 28, 40, 10, "0xD1AA3AFF")
        ur(p, ox, oy, s, 30, 17, 8, 13, "0xD1AA3AFF")
        ur(p, ox, oy, s, 41, 12, 8, 18, "0xD1AA3AFF")
        ur(p, ox, oy, s, 52, 15, 8, 15, "0xD1AA3AFF")
        ur(p, ox, oy, s, 63, 18, 7, 12, "0xD1AA3AFF")
        ur(p, ox, oy, s, 46, 30, 8, 5, "0x7D263CFF")
    else if hat = "h_toysoldier" then
        ' navy shako with red band, brass plate, chin strap and compact plume
        ur(p, ox, oy, s, 28, 13, 44, 29, "0x152A55FF")
        ur(p, ox, oy, s, 28, 33, 44, 8, "0xD52D3CFF")
        ur(p, ox, oy, s, 42, 19, 16, 13, "0xE8B93CFF")
        ur(p, ox, oy, s, 46, 22, 8, 7, "0xF4D66FFF")
        ur(p, ox, oy, s, 31, 39, 38, 4, "0xE8B93CFF")
        ur(p, ox, oy, s, 62, 4, 8, 13, "0xD52D3CFF")
        ur(p, ox, oy, s, 67, 1, 7, 12, "0xF2F0E8FF")
    else if hat = "h_snowqueen" then
        ' tall asymmetric ice crown with layered translucent-looking crystal points
        ur(p, ox, oy, s, 28, 34, 44, 7, "0xF5FCFFFF")
        ur(p, ox, oy, s, 29, 23, 8, 13, "0xA7E4F3FF")
        ur(p, ox, oy, s, 39, 16, 9, 20, "0xD9F5FFFF")
        ur(p, ox, oy, s, 50, 8, 9, 28, "0xF5FCFFFF")
        ur(p, ox, oy, s, 61, 18, 9, 18, "0xA7E4F3FF")
        ur(p, ox, oy, s, 32, 30, 36, 5, "0x86D9EDFF")
        ur(p, ox, oy, s, 47, 27, 6, 6, "0x75CBE8FF")
        ur(p, ox, oy, s, 54, 17, 4, 9, "0xBFF2FAFF")
    else if hat = "h_santa" then
        ur(p, ox, oy, s, 31, 26, 38, 11, "0xD6322EFF")
        ur(p, ox, oy, s, 35, 20, 30, 6, "0xD6322EFF")
        ur(p, ox, oy, s, 52, 16, 18, 5, "0xD6322EFF")
        ur(p, ox, oy, s, 66, 14, 8, 8, "0xFFFFFFFF")
        ur(p, ox, oy, s, 28, 36, 44, 8, "0xFFFFFFFF")
    else if hat = "h_elf" then
        ur(p, ox, oy, s, 32, 26, 36, 12, "0x2E9E4FFF")
        ur(p, ox, oy, s, 38, 18, 24, 8, "0x2E9E4FFF")
        ur(p, ox, oy, s, 56, 14, 8, 6, "0x2E9E4FFF")
        ur(p, ox, oy, s, 62, 14, 6, 6, "0xE8B93CFF")
        ur(p, ox, oy, s, 28, 36, 44, 6, "0xD6322EFF")
    else if hat = "h_reindeer" then
        ur(p, ox, oy, s, 30, 38, 40, 4, "0x6B4423FF")
        ur(p, ox, oy, s, 26, 36, 8, 8, "0x8A5A2BFF")
        ur(p, ox, oy, s, 66, 36, 8, 8, "0x8A5A2BFF")
        ur(p, ox, oy, s, 32, 22, 5, 16, "0x8A5A2BFF")
        ur(p, ox, oy, s, 26, 24, 6, 4, "0x8A5A2BFF")
        ur(p, ox, oy, s, 28, 18, 5, 4, "0x8A5A2BFF")
        ur(p, ox, oy, s, 63, 22, 5, 16, "0x8A5A2BFF")
        ur(p, ox, oy, s, 68, 24, 6, 4, "0x8A5A2BFF")
        ur(p, ox, oy, s, 67, 18, 5, 4, "0x8A5A2BFF")
    else if hat = "h_turkey" then
        ur(p, ox, oy, s, 28, 26, 8, 12, "0xC0283CFF")
        ur(p, ox, oy, s, 36, 20, 8, 18, "0xF08A2AFF")
        ur(p, ox, oy, s, 44, 15, 12, 23, "0xF2C230FF")
        ur(p, ox, oy, s, 56, 20, 8, 18, "0xF08A2AFF")
        ur(p, ox, oy, s, 64, 26, 8, 12, "0xC0283CFF")
        ur(p, ox, oy, s, 30, 34, 40, 10, "0x8A5A2BFF")
        ur(p, ox, oy, s, 38, 36, 5, 5, "0xFFFFFFFF")
        ur(p, ox, oy, s, 57, 36, 5, 5, "0xFFFFFFFF")
        ur(p, ox, oy, s, 40, 38, 2, 2, "0x1B1B1BFF")
        ur(p, ox, oy, s, 59, 38, 2, 2, "0x1B1B1BFF")
        ur(p, ox, oy, s, 46, 40, 8, 4, "0xF2A02AFF")
        ur(p, ox, oy, s, 48, 44, 4, 5, "0xC0283CFF")
    else if hat = "h_pilgrim" then
        ur(p, ox, oy, s, 26, 38, 48, 4, "0x1E1E24FF")
        ur(p, ox, oy, s, 34, 20, 32, 19, "0x1E1E24FF")
        ur(p, ox, oy, s, 34, 31, 32, 4, "0xF2F2F2FF")
        ur(p, ox, oy, s, 46, 30, 8, 6, "0xE8B93CFF")
    end if
    drawEmeraldWearablesAt(p, ox, oy, s, cfg, "effect")
    if full then drawPet(p, ox, oy, s, cfg.pet, cfg.petColor)
    m.avatarEffectsEnabled = priorAvatarEffects
end sub

' ---------- shared screen pieces ----------

sub buildWhoRow(root as Object)
    keys = profileKeys()
    for i = 0 to keys.count() - 1
        k = keys[i]
        bg = "0x182343FF"
        if m.who = k then bg = "0x3E63DDFF"
        t = addItem(root, "who", k, i, 0, 56 + i * 142, 80, 130, 112, bg)
        if m.who = k then mkRect(t.node, 0, 0, 130, 5, "0xFFD66BFF")
        drawProfileAvatarFace(t.node, k, 30, 6, 70)
        mkLabelW(t.node, personName(k), 0, 80, 130, 24, m.C.text, "center")
    end for
end sub

sub buildPreviewPanel(root as Object, cfg as Object)
    mkRect(root, 64, 228, 410, 752, "0x05081270")
    mkRect(root, 56, 220, 410, 752, "0x182343FF")
    mkRect(root, 56, 220, 410, 7, "0xFFD66BFF")
    mkLabelW(root, "YOUR LOOK", 78, 246, 366, 22, "0xAAB9DCFF", "center")
    mkRect(root, 82, 290, 358, 500, "0x10182FFF")
    mkRect(root, 106, 754, 310, 6, "0x27365EFF")
    drawAvatar(root, 161, 320, 2, cfg, "full")
    mkLabelW(root, personName(m.who), 56, 814, 410, 38, m.C.text, "center")
    mkLabelW(root, "AVAILABLE BALANCE", 56, 866, 410, 20, "0xAAB9DCFF", "center")
    mkLabelW(root, fmtCb(m.state.cb[m.who]), 56, 894, 410, 36, "0xFFD66BFF", "center")
end sub

sub cycleSlot(slot as String, dir as Integer)
    ensureWho()
    cfg = m.state.avatar[m.who]
    if slot = "skin" then
        n = skinColors().count()
        armor = itemById("o_ultron")
        canUseArmor = false
        if armor <> invalid then canUseArmor = isOwned(m.who, armor)
        choices = n
        if canUseArmor then choices = choices + 1
        selected = cfg.skin
        if cfg.baseSkin = "robot" and canUseArmor then selected = n
        selected = (selected + dir + choices) mod choices
        if selected = n then
            cfg.baseSkin = "robot"
        else
            cfg.skin = selected
            cfg.baseSkin = "human"
            if cfg.outfit = "o_ultron" or cfg.outfit = "o_doomarmor" then cfg.outfit = defaultAvatar(m.who).outfit
        end if
    else if slot = "hcol" then
        n = hairColors().count()
        cfg.hcol = (cfg.hcol + dir + n) mod n
    else if slot = "ecol" then
        n = eyeColors().count()
        cfg.ecol = (cfg.ecol + dir + n) mod n
    else if slot = "ageGroup" then
        ages = ageGroupIds()
        ai = 0
        for i = 0 to ages.count() - 1
            if ages[i] = cfg.ageGroup then ai = i
        end for
        cfg.ageGroup = ages[(ai + dir + ages.count()) mod ages.count()]
    else if slot = "presentation" then
        presentations = presentationIds()
        pi = 0
        for i = 0 to presentations.count() - 1
            if presentations[i] = cfg.presentation then pi = i
        end for
        cfg.presentation = presentations[(pi + dir + presentations.count()) mod presentations.count()]
    else if slot = "shape" then
        shp = shapeIds()
        si = 0
        for i = 0 to shp.count() - 1
            if shp[i] = cfg.shape then si = i
        end for
        cfg.shape = shp[(si + dir + shp.count()) mod shp.count()]
    else if slot = "height" then
        heights = heightIds()
        hi = 0
        for i = 0 to heights.count() - 1
            if heights[i] = cfg.height then hi = i
        end for
        cfg.height = heights[(hi + dir + heights.count()) mod heights.count()]
    else if slot = "petcolor" then
        n = petColorNames().count()
        cfg.petColor = (cfg.petColor + dir + n) mod n
    else if slot = "gear" then
        gopts = ownedList(m.who, "gear")
        if gopts.count() = 0 then return
        if m.gearCur = invalid then m.gearCur = 0
        m.gearCur = (m.gearCur + dir + gopts.count()) mod gopts.count()
    else if slot = "hand" then
        hopts = ownedList(m.who, "hand")
        if hopts.count() = 0 then return
        if m.handCur = invalid then m.handCur = 0
        m.handCur = (m.handCur + dir + hopts.count()) mod hopts.count()
    else
        opts = ownedList(m.who, slot)
        if opts.count() = 0 then return
        idx = 0
        for i = 0 to opts.count() - 1
            if opts[i].id = cfg[slot] then idx = i
        end for
        cfg[slot] = opts[(idx + dir + opts.count()) mod opts.count()].id
        if slot = "outfit" then
            cfg.top = "t_none"
            cfg.bottom = "p_none"
            if cfg.outfit = "o_pilot_child_blue" then cfg.ageGroup = "9-11" : cfg.presentation = "male"
            if cfg.outfit = "o_pilot_preteen_purple" then cfg.ageGroup = "12-14" : cfg.presentation = "female"
            if cfg.outfit = "o_pilot_adult_green" then cfg.ageGroup = "22-27" : cfg.presentation = "male"
            applyOutfitDefaults(cfg, cfg.outfit, m.state.owned[m.who])
        end if
    end if
    m.state.avatar[m.who] = cfg
    saveState()
    rebuildScreen()
end sub

sub equipShopItem(who as String, it as Object)
    cfg = m.state.avatar[who]
    if it.cat = "gear" then
        on = not hasGear(cfg, it.id)
        setGear(cfg, it.id, on)
        if on then showToast(personName(who) + " put on " + it.name) else showToast(personName(who) + " took off " + it.name)
    else if it.cat = "hand" then
        on = not hasHandItem(cfg, it.id)
        setHandItem(cfg, it.id, on)
        if on then showToast(personName(who) + " equipped " + it.name) else showToast(personName(who) + " put away " + it.name)
    else
        cfg[it.cat] = it.id
        if it.cat = "outfit" then
            cfg.top = "t_none"
            cfg.bottom = "p_none"
            applyOutfitDefaults(cfg, it.id, m.state.owned[who])
        end if
        showToast(personName(who) + " is now wearing " + it.name)
    end if
end sub

sub buyItem(id as String)
    ensureWho()
    it = itemById(id)
    if it = invalid then return
    who = m.who
    if isOwned(who, it) then
        equipShopItem(who, it)
        saveState()
        rebuildScreen()
        return
    end if
    bal = m.state.cb[who]
    if bal < it.price then
        showToast("Need " + fmtCb(it.price - bal) + " more for " + it.name)
        return
    end if
    m.pendingBuy = id
    showScreen("confirmbuy")
end sub

sub completePendingPurchase()
    ensureWho()
    id = m.pendingBuy
    it = itemById(id)
    if it = invalid then
        m.pendingBuy = ""
        showScreen("shop")
        return
    end if
    who = m.who
    if isOwned(who, it) then
        m.pendingBuy = ""
        equipShopItem(who, it)
        saveState()
        showScreen("shop")
        return
    end if
    bal = m.state.cb[who]
    if bal < it.price then
        m.pendingBuy = ""
        showToast("Balance changed - " + fmtCb(it.price - bal) + " more is needed")
        showScreen("shop")
        return
    end if
    m.state.cb[who] = bal - it.price
    m.state.owned[who][id] = true
    grantComboParts(who, id)
    cfg = m.state.avatar[who]
    if it.cat = "gear" then
        setGear(cfg, id, true)
    else if it.cat = "hand" then
        setHandItem(cfg, id, true)
    else
        cfg[it.cat] = id
        if it.cat = "outfit" then
            cfg.top = "t_none"
            cfg.bottom = "p_none"
            applyOutfitDefaults(cfg, id, m.state.owned[who])
        end if
    end if
    m.pendingBuy = ""
    saveState()
    showToast(personName(who) + " bought " + it.name + " for " + fmtCb(it.price))
    showScreen("shop")
end sub

sub buildConfirmBuy()
    root = m.screenRoot
    ensureWho()
    it = itemById(m.pendingBuy)
    if it = invalid then
        m.pendingBuy = ""
        showScreen("shop")
        return
    end if
    cfg = copyCfg(m.state.avatar[m.who])
    if it.cat = "gear" then
        setGear(cfg, it.id, true)
    else if it.cat = "hand" then
        setHandItem(cfg, it.id, true)
    else
        cfg[it.cat] = it.id
        if it.cat = "outfit" then
            cfg.top = "t_none"
            cfg.bottom = "p_none"
            applyOutfitDefaults(cfg, it.id, invalid)
        end if
    end if
    mkLabelW(root, "CONFIRM PURCHASE", 460, 100, 1000, 46, m.C.text, "center")
    mkLabelW(root, "Please review this purchase before any C-Bucks are spent.", 460, 160, 1000, 26, m.C.dim, "center")
    mkRect(root, 650, 220, 620, 430, "0x182343FF")
    mkRect(root, 650, 220, 620, 7, "0xFFD66BFF")
    drawAvatar(root, 670, 246, 2, cfg, "full")
    mkLabelW(root, it.name, 970, 300, 260, 34, m.C.text, "center")
    mkLabelW(root, fmtCb(it.price), 970, 360, 260, 42, "0xFFD66BFF", "center")
    mkLabelW(root, "FOR " + personName(m.who), 970, 420, 260, 24, m.C.dim, "center")
    parts = comboParts(it.id)
    if parts.count() > 0 then mkLabelW(root, "Includes reusable mix-and-match pieces", 950, 486, 300, 22, m.C.green, "center")
    yes = addItem(root, "action", "buyyes", 0, 0, 560, 720, 380, 90, "0x3E63DDFF")
    mkLabelW(yes.node, "YES - CONTINUE", 0, 25, 380, 30, m.C.text, "center")
    no = addItem(root, "action", "buyno", 1, 0, 980, 720, 380, 90, "0x182343FF")
    mkLabelW(no.node, "NO - GO BACK", 0, 25, 380, 30, m.C.text, "center")
    mkLabelW(root, personName(m.who) + "'s own spending PIN is requested after YES. The charge is final only after the correct PIN.", 460, 844, 1000, 23, m.C.dim, "center")
end sub

sub toggleCurrentGear()
    ensureWho()
    cfg = m.state.avatar[m.who]
    opts = ownedList(m.who, "gear")
    if opts.count() = 0 then
        showToast("No accessories yet - visit the Shop")
        return
    end if
    if m.gearCur = invalid then m.gearCur = 0
    if m.gearCur >= opts.count() then m.gearCur = 0
    g = opts[m.gearCur]
    setGear(cfg, g.id, not hasGear(cfg, g.id))
    saveState()
    rebuildScreen()
end sub

sub toggleCurrentHandItem()
    ensureWho()
    cfg = m.state.avatar[m.who]
    opts = ownedList(m.who, "hand")
    if opts.count() = 0 then
        showToast("No weapons or powers yet - visit the Shop")
        return
    end if
    if m.handCur = invalid then m.handCur = 0
    if m.handCur >= opts.count() then m.handCur = 0
    it = opts[m.handCur]
    setHandItem(cfg, it.id, not hasHandItem(cfg, it.id))
    saveState()
    rebuildScreen()
end sub

sub handleExtraOK(it as Object)
    if it.kind = "pinreset" then
        beginShopPinReset(it.id)
    else if it.kind = "mealday" then
        selectMealPlanDay(it.id)
    else if it.kind = "mealchoice" then
        openMealPlanCustomEditor(it.id)
    else if it.kind = "musicstation" then
        setMusicMode(it.id)
    else if it.kind = "familyfield" then
        openFamilyEditor(it.id)
    else if it.kind = "who" then
        m.who = it.id
        rebuildScreen()
    else if it.kind = "slot" then
        if it.id = "gear" then
            toggleCurrentGear()
        else if it.id = "hand" then
            toggleCurrentHandItem()
        else
            cycleSlot(it.id, 1)
        end if
    else if it.kind = "cat" then
        m.shopCat = it.id
        m.shopPage = 0
        rebuildScreen()
    else if it.kind = "page" then
        if it.id = "prev" then m.shopPage = m.shopPage - 1 else m.shopPage = m.shopPage + 1
        rebuildScreen()
    else if it.kind = "invcat" then
        m.inventoryCat = it.id
        m.inventoryPage = 0
        rebuildScreen()
    else if it.kind = "invpage" then
        if it.id = "prev" then m.inventoryPage = m.inventoryPage - 1 else m.inventoryPage = m.inventoryPage + 1
        rebuildScreen()
    else if it.kind = "invitem" then
        invItem = itemById(it.id)
        if invItem <> invalid and isOwned(m.who, invItem) then
            equipShopItem(m.who, invItem)
            saveState()
            rebuildScreen()
        end if
    else if it.kind = "buy" then
        buyItem(it.id)
    else if it.kind = "wallet" then
        adjustWallet(it.id, 500)
    else if it.kind = "bonuspoint" then
        adjustBonusPoint(it.id, 1)
    end if
end sub

' ---------- avatar builder screen ----------

sub buildAvatar()
    root = m.screenRoot
    ensureWho()
    cfg = m.state.avatar[m.who]
    buildWhoRow(root)
    mkLabelW(root, "HD AVATAR STUDIO", 940, 88, 920, 40, m.C.text, "left")
    mkLabelW(root, "Smooth illustrated previews · choose a profile, highlight a detail, then use LEFT or RIGHT. Accessories toggle with OK.", 940, 140, 920, 24, m.C.dim, "left")
    buildPreviewPanel(root, cfg)
    slots = [
        { id: "skin", label: "Skin" },
        { id: "ecol", label: "Eye color" },
        { id: "ageGroup", label: "Age group" },
        { id: "presentation", label: "Presentation" },
        { id: "shape", label: "Body" },
        { id: "height", label: "Height" },
        { id: "hair", label: "Hair style" },
        { id: "hcol", label: "Hair color" },
        { id: "outfit", label: "Outfit" },
        { id: "top", label: "Top" },
        { id: "bottom", label: "Bottoms" },
        { id: "hat", label: "Hat" },
        { id: "gear", label: "Facial accessories" },
        { id: "back", label: "Worn accessories" },
        { id: "hand", label: "Weapons & powers" },
        { id: "tattoo", label: "Tattoo" },
        { id: "pet", label: "Pet" },
        { id: "petcolor", label: "Pet color" }
    ]
    sk = skinColors()
    skn = skinColorNames()
    hcs = hairColors()
    hcn = hairColorNames()
    ecs = eyeColors()
    ecn = eyeColorNames()
    for i = 0 to slots.count() - 1
        sl = slots[i]
        r = addItem(root, "slot", sl.id, 0, i + 1, 500, 196 + i * 37, 1000, 31, "0x182343FF")
        mkRect(r.node, 0, 0, 7, 31, "0x3E63DDFF")
        mkLabel(r.node, sl.label, 30, 3, 19, "0xAAB9DCFF")
        valTxt = ""
        if sl.id = "skin" then
            valTxt = skn[cfg.skin]
            mkRect(r.node, 910, 4, 28, 28, sk[cfg.skin])
            if cfg.baseSkin = "robot" then valTxt = "Ultron armor"
            if cfg.baseSkin = "emerald" then valTxt = "Emerald armor"
        else if sl.id = "hcol" then
            valTxt = hcn[cfg.hcol]
            mkRect(r.node, 910, 4, 28, 28, hcs[cfg.hcol])
        else if sl.id = "ecol" then
            valTxt = ecn[cfg.ecol]
            mkRect(r.node, 910, 4, 28, 28, ecs[cfg.ecol])
        else if sl.id = "ageGroup" then
            valTxt = ageGroupName(cfg.ageGroup)
        else if sl.id = "presentation" then
            valTxt = presentationName(cfg.presentation)
        else if sl.id = "shape" then
            valTxt = shapeName(cfg.shape)
        else if sl.id = "height" then
            valTxt = heightName(cfg.height)
        else if sl.id = "petcolor" then
            valTxt = petColorNames()[cfg.petColor]
        else if sl.id = "gear" then
            gopts = ownedList(m.who, "gear")
            if gopts.count() = 0 then
                valTxt = "none yet - see Shop"
            else
                if m.gearCur = invalid then m.gearCur = 0
                if m.gearCur >= gopts.count() then m.gearCur = 0
                gi = gopts[m.gearCur]
                gst = "off"
                if hasGear(cfg, gi.id) then gst = "ON"
                valTxt = gi.name + " : " + gst
            end if
        else if sl.id = "hand" then
            hopts = ownedList(m.who, "hand")
            if hopts.count() = 0 then
                valTxt = "none yet - see Shop"
            else
                if m.handCur = invalid then m.handCur = 0
                if m.handCur >= hopts.count() then m.handCur = 0
                hi = hopts[m.handCur]
                hst = "off"
                if hasHandItem(cfg, hi.id) then hst = "ON"
                valTxt = hi.name + " : " + hst
            end if
        else
            cur = itemById(cfg[sl.id])
            if cur <> invalid then valTxt = cur.name
        end if
        mkRect(r.node, 300, 1, 560, 29, "0x10182FFF")
        mkLabelW(r.node, "‹", 312, 1, 40, 23, "0xFFD66BFF", "center")
        mkLabelW(r.node, valTxt, 356, 4, 452, 20, m.C.text, "center")
        mkLabelW(r.node, "›", 812, 1, 40, 23, "0xFFD66BFF", "center")
    end for
    inv = addItem(root, "action", "avinventory", 0, 18, 500, 866, 490, 52, "0x153829FF")
    mkLabelW(inv.node, "VISUAL INVENTORY", 0, 12, 490, 27, m.C.green, "center")
    b = addItem(root, "action", "goshop", 1, 18, 1010, 866, 490, 52, "0x3E63DDFF")
    mkLabelW(b.node, "DISCOVER IN SHOP  ›", 0, 12, 490, 27, m.C.text, "center")
    ptxt = "PODIUM SHOWS: PRESET PICTURES  ·  OK TO SWITCH"
    if m.state.podiumAvatar = "built" then ptxt = "PODIUM SHOWS: YOUR BUILT LOOKS  ·  OK TO SWITCH"
    pb = addItem(root, "action", "podiumsrc", 0, 19, 500, 924, 1000, 52, "0x182343FF")
    mkRect(pb.node, 0, 0, 7, 52, "0x3E63DDFF")
    mkLabelW(pb.node, ptxt, 0, 11, 1000, 27, m.C.text, "center")
    spin = "NOT SET  ·  OK TO SET"
    if shopPinFor(m.who) <> "" then spin = "SET  ·  OK TO CHANGE"
    sp = addItem(root, "action", "avshoppin", 0, 20, 500, 982, 1000, 52, "0x182343FF")
    mkRect(sp.node, 0, 0, 7, 52, "0x3E63DDFF")
    mkLabelW(sp.node, "SPENDING PIN FOR " + UCase(personName(m.who)) + ": " + spin, 0, 11, 1000, 27, m.C.text, "center")
end sub

sub buildInventory()
    root = m.screenRoot
    ensureWho()
    if m.inventoryCat = invalid or m.inventoryCat = "" then m.inventoryCat = "outfit"
    if m.inventoryPage = invalid then m.inventoryPage = 0
    cfg = m.state.avatar[m.who]
    buildWhoRow(root)
    mkLabelW(root, "AVATAR INVENTORY", 940, 88, 520, 40, m.C.text, "left")
    mkLabelW(root, "Owned items for " + personName(m.who) + "  ·  choose an image to equip it", 940, 142, 620, 25, m.C.dim, "left")
    backButton = addItem(root, "action", "avatarback", 8, 0, 1570, 92, 294, 70, "0x3E63DDFF")
    mkLabelW(backButton.node, "BACK TO AVATAR", 0, 19, 294, 27, m.C.text, "center")
    buildPreviewPanel(root, cfg)

    cats = [
        { id: "outfit", label: "Outfits" },
        { id: "top", label: "Tops" },
        { id: "bottom", label: "Bottoms" },
        { id: "hat", label: "Hats" },
        { id: "hair", label: "Hair" },
        { id: "gear", label: "Face" },
        { id: "back", label: "Worn" },
        { id: "hand", label: "Weapons" },
        { id: "tattoo", label: "Tattoos" },
        { id: "pet", label: "Pets" }
    ]
    for i = 0 to cats.count() - 1
        bg = "0x182343FF"
        if m.inventoryCat = cats[i].id then bg = "0x3E63DDFF"
        catTile = addItem(root, "invcat", cats[i].id, i, 1, 500 + i * 136, 212, 128, 60, bg)
        if m.inventoryCat = cats[i].id then mkRect(catTile.node, 0, 54, 128, 6, "0x7EE2A8FF")
        mkLabelW(catTile.node, cats[i].label, 0, 18, 128, 21, m.C.text, "center")
    end for

    list = ownedList(m.who, m.inventoryCat)
    pageCount = (list.count() + 11) \ 12
    if pageCount < 1 then pageCount = 1
    if m.inventoryPage >= pageCount then m.inventoryPage = pageCount - 1
    if m.inventoryPage < 0 then m.inventoryPage = 0
    mkLabelW(root, list.count().toStr() + " OWNED  •  PAGE " + (m.inventoryPage + 1).toStr() + " OF " + pageCount.toStr(), 940, 176, 620, 20, "0xAAB9DCFF", "left")

    if list.count() = 0 then
        mkRect(root, 650, 360, 1060, 280, "0x182343FF")
        mkLabelW(root, "NO ITEMS IN THIS CATEGORY YET", 700, 438, 960, 34, m.C.text, "center")
        mkLabelW(root, "Visit the Shop to add choices to this inventory.", 700, 500, 960, 24, m.C.dim, "center")
    else
        pageStart = m.inventoryPage * 12
        pageEnd = pageStart + 11
        if pageEnd >= list.count() then pageEnd = list.count() - 1
        for i = pageStart to pageEnd
            it = list[i]
            displayIdx = i - pageStart
            col = displayIdx mod 6
            row = displayIdx \ 6
            if it.cat = "gear" then
                worn = hasGear(cfg, it.id)
            else if it.cat = "hand" then
                worn = hasHandItem(cfg, it.id)
            else if it.cat = "outfit" then
                worn = (cfg.outfit = it.id and cfg.top = "t_none" and cfg.bottom = "p_none")
            else
                worn = (cfg[it.cat] = it.id)
            end if
            bg = "0x182343FF"
            if worn then bg = "0x153829FF"
            tile = addItem(root, "invitem", it.id, col, row + 2, 500 + col * 228, 292 + row * 304, 220, 290, bg)
            if worn then mkRect(tile.node, 0, 0, 220, 7, "0x7EE2A8FF")
            pc = copyCfg(cfg)
            if it.cat = "gear" then
                setGear(pc, it.id, true)
            else if it.cat = "hand" then
                setHandItem(pc, it.id, true)
            else
                pc[it.cat] = it.id
                if it.cat = "outfit" then
                    pc.top = "t_none"
                    pc.bottom = "p_none"
                end if
            end if
            if it.cat = "outfit" or it.cat = "back" or it.cat = "hand" or it.cat = "top" or it.cat = "bottom" or it.cat = "pet" or it.cat = "tattoo" then
                drawAvatar(tile.node, 60, 14, 1, pc, "full")
            else
                drawAvatar(tile.node, 10, 20, 2, pc, "head")
            end if
            mkRect(tile.node, 18, 218, 184, 1, "0x34466FFF")
            mkLabelW(tile.node, it.name, 10, 228, 200, 21, m.C.text, "center")
            if worn and (it.cat = "gear" or it.cat = "hand") then
                mkLabelW(tile.node, "✓ EQUIPPED · OK REMOVE", 8, 262, 204, 17, m.C.green, "center")
            else if worn then
                mkLabelW(tile.node, "✓  EQUIPPED", 10, 262, 200, 20, m.C.green, "center")
            else
                mkLabelW(tile.node, "OWNED  ·  OK TO EQUIP", 10, 262, 200, 18, m.C.green, "center")
            end if
        end for
    end if

    if pageCount > 1 then
        if m.inventoryPage > 0 then
            prev = addItem(root, "invpage", "prev", 0, 4, 500, 910, 210, 38, "0x182343FF")
            mkLabelW(prev.node, "‹  PREVIOUS", 0, 7, 210, 22, m.C.text, "center")
        end if
        if m.inventoryPage < pageCount - 1 then
            nxt = addItem(root, "invpage", "next", 5, 4, 1650, 910, 210, 38, "0x182343FF")
            mkLabelW(nxt.node, "NEXT  ›", 0, 7, 210, 22, m.C.text, "center")
        end if
    end if
    mkLabelW(root, "OWNED ITEMS ONLY  •  OK EQUIPS  •  ACCESSORY LAYERS TOGGLE ON/OFF  •  BACK RETURNS TO AVATAR", 500, 956, 1360, 20, m.C.dim, "center")
end sub

sub buildShop()
    root = m.screenRoot
    ensureWho()
    if m.shopCat = invalid then m.shopCat = "outfit"
    if m.shopCat = "football" then m.shopCat = "sports"
    if m.shopPage = invalid then m.shopPage = 0
    cfg = m.state.avatar[m.who]
    buildWhoRow(root)
    mkLabelW(root, "THE STYLE SHOP", 940, 88, 400, 40, m.C.text, "left")
    mkLabelW(root, "Shopping for " + personName(m.who), 940, 142, 400, 25, m.C.dim, "left")
    mkLabelW(root, fmtCb(m.state.cb[m.who]) + " AVAILABLE", 1370, 98, 490, 28, "0xFFD66BFF", "right")
    buildPreviewPanel(root, cfg)
    cats = [
        { id: "outfit", label: "Outfits" },
        { id: "hat", label: "Hats" },
        { id: "hair", label: "Hair" },
        { id: "gear", label: "Face" },
        { id: "back", label: "Worn" },
        { id: "hand", label: "Weapons" },
        { id: "sports", label: "Sports" },
        { id: "cheer", label: "Cheer" },
        { id: "season", label: "Seasonal" },
        { id: "tattoos", label: "Tattoos" },
        { id: "pets", label: "Pets" }
    ]
    for i = 0 to cats.count() - 1
        bg = "0x182343FF"
        if m.shopCat = cats[i].id then bg = "0x3E63DDFF"
        t = addItem(root, "cat", cats[i].id, i, 1, 500 + i * 122, 212, 116, 60, bg)
        if m.shopCat = cats[i].id then mkRect(t.node, 0, 54, 116, 6, "0xFFD66BFF")
        mkLabelW(t.node, cats[i].label, 0, 18, 116, 19, m.C.text, "center")
    end for
    list = []
    for each it in catalog()
        if it.price > 0 then
            if it.tab <> "" then
                if it.tab = m.shopCat then list.push(it)
            else if it.cat = m.shopCat then
                list.push(it)
            end if
        end if
    end for
    ownedN = 0
    for each shopItem in list
        if isOwned(m.who, shopItem) then ownedN = ownedN + 1
    end for
    pageCount = (list.count() + 11) \ 12
    if pageCount < 1 then pageCount = 1
    if m.shopPage >= pageCount then m.shopPage = pageCount - 1
    if m.shopPage < 0 then m.shopPage = 0
    mkLabelW(root, list.count().toStr() + " STYLES  •  " + ownedN.toStr() + " OWNED  •  PAGE " + (m.shopPage + 1).toStr() + " OF " + pageCount.toStr(), 940, 176, 920, 20, "0xAAB9DCFF", "left")
    bal = m.state.cb[m.who]
    pageStart = m.shopPage * 12
    pageEnd = pageStart + 11
    if pageEnd >= list.count() then pageEnd = list.count() - 1
    for i = pageStart to pageEnd
        it = list[i]
        displayIdx = i - pageStart
        col = displayIdx mod 6
        row = displayIdx \ 6
        owned = isOwned(m.who, it)
        if it.cat = "gear" then
            worn = hasGear(cfg, it.id)
        else if it.cat = "hand" then
            worn = hasHandItem(cfg, it.id)
        else if it.cat = "outfit" then
            worn = (cfg.outfit = it.id and cfg.top = "t_none" and cfg.bottom = "p_none")
        else
            worn = (cfg[it.cat] = it.id)
        end if
        bg = "0x182343FF"
        if owned then bg = "0x153829FF"
        tile = addItem(root, "buy", it.id, col, row + 2, 500 + col * 228, 292 + row * 304, 220, 290, bg)
        if worn then mkRect(tile.node, 0, 0, 220, 7, "0x7EE2A8FF")
        pc = copyCfg(cfg)
        if it.cat = "gear" then
            setGear(pc, it.id, true)
        else if it.cat = "hand" then
            setHandItem(pc, it.id, true)
        else
            pc[it.cat] = it.id
            if it.cat = "outfit" then
                pc.top = "t_none"
                pc.bottom = "p_none"
            end if
        end if
        if it.cat = "outfit" or it.cat = "back" or it.cat = "hand" or it.cat = "top" or it.cat = "bottom" or it.cat = "pet" or it.cat = "tattoo" then
            drawAvatar(tile.node, 60, 14, 1, pc, "full")
        else
            drawAvatar(tile.node, 10, 20, 2, pc, "head")
        end if
        mkRect(tile.node, 18, 218, 184, 1, "0x34466FFF")
        mkLabelW(tile.node, it.name, 10, 228, 200, 21, m.C.text, "center")
        if worn then
            mkLabelW(tile.node, "✓  EQUIPPED", 10, 262, 200, 21, m.C.green, "center")
        else if owned then
            mkLabelW(tile.node, "OWNED  ·  OK TO EQUIP", 10, 262, 200, 19, m.C.green, "center")
        else if bal >= it.price then
            mkLabelW(tile.node, fmtCb(it.price) + "  ·  OK TO BUY", 10, 262, 200, 21, "0xFFD66BFF", "center")
        else
            mkLabelW(tile.node, fmtCb(it.price) + "  ·  NEED " + fmtCb(it.price - bal), 10, 262, 200, 19, m.C.dim, "center")
        end if
    end for
    if pageCount > 1 then
        if m.shopPage > 0 then
            prev = addItem(root, "page", "prev", 0, 4, 500, 910, 210, 38, "0x182343FF")
            mkLabelW(prev.node, "‹  PREVIOUS", 0, 7, 210, 22, m.C.text, "center")
        end if
        if m.shopPage < pageCount - 1 then
            nxt = addItem(root, "page", "next", 5, 4, 1650, 910, 210, 38, "0x182343FF")
            mkLabelW(nxt.node, "NEXT  ›", 0, 7, 210, 22, m.C.text, "center")
        end if
    end if
    mkLabelW(root, "PREVIEW ANY ITEM  •  PURCHASES REQUIRE REVIEW + SPENDING PIN  •  OWNED ITEMS EQUIP INSTANTLY", 500, 956, 1360, 20, m.C.dim, "center")
end sub
