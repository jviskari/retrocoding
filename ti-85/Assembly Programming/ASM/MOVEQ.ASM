;if you have any questions just ask:)



#include "TI-85.H"

 

.org 0

.db "First real attempt",0


;the textscreen goess form 0-20 columns and 0-7 rows in asm
 

	ROM_CALL(CLEARLCD)
Start
	SUB	A	;SUBTRACTS A FROM ITSELF GIVING US 0
	LD	(CURSOR_ROW),a
	ld	(CURSOR_COL),a
keypress	
	ld a, 'Q'
	ROM_CALL(TR_CHARPUT)
	CALL GET_KEY
	CP $37
	ret z
	CP K_UP
	jr 	z,up	;jump to up if the cp is 0-less bytes than JUMP_Z
	CP K_LEFT	;but can only be used if less than 128? bytes
	jr	z,left
	CP K_RIGHT
	jr	z,right
	CP K_DOWN
	jr	z,down
	
	jr	Keypress

Up
	LD a, (CURSOR_ROW)
	CP 0			;if it is all the way up keep there
	jr	z,keypress
	DEC a
	LD (CURSOR_ROW), a
	jr	clearandreturn
Left:
	LD a, (CURSOR_COL)
	CP 0			;all the way left
	jr	z,keypress
	DEC a
	LD (CURSOR_COL), a
	ROM_CALL(CLEARLCD)
	jr	clearandreturn
Right:
	LD a, (CURSOR_COL)
	CP 20
	jr	z,keypress		;all the way right
	inc	a
	LD (CURSOR_COL), a
	jr	clearandreturn
Down:
	LD a, (CURSOR_ROW)
	CP 7
	jr	z,keypress
	inc	a		;rises as screen goes lower!!
	LD (CURSOR_ROW), a
	;no need for jr beacause it will automatically go there:)

clearandreturn
	ROM_CALL(CLEARLCD)
	jr	keypress	

.end
