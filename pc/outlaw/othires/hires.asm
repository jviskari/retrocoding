; High resolution stringwriter
; Part of the Magicware BBS intro
; Call +39 6-52355532 !!!
; Some weird bug might still exist.
; By Vulture / Outlaw Triad

DOSSEG                          ; Sort segment to DOS standards
.MODEL SMALL
.286
.STACK 200h
.DATA
.CODE
JUMPS                           ; Let tasm handle out of range jumps
ASSUME cs:@code,ds:@code

; === Data ===

INCLUDE Font.inc                ; Fontdata

Label Credits Byte
       DB 13,10,"Ü  ÜÜ  ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ  ÜÜ  Ü"
       DB 13,10,"                    - An Outlaw Triad Production (c) 1996 -",13,10
       DB 13,10,"                             CodeùùùùùùùùùùVulture" ,13,10
       DB 13,10,"                            -=ð Outlaw Triad Is ð=-",13,10
       DB 13,10,"          Vulture(code) þ Dazl(artist) þ Troop(sysop) þ Xplorer(artist)",13,10
       DB 13,10,"ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ",13,10,"$"

Label Palette Byte
       DB   0,0,45              ; Background color
       DB   45,45,45            ; Character color

Label Text1 Byte
       DB   '       this file passed magicware',254
       DB   254
       DB   254
       DB   254
       DB   254
       DB   '               distro for',254
       DB   254
       DB   '                valhalla',254
       DB   '              outlaw triad',254
       DB   254
       DB   '           more groups wanted',254
       DB   0

Label Text2 Byte
       DB   254
       DB   254
       DB   254
       DB   '               call us for',254
       DB   254
       DB   '                  demos',254
       DB   '                  music',254
       DB   '                 sources',254
       DB   '                 patches',254
       DB   '                 graphix',254
       DB   254
       DB   '                we got it',254
       DB   0

Label Text3 Byte
       DB   254
       DB   254
       DB   254
       DB   254
       DB   254
       DB   254
       DB   '    press escape for da magic number',254
       DB   254
       DB   '             intro will reset',254
       DB   0

Label TextLabel Word
       DW   offset Text1
       DW   offset Text2
       DW   offset Text3

VgaPos  EQU  80*75              ; Start pos on vga
Counter DW   0
TextP   DW   0                  ; Which text to do

; === Sub-routines ===

WaitVrt PROC NEAR               ; Waits for vertical retrace
    mov     dx,3dah
Vrt:
    in      al,dx
    test    al,1000b
    jnz     Vrt
NoVrt:
    in      al,dx
    test    al,1000b
    jz      NoVrt
    ret
WaitVrt ENDP

SetColor PROC NEAR              ; Needs: cx:=color (0 to 15)
    mov     dx,3ceh             ; Graphic Controller address register port
    mov     ax,0f01h            ; Index 01h  (enable set/reset register)
    out     dx,ax
    xor     al,al               ; Index 00h  (set/reset register)
    mov     ah,cl               ; Color (0 to 15)
    out     dx,ax               ; Set color
    ret
SetColor ENDP

TestEsc PROC NEAR
    in      al,60h              ; Was ESCAPE pressed ?
    cmp     al,1
    je      QuitNow             ; Yes => quit now. . .
    ret
TestEsc ENDP

WriteLine PROC NEAR             ; Writes a textstring to vga-memory
StartWrite:
    lodsb                       ; Load a character from textstring
    cmp     al,254              ; Reached end of line?
    je      UpdatePos
    cmp     al,0                ; Reached end of da text?
    je      QuitPrint
    cmp     al,' '
    jne     short DoChar

    add     di,Xsize            ; Only increase xpos to do
    inc     Counter
    jmp     StartWrite          ; a space

DoChar:
    push    si                  ; Save character offset
    push    di                  ; And save vga-pos

; === Locate char in fontdata ===

    mov     bl,al
    lea     si,[Order]
    xor     cx,cx
Search:
    lodsb                       ; Load char from order
    cmp     bl,al
    je      CharOk
    inc     cx
    jmp     Search
CharOk:
    lea     si,[Font]
    shl     cl,1                ; *2 (coz Xsize is 2)
    xor     ch,ch
    add     si,cx               ; ds:si=upperleft corner char in fontdata

    mov     dx,3ceh             ; Graphic Controller address register port

; === Draw the character ===
    mov     cx,Ysize            ; Do all y-lines
