@echo off
SET THEFILE=D:\SnakeMir2\Client\zengl-src-0.3.12\bin\i386-win32\demo06.exe
echo Linking %THEFILE%
C:\lazarus\fpc\2.6.2\bin\i386-win32\ld.exe -b pei-i386 -m i386pe  --gc-sections  -s --subsystem windows --entry=_WinMainCRTStartup    -o D:\SnakeMir2\Client\zengl-src-0.3.12\bin\i386-win32\demo06.exe D:\SnakeMir2\Client\zengl-src-0.3.12\bin\i386-win32\link.res
if errorlevel 1 goto linkend
C:\lazarus\fpc\2.6.2\bin\i386-win32\postw32.exe --subsystem gui --input D:\SnakeMir2\Client\zengl-src-0.3.12\bin\i386-win32\demo06.exe --stack 16777216
if errorlevel 1 goto linkend
goto end
:asmend
echo An error occured while assembling %THEFILE%
goto end
:linkend
echo An error occured while linking %THEFILE%
:end