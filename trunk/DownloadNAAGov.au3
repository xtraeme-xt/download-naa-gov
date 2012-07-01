;
; Download NAA.gov images
; http://code.google.com/p/download-naa-gov/
; To use navigate to naa.gov, find a document with a digital file. The url will contain: 
;   http://recordsearch.naa.gov.au/scripts/Imagine.asp
; On this page hit F9 over the next page button (it looks like an arrow ... ->) . 
; Then either hit F10 or click Command->start to download
;

#include <WindowsConstants.au3>
#include <GuiMenu.au3>
#include <GUIConstantsEx.au3>
#include <GuiConstants.au3>
#include <process.au3>
#Include <Array.au3>
#include <misc.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <StaticConstants.au3>
#include <INet.au3>

Const $version = "0.0.1"

Global Enum Step +1 $ECLEAN_EXIT = 0, $EEMERGENCY_EXIT, $EPREMATURE_EXIT, $E3_EXIT, $E4_EXIT, $EINTERNALERR_EXIT
Global Enum Step +2 $EINFINITELOOPDBG=1, $EVERBOSE, $ETRACE, $EASSERT, $EUNHANDLED, $EINTERNAL, $EUSER
Global Enum Step +2 $ENOTHING = 0, $EUSERVERBOSE = 12
Global $gDisableLoggerLevels = $ENOTHING

Global $gNT = 15
Global $gSleepMultiplier = 1

Global $gButton
Global $gWindow
Global $label5
Global $label6

Dim Const $empty[2] = [0,0]
Dim $gCoords = $empty
Global $gStop = false
Dim $gWinPos[2] = [0, 0]
Dim $gWinSize[2] = [0, 0]

Global $gCWD = @WorkingDir

HotKeySet("{F9}", "SetCoords")
HotKeySet("{F10}", "Start")
HotKeySet("{F11}", "Stop")
HotKeySet("^!+e", "EmergencyExit")

;If $gNT = 1 Then
;	GuiCreate("DL-NAA-GOV", 160, 140, -1, -1, $WS_SIZEBOX) ;10, 10, $WS_SIZEBOX -- height 200 old
;Else
	GuiCreate("DL-NAA-GOV", 180, 122) ;height 200
;EndIf
GUISetBkColor(0xffffff)
$gui_input = GUICtrlCreateInput("", 90,10, 80, 20, $ES_RIGHT) ; old 160
$gui_startnum = GUICtrlCreateInput("", 90,40, 80, 20, $ES_RIGHT)
$gui_pad = GUICtrlCreateInput("", 90,70, 80, 20, $ES_RIGHT)

$spacer = 30
$lab2h = 13 ;36
$label2 = GuiCtrlCreateLabel("Total # of pgs:", 5, $lab2h)
$lab3h = $lab2h + $spacer
$label3 = GuiCtrlCreateLabel("Current pg #:  ", 5, $lab3h)
$lab4h = $lab3h + $spacer
$label4 = GuiCtrlCreateLabel("Padding width: ", 5, $lab4h)


$commands = GuiCtrlCreateMenu("&Commands")
$startitem = GuiCtrlCreateMenuItem("&Start (F10)", $commands)
$pauseitem = GuiCtrlCreateMenuItem("&Pause (F11)", $commands)
;$stopitem = GuiCtrlCreateMenuItem("S&top", $commands)
$exititem = GuiCtrlCreateMenuItem("&Exit (Alt+Ctrl+Shift+E)", $commands)

$help = GuiCtrlCreateMenu("&Help")
$readmeitem = GuiCtrlCreateMenuItem("View &Project", $help)
$aboutitem = GuiCtrlCreateMenuItem("&About", $help)


GuiSetState()



do
	$msg = GuiGetMsg()
	StateMachine($msg)
Until $msg = $GUI_EVENT_CLOSE OR $msg = $exititem


