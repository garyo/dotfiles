; AutoHotKeys script ===========
; by Gary Oberbrunner

#SingleInstance force
SetkeyDelay, 0

;;; Make this script autostart with Windows next boot.
;;; Just run this script once to enable.
SplitPath, A_Scriptname, , , , OutNameNoExt
LinkFile=%A_StartupCommon%\%OutNameNoExt%.lnk
IfNotExist, %LinkFile%
  FileCreateShortcut, %A_ScriptFullPath%, %LinkFile%
SetWorkingDir, %A_ScriptDir%

; end of auto-execute section; hotkeys go below.
return

; -----------------------------

; Win+\ - turn off monitor.  Doesn't work always.
#\ UP::
    SendMessage 0x112, 0xF140, 0, , Program Manager  ; Start screensaver
    SendMessage 0x112, 0xF170, 2, , Program Manager  ; Monitor off
    Return

; Shift-F5: Insert current date in GenArts format
+F5::
    FormatTime date,, d{-}MMM{-}yy
    Send %date%
    return

; Ctrl-F5: Insert current date in yy-mm-dd format
^F5::
    FormatTime date,, yyyy{-}MM{-}dd
    Send %date%
    return

; Run or active DbgView on Ctrl-Alt-Shift-D
^!+d::
IfWinExist DebugView
{
  WinActivate DebugView
}
else
{
  Run %PROGRAMFILES%\DbgView\DbgView.exe
}
return

; Run or active Emacs on Ctrl-Alt-Shift-E
^!+e::
IfWinExist emacs
{
  WinActivate emacs
}
else
{
  Run c:\emacs\emacs-21.3\bin\emacs
}
return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Auto-expand shortcuts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;::ob::oberbrunner
:o:\pf32::c:\Program Files (x86)\
:o:\pf::c:\Program Files\
:o:/pf32::"c:/Program Files (x86)"/
:o:/pf::"/Program Files"/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Currency
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; (* means no end key needed, ? means triggers inside word)
:*?:$eur::€
:*?:$ukp::£
:*?:$yen::¥

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Type accented letters OSX-style (http://www.autohotkey.com/board/topic/27801-special-characters-osx-style/)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Alt+': acute
; Alt+`: grave
; Alt+^: circumflex
; Alt+~: tilde
; Alt+u: umlaut
; (no cedilla)

#UseHook
!VKC0SC029::	; grave `
!VKDESC028::	; acute '
!^::	; circumflex
!~::    ; tilde
!u::	; umlaut
Accent:=1
Sleep 5000
Accent:=0
return

#If Accent
;              1 2 3 4 5 6 7 8 9 1
;                                0
;          r   g G a A c C t T u U
*a::
diacritic("a","à,À,á,Á,â,Â,ã,Ã,ä,Ä")
Accent:=0
return
*e::
diacritic("e","è,È,é,É,ê,Ê,e,E,ë,Ë")
Accent:=0
return
*i::
diacritic("i","ì,Ì,í,Í,î,Î,i,I,ï,Ï")
Accent:=0
return
*o::
diacritic("o","ò,Ò,ó,Ó,ô,Ô,õ,Õ,ö,Ö")
Accent:=0
return
*u::
diacritic("u","ù,Ù,ú,Ú,û,Û,u,U,ü,Ü")
Accent:=0
return
*n::
diacritic("n","n,N,n,N,n,N,ñ,Ñ,n,N")
Accent:=0
return
*y::
diacritic("y","y,Y,y,Y,y,Y,y,Y,ÿ,Ÿ")
Accent:=0
return

diacritic(regular,accentedCharacters) {
    StringSplit, char, accentedCharacters, `,
    graveOption := char1
    graveShiftOption := char2
    acuteOption              := char3
    acuteShiftOption := char4
    circumflexOption := char5
    circumflexShiftOption := char6
    tildeOption := char7
    tildeShiftOption := char8
    umlautOption := char9
    umlautShiftOption := char10

    if (A_PriorHotKey = "!VKC0SC029" && A_TimeSincePriorHotkey < 2000) {
        if (GetKeyState("Shift")) {
            SendInput % graveShiftOption
        } else {
            SendInput % graveOption
        }
    } else if (A_PriorHotKey = "!e" && A_TimeSincePriorHotkey < 2000) {
        if (GetKeyState("Shift")) {
            SendInput % acuteShiftOption
        } else {
            SendInput % acuteOption
        }
    } else if (A_PriorHotKey = "!i" && A_TimeSincePriorHotkey < 2000) {
        if (GetKeyState("Shift")) {
            SendInput % circumflexShiftOption
        } else {
            SendInput % circumflexOption
        }
    } else if (A_PriorHotKey = "!t" && A_TimeSincePriorHotkey < 2000) {
        if (GetKeyState("Shift")) {
            SendInput % tildeShiftOption
        } else {
            SendInput % tildeOption
        }
    } else if (A_PriorHotKey = "!u" && A_TimeSincePriorHotkey < 2000) {
        if (GetKeyState("Shift")) {
            SendInput % umlautShiftOption
        } else {
            SendInput % umlautOption
        }
    } else {
        if (GetKeyState("Shift") or GetKeyState("Capslock","T")) {
            SendInput % "+" regular
        } else {
            SendInput % regular
        }
    }
}

#If


; end of file ==============
