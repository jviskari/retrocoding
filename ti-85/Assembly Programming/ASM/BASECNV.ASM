; implement:
; - base lookup on key
; - cursor in input (|)
; - speed up Mult32,Div32,Add32

#include "TI-85.h"

	.org	0
txtTitle:
	.db	"BaseConverter 1.0",0

CURSOR_YPOS		= TEXT_MEM	; BYTE
OLD_CURSOR_YPOS		= TEXT_MEM+1	; BYTE
INPUT_BASE		= TEXT_MEM+2	; BYTE
OUTPUT_BASE		= TEXT_MEM+3	; BYTE
INPUT_CURSOR_XPOS	= TEXT_MEM+4	; BYTE
INPUT			= TEXT_MEM+5	; LONG
arg1			= TEXT_MEM+9	; LONG
arg2			= TEXT_MEM+13	; LONG
res1			= TEXT_MEM+17	; LONG
tmp			= TEXT_MEM+21	; LONG

	ld	a,4
	out	(5),a
	ROM_CALL(CLEARLCD)

	ld	bc,$0c0c
	ld	(CURSOR_YPOS),bc
	ld	bc,$100a
	ld	(INPUT_BASE),bc
	ld	a,0
	ld	(INPUT_CURSOR_XPOS),a

	ld	de,(PROGRAM_ADDR)

	ld	bc,$0001
	ld	hl,txtTitle
	CALL_(	DispText)

	ld	hl,txtAuthor
	add	hl,de
	ROM_CALL(D_ZM_STR)

	ld	bc,$0c05
	ld	hl,txtInputBase
	CALL_(	DispText)

	ld	bc,$1805
	ld	hl,txtInput
	CALL_(	DispText)

	ld	bc,$2405
	ld	hl,txtOutputBase
	CALL_(	DispText)

	ld	bc,$3005
	ld	hl,txtOutput
	CALL_(	DispText)

	ld	bc,$e03F
	ld	(VIDEO_MEM+391),bc
	ld	bc,$e03F
	ld	(VIDEO_MEM+775),bc

	ld	hl,$1205
	ld	(CURSOR_X),hl
	ld	a,(INPUT_BASE)
	ld	ix,VIDEO_MEM+295
	CALL_(	UpdateBase)

	ld	hl,$2a05
	ld	(CURSOR_X),hl
	ld	a,(OUTPUT_BASE)
	ld	ix,VIDEO_MEM+679
	CALL_(	UpdateBase)

UpdateCursor:
	ld	a,(OLD_CURSOR_YPOS)
	ld	b,a
	ld	c,1
	ld	de,(PROGRAM_ADDR)
	ld	hl,txtClearCursor
	CALL_(	DispText)
	ld	a,(CURSOR_YPOS)
	ld	(CURSOR_Y),a
	ld	(OLD_CURSOR_YPOS),a
	ld	a,1
	ld	(CURSOR_X),a
	ld	a,5
	ROM_CALL(M_CHARPUT)

KeyLoop:
	call	GET_KEY
	cp	K_EXIT
	JUMP_Z(	Exit)
	cp	K_CLEAR
	CALL_Z(	ClearInput)
	cp	K_MORE
	JUMP_Z(	FastExit)
	cp	K_ENTER
	jr	z,KeyDown
	cp	K_SECOND
	CALL_Z(	UpdateOutput)
	cp	K_UP
	jr	z,KeyUp
	cp	K_DOWN
	jr	z,KeyDown
	cp	K_LEFT
	jr	z,KeyLeft
	cp	K_RIGHT
	JUMP_Z(	KeyRight)
	cp	K_DEL
	JUMP_Z(	KeyDel)
	cp	0
	JUMP_NZ(KeyDigit)
	jr	KeyLoop

KeyUp:
	ld	a,(CURSOR_YPOS)
	cp	$0c
	jr	z,KeyLoop
	sub	12
	ld	(CURSOR_YPOS),a
	jr	UpdateCursor

KeyDown:
	ld	a,(CURSOR_YPOS)
	cp	$30
	jr	z,KeyLoop
	add	a,12
	ld	(CURSOR_YPOS),a
	JUMP_(	UpdateCursor)

