;num1.asm


;(c) Tim FitzRandolph, 1996


;This program simply clears the screen, and then waits for the pressing
;of either the ENTER or EXIT keys.
;every line is commented to make it easy to follow.



#include "TI-85.H"              ;this is a file that comes with ZShell, which
                                ;makes several things easier.  always include
                                ;it.

.org 0                  ;need this line.
.db "Example 1",0       ;text to be displayed in ZShell menu screen, 0 terminated.


        ROM_CALL(CLEARLCD)      ;routines in ti-85.h to clear the screen!


Wait:                           ;defines code. like lbl command in TI-BASIC
        call GET_KEY            ;register A now contains the last key press
                                ;(in hexadecimal)
        cp $37                  ;compare keypress to $37 (scancode for EXIT)
        ret z                   ;if they are the same, return to ZShell.
        cp $9                   ;compare keypress to $9 (scancode for ENTER)
        ret z                   ;if they are the same, return to ZShell
        JUMP_(Wait)             ;if the program gets this far, then the user
                                ;has not pressed EXIT or ENTER, so jump (goto)
                                ;Wait and try again!



.end    ;defines end of the code. always leave a blank line after this.


