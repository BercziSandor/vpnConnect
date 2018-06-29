#AutoIt3Wrapper_Change2CUI=y

#include <Inet.au3>
#include <Crypt.au3>
#include <GUIConstantsEx.au3>
#include <GuiToolbar.au3>
#include <WindowsConstants.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <WinAPIDiag.au3>

FileGetVersion(@ScriptFullPath)
FileGetVersion(@ScriptName)


$helpString = 'vpnConnect - Berczi Sandor' & @CRLF & _
'Leiras: egyszeru AutoIt ( https://www.autoitscript.com/site/autoit/ ) script, amely megkonnyiti a VPN-hez valo kapcsolodast az It-Services berkein belul.' & @CRLF & _
' Egy, a script mellett levo file-ban a felhasznalo altal megadott jelszoval kodolva tarolja le a jelszavakat.' & @CRLF & _
'  (Amennyiben a file nem letezik, bekeri a jelszavakat, majd letrehozza a titkositott file-t)'

; CONSTANTS
Global $CONSOLE_MODE        = 1
Global $VPN_CONSOLE         = 0
Global $VPN_GRAPHICAL       = 1
Global $statusWindowTimeout = 1
Global $vpnClientMode       = $VPN_GRAPHICAL

Global $warningSoundFile = @WindowsDir & "\media\Windows Information Bar.wav"
$warningSoundFile = @WindowsDir & "\media\Windows Startup.wav"
$warningSoundFile = @WindowsDir & "\media\Windows Pop-up Blocked.wav"

; CONSTANTS - DO NOT Change
Global $VPN_STATE_CONNECTED       = "connected"
Global $VPN_STATE_DISCONNECTED    = "disconnected"
Global $VPN_STATE_UNKNOWN         = "unknown"
Global $NET_STATE_CONNECTED_ITSH  = "connected_itsh"
Global $NET_STATE_CONNECTED_OTHER = "connected_other"
Global $NET_STATE_DISCONNECTED    = "disconnected"
Global $NET_STATE_UNKNOWN         = "unknown"
Global $publicIP
Global $sMessage                  = ""
Global $clientRoot                = "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client"

Global $pwTiks ;tiks
Global $pwWindows ;win
Global $startTimeStamp= @YEAR & @MON & @MDAY & "_" & @MIN & @SEC
Global $hFileLog = -1

; GUI
Local $gui_icon_net, $gui_icon_vpn
Local $gui_button_ok
Local $gui_log


; ----------------------------------------
; Entry point
WinMinimizeAll ( )
ini()
WinSetState("vpnConnect", "", @SW_RESTORE )
WinSetState("vpnConnect", "", @SW_SHOW)
help()
main()
; WinMinimizeAllUndo ( )




; ----------------------------------------
; Functions


Func help()
	msg($helpString)
EndFunc

Func ini()

	; msg("ini() entering")
	Local $hTimer = TimerInit()
	Opt( "SendKeyDelay", 100 )
	Opt( "WinTitleMatchMode", 2 )


	If Not FileExists($clientRoot) Then
		msgBBox( "Directory '" & $clientRoot & "' could not found, exiting." )
		myend()
	EndIf

	If $CONSOLE_MODE = 0 Then
		; GUI
		GUICreate("vpnConnect", 700, 1000, 10, 10)
		GUISetState(@SW_SHOW)
		$gui_button_ok = GUICtrlCreateButton("Ok", 0, 0, 40, 40, $BS_ICON)
		$gui_icon_net  = GUICtrlCreateIcon("netcenter.dll", -5, 0,  51,40,40)
		$gui_icon_vpn  = GUICtrlCreateIcon(".\vpn_connected.ico", 0,  0 + 4, 91 + 4, 32,32 )
		$gui_log       = GUICtrlCreateEdit("First line", 60, 10, 600, 900, $ES_AUTOVSCROLL + $WS_VSCROLL)
	Else

		If Not FileExists(@ScriptDir & "/log" ) Then
			DirCreate ( @ScriptDir & "/log" )
			If Not FileExists(@ScriptDir & "/log" ) Then
				msgBBox( "Directory '" & @ScriptDir & "/log" & "' could not be created, exiting." )
				myend()
			EndIf
		EndIf

		$hFileLog = FileOpen(@ScriptDir & "/log/vpnConnect_" & $startTimeStamp & ".log" , $FO_APPEND)
		If $hFileLog = -1 Then
		   MsgBox($MB_SYSTEMMODAL, "", "An error occurred whilst writing the log file.")
		   Return False
		EndIf
	EndIf
	msg("ini(): getting ip address")
	$publicIP = _GetIP()

	msg("ini(): returning (" & Round(TimerDiff($hTimer) / 1000, 1) & "s )")

