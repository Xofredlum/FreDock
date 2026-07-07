;============================================================
; FreDock - Clipboard Module
;============================================================

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

    ; Alpha 2: instant visual feedback on the clicked button.
    FlashButtonCopied(index)
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
