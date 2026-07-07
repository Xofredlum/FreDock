;============================================================
; FreDock - Editor Module
;============================================================

OpenButtonEditor(index := 0) {
    global Buttons

    isNew := index = 0
    currentName := isNew ? "" : Buttons[index].Name
    currentText := isNew ? "" : Buttons[index].Text

    editorGui := Gui("+AlwaysOnTop", isNew ? "FreDock - New Button" : "FreDock - Edit Button")
    editorGui.MarginX := 18
    editorGui.MarginY := 15

    EnableDarkTitleBar(editorGui)

    editorGui.BackColor := C("BG")
    editorGui.SetFont("s10 c" C("TEXT"), "Segoe UI")

    editorGui.Add("Text", "w340 Center c" C("TEXT"), isNew ? "New Button" : "Edit Button")
    editorGui.Add("Text", "w340 Center c" C("LINE"), "──────────────────────────────")

    editorGui.Add("Text", "w340 c" C("TEXT_SOFT"), "Button name")

    ; Edit controls use the current GUI font color by default.
    ; Because the editor window is dark, the GUI font is white,
    ; so we temporarily switch to black for readable Windows Edit fields.
    editorGui.SetFont("s10 c000000", "Segoe UI")
    nameEdit := editorGui.Add("Edit", "w340", currentName)

    editorGui.SetFont("s10 c" C("TEXT"), "Segoe UI")
    editorGui.Add("Text", "w340 c" C("TEXT_SOFT") " y+10", "Text to copy")

    editorGui.SetFont("s10 c000000", "Segoe UI")
    textEdit := editorGui.Add("Edit", "w340 h130 Multi WantTab", currentText)

    editorGui.SetFont("s10 c" C("TEXT"), "Segoe UI")

    charCounter := editorGui.Add("Text", "w340 c" C("DIM"), StrLen(currentText) " characters")
    textEdit.OnEvent("Change", (*) => charCounter.Text := StrLen(textEdit.Value) " characters")

    editorGui.Add("Text", "w340 Center c" C("LINE"), "──────────────────────────────")

    if isNew {
        cancelBtn := editorGui.Add("Text", "xm w160 h26 Center Border Background" C("TOOL") " c" C("TEXT_SOFT") " 0x200", "Cancel")
        okBtn := editorGui.Add("Text", "x+20 w160 h26 Center Border Background" C("ACCENT") " cFFFFFF 0x200", "OK")
    } else {
        deleteBtn := editorGui.Add("Text", "xm w100 h26 Center Border Background" C("TOOL") " c" C("TEXT_SOFT") " 0x200", "Delete")
        cancelBtn := editorGui.Add("Text", "x+20 w100 h26 Center Border Background" C("TOOL") " c" C("TEXT_SOFT") " 0x200", "Cancel")
        okBtn := editorGui.Add("Text", "x+20 w100 h26 Center Border Background" C("ACCENT") " cFFFFFF 0x200", "OK")
        deleteBtn.SetFont("s9 c" C("TEXT_SOFT"), "Segoe UI")
        deleteBtn.OnEvent("Click", (*) => DeleteButtonFromEditor(editorGui, index))
    }

    cancelBtn.SetFont("s9 c" C("TEXT_SOFT"), "Segoe UI")
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
