;LOOK!
; A little demo (C)1996 by Andreas Ess
;If you use any routine, give me an appropriate credit. Thanks.
; Write a letter to:
;  Andreas Ess
;  Tufers 156
;  A-6811 Goefis
;  Austria/Europe
;-----------------------------------------------------------------------------

#INCLUDE "TI-85.H"

;-----------------------------------------------------------------------------
;Variables in TEXTMEM
;-----------------------------------------------------------------------------
;Starfield:
Stars = TEXT_MEM      ;90 bytes -> 30 star's x, y, z position
XPos = TEXT_MEM+90
YPos = TEXT_MEM+91
ZPos = TEXT_MEM+92
SQUOT = TEXT_MEM+93
SREM = TEXT_MEM+94
;Scroller:
ScrollPos = TEXT_MEM+95
ScrollX = TEXT_MEM+97
TempX = TEXT_MEM+98
TempByte = TEXT_MEM+99
ScrollBuf = TEXT_MEM+100 ;needs 16 bytes...
Header = TEXT_MEM+116

.org 0
.db "LOOK! V0.1 YOURSELF...",0

Start:
 ld   a, 4        
 out  (5), a      
 ;STARFIELD INITIALISATION:
 ld   hl, (PROGRAM_ADDR)
 ld   de, RStars
 add  hl, de
 ld   de, Stars
 ld   bc, 90
 ldir
 ;SCROLLER INITIALISATION:
 ld  a, 126
 ld  (ScrollX), a
WNoKey:
 call GET_KEY
 cp   0
 jr   nz, WNoKey
DemoLoop:
 ;First, clear DoubleBuffer:
 ld   a, 0
 ld   bc, 1024
 ld   hl, GRAPH_MEM
ClearL:
 ld   a, 0
 ld   (hl), a
 inc  hl
 dec  bc
 ld   a, b
 or   c
 jr   nz, ClearL
 ;Do stuff:
 CALL_(DoStars)
 CALL_(DoScrolly)
 CALL_(DoMirror)
 ;show buffer:
 ld   bc, 1024
 ld   hl, GRAPH_MEM
 ld   de, VIDEO_MEM
 ldir
 call GET_KEY
 cp   0
 jr   z, DemoLoop
 ret

;-----------------------------------------------------------------------------
;DoMirror
;-----------------------------------------------------------------------------
DoMirror:
 ld    bc, 16
 ld    hl, $8641
 ld    de, $8A31
 ldir
 ld    bc, 16
 ld    hl, $8671
 ld    de, $8A21
 ldir
 ld    bc, 16
 ld    hl, $86A1
 ld    de, $8A11
 ldir
 ld    bc, 16
 ld    hl, $87C1
 ld    de, $8A01
 ldir
 ld    bc, 16
 ld    hl, $8841
 ld    de, $89F1
 ldir
 ld    bc, 16
 ld    hl, $88C1
 ld    de, $89E1
 ldir
 ret

;-----------------------------------------------------------------------------
;DoStars
;-----------------------------------------------------------------------------
DoStars:
 ld   b, 30
 ld   hl, Stars
DoStarLoop:
 push bc
 ;recalculate it's position
 ld   a, (hl)
 ld   (XPos), a
 inc  hl
 ld   a, (hl)
 ld   (YPos), a
 inc  hl
 ld   a, (hl)
 ld   (ZPos), a
 dec  a
 jr   nz, IncHL
 ld   a, 32
IncHL:
 ld   (hl), a
 inc  hl
 push hl
 ;Calculate 2D-XPos by saying XPos2D = 4*XPos3D/ZPos3D
 ld   de, 64
 ld   a, (XPos)
 ld   h, 0
 ld   l, a
 or   a      ;clear carry
 sbc  hl, de
 add  hl, hl
 ld   a, (ZPos)
 ld   d, 0
 ld   e, a
 CALL_(SDIV16)
 ld   de, 64
 add  hl, de
 ld   b, l          ;B now contains X-Pos
 ;Calculate 2D-YPos by saying YPos2D = 4*YPos3D/ZPos3D
 ld   de, 32
 ld   a, (YPos)
 ld   h, 0
 ld   l, a
 or   a
 sbc  hl, de
 add  hl, hl
 ld   a, (ZPos)
 ld   d, 0
 ld   e, a
 CALL_(SDIV16)
 ld   de, 32
 add  hl, de
 ld   c, l          ;C now contains X-Pos
 ;finally, show it:
 CALL_(PointOn)
 pop  hl
 pop  bc
 djnz DoStarLoop
 ret

