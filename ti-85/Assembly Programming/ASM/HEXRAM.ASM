; This program is based on Hexview by Philip Montgomery and Chris Busch

; Example file to demonstrate programming for OS-85
; Press UP/DOWN, +/-, */slash to move through your RAM.
; Pressing ALPHA will show what each byte is.

#INCLUDE "TI-85.H"

MEMLOC =$80DF
TEMPLOC =$80E1
TOGGLE =$80E3

.ORG 0
.DB "Ram viewer by Jason Todd",0

        ROM_CALL(CLEARLCD)
        LD A,(OS_VER)
        CP $20                          ; Check for OS-85 2.0
        JR NC,CONTINUE                  ; or later (Not Carry)
        LD HL,0
        LD ($800C),HL
        LD DE,(PROGRAM_ADDR)
        LD HL,NEEDOS85
        ADD HL,DE
        ROM_CALL(D_ZT_STR)              ; Show "Needs OS-85 2.0"...
WAITKEY:
        CALL GET_KEY                    ; Use GET_KEY and not GETKEY since
        OR A                            ;       we found out OS-85 isn't
        JR Z,WAITKEY                    ;       running after all.
        RET                             ; Exit back to ZShell or whatever

CONTINUE:
        CALL OS_MENUBAR                 ; Simply draw the "task bar"
        LD HL,$3A1D                     ; These 6 lines put the program's
        LD ($8333),HL                   ;       name on the task bar.
        LD HL,PROGRAMTITLE              ;       ;
        LD DE,(PROGRAM_ADDR)            ;       ;
        ADD HL,DE                       ;       ;
        ROM_CALL(D_ZM_STR)              ;       ;
        LD HL,0
        LD (MEMLOC),HL

LOOP:
        LD A,(TOGGLE)
        CP 0
        CALL_Z(DRAWSCREEN)
        CP 1
        CALL_Z(ALPHASCREEN)

PAUSE:
        CALL OS_GETKEY                  ; A good routine, saves batteries...
        CP $30
        JR Z,ALPHA
        CP 1
        JR Z,DOWN
        CP 4
        JR Z,UP
        CP $A
        JR Z,PLUS
        CP $B
        JR Z,MINUS
        CP $C
        JR Z,STAR
        CP $D
        JR Z,SLASH
        CP $37
        RET Z
        JR PAUSE

ALPHA:
        LD A,(TOGGLE)
        LD B,A
        LD A,1
        SUB B
        LD (TOGGLE),A
        JR LOOP

DOWN:
        LD HL,(MEMLOC)
        LD DE,$0010
        ADD HL,DE
        LD (MEMLOC),HL
        JR LOOP

UP:
        LD HL,(MEMLOC)
        LD DE,$FFF0
        ADD HL,DE
        LD (MEMLOC),HL
        JR LOOP

PLUS:
        LD HL,(MEMLOC)
        LD DE,$0100
        ADD HL,DE
        LD (MEMLOC),HL
        JR LOOP

MINUS:
        LD HL,(MEMLOC)
        LD DE,$FF00
        ADD HL,DE
        LD (MEMLOC),HL
        JUMP_(LOOP)

STAR:
        LD HL,(MEMLOC)
        LD DE,$1000
        ADD HL,DE
        LD (MEMLOC),HL
        JUMP_(LOOP)

SLASH:
        LD HL,(MEMLOC)
        LD DE,$F000
        ADD HL,DE
        LD (MEMLOC),HL
        JUMP_(LOOP)

ALPHASCREEN:
        LD HL,$0200
        LD ($8333),HL
        LD C,0
        LD HL,(MEMLOC)
        LD (TEMPLOC),HL
ALPHALINE:
        LD A,1
        LD ($8333),A
        LD HL,(PROGRAM_ADDR)
        LD DE,ALPHATEMP
        ADD HL,DE
        ROM_CALL(D_ZM_STR)
        LD A,($8334)
        SUB 2
        LD ($8334),A
        LD A,0
        LD ($8333),A
        PUSH BC
        LD HL,(TEMPLOC)
        LD B,0
ALPHALOOP:
        LD A,(HL)
        INC HL
        PUSH HL
        PUSH BC
        CALL_(MHEX)
        POP BC
        POP HL
        LD A,B
        INC A
        LD B,A
        CP 16
        JR NZ,ALPHALOOP
        LD A,($8334)
        ADD A,10
        LD ($8334),A
        LD (TEMPLOC),HL
        POP BC
        LD A,C
        INC A
        LD C,A
        CP 7
        JR NZ,ALPHALINE
        RET

DRAWSCREEN:
        LD HL,0
        LD ($800C),HL
        LD C,0
        LD HL,(MEMLOC)
        LD (TEMPLOC),HL
SCREENLINE:
        PUSH BC
        LD A,(TEMPLOC+1)
        CALL_(THEX)
        LD A,(TEMPLOC)
        CALL_(THEX)
        LD A,' '
        CALL_(CHARPUT)
        LD HL,(TEMPLOC)
        LD B,0
DRAWLOOP:
        LD A,(HL)
        INC HL
        PUSH HL
        CALL_(CHARPUT)
        POP HL
        LD A,B
        INC A
        LD B,A
        CP 16
        JR NZ,DRAWLOOP
        LD (TEMPLOC),HL
        POP BC
        LD A,C
        INC A
        LD C,A
        CP 7
        JR NZ,SCREENLINE
        RET

THEX:
        CALL_(HEX1)
        CP $3A
        JR C,THEXCHAR
        SUB $30
THEXCHAR:
        ROM_CALL(TX_CHARPUT)
        CALL_(HEX2)
        CP $3A
        JR C,THEXCHAR2
        SUB $30
THEXCHAR2:
        ROM_CALL(TX_CHARPUT)
        RET

MHEX:
        CALL_(HEX1)
        CP $3A
        JR C,MHEXCHAR
        ADD A,7
MHEXCHAR:
        ROM_CALL(M_CHARPUT)
        CALL_(HEX2)
        CP $3A
        JR C,MHEXCHAR2
        ADD A,7
MHEXCHAR2:
        ROM_CALL(M_CHARPUT)
        RET

HEX1:
        LD B,A
        AND $F0
        RRCA
        RRCA
        RRCA
        RRCA
        ADD A,$30
        RET
HEX2:
        LD A,B
        AND $F
        ADD A,$30
        RET

CHARPUT:
        CP $D6
        JR NZ,CHARPUTCONTINUE
        LD A,'.'
CHARPUTCONTINUE:
        ROM_CALL(TX_CHARPUT)
        RET

ALPHATEMP:
.DB "      .      .      .      ."
.DB "      .      .      .      ."
.DB "      .      .      .      ."
.DB "      .      .      .      ",0

NEEDOS85:
.DB "This program needs   "
.DB "OS-85 2.0 to run...",0

PROGRAMTITLE:
.DB "Hex RAM Viewer by JLT",0

.END
