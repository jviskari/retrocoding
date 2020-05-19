; Fire effect in (t)asm
; By Vulture / Outlaw Triad

DOSSEG
.MODEL SMALL
.STACK 200h           ; 512 byte stack
.286
.DATA                 ; Empty
.CODE
JUMPS

; === Data starts here ===

Label Palette Byte
     db 0,0,0         ; Base color
     d = 0
     REPT 31          ; Create red-scale for fire (can be improved)
        db  d,0,5
        db  d,0,6
        db  d,0,7
        d = d + 2
     ENDM

; === VGA registers ===

Seq_Index   = 03C4h   ; Sequencer Registers Adress  ( for memory mode, etc  )
CrtC_Index  = 03D4h   ; CRTC Adress Register ( for max scanline, vert retrace )

; === Other variables ===

Label Credits Byte
         db 13,10,"‹  ‹‹  ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹  ‹‹  ‹"
         db 13,10,"                    - An Outlaw Triad Production (c) 1996 -",13,10
         db 13,10,"                             Code˘˘˘˘˘˘˘˘˘˘Vulture" ,13,10,13,10
         db 13,10,"                            -= Outlaw Triad Is =-",13,10
         db 13,10,"    Vulture(code) ˛ Dazl(gfx) ˛ Troop(sysop) ˛ Kr'33(code) ˛ Xplorer(artist)",13,10
         db 13,10,"‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹",13,10,"$"

Seed     dw   ?       ; Any number for randomness (obtained from system clock)

Xsize    equ  80      ; Number of pixels on 1 scanline / 4 (in unchained mode)
Ysize    equ  100     ; Ysize

Virtual  db Xsize*Ysize DUP (0) ; To hold all data

; === Sub-routines ===

SetVGA PROC NEAR
; === Set normal Mode 13h ===
    mov     ax,0013h         ; Lineair videomode 13h  320*200*256
    int     10h              ; Set the mode

; === Disable chain4 bit ===
    mov     dx,Seq_Index     ; Sequencer Address Register
    mov     ax,0604h         ; 06h = 00000110b
    out     dx,ax            ; Disable chain4 mode & enable extended memory

; === Disable word / enable byte mode ===
    mov     dx,CrtC_Index
    mov     ax,00014h        ; Underline Location (disable dword mode)
    out     dx,ax
    mov     ax,0e317h        ; Mode Control (enable byte mode)
    out     dx,ax

; === Clear display memory ===
    mov     dx,Seq_Index     ; Select port 03c4h
    mov     ax,00f02h        ; Map Mask Register (select all planes)
    out     dx,ax
    xor     di,di            ; Set es:di to point to screenmem  di=0
    xor     ax,ax            ; Color to store = usually black = 0
    mov     cx,32768         ; 32768 words * 2 = 65536 bytes = 1 plane
    rep     stosw            ; Clear all 4 planes using wordwrites

; === Set scanline register ===
    mov     ax,4109h         ; Duplicate each scan 2 times (normal)
    out     dx,ax            ; (set 4009 to get into 320*400 mode)

; === Setup palette ===
    lea     si,Palette       ; Load offset palette data
    mov     dx,03c8h         ; Write palette register
    xor     al,al            ; Start writing at 0
    out     dx,al
    mov     cx,94*3          ; # of rgb values to shift
    mov     dx,03c9h         ; Data register
    rep     outsb

    ret
SetVGA ENDP

WaitVrt PROC NEAR
    mov     dx,3dah
Vrt:
    in      al,dx
    test    al,1000b
    jnz     Vrt              ; Wait until Verticle Retrace starts
NoVrt:
    in      al,dx
    test    al,1000b
    jz      NoVrt            ; Wait until Verticle Retrace ends
    ret                      ; Return to main program
WaitVrt ENDP

; =================================
;  Random: generates random number
;  Input : cx = range
;  Output: dx = random number
; =================================

Random PROC NEAR             ; Reasonably random (can be improved)
    mov     ax,Seed
    add     ax,1234
    xor     al,ah
    rol     ah,1             ; Rotate left
    add     ax,4321
    ror     al,2             ; Rotate right
    xor     ah,al
    mov     Seed,ax
    xor     dx,dx
    div     cx
    ret
Random ENDP

; === Main program ===

START:

    cld                                 ; Clear direction flag

; === Set pointers ===
    mov     ax,cs
    mov     ds,ax
    mov     ax,0a000h
    mov     es,ax

; === Set random seed ===
    xor     ah,ah
    int     1ah
    mov     [Seed],dx                   ; Get random seed from clock

; === Setup screen ===
    call    SetVGA                      ; Setup unchained vga-screen

MainLoop:

; === Put new row on bottom virtual screen ===
    mov     si,offset [Virtual]
    add     si,(Xsize*Ysize)-Xsize      ; si:=start last row
    mov     bx,Xsize
    xor     dx,dx
DoLine:
    mov     cx,85
    call    Random                      ; Generate random number
    mov     byte ptr ds:[si],dl
    inc     si                          ; Next cel (Xsize cels to do)
    dec     bx
    jnz     DoLine

; === Create Fire Effect ===
    mov     si,offset [Virtual]
    add     si,Xsize+1                  ; Start at second line
    mov     cx,(Xsize*Ysize)-Xsize-1
DoFire:
    xor     ax,ax                       ; Reset to 0

; === 3 pixels above current pix ===
    add     al,byte ptr ds:[si-Xsize-1]
    adc     ah,0                        ; Add with carry
    add     al,byte ptr ds:[si-Xsize+1]
    adc     ah,0
    add     al,byte ptr ds:[si-Xsize]
    adc     ah,0
; === 2 pixels besides current pix ===
    add     al,byte ptr ds:[si-1]
    adc     ah,0
    add     al,byte ptr ds:[si+1]
    adc     ah,0
; === 3 pixels under current pix ===
    add     al,byte ptr ds:[si+Xsize-1]
    adc     ah,0
    add     al,byte ptr ds:[si+Xsize]
    adc     ah,0
    add     al,byte ptr ds:[si+Xsize+1]
    adc     ah,0

; === Divide by 3+2+3=8 to average ===
    shr     ax,3
    jz      Zero
    dec     ax
Zero:
    mov     byte ptr ds:[si-Xsize],al   ; 4 pixels are filled at a time
    inc     si                          ; due to unchained vga-screen
    loop    DoFire

; === Bring it all to VGA ===
    call    WaitVrt                     ; Wait for retrace
    mov     si,offset [Virtual]
    mov     cx,(Xsize*Ysize)/2
    mov     di,80*106                   ; Save first 106 lines and store
    rep     movsw                       ; bottomlines in offscreen memory !!!

; === Scan keyboard and loop ===
    in      al,60h                      ; Scan keyboard
    cmp     al,1                        ; Test on ESCAPE
    jne     MainLoop                    ; Continue if not pressed

; === Back to DOS ===
    mov     ax,0003h
    int     10h                         ; Get into 80x25 text mode
    mov     ah,9
    lea     dx,Credits
    int     21h                         ; Print string
    mov     ax,4c00h
    int     21h                         ; Return control to DOS

END START                               ; The End


; Thanx to all people who have released fire-code before I did.

;    -Vulture / Outlaw Triad