KeyLeft:
	ld	a,(CURSOR_YPOS)
	cp	$0c
	jr	z,KLInput
	cp	$24
	jr	z,KLOutput
	JUMP_(	KeyLoop)
KLInput:
	ld	a,(INPUT_BASE)
	cp	2
	JUMP_Z(	KeyLoop)
	dec	a
KLRInputUpd:
	ld	(INPUT_BASE),a
	CALL_(	ClearInput)
	ld	hl,$1205
	ld	(CURSOR_X),hl
	ld	ix,VIDEO_MEM+295
	ld	a,(INPUT_BASE)
	CALL_(	UpdateBase)
	JUMP_(	KeyLoop)
KLOutput:
	ld	a,(OUTPUT_BASE)
	cp	2
	JUMP_Z(	KeyLoop)
	dec	a
KLROutputUpd:
	ld	(OUTPUT_BASE),a
	ld	hl,$2a05
	ld	(CURSOR_X),hl
	ld	ix,VIDEO_MEM+679
	CALL_(	UpdateBase)
	CALL_(	UpdateOutput)
	JUMP_(	KeyLoop)

KeyRight:
	ld	a,(CURSOR_YPOS)
	cp	$0c
	jr	z,KRInput
	cp	$24
	jr	z,KROutput
	JUMP_(	KeyLoop)
KRInput:
	ld	a,(INPUT_BASE)
	cp	21
	JUMP_Z(	KeyLoop)
	inc	a
	JUMP_(	KLRInputUpd)
KROutput:
	ld	a,(OUTPUT_BASE)
	cp	21
	JUMP_Z(	KeyLoop)
	inc	a
	JUMP_(	KLROutputUpd)

KeyDigit:
	ld	c,99
	cp	K_1
	jr	nz,KDK_2
	ld	c,1
KDK_2:	cp	K_2
	jr	nz,KDK_3
	ld	c,2
KDK_3:	cp	K_3
	jr	nz,KDK_4
	ld	c,3
KDK_4:	cp	K_4
	jr	nz,KDK_5
	ld	c,4
KDK_5:	cp	K_5
	jr	nz,KDK_6
	ld	c,5
KDK_6:	cp	K_6
	jr	nz,KDK_7
	ld	c,6
KDK_7:	cp	K_7
	jr	nz,KDK_8
	ld	c,7
KDK_8:	cp	K_8
	jr	nz,KDK_9
	ld	c,8
KDK_9:	cp	K_9
	jr	nz,KDK_0
	ld	c,9
KDK_0:	cp	K_0
	jr	nz,KDK_A
	ld	c,0
	ld	ix,INPUT
	ld	a,(ix)
	cp	0
	JUMP_NZ(KDGotKey)
	ld	a,(ix+1)
	cp	0
	JUMP_NZ(KDGotKey)
	ld	a,(ix+2)
	cp	0
	JUMP_NZ(KDGotKey)
	ld	a,(ix+3)
	cp	0
	JUMP_NZ(KDGotKey)
	JUMP_(	KeyLoop)
KDK_A:	cp	K_LOG
	jr	nz,KDK_B
	ld	c,10
KDK_B:	cp	K_SIN
	jr	nz,KDK_C
	ld	c,11
KDK_C:	cp	K_COS
	jr	nz,KDK_D
	ld	c,12
KDK_D:	cp	K_TAN
	jr	nz,KDK_E
	ld	c,13
KDK_E:	cp	K_RAISE
	jr	nz,KDK_F
	ld	c,14
KDK_F:	cp	K_LN
	jr	nz,KDK_G
	ld	c,15
KDK_G:	cp	K_EE
	jr	nz,KDK_H
	ld	c,16
KDK_H:	cp	K_LEFTPAR
	jr	nz,KDK_I
	ld	c,17
KDK_I:	cp	K_RIGHTPAR
	jr	nz,KDK_J
	ld	c,18
KDK_J:	cp	K_SLASH
	jr	nz,KDK_K
	ld	c,19
KDK_K:	cp	K_SQUARE
	jr	nz,KDGotKey
	ld	c,20

