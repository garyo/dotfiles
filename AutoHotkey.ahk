; AutoHotKeys script ===========
; by Gary Oberbrunner 2-Dec-04 - updated 1-Mar-10

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

;;; Auto-expand shortcuts
;::ob::oberbrunner
:o:\pf32::c:\Program Files (x86)\
:o:\pf::c:\Program Files\
:o:/pf32::"c:/Program Files (x86)"/
:o:/pf::"/Program Files"/

;;; Currency
;;; (* means no end key needed, ? means triggers inside word)
:*?:$eur::€
:*?:$ukp::£
:*?:$yen::¥

; end of file ==============
