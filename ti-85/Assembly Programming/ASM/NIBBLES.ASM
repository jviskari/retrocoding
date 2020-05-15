; Nibbles for ZShell 1.1 source code

	#include "TI-85.h"

	.org	0
msgNibblesTitle1:
	.db	"Nibbles for ZShell 1.1",0

MASK_XMOVE	= TEXT_MEM
MASK_YMOVE	= TEXT_MEM+1
OBJ_PICKEDUP	= TEXT_MEM+2
OBJ_XPOS	= TEXT_MEM+3
OBJ_YPOS	= TEXT_MEM+4
MASK_MOVE	= TEXT_MEM+5
MASK_START	= TEXT_MEM+6
MASK_END	= TEXT_MEM+8
MASK_WANNASTART	= TEXT_MEM+10
randvar		= TEXT_MEM+12
SCORE		= TEXT_MEM+14		; NOTE! WORD
DELAY_TIME	= TEXT_MEM+16		; NOTE! WORD
DELAY_COUNTER	= TEXT_MEM+18		; NOTE! WORD
MASK_DATA	= TEXT_MEM+20		; NOTE! WORD
MASK_STEER	= TEXT_MEM+22
LEVEL		= TEXT_MEM+23
TMPSCORE	= TEXT_MEM+24

masklen_size	= 180
lastlevel	= 10
speed_slowest	= 1500
speed_slow	= 1100
speed_normal	= 800
speed_fast	= 350
speed_fastest	= 127

	ld	a,4
	out	(5),a

	ROM_CALL(CLEARLCD)

	ld	c,63			; display welcome picture
	ld	hl,(PROGRAM_ADDR)
	ld	de,PictureData
	add	hl,de
	ld	de,VIDEO_MEM
DispPic_Loop2:
	ld	b,16
DispPic_Loop1:
	ld	a,(hl)
	ld	(de),a
	inc	hl
	inc	de
	djnz	DispPic_Loop1
	dec	c
	jr	nz,DispPic_Loop2

WaitKey_Pic:				; wait for any key
	call	GET_KEY
	cp	0
	jr	z,WaitKey_Pic

RestartGame:				; (restart game from level 1)
	ld	a,1
	ld	(LEVEL),a
	ld	bc,0
	ld	(SCORE),bc

PlayNewLevel:				; (play other level)
	ROM_CALL(CLEARLCD)

	ld	a,0
	ld	(OBJ_PICKEDUP),a
	ld	bc,0
	ld	(MASK_END),bc
	ld	bc,8
	ld	(MASK_START),bc
	ld	bc,-1
	ld	(MASK_WANNASTART),bc

	ld	hl,maskData
	ld	de,(PROGRAM_ADDR)
	add	hl,de
	ld	(MASK_DATA),hl		; for faster access
	ld	hl,maskSteer
	add	hl,de
	ld	a,(hl)
	ld	(MASK_STEER),a


DispSettingsScr:
	ld	a,(LEVEL)		; skip settings screen if
	cp	1			; not playing first level
	JUMP_NZ(StartLevel)

	ld	bc,$0000
	ld	hl,msgNibblesTitle1
	CALL_(	DisplayMenuTxt)
;	ld	bc,$004c
	ld	hl,msgNibblesTitle2
	add	hl,de
	ROM_CALL(D_ZM_STR)
	ld	bc,$0700
	ld	hl,msgNibblesTitle3
	CALL_(	DisplayMenuTxt)
	ld	bc,$073e
	ld	hl,msgNibblesTitle4
	CALL_(	DisplayMenuTxt)
	ld	bc,$1209
	ld	hl,msgSetLevel
	CALL_(	DisplayMenuTxt)
	ld	bc,$1901
	ld	hl,msgSetSpeed
	CALL_(	DisplayMenuTxt)
	ld	bc,$2003
	ld	hl,msgSetSteer
	CALL_(	DisplayMenuTxt)
	ld	bc,$2700
	ld	hl,msgKeyEnter
	CALL_(	DisplayMenuTxt)
	ld	bc,$2e07
	ld	hl,msgKeyExit
	CALL_(	DisplayMenuTxt)
	ld	bc,$3900
	ld	hl,msgHighscore
	CALL_(	DisplayMenuTxt)

	ld	ix,highscore		; convert highscore to ASCII
	add	ix,de
	ld	l,(ix)
	ld	h,(ix+1)
	ld	ix,highscoreData+4
	add	ix,de
	ld	b,5
DispHighscore:
	call	UNPACK_HL
	add	a,'0'
	ld	(ix),a
	dec	ix
	djnz	DispHighscore
	ld	bc,$3924
	ld	hl,highscoreData
	CALL_(	DisplayMenuTxt)

	CALL_(	DisplayLevel)

	ld	bc,$2060
	ld	hl,msgSteer0
	ld	a,(MASK_STEER)
	cp	0
	jr	z,DispSteer
	ld	hl,msgSteer1
