#Requires AutoHotkey v2.0
Persistent
DetectHiddenWindows True

; ==============================================================================
; Media Control Script - Pure AHK with WinRT API (Optimized Version)
; ==============================================================================
; This script provides global hotkeys to control media playback for Spotify
; and Pocket Casts using Windows' Global System Media Transport Controls (SMTC).
;
; Features:
; - Toggle between Spotify and Pocket Casts control modes
; - Play/Pause, Skip Next/Previous, Fast Forward/Rewind
; - Fire-and-forget async calls for responsive consecutive key presses
; - Tray icon changes to reflect current mode
;
; Hotkeys:
;   Ctrl+Win+S - Toggle between Spotify and Pocket Casts mode
;   Ctrl+Win+P - Play/Pause
;   Ctrl+Win+J - Skip to next track
;   Ctrl+Win+K - Skip to previous track
;   Ctrl+Win+L - Fast forward (Spotify) / Skip next (Pocket Casts)
;   Ctrl+Win+H - Rewind (Spotify) / Skip previous (Pocket Casts)
;   Ctrl+Win+I - List all active media sessions (debug)
; ==============================================================================

; ==============================================================================
; 1. CONFIGURATION
; ==============================================================================
; Define supported applications with their properties:
; - Path: Full path to executable (discovered at runtime)
; - Exe: Process name for window detection
; - SMTCName: Identifier used in SMTC session matching (case-insensitive)
; - FallbackIcon: Shell32.dll icon index when app icon unavailable

Apps := Map()
Apps["Spotify"]     := {Path: "", Exe: "Spotify.exe", SMTCName: "spotify", FallbackIcon: 297}
Apps["PocketCasts"] := {Path: "", Exe: "Pocket Casts.exe", SMTCName: "pocketcasts", FallbackIcon: 273}

; ==============================================================================
; 2. PATH DISCOVERY
; ==============================================================================
; Locate application executables on the system.
; These paths are used for tray icon display.

; Spotify: Standard installation path in AppData\Roaming
SpotifyPath := A_AppData "\Spotify\Spotify.exe"
if FileExist(SpotifyPath)
    Apps["Spotify"].Path := SpotifyPath

; Pocket Casts: Installed in LocalAppData, search recursively
; as the exact path may vary by version
LocalBaseDir := EnvGet("LOCALAPPDATA") "\pocket_casts_desktop"
if DirExist(LocalBaseDir) {
    Loop Files, LocalBaseDir "\Pocket Casts.exe", "R" {
        Apps["PocketCasts"].Path := A_LoopFileFullPath
        break
    }
}

; ==============================================================================
; 3. WINRT INITIALIZATION
; ==============================================================================
; Initialize Windows Runtime to access the GlobalSystemMediaTransportControlsSessionManager.
; This manager provides access to all active media sessions on the system.

Global SessionManager := 0

InitWinRT() {
    Global SessionManager
    
    ; Create HSTRING for the WinRT class name
    className := "Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager"
    DllCall("combase.dll\WindowsCreateString", "wstr", className, "uint", StrLen(className), "ptr*", &hClassName := 0)
    
    ; IID for IGlobalSystemMediaTransportControlsSessionManagerStatics
    ; This interface provides the RequestAsync method to get the session manager
    IID := Buffer(16)
    DllCall("ole32.dll\CLSIDFromString", "wstr", "{2050c4ee-11a0-57de-aed7-c97c70338245}", "ptr", IID)
    
    ; Get the activation factory for the session manager class
    hr := DllCall("combase.dll\RoGetActivationFactory", "ptr", hClassName, "ptr", IID, "ptr*", &factory := 0, "uint")
    DllCall("combase.dll\WindowsDeleteString", "ptr", hClassName)
    
    if (hr != 0 || !factory) {
        MsgBox("Failed to get activation factory. HRESULT: " Format("0x{:08X}", hr))
        return false
    }
    
    ; Call RequestAsync to get the session manager (vtable index 6)
    hr := ComCall(6, factory, "ptr*", &asyncOp := 0)
    ObjRelease(factory)
    
    if (hr != 0 || !asyncOp) {
        MsgBox("RequestAsync failed. HRESULT: " Format("0x{:08X}", hr))
        return false
    }
    
    ; Poll for async operation completion (max ~1 second)
    ; Status values: 0=Started, 1=Completed, 2=Error, 3=Canceled
    loop 100 {
        try {
            ComCall(7, asyncOp, "uint*", &status := 0)  ; IAsyncInfo.get_Status
            if (status = 1)  ; Completed
                break
            if (status > 1) {  ; Error or Canceled
                MsgBox("Async operation failed with status: " status)
                ObjRelease(asyncOp)
                return false
            }
        }
        Sleep(10)
    }
    
    ; Retrieve the session manager from the completed async operation
    try {
        ComCall(8, asyncOp, "ptr*", &result := 0)  ; IAsyncOperation.GetResults
    }
    ObjRelease(asyncOp)
    
    if !result {
        MsgBox("Failed to get SessionManager from async operation")
        return false
    }
    
    SessionManager := result
    return true
}

