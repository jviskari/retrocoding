;if you have any questions just ask me ELinenberg@gnn.com	
;snake.asm

#include "ti-85.h"

.org 0
.db "Snake v0.0", 0

X 	= $80DF  
Y 	= $80E0  
lastkey	= $80E1
Start:
        ld 	a,63
        ld 	(X),a    
        ld 	a,31
        ld 	(Y),a    
        ld	a,1
        ld	(lastkey),a
        ld 	a,4
        out 	(5),a
        ROM_CALL(CLEARLCD)   

Keyloop:
        call 	GET_KEY
        cp 	K_EXIT
        ret 	z
        cp 	K_LEFT
        jr	z,left       
        cp 	K_RIGHT          
        jr	z,right      
	cp	K_UP
	jr	z,up
	cp	K_DOWN
	jr	z,down
	ld	a,(lastkey)
	cp	1
	jr	z,up
	cp	2
	jr	z,down
	cp	3
	jr	z,left
	cp	4
	jr	z,right	
Up:
        ld	a,1
        ld	(lastkey),a
        ld 	a,(Y)
        inc 	a
        ld 	(Y),a
        jr	delay
Down:
        ld	a,2
        ld	(lastkey),a
        ld	a,(Y)
	dec 	a
        ld 	(Y),a
        jr	delay
Left:
        ld	a,3
        ld	(lastkey),a
        ld 	a,(X)
        dec 	a
        ld 	(X),a
        jr	delay
Right:
        ld	a,4
       	ld	(lastkey),a
        ld 	a,(X)
        inc 	a
        ld 	(X),a
       ;jr	delay	not needed becuase delay is next

Delay:
        ld 	a,$3F
        ld 	b,$3F

DelayLoop:
        dec 	a
        jr 	nz, DelayLoop
        dec 	b
        jr 	nz, DelayLoop
        
DrawDot:
        ld 	a,(X)
        ld 	b,a          
        ld 	a,(Y)
        ld 	c,a
PlotPixel:
        ROM_CALL(FIND_PIXEL)
        ld 	de,$FC00
        add 	hl,de
        or 	(HL)
        ld 	(HL),a
        jr	keyloop

        

.end
