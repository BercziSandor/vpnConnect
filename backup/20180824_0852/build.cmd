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

echo Making backup...
if not exist .\backup\%version2% (
	mkdir ".\backup\%version2%"
)
copy /Y *.cmd .\backup\%version2%\
copy /Y *.au3 .\backup\%version2%\

del .\bin\%APP%.exe
echo Building %APP%: version: %version%... (Console)
%Aut2Exe% /in .\%APP%.au3 /out bin/%APP%.exe 		/console /icon	.\res\Disconnect.ico /pack /companyname "IT-Services Kft." /productversion "%version%"

rem GUI
rem del .\bin\%APP%_gui.exe
rem echo Building %APP%: version: %version%... (GUI)
rem %Aut2Exe% /in .\%APP%.au3 /out bin/%APP%_gui.exe	/gui	/icon	.\res\Disconnect.ico /pack /companyname "IT-Services Kft." /productversion "%version%"

mkdir .\bin\res\
copy /Y .\res\*.* .\bin\res\

echo Creating distribution files
mkdir dist
if exist ./dist/vpnConnect_%version2%.zip (
	rm ./dist/vpnConnect_%version2%.zip
)
cd bin
zip -r ../dist/vpnConnect_%version2%.zip ./vpnConnect*.exe ./res/ ../README.md

rem pause