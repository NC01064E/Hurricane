' ================= Animated Seasonal Ambient Worlds =================

function ambientSeasonForMonth(month as Integer) as String
    if month = 12 or month <= 2 then return "winter"
    if month >= 3 and month <= 5 then return "spring"
    if month >= 6 and month <= 8 then return "summer"
    return "fall"
end function

function ambientSeasonName(kind as String) as String
    if kind = "winter" then return "WINTER BLOCKSCAPE"
    if kind = "spring" then return "SPRING BLOSSOM WORLD"
    if kind = "summer" then return "SUMMER BLOCK BEACH"
    return "FALL BLOCK FOREST"
end function

sub drawBlockTree(parent as Object, x as Integer, groundY as Integer, scale as Integer, trunk as String, leaves as Object)
    unit = 18 * scale
    mkRect(parent, x + (unit * 2), groundY - (unit * 5), unit, unit * 5, trunk)
    mkRect(parent, x + unit, groundY - (unit * 7), unit * 3, unit * 2, leaves[0])
    mkRect(parent, x, groundY - (unit * 6), unit * 5, unit * 2, leaves[1])
    mkRect(parent, x + unit, groundY - (unit * 8), unit * 3, unit, leaves[2])
    mkRect(parent, x + (unit * 4), groundY - (unit * 5), unit, unit, leaves[0])
end sub

sub drawBlockPine(parent as Object, x as Integer, groundY as Integer, scale as Integer)
    unit = 16 * scale
    mkRect(parent, x + (unit * 3), groundY - (unit * 4), unit, unit * 4, "0x704321FF")
    mkRect(parent, x + (unit * 2), groundY - (unit * 7), unit * 3, unit * 2, "0x174B37FF")
    mkRect(parent, x + unit, groundY - (unit * 5), unit * 5, unit * 2, "0x1F6547FF")
    mkRect(parent, x, groundY - (unit * 3), unit * 7, unit * 2, "0x277A50FF")
    mkRect(parent, x + (unit * 2), groundY - (unit * 7), unit * 3, 8 * scale, "0xEAF7FFFF")
    mkRect(parent, x + unit, groundY - (unit * 5), unit * 5, 7 * scale, "0xDDF1FAFF")
end sub

sub drawSeasonCelestial(parent as Object, sky as Object)
    if sky.phase = "NIGHT TIME" or sky.phase = "LATE NIGHT" then
        drawAmbientStars(parent, "0xE8F2FFFF")
        phase = moonPhaseInfo()
        drawMoonGlyph(parent, 1600, 106, 2, phase.index, sky.top)
    else
        drawAmbientSun(parent, sky)
    end if
end sub

sub drawFallWorld(parent as Object, fx as Object)
    mkRect(parent, 0, 570, 1920, 510, "0x6E4828FF")
    mkRect(parent, 0, 570, 1920, 34, "0xA66B2FFF")
    for i = 0 to 39
        c = "0x8B5528FF"
        if i mod 3 = 1 then c = "0x75451FFF"
        if i mod 3 = 2 then c = "0xB17A3FFF"
        mkRect(parent, i * 52, 604 + ((i mod 2) * 26), 52, 52, c)
    end for
    leavesA = ["0xD4482FFF", "0xE87828FF", "0xF2B134FF"]
    leavesB = ["0xB82F2FFF", "0xD85826FF", "0xE89E2FFF"]
    drawBlockTree(parent, 36, 620, 2, "0x704321FF", leavesA)
    drawBlockTree(parent, 330, 650, 1, "0x61391EFF", leavesB)
    drawBlockTree(parent, 1510, 630, 2, "0x704321FF", leavesB)
    drawBlockTree(parent, 1330, 650, 1, "0x61391EFF", leavesA)
    leafColors = ["0xF2B134FF", "0xE87828FF", "0xD4482FFF", "0xA9342FFF"]
    for i = 0 to 31
        x = 24 + ((i * 157) mod 1880)
        y = -130 + ((i * 83) mod 650)
        size = 9 + ((i mod 3) * 4)
        mkRect(fx, x, y, size, size, leafColors[i mod 4])
        mkRect(fx, x + size, y + size, size, size, leafColors[(i + 1) mod 4])
    end for
