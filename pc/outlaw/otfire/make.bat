@echo off

tasm fire.asm
if errorlevel 1 then goto end:
tlink fire.obj
fire.exe

:end
del *.bak
del *.obj
del *.map
