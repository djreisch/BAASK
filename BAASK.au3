; Batch Auto Activator for Steam Games (BAASK) is an automation script to activate multiple keys on Steam
;
; This program is a continuation of Batch Add Game Steam (BAGS) by Sunder Iyer
; https://github.com/goldenxp/batch-add-game-steam
; Sunder derived his work from the Steam Bulk Key Activator (SBKA) by Shedo Surashu
; https://web.archive.org/web/20140214183818/http://coffeecone.com/sbka (I know, this link is dead)
;
; Steam altered their UI flow which invalidated SBKA's flow which spurred
; the creation of BAGS - which attempts to handle the new Add Game flow
; while introducing a new UI flow of its own.
;
; The BAGS project became inactive but could still be improved. Iyer's code was cloned by Daniel Reisch
; https://github.com/djreisch/BAASK
; And is now maintained as BAASK (Batch Auto Activator for Steam Games)
;
; All parent and child practices have remained compliant with SBKA's GPLv3 license
; as well as BAGS GPLv3 license and in the spirit of free software
; this program (BAASK) is also released under GPLv3

#include <Constants.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <File.au3>
#include <GuiEdit.au3>

#AutoIt3Wrapper_Res_Comment=Batch Auto Activator for Steam keys     ;Comment field
#AutoIt3Wrapper_Res_Description=Batch Auto Activator for Steam keys ;Description field
#AutoIt3Wrapper_Res_Fileversion=1.1.1.0                         	;File Version
#AutoIt3Wrapper_Res_ProductVersion=1.1.1.0                      	;Product Version
#AutoIt3Wrapper_Res_LegalCopyright=GPLv3                        	;Copyright field

; Set up simple event based GUI with 2 labels, 1 edit box and 1 button
Opt("GUIOnEventMode", 1)
Global $baask = GUICreate("BAASK", 260, 600)
GUISetOnEvent($GUI_EVENT_CLOSE, "OnClose")
GUICtrlCreateLabel("Add Keys (one per line)", 30, 10)
Global $editbox = GUICtrlCreateEdit("", 30, 30, 200, 400, $ES_WANTRETURN)
GUICtrlCreateLabel("Note: Steam won't let you redeem more" & @CRLF & "than 25 keys per hour.", 30, 440)
; Create and hook up button
Local $buttonMsg = "Run!"
Local $button = GUICtrlCreateButton($buttonMsg, 80, 480, 100, 100, $BS_MULTILINE)
GUICtrlSetOnEvent($button, OnExecute)
GUISetState(@SW_SHOW)

HotKeySet("{ESC}","Quit") ;Press ESC key to quit

; Keep it running
While True
   Sleep(100)
WEnd

; Attempts to redeem each line in the edit field as a key for a new game (or product)
Func OnExecute()
   Local $textBlock = GUICtrlRead($editbox)
   Local $keyArray = StringSplit($textBlock, @CRLF)
   Local $count = 0

   GUICtrlSetData($editBox, "Duplicate Keys:" & @CRLF & @CRLF) ;writes header to UI box

   For $i = 1 to $keyArray[0]
	  If ($keyArray[$i] <> "") Then
		 Redeem($keyArray[$i])
		 $count = $count + 1
	  EndIf
   Next
   If ($count > 0) Then
	   MsgBox(64, "Key Activation Complete!", "Out of " & $count & " keys, " & _GUICtrlEdit_GetLineCount($editBox) - 3 & " were for games you already own") ;shows popup window explaining what happened
   Else
	  GUICtrlSetData($editBox, "(Psst! Type your keys here)")
   EndIf
   WinActivate($baask)
EndFunc

; Exits the GUI
Func OnClose()
   Exit
EndFunc

; Meaty function that emulates user's action to redeem a steam key
Func Redeem($key)
   ; Check if the Steam window is available using the title and class name
   ; Class name is USurface_ followed by a number, so we wildcard it

   ; Local $steamwin = "[TITLE:Steam; REGEXPCLASS:USurface\_\d*]"

   Local $prodactwin = "[TITLE:Product Activation; REGEXPCLASS:USurface\_\d*]"
   Local $workingwin = "[TITLE:Steam - Working; REGEXPCLASS:USurface\_\d*]"
   Local $printwin   = "[TITLE:Print; REGEXPCLASS:#32770]"
   Local $installwin = "[TITLE:Install - ; REGEXPCLASS:USurface\_\d*]"