EndFunc

Func myend()
	; If $CONSOLE_MODE = 0 Then
	; Else
	; EndIf
	If $hFileLog <> -1 Then
		FileClose($hFileLog)
	EndIf
	WinMinimizeAllUndo ( )
	exit

EndFunc

Func loadPWs()
	Local $data
	Local $pass
	$sep = "×"
	$Algorithm = $CALG_AES_256
	$iniFile = @ScriptDir & "\vpnConnect.ini"
	if FileExists($iniFile) Then
		$data= FileRead($iniFile)
		$pass = InputBox( "Enter password", "Please type the password for the ini file.", "", "*" )
		if $pass == "" or @error <> 0 Then
			msgBBox( "No password gived, exiting." )
			myend()
		EndIf

		$data_bin = _Crypt_DecryptData( $data, $pass, $Algorithm );
		if $data_bin == "-1" Then
			msgBBox( "Wrong password. Delete "&$iniFile&" and try again." )
			myend()
		Else
			$data_decr = BinaryToString($data_bin)
			$splitted = StringSplit( $data_decr, $sep )
			$pwTiks = $splitted[1]
			$pwWindows = $splitted[2]
		EndIf
	Else
		$pwTiks = InputBox( "Enter password", "Please type the password for TIKS card.",     "", "*" )
		$pwWindows = InputBox( "Enter password", "Please type the password for Windows login.", "", "*" )
		$pass = InputBox( "Enter password", "Please type the password for the ini file.",  "", "*" )
		$data_decr = StringToBinary( $pwTiks & $sep & $pwWindows )
		if MsgBox( $MB_YESNO, "", "May I save the to an encrypted file?", 10 ) = $IDYES Then
			$data = _Crypt_EncryptData( $data_decr, $pass, $Algorithm )
			FileWrite( $iniFile, $data )
			msg("loadPWs(): ini file saved")
		EndIf
	EndIf;
  EndFunc


; Disconnecting VPN, exit GUI
Func disconnect()
	msg("disconnect() entering")
	if ProcessExists("vpnui.exe") Then
		Local $hTimer = TimerInit()
		msg("disconnect() VPNCLI: disconnecting...")
		ShellExecuteWait( $clientRoot & "\vpncli.exe", "disconnect", "", "", @SW_HIDE )
		msg("disconnect() Closing VPNCLI")
		ProcessClose("vpnui.exe")
		msg("VPN connection closed. (" & Round(TimerDiff($hTimer) / 1000, 1) & "s )")
	EndIf
	refreshStatusIcons()
	removeOldIconsFromTray()

	If ProcessExists("CiscoJabber.exe") Then
		Local $hTimer = TimerInit()
		msg("disconnect() Closing CiscoJabber.exe")
		ProcessClose("CiscoJabber.exe")
		msg("Jabber closed. (" & Round(TimerDiff($hTimer) / 1000, 1) & "s )")
	EndIf

	If ProcessExists("OUTLOOK.EXE") Then
		Local $hTimer = TimerInit()
		msg("disconnect() Closing OUTLOOK.EXE")
		ProcessClose("OUTLOOK.EXE")
		msg("Outlook closed. (" & Round(TimerDiff($hTimer) / 1000, 1) & "s )")
	EndIf

	msg("disconnect() returning")

EndFunc

