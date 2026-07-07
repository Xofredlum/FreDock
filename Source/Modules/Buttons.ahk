;============================================================
; FreDock - Buttons Module
;============================================================
;
; Purpose:
; Builds the main FreDock window and manages dock button
; rendering, edit mode visual state, toolbar micro-interactions
; and click feedback.
;
; Beta 1 focus:
; - complete Dark / Light / System appearance support
; - toolbar and dock text colors adapt to the active theme
; - theme switch applies immediately from Settings
;
;============================================================

BuildGui() {
    global mainGui, statusText, editBtn, addBtn
    global MAIN_WIDTH, TOOL_HEIGHT, alwaysOnTop, editMode
    global ButtonHoverMap, lastButtonHoverHwnd
    global ToolHoverMap, lastToolHoverHwnd

    try mainGui.Destroy()

    ButtonHoverMap := Map()
    lastButtonHoverHwnd := 0
    ToolHoverMap := Map()
    lastToolHoverHwnd := 0

    RegisterButtonHoverHandler()

    mainGui := Gui(alwaysOnTop ? "+AlwaysOnTop" : "", App.WindowTitle(editMode))
    mainGui.MarginX := Metrics.MarginX
    mainGui.MarginY := Metrics.MarginY

    EnableDarkTitleBar(mainGui)

    mainGui.BackColor := editMode ? C("BG_EDIT") : C("BG")
    mainGui.SetFont("s10 c" C("TEXT"), "Segoe UI")
    mainGui.OnEvent("Close", (*) => HideAndSavePosition())

    LoadButtonsFromIni()
    AddButtonsToGui()

    mainGui.Add("Text", "xm w" MAIN_WIDTH " h" Metrics.SeparatorHeight " Center c" C("LINE"), "──────────────────────")

    editCaption := editMode ? "✔ Done" : "Edit"
    editBg := editMode ? C("DONE") : C("TOOL")
    editWidth := editMode ? Metrics.EditButtonWidth : 46

    editTextColor := editMode ? "FFFFFF" : C("TEXT_SOFT")
    editBtn := mainGui.Add("Text", "xm w" editWidth " h" TOOL_HEIGHT " Center Border Background" editBg " c" editTextColor " 0x200", editCaption)
    helpBtn := mainGui.Add("Text", "x+" Metrics.Gap " w36 h" TOOL_HEIGHT " Center Border Background" C("TOOL") " c" C("TEXT_SOFT") " 0x200", "Help")
    settingsBtn := mainGui.Add("Text", "x+" Metrics.Gap " w58 h" TOOL_HEIGHT " Center Border Background" C("TOOL") " c" C("TEXT_SOFT") " 0x200", "Settings")
    aboutBtn := mainGui.Add("Text", "x+" Metrics.Gap " w46 h" TOOL_HEIGHT " Center Border Background" C("TOOL") " c" C("TEXT_SOFT") " 0x200", "About")
    exitBtn := mainGui.Add("Text", "x+" Metrics.Gap " w22 h" TOOL_HEIGHT " Center Border Background" C("TOOL") " c" C("TEXT_SOFT") " 0x200", "X")

    editBtn.SetFont("s9 c" editTextColor (editMode ? " Bold" : ""), "Segoe UI")
    helpBtn.SetFont("s9 c" C("TEXT_SOFT"), "Segoe UI")
    settingsBtn.SetFont("s9 c" C("TEXT_SOFT"), "Segoe UI")
    aboutBtn.SetFont("s9 c" C("TEXT_SOFT"), "Segoe UI")
    exitBtn.SetFont("s9 c" C("TEXT_SOFT"), "Segoe UI")

    editBtn.OnEvent("Click", (*) => ToggleEditMode())
    helpBtn.OnEvent("Click", (*) => ShowHelp())
    settingsBtn.OnEvent("Click", (*) => ShowSettings())
    aboutBtn.OnEvent("Click", (*) => ShowAbout())
    exitBtn.OnEvent("Click", (*) => ExitFreDock())

    RegisterToolHover(editBtn, editMode ? "done" : "edit")
    RegisterToolHover(helpBtn, "normal")
    RegisterToolHover(settingsBtn, "normal")
    RegisterToolHover(aboutBtn, "normal")
    RegisterToolHover(exitBtn, "exit")

    if editMode {
        mainGui.Add("Text", "xm w" MAIN_WIDTH " h" Metrics.SectionGap, "")
        statusText := mainGui.Add("Text", "xm w134 c" C("STATUS") " Center", "✔ EDIT MODE")
        addBtn := mainGui.Add("Text", "x+8 yp-6 w" Metrics.AddButtonWidth " h" Metrics.AddButtonHeight " Center Border Background" C("TOOL_EDIT") " cFFFFFF 0x200", "➕ Add")
        addBtn.SetFont("s9 cFFFFFF Bold", "Segoe UI")
        addBtn.OnEvent("Click", (*) => OpenButtonEditor(0))
        RegisterToolHover(addBtn, "add")
    } else {
        statusText := mainGui.Add("Text", "xm w" MAIN_WIDTH " c" C("STATUS") " Center", "")
        addBtn := ""
    }
}