;-----------------------------------------------------------------------------
;SDIV16: signed division, uses UDIV16
;-----------------------------------------------------------------------------
SDIV16:
 push  bc
 ld    a, h
 ld    (SREM), a
 xor   d
 ld    (SQUOT), a

 bit   7, d
 jr    z, CheckDE
 or    a
 sub   a
 sub   e
 ld    e, a
 sbc   a, a
 sub   d
 ld    d, a

CheckDE:
 bit   7, h
 jr    z, DoDiv
 or    a
 sub   a
 sub   l
 ld    l, a
 sbc   a, a
 sub   h
 ld    h, a

DoDiv:
 CALL_(UDIV16)

 ld    a, (SQUOT)
 bit   7, a
 jr    z, DoRem    ;!
 or    a
 sub   a
 sub   l
 ld    l, a
 sbc   a, a
 sub   h
 ld    h, a

DoRem:
 pop   bc
 ret

;-----------------------------------------------------------------------------
;UDIV16: divides HL trough DE
; quotient in HL
; remainder in DE
; carry = 0
;-----------------------------------------------------------------------------
UDIV16:

Divide:
 ld    c, l
 ld    a, h
 ld    hl, 0       ;hl = remainder
 ld    b, 16       ;16 bits in dividend
 or    a           ;clear carry

DivLoop:
 rl    c
 rla
 rl    l
 rl    h

 push  hl
 sbc   hl, de
 ccf

 jr    c, Drop
 ex    (sp), hl
Drop:
 inc   sp
 inc   sp
 djnz  DivLoop

 ex    de, hl
 rl    c
 ld    l, c
 rla
 ld    h, a
 or    a
 ret

;-----------------------------------------------------------------------------
;PointOn: draws point at b=x, c=y
;-----------------------------------------------------------------------------
PointOn:
 push hl
 push bc
 push de
 ROM_CALL(FIND_PIXEL)  ;HL=byte offset in video buffer, A=2^(bit to change)
 ld   de, GRAPH_MEM
 add  hl, de
 or   (hl)
 ld   (hl), a
 pop  de
 pop  bc
 pop  hl
 ret

;-----------------------------------------------------------------------------
;DoScrolly
;-----------------------------------------------------------------------------
DoScrolly:
 ld   hl, (PROGRAM_ADDR)
 ld   de, TheScrolly
 add  hl, de
 ld   de, (ScrollPos)   ;position in scrolltext
 add  hl, de
 ld   de, TEXT_MEM+100
 ld   bc, 16
 ldir
 ld   a, 0
 ld   (TEXT_MEM+117), a
 ;Now, show bitmaps according to buffer
 ld   a, (ScrollX)
 ;divide 128-a by 8
 ld   b, a
 ld   a, 128
 sub  b
 srl  a
 srl  a
 srl  a
 inc  a
 ld   b, a          ;b contains letters to draw
 ld   a, (ScrollX)
 ld   (TempX), a
 ld   c, 0
DrawLetter:
 push bc
 ld   hl, TEXT_MEM+100
 ld   d, 0
 ld   e, c
 add  hl, de
 ld   a, (hl)             ;A now contains letter
 ld   hl, (PROGRAM_ADDR)
 ld   de, Space
 add  hl, de
 ex   de, hl
 ld   h, 0
 ld   l, a
 add  hl, hl
 add  hl, hl
 add  hl, hl
 add  hl, de
 ex   de, hl
 ld   a, (TempX)
 ld   b, a
 ld   c, 0
 CALL_(Bitmap)
 ld   a, (TempX)
 add  a, 8
 ld   (TempX), a
 pop  bc
 inc  c
 djnz DrawLetter
 ;change ScrollX
 ld   a, (ScrollX)
 dec  a
 dec  a
 jr   nz, GoOnScrolly
 ld   hl, (ScrollPos)
 inc  hl
 ld   (ScrollPos), hl
 ld   a, 8
GoOnScrolly:
 ld   (ScrollX), a
 ;draw 'AE' at pos 0, 0
 ld   b,  8
 ld   hl, (PROGRAM_ADDR)
 ld   de, MyLogo
 add  hl, de
 ld   de, GRAPH_MEM
 ldi
 ld   de, GRAPH_MEM+16
 ldi
 ld   de, GRAPH_MEM+32
 ldi
 ld   de, GRAPH_MEM+48
 ldi
 ld   de, GRAPH_MEM+64
 ldi
 ld   de, GRAPH_MEM+80
 ldi
 ld   de, GRAPH_MEM+96
 ldi
 ld   de, GRAPH_MEM+112
 ldi
 ld   de, GRAPH_MEM+128
 ret

