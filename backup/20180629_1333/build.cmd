@echo off

SET Aut2Exe=c:\Users\sberczi\Dropbox\prog\_\autoIt\autoIt\Aut2Exe\Aut2exe_x64.exe




cd /d %~dp0
SET APP=vpnConnect
for %%a in (%APP%.au3) do set version=%%~ta
SET version2=%version::=%
SET version2=%version2: =_%
SET version2=%version2:.=%

if not exist %Aut2Exe% (
	echo ERROR: AutoIt not found, set it's location in this file first and try again.
	echo download location: https://www.autoitscript.com/site/autoit/downloads/ -> https://www.autoitscript.com/cgi-bin/getfile.pl?autoit3/autoit-v3.zip
	pause
	exit 1
)

echo Making backup..
mkdir ".\backup\%version2%"
cp *.au3 .\backup\%version2%\
cp *.cmd .\backup\%version2%\

del %APP%.exe
echo Building %APP%: version: %version%... (Console)
%Aut2Exe% /in .\%APP%.au3 /out %APP%.exe 		/console /icon .\res\Disconnect.ico /pack /companyname "IT-Services Kft." /productversion "%version%"

rem del %APP%_gui.exe
rem echo Building %APP%: version: %version%... (GUI)
rem %Aut2Exe% /in .\%APP%.au3 /out %APP%_gui.exe    /gui /icon .\res\Disconnect.ico /pack /companyname "IT-Services Kft." /productversion "%version%"

rem pause