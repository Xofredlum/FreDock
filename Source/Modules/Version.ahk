;============================================================
; FreDock - Version Module
;============================================================

class App
{
    static Name    := "FreDock"
    static Version := "1.4.0 RC1"
    static Edition := "Polish Edition"
    static Author  := "by Xofredlum"
    static Credits := "Designed with ChatGPT && Xofredlum"
    static Tagline := "A lightweight visual clipboard launcher"

    static FullName()
    {
        return App.Name " " App.Version
    }

    static Title()
    {
        return App.Name " " App.Version " - " App.Edition
    }

    static WindowTitle(editMode := false)
    {
        return App.Name
    }
}

; Legacy globals kept for compatibility during the 1.4 modular refactor.
APP_NAME := App.FullName()
APP_AUTHOR := App.Author
APP_CREDITS := App.Credits
APP_TAGLINE := App.Tagline
