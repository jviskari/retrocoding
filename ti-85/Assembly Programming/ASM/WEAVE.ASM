;                                          
;                                              
;                                           
;                                          
;                                            

; (c) Tim FitzRandolph, 1996

;Well, I've decided to release the source code to my 1st ZShell game,
;Weave (1.4)...  PLEASE DON'T CUT-AND-PASTE from this code, without giving
;me credit for it!  Well, i guess thats about it, I've added a bunch of
;neat comments, so hopefully you can follow it....

;If this helps you any, please let me know by mailing me at:
;
;timfitz@ix.netcom.com

;thanks!
;-Tim FitzRandolph


#INCLUDE "TI-85.H"

.org 0
.db "Weave 1.4",0               ;ZShell menu text..

;-------------------------------------------;
;  define memory for all the neat variables ;
;-------------------------------------------;


shipx   = $80DF         ;ships X position
shipy   = $80E0         ;ships Y position

wall1x  = $80E1         ;wall X and Y positions
wall1y  = $80E2         
wall2x  = $80E3
wall2y  = $80E4

score   = $80F0         ;self explanatory

walljump =$8101         ;amount of pixels the walls jump each loop


endit   = $8106         ;variable to track quitting
endit2  = $8108         ;variable to track DEATH

;-------------------------------------------;
;  Initialize the game variables and stuff  ;
;-------------------------------------------;
InitGame:

        ld A,4                          ;set the game to graphics mode
        out (5),A

        ld   hl,ZS_BITS
        set  0,(hl)             

        ld A,5                          ;--INITIALIZE VARIABLES--;
        ld (shipy),A                    ;                        ;
        ld A,55                         ;                        ;
        ld (shipx),A                    ;                        ;
                                        ;                        ;
        ld A,8                          ;                        ;
        ld (wall1x),A                   ;                        ;
        ld A,59                         ;                        ;
        ld (wall2x),A                   ;                        ;
                                        ;                        ;
        ld A,60                         ;                        ;
        ld (wall1y),A                   ;                        ;
        ld A,28                         ;                        ;
        ld (wall2y),A                   ;---done initializing----;

        ld hl,0
        ld (score),hl

        ROM_CALL(CLEARLCD)                      ;clear the screen

;-------------------------------------------;
;     Show the title screen and stuff!!     ;
;-------------------------------------------;
TitleScreen:

        set 3,(IY+05)           ;set text to White on Black
        
        ld hl, $0001                    ;Y=1,x=0
        ld ($800C),hl
        ld hl, (PROGRAM_ADDR)
        ld de, blank1
        add hl,de
        ROM_CALL(D_ZT_STR)              ;show +-------------+
        ld hl, $0002                    ;Y=2,X=0
        ld ($800C),hl
        ld hl, (PROGRAM_ADDR)
        ld de, weavetitle
        add hl,de
        ROM_CALL(D_ZT_STR)              ;show |   Weave 1.4  |
        ld hl, $0003                    ;Y=3,X=0
        ld ($800C),hl
        ld hl, (PROGRAM_ADDR)
        ld de, blank2
        add hl,de
        ROM_CALL(D_ZT_STR)              ;show +-------------+

        res 3, (IY+05)          ;reset text to Black on White

        ld hl, $2C1A                    ;Y=2C,X=1A
        ld ($8333), hl
        ld hl, (PROGRAM_ADDR)
        ld de,author
        add hl,de
        ROM_CALL(D_ZM_STR)              ;print author text(menu style)

        ld hl, $384C                    ;Y=38,X=4C         
        ld ($8333), hl
        ld hl, (PROGRAM_ADDR)
        ld de,enterstring
        add hl,de
        ROM_CALL(D_ZM_STR)

WaitKey1:                               ;wait for press of enter key
        call GET_KEY
        cp $09                  ;is ENTER pressed?
        jr z,SpeedScreen        ;yes, so jump to SpeedScreen
        jr WaitKey1             ;no, so try again.

