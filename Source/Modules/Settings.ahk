;============================================================
; FreDock - Settings Module
;============================================================
;
; Purpose:
; Handles the Settings dialog and user preferences.
; Beta 1 adds Appearance: Dark / Light / System.
;
;============================================================

ShowSettings() {
    global soundEnabled, alwaysOnTop, snapMode, appearanceMode, opacityPercent
    global iniFile, lastIniModified, mainGui

    settingsGui := Gui("+AlwaysOnTop", "FreDock Settings")
    settingsGui.MarginX := 18
    settingsGui.MarginY := 15

    EnableDarkTitleBar(settingsGui)

    settingsGui.BackColor := C("BG")
    settingsGui.SetFont("s10 c" C("TEXT"), "Segoe UI")

    settingsGui.Add("Text", "w320 Center c" C("TEXT"), "FreDock Settings")
    settingsGui.Add("Text", "w320 Center c" C("LINE"), "──────────────────────────────")

    settingsGui.Add("Text", "w320 c" C("TEXT_SOFT"), "Appearance:")

    appearanceChoices := ["Dark", "Light", "System"]
    appearanceIndex := 1

    for index, value in appearanceChoices {
        if (value = appearanceMode) {
            appearanceIndex := index
            break
        }
    }

    ddlAppearance := settingsGui.Add("DropDownList", "w320 Choose" appearanceIndex, appearanceChoices)

    settingsGui.Add("Text", "w320 c" C("TEXT_SOFT") " y+10", "Transparency:")

    opacityLabel := settingsGui.Add("Text", "w320 c" C("TEXT") " Center", "Window opacity: " opacityPercent "%")
    opacitySlider := settingsGui.Add("Slider", "w320 Range70-100 ToolTip", opacityPercent)
    opacitySlider.OnEvent("Change", (*) => PreviewOpacity(opacitySlider, opacityLabel))

    settingsGui.Add("Text", "w320 c" C("TEXT_SOFT") " y+10", "Options:")

    chkSound := settingsGui.Add("CheckBox", "w320 c" C("TEXT") " Checked" (soundEnabled ? "1" : "0"), "Sound")
    chkTop := settingsGui.Add("CheckBox", "w320 c" C("TEXT") " Checked" (alwaysOnTop ? "1" : "0"), "Always on top")

    settingsGui.Add("Text", "w320 c" C("TEXT_SOFT") " y+10", "Snap position:")

    snapChoices := ["None", "Left", "Right", "Top"]
    snapIndex := 1

    for index, value in snapChoices {
        if (value = snapMode) {
            snapIndex := index
            break
        }
    }

    ddlSnap := settingsGui.Add("DropDownList", "w320 Choose" snapIndex, snapChoices)

    settingsGui.Add("Text", "w320 Center c" C("LINE"), "──────────────────────────────")

    saveBtn := settingsGui.Add("Text", "w155 h26 Center Border Background" C("ACCENT") " cFFFFFF 0x200", "Save")
    cancelBtn := settingsGui.Add("Text", "x+10 w155 h26 Center Border Background" C("TOOL") " c" C("TEXT_SOFT") " 0x200", "Cancel")

    saveBtn.SetFont("s9 cFFFFFF", "Segoe UI")
    cancelBtn.SetFont("s9 c" C("TEXT_SOFT"), "Segoe UI")

    saveBtn.OnEvent("Click", (*) => SaveSettings(settingsGui, chkSound.Value, chkTop.Value, ddlSnap.Text, ddlAppearance.Text, opacitySlider.Value))
    cancelBtn.OnEvent("Click", (*) => CancelSettings(settingsGui))

    settingsGui.Show("AutoSize")
}

SaveSettings(settingsGui, newSound, newTop, newSnap, newAppearance, newOpacity) {
    global soundEnabled, alwaysOnTop, snapMode, appearanceMode, opacityPercent
    global iniFile, lastIniModified, mainGui, isSavingIni

    soundEnabled := newSound = 1
    alwaysOnTop := newTop = 1
    snapMode := newSnap
    appearanceMode := newAppearance
    opacityPercent := Integer(newOpacity)
    if (opacityPercent < 70)
        opacityPercent := 70
    if (opacityPercent > 100)
        opacityPercent := 100
    Theme.Set(appearanceMode)

    Critical "On"
    isSavingIni := true
    try {
        IniWrite soundEnabled ? "1" : "0", iniFile, "Options", "Sound"
        IniWrite alwaysOnTop ? "1" : "0", iniFile, "Options", "AlwaysOnTop"
        IniWrite snapMode, iniFile, "Options", "Snap"
        IniWrite appearanceMode, iniFile, "Options", "Appearance"
        IniWrite opacityPercent, iniFile, "Options", "Opacity"
        lastIniModified := FileGetTime(iniFile, "M")
    } finally {
        isSavingIni := false
        Critical "Off"
    }

    settingsGui.Destroy()

    ; Rebuild immediately so the new theme is visible without restarting FreDock.
    RebuildGuiKeepPosition("Appearance updated")

    if soundEnabled
        SoundBeep 700, 25
}

PreviewOpacity(slider, label) {
    global mainGui

    value := Integer(slider.Value)
    label.Text := "Window opacity: " value "%"
    SetWindowOpacity(mainGui, value)
}

CancelSettings(settingsGui) {
    global opacityPercent, mainGui

    SetWindowOpacity(mainGui, opacityPercent)
    settingsGui.Destroy()
}

ApplySnap() {
    global mainGui, snapMode

    mainGui.GetPos(&x, &y, &w, &h)
    MonitorGetWorkArea(1, &left, &top, &right, &bottom)

    if (snapMode = "Left") {
        mainGui.Move(left + 10, top + 10)
    } else if (snapMode = "Right") {
        mainGui.Move(right - w - 10, top + 10)
    } else if (snapMode = "Top") {
        mainGui.Move((right - left - w) // 2, top + 10)
    }
}