DispSteer:
	CALL_(	DisplayMenuTxt)

	ld	hl,maskSpeed
	add	hl,de
	call	LD_HL_MHL
	ld	b,h
	ld	c,l
	ld	hl,maskSpeedText
	add	hl,de
	call	LD_HL_MHL

	JUMP_(	DispSpeed)

WaitKey_Set:
	CALL_(	GetRandom)
	call	GET_KEY

	cp	K_ENTER
	JUMP_Z(	StartLevel)
	cp	K_EXIT
	JUMP_Z(	ExitGame)
	cp	K_LEFT
	jr	z,DecStartLevel
	cp	K_RIGHT
	jr	z,IncStartLevel
	cp	K_F1
	JUMP_Z(	SetSpeed_1)
	cp	K_F2
	JUMP_Z(	SetSpeed_2)
	cp	K_F3
	JUMP_Z(	SetSpeed_3)
	cp	K_F4
	JUMP_Z(	SetSpeed_4)
	cp	K_F5
	JUMP_Z(	SetSpeed_5)
	cp	K_MORE
	jr	nz,WaitKey_Set

ChangeSteer:
	ld	a,(MASK_STEER)
	cp	0
	jr	z,SetSteer_2But

	ld	a,0		; is 2-button
	ld	(MASK_STEER),a
	ld	hl,msgSteer0
	jr	DispSteerBut
SetSteer_2But:			; is 4-button
	ld	a,1
	ld	(MASK_STEER),a
	ld	hl,msgSteer1

DispSteerBut:
	ld	ix,maskSteer
	add	ix,de
	ld	(ix),a
	ld	bc,$2060
	CALL_(	DisplayMenuTxt)
	jr	WaitKey_Set

IncStartLevel:
	ld	ix,lastPlayedLevel
	add	ix,de
	ld	b,(ix)
	ld	a,(LEVEL)
	cp	b
	jr	nc,WaitKey_Set
	inc	a
	ld	(LEVEL),a
	jr	DispStartLevel

DecStartLevel:
	ld	a,(LEVEL)
	dec	a
	cp	0
	JUMP_Z(	WaitKey_Set)
	ld	(LEVEL),a

DispStartLevel:
	CALL_(	DisplayLevel)
	JUMP_(	WaitKey_Set)

SetSpeed_1:
	ld	bc,speed_slowest
	ld	hl,msgSpeed1
	jr	DispSpeed
SetSpeed_2:
	ld	bc,speed_slow
	ld	hl,msgSpeed2
	jr	DispSpeed
SetSpeed_3:
	ld	bc,speed_normal
	ld	hl,msgSpeed3
	jr	DispSpeed
SetSpeed_4:
	ld	bc,speed_fast
	ld	hl,msgSpeed4
	jr	DispSpeed
SetSpeed_5:
	ld	bc,speed_fastest
	ld	hl,msgSpeed5

DispSpeed:
	ld	(DELAY_TIME),bc
	ld	ix,maskSpeed
	add	ix,de
	ld	(ix),c
	ld	(ix+1),b
	ld	ix,maskSpeedText
	add	ix,de
	ld	(ix),l
	ld	(ix+1),h
	ld	bc,$1960
	CALL_(	DisplayMenuTxt)
	JUMP_(	WaitKey_Set)

StartLevel:

	ld	a,(LEVEL)
	cp	6
	jr	z,MaskMove_Up
	cp	10
	jr	nz,MaskMove_Right

MaskMove_Up:
	ld	bc,$0200
	ld	(MASK_XMOVE),bc
	ld	a,3
	ld	(MASK_MOVE),a

	ld	ix,(MASK_DATA)		; initialize begin mask positions
	ld	a,4
	ld	(ix),a
	ld	(ix+1),a
	ld	(ix+2),a
	ld	(ix+3),4
	ld	(ix+4),a
	ld	(ix+5),6
	ld	(ix+6),a
	ld	(ix+7),8
	ld	(ix+8),a
	ld	(ix+9),10
	jr	DrawBord

MaskMove_Right:
	ld	bc,$0002
	ld	(MASK_XMOVE),bc
	ld	a,b
	ld	(MASK_MOVE),a
	
	ld	ix,(MASK_DATA)		; initialize begin mask positions
	ld	a,4
	ld	(ix),a
	ld	(ix+1),a
	ld	(ix+3),a
	ld	(ix+5),a
	ld	(ix+7),a
	ld	(ix+9),a
	ld	(ix+2),4
	ld	(ix+4),6
	ld	(ix+6),8
	ld	(ix+8),10

DrawBord:
	ROM_CALL(CLEARLCD)

DrawBorder:				; draw playground borders
	ld	b,32
	ld	ix,VIDEO_MEM
DrawBorder_T:
	ld	(ix),$FF
	inc	ix
	djnz	DrawBorder_T

	ld	b,60
	ld	de,16
DrawBorder_LR:
	ld	(ix),$C0
	ld	(ix+15),$03
	add	ix,de
	djnz	DrawBorder_LR

	ld	b,32
