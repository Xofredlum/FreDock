#Requires AutoHotkey v2.0
#SingleInstance Force

;@Ahk2Exe-SetName FreDock
;@Ahk2Exe-SetDescription FreDock - A lightweight clipboard companion
;@Ahk2Exe-SetVersion 1.2.0
;@Ahk2Exe-SetProductName FreDock
;@Ahk2Exe-SetProductVersion 1.2.0
;@Ahk2Exe-SetCompanyName Xofredlum
;@Ahk2Exe-SetCopyright © 2026 Xofredlum
;@Ahk2Exe-SetOrigFilename FreDock.exe

; ==========================================================
; FreDock 1.2.0
; A lightweight clipboard companion
;
; by Xofredlum
; Designed with ChatGPT && Xofredlum
;
; AutoHotkey v2
; ==========================================================

APP_NAME := "FreDock 1.2.0"
APP_AUTHOR := "by Xofredlum"
APP_CREDITS := "Designed with ChatGPT && Xofredlum"

COLOR_BG := "202020"
COLOR_BUTTON := "303030"
COLOR_TOOL := "282828"
COLOR_TEXT := "FFFFFF"
COLOR_DIM := "808080"
COLOR_LINE := "404040"
COLOR_ACCENT := "5DB7FF"
COLOR_STATUS := COLOR_ACCENT

MAIN_WIDTH := 230
BUTTON_HEIGHT := 28
TOOL_HEIGHT := 24

iniFile := A_ScriptDir "\FreDock.ini"
iconFile := A_ScriptDir "\FreDock.ico"
lastIniModified := ""

soundEnabled := true
alwaysOnTop := true
snapMode := "None"

ShowSplash()

if !FileExist(iniFile) {
    Loop 6 {
        IniWrite "Button " A_Index, iniFile, "Button" A_Index, "Name"
        IniWrite "", iniFile, "Button" A_Index, "Text"
    }

    IniWrite "", iniFile, "Window", "X"
    IniWrite "", iniFile, "Window", "Y"

    IniWrite "1", iniFile, "Options", "Sound"
    IniWrite "1", iniFile, "Options", "AlwaysOnTop"
    IniWrite "None", iniFile, "Options", "Snap"
}

soundEnabled := IniRead(iniFile, "Options", "Sound", "1") = "1"
alwaysOnTop := IniRead(iniFile, "Options", "AlwaysOnTop", "1") = "1"
snapMode := IniRead(iniFile, "Options", "Snap", "None")

lastIniModified := FileGetTime(iniFile, "M")

mainGui := Gui()

BuildGui()

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

SetTimer WatchIniChanges, 1000

ShowSplash() {
    global APP_CREDITS, COLOR_ACCENT, COLOR_BG, iconFile

    splash := Gui("-Caption +AlwaysOnTop +ToolWindow", "FreDock Splash")
    splash.BackColor := COLOR_BG
    splash.MarginX := 22
    splash.MarginY := 18

    if FileExist(iconFile)
        splash.Add("Picture", "w96 h96 Center", iconFile)

    splash.SetFont("s20 cFFFFFF Bold", "Segoe UI")
    splash.Add("Text", "w360 Center", "FreDock")

    splash.SetFont("s10 c808080", "Segoe UI")
    splash.Add("Text", "w360 Center", "Version 1.2.0")

    splash.Add("Text", "w360 Center c404040", "──────────────────────────────")

    splash.SetFont("s10 cCFCFCF", "Segoe UI")
    splash.Add("Text", "w360 Center", "A lightweight clipboard companion")

    splash.Add("Text", "w360 Center c404040", "──────────────────────────────")

    splash.SetFont("s9 c" COLOR_ACCENT, "Segoe UI")
    splash.Add("Text", "w360 Center", "by Xofredlum")

    splash.SetFont("s8 c808080", "Segoe UI")
    splash.Add("Text", "w360 Center", APP_CREDITS)

    splash.Show("AutoSize Center")
    WinSetTransparent 235, splash.Hwnd

    Sleep 1100
    splash.Destroy()
}

