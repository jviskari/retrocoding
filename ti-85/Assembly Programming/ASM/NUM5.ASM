;num5.asm

;(c) Tim FitzRandolph,1996

;This progam gets a little more complicated.  It is a demo, which allows the
;user to move around a dot on the screen.  it shows the basics of animation.


#include "TI-85.H"

.org 0
.db "Example 5",0               ;ZShell menu text


DotX            = $80DF         ;variable for x position stored in $80DF mem slot.
DotY            = $80E0         ;y is stored in $80E0, which id $80DF + 1.



Init:

        ld a,63
        ld (DotX),a     ;set DotX to 63.

        ld a,30
        ld (DotY),a     ;set DotY to 30.


        ld a,4
        out (5),a               ;set to graphics mode.

        ROM_CALL(CLEARLCD)      ;clear the screen.


TheLoop:                        ;beginning of program loop.
        CALL_(EraseDot)         ;erase the dot.
        JUMP_(KeyTest)          ;get keypresses, possibly move the dot.
afterkeys:
        CALL_(DrawDot)          ;draw the dot.

        JUMP_(TheLoop)          ;loop back to the start!






;CHECK FOR KEYPRESSES TO QUIT, OR MOVE THE DOT.
KeyTest:
        call GET_KEY            ;get a keypress.
        cp $37                  ;EXIT pressed?
        ret z                   ;yep, so exit to ZShell.

        cp $4                   ;UP pressed?
        CALL_Z(moveup)          ;yep, so move dot up.

        cp $1                   ;DOWN pressed?
        CALL_Z(movedown)        ;yep, so move dot down.

        cp $2                   ;LEFT pressed?
        CALL_Z(moveleft)        ;yep, so move dot left.

        cp $3                   ;RIGHT pressed?
        CALL_Z(moveright)       ;yep, so move dot right.


        JUMP_(afterkeys)        ;done with the keys!


moveup:
        ld a,(DotY)     ;load Y position into register A
        inc a
        inc a           ;a = a+2
        ld (DotY),a     ;reload NEW y position into memory slot DotY.
        ret             ;done.

movedown:
        ld a,(DotY)     ;load Y position into A
        dec a
        dec a           ;a = a-2
        ld (DotY),a     ;refresh the memory with new position
        ret             ;done.

moveleft:
        ld a,(DotX)     ;load X position into A
        dec a
        dec a           ;a = a-2
        ld (DotX),a     ;set X position to new number.
        ret             ;done.

moveright:
        ld a,(DotX)
        inc a
        inc a
        ld (DotX),a
        ret             ;done.





;DRAW THE DOT ON THE SCREEN BASED ON X,Y POSITION
DrawDot:
        ld a,(DotX)
        ld b,a          ;B=Xposition
        ld a,(DotY)
        ld c,a          ;C=Yposition
        CALL_(PlotPixel)        ;plot 1st pixel.
        inc C           ;Y = Y+1
        CALL_(PlotPixel)
        inc B           ;X = X+1
        CALL_(PlotPixel)
        dec C           ;Y = Y-1
        CALL_(PlotPixel)
        ret             ;done.


;ERASE THE DOT ON THE SCREEN BASED ON X,Y POSITION
EraseDot:
        ld a,(DotX)
        ld b,a          ;B=Xposition
        ld a,(DotY)
        ld c,a          ;C=Yposition
        CALL_(ErasePixel)        ;plot 1st pixel.
        inc C           ;Y = Y+1
        CALL_(ErasePixel)
        inc B           ;X = X+1
        CALL_(ErasePixel)
        dec C           ;Y = Y-1
        CALL_(ErasePixel)
        ret             ;done.





;plot a point (Magnus' routine)
PlotPixel:
        ROM_CALL(FIND_PIXEL)
        ld de,$FC00
        add hl,de
        or (HL)
        ld (HL),a
        ret


;erase a pixel (Magnus' routine)
ErasePixel:
        ROM_CALL(FIND_PIXEL)
        ld de,$FC00
        add hl,de
        xor 255
        and (HL)
        ld (HL),a
        ret



;thats it!

.end