;-------------------------------------------;
;     Show the title screen and stuff!!     ;
;-------------------------------------------;
SpeedScreen:

        ROM_CALL(CLEARLCD)              ;clear the screen

        ld hl, $012A                    ;Y=1,X=2A       
        ld ($8333), hl
        ld hl, (PROGRAM_ADDR)
        ld de,weavetext
        add hl,de
        ROM_CALL(D_ZM_STR)              ;display "W  E  A  V  E" (menu style)

        ld hl, $0A1F            
        ld ($8333), hl
        ld hl, (PROGRAM_ADDR)
        ld de,howfast
        add hl,de
        ROM_CALL(D_ZM_STR)              ;display "HOW FAST?"

        ld hl, $142C            
        ld ($8333), hl
        ld hl, (PROGRAM_ADDR)
        ld de,speeds1
        add hl,de
        ROM_CALL(D_ZM_STR)              ;display "MASTER"
        ld hl, $1A2C           
        ld ($8333), hl
        ld hl, (PROGRAM_ADDR)
        ld de,speeds2
        add hl,de
        ROM_CALL(D_ZM_STR)              ;display "GOOD"
        ld hl, $202C            
        ld ($8333), hl
        ld hl, (PROGRAM_ADDR)
        ld de,speeds3
        add hl,de
        ROM_CALL(D_ZM_STR)              ;i forget what it says here...
        ld hl, $262C           
        ld ($8333), hl
        ld hl, (PROGRAM_ADDR)
        ld de,speeds4
        add hl,de
        ROM_CALL(D_ZM_STR)              ;and here 

        jr SpeedLoop        ;wait for the user's choice



;-------------;
;-------------;
SpeedLoop:
        call GET_KEY            ;check for a keypress
        cp $35                  ;is F1 pressed?
        jr z,speed1              ;yep, so set the speed

        cp $34                  ;is F2 pressed?
        jr z,speed2               ;yep, so set the speed

        cp $33                  ;is F3 pressed?
        jr z,speed3               ;yep, so set the speed

        cp $32                  ;is F4 pressed?
        jr z,speed4               ;yep, so set the speed

        jr SpeedLoop            ;loop back if no key pressed.


speed1:         ;user chose fastest speed.
        ld A,4
        ld (walljump),A         ;walls will jump 4 pixels each game loop

        jr HowScreen

speed2:         ;user chose fast speed.
        ld A,3                  ;walls will jump 3 pixels each game loop
        ld (walljump),A

        jr HowScreen

speed3:         ;user chose average speed.
        ld A,2
        ld (walljump),A

        jr HowScreen

speed4:         ;user chose slow speed.
        ld A,1
        ld (walljump),A

        jr HowScreen


;-------------------------------------------;
;  Explain to the user the keys and stuff   ;
;-------------------------------------------;
HowScreen:
        ROM_CALL(CLEARLCD)              ;clear the screen

        ld hl, $012A   
        ld ($8333), hl
        ld hl, (PROGRAM_ADDR)
        ld de,weavetext
        add hl,de
        ROM_CALL(D_ZM_STR)              ;diaplay "W E A V E"

        ld hl, $0A2A           
        ld ($8333), hl
        ld hl, (PROGRAM_ADDR)
        ld de,howtoplay
        add hl,de
        ROM_CALL(D_ZM_STR)

        ld hl, $1424            
        ld ($8333), hl
        ld hl, (PROGRAM_ADDR)
        ld de,keys1
        add hl,de
        ROM_CALL(D_ZM_STR)
        ld hl, $1A24           
        ld ($8333), hl
        ld hl, (PROGRAM_ADDR)
        ld de,keys2
        add hl,de
        ROM_CALL(D_ZM_STR)
        ld hl, $2024            
        ld ($8333), hl
        ld hl, (PROGRAM_ADDR)
        ld de,keys3
        add hl,de
        ROM_CALL(D_ZM_STR)