BuildGui() {
    global mainGui, statusText, APP_NAME
    global COLOR_BG, COLOR_TEXT, COLOR_LINE, COLOR_TOOL, COLOR_STATUS
    global MAIN_WIDTH, TOOL_HEIGHT
    global alwaysOnTop

    try mainGui.Destroy()

    mainGui := Gui(alwaysOnTop ? "+AlwaysOnTop" : "", APP_NAME)
    mainGui.MarginX := 12
    mainGui.MarginY := 8

    DllCall("Dwmapi\DwmSetWindowAttribute"
        , "Ptr", mainGui.Hwnd
        , "Int", 20
        , "Int*", 1
        , "Int", 4)

    mainGui.BackColor := COLOR_BG
    mainGui.SetFont("s10 c" COLOR_TEXT, "Segoe UI")
    mainGui.OnEvent("Close", (*) => HideAndSavePosition())

    LoadButtonsFromIni()

    mainGui.Add("Text", "xm w" MAIN_WIDTH " h8 Center c" COLOR_LINE, "──────────────────────")

    editBtn := mainGui.Add("Text", "xm w36 h" TOOL_HEIGHT " Center Border Background" COLOR_TOOL " cC0C0C0 0x200", "Edit")
    helpBtn := mainGui.Add("Text", "x+3 w36 h" TOOL_HEIGHT " Center Border Background" COLOR_TOOL " cC0C0C0 0x200", "Help")
    settingsBtn := mainGui.Add("Text", "x+3 w58 h" TOOL_HEIGHT " Center Border Background" COLOR_TOOL " cC0C0C0 0x200", "Settings")
    aboutBtn := mainGui.Add("Text", "x+3 w46 h" TOOL_HEIGHT " Center Border Background" COLOR_TOOL " cC0C0C0 0x200", "About")
    exitBtn := mainGui.Add("Text", "x+3 w36 h" TOOL_HEIGHT " Center Border Background" COLOR_TOOL " cC0C0C0 0x200", "Exit")

    editBtn.SetFont("s9 cC0C0C0", "Segoe UI")
    helpBtn.SetFont("s9 cC0C0C0", "Segoe UI")
    settingsBtn.SetFont("s9 cC0C0C0", "Segoe UI")
    aboutBtn.SetFont("s9 cC0C0C0", "Segoe UI")
    exitBtn.SetFont("s9 cC0C0C0", "Segoe UI")

    editBtn.OnEvent("Click", (*) => EditIni())
    helpBtn.OnEvent("Click", (*) => ShowHelp())
    settingsBtn.OnEvent("Click", (*) => ShowSettings())
    aboutBtn.OnEvent("Click", (*) => ShowAbout())
    exitBtn.OnEvent("Click", (*) => ExitFreDock())

    statusText := mainGui.Add("Text", "xm w" MAIN_WIDTH " c" COLOR_STATUS " Center", "")
}

LoadButtonsFromIni() {
    global iniFile

    index := 1

    Loop {
        section := "Button" index
        name := IniRead(iniFile, section, "Name", "__MISSING__")
        text := IniRead(iniFile, section, "Text", "__MISSING__")

        if (name = "__MISSING__" && text = "__MISSING__")
            break

        if (name = "")
            name := "Button " index

        AddButton(name, text)
        index++
    }
}

AddButton(name, text) {
    global mainGui, MAIN_WIDTH, BUTTON_HEIGHT, COLOR_BUTTON

    btn := mainGui.Add("Text"
        , "xm w" MAIN_WIDTH " h" BUTTON_HEIGHT " Center Border Background" COLOR_BUTTON " cFFFFFF 0x200"
        , name)

    btn.SetFont("s10 cFFFFFF", "Segoe UI")
    btn.OnEvent("Click", (*) => CopyToClipboard(text))
}

CopyToClipboard(text) {
    global statusText, soundEnabled

    if text = "" {
        if soundEnabled
            SoundBeep 300, 40

        statusText.Text := "⚠ Empty button"
        SetTimer () => statusText.Text := "", -1200
        return
    }

    A_Clipboard := text
    ClipWait 1

    if soundEnabled
        SoundBeep 500, 20

    statusText.Text := "✔ Copied to clipboard"
    SetTimer () => statusText.Text := "", -1200
}