Func StateMachine($msg)
	;Dim $tempSize[2]
	Select
		Case $msg = $GUI_EVENT_CLOSE Or $msg = $exititem
			return 1
			
		Case $msg = $startitem
			return Start()
			
		Case $msg = $pauseitem
			Stop()
			
			;================  ABOUT DIALOGUE CASES =================
		Case $msg = $aboutitem
			If WinExists("DL-NAA-GOVAbout") Then 
				GUIDelete($gWindow)
				return 0 ; ContinueLoop
			EndIf
			
			;If $gNT <> 1 Then
			;	$width = 242
			;Else
				$width = 220
			;EndIf
			$height = 110
			Dim $pos = WinGetPos("[TITLE:DL-NAA-GOV; CLASS:AutoIt v3 GUI]") ;("DL-NAA-GOV")
			$tempSize = WinGetClientSize("[TITLE:DL-NAA-GOV; CLASS:AutoIt v3 GUI]") ;"DL-NAA-GOV")
			$tempSize[0] += 5
			$gWindow = GUICreate("DL-NAA-GOVAbout", "112", $height, $pos[0] + $tempSize[0], $pos[1], $WS_POPUPWINDOW) ;280x160
			$label1 = GuiCtrlCreateLabel("Download NAA Gov", (8 * ($width / 2)) / 100, 3, 100)
			GUICtrlSetFont($label1, 14, 800, 4, "Times New Roman")
			GUICtrlSetColor($label1, 0xff0000)
			$spacer = 20
			$lab2h = 32 ;36
			$label2 = GuiCtrlCreateLabel("Created By:  Xtraeme", 5, $lab2h)
			$lab3h = $lab2h + $spacer
			$label3 = GuiCtrlCreateLabel("Contact:", 5, $lab3h, 23)	;The auto width feature clips the labels so we need to be explicit
			$lab4h = $lab3h + $spacer
			$label4 = GuiCtrlCreateLabel("Website:", 5, $lab4h, 23)
			$lab45h = $lab4h + $spacer
			$label45 = GuiCtrlCreateLabel("Version:        " & $version, 5, $lab45h)

			;GUICtrlSetColor($label, 0xff0000)
			;GUICtrlSetFont($label2, 9, 400, 4)
			GUISetState(@SW_SHOW, $gWindow)
			$max = $width - 112
			For $counter = 0 to $max
				WinMove("DL-NAA-GOVAbout", "", $pos[0] + $tempSize[0], $pos[1], 112 + $counter, $height)
			Next

			Global $label5 = GuiCtrlCreateLabel("xthaus@yahoo.com", 70, $lab3h - 2, $SS_NOTIFY)
			GUICTRLSetFont($label5, 9, 400, 4)
			GUICtrlSetColor($label5, 0x0000ff)
			Global $label6 = GuiCtrlCreateLabel("http://sigsno.org", 70, $lab4h - 2, $SS_NOTIFY)
			GUICTRLSetFont($label6, 9, 400, 4)
			GUICtrlSetColor($label6, 0x0000ff)

			$gButton = GUICtrlCreateButton("i", $width - 15, 5, 12, 12, BitOr($BS_BITMAP, $BS_DEFPUSHBUTTON))
			GuiCtrlSetImage($gButton, $gCWD & "\left.bmp")
			;GUISetState(@SW_SHOW, $gButton)
			;Msgbox(0,"The Ultimate Collection","Created by Xtraeme." & @LF & "Contact: xthaus@yahoo.com" & @LF & "Website: http://wiki.razing.net")
			

		Case $msg = $label6
			If WinExists("DL-NAA-GOVAbout") Then
				If FileExists(@ProgramFilesDir & "\Internet Explorer\iexplore.exe") Then
					;Run(@ProgramFilesDir & "\Internet Explorer\iexplore.exe http://wiki.razing.net")
					_RunDOS("start http://sigsno.org")
				EndIf
			EndIf
		
		Case $msg = $readmeitem 
			If FileExists(@ProgramFilesDir & "\Internet Explorer\iexplore.exe") Then
				;Run(@ProgramFilesDir & "\Internet Explorer\iexplore.exe http://wiki.razing.net")
				_RunDOS("start http://code.google.com/p/download-naa-gov/")
			EndIf
		
		Case $msg = $label5
			_INetMail("xthaus@yahoo.com", "[DL-NAA-GOV] ", "Please leave the [DL-NAA-GOV] in the Subject so my mail filter can sort by it, thanks!")

		Case $msg = $gButton
			If WinExists("DL-NAA-GOVAbout") Then
#cs
				$width = 220
				$height = 110
				$pos = WinGetPos("[TITLE:DL-NAA-GOV; CLASS:AutoIt v3 GUI]") ;"DL-NAA-GOV")
				$tempSize = WinGetClientSize("[TITLE:DL-NAA-GOV; CLASS:AutoIt v3 GUI]") ; ("DL-NAA-GOV")
				$tempSize[0] += 5
				GUICtrlDelete($gButton)
				GUICtrlDelete($label5)
				GUICtrlDelete($label6)
				For $counter = $width to 112 step -1
					WinMove("DL-NAA-GOVAbout", "", $pos[0] + $tempSize[0], $pos[1], $counter, $height)
				Next
