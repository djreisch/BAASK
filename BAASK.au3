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

#Region
#AutoIt3Wrapper_Res_Comment=Batch Auto Activator for Steam keys     ;Program Comment
#AutoIt3Wrapper_Res_Description=Batch Auto Activator for Steam keys ;File Description
#AutoIt3Wrapper_Res_Fileversion=3.3.1.0								;File Version
#AutoIt3Wrapper_Res_ProductVersion=3.3.1.0							;Product Version
#AutoIt3Wrapper_Res_LegalCopyright=GPLv3							;Legal Copyright
#AutoIt3Wrapper_Res_Field=Productname|BAASK							;Program Name

;command to run after compile to sign exe
#AutoIt3Wrapper_Run_After=resources\codesign.bat
#EndRegion

#include <Constants.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstants.au3>
#include <GUIConstantsEx.au3>
#include <File.au3>
#include <GuiEdit.au3>

Global $VERSION  = "3.3.1"


;Starts to set up simple event based GUI with 2 labels, 1 edit box and 1 button

Global $editbox
Global $baask
Local  $button
Global $exitBool

Opt("GUIOnEventMode", 1)                           ;enables on even functions
$baask = GUICreate("BAASK v" & $VERSION, 260, 600) ;creates the baask GUI
GUISetOnEvent($GUI_EVENT_CLOSE, "Quit")            ;enables that when the GUI closes, the script terminates

GUICtrlCreateLabel("Add Your Keys (one per line)", 30, 10)         ;creates a GUI label in the top left

$editbox = GUICtrlCreateEdit("", 30, 30, 200, 400, $ES_WANTRETURN) ;creates an edit box
GUICtrlCreateLabel("Note: Steam won't let you redeem more" & @CRLF & "than 25 keys per hour.", 30, 440) ;displays note under the text box

;Create and hook up button
;Local $buttonMsg = "Run!" ;creates button button message
$button = GUICtrlCreateButton("Run!", 80, 480, 100, 100, $BS_MULTILINE) ;creates a multi-lined button with the text
GUICtrlSetOnEvent($button, OnExecute)                                   ;sets that when button is clicked, execute function OnExecute
GUISetState(@SW_SHOW)                                                   ;makes sure the GUI is shown

$exitBool = false         ;set this to false so program doesn't exit right away
HotKeySet("{ESC}","Quit") ;Press ESC key to quit program at any time

Main() ;start the main function (the program core)

; Keeps the program running forever until the Quit function is called
Func Main()

	While True
		Sleep(100)
	WEnd

EndFunc