WaitKey2:
        call GET_KEY            ;get keypress
        cp $37          ;EXIT pressed?
        ret z           ;yep, so quit to ZShell
        cp $9           ;ENTER pressed?
        jr z,TheGame    ;yep, so goto the game
        jr WaitKey2     ;nothing pressed, try again



;-------------------------------------------;
;  THE ACTUAL GAME STARTS HERE!!! HOORAY!   ;
;-------------------------------------------;
TheGame:

        ROM_CALL(CLEARLCD)              ;clear the screen

;\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

GameLoop:                               ;the actual game loop

        CALL_(EraseShip)                ;erase the player
        CALL_(EraseWalls)               ;erase the walls
        CALL_(KeyTest)                  ;test for keypresses

        ld A,(endit)                    ;time to quit?
        cp 1
        JUMP_Z(EndScreen)               ;yep!

        CALL_(DrawShip)                 ;draw the player
        CALL_(MoveWalls)                ;move the walls down
        CALL_(DrawWalls)                ;draw the walls
        CALL_(CheckDeath)               ;see if the player is dead
        ld A,(endit2)
        cp 1                            ;player dead for reals?
        JUMP_Z(EndScreen)               ;okay, quit!

        CALL_(Delay)                    ;pause for a bit
        jr GameLoop                             ;loop back to the top

;\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/





;------------------\
EraseShip:
        ld A,(shipx)
        ld B,A
        ld A,(shipy)
        ld C,A

        CALL_(ErasePixel)
        dec C
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        dec B
        dec B
        CALL_(ErasePixel)

        ret
;-------------------/



;------------------\
DrawShip:
        ld A,(shipx)
        ld B,A
        ld A,(shipy)
        ld C,A

        CALL_(PlotPixel)
        dec C
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        dec B
        dec B
        CALL_(PlotPixel)

        ret
;-------------------/


;------------------\
EraseWalls:
        ld A,(wall1x)
        ld B,A
        ld A,(wall1y)
        ld C,A
        CALL_(eraseloop)


        ld A,(wall2x)
        ld B,A
        ld A,(wall2y)
        ld C,A
        CALL_(eraseloop)

        ret
;-------------------/
eraseloop:
        CALL_(ErasePixel)       ;this could have been done with a loop,
        inc B                   ;but at the time I didn't want to figure
        CALL_(ErasePixel)       ;it all out, so i did it the long way.....
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)
        inc B
        CALL_(ErasePixel)       ;thats one big wall!
        ret

;------------------\
DrawWalls:
        ld A,(wall1x)
        ld B,A
        ld A,(wall1y)
        ld C,A
        ld h,0
        CALL_(drawloop)


        ld A,(wall2x)
        ld B,A
        ld A,(wall2y)
        ld C,A
        ld h,0
        CALL_(drawloop)

        ret
;-------------------/
drawloop:
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        CALL_(PlotPixel)
        inc B
        ret

;------------------\
MoveWalls:
        ld A,(wall1y)
        ld B,A
        ld A,(walljump)
        cp $01                  ;jump 1 pixel?
        CALL_Z(move1)
        cp $02                  ;jump 2 pixels?
        CALL_Z(move2)
        cp $03                  ;3?
        CALL_Z(move3)
        cp $04                  ;4?!?
        CALL_Z(move4)
        ld (wall1y),A

        ld B,A
        ld A,0          ;wall all the way down???
        cp B
        CALL_Z(reset1)  ;yep, so reset to the top!
        ld A,1
        cp B
        CALL_Z(reset1)
        ld A,2
        cp B
        CALL_Z(reset1)
        ld A,3
        cp B
        CALL_Z(reset1)


        ld A,(wall2y)
        ld B,A
        ld A,(walljump)
        cp $01
        CALL_Z(move1)
        cp $02
        CALL_Z(move2)
        cp $03
        CALL_Z(move3)
        cp $04
        CALL_Z(move4)
        ld (wall2y),A

        ld B,A
        ld A,0
        cp B
        CALL_Z(reset2)
        ld A,1
        cp B
        CALL_Z(reset2)
        ld A,2
        cp B
        CALL_Z(reset2)
        ld A,3
        cp B
        CALL_Z(reset2)

        ret

