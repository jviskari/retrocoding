; A 3d starfield in (t)asm
; By Vulture / Outlaw Triad

DOSSEG                ; Init program
.MODEL SMALL
.STACK 200h
.386
.DATA
.CODE
JUMPS

Label Credits Byte
        db 13,10,"Ü  ÜÜ  ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ  ÜÜ  Ü"
        db 13,10,"                    - An Outlaw Triad Production (c) 1996 -",13,10
        db 13,10,"                             CodeùùùùùùùùùùVulture" ,13,10,13,10
        db 13,10,"                            -=ð Outlaw Triad Is ð=-",13,10
        db 13,10,"         Vulture(code) þ Dazl(artist) þ Troop(sysop) þ Xplorer(artist)",13,10
        db 13,10,"ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ",13,10,"$"

Label Palette Byte
        db  0,0,0       ; Base color black => R,G,B = 0,0,0
        i=63
        REPT 16         ; 16 grey shades (from bright to black)
          db  i,i,i
          i=i-4
        ENDM

Star_3d STRUC           ; Format of star
     X   DW   0         ; X-position of star
     Y   DW   0         ; Y-position of star
     Z   DW   0         ; Z-position of star
     Old DW   0         ; Where to erase old star
Star_3d ENDS

StarSize = 8            ; 4 wordz are 8 bytes

MaxStar equ 250         ; What would thiz be, eh? ;-)

Stars   Star_3d MaxStar DUP (?) ; Array to hold all star data

Speed   equ 1           ; Guess what?

Xoff    equ 160
Yoff    equ 100         ; To center the star on the vga
Zoff    equ 256         ; Z-value at start (distance, try and change this)

Seed    dw  ?           ; Random number seed (obtained from system clock)

; =====================================
;  WaitVrt: Waits for vertical retrace
; =====================================

WaitVrt PROC NEAR                  ; Waits for vertical retrace
    mov     dx,3dah                ; to avoid "snow"
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

; =================================
;  Random: generates random number
;  Input : cx = range
;  Output: dx = random number
; =================================

Random PROC NEAR                   ; Reasonably random (can be improved)
    mov     ax,Seed
    add     ax,1234                ; Add a random number
    xor     al,ah                  ; Shuffle around
    rol     ah,1
    add     ax,4321
    ror     al,1
    xor     ah,al
    mov     Seed,ax
    xor     dx,dx
    div     cx
    ret
Random ENDP

; =================================
;  InitStars: sets variables x,y,z
;             for all stars
; =================================

InitStars PROC NEAR
    xor     si,si
    mov     bx,MaxStar
InitLoop:
    mov     cx,320
    call    Random
    sub     dx,160
    mov     [Stars.x+si],dx        ; Random X (-160..160)
    mov     cx,200
    call    Random
    sub     dx,100
    mov     [Stars.y+si],dx        ; Random Y (-100..100)
    mov     [Stars.z+si],Zoff      ; Reset Z
    add     si,StarSize
    dec     bx
    jnz     InitLoop
    ret
InitStars ENDP

; =========================================
;  CreateStar: sets variables for new star
;  Input : si = pointer to current star
;  Output: variables set
; =========================================

CreateStar PROC NEAR
    mov     cx,320
    call    Random
    sub     dx,160
    mov     [Stars.x+si],dx        ; New random X (-160..160)
    mov     cx,200
    call    Random
    sub     dx,100
    mov     [Stars.y+si],dx        ; New random Y (-100..100)
    mov     [Stars.z+si],Zoff      ; Reset Z
    ret
CreateStar ENDP

; =====================================
;  CalcStars: updates all stars on vga
; =====================================

UpdateStars PROC NEAR
    xor     si,si                  ; First star
    mov     cx,MaxStar             ; Do all
MainStarLoop:
    push    cx

    cmp     [Stars+si].z,0         ; Reached z=0?
    jbe     TermStar               ; If so, then terminate star

    mov     di,[Stars.Old+si]
    mov     byte ptr es:[di],0     ; Delete old star

; === Calc X pos ===
    mov     ax,[Stars.x+si]
    movsx   dx,ah
    shl     ax,8                   ; ax = X * 256
    mov     cx,[Stars.z+si]
    idiv    cx                     ; ax = (X * 256) / Z
    add     ax,Xoff                ; ax = ((X * 256) / Z) + Xoff
    cmp     ax,320                 ; Rangecheck X
    jae     TermStar
    mov     di,ax

; === Calc Y pos ===
    mov     ax,[Stars.y+si]
    movsx   dx,ah
    shl     ax,8                   ; ax = Y * 256
    idiv    cx                     ; ax = (Y * 256) / Z
    add     ax,Yoff                ; ax = ((Y * 256) / Z) + Yoff
    cmp     ax,200                 ; Rangecheck Y
    jae     TermStar
    mov     bx,320
    imul    bx
    add     di,ax

; === Calc color ===               ; Z in range 0..255
    mov     ax,[Stars.z+si]
    mov     cx,16
    idiv    cx

; === Place dot & save vars ===
    mov     byte ptr es:[di],al    ; Place star
    mov     [Stars.Old+si],di      ; Save spot for erasure
    sub     [Stars.z+si],Speed     ; Decrease Z (go towards viewer)
    jmp     short ContinueStar     ; Do next

TermStar:
    call    CreateStar             ; If z=0 or star<>range then create new 1

ContinueStar:
    add     si,StarSize            ; Point to next star
    pop     cx
    loop    MainStarLoop           ; Loop until done

    ret
UpdateStars ENDP

; === Main Program ===

START:

; === Set pointers ===
    mov     ax,cs
    mov     ds,ax                  ; Set ds
    mov     ax,0a000h
    mov     es,ax                  ; Set es

; === Set random seed ===
    xor     ah,ah
    int     1ah
    mov     [Seed],dx              ; Get random seed from clock

; === Init vga ===
    mov     ax,0013h
    int     10h                    ; Vgamode 13h 320*200*256 (1 page)

    lea     si,Palette             ; Set palette
    mov     dx,03c8h
    xor     al,al
    out     dx,al
    inc     dx
    mov     cx,17*3                ; 17 colors
    rep     outsb

; === Do starstuff ===
    call    InitStars              ; Set all variables for stars

MainLoop:
    call    UpdateStars            ; Next frame
    call    WaitVrt                ; Wait for vertical retrace
    in      al,60h                 ; Check for escape
    cmp     al,1
    jne     MainLoop

; === Quit to DOS ===
    mov     ax,0003h               ; Back to textmode
    int     10h
    lea     dx,Credits
    mov     ah,9
    int     21h                    ; Write string
    mov     ax,4c00h               ; Return control to DOS
    int     21h

END START