EditIni() {
    global iniFile, statusText, soundEnabled

    Run 'notepad.exe "' iniFile '"'

    statusText.Text := "✎ Config opened"

    if soundEnabled
        SoundBeep 700, 25

    SetTimer () => statusText.Text := "", -1200
}

ShowSettings() {
    global soundEnabled, alwaysOnTop, snapMode
    global COLOR_BG, COLOR_ACCENT, statusText
    global iniFile, lastIniModified, mainGui

    settingsGui := Gui("+AlwaysOnTop", "FreDock Settings")
    settingsGui.MarginX := 16
    settingsGui.MarginY := 14

    DllCall("Dwmapi\DwmSetWindowAttribute"
        , "Ptr", settingsGui.Hwnd
        , "Int", 20
        , "Int*", 1
        , "Int", 4)

    settingsGui.BackColor := COLOR_BG
    settingsGui.SetFont("s10 cFFFFFF", "Segoe UI")

    settingsGui.Add("Text", "w300 Center cFFFFFF", "FreDock Settings")
    settingsGui.Add("Text", "w300 Center c404040", "──────────────────────────────")

    chkSound := settingsGui.Add("CheckBox", "w300 cFFFFFF Checked" (soundEnabled ? "1" : "0"), "Sound")
    chkTop := settingsGui.Add("CheckBox", "w300 cFFFFFF Checked" (alwaysOnTop ? "1" : "0"), "Always on top")

    settingsGui.Add("Text", "w300 cCFCFCF", "Snap position:")

    snapChoices := ["None", "Left", "Right", "Top"]
    snapIndex := 1

    for index, value in snapChoices {
        if (value = snapMode) {
            snapIndex := index
            break
        }
    }

    ddlSnap := settingsGui.Add("DropDownList", "w300 Choose" snapIndex, snapChoices)

    settingsGui.Add("Text", "w300 Center c404040", "──────────────────────────────")

    saveBtn := settingsGui.Add("Text", "w145 h26 Center Border Background282828 cC0C0C0 0x200", "Save")
    cancelBtn := settingsGui.Add("Text", "x+10 w145 h26 Center Border Background282828 cC0C0C0 0x200", "Cancel")

    saveBtn.SetFont("s9 cC0C0C0", "Segoe UI")
    cancelBtn.SetFont("s9 cC0C0C0", "Segoe UI")

    saveBtn.OnEvent("Click", (*) => SaveSettings(settingsGui, chkSound.Value, chkTop.Value, ddlSnap.Text))
    cancelBtn.OnEvent("Click", (*) => settingsGui.Destroy())

    settingsGui.Show("AutoSize")
}

