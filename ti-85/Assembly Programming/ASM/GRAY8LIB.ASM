
Page2 = $8981
Page3 = $8982
Count = $8980
Page2Addr = $8983
Page3Addr = $8985

GrayScaleOn
        ld hl,($8be5)   ;get end of VAT
        dec hl
        dec hl          ;make sure we're clear it..

           ; now we need to get the position of
           ; the nearest screen boundary

        ld a,h
        sub $8 ;2*1k
        ld h,a
        ld l,0
        push hl

            ;Tests if there is a space for the 3K
            ;needed for the 2nd+3rd screens 

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

        ld a,h
        add a,4
        ld h,a
        ld (Page3Addr),hl

        and %00111111
        ld (Page3),a


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
	ld	hl,$8700	 
	ld	(hl),a		 
	inc	hl		 
	ld	b,0		 
CopyLoop
	ld	(hl),a		 
	inc	hl		 
	djnz	CopyLoop
               

	ld	hl,(PROGRAM_ADDR)	 
	ld	de,Int_Rout 
	add	hl,de		; get the rout we want to be called
        ld      de,$8888        ;where it gets called from
        ld      bc,Int_RoutEnd+1-Int_Rout         
	ldir			; copy it there

        ld a,0
        ld  (Count),a

        ld a,$87
        ld i,a

        im 2
        ret

       
Int_Rout

	ex	af,af'		 
	exx			 

        in a,(3)
        bit 1,a           ; check that it is a vbl interrupt
        jr z,EndInt

        ld a,(Count)
        cp 6
        jr z,Disp_3
        cp 4
        jr c,Disp_1
        jr Disp_2

Disp_1
        inc a
        ld (Count),a
        ld a,$3c
        out (0),a
        jr EndInt
Disp_2
        inc a
        ld (Count),a
        ld a,(Page2)
        out (0),a
        jr EndInt

Disp_3
        ld a,(Page3)
        out (0),a
        sub a
        ld (Count),a
EndInt
	exx			
	ex	af,af'
	jp	$38	
Int_RoutEnd
