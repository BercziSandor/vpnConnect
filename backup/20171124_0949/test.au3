#AutoIt3Wrapper_Change2CUI=y
#include <GUIConstants.au3>
If $cmdline[0]=0 Then
    $title="Default Title"
Else
    $title=$cmdline[1]
EndIf
$Form1 = GUICreate($title, 633, 454, 193, 125)
$Button1 = GUICtrlCreateButton("Button1", 24, 224, 121, 49, 0)
$Button2 = GUICtrlCreateButton("Button2", 152, 224, 121, 57, 0)
$Button3 = GUICtrlCreateButton("Button3", 288, 224, 105, 33, 0)
$Slider1 = GUICtrlCreateSlider(48, 32, 561, 33)
GUISetState(@SW_SHOW)

Opt("GUIOnEventMode",1)
GUICtrlSetOnEvent ($Button1,"Button1")
GUICtrlSetOnEvent ($Button2,"Button2")
GUICtrlSetOnEvent ($Button3,"Button3")
GUICtrlSetOnEvent ($Slider1,"Slider1")
GUISetOnEvent($GUI_EVENT_CLOSE,"Close")
While 1
sleep(1000)
WEnd

Func Button1()
    ConsoleWrite("Button1"&@CRLF)
EndFunc
Func Button2()
    ConsoleWrite("Button2"&@CRLF)
EndFunc
Func Button3()
    ConsoleWrite("Button3"&@CRLF)
EndFunc
Func slider1()
    ConsoleWrite("Slider: "&GUICtrlRead($Slider1)&@CRLF)
EndFunc
Func Close()
    Exit
EndFunc