Func connect()
	disconnect()
	msg("connect() entering")
	if $vpnClientMode = $VPN_GRAPHICAL Then
		;Start GUI
		msg("connect() running vpnui.exe")
		$pid = Run( $clientRoot & "\vpnui.exe", "" )
		If $pid = 0 Then
			msgBBox( "vpnui.exe could not started, exiting." )
			myend()
		EndIf;

		$winTitle = "Cisco AnyConnect Secure Mobility Client"
		msg("connect() activating " & $winTitle )
		$handleCiscoAnyConnect = u_activateWindow($winTitle, "Ready to connect.")

		; 1: Standard method
		; u_clickOnButtonOnWindow( $winTitle, "Button1" )

		; 2: Keyboard
		u_SendToWindow($handleCiscoAnyConnect, "{TAB}{TAB}{ENTER}")

		; 3:
		; Bug (?) with this window: standard method does not work.
		; ablak abs koord: 564,261
		; button abs center:1113,494
		;  -> button rel center:549,233
		; clickOnWindow( $winTitle, 549, 233 ) ; 2016.10.01
		; clickOnWindow( $winTitle, 509, 195 ) ; 2016.11.10

		;------------------------------------------------------
		; SmartCard pin
		$winTitle = "Windows Security"
		$winHandle = u_activateWindow($winTitle,"")
		if (StringLen ( $pwTiks ) > 0 ) Then
			Send( $pwTiks & "{ENTER}" )
		Else
			Send("2222{BS}{BS}{BS}{BS}")
			SoundPlay( $warningSoundFile, 1 )
			msg( "connect() User interaction on window " & $winTitle )
		EndIf
		WinWaitClose($winHandle)

		;------------------------------------------------------
		$winTitle = "Cisco AnyConnect | "
		$winHandle = u_activateWindow($winTitle,"")
		if (StringLen ( $pwWindows ) > 0 ) Then
			Send( $pwWindows & "{ENTER}" )
		Else
			Send("2222{BS}{BS}{BS}{BS}")
			SoundPlay( $warningSoundFile, 1 )
			msg( "connect() User interaction on window " & $winTitle )
		EndIf
		WinWaitClose($winHandle)

		;------------------------------------------------------
		$winTitle = "Cisco AnyConnect"
		u_clickOnButtonOnWindow( $winTitle, "Button1" )

		;------------------------------------------------------
		;Cisco NAC Agent window : nothing to do
		$winTitle = "Cisco NAC Agent"
		; 160429: not needed??? $winHandle = u_activateWindow($winTitle)
		; WinWaitClose($winTitle)
	Else
		Local $cmd=@ComSpec & " /c """ & $clientRoot & "\vpncli.exe"" connect Budapest"
		msg("executing: [" & $cmd & "]")
		Local $pid=Run( $cmd, "", @SW_MAXIMIZE, $STDOUT_CHILD)

		; SmartCard pin
		$winTitle = "Windows Security"
		$winHandle = u_activateWindow($winTitle,"")
		if (StringLen ( $pwTiks ) > 0 ) Then
			Send( $pwTiks & "{ENTER}" )
		Else
			Send("2222{BS}{BS}{BS}{BS}")
			SoundPlay( $warningSoundFile, 1 )
			msg( "connect() User interaction on window " & $winTitle )
		EndIf
		WinWaitClose($winHandle)
		Local $sOutput = StdoutRead($pid)

		msg("out: " & $sOutput)

		; Please enter your username and password.
		$winHandle = u_activateWindow($pid,"")
		if (StringLen ( $pwWindows ) > 0 ) Then
			Send( $pwWindows & "{ENTER}" )
		Else
			Send("2222{BS}{BS}{BS}{BS}")
			SoundPlay( $warningSoundFile, 1 )
			msg( "connect() User interaction on window " & $winTitle )
		EndIf
		Sleep(900000)
		; TODO: to be implement
	EndIf

	u_processClose("Viber.exe")
	; u_processClose("Dropbox.exe")

	; TODO: instead of fix waiting, wait for text "Compliant." on this window:
	$winTitle = "Cisco AnyConnect Secure Mobility Client"
	msg("connect() activating " & $winTitle )
	Local $i = 0
	While $i < 90
		u_activateWindow($handleCiscoAnyConnect,"")
		Local $txt=WinGetText ( $handleCiscoAnyConnect )
		; msg("Text on window: " & $txt )
		If StringInStr($txt, "Compliant.", $STR_CASESENSE ) Then
			ExitLoop
			msg("'Compliant' appeared, exit waiting.")
		Else
			msg("Still waiting for text 'Compliant' on Cisco AnyConnect window...")
		EndIf
		$i = $i + 1
		Sleep(1000)
	WEnd



	Local $vpnState = $VPN_STATE_DISCONNECTED
	msg("Checking for connection state...")
	Local $i = 0
	While $i <= 60 and $vpnState <> $VPN_STATE_CONNECTED
		$vpnState = get_VPN_state()
		$i = $i + 1
		Sleep(500)
	WEnd
	If $vpnState <> $VPN_STATE_CONNECTED Then
		msgBBox( "VPN is not connected, exiting." )
		myend()
	EndIf

	; OUTLOOK -->
	msg("Starting Outlook")
	Run( @ProgramFilesDir & "\Microsoft Office\Office14\OUTLOOK.EXE", '.', @SW_MINIMIZE, $STDOUT_CHILD )
	Local $hWnd = WinWait("Microsoft Outlook", "", 10)
	WinSetState($hWnd, "", @SW_MINIMIZE)
	;------------------------------------------------------
	; SmartCard pin
	If ( 1 > 2 ) Then
		$winTitle = "Windows Security"
		$winHandle = u_activateWindow($winTitle,"")
		if (StringLen ( $pwTiks ) > 0 ) Then
			Send( $pwTiks & "{ENTER}" )
		Else
			Send("2222{BS}{BS}{BS}{BS}")
			SoundPlay( $warningSoundFile, 1 )
			msg( "connect() User interaction on window " & $winTitle )
		EndIf
		WinWaitClose($winHandle)
	EndIf
	; <-- OUTLOOK

	; TODO: bugfix for minimize

	; JABBER -->
	Run( @ProgramFilesDir & "\Cisco Systems\Cisco Jabber\CiscoJabber.exe" )
	; msg("Click 'Sign in' button: Cisco Jabber 200 450")
	; clickOnWindow( "Cisco Jabber", 200, 450 )

	;------------------------------------------------------
	$winTitle = "Windows Security"
	$winHandle = u_activateWindow($winTitle,"")
	if (StringLen ( $pwWindows ) > 0 ) Then
		Send( $pwWindows & "{ENTER}" )
	Else
		Send("2222{BS}{BS}{BS}{BS}")
		SoundPlay( $warningSoundFile, 1 )
		msg( "connect() User interaction on window " & $winTitle )
	EndIf
	WinWaitClose($winHandle)
	; <-- JABBER

	; Obsolete?
	if (0) Then
		;'Meeting Host Account' window :
		$winTitle = "Meeting Host Account"
		msg( "Waiting for window '" & $winTitle & "'" )
		$winHandle = WinWait( $winTitle, "", 60 )
		If $winHandle = 0 Then
		Else
			if WinActivate($winTitle) = 0 Then
				msgBBox( "'" & $winTitle & "' window could not activated, exiting." )
				myend()
			Else
				msg("... window appeared")
				WinWaitActive($winTitle,"",10)
				WinClose($winTitle)
			EndIf
			if (0) Then
				;Click on Accept button
				$buttonHandle = ControlGetHandle( '[ACTIVE]', '', 'Button2' )
				$buttonPos = WinGetPos($buttonHandle)
				sleep(1)
				MouseClick( "left", $buttonPos[0] + $buttonPos[2] / 2, $buttonPos[1] + $buttonPos[3] / 2 )
			EndIf
		EndIf
	EndIf

	refreshStatusIcons()
	msg("connect() returning")