KDGotKey:
	ld	a,c
	cp	99
	JUMP_Z(	KeyLoop)

	ld	a,(INPUT_BASE)
	dec	a
	cp	c
	JUMP_C(	KeyLoop)

	ld	a,(CURSOR_YPOS)
	cp	$18
	JUMP_NZ(KeyLoop)

KDKInput:
	ld	d,$1e
	ld	a,(INPUT_CURSOR_XPOS)
	ld	e,a
	ld	(CURSOR_X),de

	ld	a,c
	cp	10
	jr	c,KDBelow10
	add	a,7
KDBelow10:

	push	af

;	ld	hl,$0101
;	ld	(CURSOR_ROW),hl
;	ld	hl,(INPUT+2)
;	ROM_CALL(D_HL_DECI)
;	ld	hl,(INPUT)
;	ROM_CALL(D_HL_DECI)

        ld      de,(INPUT)
	ld      (arg1),de
	ld      de,(INPUT+2)
	ld      (arg1+2),de
	ld      a,(INPUT_BASE)
	ld      e,a
	ld      d,0
	ld      (arg2),de
	ld      e,0
	ld      (arg2+2),de
	CALL_(  Mult32)

;	ld	hl,$0102
;	ld	(CURSOR_ROW),hl
;	ld	hl,(res1+2)
;	ROM_CALL(D_HL_DECI)
;	ld	hl,(res1)
;	ROM_CALL(D_HL_DECI)
;WaitA:	call	GET_KEY
;	cp	0
;	jr	z,WaitA

;	cp	1
;	JUMP_Z(	KDCarry)

	xor	a
	ld	hl,(res1)
	ld	de,(INPUT)
	sbc	hl,de
	ld	hl,(res1+2)
	ld	de,(INPUT+2)
	sbc	hl,de
	jr	c,KDCarry

	pop	af

        add     a,'0'
        ROM_CALL(M_CHARPUT)
	ld	a,(CURSOR_X)
	ld	(INPUT_CURSOR_XPOS),a


        ld      de,(res1)
        ld      (INPUT),de
        ld      de,(res1+2)
        ld      (INPUT+2),de

        ld      de,(INPUT)
        ld      (arg1),de
        ld      de,(INPUT+2)
        ld      (arg1+2),de
        ld      e,c
        ld      d,0
        ld      (arg2),de
        ld      e,0
        ld      (arg2+2),de
        CALL_(  Add32)
        ld      de,(arg1)
        ld      (INPUT),de
        ld      de,(arg1+2)
	ld      (INPUT+2),de

	CALL_(	UpdateOutput)
	JUMP_(	KeyLoop)
KDCarry:
	pop	af
	JUMP_(	KeyLoop)

KeyDel:
	ld	a,(CURSOR_YPOS)
	cp	$18
	JUMP_NZ(KeyLoop)

	ld	a,(INPUT_CURSOR_XPOS)
;	cp	$05
	cp	0
	JUMP_Z(	KeyLoop)

        ld      de,(INPUT)
        ld      (arg1),de
        ld      de,(INPUT+2)
        ld      (arg1+2),de
        ld      a,(INPUT_BASE)
        ld      e,a
        ld      d,0
        ld      (arg2),de
        ld      e,0
        ld      (arg2+2),de
        CALL_(  Div32)
        ld      de,(arg1)
        ld      (INPUT),de
        ld      de,(arg1+2)
        ld      (INPUT+2),de

	ld	a,(INPUT_CURSOR_XPOS)
	sub	$04
	ld	(INPUT_CURSOR_XPOS),a

	ld	b,$1e
	ld	c,a
	ld	de,(PROGRAM_ADDR)
	ld	hl,txtClearCursor
	CALL_(	DispText)

	CALL_(	UpdateOutput)
	JUMP_(	KeyLoop)

FastExit:
	ld	hl,ZS_BITS
	set	1,(hl)
Exit:
;	ld	hl,ZS_BITS
;	set	0,(hl)
	ret

ClearInput:
	ld	hl,VIDEO_MEM+496
	ld	b,80
CIClearLoop:
	ld	(hl),$00
	inc	hl
	djnz	CIClearLoop
	ld	de,0
	ld	(INPUT),de
	ld	(INPUT+2),de
	ld	a,$00
	ld	(INPUT_CURSOR_XPOS),a