DrawBorder_B:
	ld	(ix),$FF
	inc	ix
	djnz	DrawBorder_B

	ld	a,(LEVEL)
	cp	2
	jr	z,DrawLevel_2
	cp	3
	jr	z,DrawLevel_3
	cp	4
	jr	z,DrawLevel_4
	cp	5
	JUMP_Z(	DrawLevel_5)
	cp	6
	JUMP_Z(	DrawLevel_6)
	cp	7
	JUMP_Z(	DrawLevel_7)
	cp	8
	JUMP_Z(	DrawLevel_8)
	cp	9
	JUMP_Z(	DrawLevel_9)
	cp	10
	JUMP_Z(	DrawLevel_10)
	JUMP_(	DrawObjects)

DrawLevel_2:
	ld	ix,VIDEO_MEM+483
	ld	b,10
	ld	a,$FF
DrawLevel_2B:
	ld	(ix),a
	ld	(ix+16),a
	inc	ix
	djnz	DrawLevel_2B
	JUMP_(	DrawObjects)

DrawLevel_3:
	ld	ix,VIDEO_MEM+228
	ld	b,36
	ld	a,$c0
	ld	de,16
DrawLevel_3B:
	ld	(ix),a
	ld	(ix+8),a
	add	ix,de
	djnz	DrawLevel_3B
	JUMP_(	DrawObjects)

DrawLevel_4:
	ld	ix,VIDEO_MEM+36
	ld	b,30
	ld	a,$c0
	ld	de,16
DrawLevel_4B:
	ld	(ix),a
	add	ix,de
	djnz	DrawLevel_4B

	ld	b,30
	ld	de,8
	add	ix,de
	ld	de,16
DrawLevel_4C:
	ld	(ix),a
	add	ix,de
	djnz	DrawLevel_4C

	ld	ix,VIDEO_MEM+264
	ld	b,8
	ld	a,$FF
DrawLevel_4D:
	ld	(ix),a
	ld	(ix+16),a
	inc	ix
	djnz	DrawLevel_4D

	ld	ix,VIDEO_MEM+736
	ld	b,8
DrawLevel_4E:
	ld	(ix),a
	ld	(ix+16),a
	inc	ix
	djnz	DrawLevel_4E
	JUMP_(	DrawObjects)

DrawLevel_5:
	ld	a,$FF
	ld	ix,VIDEO_MEM+773
	ld	(ix),a
	ld	(ix+16),a
	ld	(ix+1),a
	ld	(ix+17),a
	ld	(ix+2),a
	ld	(ix+18),a
	ld	(ix+3),a
	ld	(ix+19),a
	ld	(ix+4),a
	ld	(ix+20),a
	ld	(ix+5),a
	ld	(ix+21),a
	ld	ix,VIDEO_MEM+229
	ld	(ix),a
	ld	(ix+16),a
	ld	(ix+1),a
	ld	(ix+17),a
	ld	(ix+2),a
	ld	(ix+18),a
	ld	(ix+3),a
	ld	(ix+19),a
	ld	(ix+4),a
	ld	(ix+20),a
	ld	(ix+5),a
	ld	(ix+21),a

	ld	b,28
	ld	de,16
	ld	ix,VIDEO_MEM+292
DrawLevel_5B:
	ld	(ix),$0c
	ld	(ix+7),$30
	add	ix,de
	djnz	DrawLevel_5B
	JUMP_(	DrawObjects)

DrawLevel_6:
	ld	b,26
	ld	de,16
	ld	ix,VIDEO_MEM+33
	ld	a,$03
DrawLevel_6B:
	ld	(ix),a
	ld	(ix+2),a
	ld	(ix+4),a
	ld	(ix+6),a
	ld	(ix+8),a
	ld	(ix+10),a
	ld	(ix+12),a
	add	ix,de
	djnz	DrawLevel_6B

	ld	b,24
	ld	ix,VIDEO_MEM+609
DrawLevel_6C:
	ld	(ix),a
	ld	(ix+2),a
	ld	(ix+4),a
	ld	(ix+6),a
	ld	(ix+8),a
	ld	(ix+10),a
	ld	(ix+12),a
	add	ix,de
	djnz	DrawLevel_6C

	JUMP_(	DrawObjects)

DrawLevel_7:
	ld	ix,VIDEO_MEM+40
	ld	b,15
	ld	de,64
	ld	a,$c0
DrawLevel_7B:
	ld	(ix),a
	ld	(ix+16),a
	add	ix,de
	djnz	DrawLevel_7B

	JUMP_(	DrawObjects)

DrawLevel_8:
	ld	ix,VIDEO_MEM+33
	ld	b,46
	ld	de,16
	ld	a,$03
DrawLevel_8B:
	ld	(ix),a
	ld	(ix+4),a
	ld	(ix+8),a
	ld	(ix+12),a
	add	ix,de
	djnz	DrawLevel_8B

	ld	ix,VIDEO_MEM+259
	ld	b,46
DrawLevel_8C:
	ld	(ix),a
	ld	(ix+4),a
	ld	(ix+8),a
	add	ix,de
	djnz	DrawLevel_8C

	JUMP_(	DrawObjects)