EndFunc

Func reconnect()
	msg("reconnect() entering")
	loadPWs()
	connect()
	refreshStatusIcons()
	msg("reconnect() returning")

EndFunc



Func refreshStatusIcons()
	return
	Local $status_net, $status_vpn
	$status_vpn=get_VPN_state()
	If $status_vpn = $VPN_STATE_CONNECTED Then
		GUICtrlSetImage($gui_icon_net, "netcenter.dll", -5) ; ok
		GUICtrlSetImage($gui_icon_vpn, @ScriptDir & "\vpn_connected.ico")
	Else
		GUICtrlSetImage($gui_icon_vpn, @ScriptDir & "\vpn_error.ico")
		$status_net=get_NET_state()
		If $status_net == $NET_STATE_CONNECTED_ITSH or $status_net == $NET_STATE_CONNECTED_OTHER  Then
			GUICtrlSetImage($gui_icon_net, "netcenter.dll", -5) ; ok
		Else
			GUICtrlSetImage($gui_icon_net, "netcenter.dll", -6) ; error
		EndIf
	EndIf
EndFunc


Func main()

	Local $fullTimer = TimerInit()
	msg("main() entering")

	Local $netState = get_NET_state()
	Local $vpnState = get_VPN_state()
	refreshStatusIcons()
	removeOldIconsFromTray()
	If $vpnState == $VPN_STATE_CONNECTED Then
		Local $buttonPressed = MsgBox( $MB_YESNOCANCEL, "Question", "You are connected to VPN. Do you want to reconnect?" & @CRLF & "yes: reconnect, no: disconnect, cancel: do nothing" );
		If $buttonPressed = $IDYES Then
			reconnect()
		ElseIf $buttonPressed = $IDNO Then
			disconnect()
		ElseIf $buttonPressed = $IDCANCEL Then
			; dummy
		EndIf
	ElseIf $vpnState == $VPN_STATE_DISCONNECTED Then
		msg( "main() your ip is " & $publicIP )
		If $netState == $NET_STATE_DISCONNECTED Then
			MsgBox( $MB_OKCANCEL, "Error", "You are not connected to the internet, right?"& @CRLF & "Please connect first. Exiting." )
			msg("You are not connected to the internet, right?")
			msg("Please connect first. Exiting.")
			sleep(5000)
		ElseIf $netState == $NET_STATE_CONNECTED_OTHER Then
			msg( "main() your ip is " & $publicIP )
			reconnect()
		ElseIf $netState == $NET_STATE_CONNECTED_ITSH Then
			msg("You are in the LAN environment, right?")
			msg("So, you don't need to connect to the VPN. Exiting")
			disconnect()
			refreshStatusIcons()
			sleep(5000)
		Else
		EndIf
	Else
		if MsgBox( $MB_RETRYCANCEL, "Title", "The VPN is in unknown state. Do you want to try to reconnect?" ) = $IDRETRY Then
			main()
		EndIf
	EndIf
	msg("Total time: " & Round(TimerDiff($fullTimer) / 1000, 1) & "s" )
	msg("Bye.")
	sleep(2000)
	GUIDelete()

