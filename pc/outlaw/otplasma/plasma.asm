; Plasma in 100% (t)asm
; By Vulture/Outlaw Triad

; Derived from example code by Jare/VangelisTeam

IDEAL
DOSSEG
MODEL SMALL
P386
JUMPS

SEGMENT CODE                    ; Code segment starts
ASSUME cs:code,ds:code          ; Let cs and ds point to code segment

ORG 100h

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ[ Main Program ]ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

START:

    mov     ax,0a000h
    mov     es,ax

    call    Set_Vga

Main_Loop:                      ; Go into mainloop
    call    Do_Plasma
    call    WaitVrt
    in      al,60h              ; Scan keyboard
    cmp     al,1
    jne     Main_Loop           ; Quit on escape

; === Quit to DOS ===
    mov     ax,0003h            ; Back to textmode
    int     10h
    lea     dx,[Credits]
    mov     ah,09h
    int     21h
    ret

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ[ Sub Routines ]ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

PROC WaitVrt
    mov     dx,3dah
Vrt:
    in      al,dx
    test    al,1000b
    jnz     Vrt                 ; Wait until Verticle Retrace starts
NoVrt:
    in      al,dx
    test    al,1000b
    jz      NoVrt               ; Wait until Verticle Retrace ends
    ret
ENDP WaitVrt

PROC Set_Vga
    mov     ax,0013h            ; Videomode 13h  320*200*256
    int     10h                 ; Set the mode

; === Reprogram vga registers ===
    mov     dx,03c4h            ; Sequencer Register
    mov     ax,0604h
    out     dx,ax               ; Disable chain4 bit
    mov     dx,03d4h            ; CrtC register
    mov     ax,0014h
    out     dx,ax               ; Turn off double word mode
    mov     ax,0e317h
    out     dx,ax               ; Turn on byte mode
    mov     ax,04709h
    out     dx,ax               ; Duplicate scanlines

; === Clear VGA memory ===
    mov     dx,03c4h            ; Select port 03c4h
    mov     ax,00f02h           ; Map Mask Register (select all planes)
    out     dx,ax
    mov     ax,0a000h           ; VGA segment
    mov     es,ax
    xor     di,di               ; Set es:di to point to screenmem  di=0
    xor     ax,ax               ; Color to store = usually black = 0
    mov     cx,32768            ; 32768 words * 2 = 65536 bytes = 1 plane
    rep     stosw               ; Clear all 4 planes using wordwrites

; === Set palette ===
    lea     si,[Plasma_Palette]
    mov     dx,03c8h
    xor     al,al
    out     dx,al
    inc     dx
    mov     cx,128*3
    repz    outsb

    ret
ENDP Set_Vga

PROC Do_Plasma
    xor     di,di               ; Reset vga position

    mov     cl,[Co1]            ; Vertical cosine start values
    mov     ch,[Co2]

    mov     ah,50               ; 50 scanlines
@Outer_Plasma:
    push    ax

    mov     dl,[Co3]            ; Horizontal cosine start values
    mov     dh,[Co4]

    mov     ah,80               ; 80 pixels on 1 scanline
@Inner_Plasma:
    mov     al,50               ; Initial value (experiment with thiz!)
    add     al,ah
    xor     bh,bh

    mov     bl,dl               ; Add 4 cosine values
    add     al,[Cosine+bx]
    mov     bl,dh
    add     al,[Cosine+bx]
    mov     bl,cl
    add     al,[Cosine+bx]
    mov     bl,ch
    add     al,[Cosine+bx]
    and     al,01111111b
    stosb                       ; Write resulting value to [es:di]
    add     dl,1
    add     dh,2
    dec     ah                  ; Next pixel on horizontal line
    jnz     @Inner_Plasma

    add     cl,3
    add     ch,4
    pop     ax
    dec     ah                  ; Next horizontal line
    jnz     @Outer_Plasma

    sub     [Co1],4
    add     [Co2],3
    sub     [Co3],2
    add     [Co4],1

    ret
ENDP Do_Plasma

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ[ Data ]ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

INCLUDE "cosine.dat"

Label Credits Byte
        db 13,10,"Ü  ÜÜ  ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ  ÜÜ  Ü"
        db 13,10,"                    - An Outlaw Triad Production (c) 1996 -",13,10
        db 13,10,"                             CodeùùùùùùùùùùVulture" ,13,10
        db 13,10,"                            -=ğ Outlaw Triad Is ğ=-",13,10
        db 13,10,"  Vulture(code) ş Dazl(artist) ş Troop(sysop) ş Xplorer(artist) ş Inopia(code)",13,10
        db 13,10,"ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ",13,10,"$"

Label Plasma_Palette Byte
   i = 0
   rept 32
     db 33,i,i
     i = i + 1
   endm
   rept 32
     db i,i,33
     i = i - 1
   endm
   rept 32
     db i,i,33
     i = i + 1
   endm
   rept 32
     db 33,i,i
     i = i - 1
   endm

Co1  db ?
Co2  db ?
Co3  db ?
Co4  db ?

ENDS CODE                  ; End of codesegment
END START

; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ[ The End ]ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