DrawLevel_9:
	ld	ix,VIDEO_MEM+97
	ld	b,6
	ld	de,129
DrawLevel_9B:
	ld	a,$c0
	ld	(ix),a
	ld	(ix+16),a
	ld	(ix+64+8),a
	ld	(ix+80+8),a

	ld	a,$0c
	ld	(ix+7),a
	ld	(ix+16+7),a
	ld	(ix+64),a
	ld	(ix+80),a

	ld	a,$30
	ld	(ix+32),a
	ld	(ix+48),a
	ld	(ix+96+8),a
	ld	(ix+112+8),a

	ld	a,$03
	ld	(ix+32+7),a
	ld	(ix+48+7),a
	ld	(ix+96),a
	ld	(ix+112),a

	add	ix,de
	djnz	DrawLevel_9B

	ld	(ix),$c0
	ld	(ix+7),$0c
	ld	(ix+16),$c0
	ld	(ix+16+7),$0c
	ld	(ix+32),$30
	ld	(ix+32+7),a
	ld	(ix+48),$30
	ld	(ix+48+7),a
	jr	DrawObjects

DrawLevel_10:
	ld	ix,VIDEO_MEM+33
	ld	b,15
	ld	de,64
	ld	a,$03
DrawLevel_10B:
	ld	(ix),a
	ld	(ix+4),a
	ld	(ix+8),a
	ld	(ix+12),a
	ld	(ix+16),a
	ld	(ix+4+16),a
	ld	(ix+8+16),a
	ld	(ix+12+16),a

	ld	(ix+2+32),a
	ld	(ix+6+32),a
	ld	(ix+10+32),a
	ld	(ix+2+16+32),a
	ld	(ix+6+16+32),a
	ld	(ix+10+16+32),a

	add	ix,de
	djnz	DrawLevel_10B

	jr	DrawObjects

DrawObjects:
	CALL_(	PutObject)
	ld	a,(OBJ_XPOS)
	ld	b,a
	ld	a,(OBJ_YPOS)
	ld	c,a
	CALL_(	DrawSegment)

	ld	ix,(MASK_DATA)
	ld	b,(ix)
	ld	c,(ix+1)
	CALL_(	DrawSegment)
	ld	b,(ix+2)
	ld	c,(ix+3)
	CALL_(	DrawSegment)
	ld	b,(ix+4)
	ld	c,(ix+5)
	CALL_(	DrawSegment)
	ld	b,(ix+6)
	ld	c,(ix+7)
	CALL_(	DrawSegment)
	ld	b,(ix+8)
	ld	c,(ix+9)
	CALL_(	DrawSegment)

UpdatePos:
	ld	ix,(MASK_DATA)
	ld	de,(MASK_START)
	add	ix,de
	ld	b,(ix)			; b = x pos
	ld	c,(ix+1)		; c = y pos
	ld	a,(MASK_XMOVE)
	add	a,b
	ld	b,a
	ld	a,(MASK_YMOVE)
	add	a,c
	ld	c,a

	ld	hl,(MASK_START)
	inc	hl
	inc	hl
	ld	de,masklen_size
	call	CP_HL_DE
	jr	nz,UpdatePos_1
	ld	hl,0
UpdatePos_1:
	ld	(MASK_START),hl

	ld	ix,(MASK_DATA)
	ld	de,(MASK_START)
	add	ix,de
	ld	(ix),b
	ld	(ix+1),c

UpdateScr:
	ROM_CALL(FIND_PIXEL)
	ld	de,VIDEO_MEM
	add	hl,de
	and	(hl)
	cp	0
	JUMP_Z(UpdateScr_1)

	ld	hl,OBJ_XPOS
	ld	a,b
	cp	(hl)
	JUMP_NZ(LooseGame)
	inc	hl
	ld	a,c
	cp	(hl)
	JUMP_NZ(LooseGame)

PickupObject:
	push	bc
	ld	hl,(MASK_START)
	ld	de,20
	add	hl,de
	ld	b,h
	ld	c,l
	ld	de,-masklen_size
	add	hl,de
	bit	7,h
	jr	z,PickupObject_2
	ld	h,b
	ld	l,c
PickupObject_2:
	ld	(MASK_WANNASTART),hl

	ld	hl,(SCORE)		; check for MAX SCORE
	ld	de,100
	add	hl,de
	ld	(SCORE),hl

	pop	bc

	ld	a,(OBJ_PICKEDUP)
	cp	8
	JUMP_Z(	WonGame)
	inc	a
	ld	(OBJ_PICKEDUP),a

	push	bc

	CALL_(	PutObject)
	ld	a,(OBJ_YPOS)
	ld	c,a
	ld	a,(OBJ_XPOS)
	ld	b,a
	CALL_(	DrawSegment)

	pop	bc

UpdateScr_1:
	CALL_(	DrawSegment)

	ld	hl,(MASK_WANNASTART)
	ld	de,-1
	call	CP_HL_DE
	jr	z,RemoveSeg
	ld	de,(MASK_START)
	call	CP_HL_DE
	jr	nz,NoRemoveSeg

	ld	hl,-1
	ld	(MASK_WANNASTART),hl

