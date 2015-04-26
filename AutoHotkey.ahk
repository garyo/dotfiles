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

return
; end of auto-execute section; hotkeys go below.
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
:*?:$eur::Ђ
:*?:$ukp::Ј
:*?:$yen::Ґ

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Type accented letters OSX-style (http://www.autohotkey.com/board/topic/27801-special-characters-osx-style/)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Alt+': acute б
; Alt+`: grave а
; Alt+^: circumflex в
; Alt+~: tilde г
; Alt+u: umlaut д
; (no cedilla)
; бaва

#UseHook
!VKC0SC029::Return 	; grave -> the grave ` accent gave some probs, used the virtualkey + scancode instead
!VKDESC028::Return    	; acute
!^::Return		; circumflex
!~::Return         	; tilde
!u::Return		; umlaut

;                  1 2 3 4 5 6 7 8 9 1
;                                    0
;              r   g G a A c C t T u U
*a::diacritic("a","а,А,б,Б,в,В,г,Г,д,Д")
*e::diacritic("e","и,И,й,Й,к,К,e,E,л,Л")
*i::diacritic("i","м,М,н,Н,о,О,i,I,п,П")
*o::diacritic("o","т,Т,у,У,ф,Ф,х,Х,ц,Ц")
*u::diacritic("u","щ,Щ,ъ,Ъ,ы,Ы,u,U,ь,Ь")
*n::diacritic("n","n,N,n,N,n,N,с,С,n,N")
*y::diacritic("y","y,Y,y,Y,y,Y,y,Y,я,џ")

diacritic(regular,accentedCharacters) {
	StringSplit, char, accentedCharacters, `,
	graveOption            := char1
	graveShiftOption       := char2
	acuteOption            := char3
	acuteShiftOption       := char4
	circumflexOption       := char5
	circumflexShiftOption  := char6
	tildeOption            := char7
	tildeShiftOption       := char8
	umlautOption           := char9
	umlautShiftOption      := char10

	if (A_PriorHotKey = "!VKC0SC029" && A_TimeSincePriorHotkey < 2000) {
		if (GetKeyState("Shift")) {
			SendInput % graveShiftOption
		} else {
			SendInput % graveOption
		}
	} else if (A_PriorHotKey = "!VKDESC028" && A_TimeSincePriorHotkey < 2000) {
		if (GetKeyState("Shift")) {
			SendInput % acuteShiftOption
		} else {
			SendInput % acuteOption
		}
	} else if (A_PriorHotKey = "!^" && A_TimeSincePriorHotkey < 2000) {
		if (GetKeyState("Shift")) {
			SendInput % circumflexShiftOption
		} else {
			SendInput % circumflexOption
		}
	} else if (A_PriorHotKey = "!~" && A_TimeSincePriorHotkey < 2000) {
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

; end of file ==============