move1:
        ld A,B
        dec A   ;move down 1
        ret

move2:
        ld A,B
        dec A   ;move down 2...
        dec A
        ret

move3:
        ld A,B
        dec A   ;3....
        dec A
        dec A
        ret

move4:
        ld A,B
        dec A   ;or 4.
        dec A
        dec A
        dec A
        ret


reset1:
        ld A,63
        ld (wall1y),A   ;reset to the top
        ld A,(wall1x)
        cp $125
        CALL_Z(res1)
        inc a           ;add some to the x
        inc a
        inc a
        inc a
        inc a
        ld (wall1x),A
        ret

res1:
        ld a,0
        ld (wall1x),a
        ret
reset2:
        ld a,63
        ld (wall2y),A
        ld A,(wall2x)
        cp $4
        CALL_Z(res2)
        dec a
        dec a
        dec a
        dec a
        dec a
        dec a
        dec a
        dec a
        ld (wall2x),A
        ret

res2:
        ld a,127
        ld (wall2x),a
        ret



;------------------\
KeyTest:
        ld a,0
        out (1),a
        in a,(1)
        cp 0            ;no keys pressed?
        ret z           ;nope. back to game.
        bit 6,a         ;EXIT (among others) pressed?
        push af
        CALL_Z(QUIT)    ;yep.
        pop af
        bit 1,a         ;LEFT (among others) pressed?
        push af
        CALL_Z(moveleft);yep.
        pop af
        bit 2,a         ;RIGHT (among.. you get the idea.)
        push af
        CALL_Z(moveright)
        pop af

        ret
;-------------------/


QUIT:
        ld A,1          ;set quit variable to 1...
        ld (endit),A
        ret


;------------------\
moveleft:
        ld A,(shipx)
        dec A           ;move ship 3 to the left
        dec A
        dec a
        ld (shipx),a
        ret
;-------------------/


;------------------\
moveright:              
        ld A,(shipx)    ;3 to the right
        inc A
        inc A
        inc a
        ld (shipx),a
        ret
;-------------------/




;This routine was taken from Magnus Hagander's Useful Zshell Routines page..
;THANK YOU MAGNUS!!!!!!

PlotPixel:
        ROM_CALL(FIND_PIXEL)
        ld de,$FC00
        add hl,de
        or (HL)
        ld (HL),A
        ret


;This routine was taken from Magnus Hagander's Useful Zshell Routines page..
;THANK YOU MAGNUS!!!!!!

ErasePixel:
        ROM_CALL(FIND_PIXEL)
        ld de,$FC00
        add hl,de
        xor 255
        and (HL)
        ld (HL),A
        ret


;this delay routine is very similar to the one in Mel Tsai's Columns2.asm
;source file.  THANKS! I never would of thought of this for a delay!!!
;THANKS AGAIN!!

Delay:
        ld a,$3F
        ld b,$3F
dloop:
        dec a
        jr nz,dloop
        dec b
        jr nz,dloop
        ret



;This routine was taken from Magnus Hagander's Useful Zshell Routines page..
;THANK YOU MAGNUS!!!!!!

GetPixel:
        ROM_CALL(FIND_PIXEL)
        ld de,$FC00
        add hl,de
        and (hl)
        ret