RemoveSeg:
	ld	ix,(MASK_DATA)
	ld	de,(MASK_END)
	add	ix,de
	ld	b,(ix)
	ld	c,(ix+1)

	CALL_(	ClearPixel)
	inc	b
	CALL_(	ClearPixel)
	inc	c
	CALL_(	ClearPixel)
	dec	b
	CALL_(	ClearPixel)

RemoveSeg_2:
	ld	hl,(MASK_END)
	inc	hl
	inc	hl
	ld	de,masklen_size
	call	CP_HL_DE
	jr	nz,RemoveSeg_1
	ld	hl,0
RemoveSeg_1:
	ld	(MASK_END),hl

NoRemoveSeg:
	ld	hl,(DELAY_TIME)
	ld	(DELAY_COUNTER),hl

	ld	a,(TMPSCORE)
	inc	a
	ld	(TMPSCORE),a
	cp	10
	jr	nz,UpdatePos_0
	ld	a,0
	ld	(TMPSCORE),a

	ld	hl,(SCORE)
	dec	hl
	ld	a,h
	cp	-1
	JUMP_Z(	UpdatePos_0)
	ld	(SCORE),hl
UpdatePos_0:

CheckKey_Input:
	ld	hl,(DELAY_COUNTER)
	dec	hl
	ld	(DELAY_COUNTER),hl
	ld	a,h
	cp	-1
	JUMP_Z(	UpdatePos)

CheckKey_Left:
	call	GET_KEY
	cp	K_LEFT
	jr	nz,CheckKey_Right

	ld	a,(MASK_STEER)
	dec	a
	jr	nz,CheckKey_Input

	ld	bc,$00FE
	ld	(MASK_XMOVE),bc
	jr	CheckKey_Input

CheckKey_Right:
	cp	K_RIGHT
	jr	nz,CheckKey_Up

	ld	a,(MASK_STEER)
	dec	a
	jr	nz,CheckKey_Input

	ld	bc,$0002
	ld	(MASK_XMOVE),bc
	JUMP_(	CheckKey_Input)

CheckKey_Up:
	cp	K_UP
	jr	nz,CheckKey_Down

	ld	a,(MASK_STEER)
	dec	a
	jr	z,KeyUp_4But

	ld	hl,maskMoveArray
	ld	de,(PROGRAM_ADDR)
	add	hl,de
	ld	a,(MASK_MOVE)
	inc	a
	and	3
	ld	(MASK_MOVE),a
	ld	d,0
	ld	e,a
	add	hl,de
	add	hl,de
	ld	a,(hl)
	ld	(MASK_XMOVE),a
	inc	hl
	ld	a,(hl)
	ld	(MASK_YMOVE),a
	JUMP_(	CheckKey_Input)

KeyUp_4But:
	ld	bc,$0200
	ld	(MASK_XMOVE),bc
	JUMP_(	CheckKey_Input)

CheckKey_Down:
	cp	K_DOWN
	jr	nz,CheckKey_More

	ld	a,(MASK_STEER)
	dec	a
	jr	z,KeyDown_4But

	ld	hl,maskMoveArray
	ld	de,(PROGRAM_ADDR)
	add	hl,de
	ld	a,(MASK_MOVE)
	dec	a
	and	3
	ld	(MASK_MOVE),a
	ld	d,0
	ld	e,a
	add	hl,de
	add	hl,de
	ld	a,(hl)
	ld	(MASK_XMOVE),a
	inc	hl
	ld	a,(hl)
	ld	(MASK_YMOVE),a
	JUMP_(	CheckKey_Input)
KeyDown_4But:
	ld	bc,$FE00
	ld	(MASK_XMOVE),bc
	JUMP_(	CheckKey_Input)

CheckKey_More:
	cp	K_MORE
	jr	nz,CheckKey_Exit
GamePaused:
	call	GET_KEY
	cp	K_MORE
	JUMP_Z(	CheckKey_Input)
	cp	K_EXIT
	JUMP_Z(	ExitGame)
	jr	GamePaused

CheckKey_Exit:
	cp	K_EXIT
	JUMP_NZ(CheckKey_Input)
	JUMP_(	ExitGame)

WonGame:
	ld	a,(LEVEL)
	cp	lastlevel
	jr	z,LooseGame

	ld	de,(PROGRAM_ADDR)

	ld	hl,$0101
	ld	(CURSOR_ROW),hl
	ld	hl,msgLevelDone1
	add	hl,de
	ROM_CALL(D_ZT_STR)
	ld	hl,$0103
	ld	(CURSOR_ROW),hl
	ld	hl,msgLevelDone2
	add	hl,de
	ROM_CALL(D_ZT_STR)
	ld	hl,(SCORE)
	ld	(SCORE),hl
	ROM_CALL(D_HL_DECI)
	ld	hl,$0105
	ld	(CURSOR_ROW),hl
	ld	de,(PROGRAM_ADDR)
	ld	hl,msgLevelDone3
	add	hl,de
	ROM_CALL(D_ZT_STR)

	ld	a,(LEVEL)
	add	a,1
	ld	(LEVEL),a
	add	a,'0'
	ld	hl,msgLevelDoneX
	add	hl,de
	cp	58
	jr	nz,GameWon_PutLevel

	ld	(hl),'1'
	inc	hl
	sub	10