EndFunc











;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Generic utility functions

Func get_NET_state()
	msg("get_NET_state() entering")
	Local $retval=$NET_STATE_UNKNOWN
	If (_WinAPI_IsNetworkAlive() <> 0) Then
		If ( get_VPN_state() == $VPN_STATE_CONNECTED ) Then
			$retval=$NET_STATE_CONNECTED_ITSH
		Else
			$retval=$NET_STATE_CONNECTED_OTHER
		EndIf
	Else
		$retval=$NET_STATE_DISCONNECTED
	EndIf

	if (0) Then
		msg("get_NET_state()/_GetIP() entering")
		$publicIP = _GetIP()
		msg("get_NET_state()/_GetIP() returning")
		If $publicIP == "-1" or $publicIP == "" Then
			$retval=$NET_STATE_DISCONNECTED
		ElseIf StringRegExp( $publicIP, "^10." ) = 1 Then
			$retval=$NET_STATE_CONNECTED_ITSH
		Else
			$retval=$NET_STATE_CONNECTED_OTHER
		EndIf
	EndIf


	msg("get_NET_state() returning")
	return $retval
EndFunc


Func u_activateWindow($winTitle, $winText)
	msg( "u_activateWindow(): Waiting for window '" & $winTitle & "','" & $winText & "'" )

	Local $hTimer = TimerInit()

	While 1
		If (WinActivate($winTitle,$winText) <> 0) Or (WinActive($winTitle,$winText) <> 0) Then
			; WinSetState($winTitle,"",@SW_RESTORE)
			ExitLoop
		EndIf
		Sleep(1000)
		; msg( "u_activateWindow(): Waiting..." )
	WEnd

	WinActivate($winTitle,$winText)
	$winHandle = WinWaitActive($winTitle,$winText)
	If $winHandle = 0 Then
		msgBBox( "'" & $winTitle & "' window could not found, exiting." )
		myend()
	Else
		WinSetState($winHandle,"",@SW_RESTORE)
	EndIf

	msg("u_activateWindow() ... window appeared ( " & Round(TimerDiff($hTimer) / 1000, 1) & "s )")
	WinActivate($winTitle,$winText)
	if WinActivate($winTitle,$winText) = 0 Then
		msgBBox( "'" & $winTitle & "' window could not activated, exiting." )
		myend()
	Else
		msg( "u_activateWindow(): Window '" & $winTitle & "' activated." )
	EndIf
	msg( "u_activateWindow(): Returning." )
	return $winHandle