AddButtonsToGui() {
    global Buttons

    for index, btn in Buttons
        AddDockButton(index, btn.Name, btn.Text)
}

AddDockButton(index, name, text) {
    global mainGui, MAIN_WIDTH, BUTTON_HEIGHT, editMode, Buttons, ButtonHoverMap

    bg := editMode ? C("BUTTON_EDIT") : C("BUTTON")
    caption := editMode ? "✎ " name : name

    btnCtrl := mainGui.Add("Text"
        , "xm w" MAIN_WIDTH " h" BUTTON_HEIGHT " Center Border Background" bg " c" C("TEXT") " 0x200"
        , caption)

    btnCtrl.SetFont("s10 c" C("TEXT"), "Segoe UI")
    btnCtrl.OnEvent("Click", ButtonClick.Bind(index))

    Buttons[index].Control := btnCtrl
    ButtonHoverMap[btnCtrl.Hwnd] := index
}

RegisterButtonHoverHandler() {
    global hoverHandlerRegistered

    if hoverHandlerRegistered
        return

    OnMessage(0x200, HandleMainMouseMove) ; WM_MOUSEMOVE
    hoverHandlerRegistered := true
}

HandleMainMouseMove(wParam, lParam, msg, hwnd) {
    global ButtonHoverMap, lastButtonHoverHwnd
    global ToolHoverMap, lastToolHoverHwnd

    if (lastButtonHoverHwnd && lastButtonHoverHwnd != hwnd)
        RestoreButtonHover(lastButtonHoverHwnd)

    if (lastToolHoverHwnd && lastToolHoverHwnd != hwnd)
        RestoreToolHover(lastToolHoverHwnd)

    if ButtonHoverMap.Has(hwnd) {
        if (lastButtonHoverHwnd != hwnd) {
            ApplyButtonHover(hwnd)
            lastButtonHoverHwnd := hwnd
        }
    } else {
        lastButtonHoverHwnd := 0
    }

    if ToolHoverMap.Has(hwnd) {
        if (lastToolHoverHwnd != hwnd) {
            ApplyToolHover(hwnd)
            lastToolHoverHwnd := hwnd
        }
    } else {
        lastToolHoverHwnd := 0
    }
}

ApplyButtonHover(hwnd) {
    global ButtonHoverMap, Buttons, editMode

    if !ButtonHoverMap.Has(hwnd)
        return

    index := ButtonHoverMap[hwnd]
    if (index < 1 || index > Buttons.Length)
        return

    ; Beta1-fix1: hover can fire while the GUI is being rebuilt or
    ; while the button array has just been rewritten after a settings/theme save.
    ; In that tiny timing window, the object may not yet expose Control.
    if !HasProp(Buttons[index], "Control")
        return

    ctrl := Buttons[index].Control
    if (ctrl = "")
        return

    try {
        if (ctrl.Text = "✔ Copied")
            return
        hoverBg := editMode ? C("BUTTON_EDIT_HOVER") : C("BUTTON_HOVER")
        ctrl.Opt("Background" hoverBg " c" C("TEXT"))
    }
}

RestoreButtonHover(hwnd) {
    global ButtonHoverMap, Buttons, editMode

    if !ButtonHoverMap.Has(hwnd)
        return

    index := ButtonHoverMap[hwnd]
    if (index < 1 || index > Buttons.Length)
        return

    ; Beta1-fix1: same safety guard as ApplyButtonHover().
    if !HasProp(Buttons[index], "Control")
        return

    ctrl := Buttons[index].Control
    if (ctrl = "")
        return

    try {
        if (ctrl.Text = "✔ Copied")
            return
        bg := editMode ? C("BUTTON_EDIT") : C("BUTTON")
        ctrl.Opt("Background" bg " c" C("TEXT"))
    }
}

RegisterToolHover(ctrl, kind := "normal") {
    global ToolHoverMap

    if (ctrl = "")
        return

    try ctrl.GetPos(&x, &y, &w, &h)

    normalBg := (kind = "done") ? C("DONE") : (kind = "add") ? C("TOOL_EDIT") : C("TOOL")
    hoverBg := C("TOOL_HOVER")
    hoverText := C("TEXT")

    if (kind = "done") {
        hoverBg := C("TOOL_DONE_HOVER")
        hoverText := "FFFFFF"
    } else if (kind = "add") {
        hoverBg := C("TOOL_EDIT_HOVER")
        hoverText := "FFFFFF"
    } else if (kind = "exit") {
        hoverBg := C("TOOL_EXIT_HOVER")
        hoverText := C("TEXT")
    } else if (kind = "edit") {
        hoverBg := C("TOOL_HOVER")
        hoverText := C("TEXT")
    }

    ToolHoverMap[ctrl.Hwnd] := {
        Control: ctrl,
        Kind: kind,
        X: x,
        Y: y,
        W: w,
        H: h,
        NormalBg: normalBg,
        HoverBg: hoverBg,
        HoverText: hoverText
    }
}

