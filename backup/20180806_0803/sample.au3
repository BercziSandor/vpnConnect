#include <Crypt.au3>
#include <MsgBoxConstants.au3>
#include <String.au3>

Global  $sOutput

Local $aStringsToEncrypt[1] = ["AutoIt123456"]


Func StringEncrypt($iAlgorithm)
	Local $hKey = _Crypt_DeriveKey("CryptPassword", $iAlgorithm) ; Declare a password string and algorithm to create a cryptographic key.
    Switch $iAlgorithm
        Case $CALG_3DES
             $iAlgorithmS = "3DES"
        Case $CALG_AES_128
             $iAlgorithmS = "AES (128bit)"
        Case $CALG_AES_192
             $iAlgorithmS = "AES (192bit)"
        Case $CALG_AES_256
             $iAlgorithmS = "AES (256bit)"
        Case $CALG_DES
             $iAlgorithmS = "DES"
        Case $CALG_RC2
             $iAlgorithmS = "RC2"
        Case $CALG_RC4
             $iAlgorithmS = "RC4"
    EndSwitch
	; $sOutput &= $iAlgorithmS & @CRLF

	For $iWord In $aStringsToEncrypt
		$enc=_StringToHex(_Crypt_EncryptData($iWord, $hKey, $iAlgorithm))
   		$dec = BinaryToString(_Crypt_DecryptData(_HexToString($enc), $hKey, $iAlgorithm))
		$sOutput &= $iAlgorithmS & " = " & $enc & " - " & $dec & @CRLF ; Encrypt the text with the cryptographic key.
	Next
	_Crypt_DestroyKey($hKey) ; Destroy the cryptographic key.
EndFunc

StringEncrypt($CALG_3DES)
StringEncrypt($CALG_AES_128)
StringEncrypt($CALG_AES_192)
StringEncrypt($CALG_AES_256)
StringEncrypt($CALG_DES)
StringEncrypt($CALG_RC2)
StringEncrypt($CALG_RC4)

MsgBox($MB_SYSTEMMODAL, "Encrypted data", $sOutput)