UpdateOutput:
	ld	hl,VIDEO_MEM+880
	ld	b,80
UOClearLoop:
	ld	(hl),$00
	inc	hl
	djnz	UOClearLoop

	ld	ix,INPUT
        ld	a,(ix)
        cp	0
        jr	nz,UOClear
        ld	a,(ix+1)
        cp	0
        jr	nz,UOClear
        ld	a,(ix+2)
        cp	0
        jr	nz,UOClear
        ld	a,(ix+3)
        cp	0
        ret	z

UOClear:
	ld	hl,$3600
	ld	(CURSOR_X),hl

	set	3,(IY+5)

        ld      de,1
        ld      (arg1),de
        ld      (tmp),de
        ld      de,0
        ld      (arg1+2),de
        ld      (tmp+2),de

	ld	de,(INPUT)
	push	de
	ld	de,(INPUT+2)
	push	de

UOFindMax:
	xor	a
	ld      hl,(INPUT)
	ld      de,(arg1)
	sbc     hl,de
	ld      hl,(INPUT+2)
	ld      de,(arg1+2)
	sbc     hl,de
	JUMP_C(	UOFoundMax)

        ld      de,(arg1)
        ld      (tmp),de
        ld      de,(arg1+2)
        ld      (tmp+2),de

        ld      d,0
        ld      a,(OUTPUT_BASE)
        ld      e,a
        ld      (arg2),de
        ld      e,0
        ld      (arg2+2),de
        CALL_(  Mult32)

	cp	1
	JUMP_Z(	UOFoundMax)

	xor	a
	ld      hl,(res1)
	ld      de,(tmp)
	sbc     hl,de
	ld      hl,(res1+2)
	ld      de,(tmp+2)
	sbc     hl,de
	jr      c,UOFoundMax

        ld      de,(res1)
        ld      (arg1),de
        ld      de,(res1+2)
        ld      (arg1+2),de

	JUMP_(	UOFindMax)

UOFoundMax:
	ld      de,(INPUT)
	ld      (arg1),de
	ld      de,(INPUT+2)
	ld      (arg1+2),de
	ld      de,(tmp)
	ld      (arg2),de
	ld      de,(tmp+2)
	ld      (arg2+2),de
	CALL_(  Div32)

UOChrOut:
	ld      a,(arg1)
	cp	10
	jr	c,UOBelow10
	add	a,7
UOBelow10:
	add     a,'0'
	ROM_CALL(M_CHARPUT)

	ld      de,(res1)
	ld      (INPUT),de
	ld      de,(res1+2)
	ld      (INPUT+2),de

	ld      de,(tmp)
	ld      (arg1),de
	ld      de,(tmp+2)
	ld      (arg1+2),de
	ld      d,0
	ld      a,(OUTPUT_BASE)
	ld      e,a
	ld      (arg2),de
	ld      e,0
	ld      (arg2+2),de
	CALL_(  Div32)
	ld      de,(arg1)
	ld      (tmp),de
	ld      de,(arg1+2)
	ld      (tmp+2),de

	ld	ix,tmp
        ld      a,(ix)
        cp      0
	JUMP_NZ(UOFoundMax)
	ld      a,(ix+1)
	cp      0
        JUMP_NZ(UOFoundMax)
        ld      a,(ix+2)
        cp      0
        JUMP_NZ(UOFoundMax)
        ld      a,(ix+3)
        cp      0
        JUMP_NZ(UOFoundMax)

	pop	de
	ld	(INPUT+2),de
	pop	de
	ld	(INPUT),de

	res	3,(IY+5)
	ret

UpdateBase:
	ld	b,a
	add	a,b
	add	a,b
	add	a,15
	ld	de,(PROGRAM_ADDR)
	ld	hl,txtBaseNumbers
	add	hl,de
	ld	d,0
	ld	e,a
	add	hl,de
	ld	(hl),0
	push	hl

	ld	a,b
	add	a,b
	add	a,b
	sub	5
	ld	d,0
	ld	e,a
	ld	bc,(PROGRAM_ADDR)
	ld	hl,txtBaseNum0
	add	hl,de
	add	hl,bc
	ROM_CALL(D_ZM_STR)
	pop	hl
	ld	(hl),' '

	ld	de,16
	ld	b,6
