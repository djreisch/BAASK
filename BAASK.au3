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

#AutoIt3Wrapper_Res_Field=Productname|BAASK							;Product Name
#AutoIt3Wrapper_Res_Comment=Batch Auto Activator for Steam keys     ;Comment field
#AutoIt3Wrapper_Res_Description=Batch Auto Activator for Steam keys ;Description field
#AutoIt3Wrapper_Res_Fileversion=3.2.0.0	                         	;File Version
#AutoIt3Wrapper_Res_ProductVersion=3.2.0.0	                      	;Product Version
#AutoIt3Wrapper_Res_LegalCopyright=GPLv3                        	;Copyright field

Global $VERSION  = "3.2.0"


;Starts to set up simple event based GUI with 2 labels, 1 edit box and 1 button

Opt("GUIOnEventMode", 1) ;enables on even functions
Global $baask = GUICreate("BAASK v" & $VERSION, 260, 600) ;creates the baask GUI
GUISetOnEvent($GUI_EVENT_CLOSE, "Quit")      ;enables that when the GUI closes, the script terminates
GUICtrlCreateLabel("Add Your Keys (one per line)", 30, 10) ;creates a GUI label in the top left
Global $editbox = GUICtrlCreateEdit("", 30, 30, 200, 400, $ES_WANTRETURN) ;creates an edit box
GUICtrlCreateLabel("Note: Steam won't let you redeem more" & @CRLF & "than 25 keys per hour.", 30, 440) ;displays note under the text box

;Create and hook up button
;Local $buttonMsg = "Run!" ;creates button button message
Local $button = GUICtrlCreateButton("Run!", 80, 480, 100, 100, $BS_MULTILINE) ;creates a multi-lined button with the text
GUICtrlSetOnEvent($button, OnExecute) ;sets that when button is clicked, execute function OnExecute
GUISetState(@SW_SHOW) ;makes sure the GUI is shown

Global $exitBool = false
HotKeySet("{ESC}","Quit") ;Press ESC key to quit program at any time

Main()

; Keeps the program running forever until the Quit function is called
Func Main()

	While True
		Sleep(100)
	WEnd

EndFunc


; Attempts to redeem each line in the edit field as a key for a new game (or product)
Func OnExecute()
	Local $textBlock = GUICtrlRead($editbox) ;used to pull key from GUI
	Local $keyArray = StringSplit($textBlock, @CRLF) ;splits key block into separate key arrays
	Local $count = 0

	GUICtrlSetData($editBox, "Duplicate Keys:" & @CRLF) ;writes header to UI box
	;_GUICtrlEdit_AppendText($editBox, @CRLF & @CRLF & "Duplicate Keys:" & @CRLF)


	;cycles through key array and starts redeeming
	For $i = 1 to $keyArray[0]
		If Not ($exitBool) Then
			If ($keyArray[$i] <> "") Then
				Redeem($keyArray[$i])
				$count = $i
			EndIf
		EndIf
	Next

	;if keys were redeemed
	If ($count > 0) Then

		GUICtrlSetData($button, "Exit") ;changes button text to Exit
		GUICtrlSetOnEvent($button, Quit) ;sets that when button is clicked, execute function Quit

		If Not ($exitBool) Then
			;message the keys were activated if exitBool is not true
			MsgBox(64, "Key Activation Complete!", "Don't forget to copy your duplicate keys from the program window (these keys can be used on another account)")
		Else
			;if exitBool is true then append untested keys because activation attempts ran out
			 _GUICtrlEdit_AppendText($editBox, @CRLF & "Untested Keys:" & @CRLF)

			;cycles through the rest of the key array posting unchecked keys
			For $i = $count to $keyArray[0]
				If ($keyArray[$i] <> "") Then
					_GUICtrlEdit_AppendText($editBox, $keyArray[$i] & @CRLF)
				EndIf
			Next

			;lets user know whats going on, saying they ran out of keys
			MsgBox(48, "Warning!", "Steam won't let you activate anymore keys right now." & @CRLF & @CRLF & "The keys in the Untested Keys section might not be duplicates and should be retried once you can activate more keys." & @CRLF & @CRLF & "We recommend waiting at least one hour before attempting to activate more keys." & @CRLF & @CRLF & "Please remember to copy your duplicate and untested keys from the program window")

		EndIf

	Else

		;if the user is silly and doesn't enter in keys
		GUICtrlSetData($editBox, "(Psst! Type your keys here)")

	EndIf


   WinActivate($baask)
