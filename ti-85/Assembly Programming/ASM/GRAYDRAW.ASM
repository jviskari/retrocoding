#include "ti-85.h"
                                        
CurrentShade    =       text_mem
OldShade        =       CurrentShade+1
yx              =       OldShade+1
PictureAddress  =       yx+2

.org 0
.db "something",0
                          
        ld      a,$c
        ld      ($8082),a
        ld      a,8
        ld      ($8083),a
        ld      de,(PROGRAM_ADDR)
        ld      hl,PicStr
        add     hl,de
        ld      de,$8084
        ld      bc,8
        ldir
        rst     10h
        ret     c
        inc     de
        inc     de
        ld      (PictureAddress),de
;begin wipe
;        ex      de,hl
;        ld      b,8
;w1:
;        push    bc
;        ld      b,0
;w2:
;        xor     a
;        ld      (hl),0
;        inc     hl
;        djnz    w2
;        pop     bc
;        djnz    w1
;        ret
;end wipe
        CALL_(GrayScaleOn)
        ret     c      
        ld      bc,1024
        ld      hl,(PictureAddress)
        ld      de,$fc00
        ldir
        ld      bc,1024
        ld      de,(Page2Addr)
        ldir
        ld      hl,$8c40
        set     0,(hl)
        ld      a,4
        out     (5),a
        ld      hl,$2020
        ld      (yx),hl
        ld      a,3
        ld      (CurrentShade),a
        CALL_(DrawPoint)
MainLoop:
KeyLoop:
        call    get_key
        cp      0
        jr      z,KeyLoop
        cp      1
        JUMP_Z(MoveDown)
        cp      2
        JUMP_Z(MoveLeft)
        cp      3
        JUMP_Z(MoveRight)
        cp      4
        JUMP_Z(MoveUp)
        cp      K_SEcond
        jr      z,Draw
        cp      K_F1
        jr      z,C1
        cp      K_F2
        jr      z,C2
        cp      K_F3
        jr      z,C3
        cp      K_F4
        jr      z,C4
        cp      $37
        jr      nz,KeyLoop
Exit:
        CALL_(DrawPointOld)
        ld      de,(PictureAddress)
        ld      hl,$fc00
        ld      bc,1024
        ldir
        ld      hl,(Page2Addr)
        ld      bc,1024
        ldir
        CALL_(GrayScaleOff)
        ret

Draw:
        ld      a,(CurrentShade)
        ld      (OldShade),a
        jr      MainLoop

C1:
        ld      a,0
        ld      (CurrentShade),a
        CALL_(DrawPoint)
        jr      MainLoop

C2:
        ld      a,1
        ld      (CurrentShade),a
        CALL_(DrawPoint)
        jr      MainLoop

C3:
        ld      a,2
        ld      (CurrentShade),a
        CALL_(DrawPoint)
        JUMP_(MainLoop)

C4:
        ld      a,3
        ld      (CurrentShade),a
        CALL_(DrawPoint)
        JUMP_(MainLoop)

MoveDown:
        CALL_(DrawPointOld)
        ld      bc,(yx)
        dec     c
        ld      (yx),bc
        CALL_(ReadPoint)
        ld      (OldShade),a
        CALL_(DrawPoint)
        JUMP_(MainLoop)

MoveUp:
        CALL_(DrawPointOld)
        ld      bc,(yx)
        inc     c
        ld      (yx),bc
        CALL_(ReadPoint)
        ld      (OldShade),a
        CALL_(DrawPoint)
        JUMP_(MainLoop)

MoveLeft:
        CALL_(DrawPointOld)
        ld      bc,(yx)
        dec     b
        ld      (yx),bc
        CALL_(ReadPoint)
        ld      (OldShade),a
        CALL_(DrawPoint)
        JUMP_(MainLoop)

MoveRight:
        CALL_(DrawPointOld)
        ld      bc,(yx)
        inc     b
        ld      (yx),bc
        CALL_(ReadPoint)
        ld      (OldShade),a
        CALL_(DrawPoint)
        JUMP_(MainLoop)

ReadPoint:
        ld      bc,(yx)
        ROM_CALL(FIND_PIXEL)
        ld      d,0
        push    hl
        ld      bc,$fc00
        add     hl,bc
        ld      e,a
        and     (hl)
        cp      0
        jr      z,RP1
        set     1,d