; ==============================================================================
; 4. STATE MANAGEMENT
; ==============================================================================
; Track which application is currently being controlled

Global CurrentMode := "Spotify"

; Initialize WinRT on script startup
if !InitWinRT() {
    MsgBox("WinRT initialization failed. Script will exit.")
    ExitApp
}

; Set initial tray icon and show feedback
UpdateSystemState()

; ==============================================================================
; 5. HOTKEYS
; ==============================================================================
; Define global hotkeys for media control
; Using Ctrl+Win modifier to avoid conflicts with common shortcuts

^#s::ToggleAppMode()           ; Switch between Spotify and Pocket Casts
^#p::ExecuteMediaAction("PlayPause")
^#l::ExecuteMediaAction("FastForward")
^#h::ExecuteMediaAction("Rewind")
^#j::ExecuteMediaAction("SkipNext")
^#k::ExecuteMediaAction("SkipPrevious")
^#i::ListSessions()            ; Debug: show all media sessions

; ==============================================================================
; 6. CORE LOGIC
; ==============================================================================

; Toggle between Spotify and Pocket Casts control modes
ToggleAppMode() {
    Global CurrentMode
    CurrentMode := (CurrentMode = "Spotify") ? "PocketCasts" : "Spotify"
    UpdateSystemState()
}

; Update tray icon and show feedback when mode changes
UpdateSystemState() {
    Global CurrentMode, Apps
    
    TargetApp := Apps[CurrentMode]
    
    ; Use app's own icon if available, otherwise fall back to shell32.dll
    IconToSet := (TargetApp.Path != "" && FileExist(TargetApp.Path)) ? TargetApp.Path : "shell32.dll"

    try {
        if (IconToSet = "shell32.dll")
            TraySetIcon(IconToSet, TargetApp.FallbackIcon)
        else
            TraySetIcon(IconToSet)
    } catch {
        TraySetIcon("shell32.dll", 1)  ; Default icon on failure
    }
}

