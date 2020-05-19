@echo off

tasm stars3d.asm
if errorlevel 1 then goto end:
tlink stars3d.obj
stars3d.exe

:end
del *.bak
del *.obj
del *.map
