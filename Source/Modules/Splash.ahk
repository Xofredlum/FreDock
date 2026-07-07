;============================================================
; FreDock - Splash Module
;============================================================

ShowSplash() {
    global APP_CREDITS, iconFile

    splash := Gui("-Caption +AlwaysOnTop +ToolWindow", "FreDock Splash")
    splash.BackColor := C("BG")
    splash.MarginX := 24
    splash.MarginY := 20

    if FileExist(iconFile)
        splash.Add("Picture", "w96 h96 Center", iconFile)

    splash.SetFont("s21 c" C("TEXT") " Bold", "Segoe UI")
    splash.Add("Text", "w360 Center", "FreDock")

    splash.SetFont("s10 c" C("DIM"), "Segoe UI")
    splash.Add("Text", "w360 Center", "Version " App.Version)

    splash.Add("Text", "w360 Center c" C("LINE"), "──────────────────────────────")

    splash.SetFont("s10 c" C("TEXT_SOFT"), "Segoe UI")
    splash.Add("Text", "w360 Center", "A lightweight visual clipboard launcher")

    splash.SetFont("s9 c" C("ACCENT"), "Segoe UI")
    splash.Add("Text", "w360 Center", "Visual Button Editor")

    splash.Add("Text", "w360 Center c" C("LINE"), "──────────────────────────────")

    splash.SetFont("s9 c" C("ACCENT"), "Segoe UI")
    splash.Add("Text", "w360 Center", "by Xofredlum")

    splash.SetFont("s8 c" C("DIM"), "Segoe UI")
    splash.Add("Text", "w360 Center", APP_CREDITS)

    splash.Show("AutoSize Center")
    WinSetTransparent 235, splash.Hwnd

    Sleep 1100
    splash.Destroy()
}

; ==========================================================
; INI Watcher / Window state / Exit
; ==========================================================
