#INCLUDE "TI-85.H"                      ; Standard...

.ORG 0                                  ; Standard...
.DB "Test program for OS_ calls",0      ; Program's name

        ROM_CALL(CLEARLCD)              ; Clear screen and set cursor to top-
        LD HL,0                         ;       left corner
        LD ($800C),HL                   ;       ;
        LD A,(OS_VER)                   ; Check if OS-85 3.0 or later is
        CP $30                          ;       running (A-$30)
        JR NC,ISVER30                   ;       If Not Carry, jump to ISVER30
        LD HL,NEEDVER30                 ; Display message for non-OS-85 users
        LD DE,(PROGRAM_ADDR)            ;       ;
        ADD HL,DE                       ;       ;
        ROM_CALL(D_ZT_STR)              ;       ;
WAITKEYLOOP:                            ; Wait for [ENTER].  Note the use of
        HALT                            ;       GET_KEY instead of OS_GETKEY.
        CALL GET_KEY                    ;       Since we determined OS-85 is
        CP 9                            ;       not running, OS_GETKEY would
        JR NZ,WAITKEYLOOP               ;       cause the TI-85 to crash.
        RET                             ; Exit to ZShell or whatever shell

ISVER30:
        CALL OS_MENUBAR                 ; Simply draw the "task bar"
        LD HL,OS85LOGO                  ; Copies the small bitmap of the
        LD DE,(PROGRAM_ADDR)            ;       OS-85 logo to the screen
        ADD HL,DE                       ;       starting at $FE02.  The logo
        LD DE,$FE02                     ;       is 15 lines down (B) and 88
        LD B,15                         ;       pixels or 11 bytes wide (C).
        LD C,11                         ;       ;
        CALL OS_SMALLBMP                ;       ;
        LD HL,VERBYTE                   ; Show "OS-85 version byte "
        LD DE,(PROGRAM_ADDR)            ;       ;
        ADD HL,DE                       ;       ;
        ROM_CALL(D_ZT_STR)              ;       ;
        CALL OS_DISPHEX                 ; A still contains the version byte
        LD HL,PAUSEMSG                  ; Show "Press [ENTER]..."
        ADD HL,DE                       ;       ;
        ROM_CALL(D_ZT_STR)              ;       ;
        CALL OS_PAUSE                   ; Simply wait for [ENTER]
        LD A,2                          ; Wait for a line of text to be input
        LD ($800C),A                    ;       from the third text line (02)
        CALL OS_INPSTR                  ;       of the screen
        LD HL,NOTICE                    ; Show the intro window, saying the
        ADD HL,DE                       ;       calc will be shut off
        CALL OS_INFOWINDOW              ;       ;
NOTICEWAIT:                             ; Wait for [MORE] and continue or
        CALL OS_GETKEY                  ;       [EXIT] and quit
        CP $37                          ;       ;
        RET Z                           ;       ;
        CP $38                          ;       ;
        JR NZ,NOTICEWAIT                ;       ;
        CALL OS_POWERDOWN               ; Turn off the TI-85, wait for [ON]
        LD HL,MENU1                     ; Show menu "Continue/Exit to OS-85"
        ADD HL,DE                       ;       ;
        CALL OS_FKEYWINDOW              ;       ;
MENU1LOOP:                              ; Wait for [F1] and continue or [F2]
        CALL OS_GETKEY                  ;       and quit or [EXIT] and quit
        CP $37                          ;       ;
        RET Z                           ;       ;
        CP $34                          ;       ;
        RET Z                           ;       ;
        CP $35                          ;       ;
        JR NZ,MENU1LOOP                 ;       ;
        CALL OS_DRAWSCREEN              ; OS-85 screen (wallpaper & taskbar)
        LD HL,$FC00                     ; Draw a box starting at $FC00 (top-
        LD B,7                          ;       left corner of screen).  Box
        LD C,13                         ;       is 56 pixels or 7 bytes wide
        CALL OS_DRAWBOX                 ;       and 13 lines down.
        LD HL,$0102                     ; Show "Continue" within the box
        LD ($8333),HL                   ;       Note it's the same "Continue"
        LD HL,CONTINUEOPTION            ;       as from the first menu, to
        LD DE,(PROGRAM_ADDR)            ;       save some space.
        ADD HL,DE                       ;       ;
        ROM_CALL(D_ZM_STR)              ;       ;
        LD HL,$0702                     ; Show "Exit" under "Continue"
        LD ($8333),HL                   ;       Again, same "Exit" as from
        LD HL,EXITOPTION                ;       first menu
        ADD HL,DE                       ;       ;
        ROM_CALL(D_ZM_STR)              ;       ;
        LD HL,$FC10                     ; The cursor menu will start just one
        LD B,7                          ;       line ($0010 bytes) below the
        LD C,2                          ;       top of the box.  The cursor
        CALL OS_MENUCURSOR              ;       is just as wide.  2 options.
        CP 1                            ; If option 1 wasn't selected or user
        RET NZ                          ;       pressed [EXIT] (A=0), quit
        LD HL,DONESCREEN                ; Show final info window
        LD DE,(PROGRAM_ADDR)            ;       ;
        ADD HL,DE                       ;       ;
        CALL OS_INFOWINDOW              ;       ;
