' ================= Meals and Family Messages =================

function familyDayNames() as Object
    return ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
end function

function mealPlanOptions(category as String) as Object
    if category = "entree" then return ["", "Chicken Thighs", "Pasta", "Chicken Cutlets", "Pork Tenderloin", "Steak", "Pork Fried Rice", "Chicken Fried Rice"]
    if category = "side" then return ["", "White Rice", "Rice Casserole", "Baked Mac & Cheese", "Stuffing", "Mashed Potatoes", "Sweet Potato", "Baked Potato"]
    if category = "vegetable" then return ["", "Green Beans", "Peas", "Corn", "Broccoli", "Stir Fry"]
    return ["", "Rolls", "Italian Pancakes"]
end function

function mealPlanCategoryName(category as String) as String
    if category = "entree" then return "ENTRÉE"
    if category = "side" then return "SIDE DISH"
    if category = "vegetable" then return "VEGETABLE"
    return "OTHER"
end function

function mealPlanSummary(dayIndex as Integer) as String
    if dayIndex < 0 or dayIndex >= m.state.family.mealPlans.count() then return ""
    plan = m.state.family.mealPlans[dayIndex]
    summary = ""
    for each category in ["entree", "side", "vegetable", "other"]
        value = plan[category]
        if value <> invalid and value <> "" then
            if summary <> "" then summary = summary + " · "
            summary = summary + value
        end if
    end for
    return summary
end function

function familyDinnerText(dayIndex as Integer) as String
    planned = mealPlanSummary(dayIndex)
    if planned <> "" then return planned
    return m.state.family.meals[dayIndex]
end function

sub clearMealPlanDay(dayIndex as Integer)
    m.state.family.mealPlans[dayIndex] = { entree: "", side: "", vegetable: "", other: "" }
end sub

function familyNowSeconds() as Integer
    return CreateObject("roDateTime").AsSeconds()
end function

function familyFieldText(id as String) as String
    if left(id, 5) = "plan:" then
        parts = id.split(":")
        dayIndex = parts[1].toInt()
        return m.state.family.mealPlans[dayIndex][parts[2]]
    end if
    idx = right(id, 1).toInt()
    if left(id, 4) = "meal" then return m.state.family.meals[idx]
    if left(id, 3) = "ann" then return m.state.family.announcements[idx]
    if left(id, 3) = "rem" then return m.state.family.reminders[idx].text
    return ""
end function

sub setFamilyFieldText(id as String, value as String)
    if left(id, 5) = "plan:" then
        parts = id.split(":")
        dayIndex = parts[1].toInt()
        plan = m.state.family.mealPlans[dayIndex]
        plan[parts[2]] = value
        m.state.family.mealPlans[dayIndex] = plan
        return
    end if
    idx = right(id, 1).toInt()
    if left(id, 4) = "meal" then
        m.state.family.meals[idx] = value
        clearMealPlanDay(idx)
    else if left(id, 3) = "ann" then
        m.state.family.announcements[idx] = value
    else if left(id, 3) = "rem" then
        reminder = m.state.family.reminders[idx]
        reminder.text = value
        if value = "" then
            reminder.expires = 0
        else if reminder.expires <= familyNowSeconds() then
            reminder.expires = familyNowSeconds() + (7 * 86400)
        end if
        m.state.family.reminders[idx] = reminder
    end if
end sub

function familyEditorTitle(id as String) as String
    if left(id, 5) = "plan:" then
        parts = id.split(":")
        return familyDayNames()[parts[1].toInt()] + " custom " + LCase(mealPlanCategoryName(parts[2]))
    end if
    idx = right(id, 1).toInt()
    if left(id, 4) = "meal" then return familyDayNames()[idx] + " dinner"
    if left(id, 3) = "ann" then return "Parent announcement " + (idx + 1).toStr()
    return "Expiring reminder " + (idx + 1).toStr()
end function

sub openFamilyEditor(id as String)
    if not m.admin then
        denyEdit()
        return
    end if
    m.familyEditId = id
    dialog = CreateObject("roSGNode", "StandardKeyboardDialog")
    dialog.title = familyEditorTitle(id)
    dialog.text = familyFieldText(id)
    dialog.buttons = ["SAVE", "CANCEL"]
    dialog.observeField("buttonSelected", "onFamilyKeyboardButton")
    m.familyKeyboard = dialog
    m.top.dialog = dialog