EndFunc


;Function that emulates the key activation process
Func Redeem($key)

   ;Variables are used to check if certain Steam windows are available using the title and class name
   ;Class name for the Steam Activation windows are USurface_ followed by a number, so we wildcard it

	Local $prodactwin = "[TITLE:Product Activation; REGEXPCLASS:USurface\_\d*]" ;general activation window
	Local $printwin   = "[TITLE:Print; REGEXPCLASS:#32770]"					   ;system print window (used to check if product key worked)
	Local $installwin = "[TITLE:Install - ; REGEXPCLASS:USurface\_\d*]"		   ;Steam game install window (used to check if duplicate key)


	;Checks if the windows already exist and then closes them if they do exist
	If WinExists($prodactwin) Then
		WinClose($prodactwin)
	EndIf

	If WinExists($installwin) Then
		WinClose($installwin)
	EndIf


	ShellExecute("steam://open/activateproduct") ;opens the Steam activation window

	WinWait($prodactwin, "", 5)		; Explicitly wait for Product Activation window
	If WinExists($prodactwin) Then

		local $prodactwinpos = WinGetPos($prodactwin) ;gets position of the steam activation window


		;these next several variables determine the position of the activation buttons based on the window location determined in the above statement

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



		;BEGINS button clicking

		ClickAndWait($nextX, $nextY)	; Click the Next Button and wait for next page
		ClickAndWait($nextX, $nextY)	; Click on I Agree, wait for next page

		Send($key)						; Write the key in auto-focused field
		Sleep(200)						; Pause briefly for visual feedback

		ClickAndWait($nextX, $nextY)	; Click on Next to submit form
		Sleep(200)						; Must Wait for the Working Window to come and go



		ClickAndWait($printX, $printY)	; Click on Print to see if the print box opens
		WinWait($printwin, "", 6)       ;waits for print window
		If(WinExists($printwin)) Then   ;if the print window exists begin statement

			WinClose($printwin)   ;close the print window
			WinClose($prodactwin) ;close the product window, the key worked

		EndIf


		If(WinExists($prodactwin)) Then    ;if the key didn't work we are going to check if it's a duplicate

			ClickAndWait($nextX, $nextY)   ;clicks next to see if it exists

			WinWait($installwin, "", 5)    ;waits for installation window (if a next button existed one should appear)

			If WinExists($installwin) Then ;if installation window opens then

			   WinClose($installwin)       ;close it
			   _GUICtrlEdit_AppendText($editBox, $key & @CRLF) ;write duplicate key to UI

			EndIf

		EndIf


		If(WinExists($prodactwin)) Then ;if the key didn't work and wasn't a duplicate, there might be another issue

			;find pixels that are not gray and if they exist then it's too many activation attempts
			Local $aCoord = PixelSearch($prodactwinpos[0]+157 , $prodactwinpos[1]+50, $prodactwinpos[0]+180, $prodactwinpos[1]+70, 0xA8A8A8, 50)
			;if the white pixels weren't found, close the window and do the next key
			If @error Then

				WinClose($prodactwin)

			Else
				;too many activation attempts, close the window and activate the program window while setting exitBool to true
				WinClose($prodactwin)

				WinActivate($baask)

				$exitBool = true

			EndIf

		EndIf ;ends If for key being a different issue

	EndIf ;beginning If statement

EndFunc


; Helper function to click a specific point and wait a specific delay
; Delay is 200 by default and is ignored when set to 0
Func ClickAndWait($x, $y, $wait=200)
   MouseClick("left", $x, $y)
   If ($wait > 0) Then
	  Sleep($wait)
   EndIf
EndFunc


Func Quit()
	Exit
EndFunc