EndFunc

Func u_SendToWindow($winTitle, $text)
	msg("Sending '" & $text & "' to window '" & $winTitle & "'")
	winInfo($winTitle)
	Send($text)
EndFunc

Func u_clickOnButtonOnWindow( $winTitle, $buttonName )
	u_clickOnButtonOnWindow_shift( $winTitle, $buttonName,0,0)
EndFunc

Func winInfo($winTitle)
	$handle=u_activateWindow($winTitle,"")
	handleInfo($handle)
	; u_showWithMouse_Window($winTitle)
	; u_showWithMouse_Window($winTitle)
EndFunc

Func handleInfo($handle)
	$pos = WinGetPos($handle)
	$x=$pos[0]
	$y=$pos[1]
	$w=$pos[2]
	$h=$pos[3]
	msg("Coords of handle: x: " & $x & ", y:" & $y & ", width:" & $w & ", height:" & $h)
EndFunc

Func getButtonHandle( $winTitle, $buttonName)
	return ControlGetHandle( $winTitle, '', $buttonName )
EndFunc

Func clickOnWindow( $winTitle,$dx,$dy)
	$lastMousePos= MouseGetPos()

	Opt("MouseCoordMode", 0) ;1=absolute, 0=relative, 2=client
	if u_activateWindow($winTitle,"") = 0 Then
		return 0
	EndIf
	Sleep(100)
	MouseClick( "main", $dx, $dy, 1, 5 );click middle of button
	Opt("MouseCoordMode", 1) ;1=absolute, 0=relative, 2=client
	MouseMove( $lastMousePos[0], $lastMousePos[1] )

	return 1
EndFunc

Func u_clickOnButtonOnWindow_shift( $winTitle, $buttonName,$dx,$dy)
	if u_activateWindow($winTitle,"") = 0 Then
		return 0
	EndIf
	;Click on button
	; u_showWithMouse_Window($winTitle)
	; showWithMouse_Button_shift($winTitle, $buttonName,$dx, $dy)

	$buttonHandle = ControlGetHandle( '[ACTIVE]', '', $buttonName )
	Opt("MouseCoordMode", 1) ;1=absolute, 0=relative, 2=client
	$lastMousePos= MouseGetPos()

	$buttonPos = WinGetPos($buttonHandle)
	$x=$buttonPos[0] + $dx
	$y=$buttonPos[1] + $dy
	$w=$buttonPos[2]
	$h=$buttonPos[3]
	MouseClick( "main", $x + ($w / 2), $y + ($h / 2), 1, 5 );click middle of button

	MouseMove( $lastMousePos[0], $lastMousePos[1] )
	return 1
EndFunc

Func showWithMouse_Button($ls_winTitle, $buttonName)
	showWithMouse_Button_shift($ls_winTitle, $buttonName,0,0)
EndFunc

Func showWithMouse_Button_shift($ls_winTitle, $buttonName,$dx,$dy)
	if u_activateWindow($ls_winTitle,"") = 0 Then
		return 0
	Else
		$lastMousePos = MouseGetPos()
		$buttonHandle = ControlGetHandle( '[ACTIVE]', '', $buttonName )
		$buttonPos    = WinGetPos($buttonHandle)
		$x = $buttonPos[0] + $dx
		$y = $buttonPos[1] + $dy
		$w = $buttonPos[2]
		$h = $buttonPos[3]
		msg("Coords of button '" & $ls_winTitle & ""& $buttonName & "': x: " & $x & ", y:" & $y & ", width:" & $w & ", height:" & $h)
		$speed = 10
		For $i = 1 To 2 Step 1
			MouseMove( $x, $y, $speed )
			MouseMove( $x + $w, $y, $speed )
			MouseMove( $x + $w, $y + $h, $speed )
			MouseMove( $x, $y + $h, $speed )
			MouseMove( $x, $y, $speed )
		Next
		Sleep(1000)
		MouseMove( $lastMousePos[0], $lastMousePos[1] )
		return 1
	EndIf