YLoop:
    mov     ah,ds:[si]          ; Load the pattern (8 bits)
    mov     al,08h              ; Index 08h (Bit Mask Register)
    out     dx,ax               ; Pattern selected (if bit=1 then it's drawn)
    movsb                       ; From ds:[si] to es:[di]
    mov     ah,ds:[si]          ; Load the pattern (8 bits)
    out     dx,ax               ; Pattern selected (if bit=1 then it's drawn)
    movsb
    add     si,78               ; Next position in data (lineair)
    add     di,78               ; And next pos on vga
    loop    YLoop

    call    WaitVrt
    call    TestEsc

; === Update pointers ===
    inc     Counter
    pop     di
    add     di,Xsize            ; Next position on screen
    pop     si
    jmp     StartWrite          ; Do next char

UpdatePos:
    sub     di,Counter          ; *2 coz Xsize is 2 bytes
    sub     di,Counter
    add     di,80*(Ysize+5)     ; Update vga-position
    mov     Counter,0
    jmp     StartWrite          ; And do next char

QuitPrint:
    ret
WriteLine ENDP

WaitHere PROC NEAR              ; Simple waitloop
    mov     cx,350
WaitLoop:
    call    WaitVrt
    call    TestEsc
    loop    WaitLoop
    ret
ENDP WaitHere

DeleteText PROC NEAR            ; Guess what this does, eh?  :-)
    xor     cx,cx               ; cx=0
    call    SetColor            ; Set background color

    mov     di,VGAPos
    mov     cx,80               ; Do entire scanline
HoriLoop:
    push    di
    mov     al,0ffh
    mov     bx,358              ; # of scanlines
VertiLoop:
    stosb
    add      di,79              ; Next scanline
    dec      bx
    jnz      VertiLoop
    pop      di
    inc      di                 ; Next position
    call     WaitVrt
    loop     HoriLoop

    mov      cx,1
    call     SetColor           ; Reset character color
    ret
DeleteText ENDP

; === Main program ===

START:

; === Get into 640*480*16 mode ===
    mov     ax,0012h
    int     10h                 ; Simple, eh? ;-)

; === Set segment pointers ===
    mov     ax,cs
    mov     ds,ax               ; ds points to codesegment
    mov     ax,0a000h
    mov     es,ax               ; es points to vga

; === Init palette stuff ===

; I haven't really figured out how
; the palette works in these high
; resolution modes. The code here
; seems to work but I would like
; to know more about it. Anyone
; out there got some more info?
; Btw, major thanx to Iguana for
; providing example code.

    mov     dx,3c0h		; Create a linear palette instead of EGA palette
    xor     al,al               ; Index 00h & data 00h
    mov     cx,2
LinPal:
    out     dx,al   	        ; Index.
    out     dx,al       	; Value => value = index
    inc     al
    loop    LinPal

    mov     al,34h  		; Redo it, activating the VGA along
    out     dx,ax
    xor     al,al
    out     dx,al          	; Force DAC index bits p4-p7 to 0

    lea     si,Palette
    mov     dx,03c8h
    xor     al,al
    out     dx,al
    inc     dx
    mov     cx,2*3              ; 2 colors
    repz    outsb

    mov     cx,1
    call    SetColor

; === Write lines ===
    mov     di,(80*45)+5
    mov     cx,70
    mov     al,0ffh
    rep     stosb
    mov     di,(80*47)+5
    mov     cx,70
    rep     stosb
    mov     di,(80*435)+5
    mov     cx,70
    rep     stosb
    mov     di,(80*437)+5
    mov     cx,70
    rep     stosb

; === Loop intro ===
MainLoop:
    mov     bx,TextP             ; Use bx as pointer
    add     bx,bx
    mov     si,[TextLabel+bx]    ; Load offset current text
    mov     di,VGAPos
    call    WriteLine            ; Write the string
    call    WaitHere             ; Wait a sec
    call    DeleteText           ; And delete the text
    cmp     TextP,2
    je      TheLast
    inc     TextP
    jmp     MainLoop
TheLast:
    mov     TextP,0              ; Text 1 again so we loop the intro
    jmp     MainLoop

; === Back to textmode ===
QuitNow:
    mov     ax,0003h
    int     10h

; === Print string ===
    lea     dx,[Credits]
    mov     ah,9
    int     21h                 ; Who's done it thiz time?

; === Back to DOS ===
    mov     ax,4c00h            ; Return control to DOS
    int     21h

END START                       ; End of program




; - Vulture / Outlaw Triad -
;     comma400@tem.nhl.nl       (at least till june 1996)