#ce				
				GUIDelete($gWindow)
			EndIf

		Case $msg = $GUI_EVENT_PRIMARYUP
			;GUIGetState($window,
			;If $gVerbosity = 1 Then MsgBox(0, "Clicked", "Clucked")
			$tempPos = WinGetPos("[TITLE:DL-NAA-GOV; CLASS:AutoIt v3 GUI]") ;("DL-NAA-GOV")
			$tempSize = WinGetClientSize("[TITLE:DL-NAA-GOV; CLASS:AutoIt v3 GUI]") ;("DL-NAA-GOV")
			$tempSize[0] += 5
			if IsArray($tempPos) AND $tempPos[0] <> $gWinPos[0] AND $tempPos[1] <> $gWinPos[1] Then
				If WinExists("DL-NAA-GOVAbout") Then WinMove("DL-NAA-GOVAbout", "", $tempPos[0] + $tempSize[0], $tempPos[1])
				$gWinPos[0] = $tempPos[0]
				$gWinPos[1] = $tempPos[1]
				$gWinSize[0] = $tempSize[0]
				$gOffset = $tempSize[0]
				$gWinSize[1] = $tempSize[1]
			EndIf

			;XTRAEME: Undo the commented block at some point ...
		Case $msg = $GUI_EVENT_MOUSEMOVE
			if(WinExists("The FoonoteReaper")) then
				;ConsoleWrite("moved ..")
				$tempPos = WinGetPos("[TITLE:DL-NAA-GOV; CLASS:AutoIt v3 GUI]") ;("DL-NAA-GOV")
				$tempSize = WinGetClientSize("[TITLE:DL-NAA-GOV; CLASS:AutoIt v3 GUI]") ;("DL-NAA-GOV")
				$tempSize[0] += 5
				if IsArray($tempPos) AND $tempPos[0] <> $gWinPos[0] AND $tempPos[1] <> $gWinPos[1] Then
					If WinExists("DL-NAA-GOVAbout") Then WinMove("DL-NAA-GOVAbout", "", $tempPos[0] + $tempSize[0], $tempPos[1])
					$gWinPos[0] = $tempPos[0]
					$gWinPos[1] = $tempPos[1]
					$gWinSize[0] = $tempSize[0]
					$gOffset = $tempSize[0]
					$gWinSize[1] = $tempSize[1]
				EndIf
			endif
			
		Case $msg = $GUI_EVENT_RESIZED
			;ConsoleWrite("resized ..")
			$tempPos = WinGetPos("[TITLE:DL-NAA-GOV; CLASS:AutoIt v3 GUI]") ;("DL-NAA-GOV")
			$tempSize = WinGetClientSize("[TITLE:DL-NAA-GOV; CLASS:AutoIt v3 GUI]") ;("DL-NAA-GOV")
			if IsArray($tempPos) AND($tempPos[0] <> $gWinPos[0] OR $tempPos[1] <> $gWinPos[1] OR $tempSize[0] <> $gWinSize[0] OR $tempSize[1] <> $gWinSize[1]) Then
				;ConsoleWrite("resized ..")
				If WinExists("DL-NAA-GOVAbout") Then WinMove("DL-NAA-GOVAbout", "", $tempPos[0] + $tempSize[0] + 12, $tempPos[1])
				$gWinPos[0] = $tempPos[0]
				$gWinPos[1] = $tempPos[1]
				$gWinSize[0] = $tempSize[0] + 12
				$gOffset = $tempSize[0]
				$gWinSize[1] = $tempSize[1]
			EndIf

			;===============  END ABOUT DIALOGUE CASES ==============
	EndSelect
	return 0
EndFunc   ;==>StateMachine


Func SetCoords()
	$gCoords = MouseGetPos()
	ConsoleWrite( $gCoords[0] & " " &  $gCoords[1] & @CRLF)
EndFunc


Func Stop()
	if($gStop = false) then
		$gStop = True
		TrayTip("", "Toggle Off", 10)
		TraySetToolTip("Toggle Off")
	Else
		$gStop = False
		TrayTip("", "Toggle On", 10)
		TraySetToolTip("Toggle On")
	EndIf
	;$gStop = mod($gStop+1, 2)
	ConsoleWrite($gStop & @CRLF)
EndFunc


Func Start()
	;Page to go up to
	$orignum = GUICtrlRead($gui_input)
	;Page we're at
	$startnum = GUICtrlRead($gui_startnum)
	;Padding scheme for filename
	$padnum = GUICtrlRead($gui_pad)
	
	if($startnum = "") Then
		$add = 1
		$num = $orignum
	Else
		$add = 0
		$num = $orignum - $startnum
	EndIf
	
	Logger($EVERBOSE, $orignum & " " & $startnum & " " & $num & " " & $padnum & " " & $gStop & " " & $gCoords[0] & " " & $gCoords[1] & @CRLF, false)
	WinActivate("[CLASS:Firefox]")
	WinWaitactive("[CLASS:Firefox]", "", 3)

	Logger($EVERBOSE, "Got past activate", false)
	While($gStop = False AND _
		  $gCoords <> $empty AND _
		  $gCoords[0] <> 0 AND _
		  $gCoords[1] <> 0 AND _
		  $num >=0) ; -1 AND $num <> ""))
				sleep(3000)
				
				$tempnum = GUICtrlRead($gui_input)
				if($startnum <> "") then
					$num = _Iif($tempnum == $orignum, $tempnum - $startnum, $tempnum)
				Else
					$num = $tempnum
				EndIf
				
				MouseMove($gCoords[0], $gCoords[1]+200)
				while (Not WinExists("Select location") and Not WinExists("Save Image"))
					MouseClick("right")
					Send("v")
					Sleep(1500)
				WEnd
				
				Send(GetPaddedNum(($orignum - $num)+$add, $orignum, $padnum))
				Sleep(1000)
				
				while (WinExists("Select location") or WinExists("Save Image"))
					Send("!s")
					Sleep(500)
					;Send("{ENTER}")
					if(WinExists("Confirm Save As")) then 
						WinActivate("Confirm Save As")
						Send("+{tab}")
						Send("{Enter}", 0)
						Sleep(150 * $gSleepMultiplier)
					Else
						Send("{ENTER}")
					endif
				WEnd
				Sleep(1000)
				$num = $num-1
				ConsoleWrite($num & " -- num")
				GUICtrlSetData($gui_input, $num)
				MouseMove($gCoords[0], $gCoords[1])
				MouseClick("left")
				MouseMove($gCoords[0]+44, $gCoords[1])
				MouseClick("left")
	WEnd	