;-----------------------------------------------------------------------------
;Draws a sprite DE at position (B,C)
;-----------------------------------------------------------------------------
Bitmap:
 push bc
 ld   a, 0                 ;store 0 into TempByte
 ld   (TempByte), a
 ld   h, 0                 ;store y-position into hl and
 ld   l, c                 ;multiplicate it by 16
 add  hl, hl ;*2
 add  hl, hl ;*4
 add  hl, hl ;*8
 add  hl, hl ;*16
 push de                   ;save de & bc temporary
 push bc
 srl  b                    ;divide b by 8
 srl  b
 srl  b
 ld   d,  0                ;load edited x-position into de
 ld   e,  b                ;add it to y-position
 add  hl, de               ;and finally
 ld   de, GRAPH_MEM        ;let it point to the vid-ram
 add  hl, de
 pop  bc                   ;pop de & bc
 pop  de
 ld   a, b                 ;load real x-position
 and  7                    ;into and make
 cp   0                    ;something like mod(a,7)
 ld   c, 128               ;c is the video-mask,
 ld   b, 128               ;b the bitmap-mask
 jr   z, Loop              ;if modulo = 0, jump directly to drawloop
 ld   b, a                 ;else shift right mod(a,7) times
Shift:
 srl  c
 djnz Shift
 ld   b, 128               ;b is 128 = bit 7 of bitmap
Loop:
 ld   a, (de)              ;load bitmap-data into a
 and  b                    ;test only one bit
 jr   z, Loop1             ;if bit = zero; erase point
 ld   a, (hl)              ;otherwise, draw point
 or   c
 ld   (hl), a              ;now save this into video-ram
Loop1:
 srl  c                    ;and shift the video-mask -> next pixel
 jr   nz, Loop2            ;if mask is zero -> fill 128 into c
 ld   c, 128               ;and use next byte of vid-data
 inc  hl
Loop2:
 srl  b                    ;now shift the bitmap-mask
 jr   nz, Loop             ;if <> zero, loop again
NextLine:
 push de                   ;save de
 ld   de, 15
 add  hl, de               ;add 15 bytes to hl
 pop  de
 inc  de                   ;and increment bitmap-pointer
 ld   b, 128               ;load 128 into bitmap-pointer
 ld   a, (TempByte)        ;TempByte holds line
 inc  a
 ld   (TempByte), a
 cp   8
 jr   nz, Loop             ;if line<8, loop again
EndBMP:
 pop  bc
 ret

;-----------------------------------------------------------------------------
;Delay: waits
;-----------------------------------------------------------------------------
Delay:
 ld bc, $1000
DelayLoop:
 dec bc
 ld a, b
 or c
 jr nz, DelayLoop
 ret

;-----------------------------------------------------------------------------
;Pre-calculated stars
;-----------------------------------------------------------------------------
RStars:
 ;    X   Y   Z
 .db $1,$0,$A
 .db $4,$16,$6
 .db $44,$C,$16
 .db $78,$11,$E
 .db $D,$2B,$12
 .db $5,$A,$1A
 .db $57,$30,$1A
 .db $79,$D,$D
 .db $78,$34,$1D
 .db $66,$1C,$13
 .db $54,$25,$11
 .db $5B,$7,$C
 .db $F,$2A,$F
 .db $3E,$23,$B
 .db $6E,$10,$5
 .db $35,$2B,$5
 .db $44,$28,$13
 .db $0,$31,$8
 .db $3A,$18,$C
 .db $49,$26,$8
 .db $15,$32,$9
 .db $2A,$19,$7
 .db $34,$3,$F
 .db $7C,$0,$D
 .db $8,$4,$8
 .db $7B,$16,$C
 .db $19,$C,$6
 .db $1F,$2F,$1C
 .db $72,$2E,$E
 .db $43,$2,$4