end sub

sub onFamilyKeyboardButton()
    if m.familyKeyboard = invalid then return
    selected = m.familyKeyboard.buttonSelected
    if selected = 0 then
        value = m.familyKeyboard.text.trim()
        if value.len() > 100 then value = left(value, 100)
        setFamilyFieldText(m.familyEditId, value)
        saveState()
        showToast("Family board updated")
    end if
    m.top.dialog = invalid
    m.familyKeyboard = invalid
    m.familyEditId = ""
    if m.screen = "family" or m.screen = "mealplanner" then rebuildScreen()
end sub

sub openMealPlanCustomEditor(category as String)
    if not m.admin then
        denyEdit()
        return
    end if
    openFamilyEditor("plan:" + m.mealPlanDay.toStr() + ":" + category)
end sub

sub selectMealPlanDay(id as String)
    m.mealPlanDay = id.toInt()
    rebuildScreen()
end sub

sub cycleMealPlanChoice(category as String, direction as Integer)
    if not m.admin then
        denyEdit()
        return
    end if
    options = mealPlanOptions(category)
    plan = m.state.family.mealPlans[m.mealPlanDay]
    current = plan[category]
    currentIndex = 0
    found = false
    for i = 0 to options.count() - 1
        if options[i] = current then currentIndex = i : found = true
    end for
    if not found then currentIndex = 0
    nextIndex = currentIndex + direction
    if nextIndex < 0 then nextIndex = options.count() - 1
    if nextIndex >= options.count() then nextIndex = 0
    plan[category] = options[nextIndex]
    m.state.family.mealPlans[m.mealPlanDay] = plan
    m.state.family.meals[m.mealPlanDay] = ""
    saveState()
    rebuildScreen()
end sub

sub clearMealPlanChoice(category as String)
    plan = m.state.family.mealPlans[m.mealPlanDay]
    plan[category] = ""
    m.state.family.mealPlans[m.mealPlanDay] = plan
    saveState()
    showToast(mealPlanCategoryName(category) + " cleared")
    rebuildScreen()
end sub

sub clearFamilyField(id as String)
    setFamilyFieldText(id, "")
    saveState()
    showToast("Entry cleared")
    rebuildScreen()
end sub

function familyReminderDaysLeft(expires as Integer) as Integer
    secondsLeft = expires - familyNowSeconds()
    if secondsLeft <= 0 then return 0
    return (secondsLeft + 86399) \ 86400
end function

sub adjustFamilyReminderExpiry(id as String, direction as Integer)
    idx = right(id, 1).toInt()
    reminder = m.state.family.reminders[idx]
    if reminder.text = "" then
        showToast("Add reminder text first")
        return
    end if
    choices = [1, 3, 7, 14, 30]
    currentDays = familyReminderDaysLeft(reminder.expires)
    choiceIdx = 0
    bestDistance = 999
    for i = 0 to choices.count() - 1
        distance = abs(choices[i] - currentDays)
        if distance < bestDistance then bestDistance = distance : choiceIdx = i
    end for
    choiceIdx = choiceIdx + direction
    if choiceIdx < 0 then choiceIdx = choices.count() - 1
    if choiceIdx >= choices.count() then choiceIdx = 0
    reminder.expires = familyNowSeconds() + (choices[choiceIdx] * 86400)
    m.state.family.reminders[idx] = reminder
    saveState()
    showToast("Reminder expires in " + choices[choiceIdx].toStr() + " days")
    rebuildScreen()
end sub

sub expireFamilyReminders()
    changed = false
    now = familyNowSeconds()
    for i = 0 to m.state.family.reminders.count() - 1
        reminder = m.state.family.reminders[i]
        if reminder.text <> "" and reminder.expires > 0 and reminder.expires <= now then
            m.state.family.reminders[i] = { text: "", expires: 0 }
            changed = true
        end if
    end for
    if changed then saveState()
end sub