GameWon_PutLevel:
	ld	(hl),a
	ld	hl,$0106
	ld	(CURSOR_ROW),hl
	ld	hl,msgLevelDone4
	add	hl,de
	ROM_CALL(D_ZT_STR)

	ld	hl,msgLevelDoneX+1
	add	hl,de
	ld	a,'.'
	ld	(hl),a

WaitKey_Won:
	call	GET_KEY
	cp	K_ENTER
	jr	nz,WaitKey_Won

	JUMP_(	PlayNewLevel)

LooseGame:
	ld	hl,$0101
	ld	(CURSOR_ROW),hl
	ld	de,(PROGRAM_ADDR)
	ld	hl,msgGameOver
	add	hl,de
	ROM_CALL(D_ZT_STR)
LooseGame_Score:
	ld	hl,$0103
	ld	(CURSOR_ROW),hl
	ld	hl,msgScore
	add	hl,de
	ROM_CALL(D_ZT_STR)
	ld	hl,(SCORE)
	ROM_CALL(D_HL_DECI)
	CALL_(	UpdateLastLevel)

CheckScore:
	ld	hl,(PROGRAM_ADDR)
	ld	de,highscore
	add	hl,de
	call	LD_HL_MHL

	ld	a,(SCORE)
	ld	e,a
	ld	a,(SCORE+1)
	ld	d,a

	call	CP_HL_DE
	jr	z,WaitKey_Loose			; same score
	jr	nc,WaitKey_Loose

StoreScore:
	ld	hl,highscore
	ld	bc,(PROGRAM_ADDR)
	add	hl,bc
	ld	(hl),e
	inc	hl
	ld	(hl),d

	ld	hl,$0105
	ld	(CURSOR_ROW),hl
	ld	hl,(PROGRAM_ADDR)
	ld	de,msgNewHighscore
	add	hl,de
	ROM_CALL(D_ZT_STR)

WaitKey_Loose:
	call	GET_KEY
	cp	K_ENTER
	JUMP_Z(	RestartGame)
	cp	K_EXIT
	jr	nz,WaitKey_Loose

ExitGame:
	CALL_(	UpdateLastLevel)
	ld      hl,ZS_BITS
	set     0,(hl)
	ret

SetPixel:
	ROM_CALL(FIND_PIXEL)
	ld	de,VIDEO_MEM
	add	hl,de
	or	(hl)
	ld	(hl),a
	ret

ClearPixel:
	ROM_CALL(FIND_PIXEL)
	ld	de,VIDEO_MEM
	add	hl,de
	xor	255
	and	(hl)
	ld	(hl),a
	ret

DrawSegment:
	CALL_(	SetPixel)
	inc	b
	CALL_(	SetPixel)
	inc	c
	CALL_(	SetPixel)
	dec	b
	CALL_(	SetPixel)
	ret

PutObject:
	CALL_(	GetRandom)
	res	0,a		; bit 0 (=1) - odd/even
	cp	0
	jr	nz,PO1
	set	1,a
PO1:	cp	126
	jr	nz,PO2
	res	1,a
PO2:	ld	(OBJ_XPOS),a
	ld	l,a
	CALL_(	GetRandom)
	srl	a
	res	0,a
	cp	0
	jr	nz,PO3
	set	1,a
PO3:	cp	62
	jr	nz,PO4
	res	1,a
PO4:	ld	(OBJ_YPOS),a
	ld	c,a
	ld	b,l
	ROM_CALL(FIND_PIXEL)
	ld	bc,VIDEO_MEM
	add	hl,bc
	and	(hl)
	cp	0
	jr	nz,PutObject
	ret

GetRandom:
	ld	a,(randvar)
	ld	b,a
	ld	a,0
	add	a,b
	sla	b
	sla	b
	add	a,b
	sla	b
	sla	b
	add	a,b
	inc	a
	ld	(randvar),a
	srl	a
	ret

DisplayMenuTxt:
	ld	(CURSOR_X),bc
	add	hl,de
	ROM_CALL(D_ZM_STR)
	ret

DisplayLevel:
	ld	bc,$1260
	ld	(CURSOR_X),bc
	ld	a,(LEVEL)
	cp	10
	jr	z,DL10
	add	a,'0'
	ROM_CALL(M_CHARPUT)
	ld	a,' '
	ROM_CALL(M_CHARPUT)
	ld	a,' '
	ROM_CALL(M_CHARPUT)
	ld	a,' '
	ROM_CALL(M_CHARPUT)
	jr	DLRet
DL10:	ld	a,'1'
	ROM_CALL(M_CHARPUT)
	ld	a,'0'
	ROM_CALL(M_CHARPUT)
