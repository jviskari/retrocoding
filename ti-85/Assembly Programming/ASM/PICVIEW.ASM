;picview 2.1;
.org 0
#include TI-85.H

TempContrast = $80df
TempPicture  = $80e5
LastPress    = $80e7
delay	     = $80e9
ifdelay	     = $80ea
adress       = $80eb  ; used to store the adress at which it store
adr2         = $80ed  ; used to store the adress at which it read
endpic       = $80f0  ; (number of pic)-1
table_adress = $80f1  ;the tables that contains the adresses of each pic

Title   .db "Graypic Vwr by EL",38,"FF v2.1",0


Start1        ; this rout copy all the adresses of the pics in the table


  ld hl,$fa6f         ; the start of the vat
  ld (adr2),hl        ; 
  ld hl,table_adress  
  ld b,9              ; we read;for max 9 pic (9*3=27 Ko)
loop:
  ld c,0	
  push hl             ;keep where we store
  ld hl,(adr2)        
  ld a,(hl)
  cp $c               ; test if we read a string
  CALL_NZ(not_found2) ; if not ,make c=1 but continue to be sure that
  dec hl              ; at the end we point to the future var
  ld e,(hl)           
  dec hl
  ld d,(hl)
  ld (adress),de      ; store in de the adress of the string in the mem
  push de              
  dec hl              ; we skip the lenght of the name and the name
             
  ld a,(hl)
  inc a
  ld e,a
  ld d,0
  or a
  sbc hl,de
  ld (adr2),hl              
  ld  de,(VAT_END)     ; be sure that we haven't reached the vat
  CALL cp_hl_de
  jr c,lend1           ; if yes end this rout
  pop de
  ex de,hl             ; hl points to the pic
  inc hl               ; skip 
  inc hl               ; the lenght of the pic
  ld a,(hl)
  or a
  CALL_NZ(not_found2)  ; test if it start with $00
  inc hl
  ld a,(hl)
  cp $7f               ; and by $7f
  CALL_NZ(not_found2)
  pop hl                ; now hl point to the table
  ld a,c                ; if it wasn't a pic don't store the adress
  cp 1                  ; and continue
  jr z,loop
  ld de,(adress)        
  ld a,e
  ld (hl),a
  inc hl
  ld a,d
  ld (hl),a
  inc hl                 ;store the adress of the pic in the table 
  djnz loop
  jr lend
lend1:
  pop de
  pop hl
lend:
  ld a,8
  sub b
  ld (endpic),a           ; now endpic store (number of pic)-1
  cp $ff                  ; test if no pic found 
  jr nz,start
  ROM_CALL(CLEARLCD)
  ld  hl, $0404           
  ld  (CURSOR_ROW), hl 
  ld hl,(PROGRAM_ADDR)
  ld de,picntfond
  add hl,de
  ROM_CALL(D_ZT_STR)
k2loop:
        call GET_KEY
        cp k_exit
        jr nz,k2loop
        ret                     
                        
Start
	ld	a,1
	ld	(delay),a		
	ROM_CALL(CLEARLCD)
   	ld  hl, $0000           
  	ld  (CURSOR_ROW), hl 
	ld hl,(PROGRAM_ADDR)
        ld de,question
        add hl,de
        ROM_CALL(D_ZT_STR)
questionkeyloop
	call GET_KEY
	cp	K_F1
	jr	z,normview
	cp	K_F2
	jr	z,getdelay
	cp	K_EXIT
	jr	z,exiteee
	jr	questionkeyloop
exiteee
	CALL_(GrayScaleOff)
        ret
getdelay
	ld	hl,$0002
	ld	(CURSOR_ROW), hl
	ld hl,(PROGRAM_ADDR)
        ld de,delaystring
        add hl,de
        ROM_CALL(D_ZT_STR)
	ld	hl,(delay)
	ROM_CALL(D_HL_DECI)
getdelaypress
	call GET_KEY
	cp	K_UP
	jr	z,raise
	cp	K_DOWN
	jr	z,lower
	cp	K_ENTER
	jr	z,delaygotten
	cp	K_EXIT
	jr	z,exiteee
	jr	getdelaypress
lower
	ld	a,(delay)
	dec	a
	or	a
	CALL_Z(make1)
	ld	(delay),a
	jr	getdelay
raise
	ld	a,(delay)
	inc	a
	cp	255
	CALL_Z(make254)
	ld	(delay),a
	jr 	getdelay
make254
	ld	a,254
	ret
make1
	ld	a,1
	ret

delaygotten
	ld	a,1
	ld	(ifdelay),a
normview
	ld a,(CONTRAST)
        ld (TempContrast),a
	sub	a
	ld (LastPress),a
	ld (TempPicture),a
	ld hl,(PROGRAM_ADDR)
