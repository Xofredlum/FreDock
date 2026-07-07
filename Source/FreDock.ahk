#Requires AutoHotkey v2.0
#SingleInstance Force

;@Ahk2Exe-SetName FreDock
;@Ahk2Exe-SetDescription FreDock - A lightweight clipboard companion
;@Ahk2Exe-SetVersion 1.3.0
;@Ahk2Exe-SetProductName FreDock
;@Ahk2Exe-SetProductVersion 1.3.0
;@Ahk2Exe-SetCompanyName Xofredlum
;@Ahk2Exe-SetCopyright © 2026 Xofredlum
;@Ahk2Exe-SetOrigFilename FreDock.exe

; ==========================================================
; FreDock 1.3.0
; A lightweight clipboard companion
;
; New in 1.3.0:
; - Visual Button Editor
; - Edit Mode ON/OFF
; - Click a button to edit it
; - ➕ Add button to create a new button
; - Delete button with automatic INI renumbering
; - FreDock.ini remains fully editable for advanced users
;
; by Xofredlum
; Designed with ChatGPT && Xofredlum
;
; AutoHotkey v2
; ==========================================================

APP_NAME := "FreDock 1.3.0"
APP_AUTHOR := "by Xofredlum"
APP_CREDITS := "Designed with ChatGPT && Xofredlum"
APP_TAGLINE := "A lightweight clipboard companion"

COLOR_BG := "202020"
COLOR_BUTTON := "303030"
COLOR_BUTTON_EDIT := "244B6A"
COLOR_TOOL := "282828"
COLOR_TOOL_EDIT := "1F5F8B"
COLOR_TEXT := "FFFFFF"
COLOR_DIM := "808080"
COLOR_LINE := "404040"
COLOR_ACCENT := "5DB7FF"
COLOR_STATUS := COLOR_ACCENT
COLOR_WARNING := "FFB84D"
COLOR_DONE := "2E8B57"

MAIN_WIDTH := 230
BUTTON_HEIGHT := 28
TOOL_HEIGHT := 24

iniFile := A_ScriptDir "\FreDock.ini"
iconFile := A_ScriptDir "\FreDock.ico"
lastIniModified := ""

soundEnabled := true
alwaysOnTop := true
snapMode := "None"
editMode := false
isSavingIni := false

mainGui := ""
statusText := ""
editBtn := ""
addBtn := ""
Buttons := []

ShowSplash()
EnsureIniExists()
LoadOptions()
lastIniModified := FileGetTime(iniFile, "M")

BuildGui()
ShowMainWindow()

SetTimer WatchIniChanges, 1000

; ==========================================================
; Startup / INI
; ==========================================================

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
}