DLRet:	ld	de,(PROGRAM_ADDR)

UpdateLastLevel:
	ld	a,(LEVEL)
	ld	b,a
	ld	de,(PROGRAM_ADDR)
	ld	hl,lastPlayedLevel
	add	hl,de
	ld	a,(hl)
	cp	b
	ret	nc
	ld	(hl),b
	ret

msgGameOver:		.db	"Game Over",0
msgLevelDone1:		.db	"Level completed.",0
msgLevelDone2:		.db	"Score so far: ",0
msgLevelDone3:		.db	"Press ENTER for",0
msgLevelDone4:		.db	"level "
msgLevelDoneX:		.db	"X...",0
msgScore:		.db	"Score: ",0
msgHighscore:		.db	"Highscore: ",0
msgNibblesTitle2:	.db	" (15.2.96)",0
msgNibblesTitle3:	.db	"by Oskar Liljeblad",0
msgNibblesTitle4:	.db	"(ol@kajen.com)",0
msgSetLevel:		.db	207,"/",5,": Starting level",0
msgSetSpeed:		.db	"F1-F5: Speed of snake",0
msgSetSteer:		.db	"MORE: Control of snake",0
msgKeyEnter:		.db	"ENTER: Start game",0
msgKeyExit:		.db	"EXIT: Exit to ZShell",0
msgSpeed1:		.db	"Slowest",0
msgSpeed2:		.db	"Slow         ",0
msgSpeed3:		.db	"Normal  ",0
msgSpeed4:		.db	"Fast            ",0
msgSpeed5:		.db	"Fastest  ",0
msgSteer0:		.db	"2-button",0
msgSteer1:		.db	"4-button",0
msgNewHighscore:	.db	"New Highscore!",0

highscoreData:
	.db	0,0,0,0,0,0
maskSteer:
	.db	0
maskSpeed:
	.dw	550
maskSpeedText:
	.dw	msgSpeed3
maskData:
	.block	masklen_size
maskMoveArray:
	.db	2,0,0,-2,-2,0,0,2
lastPlayedLevel:
	.db	1
;	.db	10
highscore:
	.dw	0
