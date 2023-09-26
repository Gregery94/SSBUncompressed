:: windows-drag-here.bat
:: run a batch file for every file supplied
@echo off

set ROM=%1
CALL "%~dp0.ezpatch\scripts\win32.bat"
EXIT /B 0
