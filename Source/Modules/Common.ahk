;============================================================
; FreDock - Common Module
;============================================================

EnsureIniExists() {
    global iniFile

    if FileExist(iniFile)
        return

    Loop 6 {
        IniWrite "Button " A_Index, iniFile, "Button" A_Index, "Name"
        IniWrite "", iniFile, "Button" A_Index, "Text"
    }

    IniWrite "", iniFile, "Window", "X"
    IniWrite "", iniFile, "Window", "Y"

    IniWrite "1", iniFile, "Options", "Sound"
    IniWrite "1", iniFile, "Options", "AlwaysOnTop"
    IniWrite "None", iniFile, "Options", "Snap"
    IniWrite "Dark", iniFile, "Options", "Appearance"
    IniWrite "100", iniFile, "Options", "Opacity"
}

LoadOptions() {
    global iniFile, soundEnabled, alwaysOnTop, snapMode, appearanceMode, opacityPercent

    soundEnabled := IniRead(iniFile, "Options", "Sound", "1") = "1"
    alwaysOnTop := IniRead(iniFile, "Options", "AlwaysOnTop", "1") = "1"
    snapMode := IniRead(iniFile, "Options", "Snap", "None")
    appearanceMode := IniRead(iniFile, "Options", "Appearance", "Dark")
    opacityPercent := Integer(IniRead(iniFile, "Options", "Opacity", "100"))
    if (opacityPercent < 70)
        opacityPercent := 70
    if (opacityPercent > 100)
        opacityPercent := 100
    Theme.Set(appearanceMode)
}

LoadButtonsFromIni() {
    global iniFile, Buttons

    Buttons := []
    index := 1

    Loop {
        section := "Button" index
        name := IniRead(iniFile, section, "Name", "__MISSING__")
        text := IniRead(iniFile, section, "Text", "__MISSING__")

        if (name = "__MISSING__" && text = "__MISSING__")
            break

        if (name = "")
            name := "Button " index

        Buttons.Push({ Index: index, Name: name, Text: text, Control: "" })
        index++
    }
}

SaveAllButtonsToIni() {
    global iniFile, Buttons, lastIniModified, isSavingIni
    global soundEnabled, alwaysOnTop, snapMode, appearanceMode, opacityPercent, mainGui

    ; Fixed4: atomic-style INI save.
    ; We no longer delete Button sections directly in FreDock.ini.
    ; Instead, we write a complete clean INI to FreDock.ini.tmp,
    ; then replace FreDock.ini in one final move operation.
    ; This prevents the auto-reload watcher from ever seeing a half-empty INI.
    Critical "On"
    isSavingIni := true

    tempFile := iniFile ".tmp"

    try {
        ; Build a safe snapshot first. Never save GUI controls or partial objects.
        cleanButtons := []

        for index, btn in Buttons {
            if !IsObject(btn)
                continue
            if !HasProp(btn, "Name") || !HasProp(btn, "Text")
                continue

            cleanButtons.Push({
                Index: cleanButtons.Length + 1,
                Name: btn.Name,
                Text: btn.Text,
                Control: ""
            })
        }

        ; Preserve current/known window position.
        windowX := IniRead(iniFile, "Window", "X", "")
        windowY := IniRead(iniFile, "Window", "Y", "")

        try {
            mainGui.GetPos(&x, &y, &w, &h)
            windowX := x
            windowY := y
        }

        ; Start from a fresh temporary file.
        try FileDelete tempFile

        ; Write buttons to temp file.
        for index, btn in cleanButtons {
            IniWrite btn.Name, tempFile, "Button" index, "Name"
            IniWrite btn.Text, tempFile, "Button" index, "Text"
            btn.Index := index
        }

        ; Write non-button sections to temp file too.
        IniWrite windowX, tempFile, "Window", "X"
        IniWrite windowY, tempFile, "Window", "Y"

        IniWrite soundEnabled ? "1" : "0", tempFile, "Options", "Sound"
        IniWrite alwaysOnTop ? "1" : "0", tempFile, "Options", "AlwaysOnTop"
        IniWrite snapMode, tempFile, "Options", "Snap"
        IniWrite appearanceMode, tempFile, "Options", "Appearance"
        IniWrite opacityPercent, tempFile, "Options", "Opacity"

        ; Replace real INI only after the temp file is fully written.
        FileMove tempFile, iniFile, 1

        Buttons := cleanButtons
        lastIniModified := FileGetTime(iniFile, "M")
    } catch as err {
        try FileDelete tempFile
        MsgBox "Unable to save FreDock.ini.`n`n" err.Message, "FreDock", "Icon!"
    } finally {
        isSavingIni := false
        Critical "Off"
    }
}

; ==========================================================
; Main GUI
; ==========================================================

WatchIniChanges() {
    global iniFile, lastIniModified, isSavingIni
    global soundEnabled, editMode

    if isSavingIni
        return

    if !FileExist(iniFile)
        return

    currentModified := FileGetTime(iniFile, "M")

    if (currentModified != lastIniModified) {
        lastIniModified := currentModified
        LoadOptions()
        RebuildGuiKeepPosition("↻ Config reloaded")

        if soundEnabled
            SoundBeep 700, 25
    }
}

SaveWindowPosition() {
    global mainGui, iniFile, lastIniModified, snapMode, isSavingIni

    try {
        if (snapMode = "None") {
            Critical "On"
            isSavingIni := true
            try {
                mainGui.GetPos(&x, &y, &w, &h)
                IniWrite x, iniFile, "Window", "X"
                IniWrite y, iniFile, "Window", "Y"
                lastIniModified := FileGetTime(iniFile, "M")
            } finally {
                isSavingIni := false
                Critical "Off"
            }
        }
    }
}

HideAndSavePosition() {
    global mainGui

    SaveWindowPosition()
    mainGui.Hide()
}

ExitFreDock() {
    SaveWindowPosition()
    ExitApp
}

EnableDarkTitleBar(guiObj) {
    ; In Beta 1 the title bar follows the active theme.
    ; Dark theme: dark title bar. Light theme: standard light title bar.
    try {
        useDark := Theme.IsDark() ? 1 : 0
        DllCall("Dwmapi\DwmSetWindowAttribute"
            , "Ptr", guiObj.Hwnd
            , "Int", 20
            , "Int*", useDark
            , "Int", 4)
    }
}


SetWindowOpacity(guiObj, percent) {
    if (guiObj = "")
        return

    if (percent < 70)
        percent := 70
    if (percent > 100)
        percent := 100

    try {
        if (percent >= 100) {
            WinSetTransparent "Off", "ahk_id " guiObj.Hwnd
        } else {
            alpha := Round(255 * percent / 100)
            WinSetTransparent alpha, "ahk_id " guiObj.Hwnd
        }
    }
}

ApplyMainOpacity() {
    global mainGui, opacityPercent
    SetWindowOpacity(mainGui, opacityPercent)
}