EndFunc

Func u_processClose($pName)
	Local $i = 0
	While $i < 10
		Local $pid=ProcessExists($pName)
		If $pid>0 Then
			msg("connect() Closing " & $pName & "(" & $pid & ")... " & $i)
			If ( ProcessClose("Viber.exe") = 0 ) Then
				msg ("Error closing "& $pName )
			EndIf
		Else
			ExitLoop
		EndIf
		$i = $i + 1
	WEnd
EndFunc

Func u_showWithMouse_Window($ls_winTitle)
	if u_activateWindow($ls_winTitle,"") = 0 Then
		return 0
	Else
		$lastMousePos= MouseGetPos()
		$speed = 5
		$winPos = WinGetPos($ls_winTitle)
		$x=$winPos[0]
		$y=$winPos[1]
		$w=$winPos[2]
		$h=$winPos[3]
		msg("Coords of window '" & $ls_winTitle & "': x: " & $x & ", y:" & $y & ", width:" & $w & ", height:" & $h)
		For $i = 1 To 1 Step 1
			MouseMove( $x, $y, $speed )
			MouseMove( $x + $w, $y, $speed )
			MouseMove( $x + $w, $y + $h, $speed )
			MouseMove( $x, $y + $h, $speed )
			MouseMove( $x, $y, $speed )
		Next
		Sleep(1000)
		MouseMove( $lastMousePos[0], $lastMousePos[1] )
		return 1
	EndIf
EndFunc

Func get_VPN_state()
	Local $iPID = Run( $clientRoot & "\vpncli.exe state", '.', @SW_HIDE, $STDOUT_CHILD )
	msg("get_VPN_state(): entering")
	ProcessWaitClose($iPID)
	Local $sOutput = StdoutRead($iPID)
	Local $retval= $VPN_STATE_UNKNOWN
	If StringInStr( $sOutput, ">> state: Connected" ) Then
		$retval= $VPN_STATE_CONNECTED
	ElseIf StringInStr( $sOutput, ">> state: Disconnected" ) Then ; and StringInStr( $sOutput, ">> notice: Ready to connect." ) Then
		$retval=$VPN_STATE_DISCONNECTED
	EndIf
	msg("get_VPN_state(): VPN state is: " & $retval)
	return $retval

EndFunc

Func msgBBox($ls_msg)
	MsgBox( $MB_SYSTEMMODAL, "", $ls_msg )
	msg($ls_msg)
EndFunc

Func msg($ls_msg)
	$tTime = @YEAR & "." & @MON & "." & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
	If $CONSOLE_MODE = 0 Then
		$sMessage = $sMessage & $ls_msg & @CRLF
		GUICtrlSetData ( $gui_log, $sMessage )
	Else
		Consolewrite($tTime & " " & $ls_msg & @CRLF)
	Endif

	FileWriteLine($hFileLog, $ls_msg)

EndFunc

Func removeOldIconsFromTray()

	$hSysTray = ControlGetHandle('[Class:Shell_TrayWnd]', '', '[Class:ToolbarWindow32;Instance:1]')
	$hSysTrayPos = WinGetPos($hSysTray)
	Local $aPos = MouseGetPos()
	For $i = _GUICtrlToolbar_ButtonCount($hSystray) To 1 Step -1
		; $sCurrent = _GUICtrlToolbar_GetButtonText($hSystray,$i)
		$buttonPos = _GUICtrlToolbar_GetButtonRect($hSysTray, $i)
		MouseMove( $hSysTrayPos[0] + ($buttonPos[0] + $buttonPos[2]) / 2, $hSysTrayPos[1] + ($buttonPos[1] + $buttonPos[3]) / 2, 3 )
	Next
	MouseMove($aPos[0],$aPos[1])

EndFunc