CheckDeath:
        ld a,(shipy)
        inc a
        inc a
        ld c,a
        ld a,(shipx)
        inc a
        ld b,a

        CALL_(GetPixel)         ;is there a pixel above the ship?
        or 0
        JUMP_NZ(DIE)            ;if so, DIE!


        ld a,(shipy)
        inc a
        inc a
        inc a
        ld c,a
        ld a,(shipx)
        inc a
        ld b,a

        CALL_(GetPixel)
        or 0
        JUMP_NZ(DIE)

        ld a,(shipy)
        inc a
        inc a
        inc a
        inc a
        ld c,a
        ld a,(shipx)
        inc a
        ld b,a

        CALL_(GetPixel)
        or 0
        JUMP_NZ(DIE)

        ret

DIE:
        ROM_CALL(CLEARLCD)      ;clear the screen...
        set 3,(IY+05)

        ld hl, $0001                    ;draw more text....
        ld ($800C), hl
        ld hl, (PROGRAM_ADDR)
        ld de,thanx1
        add hl,de
        ROM_CALL(D_ZT_STR)

        res 3,(IY+05)
        ld hl, $152A
        ld ($8333),hl
        ld hl, (PROGRAM_ADDR)
        ld de, die1
        add hl,de
        ROM_CALL(D_ZM_STR)
        ld hl, $3A25
        ld ($8333),hl
        ld hl,(PROGRAM_ADDR)
        ld de, die2
        add hl,de
        ROM_CALL(D_ZM_STR)
WaitLoopEnd:
        call GET_KEY
        cp $9
        jr z,nextend
        jr WaitLoopEnd

nextend:
        ld A,1
        ld (endit2),A
        ret

;------------------------------;
; Thank you screen and stuff   ;
;------------------------------;
EndScreen:

        ROM_CALL(CLEARLCD)      ;more neat text screens....

        set 3,(IY+05)

        ld hl, $0001
        ld ($800C), hl
        ld hl, (PROGRAM_ADDR)
        ld de,thanx1
        add hl,de
        ROM_CALL(D_ZT_STR)

        res 3,(IY+05)

        ld hl, $0003
        ld ($800C), hl
        ld hl, (PROGRAM_ADDR)
        ld de,thanx2
        add hl,de
        ROM_CALL(D_ZT_STR)

        ld hl, $0005
        ld ($800C), hl
        ld hl, (PROGRAM_ADDR)
        ld de,thanx3
        add hl,de
        ROM_CALL(D_ZT_STR)

        ld hl, $0006
        ld ($800C), hl
        ld hl, (PROGRAM_ADDR)
        ld de,thanx4
        add hl,de
        ROM_CALL(D_ZT_STR)

WaitKey5:
        call GET_KEY
        cp $09
        jr z,ENDITOKAY
        jr WaitKey5

        
ENDITOKAY:
        ret z



;Here is all of the text in the game..... PLEASE DO NOT CHANGE ANY OF THIS
;STUFF!!!!! (although you can change the difficulty settings if you want..

blank1:                 .db "+-------------------+",0
blank2:                 .db "+-------------------+",0
weavetitle:             .db "|     Weave 1.4     |",0
author:                 .db "By:  Tim FitzRandolph",0
enterstring:            .db "press [ENTER]",0
scorestr:               .db "score:",0
                    
weavetext:              .db "W      E     A     V    E",0
howfast:                .db "Choose your ability.",0
speeds1:                 .db "F1) Master",0
speeds2:                 .db "F2) Good",0
speeds3:                 .db "F3) Average",0
speeds4:                 .db "F4) Pathetic",0

howtoplay:               .db "HOW  TO  PLAY",0
keys1:                   .db "LEFT - move left",0
keys2:                   .db "RIGHT- move right",0
keys3:                   .db "EXIT - quit",0

thanx1:         .db " W  E  A  V  E   1.4 ",0
thanx2:         .db "  SPECIAL THANKS TO  ",0
thanx3:         .db "  Magnus Hagander!!  ",0
thanx4:         .db "       Mel Tsai      ",0


blank:          .db "                  ",0
die1:           .db "    C R A S H !   ",0
die2:           .db "   press  [ENTER] ",0


;OH BOY! THE END!!! YEAH!!

.end