SaveSettings(settingsGui, newSound, newTop, newSnap) {
    global soundEnabled, alwaysOnTop, snapMode
    global iniFile, lastIniModified, mainGui, statusText

    soundEnabled := newSound = 1
    alwaysOnTop := newTop = 1
    snapMode := newSnap

    IniWrite soundEnabled ? "1" : "0", iniFile, "Options", "Sound"
    IniWrite alwaysOnTop ? "1" : "0", iniFile, "Options", "AlwaysOnTop"
    IniWrite snapMode, iniFile, "Options", "Snap"

    mainGui.Opt(alwaysOnTop ? "+AlwaysOnTop" : "-AlwaysOnTop")

    if (snapMode != "None")
        ApplySnap()

    lastIniModified := FileGetTime(iniFile, "M")

    statusText.Text := "Settings saved"

    if soundEnabled
        SoundBeep 700, 25

    SetTimer () => statusText.Text := "", -1200

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

ShowHelp() {
    global COLOR_BG

    helpGui := Gui("+AlwaysOnTop", "FreDock Help")
    helpGui.MarginX := 14
    helpGui.MarginY := 12

    DllCall("Dwmapi\DwmSetWindowAttribute"
        , "Ptr", helpGui.Hwnd
        , "Int", 20
        , "Int*", 1
        , "Int", 4)

    helpGui.BackColor := COLOR_BG
    helpGui.SetFont("s10 cFFFFFF", "Segoe UI")

    helpGui.Add("Text", "w360 Center cFFFFFF", "FreDock Help")
    helpGui.Add("Text", "w360 Center c404040", "──────────────────────────────")
    helpGui.Add("Text", "w360 cCFCFCF", "• Click a button to copy its text to the clipboard.")
    helpGui.Add("Text", "w360 cCFCFCF", "• Paste with Ctrl+V.")
    helpGui.Add("Text", "w360 cCFCFCF", "• Use Edit to modify FreDock.ini.")
    helpGui.Add("Text", "w360 cCFCFCF", "• Save the INI file: FreDock reloads automatically.")
    helpGui.Add("Text", "w360 cCFCFCF", "• Add more buttons using [Button7], [Button8], etc.")
    helpGui.Add("Text", "w360 cCFCFCF", "• Use Settings to configure sound, top mode and snap.")
    helpGui.Add("Text", "w360 Center c404040", "──────────────────────────────")

    okBtn := helpGui.Add("Text", "w360 h26 Center Border Background282828 cC0C0C0 0x200", "OK")
    okBtn.SetFont("s9 cC0C0C0", "Segoe UI")
    okBtn.OnEvent("Click", (*) => helpGui.Destroy())

    helpGui.Show("AutoSize")
}

ShowAbout() {
    global APP_AUTHOR, APP_CREDITS, COLOR_ACCENT, COLOR_BG

    aboutGui := Gui("+AlwaysOnTop", "About FreDock")
    aboutGui.MarginX := 14
    aboutGui.MarginY := 12

    DllCall("Dwmapi\DwmSetWindowAttribute"
        , "Ptr", aboutGui.Hwnd
        , "Int", 20
        , "Int*", 1
        , "Int", 4)

    aboutGui.BackColor := COLOR_BG
    aboutGui.SetFont("s10 cFFFFFF", "Segoe UI")

    aboutGui.Add("Text", "w320 Center cFFFFFF", "FreDock")
    aboutGui.Add("Text", "w320 Center c808080", "Version 1.2.0")
    aboutGui.Add("Text", "w320 Center c404040", "──────────────────────────────")
    aboutGui.Add("Text", "w320 Center cCFCFCF", "A lightweight clipboard companion")
    aboutGui.Add("Text", "w320 Center c404040", "──────────────────────────────")
    aboutGui.Add("Text", "w320 Center c" COLOR_ACCENT, APP_AUTHOR)
    aboutGui.Add("Text", "w320 Center c808080", APP_CREDITS)
    aboutGui.Add("Text", "w320 Center c808080", "Powered by AutoHotkey v2")
    aboutGui.Add("Text", "w320 Center c404040", "──────────────────────────────")

    okBtn := aboutGui.Add("Text", "w320 h26 Center Border Background282828 cC0C0C0 0x200", "OK")
    okBtn.SetFont("s9 cC0C0C0", "Segoe UI")
    okBtn.OnEvent("Click", (*) => aboutGui.Destroy())

    aboutGui.Show("AutoSize")
}

WatchIniChanges() {
    global iniFile, lastIniModified, mainGui, statusText
    global soundEnabled, alwaysOnTop, snapMode

    if !FileExist(iniFile)
        return

    currentModified := FileGetTime(iniFile, "M")

    if (currentModified != lastIniModified) {
        lastIniModified := currentModified

        soundEnabled := IniRead(iniFile, "Options", "Sound", "1") = "1"
        alwaysOnTop := IniRead(iniFile, "Options", "AlwaysOnTop", "1") = "1"
        snapMode := IniRead(iniFile, "Options", "Snap", "None")

        try mainGui.GetPos(&x, &y, &w, &h)

        BuildGui()

        if (snapMode != "None") {
            mainGui.Show("AutoSize Hide")
            ApplySnap()
            mainGui.Show()
        } else {
            mainGui.Show("AutoSize x" x " y" y)
        }

        statusText.Text := "↻ Config reloaded"

        if soundEnabled
            SoundBeep 700, 25

        SetTimer () => statusText.Text := "", -1200
    }
}

SaveWindowPosition() {
    global mainGui, iniFile, lastIniModified, snapMode

    try {
        if (snapMode = "None") {
            mainGui.GetPos(&x, &y, &w, &h)
            IniWrite x, iniFile, "Window", "X"
            IniWrite y, iniFile, "Window", "Y"
            lastIniModified := FileGetTime(iniFile, "M")
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

OnExit (*) => SaveWindowPosition()
