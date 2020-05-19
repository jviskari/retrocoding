@echo off

tasm plasma.asm
if errorlevel 1 then goto end:
tlink /t plasma.obj
plasma.com

:end
del *.bak
del *.obj
del *.map