RP1:
        pop     hl
        ld      bc,(Page2Addr)
        add     hl,bc
        ld      a,e
        and     (hl)
        cp      0
        jr      z,RP2
        set     0,d
RP2:       
        ld      a,d
        ret
        

DrawPoint:
        ld      bc,(yx)
        ld      a,(CurrentShade)
        ld      d,a
        CALL_(GrayPointOn)
        ret

DrawPointOld:
        ld      bc,(yx)
        ld      a,(OldShade)
        ld      d,a
        CALL_(GrayPointOn)
        ret

GrayPointOn:
        push    de
        ROM_CALL(FIND_PIXEL)
        pop     de
        push    hl
        ld      bc,$fc00
        add     hl,bc
        ld      e,a
        bit     1,d
        jr      z,GPOErase1
GPODraw1:
        or      (hl)
        ld      (hl),a
        jr      GPO1Done
GPOErase1:
        xor     255
        and     (hl)
        ld      (hl),a
GPO1Done:
        pop     hl
        ld      bc,(Page2Addr) ;for now.
        add     hl,bc
        ld      a,e
        bit     0,d
        jr      z,GPOErase2
GPODraw2:
        or      (hl)
        ld      (hl),a
        jr      GPO2Done
GPOErase2:
        xor     255
        and     (hl)
        ld      (hl),a
GPO2Done:
        ret

Page2 = $8981
Count = $8980
Page2Addr = $8982

GrayScaleOn
        ld hl,($8be5)   ;get end of VAT
        dec hl
        dec hl          ;make sure we're clear it..

           ; now we need to get the position of
           ; the nearest screen boundary

        ld a,h
        sub 4
        ld h,a
        ld l,0
        push hl

            ;Tests if there is a space for the 1K
            ;needed for the 2nd screen

        ld de,($8be1)
        or a
        sbc hl,de
        pop hl
        jr c,GrayError        

           ;Save out the address of our 2nd Screen

        ld (Page2Addr),hl

           ; test if our block of memory
           ; is within the range addressable
           ; by the LCD hardware

        and %11000000
        cp %11000000
        jr nz,GrayError      

           ; It is, so save out the byte to send to port 0
           ; to switch to our 2nd screen

        ld a,h
        and %00111111
        ld (Page2),a

        CALL_(InstallInterrupt)
        or a            ;clear carry flag - alls OK
        ret

GrayError
        scf            ;set carry flag - Error occured
        ret


GrayScaleOff
        im 1

        ld a,$3c
        out (0),a    ;Set screen back to normal

            ;This is just to clear the
            ;Graph screen, so people don't
            ;Complain about rubbish appearing
            ;On it..

        ld hl,GRAPH_MEM           
        ld d,h                    
        ld e,l                   
        inc de                    
        ld (hl),0
        ld bc,1024
        ldir
        ret

Wait_GrayVBL
        ; Wait for the VBl routine to finish drawing the screen

        ld a,(Count)
        or a
        ret z
        jr Wait_GrayVBL

InstallInterrupt

        ld      a,$088           
        ld      hl,$8700         
        ld      (hl),a           
        inc     hl               
        ld      b,0              
CopyLoop
        ld      (hl),a           
        inc     hl               
        djnz    CopyLoop
               

        ld      hl,(PROGRAM_ADDR)        
        ld      de,Int_Rout 
        add     hl,de           ; get the rout we want to be called
        ld      de,$8888        ;where it gets called from
        ld      bc,Int_RoutEnd+1-Int_Rout         
        ldir                    ; copy it there

        ld a,0
        ld  (Count),a

        ld a,$87
        ld i,a

        im 2
        ret

       
Int_Rout

        ex      af,af'           
        exx                      

        in a,(3)
        bit 1,a           ; check that it is a vbl interrupt
        jr z,EndInt

        ld a,(Count)
        cp 2
        jr z,Disp_2

Disp_1
        inc a
        ld (Count),a
        ld a,$3c
        out (0),a
        jr EndInt
Disp_2
        ld a,(Page2)
        out (0),a
        sub a
        ld (Count),a
EndInt
        exx             
        ex      af,af'
        jp      $38     

Int_RoutEnd
        
PicStr:
        .db     "PICTUREG"
.end



