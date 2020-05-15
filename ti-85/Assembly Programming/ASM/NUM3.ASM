;num3.asm

;(c) Tim FitzRandolph, 1996


;Here is a program that prints out BIG text and menu-size text on the screen.
;The big text is white-on-black.

;NOTE:  when loading x any y positions for big text, you use coordinates just
;like the Outpt() command in TI-BASIC.  for example, a coordinate of $0003
;is equal to row 3, column 0.

;when printing MENU text, however, you use actual screen coordinates, so
; $0300 is actually 3 pixels down, 0 across.


;okay, here we go.

#include "TI-85.H"

.org 0
.db "Example 3",0                 ;ZShell menu text


Init:

        ld a,4          ;set TI-85 to graphics mode
        out (5),a       ;set TI-85 to graphics mode

        ROM_CALL(CLEARLCD)      ;clear the screen


        set 3,(IY+05)                   ;set text to White on Black
        
        ld hl, $0001                    ;X=0,Y=1
        ld ($800C),hl                   ;cursor position = hl
        ld hl, (PROGRAM_ADDR)           ;must do this
        ld de, Text1                    ;load in the text   
        add hl,de                       ;hl is ready to be printed
        ROM_CALL(D_ZT_STR)              ;print (BIG) text              

        res 3,(IY+05)                   ;reset text to Black on White

        ld hl,$3A4A             ;Y = 58 (3A),   X = 74 (4A)
        ld ($8333),hl           ;load hl into cursor position
        ld hl,(PROGRAM_ADDR)    ;must be done when printing text
        ld de,EnterStr1         ;load the text into de
        add hl,de               ;hl now contains the text
        ROM_CALL(D_ZM_STR)      ;print it MENU style


Wait:
        call GET_KEY            ;check for a keypress

        cp $9                   ;ENTER pressed?
        ret z                   ;yes, so exit to ZShell
        
        JUMP_(Wait)             ;if it gets this far, ENTER was
                                ;not pressed, so jump back to Wait and
                                ;try again.




;TEXT USED IN THE PROGRAM

Text1:          .db "--White on Black!!!--",0

EnterStr1:      .db "Press [ENTER]",0


.end