; Attempts to redeem each line in the edit field as a key for a new game (or product)
Func OnExecute()
	Local $textBlock = GUICtrlRead($editbox)            ;used to pull key from GUI
	Local $keyArray = StringSplit($textBlock, @CRLF)    ;splits key block into separate key arrays
	Local $count = 0                                    ;counter used for current key

	GUICtrlSetData($editBox, "Duplicate Keys:" & @CRLF) ;writes header to UI box


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

		GUICtrlSetData($button, "Exit")  ;changes button text to Exit
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
	Local $workingwin = "[TITLE:Steam - Working; REGEXPCLASS:USurface\_\d*]"
	Local $installwin = "[TITLE:Install - ; REGEXPCLASS:USurface\_\d*]"		   ;Steam game install window (used to check if duplicate key)

	Local $prodactwinpos      ;used for the position of the activation window
	Local $windowSize         ;used to hold the size of the activation window
	Local $offset[2] = [1, 1] ;if size is not standard this stores the ration of the windows size to multiply by

	Local $backBtn[2]         ;array for x,y of back button
	Local $nextBtn[2]		  ;array for x,y of next button
	Local $cancelBtn[2]		  ;array for x,y of cancel button
	Local $finishBtn[2]		  ;array for x,y of finish button
	Local $printBtn[2]		  ;array for x,y of print button

	Local $colorAr[4]         ;;array for color values of 4 pixel locations during window search (when "Too Many Activation Attempts" gets triggered)



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

		$prodactwinpos = WinGetPos($prodactwin)     ;gets position of the steam activation window
		$windowSize = WinGetClientSize($prodactwin) ;gets size of the window to calculate offsetting

		If $windowSize[0] <> 476 Or $windowSize[1] <> 400 Then

			$offset[0] = $windowSize[0] / 476
			$offset[1] = $windowSize[1] / 400

		EndIf


		;these next several variables calculate and store the position of the activation buttons based on the product activation window location and the windows offset

		$backBtn[0] = ($prodactwinpos[0] + 214) * $offset[0]
		$backBtn[1] = ($prodactwinpos[1] + 374) * $offset[1]

		$nextBtn[0] = ($prodactwinpos[0] + 314) * $offset[0]
		$nextBtn[1] = ($prodactwinpos[1] + 374) * $offset[1]

		$cancelBtn[0] = ($prodactwinpos[0] + 414) * $offset[0]
		$cancelBtn[1] = ($prodactwinpos[1] + 374) * $offset[1]

		$finishBtn[0] = ($prodactwinpos[0] + 414) * $offset[0]
		$finishBtn[1] = ($prodactwinpos[1] + 374) * $offset[1]

		$printBtn[0] = ($prodactwinpos[0] + 222) * $offset[0]
		$printBtn[1] = ($prodactwinpos[1] + 278) * $offset[1]

		;BEGINS button clicking

		ClickAndWait($nextBtn[0], $nextBtn[1])	 ; Click the Next Button and wait for next page
		ClickAndWait($nextBtn[0], $nextBtn[1])	 ; Click on I Agree, wait for next page

		Send($key)						         ; Write the key in auto-focused field
		Sleep(200)						         ; Pause briefly for visual feedback

		ClickAndWait($nextBtn[0], $nextBtn[1])	 ; Click on Next to submit form

		WinWaitClose($workingwin)                ; Must Wait for the Working Window to come and go


		ClickAndWait($printBtn[0], $printBtn[1]) ; Click on Print to see if the print box opens
		WinWait($printwin, "", 6)                ;waits for print window
		If(WinExists($printwin)) Then            ;if the print window exists begin statement

			WinClose($printwin)                  ;close the print window
			WinClose($prodactwin)                ;close the product window, the key worked

		EndIf


		If(WinExists($prodactwin)) Then            ;if the key didn't work we are going to check if it's a duplicate

			ClickAndWait($nextBtn[0], $nextBtn[1]) ;clicks next to see if it exists

			WinWait($installwin, "", 5)            ;waits for installation window (if a next button existed one should appear)

			If WinExists($installwin) Then         ;if installation window opens then

			   WinClose($installwin)               ;close it
			   _GUICtrlEdit_AppendText($editBox, $key & @CRLF) ;write duplicate key to UI

			EndIf

		EndIf


		If(WinExists($prodactwin)) Then ;if the key didn't work and wasn't a duplicate, there might be another issue

			;find pixels that are not gray and if they exist then it's too many activation attempts

			$colorAr[0] = PixelGetColor($prodactwinpos[0]+157 , $prodactwinpos[1]+59, $prodactwin)
			$colorAr[1] = PixelGetColor($prodactwinpos[0]+158 , $prodactwinpos[1]+59, $prodactwin)
			$colorAr[2] = PixelGetColor($prodactwinpos[0]+159 , $prodactwinpos[1]+59, $prodactwin)
			$colorAr[3] = PixelGetColor($prodactwinpos[0]+160 , $prodactwinpos[1]+59, $prodactwin)


			;if the white pixels weren't found, close the window and do the next key
			If (($colorAr[0] == $colorAr[1]) And ($colorAr[1] == $colorAr[2]) And ($colorAr[2] == $colorAr[3])) Then

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