EndFunc


Func GetPaddedNum($num, $maxnum, $explicitpad=-1)
	Logger($ETRACE, "GetPadddedNum(" & $num & ")", false)
	Dim $paddednum = ""
	$maxlen = stringlen($maxnum)
	$curlen = stringlen($num)
	
	if($explicitpad <> -1 and $explicitpad <> "") then
		$diff = $explicitpad-$curlen
	Else
		$diff = $maxlen-$curlen
	EndIf
	
	if(($curlen < $maxlen) OR ($curlen < $explicitpad)) Then
		for $i = 1 to $diff
			$paddednum &= "0"
		Next
	EndIf
	$paddednum &= $num
	;ConsoleWrite($paddednum & " -- the padded num")
	return $paddednum
EndFunc
	
	
Func GetClip(ByRef $clip, $sendCtrlC = false, $count = "")
	Logger($ETRACE, "GetClip()", false)
	
	;Santize and store old input
	Local $oldclip = ""
	if($sendCtrlC) then
		$oldclip = ClipGet()
		Logger($EVERBOSE, "$oldclip: " & $oldclip, false)
		ClipPut("") ; May want to make sure we have something we can check for.
		Send("{CTRLDOWN}")
		Send("^c")
		Send("{CTRLUP}")
		Sleep(200 * $gSleepMultiplier) ; give it some time to grab it as the transfer might take a moment
	endif
	
	$clip = ClipGet()
	$ret = @error
	;ConsoleWrite("THIS IS THE TEMPCLIP: " & $clip & @CRLF)
	
	if($ret <> 0) then
		if($ret = 1) then
			Logger($EVERBOSE, "err#:" & $ret & " clipboard (#" & $count & ") empty clipboard", false)
		elseif($ret = 2) then
			Logger($EVERBOSE, "err#:" & $ret & " clipboard (#" & $count & ") non-text entry on clipboard", false)
		elseif($ret > 2 And $ret <= 4) then
			Logger($EVERBOSE, "err#:" & $ret & " clipboard (#" & $count & ") cannot access clipboard", false)
		else
			Logger($EVERBOSE, "err#:" & $ret & " clipboard (#" & $count & ") unknown error", false)
		endif
	endif
	;Retore the original clip
	if($sendCtrlC) then ClipPut($oldclip)
	return $ret
