;mk.asm

;(c) Tim FitzRandolph, 1996



#include "TI-85.H"

.org 0
.db "Multi-Key test thingy",0


;this program demonstrates the easiest way to have multiple keys down an
;once...  you can have up to 8 keys down at a time (this demo uses 4)...  



;by reading the keyboard port directly, and then checking the bits, we can get an idea
;of which keys are pressed.  Its not really accurate, but it makes it easier than using
;counters and stuff (which slows stuff down).  Heres a chart taken from TI-PORTS.TXT
;by Dan Eble, which shows exactly which keys can be pressed with each bit.


;Bit 7 = 1: key pressed is one of { ALPHA x-VAR DEL MORE }
;Bit 6 = 1: key pressed is one of { GRAPH STAT PRGM CUSTOM CLEAR EXIT }
;Bit 5 = 1: key pressed is one of { LOG SIN COS TAN ^ 2nd }
;Bit 4 = 1: key pressed is one of { LN EE ( ) / F1 }
;Bit 3 = 1: key pressed is one of { UP xý 7 8 9 * F2 }
;Bit 2 = 1: key pressed is one of { RIGHT , 4 5 6 - F3 }
;Bit 1 = 1: key pressed is one of { LEFT STO> 1 2 3 + F4 }
;Bit 0 = 1: key pressed is one of { DOWN 0 . (-) ENTER F5}



Init:
        ld a,4
        out (5),a

        ROM_CALL(CLEARLCD)


Loop:

        ROM_CALL(CLEARLCD)      ;clear the screen
        CALL_(DrawTitle)        ;draw title text
        

        ld a,0
        out (1),a       ;send 0 to the keyboard port
        in a,(1)        ;check the keyboard port directly.
        cp 0            ;no keys pressed?
        JUMP_Z(Loop)    ;no keys pressed, so try again.
        bit 6,a         ;EXIT (among others) pressed?
        ret z           ;yep. (exit to ZShell)
        bit 1,a         ;LEFT (among others) pressed?
        push af
        CALL_Z(drawleft);yep.
        pop af
        bit 2,a         ;RIGHT (among others) pressed?
        push af
        CALL_Z(drawright)
        pop af
        bit 3,a         ;UP (among others) pressed?
        push af
        CALL_Z(drawup)  ;yep.
        pop af
        bit 0,a         ;DONW (among other) pressed?
        push af
        CALL_Z(drawdown)
        pop af

        CALL_(Delay)    ;puase, so the screen doesn't flicker so much

        JUMP_(Loop)     ;done checking, loop back to the top


drawleft:
        ld hl,$0303     ;Y=3,X=3
        ld ($800C),hl
        ld hl,(PROGRAM_ADDR)
        ld de,LeftPressed
        add hl,de
        ROM_CALL(D_ZT_STR)
        ret

drawright:
        ld hl,$0D03     ;Y=3,X=13
        ld ($800C),hl
        ld hl,(PROGRAM_ADDR)
        ld de,RightPressed
        add hl,de
        ROM_CALL(D_ZT_STR)
        ret

drawup:
        ld hl,$0901     ;Y=1,X=9
        ld ($800C),hl
        ld hl,(PROGRAM_ADDR)
        ld de,UpPressed
        add hl,de
        ROM_CALL(D_ZT_STR)
        ret

drawdown:
        ld hl,$0805     ;Y=5,X=8
        ld ($800C),hl
        ld hl,(PROGRAM_ADDR)
        ld de,DownPressed
        add hl,de
        ROM_CALL(D_ZT_STR)
        ret


DrawTitle:
        ld hl,$0007
        ld ($800C),hl
        ld hl,(PROGRAM_ADDR)
        ld de,TitleText
        add hl,de
        ROM_CALL(D_ZT_STR)
        ret


Delay:
        ld a,$FF
dloop1:
        dec a
        cp 0
        JUMP_NZ(dloop1)

        ld a,$FF
dloop2:
        dec a
        cp 0
        JUMP_NZ(dloop2)

        ret

        



;strings for the program...

TitleText:       .db "PRESS THE ARROW KEYS",0

LeftPressed:    .db "LEFT",0
RightPressed:   .db "RIGHT",0
UpPressed:      .db "UP",0
DownPressed:    .db "DOWN",0



.end