ApplyToolHover(hwnd) {
    global ToolHoverMap

    if !ToolHoverMap.Has(hwnd)
        return

    item := ToolHoverMap[hwnd]
    ctrl := item.Control
    grow := Metrics.ToolHoverGrow

    try {
        ctrl.Move(item.X - 1, item.Y - 1, item.W + grow, item.H + grow)
        ctrl.Opt("Background" item.HoverBg " c" item.HoverText)
        ctrl.SetFont("s" Metrics.ToolHoverFontSize " c" item.HoverText " Bold", "Segoe UI")
    }
}

RestoreToolHover(hwnd) {
    global ToolHoverMap, editMode

    if !ToolHoverMap.Has(hwnd)
        return

    item := ToolHoverMap[hwnd]
    ctrl := item.Control

    textColor := (item.Kind = "done" || item.Kind = "add") ? "FFFFFF" : C("TEXT_SOFT")
    fontWeight := (item.Kind = "done" || item.Kind = "add") ? " Bold" : ""

    try {
        ctrl.Move(item.X, item.Y, item.W, item.H)
        ctrl.Opt("Background" item.NormalBg " c" textColor)
        ctrl.SetFont("s9 c" textColor fontWeight, "Segoe UI")
    }
}

ShowMainWindow() {
    global mainGui, iniFile, snapMode

    windowX := IniRead(iniFile, "Window", "X", "")
    windowY := IniRead(iniFile, "Window", "Y", "")

    if (snapMode != "None") {
        mainGui.Show("AutoSize Hide")
        ApplySnap()
        mainGui.Show()
    } else if (windowX != "" && windowY != "") {
        mainGui.Show("AutoSize x" windowX " y" windowY)
    } else {
        mainGui.Show("AutoSize")
    }

    ApplyMainOpacity()
}

RebuildGuiKeepPosition(message := "", animate := false, oldHeight := 0) {
    global mainGui, snapMode, statusText

    x := ""
    y := ""

    try mainGui.GetPos(&x, &y, &w, &h)

    if (oldHeight = 0)
        oldHeight := h

    BuildGui()

    if (snapMode != "None") {
        mainGui.Show("AutoSize Hide")
        ApplySnap()
        mainGui.Show()
    } else if (x != "" && y != "") {
        mainGui.Show("AutoSize x" x " y" y)
    } else {
        mainGui.Show("AutoSize")
    }

    ApplyMainOpacity()

    try mainGui.GetPos(&newX, &newY, &newW, &newH)

    if (animate && oldHeight > 0 && newH > oldHeight) {
        mainGui.Move(,,, oldHeight)
        step := 6
        currentH := oldHeight
        while (currentH < newH) {
            currentH += step
            if (currentH > newH)
                currentH := newH
            mainGui.Move(,,, currentH)
            Sleep 8
        }
    }

    if (message != "")
        SetStatus(message)
}

ToggleEditMode() {
    global editMode, soundEnabled, mainGui

    oldH := 0
    try mainGui.GetPos(&x, &y, &w, &oldH)

    editMode := !editMode

    if soundEnabled
        SoundBeep editMode ? 760 : 520, 25

    RebuildGuiKeepPosition(editMode ? "Click a button or ➕ Add" : "Ready", editMode, oldH)
}

ButtonClick(index, *) {
    global editMode

    if editMode
        OpenButtonEditor(index)
    else
        CopyButton(index)
}

FlashButtonCopied(index) {
    global Buttons

    if (index < 1 || index > Buttons.Length)
        return

    if !HasProp(Buttons[index], "Control")
        return

    ctrl := Buttons[index].Control
    if (ctrl = "")
        return

    try {
        ctrl.Text := "✔ Copied"
        ctrl.SetFont("s10 cFFFFFF Bold", "Segoe UI")
        ctrl.Opt("Background" C("BUTTON_FEEDBACK") " cFFFFFF")
        SetTimer RestoreButtonCaption.Bind(index), -Metrics.CopiedFeedbackMs
    }
}

RestoreButtonCaption(index, *) {
    global Buttons, editMode

    if (index < 1 || index > Buttons.Length)
        return

    if !HasProp(Buttons[index], "Control")
        return

    ctrl := Buttons[index].Control
    if (ctrl = "")
        return

    try {
        caption := editMode ? "✎ " Buttons[index].Name : Buttons[index].Name
        bg := editMode ? C("BUTTON_EDIT") : C("BUTTON")
        ctrl.Text := caption
        ctrl.SetFont("s10 c" C("TEXT"), "Segoe UI")
        ctrl.Opt("Background" bg " c" C("TEXT"))
    }
}