EndFunc  


Func CleanupExit($code, $msg, $bMsgBox)
	Logger($ETRACE, "CleanupExit()", false)
	;IMPL -- two params? code, message, msgbox and then write location or other details.
	;the code will determine if we exit (i.e. 5)
	;Exit(5)  ;worst error
	;0 is (verbosity just normal clean exit?)	
	;1 is (perhaps the user quitting prematurely?)
	;2 is (a problem where the program has some unsolvable state and must quit)
	;3-4 ... ?
	;5 is internal error (worst case scenario, something really screwed up worse than premature like bad data)
	Select
		Case $code = $ECLEAN_EXIT
			if $bMsgBox then MsgBox(48, "Clean Exit", $msg);
			_ConsoleWrite("Clean Exit: " & $msg)
		Case $code = $EEMERGENCY_EXIT
			if $bMsgBox then MsgBox(48, "Emergency Exit", $msg);
			_ConsoleWrite("Emergency Exit: " & $msg)
		Case $code = $EPREMATURE_EXIT
			if $bMsgBox then MsgBox(48, "Premature Exit", $msg);
			_ConsoleWrite("Premature Exit: " & $msg)
		Case $code = $EINTERNALERR_EXIT
			if $bMsgBox then MsgBox(48, "Internal Error", $msg);
			_ConsoleWrite("Internal Error Exit: " & $msg)
	EndSelect
	;if($gLoggerEnabled) then _Console_Free()
	Exit($code)
EndFunc   ;==>CleanupExit


Func EmergencyExit()
	Logger($ETRACE, "EmergencyExit()", false)
	CleanupExit($EEMERGENCY_EXIT, "Hotkey shutdown...", false)
EndFunc


Func _ConsoleWrite($string)
	ConsoleWrite($string)
	;if($gLoggerEnabled) then _Console_Write($string)
EndFunc


Func Logger($code, $msg, $bMsgBox, $timeout = 0)
	;Overall levels will be:
	; 0. nothing
	; 1. Infinite loop patterns
	; 3. Verbose output
	; 4. 
	; 5. Traces
	; 6. 
	; 7. Asserts
	; 8.
	; 9. Unhandled exceptions
	; 10.
	; 11. Internal errors
	; 12. User messages
	; 13. User level messages.
	;if($gDisableLoggerLevels >= $code and NOT IsLoggerCodeExempt($code)) then return
	Select
		Case $code = $EINFINITELOOPDBG
			_ConsoleWrite($msg)	;the $msg acts as a "pattern" to print
		Case $code = $EVERBOSE
			if $bMsgBox then MsgBox(64, "Verbose", $msg, $timeout);
			_ConsoleWrite("Verbose: " & $msg & @CRLF)
		Case $code = $ETRACE
			if $bMsgBox then MsgBox(64, "Trace", $msg & @CRLF, $timeout);
			_ConsoleWrite("Trace: " & $msg & @CRLF)
		Case $code = $EASSERT
			if $bMsgBox then MsgBox(64, "Assert", $msg & @CRLF, $timeout);
			_ConsoleWrite("Assert: " & $msg & @CRLF)
		Case $code = $EUNHANDLED ;was 1
			if $bMsgBox then MsgBox(64, "Unhandled Exception", $msg, $timeout);
			_ConsoleWrite("Unhandled Exception: " & $msg & @CRLF)
		Case $code = $EINTERNAL ;was 5
			if $bMsgBox then MsgBox(48, "Internal Error", $msg, $timeout);
			_ConsoleWrite("Internal Error: " & $msg & @CRLF)
		Case $code = $EUSERVERBOSE
			if $bMsgBox then MsgBox(48, "User Verbose", $msg, $timeout);
			_ConsoleWrite("UVerbose: " & $msg & @CRLF)
		Case $code = $EUSER
			if $bMsgBox then MsgBox(48, "Notification", $msg, $timeout);
			_ConsoleWrite("Notification: " & $msg & @CRLF)
		Case Else
			if $bMsgBox then MsgBox(64, "Unknown Error Level:", "(Err#:" & $code & "): " & $msg & @CRLF, $timeout);
			_ConsoleWrite("Unknown Error Level: (#" & $code & "): " & $msg & @CRLF)
	EndSelect
EndFunc   ;==>Logger