; Execute a media control action on the currently selected app
; Actions: PlayPause, FastForward, Rewind, SkipNext, SkipPrevious
ExecuteMediaAction(Action) {
    Global CurrentMode, Apps, SessionManager
    
    if !SessionManager {
        ShowFeedback("SessionManager not initialized")
        return
    }
    
    ; Remap actions for Pocket Casts which doesn't support FastForward/Rewind
    ; Also disable SkipNext/SkipPrevious to avoid accidental episode changes
    if (CurrentMode = "PocketCasts") {
        if (Action = "FastForward")
            Action := "SkipNext"
        else if (Action = "Rewind")
            Action := "SkipPrevious"
        else if (Action = "SkipNext")
            return  ; Disabled for Pocket Casts
        else if (Action = "SkipPrevious")
            return  ; Disabled for Pocket Casts
    }
    
    TargetApp := Apps[CurrentMode]
    
    ; Verify the target application is running
    if !WinExist("ahk_exe " TargetApp.Exe) {
        ShowFeedback(CurrentMode " is NOT running")
        return
    }
    
    ; Get list of active media sessions from SessionManager
    ; IGlobalSystemMediaTransportControlsSessionManager.GetSessions (vtable index 7)
    try {
        ComCall(7, SessionManager, "ptr*", &sessionList := 0)
    } catch as e {
        ShowFeedback("GetSessions failed: " e.Message)
        return
    }
    
    if !sessionList {
        ShowFeedback("No session list returned")
        return
    }
    
    ; Get the number of sessions
    ; IVectorView.get_Size (vtable index 7)
    try {
        ComCall(7, sessionList, "uint*", &count := 0)
    } catch as e {
        ObjRelease(sessionList)
        ShowFeedback("get_Size failed: " e.Message)
        return
    }
    
    if (count = 0) {
        ShowFeedback("No media sessions found")
        ObjRelease(sessionList)
        return
    }
    
    ; Search for a session matching our target application
    targetSession := 0
    Loop count {
        ; IVectorView.GetAt (vtable index 6)
        try {
            ComCall(6, sessionList, "uint", A_Index - 1, "ptr*", &session := 0)
        } catch {
            continue
        }
        
        if !session
            continue
        
        ; Get the source app's user model ID
        ; IGlobalSystemMediaTransportControlsSession.get_SourceAppUserModelId (vtable index 6)
        try {
            ComCall(6, session, "ptr*", &hString := 0)
            appId := HStringToString(hString)
            DeleteHString(hString)
        } catch {
            ObjRelease(session)
            continue
        }
        
        ; Check if this session belongs to our target app (case-insensitive match)
        if InStr(StrLower(appId), TargetApp.SMTCName) {
            targetSession := session
            break
        }
        ObjRelease(session)
    }
    ObjRelease(sessionList)
    
    if !targetSession {
        ShowFeedback("No session for " CurrentMode)
        return
    }
    
    ; Execute the media control action
    ; Fire-and-forget: we don't wait for the async operation to complete
    ; This allows rapid consecutive key presses without blocking
    ;
    ; IGlobalSystemMediaTransportControlsSession method vtable indices:
    ; Reference: https://github.com/Descolada/AHK-v2-libraries/blob/main/Lib/Media.ahk
    ;   14 = TryFastForwardAsync
    ;   15 = TryRewindAsync
    ;   16 = TrySkipNextAsync
    ;   17 = TrySkipPreviousAsync
    ;   20 = TryTogglePlayPauseAsync
    try {
        switch Action {
            case "PlayPause":
                ComCall(20, targetSession, "ptr*", &asyncOp := 0)
            case "FastForward":
                ComCall(14, targetSession, "ptr*", &asyncOp := 0)
            case "Rewind":
                ComCall(15, targetSession, "ptr*", &asyncOp := 0)
            case "SkipNext":
                ComCall(16, targetSession, "ptr*", &asyncOp := 0)
            case "SkipPrevious":
                ComCall(17, targetSession, "ptr*", &asyncOp := 0)
        }
        ; Release async operation immediately without waiting for result
        ; This is the key optimization for responsive consecutive presses
        if asyncOp
            ObjRelease(asyncOp)
    } catch as e {
        ShowFeedback("Action failed: " e.Message)
    }
    
    ObjRelease(targetSession)
}

; Debug function: List all active media sessions
ListSessions() {
    Global SessionManager
    
    if !SessionManager {
        MsgBox("SessionManager not initialized")
        return
    }
    
    try {
        ComCall(7, SessionManager, "ptr*", &sessionList := 0)
        ComCall(7, sessionList, "uint*", &count := 0)
    } catch as e {
        MsgBox("Error: " e.Message)
        return
    }
    
    list := "Media Sessions (" count "):`n`n"
    
    Loop count {
        try {
            ComCall(6, sessionList, "uint", A_Index - 1, "ptr*", &session := 0)
            ComCall(6, session, "ptr*", &hString := 0)
            appId := HStringToString(hString)
            DeleteHString(hString)
            list .= A_Index ". " appId "`n"
            ObjRelease(session)
        }
    }
    
    ObjRelease(sessionList)
    MsgBox(list, "Media Sessions")
}

; ==============================================================================
; 7. WINRT HELPER FUNCTIONS
; ==============================================================================

; Convert an HSTRING (WinRT string handle) to an AHK string
HStringToString(hString) {
    if !hString
        return ""
    len := 0
    pStr := DllCall("combase.dll\WindowsGetStringRawBuffer", "ptr", hString, "uint*", &len, "ptr")
    if !pStr
        return ""
    return StrGet(pStr, len, "UTF-16")
}

; Release an HSTRING handle
DeleteHString(hString) {
    if hString
        DllCall("combase.dll\WindowsDeleteString", "ptr", hString)
}

; Convert string to lowercase (wrapper for Format)
StrLower(str) {
    return Format("{:L}", str)
}

; ==============================================================================
; 8. UI HELPERS
; ==============================================================================

; Show a tooltip that auto-dismisses after 2 seconds
ShowFeedback(Text) {
    ToolTip(Text)
    SetTimer () => ToolTip(), -2000
}