sub drawFamilyField(root as Object, id as String, col as Integer, row as Integer, x as Integer, y as Integer, w as Integer, h as Integer, label as String, value as String, accent as String)
    item = addItem(root, "familyfield", id, col, row, x, y, w, h, m.C.panel)
    mkRect(item.node, 0, 0, 7, h, accent)
    mkLabel(item.node, label, 24, 12, 19, m.C.dim)
    shown = value
    if shown = "" then shown = "Not set"
    valueColor = m.C.text
    if value = "" then valueColor = m.C.dim
    field = mkLabelW(item.node, shown, 24, 42, w - 48, 28, valueColor, "left")
    field.wrap = false
    field.ellipsizeOnBoundary = true
end sub

sub buildFamily()
    expireFamilyReminders()
    root = m.screenRoot
    days = familyDayNames()
    ni = nowInfo()
    theme = monthTheme(ni.month)
    surface = monthSurfaceTheme(ni.month)
    drawSeasonalHub(root, ni.month)

    mkLabel(root, "MEALS & FAMILY MESSAGES", 56, 84, 44, m.C.text)
    modeText = "VIEW ONLY · select a change to enter the Admin PIN"
    if m.admin then modeText = "ADMIN EDITING · OK edit · * clear · << >> changes reminder expiry"
    mkLabelW(root, modeText, 760, 100, 690, 24, m.C.dim, "right")
    plannerButton = addItem(root, "action", "mealplanner", 2, -1, 1490, 90, 374, 52, theme.bg)
    mkRect(plannerButton.node, 0, 0, 7, 52, theme.a)
    mkLabelW(plannerButton.node, "OPEN MEAL PLANNER", 12, 13, 348, 24, m.C.text, "center")

    dinner = familyDinnerText(ni.dow)
    dinnerCard = addItem(root, "familyfield", "meal" + ni.dow.toStr(), 0, 0, 56, 158, 870, 150, surface.panel)
    mkRect(dinnerCard.node, 0, 0, 9, 150, theme.a)
    mkLabel(dinnerCard.node, "TONIGHT'S DINNER", 30, 20, 22, theme.b)
    dinnerShown = dinner
    if dinnerShown = "" then dinnerShown = "Dinner has not been planned yet"
    dinnerLabel = mkLabelW(dinnerCard.node, dinnerShown, 30, 60, 810, 46, m.C.text, "left")
    dinnerLabel.wrap = false
    dinnerLabel.ellipsizeOnBoundary = true
    mkLabel(dinnerCard.node, days[ni.dow] + " · OK requests Admin approval", 30, 116, 19, m.C.dim)

    mkRect(root, 954, 158, 910, 150, surface.panel)
    mkRect(root, 954, 158, 9, 150, theme.b)
    mkLabel(root, "FAMILY BOARD", 986, 178, 22, theme.a)
    activeAnnouncements = 0
    activeReminders = 0
    for each announcement in m.state.family.announcements
        if announcement <> "" then activeAnnouncements = activeAnnouncements + 1
    end for
    for each reminder in m.state.family.reminders
        if reminder.text <> "" then activeReminders = activeReminders + 1
    end for
    mkLabelW(root, activeAnnouncements.toStr() + " announcements", 986, 220, 380, 31, m.C.text, "left")
    mkLabelW(root, activeReminders.toStr() + " active reminders", 1410, 220, 410, 31, m.C.text, "right")
    mkLabel(root, "Clear, shared, and visible to everyone", 986, 266, 20, m.C.dim)

    mkLabel(root, "WEEKLY MEAL PLAN", 56, 336, 26, theme.b)
    for i = 0 to 6
        mealValue = familyDinnerText(i)
        dayLabel = days[i]
        if i = ni.dow then dayLabel = dayLabel + " · TODAY"
        drawFamilyField(root, "meal" + i.toStr(), 0, i + 1, 56, 374 + (i * 88), 870, 76, dayLabel, mealValue, theme.a)
    end for

    mkLabel(root, "PARENT ANNOUNCEMENTS", 954, 336, 26, theme.b)
    for i = 0 to 2
        drawFamilyField(root, "ann" + i.toStr(), 1, i + 1, 954, 374 + (i * 112), 910, 98, "ANNOUNCEMENT " + (i + 1).toStr(), m.state.family.announcements[i], theme.b)
    end for

    mkLabel(root, "EXPIRING REMINDERS", 954, 724, 26, theme.b)
    for i = 0 to 3
        reminder = m.state.family.reminders[i]
        expiry = "NO REMINDER"
        if reminder.text <> "" then
            daysLeft = familyReminderDaysLeft(reminder.expires)
            if daysLeft = 1 then expiry = "EXPIRES TOMORROW" else expiry = "EXPIRES IN " + daysLeft.toStr() + " DAYS"
        end if
        drawFamilyField(root, "rem" + i.toStr(), 1, i + 5, 954, 762 + (i * 70), 910, 60, expiry, reminder.text, theme.a)
    end for