UIBMarker:
	ld	a,$3F
	xor	(ix)
	ld	(ix),a
	ld	a,$e0
	xor	(ix+1)
	ld	(ix+1),a
	add	ix,de
	djnz	UIBMarker
	ret

Mult32:                                 ; arg1 * arg2 -> res1
	ld	a,0
        ld      b,32                    ; uses de, b, a
        ld      de,0
        ld      (res1),de
        ld      (res1+2),de

Mult32Loop:
        ld      de,(arg1+2)             ; arg1 << 1 -> arg1
        srl     d
        rr      e
        ld      (arg1+2),de
        ld      de,(arg1)
        rr      d
        rr      e
        ld      (arg1),de
        jr      nc,Mult32NoAdd

        ld      hl,(res1)               ; res1 + arg2 -> res1
        ld      de,(arg2)
        add     hl,de
        ld      (res1),hl
        ld      hl,(res1+2)
        ld      de,(arg2+2)
        adc     hl,de
        ld      (res1+2),hl
	jr	nc,Mult32NoAdd
	ld	a,1
Mult32NoAdd:
        ld      de,(arg2)               ; arg2 << 1 -> arg2
        sla     e
        rl      d
        ld      (arg2),de
        ld      de,(arg2+2)
        rl      e
        rl      d
        ld      (arg2+2),de
        djnz    Mult32Loop
        ret

Add32:                                  ; arg1 + arg2 -> arg1
        ld      hl,(arg1)               ; uses hl, de
        ld      de,(arg2)
        add     hl,de
        ld      (arg1),hl
        ld      hl,(arg1+2)
        ld      de,(arg2+2)
        adc     hl,de
        ld      (arg1+2),hl
        ret

Div32:                                  ; arg1 / arg2 -> arg1 , res1 (remainder)
        ld      de,0                    ; uses de, b
        ld      (res1),de
        ld      (res1+2),de
        ld      b,32
        and     a                       ; clear carry
Div32Loop:
        ld      de,(arg1)               ; arg1 >> 1 -> arg1
        rl      e
        rl      d
        ld      (arg1),de
        ld      de,(arg1+2)
        rl      e
        rl      d
        ld      (arg1+2),de
        ld      de,(res1)               ; res1 >> 1 -> res1
        rl      e
        rl      d
        ld      (res1),de
        ld      de,(res1+2)
        rl      e
        rl      d
        ld      (res1+2),de
        ld      hl,(res1)               ; res1 - arg2 -> res1
        ld      de,(arg2)
        sbc     hl,de
        ld      (res1),hl
        ld      hl,(res1+2)
        ld      de,(arg2+2)
        sbc     hl,de
        ld      (res1+2),hl
        jr      nc,Div32NoAdd
        ld      hl,(res1)               ; res1 + arg2 -> res1
        ld      de,(arg2)
        add     hl,de
        ld      (res1),hl
        ld      hl,(res1+2)
        ld      de,(arg2+2)
        adc     hl,de
        ld      (res1+2),hl
Div32NoAdd:
        ccf
        djnz    Div32Loop
        ld      de,(arg1)               ; arg1 >> 1 -> arg1
        rl      e
        rl      d
        ld      (arg1),de
        ld      de,(arg1+2)
        rl      e
        rl      d
        ld      (arg1+2),de
	ret

DispText:
	ld	(CURSOR_X),bc
	add	hl,de
	ROM_CALL(D_ZM_STR)
	ret

txtAuthor:	.db	" by Oskar Liljeblad",0
txtInputBase:	.db	"Input Base:",0
txtInput:	.db	"Input:",0
txtOutputBase:	.db	"Output Base:",0
txtOutput:	.db	"Output:",0
txtClearCursor:	.db	"   ",0
txtBaseNum0:	.db	" -- -- -- -- -- --"
txtBaseNumbers:	.db	" 02 03 04 05 06 07 08"
		.db	" 09 10 11 12 13 14"
		.db	" 15 16 17 18 19 20"
		.db	" 21 -- -- -- -- -- -- ",0

		.end