;-----------------------------------------------------------------------------
;The scroller itself:
;-----------------------------------------------------------------------------
TheScrolly:
 .db $12,$13,$0,$19,$1F,$1E,$0,$1E,$12,$F,$1C,$F,$2F,$0,$21,$F
 .db $16,$D,$19,$17,$F,$0,$1E,$19,$0,$17,$23,$0,$28,$16,$19,$19
 .db $15,$2F,$28,$0,$E,$F,$17,$19,$2E,$0,$21,$F,$16,$16,$2D,$0
 .db $1E,$12,$13,$1D,$0,$21,$19,$18,$28,$1E,$0,$E,$19,$0,$B,$18
 .db $23,$1E,$12,$13,$18,$11,$0,$F,$16,$1D,$F,$0,$1E,$12,$B,$18
 .db $0,$1D,$D,$1C,$19,$16,$16,$0,$B,$0,$1E,$F,$22,$1E,$0,$B
 .db $18,$E,$0,$1D,$12,$19,$21,$0,$1E,$12,$13,$1D,$0,$10,$B,$18
 .db $1E,$B,$1D,$1E,$13,$D,$0,$4,$E,$2C,$1D,$1E,$B,$1C,$1D,$2E
 .db $0,$10,$13,$1C,$1D,$1E,$0,$13,$0,$21,$B,$18,$1E,$F,$E,$0
 .db $1E,$19,$0,$B,$E,$E,$0,$4,$E,$2C,$D,$1F,$C,$F,$1D,$2D
 .db $0,$C,$1F,$1E,$0,$13,$1E,$0,$E,$13,$E,$18,$28,$1E,$0,$21
 .db $19,$1C,$15,$2E,$2E,$2E,$0,$12,$19,$21,$F,$20,$F,$1C,$2D,$0
 .db $12,$F,$1C,$F,$0,$B,$1C,$F,$0,$1E,$12,$F,$0,$11,$1C,$F
 .db $F,$1E,$13,$18,$11,$1D,$26,$0,$E,$B,$18,$0,$F,$C,$16,$F
 .db $2D,$0,$17,$B,$11,$18,$1F,$1D,$0,$12,$B,$11,$B,$18,$E,$F
 .db $1C,$2D,$0,$1C,$19,$C,$F,$1C,$1E,$0,$1E,$B,$23,$16,$19,$1C
 .db $0,$2C,$0,$10,$19,$1C,$0,$24,$1D,$12,$F,$16,$16,$0,$2C,$0
 .db $C,$1C,$13,$B,$18,$0,$11,$1C,$B,$23,$0,$2C,$0,$13,$0,$12
 .db $19,$1A,$F,$0,$23,$19,$1F,$0,$11,$19,$1E,$0,$17,$23,$0,$16
 .db $F,$1E,$1E,$F,$1C,$2D,$0,$1E,$13,$17,$0,$10,$13,$1E,$24,$1C
 .db $B,$18,$E,$19,$16,$1A,$12,$0,$2C,$0,$10,$19,$1C,$0,$1D,$F
 .db $18,$E,$13,$18,$11,$0,$17,$F,$0,$18,$B,$1D,$1C,$0,$2C,$0
 .db $14,$13,$18,$11,$23,$B,$18,$11,$0,$22,$1F,$2D,$0,$D,$12,$1C
 .db $13,$1D,$0,$C,$1F,$1D,$D,$12,$2D,$0,$B,$18,$E,$0,$B,$16
 .db $16,$0,$1E,$12,$F,$0,$19,$1E,$12,$F,$1C,$1D,$0,$21,$12,$19
 .db $0,$21,$1C,$13,$1E,$F,$0,$1D,$19,$0,$10,$B,$18,$1E,$B,$1D
 .db $1E,$13,$D,$0,$11,$B,$17,$F,$1D,$2E,$0,$11,$B,$17,$F,$1D
 .db $0,$2C,$0,$E,$1F,$1C,$13,$18,$11,$0,$1E,$12,$F,$0,$16,$B
 .db $1D,$1E,$0,$21,$F,$F,$15,$1D,$0,$13,$0,$E,$13,$E,$18,$28
 .db $1E,$0,$21,$1C,$19,$1E,$F,$0,$B,$18,$23,$1E,$12,$13,$18,$11
 .db $0,$C,$F,$D,$B,$1F,$1D,$F,$0,$13,$0,$21,$B,$1D,$0,$B
 .db $D,$1E,$13,$20,$F,$0,$19,$18,$0,$1E,$12,$F,$0,$1A,$D,$2E
 .db $2E,$2E,$0,$1D,$19,$1C,$1C,$23,$2F,$0,$1A,$F,$1C,$12,$B,$1A
 .db $1D,$0,$13,$28,$16,$16,$0,$1C,$F,$16,$F,$B,$1D,$F,$0,$B
 .db $0,$15,$13,$18,$E,$0,$19,$10,$0,$1A,$B,$1A,$F,$1C,$C,$19
 .db $23,$0,$13,$10,$0,$13,$28,$20,$F,$0,$11,$19,$1E,$0,$1E,$13
 .db $17,$F,$2E,$0,$19,$15,$B,$23,$2D,$0,$1E,$12,$B,$1E,$28,$1D
 .db $0,$13,$1E,$2D,$0,$C,$23,$F,$2F,$0