;   If (WinExists($steamwin)) Then
;	  WinActivate($steamwin)
;	  If (WinActive($steamwin)) Then
		 ; Steam doesn't have traditional buttons so we can't access any controls directly
		 ; We will need to emulate mouse clicks on specific x,y positions
		 ; To facilitate this we will maximize the window to ensure our top-left is 0,0
		 ; and to ensure the top menu bar is completely exposed to click on

;		 WinSetState($steamwin, "", @SW_MAXIMIZE)
;		 ClickAndWait(150, 20)				; Click Games Menu and wait briefly for it
;		 ClickAndWait(150, 64, 0)			; Click Activate Product, Skip waiting

		ShellExecute("steam://open/activateproduct")

		WinWait($prodactwin, "", 5)		; Explicitly wait for Product Activation window
		If WinExists($prodactwin) Then

			local $prodactwinpos = WinGetPos($prodactwin)


			Local $backX = $prodactwinpos[0] + 214
			Local $backY = $prodactwinpos[1] + 374

			Local $nextX = $prodactwinpos[0] + 314
			Local $nextY = $prodactwinpos[1] + 374

			Local $cancelX = $prodactwinpos[0] + 414
			Local $cancelY = $prodactwinpos[1] + 374

			Local $finishX = $prodactwinpos[0] + 414
			Local $finishy = $prodactwinpos[1] + 374

			Local $printX = $prodactwinpos[0] + 222
			Local $printY = $prodactwinpos[1] + 278


			; Window appears in the center of the desktop, use this as point of reference
			; We will be clicking the second button at the bottom of the window, So
			; calculate its offset from the center for re-usage


			ClickAndWait($nextX, $nextY)	; Click the Next Button and wait for next page
			ClickAndWait($nextX, $nextY)	; Click on I Agree, wait for next page

			Send($key)							; Write the key in auto-focused field
			Sleep(200)							; Pause briefly for visual feedback

			ClickAndWait($nextX, $nextY)	; Click on Next to submit form
			Sleep(200)						; Must Wait for the Working Window to come and go



			ClickAndWait($printX, $printY)	; Click on Print to see if the print box opens
			WinWait($printwin, "", 5) ;waits for print window
			If(WinExists($printwin)) Then  ;if the print window exists

				WinClose($printwin)   ;close the print window
				WinClose($prodactwin) ;close the product window, the key worked
			EndIf

			If(WinExists($prodactwin)) Then ;if the key didn't work we are going to check if it's a duplicate

				ClickAndWait($nextX, $nextY) ;clicks next if available

				WinWait($installwin, "", 5)  ;waits for installation window

				If WinExists($installwin) Then ;if installation window opens...
				   WinClose($installwin)   ;close it
				   _GUICtrlEdit_AppendText($editBox, $key & @CRLF) ;write duplicate key to UI
				EndIf

			EndIf

			If(WinExists($prodactwin)) Then ;if the key didn't work and wasn't a duplicate, there might be another issue

				Local $userAnswer = MsgBox(20, "The Program Encountered an Error", "Does the Product Activation window behind this message say there have been Too Many Activation Attempts?") ;shows popup if key is bad or too many activation attemtps

				If($userAnswer = $IDYES) Then
					_GUICtrlEdit_AppendText($editBox, "Unknown" & @CRLF & $key & @CRLF)
					WinClose($prodactwin)
					MsgBox(48, "Warning!", "Steam won't let you activate anymore keys right now." & @CRLF & "The last key used has been written to the program window underneath the unknown section. You should retry this key later as it may work on your account." & @CRLF & "We reccomend waiting at least one hour before attempting to activate more keys" & @CRLF & @CRLF & "WARNING: Please remember to copy your duplicate keys from the program window." & @CRLF & @CRLF & "Pressing OK will EXIT the program")
					Quit
				Else
					WinClose($prodactwin)
				EndIf

			EndIf

		EndIf
			; Finished process
		 ;EndIf ; (end product win exist)
	  ;EndIf ; (end steam win active)
   ;EndIf
EndFunc

; Helper function to click a specific point and wait a specific delay
; Delay is 200 by default and is ignored when set to 0
Func ClickAndWait($x, $y, $wait=200)
   MouseClick("left", $x, $y)
   If ($wait > 0) Then
	  Sleep($wait)
   EndIf
EndFunc

; Quits script when called
Func Quit()
    Exit
EndFunc