LoadOptions() {
    global iniFile, soundEnabled, alwaysOnTop, snapMode

    soundEnabled := IniRead(iniFile, "Options", "Sound", "1") = "1"
    alwaysOnTop := IniRead(iniFile, "Options", "AlwaysOnTop", "1") = "1"
    snapMode := IniRead(iniFile, "Options", "Snap", "None")
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
    global soundEnabled, alwaysOnTop, snapMode, mainGui

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

BuildGui() {
    global mainGui, statusText, editBtn, addBtn, APP_NAME
    global COLOR_BG, COLOR_TEXT, COLOR_LINE, COLOR_TOOL, COLOR_TOOL_EDIT, COLOR_STATUS, COLOR_DONE
    global MAIN_WIDTH, TOOL_HEIGHT, alwaysOnTop, editMode

    try mainGui.Destroy()

    mainGui := Gui(alwaysOnTop ? "+AlwaysOnTop" : "", editMode ? APP_NAME " - EDIT MODE" : APP_NAME)
    mainGui.MarginX := 12
    mainGui.MarginY := 8

    EnableDarkTitleBar(mainGui)

    mainGui.BackColor := COLOR_BG
    mainGui.SetFont("s10 c" COLOR_TEXT, "Segoe UI")
    mainGui.OnEvent("Close", (*) => HideAndSavePosition())

    LoadButtonsFromIni()
    AddButtonsToGui()

    mainGui.Add("Text", "xm w" MAIN_WIDTH " h8 Center c" COLOR_LINE, "──────────────────────")

    editCaption := editMode ? "✔ Done" : "Edit"
    editBg := editMode ? COLOR_DONE : COLOR_TOOL
    editWidth := editMode ? 52 : 46

    editBtn := mainGui.Add("Text", "xm w" editWidth " h" TOOL_HEIGHT " Center Border Background" editBg " cFFFFFF 0x200", editCaption)
    helpBtn := mainGui.Add("Text", "x+3 w36 h" TOOL_HEIGHT " Center Border Background" COLOR_TOOL " cC0C0C0 0x200", "Help")
    settingsBtn := mainGui.Add("Text", "x+3 w58 h" TOOL_HEIGHT " Center Border Background" COLOR_TOOL " cC0C0C0 0x200", "Settings")
    aboutBtn := mainGui.Add("Text", "x+3 w46 h" TOOL_HEIGHT " Center Border Background" COLOR_TOOL " cC0C0C0 0x200", "About")
    exitBtn := mainGui.Add("Text", "x+3 w26 h" TOOL_HEIGHT " Center Border Background" COLOR_TOOL " cC0C0C0 0x200", "X")

    editBtn.SetFont("s9 cFFFFFF", "Segoe UI")
    helpBtn.SetFont("s9 cC0C0C0", "Segoe UI")
    settingsBtn.SetFont("s9 cC0C0C0", "Segoe UI")
    aboutBtn.SetFont("s9 cC0C0C0", "Segoe UI")
    exitBtn.SetFont("s9 cC0C0C0", "Segoe UI")

    editBtn.OnEvent("Click", (*) => ToggleEditMode())
    helpBtn.OnEvent("Click", (*) => ShowHelp())
    settingsBtn.OnEvent("Click", (*) => ShowSettings())
    aboutBtn.OnEvent("Click", (*) => ShowAbout())
    exitBtn.OnEvent("Click", (*) => ExitFreDock())

    if editMode {
        ; Fixed5: an expanded edit panel appears under the toolbar.
        ; It visually reveals the new creation action while keeping the UI compact in normal mode.
        mainGui.Add("Text", "xm w" MAIN_WIDTH " h4", "")
        statusText := mainGui.Add("Text", "xm w146 c" COLOR_STATUS " Center", "✔ EDIT MODE")
        addBtn := mainGui.Add("Text", "x+8 yp-5 w76 h28 Center Border Background" COLOR_TOOL_EDIT " cFFFFFF 0x200", "➕ Add")
        addBtn.SetFont("s9 cFFFFFF Bold", "Segoe UI")
        addBtn.OnEvent("Click", (*) => OpenButtonEditor(0))
    } else {
        statusText := mainGui.Add("Text", "xm w" MAIN_WIDTH " c" COLOR_STATUS " Center", "")
        addBtn := ""
    }
}

AddButtonsToGui() {
    global Buttons

    for index, btn in Buttons
        AddDockButton(index, btn.Name, btn.Text)
}

AddDockButton(index, name, text) {
    global mainGui, MAIN_WIDTH, BUTTON_HEIGHT, COLOR_BUTTON, COLOR_BUTTON_EDIT, editMode, Buttons

    bg := editMode ? COLOR_BUTTON_EDIT : COLOR_BUTTON
    caption := editMode ? "✎ " name : name

    btnCtrl := mainGui.Add("Text"
        , "xm w" MAIN_WIDTH " h" BUTTON_HEIGHT " Center Border Background" bg " cFFFFFF 0x200"
        , caption)

    btnCtrl.SetFont("s10 cFFFFFF", "Segoe UI")
    btnCtrl.OnEvent("Click", ButtonClick.Bind(index))

    Buttons[index].Control := btnCtrl
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

CopyButton(index) {
    global Buttons, soundEnabled

    if (index < 1 || index > Buttons.Length)
        return

    text := Buttons[index].Text

    if text = "" {
        if soundEnabled
            SoundBeep 300, 40

        SetStatus("⚠ Empty button")
        return
    }

    A_Clipboard := text
    ClipWait 1

    if soundEnabled
        SoundBeep 500, 20

    SetStatus("✔ Copied to clipboard")
}

SetStatus(message, duration := 1200) {
    global statusText

    ; The GUI can be rebuilt while a previous status timer is still pending.
    ; Use a safe restore function instead of a lambda touching an old control.
    try {
        statusText.Text := message
        if (duration > 0)
            SetTimer RestoreStatus, -duration
    }
}

RestoreStatus(*) {
    global statusText, editMode

    try statusText.Text := (editMode ? "✔ EDIT MODE" : "")
}

; ==========================================================
; Visual Button Editor
; ==========================================================

OpenButtonEditor(index := 0) {
    global Buttons, COLOR_BG, COLOR_ACCENT

    isNew := index = 0
    currentName := isNew ? "" : Buttons[index].Name
    currentText := isNew ? "" : Buttons[index].Text

    editorGui := Gui("+AlwaysOnTop", isNew ? "FreDock - New Button" : "FreDock - Edit Button")
    editorGui.MarginX := 16
    editorGui.MarginY := 14

    EnableDarkTitleBar(editorGui)

    editorGui.BackColor := COLOR_BG
    editorGui.SetFont("s10 cFFFFFF", "Segoe UI")

    editorGui.Add("Text", "w340 Center cFFFFFF", isNew ? "New Button" : "Edit Button")
    editorGui.Add("Text", "w340 Center c404040", "──────────────────────────────")

    editorGui.Add("Text", "w340 cCFCFCF", "Button name")

    ; Edit controls use the current GUI font color by default.
    ; Because the editor window is dark, the GUI font is white,
    ; so we temporarily switch to black for readable Windows Edit fields.
    editorGui.SetFont("s10 c000000", "Segoe UI")
    nameEdit := editorGui.Add("Edit", "w340", currentName)

    editorGui.SetFont("s10 cFFFFFF", "Segoe UI")
    editorGui.Add("Text", "w340 cCFCFCF y+10", "Text to copy")

    editorGui.SetFont("s10 c000000", "Segoe UI")
    textEdit := editorGui.Add("Edit", "w340 h130 Multi WantTab", currentText)

    editorGui.SetFont("s10 cFFFFFF", "Segoe UI")

    charCounter := editorGui.Add("Text", "w340 c808080", StrLen(currentText) " characters")
    textEdit.OnEvent("Change", (*) => charCounter.Text := StrLen(textEdit.Value) " characters")

    editorGui.Add("Text", "w340 Center c404040", "──────────────────────────────")

    if isNew {
        cancelBtn := editorGui.Add("Text", "xm w160 h26 Center Border Background282828 cC0C0C0 0x200", "Cancel")
        okBtn := editorGui.Add("Text", "x+20 w160 h26 Center Border Background" COLOR_ACCENT " cFFFFFF 0x200", "OK")
    } else {
        deleteBtn := editorGui.Add("Text", "xm w100 h26 Center Border Background282828 cC0C0C0 0x200", "Delete")
        cancelBtn := editorGui.Add("Text", "x+20 w100 h26 Center Border Background282828 cC0C0C0 0x200", "Cancel")
        okBtn := editorGui.Add("Text", "x+20 w100 h26 Center Border Background" COLOR_ACCENT " cFFFFFF 0x200", "OK")
        deleteBtn.SetFont("s9 cC0C0C0", "Segoe UI")
        deleteBtn.OnEvent("Click", (*) => DeleteButtonFromEditor(editorGui, index))
    }

    cancelBtn.SetFont("s9 cC0C0C0", "Segoe UI")
    okBtn.SetFont("s9 cFFFFFF", "Segoe UI")

    cancelBtn.OnEvent("Click", (*) => editorGui.Destroy())
    okBtn.OnEvent("Click", (*) => SaveButtonFromEditor(editorGui, index, nameEdit.Value, textEdit.Value))

    editorGui.Show("AutoSize")

    ; Fixed5: focus the button name and select its content immediately.
    ; The user can start typing without an extra click.
    try {
        nameEdit.Focus()
        DllCall("User32\SendMessage", "Ptr", nameEdit.Hwnd, "UInt", 0xB1, "Ptr", 0, "Ptr", -1)
    }
}

SaveButtonFromEditor(editorGui, index, name, text) {
    global Buttons

    name := Trim(name)

    if (name = "") {
        MsgBox "Button name cannot be empty.", "FreDock", "Icon! Owner" editorGui.Hwnd
        return
    }

    if (index = 0) {
        Buttons.Push({ Index: Buttons.Length + 1, Name: name, Text: text, Control: "" })
    } else {
        Buttons[index].Name := name
        Buttons[index].Text := text
    }

    SaveAllButtonsToIni()
    editorGui.Destroy()
    RebuildGuiKeepPosition(index = 0 ? "Button added" : "Button saved")
}

DeleteButtonFromEditor(editorGui, index) {
    global Buttons

    if (index < 1 || index > Buttons.Length)
        return

    buttonName := Buttons[index].Name
    result := MsgBox("Delete button `"" buttonName "`"?`n`nThis action cannot be undone.", "FreDock", "YesNo Icon? Owner" editorGui.Hwnd)

    if (result != "Yes")
        return

    Buttons.RemoveAt(index)
    SaveAllButtonsToIni()
    editorGui.Destroy()
    RebuildGuiKeepPosition("Button deleted")
}

; ==========================================================
; Advanced INI editor
; ==========================================================

EditIni() {
    global iniFile, soundEnabled

    Run 'notepad.exe "' iniFile '"'
    SetStatus("✎ Config opened")

    if soundEnabled
        SoundBeep 700, 25
}

; ==========================================================
; Settings
; ==========================================================

ShowSettings() {
    global soundEnabled, alwaysOnTop, snapMode
    global COLOR_BG, iniFile, lastIniModified, mainGui

    settingsGui := Gui("+AlwaysOnTop", "FreDock Settings")
    settingsGui.MarginX := 16
    settingsGui.MarginY := 14

    EnableDarkTitleBar(settingsGui)

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
    global iniFile, lastIniModified, mainGui, isSavingIni

    soundEnabled := newSound = 1
    alwaysOnTop := newTop = 1
    snapMode := newSnap

    Critical "On"
    isSavingIni := true
    try {
        IniWrite soundEnabled ? "1" : "0", iniFile, "Options", "Sound"
        IniWrite alwaysOnTop ? "1" : "0", iniFile, "Options", "AlwaysOnTop"
        IniWrite snapMode, iniFile, "Options", "Snap"
        lastIniModified := FileGetTime(iniFile, "M")
    } finally {
        isSavingIni := false
        Critical "Off"
    }

    mainGui.Opt(alwaysOnTop ? "+AlwaysOnTop" : "-AlwaysOnTop")

    if (snapMode != "None")
        ApplySnap()

    SetStatus("Settings saved")

    if soundEnabled
        SoundBeep 700, 25

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

; ==========================================================
; Help / About / Splash
; ==========================================================

ShowHelp() {
    global COLOR_BG

    helpGui := Gui("+AlwaysOnTop", "FreDock Help")
    helpGui.MarginX := 14
    helpGui.MarginY := 12

    EnableDarkTitleBar(helpGui)

    helpGui.BackColor := COLOR_BG
    helpGui.SetFont("s10 cFFFFFF", "Segoe UI")

    helpGui.Add("Text", "w380 Center cFFFFFF", "FreDock Help")
    helpGui.Add("Text", "w380 Center c404040", "──────────────────────────────")
    helpGui.Add("Text", "w380 cCFCFCF", "• Normal mode: click a button to copy its text.")
    helpGui.Add("Text", "w380 cCFCFCF", "• Paste with Ctrl+V.")
    helpGui.Add("Text", "w380 cCFCFCF", "• Edit mode: click Edit, then click a button to modify it.")
    helpGui.Add("Text", "w380 cCFCFCF", "• Use ➕ Add in Edit mode to create a new button.")
    helpGui.Add("Text", "w380 cCFCFCF", "• Delete removes a button and renumbers the INI sections.")
    helpGui.Add("Text", "w380 cCFCFCF", "• FreDock.ini is still available for advanced users.")
    helpGui.Add("Text", "w380 cCFCFCF", "• External INI changes reload automatically.")
    helpGui.Add("Text", "w380 Center c404040", "──────────────────────────────")

    editIniBtn := helpGui.Add("Text", "w185 h26 Center Border Background282828 cC0C0C0 0x200", "Open INI")
    okBtn := helpGui.Add("Text", "x+10 w185 h26 Center Border Background282828 cC0C0C0 0x200", "OK")

    editIniBtn.SetFont("s9 cC0C0C0", "Segoe UI")
    okBtn.SetFont("s9 cC0C0C0", "Segoe UI")

    editIniBtn.OnEvent("Click", (*) => EditIni())
    okBtn.OnEvent("Click", (*) => helpGui.Destroy())

    helpGui.Show("AutoSize")
}

ShowAbout() {
    global APP_AUTHOR, APP_CREDITS, APP_TAGLINE, COLOR_ACCENT, COLOR_BG

    aboutGui := Gui("+AlwaysOnTop", "About FreDock")
    aboutGui.MarginX := 14
    aboutGui.MarginY := 12

    EnableDarkTitleBar(aboutGui)

    aboutGui.BackColor := COLOR_BG
    aboutGui.SetFont("s10 cFFFFFF", "Segoe UI")

    aboutGui.Add("Text", "w330 Center cFFFFFF", "FreDock")
    aboutGui.Add("Text", "w330 Center c808080", "Version 1.3.0")
    aboutGui.Add("Text", "w330 Center c404040", "──────────────────────────────")
    aboutGui.Add("Text", "w330 Center cCFCFCF", APP_TAGLINE)
    aboutGui.Add("Text", "w330 Center c" COLOR_ACCENT, "Visual Button Editor")
    aboutGui.Add("Text", "w330 Center c404040", "──────────────────────────────")
    aboutGui.Add("Text", "w330 Center c" COLOR_ACCENT, APP_AUTHOR)
    aboutGui.Add("Text", "w330 Center c808080", APP_CREDITS)
    aboutGui.Add("Text", "w330 Center c808080", "Powered by AutoHotkey v2")
    aboutGui.Add("Text", "w330 Center c404040", "──────────────────────────────")

    okBtn := aboutGui.Add("Text", "w330 h26 Center Border Background282828 cC0C0C0 0x200", "OK")
    okBtn.SetFont("s9 cC0C0C0", "Segoe UI")
    okBtn.OnEvent("Click", (*) => aboutGui.Destroy())

    aboutGui.Show("AutoSize")
}

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
    splash.Add("Text", "w360 Center", "Version 1.3.0")

    splash.Add("Text", "w360 Center c404040", "──────────────────────────────")

    splash.SetFont("s10 cCFCFCF", "Segoe UI")
    splash.Add("Text", "w360 Center", "A lightweight clipboard companion")

    splash.SetFont("s9 c" COLOR_ACCENT, "Segoe UI")
    splash.Add("Text", "w360 Center", "Visual Button Editor")

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

; ==========================================================
; INI Watcher / Window state / Exit
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
    try {
        DllCall("Dwmapi\DwmSetWindowAttribute"
            , "Ptr", guiObj.Hwnd
            , "Int", 20
            , "Int*", 1
            , "Int", 4)
    }
}

OnExit (*) => SaveWindowPosition()