;-----------------------------------------------------------------------------
;My own font:
;-----------------------------------------------------------------------------
MyLogo: .db $40,$A0,$E0,$A7,$A4,$06,$04,$07
Space: .db $0,$0,$0,$0,$0,$0,$0,$0
Letter0: .db $7C,$E6,$EA,$EA,$EA,$F2,$7C,$0
Letter1: .db $38,$78,$B8,$38,$38,$38,$38,$0
Letter2: .db $7C,$8E,$1C,$38,$70,$E0,$FE,$0
Letter3: .db $FC,$FE,$6,$C,$6,$FE,$FC,$0
Letter4: .db $CC,$CC,$CC,$FC,$1C,$1C,$1C,$0
Letter5: .db $FC,$C0,$C0,$F8,$C,$C,$F8,$0
Letter6: .db $7C,$E2,$E0,$FC,$E2,$E2,$7C,$0
Letter7: .db $FE,$E,$1C,$38,$70,$E0,$E0,$0
Letter8: .db $7C,$E6,$E6,$7C,$E6,$E6,$7C,$0
Letter9: .db $7C,$8E,$8E,$7E,$E,$8E,$7C,$0
LetterA: .db $7C,$F6,$F6,$FE,$F6,$F6,$F6,$0
LetterB: .db $FC,$E2,$FC,$E2,$E2,$FE,$FC,$0
LetterC: .db $7C,$E2,$E0,$E0,$E0,$E2,$7C,$0
LetterD: .db $FC,$E2,$E2,$E2,$E2,$E2,$FC,$0
LetterE: .db $FC,$E0,$F8,$E0,$E0,$E0,$FC,$0
LetterF: .db $FE,$E0,$F8,$E0,$E0,$E0,$E0,$0
LetterG: .db $7C,$E2,$E0,$E0,$EE,$E6,$7C,$0
LetterH: .db $E6,$E6,$E6,$FE,$E6,$E6,$E6,$0
LetterI: .db $38,$38,$38,$38,$38,$38,$38,$0
LetterJ: .db $1C,$1C,$1C,$1C,$9C,$DC,$78,$0
LetterK: .db $E2,$E4,$E8,$F8,$E4,$E2,$E2,$0
LetterL: .db $E0,$E0,$E0,$E0,$E0,$E0,$FE,$0
LetterM: .db $C6,$EE,$D6,$C6,$C6,$C6,$C6,$0
LetterN: .db $E2,$E2,$F2,$EA,$E6,$E2,$E2,$0
LetterO: .db $7C,$E2,$E2,$E2,$E2,$E2,$7C,$0
LetterP: .db $FC,$E2,$E2,$FC,$E0,$E0,$E0,$0
LetterQ: .db $7C,$E2,$E2,$E2,$EA,$E6,$7C,$0
LetterR: .db $FC,$E2,$E2,$FC,$E8,$E4,$E2,$0
LetterS: .db $7C,$E0,$E0,$78,$1C,$1C,$F8,$0
LetterT: .db $FE,$38,$38,$38,$38,$38,$38,$0
LetterU: .db $E2,$E2,$E2,$E2,$E2,$E2,$7C,$0
LetterV: .db $C4,$C4,$C4,$64,$6C,$68,$38,$0
LetterW: .db $C6,$C6,$C6,$C6,$C6,$D6,$EE,$0
LetterX: .db $C6,$C6,$6C,$38,$6C,$C6,$C6,$0
LetterY: .db $84,$CC,$78,$30,$30,$30,$30,$0
LetterZ: .db $FE,$E,$1C,$38,$70,$E0,$FE,$0
Asking: .db $7C,$C6,$C,$18,$30,$0,$30,$0
DPoint: .db $0,$60,$60,$0,$0,$60,$60,$0
Semikol: .db $0,$30,$30,$0,$30,$30,$30,$60
Apostro: .db $60,$60,$60,$0,$0,$0,$0,$0
Par1: .db $60,$C0,$C0,$C0,$C0,$C0,$60,$0
Par2: .db $C0,$60,$60,$60,$60,$60,$C0,$0
Plus: .db $38,$38,$FE,$FE,$FE,$38,$38,$0
Minus: .db $0,$0,$0,$7E,$7E,$0,$0,$0
BStrich: .db $0,$0,$0,$0,$0,$30,$30,$60
Point: .db $0,$0,$0,$0,$0,$60,$60,$0
Rufe: .db $60,$60,$60,$60,$60,$0,$60,$0

.end