PictureData:
        .db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .db     $1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0
        .db     $3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8
        .db     $70,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$7F,$FF,$FC
        .db     $60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$7F,$FF,$FC
        .db     $67,$C7,$BD,$FF,$1F,$F1,$E0,$7F,$C7,$F0,$00,$00,$00,$7F,$FF,$FC
        .db     $67,$E7,$BD,$FF,$9F,$F9,$E0,$7F,$CF,$F8,$00,$00,$00,$7F,$FF,$FC
        .db     $67,$F7,$BD,$FF,$DF,$FD,$E0,$7F,$DF,$FC,$00,$00,$00,$7F,$FF,$FC
        .db     $60,$7F,$80,$03,$C0,$3D,$E0,$00,$00,$3C,$00,$00,$00,$7F,$FF,$FC
        .db     $60,$3F,$80,$03,$C0,$3D,$E0,$00,$00,$3C,$30,$00,$00,$7F,$FF,$FC
        .db     $67,$9F,$BD,$E3,$DE,$3D,$E0,$78,$1E,$3C,$40,$00,$00,$7F,$FF,$FC
        .db     $67,$8F,$BD,$E3,$DE,$3D,$E0,$78,$1E,$3C,$F6,$70,$00,$7F,$FF,$FC
        .db     $67,$87,$BD,$E3,$DE,$3D,$E0,$78,$1E,$3C,$49,$48,$00,$7F,$FF,$FC
        .db     $67,$87,$BD,$FF,$9F,$F9,$E0,$7F,$DF,$00,$49,$48,$00,$7F,$FF,$FC
        .db     $67,$87,$BD,$FF,$1F,$F1,$E0,$7F,$CF,$80,$49,$40,$00,$7F,$FF,$FC
        .db     $67,$87,$BD,$FF,$9F,$F9,$E0,$7F,$C7,$C0,$49,$40,$00,$7F,$FF,$FC
        .db     $67,$87,$BD,$E3,$DE,$3D,$E0,$78,$03,$E0,$49,$40,$00,$7F,$FF,$FC
        .db     $67,$87,$BD,$E3,$DE,$3D,$E0,$78,$01,$F0,$46,$40,$00,$7F,$FF,$FC
        .db     $67,$87,$BD,$E3,$DE,$3D,$E0,$78,$00,$F8,$00,$00,$00,$7F,$FF,$FC
        .db     $67,$87,$BD,$E3,$DE,$3D,$E0,$78,$1E,$7C,$00,$00,$00,$7F,$FF,$FC
        .db     $67,$87,$BD,$E3,$DE,$3D,$E0,$78,$1E,$3C,$F3,$20,$0A,$7F,$FF,$FC
        .db     $67,$87,$BD,$E3,$DE,$3D,$E0,$78,$1E,$3C,$14,$A0,$0A,$7F,$FF,$FC
        .db     $67,$87,$BD,$E3,$DE,$3D,$E0,$78,$1E,$3C,$24,$B8,$CA,$7F,$FF,$FC
        .db     $67,$87,$BD,$E3,$DE,$3D,$E0,$78,$1E,$3C,$22,$25,$2A,$7F,$FF,$FC
        .db     $67,$87,$BD,$E3,$DE,$3D,$E0,$78,$1E,$3C,$21,$25,$2A,$7F,$FF,$FC
        .db     $67,$87,$BD,$E3,$DE,$3D,$E0,$78,$1E,$3C,$44,$A5,$EA,$7F,$FF,$FC
        .db     $67,$87,$BD,$FF,$DF,$FD,$FF,$7F,$DF,$FC,$44,$A5,$0A,$7F,$FF,$FC
        .db     $67,$87,$BD,$FF,$9F,$F9,$FF,$7F,$CF,$F8,$84,$A5,$2A,$7F,$FF,$FC
        .db     $67,$87,$BD,$FF,$1F,$F1,$FF,$7F,$C7,$F0,$F3,$24,$CA,$7F,$FF,$FC
        .db     $60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$7F,$FF,$FC
        .db     $60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FC
        .db     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FC
        .db     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FC
        .db     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0,$00,$00,$0C
        .db     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0,$00,$00,$0C
        .db     $7F,$BF,$FC,$FE,$FF,$FF,$75,$7E,$F7,$FD,$FF,$FF,$E0,$F0,$0F,$0C
        .db     $7F,$BF,$FB,$7E,$FF,$FF,$7D,$FE,$F7,$FD,$FF,$FF,$E1,$F0,$1F,$0C
        .db     $7F,$8D,$BB,$66,$D9,$8F,$75,$66,$36,$71,$FF,$FF,$E3,$F0,$3F,$0C
        .db     $7F,$B5,$BB,$5A,$B6,$B7,$75,$5A,$D5,$AD,$FF,$FF,$E3,$F0,$3F,$0C
        .db     $7F,$B5,$BB,$5E,$7E,$B7,$75,$5A,$D7,$AD,$FF,$FF,$E3,$F0,$3F,$0C
        .db     $7F,$B6,$BB,$66,$78,$BF,$75,$42,$D6,$2D,$FF,$FF,$E3,$F0,$3F,$0C
        .db     $7F,$B7,$7B,$7A,$B6,$BF,$75,$5E,$D5,$AD,$FF,$FF,$E0,$F0,$0F,$0C
        .db     $7F,$B7,$7B,$5A,$B6,$BF,$75,$5A,$D5,$AD,$FF,$FF,$E0,$F0,$0F,$0C
        .db     $7F,$8F,$7C,$E6,$D8,$BF,$15,$66,$36,$31,$FF,$FF,$E0,$F0,$0F,$0C
        .db     $7F,$FF,$7F,$FF,$FF,$FF,$FF,$7F,$FF,$FF,$FF,$FF,$E0,$F0,$0F,$0C
        .db     $7F,$FE,$FF,$FF,$FF,$FF,$FE,$FF,$FF,$FF,$FF,$FF,$E0,$F0,$0F,$0C
        .db     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0,$F0,$0F,$0C
        .db     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0,$F0,$0F,$0C
        .db     $7F,$DF,$BC,$7B,$FE,$FF,$FF,$FF,$FD,$FF,$FF,$FF,$E0,$F0,$0F,$0C
        .db     $7F,$BF,$B3,$9B,$FF,$FF,$FF,$FF,$FE,$FF,$FF,$FF,$E0,$F0,$0F,$0C
        .db     $7F,$B9,$B7,$DB,$66,$CC,$7E,$73,$0E,$FF,$FF,$FF,$E0,$F0,$0F,$0C
        .db     $7F,$B6,$AC,$6A,$DA,$B5,$BD,$AD,$56,$FF,$FF,$FF,$E0,$F0,$0F,$0C
        .db     $7F,$B6,$AD,$69,$FA,$B5,$BD,$AD,$56,$FF,$FF,$FF,$E0,$F0,$0F,$0C
        .db     $7F,$B6,$AD,$69,$E2,$85,$BD,$ED,$56,$FF,$FF,$FF,$E0,$F0,$0F,$0C
        .db     $7F,$B6,$AD,$6A,$DA,$BD,$BD,$AD,$56,$FF,$FF,$FF,$E0,$F0,$0F,$0C
        .db     $7F,$B6,$AD,$6A,$DA,$B5,$BD,$AD,$56,$FF,$FF,$FF,$E0,$F0,$0F,$0C
        .db     $7F,$D9,$B4,$9B,$62,$CD,$A6,$73,$55,$FF,$FF,$FF,$E0,$F3,$CF,$0C
        .db     $7F,$FF,$F3,$FF,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0,$F3,$CF,$0C
        .db     $7F,$FF,$FC,$3F,$FD,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0,$F3,$CF,$0C
        .db     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0,$00,$00,$0C
        .db     $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0,$00,$00,$1C
        .db     $3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8
        .db     $1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0
	.end
