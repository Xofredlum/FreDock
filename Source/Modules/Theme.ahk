;============================================================
; FreDock - Theme Module
;============================================================
;
; Purpose:
; Centralizes all colors used by the interface.
; Beta 1 adds the complete Appearance mode:
; Dark / Light / System.
;
;============================================================

class Theme
{
    static Mode := "Dark"
    static Current := "Dark"

    static Dark := Map(
        "BG",              "202020",
        "BG_EDIT",         "252A2E",
        "BUTTON",          "2F2F2F",
        "BUTTON_HOVER",    "3A3A3A",
        "BUTTON_FEEDBACK", "2E8B57",
        "BUTTON_EDIT",     "244B6A",
        "BUTTON_EDIT_HOVER", "2C5D82",
        "TOOL",            "282828",
        "TOOL_HOVER",      "363636",
        "TOOL_PRESSED",    "202020",
        "TOOL_EDIT",       "1F5F8B",
        "TOOL_EDIT_HOVER", "2870A5",
        "TOOL_DONE_HOVER", "35A86A",
        "TOOL_EXIT_HOVER", "5A2B2B",
        "TEXT",            "FFFFFF",
        "TEXT_SOFT",       "E6E6E6",
        "DIM",             "8A8A8A",
        "LINE",            "3D3D3D",
        "ACCENT",          "5DB7FF",
        "STATUS",          "5DB7FF",
        "WARNING",         "FFB84D",
        "DONE",            "2E8B57",
        "INPUT_BG",        "FFFFFF",
        "INPUT_TEXT",      "000000"
    )

    static Light := Map(
        "BG",              "F6F7F9",
        "BG_EDIT",         "EAF4FF",
        "BUTTON",          "FFFFFF",
        "BUTTON_HOVER",    "EEF4FB",
        "BUTTON_FEEDBACK", "198754",
        "BUTTON_EDIT",     "D7ECFF",
        "BUTTON_EDIT_HOVER", "C5E3FF",
        "TOOL",            "ECEFF3",
        "TOOL_HOVER",      "DEE6EF",
        "TOOL_PRESSED",    "CFD8E3",
        "TOOL_EDIT",       "0078D4",
        "TOOL_EDIT_HOVER", "0B86E8",
        "TOOL_DONE_HOVER", "20A866",
        "TOOL_EXIT_HOVER", "FFE3E3",
        "TEXT",            "202020",
        "TEXT_SOFT",       "303030",
        "DIM",             "666666",
        "LINE",            "D0D7DE",
        "ACCENT",          "0078D4",
        "STATUS",          "0078D4",
        "WARNING",         "B26A00",
        "DONE",            "198754",
        "INPUT_BG",        "FFFFFF",
        "INPUT_TEXT",      "000000"
    )

    static Set(themeName)
    {
        if (themeName = "Light") {
            Theme.Mode := "Light"
            Theme.Current := "Light"
        } else if (themeName = "System") {
            Theme.Mode := "System"
            Theme.Current := Theme.GetSystemTheme()
        } else {
            Theme.Mode := "Dark"
            Theme.Current := "Dark"
        }

        Theme.UpdateLegacyGlobals()
    }

    static GetSystemTheme()
    {
        try {
            value := RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme", 0)
        } catch {
            return "Dark"
        }

        return (value = 1) ? "Light" : "Dark"
    }

    static IsDark()
    {
        return Theme.Current = "Dark"
    }

    static Get(colorName)
    {
        if (Theme.Mode = "System")
            Theme.Current := Theme.GetSystemTheme()

        colors := (Theme.Current = "Light") ? Theme.Light : Theme.Dark
        return colors.Has(colorName) ? colors[colorName] : "FF00FF"
    }

    static UpdateLegacyGlobals()
    {
        global COLOR_BG, COLOR_BUTTON, COLOR_BUTTON_EDIT, COLOR_BUTTON_FEEDBACK
        global COLOR_TOOL, COLOR_TOOL_EDIT, COLOR_TEXT, COLOR_DIM, COLOR_LINE
        global COLOR_ACCENT, COLOR_STATUS, COLOR_WARNING, COLOR_DONE

        COLOR_BG := Theme.Get("BG")
        COLOR_BUTTON := Theme.Get("BUTTON")
        COLOR_BUTTON_EDIT := Theme.Get("BUTTON_EDIT")
        COLOR_BUTTON_FEEDBACK := Theme.Get("BUTTON_FEEDBACK")
        COLOR_TOOL := Theme.Get("TOOL")
        COLOR_TOOL_EDIT := Theme.Get("TOOL_EDIT")
        COLOR_TEXT := Theme.Get("TEXT")
        COLOR_DIM := Theme.Get("DIM")
        COLOR_LINE := Theme.Get("LINE")
        COLOR_ACCENT := Theme.Get("ACCENT")
        COLOR_STATUS := Theme.Get("STATUS")
        COLOR_WARNING := Theme.Get("WARNING")
        COLOR_DONE := Theme.Get("DONE")
    }
}

; Short color helper.
C(name) {
    return Theme.Get(name)
}

; Legacy color globals kept for compatibility during the 1.4 modular refactor.
Theme.UpdateLegacyGlobals()
