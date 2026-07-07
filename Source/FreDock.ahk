#Requires AutoHotkey v2.0
#SingleInstance Force

;@Ahk2Exe-SetName FreDock
;@Ahk2Exe-SetDescription FreDock - A lightweight visual clipboard launcher
;@Ahk2Exe-SetVersion 1.4.0
;@Ahk2Exe-SetProductName FreDock
;@Ahk2Exe-SetProductVersion 1.4.0
;@Ahk2Exe-SetCompanyName Xofredlum
;@Ahk2Exe-SetCopyright © 2026 Xofredlum
;@Ahk2Exe-SetOrigFilename FreDock.exe

; ==========================================================
; FreDock 1.4.0 RC1 - Polish Edition
; Modular source architecture
;
; by Xofredlum
; Designed with ChatGPT && Xofredlum
;
; AutoHotkey v2
; ==========================================================

; --------------------------
; Modules
; --------------------------
#Include Modules\Version.ahk
#Include Modules\Theme.ahk
#Include Modules\Metrics.ahk
#Include Modules\Common.ahk
#Include Modules\Splash.ahk
#Include Modules\Buttons.ahk
#Include Modules\Clipboard.ahk
#Include Modules\Editor.ahk
#Include Modules\Settings.ahk
#Include Modules\About.ahk

; --------------------------
; Layout
; --------------------------
MAIN_WIDTH := Metrics.MainWidth
BUTTON_HEIGHT := Metrics.ButtonHeight
TOOL_HEIGHT := Metrics.ToolHeight

; --------------------------
; Runtime state
; --------------------------
iniFile := A_ScriptDir "\FreDock.ini"
iconFile := A_ScriptDir "\FreDock.ico"
lastIniModified := ""

soundEnabled := true
alwaysOnTop := true
snapMode := "None"
appearanceMode := "Dark"
opacityPercent := 100
editMode := false
isSavingIni := false

mainGui := ""
statusText := ""
editBtn := ""
addBtn := ""
Buttons := []
ButtonHoverMap := Map()
lastButtonHoverHwnd := 0
hoverHandlerRegistered := false
ToolHoverMap := Map()
lastToolHoverHwnd := 0

; --------------------------
; Start application
; --------------------------
EnsureIniExists()
LoadOptions()
ShowSplash()
lastIniModified := FileGetTime(iniFile, "M")

BuildGui()
ShowMainWindow()

SetTimer WatchIniChanges, 1000
OnExit (*) => SaveWindowPosition()