end sub

sub drawWinterWorld(parent as Object, fx as Object)
    mkRect(parent, 0, 570, 1920, 510, "0xCDE8F2FF")
    mkRect(parent, 0, 570, 1920, 40, "0xF4FBFFFF")
    for i = 0 to 17
        h = 40 + ((i mod 5) * 22)
        c = "0xDDEFF6FF"
        if i mod 2 = 1 then c = "0xBFDDEAFF"
        mkRect(parent, i * 120, 570 - h, 160, h, c)
    end for
    drawBlockPine(parent, 38, 650, 2)
    drawBlockPine(parent, 350, 635, 1)
    drawBlockPine(parent, 1500, 650, 2)
    drawBlockPine(parent, 1320, 630, 1)
    mkRect(parent, 760, 592, 220, 28, "0xA8D3E5FF")
    mkRect(parent, 800, 620, 142, 18, "0x8BC4DCFF")
    for i = 0 to 43
        x = 18 + ((i * 131) mod 1890)
        y = -100 + ((i * 71) mod 670)
        s = 5 + ((i mod 4) * 2)
        mkRect(fx, x, y, s, s * 2, "0xF4FBFFFF")
        mkRect(fx, x - (s \ 2), y + (s \ 2), s * 2, s, "0xE5F5FFFF")
    end for
end sub

sub drawSpringWorld(parent as Object, fx as Object)
    mkRect(parent, 0, 570, 1920, 510, "0x3E8E45FF")
    mkRect(parent, 0, 570, 1920, 34, "0x71C65AFF")
    for i = 0 to 39
        c = "0x4CA44FFF"
        if i mod 2 = 1 then c = "0x357E3DFF"
        mkRect(parent, i * 52, 604 + ((i mod 2) * 26), 52, 52, c)
    end for
    springLeaves = ["0x70C85AFF", "0x52AC4DFF", "0x8BD36AFF"]
    drawBlockTree(parent, 40, 635, 2, "0x754627FF", springLeaves)
    drawBlockTree(parent, 1510, 635, 2, "0x754627FF", springLeaves)
    blossomColors = ["0xFFD5E7FF", "0xFFAACDFF", "0xFFF0F6FF"]
    for i = 0 to 25
        bx = 54 + ((i * 61) mod 360)
        by = 330 + ((i * 47) mod 210)
        mkRect(parent, bx, by, 14, 14, blossomColors[i mod 3])
    end for
    for i = 0 to 25
        bx = 1518 + ((i * 61) mod 360)
        by = 330 + ((i * 47) mod 210)
        mkRect(parent, bx, by, 14, 14, blossomColors[(i + 1) mod 3])
    end for
    flowerColors = ["0xFFE45BFF", "0xFF8EB8FF", "0xA9D8FFFF", "0xF5F2FFFF"]
    for i = 0 to 24
        flowerX = 50 + (i * 76)
        flowerY = 620 + ((i mod 3) * 28)
        mkRect(parent, flowerX, flowerY, 5, 24, "0x226B35FF")
        mkRect(parent, flowerX - 5, flowerY, 15, 10, flowerColors[i mod 4])
    end for
    for i = 0 to 27
        x = 18 + ((i * 149) mod 1890)
        y = -110 + ((i * 89) mod 650)
        mkRect(fx, x, y, 12, 8, blossomColors[i mod 3])
        mkRect(fx, x + 8, y + 7, 9, 7, blossomColors[(i + 1) mod 3])
    end for
end sub

