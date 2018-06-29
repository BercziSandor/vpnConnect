#include <Inet.au3>
#include <Crypt.au3>
#include <GUIConstantsEx.au3>
#include <GuiToolbar.au3>
#include <WindowsConstants.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <WinAPIDiag.au3>

Func msgBBox($ls_msg)
    MsgBox( $MB_SYSTEMMODAL, "", $ls_msg )
    msg($ls_msg)
EndFunc


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
        exit 1;
    EndIf

    $data_bin = _Crypt_DecryptData( $data, $pass, $Algorithm );
    if $data_bin == "-1" Then
        msgBBox( "Wrong password. Delete " & $iniFile & " and try again." )
        exit 1;
    Else
        $data_decr = BinaryToString($data_bin)
        $splitted = StringSplit( $data_decr, $sep )
        $pw1 = $splitted[1]
        $pw2 = $splitted[2]
        msgBBox("1: [" & $pw1 & "] 2:[" & $pw2 & "]")
    EndIf
EndIf