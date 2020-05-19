@echo off

tasm highres.asm
if errorlevel 1 then goto end:
tlink highres.obj
highres.exe

:end
del *.bak
del *.obj
del *.map