sub drawSummerWorld(parent as Object, fx as Object)
    mkRect(parent, 0, 520, 1920, 230, "0x2F9EC4FF")
    mkRect(parent, 0, 750, 1920, 330, "0xE7C36FFF")
    mkRect(parent, 0, 730, 1920, 32, "0xF5D98FFF")
    mkRect(parent, 0, 520, 1920, 30, "0x75D8E8FF")
    mkRect(parent, 0, 606, 1920, 24, "0x3FB4D3FF")
    mkRect(parent, 0, 692, 1920, 22, "0x2389B4FF")
    for i = 0 to 20
        mkRect(fx, -70 + (i * 110), 548 + ((i mod 3) * 86), 72, 8, "0xD9FAFFFF")
        mkRect(fx, -36 + (i * 110), 556 + ((i mod 3) * 86), 54, 7, "0x8BE2EEFF")
    end for
    mkRotRect(parent, 110, 470, 34, 300, "0x8A572DFF", -0.10)
    mkRect(parent, 48, 430, 120, 34, "0x238343FF")
    mkRotRect(parent, 96, 394, 34, 140, "0x2F9A50FF", -0.72)
    mkRotRect(parent, 130, 402, 34, 140, "0x2F9A50FF", 0.72)
    mkRotRect(parent, 1740, 468, 34, 302, "0x8A572DFF", 0.10)
    mkRect(parent, 1702, 430, 130, 34, "0x238343FF")
    mkRotRect(parent, 1740, 394, 34, 140, "0x2F9A50FF", -0.72)
    mkRotRect(parent, 1778, 402, 34, 140, "0x2F9A50FF", 0.72)
    mkRect(parent, 370, 790, 220, 18, "0xD7AA54FF")
    mkRect(parent, 406, 808, 148, 28, "0xF1D17EFF")
    mkRect(parent, 1338, 820, 180, 22, "0xD7AA54FF")
end sub

sub drawAmbientSeasonalBackground(root as Object, sky as Object, month as Integer)
    m.ambientSeasonKind = ambientSeasonForMonth(month)
    staticGroup = CreateObject("roSGNode", "Group")
    root.appendChild(staticGroup)
    drawSeasonCelestial(staticGroup, sky)
    m.ambientSeasonFxGroup = CreateObject("roSGNode", "Group")
    m.ambientSeasonFxGroup.translation = [0, m.ambientSeasonOffset]
    if m.ambientSeasonKind = "winter" then
        drawWinterWorld(staticGroup, m.ambientSeasonFxGroup)
    else if m.ambientSeasonKind = "spring" then
        drawSpringWorld(staticGroup, m.ambientSeasonFxGroup)
    else if m.ambientSeasonKind = "summer" then
        drawSummerWorld(staticGroup, m.ambientSeasonFxGroup)
    else
        drawFallWorld(staticGroup, m.ambientSeasonFxGroup)
    end if
    root.appendChild(m.ambientSeasonFxGroup)

    shadeOpacity = 0.0
    if sky.phase = "EVENING" then shadeOpacity = 0.14
    if sky.phase = "NIGHT TIME" then shadeOpacity = 0.28
    if sky.phase = "LATE NIGHT" then shadeOpacity = 0.42
    shade = mkRect(root, 0, 286, 1920, 794, "0x020713FF")
    shade.opacity = shadeOpacity
    mkLabelW(root, ambientSeasonName(m.ambientSeasonKind), 78, 266, 520, 18, "0xF5F7FFFF", "left")
end sub

sub animateAmbientSeason()
    if m.ambientSeasonFxGroup = invalid then return
    if m.ambientSeasonKind = "summer" then
        m.ambientSeasonOffset = (m.ambientSeasonOffset + 3) mod 110
        m.ambientSeasonFxGroup.translation = [m.ambientSeasonOffset, 0]
        return
    end if
    speed = 3
    wrap = 120
    sway = 0
    if m.ambientSeasonKind = "fall" then speed = 5 : wrap = 150
    if m.ambientSeasonKind = "spring" then speed = 2 : wrap = 130
    if m.ambientPulse = 1 or m.ambientPulse = 2 then sway = 4
    if m.ambientSeasonKind = "winter" then sway = -2
    m.ambientSeasonOffset = (m.ambientSeasonOffset + speed) mod wrap
    m.ambientSeasonFxGroup.translation = [sway, m.ambientSeasonOffset]
end sub