getpicloop
	CALL_(GrayScaleOn)
        JUMP_C(MemoryError)
	ld a,(TempPicture)
	cp 1
	jr z,PIC1a
	cp 2
	jr z,PIC2a
	cp 3
	jr z,PIC3a
	cp 4
	jr z,PIC4a
	cp 5
	jr z,PIC5a
	cp 6
	jr z,PIC6a
	cp 7
	jr z,PIC7a
	cp 8
	jr z,PIC8a
	cp 9
	jr z,PIC9a
	cp 0
	jr z,PIC0a
PIC0a
	ld hl,(table_adress) ; hl points to the adress of the pic
        jr gotpic
PIC1a        
	ld hl,(table_adress+2)
        jr gotpic
PIC2a
	ld hl,(table_adress+4)
        jr gotpic
PIC3a
	ld hl,(table_adress+6)
        jr gotpic
PIC4a        
	ld hl,(table_adress+8)
        jr gotpic
PIC5a
	ld hl,(table_adress+10)
        jr gotpic
PIC6a
	ld hl,(table_adress+12)
        jr gotpic
PIC7a        
	ld hl,(table_adress+14)
        jr gotpic
PIC8a
	ld hl,(table_adress+16)
        jr gotpic
PIC9a
        ld hl,(table_adress+18)
        
gotpic
        ld a,h           ;
        add a,l          ;Test if hl points to an adress or if it equal 0 
        cp 0             ; 
        jr z,rout1       ;
        inc hl                   ; I think that you can optimise it
        inc hl                   ;
        inc hl                   ;
        inc hl                   ;
        jr rout2
rout1:
        xor a
        ld (temppicture),a
          
        call GET_KEY
  	cp	K_EXIT
  	JUMP_Z(exiteee)
        
        
        JUMP_(getpicloop)        
rout2:
        ld de,$FC00
        ld bc,1024
        ldir
        ld de,(Page2Addr)
        ld bc,1024
        ldir
        ld de,(Page3Addr)
        ld bc,1024
        ldir
MainLoop
	ld	a,(ifdelay)
	cp	1
	JUMP_Z(delaydelay)
	call GET_KEY
        cp $37
        jr z,ExitMain
testrightleft
        cp K_UP
        CALL_Z(upcont)
	cp K_DOWN 
        CALL_Z(downcont)
	cp K_LEFT
	jr z,checklowerbounds
	cp K_RIGHT
	jr z,checkupperbounds
	jr mainloop
upcont
        push	af
	ld      hl,TempContrast
        inc     (hl)            
        ld      a,(TempContrast)       
        out     (2),a           
        pop	af
	ret                     
Downcont
   	push	af
	ld      hl,TempContrast
        dec     (hl)            
        ld      a,(TempContrast)       
        out     (2),a           
	pop	af
	ret
checklowerbounds
	ld	a,1
	ld	(lastpress),a
	ld	a,(TempPicture)
	dec	a
	cp	-1
	CALL_Z(make9)
	ld	(TempPicture),a
	JUMP_(getpicloop)
checkupperbounds
	sub	a
	ld	(lastpress),a
	ld	a,(TempPicture)
	inc	a
	cp	10
	CALL_Z(make0)
	ld	(Temppicture),a
	JUMP_(getpicloop)
make0
	ld	a,0
	ret
make9
	;ld	a,9
	ld a,(endpic)
        ret

exitmain2
        pop	bc
ExitMain
	CALL_(GrayScaleOff)
        ROM_CALL(CLEARTEXT)
	ret
MemoryError
        ROM_CALL(CLEARLCD)
   	ld  hl, $0000           
  	ld  (CURSOR_ROW), hl 
	ld hl,(PROGRAM_ADDR)
        ld de,MemErrorString
        add hl,de
        ROM_CALL(D_ZT_STR)
        jr waitkey_2
        
WaitKey_2
        call GET_KEY
        cp K_Exit
        jr nz,WaitKey_2
        ret

delaydelay
	ld	a,(delay)
	ld	b,a
delayok
	push	bc
	ld 	bc,500
delay2
	dec	bc
	call GET_KEY
	cp	K_EXIT
	jr	z,exitmain2
        cp K_UP
        CALL_Z(upcont)
	cp K_DOWN 
        CALL_Z(downcont)
	ld	a,b
	or	c
	jr	nz,delay2
	pop	bc
delay33				djnz delayok
	jr checkupperbounds
not_found2:
        ld c,1                    ; the sub used in the rout
        ret 
MemErrorString
        .db "Not enough memory",0
question
	.db "[F1] for normal view "
	.db "[F2] for projector   ",0
delaystring
	.db "delay",0
picntfond:
        .db "PIC not found",0
      
        
#include gray8lib.asm

.end
