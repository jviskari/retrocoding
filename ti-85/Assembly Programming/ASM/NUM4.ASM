;num4.asm

;(c) Tim FitzRandolph, 1996

;This program plots 3 points on the screen, using Magnus Hagander's
;PlotPixel routine.  It will get you familiar with the screen coordinates
;and stuff.

#include "TI-85.H"

.org 0
.db "Example 4",0               ;ZShell menu text


Init:
        ld a,4
        out (5),a       ;set TI-85 to graphics mode.

        ROM_CALL(CLEARLCD)      ;clear the screen.

        ld b,10
        ld c,10
        CALL_(PlotPixel)        ;B = x coordinate, C = y coordinate

        ld b,20
        ld c,20
        CALL_(PlotPixel)

        ld b,100
        ld c,50
        CALL_(PlotPixel)

Wait:
        call GET_KEY
        cp $9
        ret z

        JUMP_(Wait)


PlotPixel:      ;this section of code plots a pixel on the screen, where
                ;B is the X coordinate, and C id the Y coordinate.
                ;P.S. Magnus Hagander created this routine.

        ROM_CALL(FIND_PIXEL)
        ld de,$FC00
        add hl,de
        or (HL)
        ld (HL),a
        ret             ;return to program.



;that's it!

.end


