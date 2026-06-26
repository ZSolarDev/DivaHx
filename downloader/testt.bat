@echo off
setlocal enabledelayedexpansion
(
  set NL=^


)

REM  initial setup, EG; install haxe if not already installed, install haxelibs, so on and so forth.
echo Scanning for haxe...
haxe -version
IF %ERRORLEVEL% neq 0 (
    echo Haxe is not installed..
    echo Haxe is a required compiler for this game, would you like to install it?

    CHOICE /c "Y/N" /m "Press [Y] to install HAXE!NL!Press [N] to cancel install and abort build process"
    IF %ERRORLEVEL% EQU 1 GOTO HAXEINSTALLVALID
    IF %ERRORLEVEL% EQU 2 GOTO HAXEINSTALLABORT
REM 
REM 
    REM REM User said yeah to installing HAXE, continue with setup process
    :HAXEINSTALLVALID
    CD /D "%USERPROFILE%\Downloads"
    POWERSHELL -Command "Invoke-WebRequest https://github.com/HaxeFoundation/haxe/releases/download/4.3.7/haxe-4.3.7-win64.exe -OutFile haxe-4.3.7-win64.exe" >NUL 2>&1
REM 
    REM REM START /wait "C:/users/%USERNAME%/Downloads/haxe-4.3.7-win64.exe/"
REM 
    REM ECHO thank you for testing, me!


    REM https://haxe.org/download/file/4.3.7/haxe-4.3.7-win64.exe/   install path from the website after we manage to figure out how to download it through this bs.

    REM  Clean up
    REM del haxe_installer.exe
    REM 
    REM echo Haxe installation finished. 
    REM echo NOTE: You may need to restart your terminal to see the 'haxe' command.
    REM haxe -version

    REM User said no to install, so cancel the process.
    :HAXEINSTALLABORT
    ECHO Understood!!NL!Aborting build process... 
) else (
    ECHO Haxe is installed, continuing...
)
REM lime
REM if %ERRORLEVEL% neq 0 (
REM     echo lime is not installed, please wait while we install and set it up...
REM     haxelib install lime
REM     haxelib run lime setup
REM     lime
REM     if %ERRORLEVEL% neq 0 (
REM         echo We were unable to set up lime properly
REM         echo Please install and set lime up manually.
REM         pause
REM     )
REM )
REM echo lime installed, running haxelibs...
REM haxelib install flixel 6.1.2
REM haxelib install flixel-ui 2.6.4
REM haxelib install flixel-addons 3.3.2
REM haxelib install openfl 9.5.0
REM haxelib install hxcpp 4.3.2
REM echo install complete running autobuild wrapper...
REM ./autobuild.bat