end sub

function mealChoiceIsCustom(category as String, value as String) as Boolean
    if value = "" then return false
    for each optionValue in mealPlanOptions(category)
        if optionValue = value then return false
    end for
    return true
end function

sub buildMealPlanner()
    root = m.screenRoot
    ni = nowInfo()
    if m.mealPlanDay < 0 or m.mealPlanDay > 6 then m.mealPlanDay = ni.dow
    days = familyDayNames()
    theme = monthTheme(ni.month)
    surface = monthSurfaceTheme(ni.month)
    drawSeasonalHub(root, ni.month)

    mkLabel(root, "WEEKLY MEAL PLANNER", 56, 84, 44, m.C.text)
    helpText = "VIEW ONLY · selecting a change requests the Admin PIN"
    if m.admin then helpText = "REW/FWD template · arrows navigate · OK custom entry · * clear slot"
    mkLabelW(root, helpText, 720, 100, 1144, 24, m.C.dim, "right")

    for i = 0 to 6
        dayBg = surface.panel
        if i = m.mealPlanDay then dayBg = surface.row
        dayButton = addItem(root, "mealday", i.toStr(), i, 0, 56 + (i * 258), 154, 244, 68, dayBg)
        if i = m.mealPlanDay then mkRect(dayButton.node, 0, 0, 244, 6, theme.a)
        dayText = days[i]
        if i = ni.dow then dayText = dayText + " · TODAY"
        mkLabelW(dayButton.node, dayText, 8, 20, 228, 24, m.C.text, "center")
    end for

    summary = familyDinnerText(m.mealPlanDay)
    if summary = "" then summary = "No meal has been planned for " + days[m.mealPlanDay]
    mkRect(root, 56, 244, 1808, 112, surface.panel)
    mkRect(root, 56, 244, 9, 112, theme.b)
    mkLabel(root, days[m.mealPlanDay] + " DINNER", 88, 264, 20, theme.a)
    summaryLabel = mkLabelW(root, summary, 88, 300, 1740, 34, m.C.text, "left")
    summaryLabel.wrap = false
    summaryLabel.ellipsizeOnBoundary = true

    categories = ["entree", "side", "vegetable", "other"]
    cardW = 880
    cardH = 246
    for i = 0 to categories.count() - 1
        category = categories[i]
        col = i mod 2
        row = i \ 2
        x = 56 + (col * 928)
        y = 388 + (row * 276)
        plan = m.state.family.mealPlans[m.mealPlanDay]
        value = plan[category]
        card = addItem(root, "mealchoice", category, col, row + 1, x, y, cardW, cardH, surface.panel)
        accent = theme.a
        if col = 1 then accent = theme.b
        mkRect(card.node, 0, 0, 9, cardH, accent)
        mkLabel(card.node, mealPlanCategoryName(category), 32, 24, 22, accent)
        choice = value
        if choice = "" then choice = "None selected"
        choiceColor = m.C.text
        if value = "" then choiceColor = m.C.dim
        choiceLabel = mkLabelW(card.node, choice, 32, 76, cardW - 64, 44, choiceColor, "left")
        choiceLabel.wrap = false
        choiceLabel.ellipsizeOnBoundary = true
        sourceLabel = "TEMPLATE CHOICE"
        if value = "" then sourceLabel = "EMPTY SLOT"
        if mealChoiceIsCustom(category, value) then sourceLabel = "CUSTOM SLOT"
        mkLabel(card.node, sourceLabel, 32, 140, 19, m.C.gold)
        mkLabelW(card.node, "<< REW  ·  TEMPLATES  ·  FWD >>", 32, 190, 420, 21, m.C.dim, "left")
        mkLabelW(card.node, "OK · CUSTOM ENTRY", 420, 190, 420, 21, accent, "right")
    end for

    mkLabelW(root, "Back returns to Meals & Family Messages · Custom entries are saved with the same weekly plan.", 56, 976, 1808, 21, theme.a, "center")
end sub
