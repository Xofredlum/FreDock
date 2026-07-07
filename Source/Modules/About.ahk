;============================================================
; FreDock - About Module
;============================================================

ShowHelp() {
    helpGui := Gui("+AlwaysOnTop", "FreDock Help")
    helpGui.MarginX := 14
    helpGui.MarginY := 12

    EnableDarkTitleBar(helpGui)

    helpGui.BackColor := C("BG")
    helpGui.SetFont("s10 c" C("TEXT"), "Segoe UI")

    helpGui.Add("Text", "w380 Center c" C("TEXT"), "FreDock Help")
    helpGui.Add("Text", "w380 Center c" C("LINE"), "──────────────────────────────")
    helpGui.Add("Text", "w380 c" C("TEXT_SOFT"), "• Normal mode: click a button to copy its text.")
    helpGui.Add("Text", "w380 c" C("TEXT_SOFT"), "• Paste with Ctrl+V.")
    helpGui.Add("Text", "w380 c" C("TEXT_SOFT"), "• Edit mode: click Edit, then click a button to modify it.")
    helpGui.Add("Text", "w380 c" C("TEXT_SOFT"), "• Use ➕ Add in Edit mode to create a new button.")
    helpGui.Add("Text", "w380 c" C("TEXT_SOFT"), "• Delete removes a button and renumbers the INI sections.")
    helpGui.Add("Text", "w380 c" C("TEXT_SOFT"), "• FreDock.ini is still available for advanced users.")
    helpGui.Add("Text", "w380 c" C("TEXT_SOFT"), "• External INI changes reload automatically.")
    helpGui.Add("Text", "w380 Center c" C("LINE"), "──────────────────────────────")

    editIniBtn := helpGui.Add("Text", "w185 h26 Center Border Background" C("TOOL") " c" C("TEXT_SOFT") " 0x200", "Open INI")
    okBtn := helpGui.Add("Text", "x+10 w185 h26 Center Border Background" C("TOOL") " c" C("TEXT_SOFT") " 0x200", "OK")

    editIniBtn.SetFont("s9 c" C("TEXT_SOFT"), "Segoe UI")
    okBtn.SetFont("s9 c" C("TEXT_SOFT"), "Segoe UI")

    editIniBtn.OnEvent("Click", (*) => EditIni())
    okBtn.OnEvent("Click", (*) => helpGui.Destroy())

    helpGui.Show("AutoSize")
}

ShowAbout() {
    global APP_AUTHOR, APP_CREDITS, APP_TAGLINE

    aboutGui := Gui("+AlwaysOnTop", "About FreDock")
    aboutGui.MarginX := 14
    aboutGui.MarginY := 12

    EnableDarkTitleBar(aboutGui)

    aboutGui.BackColor := C("BG")
    aboutGui.SetFont("s10 c" C("TEXT"), "Segoe UI")

    aboutGui.Add("Text", "w330 Center c" C("TEXT"), "FreDock")
    aboutGui.Add("Text", "w330 Center c" C("DIM"), "Version " App.Version)
    aboutGui.Add("Text", "w330 Center c" C("LINE"), "──────────────────────────────")
    aboutGui.Add("Text", "w330 Center c" C("TEXT_SOFT"), APP_TAGLINE)
    aboutGui.Add("Text", "w330 Center c" C("ACCENT"), "Visual Button Editor")
    aboutGui.Add("Text", "w330 Center c" C("LINE"), "──────────────────────────────")
    aboutGui.Add("Text", "w330 Center c" C("ACCENT"), APP_AUTHOR)
    aboutGui.Add("Text", "w330 Center c" C("DIM"), APP_CREDITS)
    aboutGui.Add("Text", "w330 Center c" C("DIM"), "Powered by AutoHotkey v2")
    aboutGui.Add("Text", "w330 Center c" C("LINE"), "──────────────────────────────")

    okBtn := aboutGui.Add("Text", "w330 h26 Center Border Background" C("TOOL") " c" C("TEXT_SOFT") " 0x200", "OK")
    okBtn.SetFont("s9 c" C("TEXT_SOFT"), "Segoe UI")
    okBtn.OnEvent("Click", (*) => aboutGui.Destroy())

    aboutGui.Show("AutoSize")
}