DONEWAIT:                               ; Wait for [MORE] or [EXIT] then quit
        CALL OS_GETKEY                  ;       ;
        CP $37                          ;       ;
        RET Z                           ;       ;
        CP $38                          ;       ;
        JR NZ,DONEWAIT                  ;       ;
        RET                             ;       ;

NEEDVER30:
.DB "This program needs   "             ; Zero-terminated text
.DB "OS-85 3.0 to run.",0               ;       ;

VERBYTE:
.DB "OS-85 version byte ",0             ; The space at the end is for the HEX
                                        ;       display to be after it
PAUSEMSG:
.DB "Press [ENTER]...",0

NOTICE:                                 ; Information window
.DB 5                                   ; 40 pixels or 5 bytes wide for title
.DB "Welcome",0                         ; Title, zero-terminated
.DB "This is a test program.",0         ; Each line of text (up to 5 total)
.DB "Your calculator will now shut",0   ;       is zero-terminated
.DB "off (after you press [MORE]).",0   ;       ;
.DB "Once it does so, press [ON] to",0  ;       ;
.DB "resume.",0                         ;       ;
.DB 0                                   ; A lone zero to indicate window end

MENU1:                                  ; FKey window
.DB 9                                   ; 72 pixels or 9 bytes wide for title
.DB "Test program menu",0               ; Title, zero-terminated
CONTINUEOPTION:
.DB "Continue",0                        ; This will be F1 (zero-terminated)
EXITOPTION:
.DB "Exit to OS-85",0                   ; F2.  Up to 5 total lines (F1-F5).
.DB 0                                   ; Indicates end of window

DONESCREEN:                             ; Information window, same format as
.DB 5                                   ; above
.DB "Finished!",0
.DB "This test program is done.",0
.DB "If you encountered any",0
.DB "problems, contact Jason Todd",0
.DB "via E-mail.",0
.DB 0

OS85LOGO:
.DB $00,$00,$05,$40,$50,$15,$50,$00,$01,$55,$55 ; OS-85 logo, 11x15 bytes
.DB $00,$00,$0A,$8F,$27,$8A,$A3,$E3,$FC,$AA,$AA
.DB $00,$00,$15,$19,$8C,$D5,$46,$33,$01,$55,$54
.DB $00,$00,$2A,$B1,$98,$4A,$AC,$9B,$28,$AA,$A8
.DB $00,$00,$55,$25,$91,$15,$4C,$1B,$01,$55,$50
.DB $00,$00,$AA,$69,$B2,$A8,$26,$33,$78,$AA,$A0
.DB $00,$01,$55,$45,$B0,$13,$53,$E3,$CC,$55,$40
.DB $00,$02,$AA,$49,$1F,$2B,$26,$31,$86,$AA,$80
.DB $00,$05,$54,$D1,$41,$93,$4C,$18,$16,$55,$00
.DB $00,$0A,$AA,$CB,$29,$A8,$2C,$9A,$A6,$AA,$00
.DB $00,$15,$54,$D2,$11,$15,$4D,$58,$56,$54,$00
.DB $00,$2A,$AA,$C6,$43,$2A,$AC,$9B,$26,$A8,$00
.DB $00,$55,$54,$CC,$66,$55,$46,$31,$8C,$50,$00
.DB $00,$AA,$AA,$78,$3C,$AA,$A3,$E0,$F8,$A0,$00
.DB $01,$55,$55,$01,$01,$55,$50,$04,$01,$40,$00

.END                                    ; Standard...
