@echo off
cd /d %~dp0
SET APP=vpnConnect
for %%a in (%APP%.au3) do set version=%%~ta
SET version2=%version::=%
SET version2=%version2: =_%
SET version2=%version2:.=%
SET Aut2Exe=..\..\..\..\prog\_\autoIt\autoIt\Aut2Exe\Aut2exe.exe

echo Making backup..
mkdir ".\backup\%version2%"
cp *.au3 .\backup\%version2%\
cp *.cmd .\backup\%version2%\

del %APP%.exe
echo Building %APP%: version: %version%... (Console)
%Aut2Exe% /in .\%APP%.au3 /out %APP%.exe 		/console /icon ..\..\..\..\Photos\ikonok\Disconnect.ico /pack /companyname "IT-Services Kft." /productversion "%version%"

rem del %APP%_gui.exe
rem echo Building %APP%: version: %version%... (GUI)
rem %Aut2Exe% /in .\%APP%.au3 /out %APP%_gui.exe    /gui     /icon ..\..\..\..\Photos\ikonok\Disconnect.ico /pack /companyname "IT-Services Kft." /productversion "%version%"

rem pause