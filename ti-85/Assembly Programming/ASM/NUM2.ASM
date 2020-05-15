;num2.asm

;(c) Tim FitzRandolph


;This program does the following:
;(1) Clears the screen.
;(2) Prints a message on the screen.
;(3) Waits for pressing of EXIT key.
;(4) Exits to ZShell.

;It is also commented extensively for easy deciphering (how do you spell that?)


#include "TI-85.H"

.org 0
.db "Example 2",0       ;ZShell menu text.


        ROM_CALL(CLEARLCD)      ;clear the screen.

        ld hl,(PROGRAM_ADDR)    ;must be done when printing text.
        ld de,TextStr           ;load in the text to be printed (see below)
        add hl,de               ;hl now comatins the text to be printed.
        ROM_CALL(D_ZT_STR)      ;ti-85.h routine to print text stored in HL.

Wait:
        call GET_KEY            ;get a keypress
        cp $37                  ;EXIT pressed?
        ret z                   ;yep. return to ZShell


        JUMP_(Wait)             ;EXIT not pressed, try again.



;Here is the string to be printed out:
TextStr:
                .db "Wow. Text.",0



;end of code.

.end




