;fx.asm

;(c) Tim FitzRandolph, 1996

;This program reverses the screen, using basicaly my own implementation
;of FOR loops.  It isn't very well commented, but it might help some of you out.

;Oh yeah, the Get/Plot/Erase Pixel routines were made by Magnus Hagander.



#include "TI-85.H"

.org 0
.db "=-Special Effects-=",0


xl      = $80DF
yl      = $80E0


Init:
        ld a,4
        out (5),a

        ROM_CALL(CLEARLCD)

        ld a,0
        ld (xl),a
        ld (yl),a


drawtext:
        ld hl,$0A2A             
        ld ($8333),hl
        ld hl,(PROGRAM_ADDR)
        ld de,Text1
        add hl,de
        ROM_CALL(D_ZM_STR)

        ld hl,$1A1A
        ld ($8333),hl
        ld hl,(PROGRAM_ADDR)
        ld de,Text2
        add hl,de
        ROM_CALL(D_ZM_STR)

        ld hl,$3A4A
        ld ($8333),hl
        ld hl,(PROGRAM_ADDR)
        ld de,Text3
        add hl,de
        ROM_CALL(D_ZM_STR)


Yloop:


        CALL_(Xloop)


        ld a,0
        ld (xl),a

        ld a,(yl)
        inc a
        ld (yl),a

        ld a,(yl)
        cp 63
        JUMP_Z(Done)

        JUMP_(Yloop)

Xloop:

        ld a,(xl)
        ld b,a
        ld a,(yl)
        ld c,a

        CALL_(GetPixel)
        or 0
        JUMP_Z(DrawPixel)

        JUMP_(ErasePixel)

donedrawing:

        ld a,(xl)
        inc a
        ld (xl),a

        ld a,(xl)
        cp 128
        ret z


        JUMP_(Xloop)



DrawPixel:
        ROM_CALL(FIND_PIXEL)
        ld de,$FC00
        add hl,de
        or (HL)
        ld (HL),a

        JUMP_(donedrawing)


ErasePixel:
        ROM_CALL(FIND_PIXEL)
        ld de,$FC00
        add hl,de
        xor 255
        and (HL)
        ld (HL),a

        JUMP_(donedrawing)


GetPixel:
        ROM_CALL(FIND_PIXEL)
        ld de,$FC00
        add hl,de
        and (HL)
        ret





Done:
        call GET_KEY
        cp $9
        ret z
        cp $37
        ret z
        JUMP_(Done)



Text1:  .db "Screen Reverser",0
Text2:  .db "Tim FitzRandolph",0
Text3:  .db "press ENTER",0


.end


