    ; ***************************************************
    ; *
    ; *                H Y P E R G A L A G A
    ; *
    ; *
    ; *           Programmed by Patrick Davidson
    ; *
    ; *             last updated : 7-May-97
    ; *
    ; ***************************************************
 ; -------------- PROGRAM HEADER --------------------
         .org     0
         .include "ti-85.h"
         .db      "1.0.055 / Patrick Davidson"
         .db      0
.define  RAND     ld hl,(rptr) \ inc hl \ res 7,h \ ld (rptr),hl \ ld a,(hl)
.define  SCORE(p) ld hl,(score) \ ld de, p \ add hl,de \ ld (score),hl
 ; -------------- VARIABLE ADDRESSES ----------------
scrlstart =$8014
scrlpos  =$8016
score    =$8010
x        =$8012
y        =$8013
bullets  =$8014   ; 10 entries of 8 bytes
f1data   =$8064  
lives    =$8065
timer    =$8066
rptr     =$8067
nexten   =$8069
cheat    =$806a
contrast =$806b
cc       =$806c
f2data   =$806d
goodx    =$806e
goody    =$806f
goods    =$8070
invinc   =$8071
temp     =$8072
ebuls    =$80df   ; 16 entries of 8 bytes
enemies  =$815f   ; 4 entries of 8 bytes
sprtemp  =$817f
 ; -------------- INITIALIZATION CODE ---------------
         ld       (iy+13),0
         ROM_CALL(CLEARLCD)
         ld       b,96
         ld       a,32
         ld       ix,$8641
pcl:     ld       hl,0
         ld       ($800c),hl
         push     af
         push     bc
         ROM_CALL(TX_CHARPUT)
         ld       hl,$fc00
         ld       b,8
         ld       de,16
il2:     ld       a,(hl)
         ld       (ix),a
         add      hl,de
         inc      ix
         djnz     il2
         pop      bc
         pop      af
         inc      a
         djnz     pcl
         ld       a,1
         ld       (ZS_BITS),a
         ld       de,$800f
         ld       hl,$80df
         ld       bc,101
         ldir
         ld       a,(CONTRAST)
         inc      a
         cp       $20
         jr       nz,ok1
         dec      a
ok1:     inc      a
         cp       $20
         jr       nz,ok2
         dec      a
ok2:     inc      a
         cp       $20
         jr       nz,ok3
         dec      a
ok3:     ld       (contrast),a
         out      (2),a
         CALL_(display_ttl_scr)
         jr       z,nocheat
         cp       K_F4
         jr       nz,nocheat
         ld       a,255
         ld       (cheat),a
nocheat: di
         push     iy
         CALL_(play_game)
         pop      iy
         ei
         ld       a,(CONTRAST)
         out      (2),a
         ld       a,%00111111
         out      (1),a
         in       a,(1)
         bit      7,a
         jr       nz,not_2nd
         ld       a,3
         ld       (ZS_BITS),a
         ld       de,(PROGRAM_ADDR)
         ld       hl,save
         add      hl,de
         ld       (hl),1
         push     hl
         pop      de
         inc      de
         ld       hl,$8010
         ld       bc,100
         ldir
         ld       hl,$80df
         ld       bc,160
         ldir
         ret
not_2nd: CALL_(your_score)
         ROM_CALL(CLEARLCD)
         ld       ($800c),de
         ld       de,(PROGRAM_ADDR)
         ld       hl,hstitle
         add      hl,de
         ROM_CALL(D_ZT_STR)
         ld       hl,$1001
         ld       ($800c),hl
         ld       ix,hsdata
         add      ix,de
         ld       b,7
         ld       de,17
high_display_loop:
         ld       l,(ix+0)
         ld       h,(ix+1)
         push     de
         push     hl
         ROM_CALL(D_HL_DECI)
         pop      hl
         pop      de
         ld       hl,$800c
         dec      (hl)
         inc      ix
         inc      ix
         push     ix
         pop      hl
         ROM_CALL(D_ZT_STR)
         add      ix,de
         ld       hl,$800c
         inc      (hl)
         djnz     high_display_loop
loop_wk: call     GET_KEY
         or       a
         ret      nz
         jr       loop_wk
 ; -------------- SCORING ---------------------------
your_score:
         ROM_CALL(CLEARLCD)
         ld       ($800c),de
         ld       hl,score_t
         ld       de,(PROGRAM_ADDR)
         add      hl,de
         ROM_CALL(D_ZT_STR)
         ld       hl,$1000
         ld       ($800c),hl
         ld       hl,(score)
         ROM_CALL(D_HL_DECI)
wkls:    call     GET_KEY
         cp       K_ENTER
         jr       nz,wkls
         ld       hl,lowest                  ;See if ya got a hi-score
         ld       de,(PROGRAM_ADDR)
         add      hl,de
         call     LD_HL_MHL
         ld       de,(score)
         call     CP_HL_DE
         ret      nc
         ld       a,(cheat)
         or       a
         ret      nz
         ROM_CALL(CLEARLCD)
         ld       ($800c),de
         ld       de,(PROGRAM_ADDR)
         ld       hl,hi_score_str
         add      hl,de
         ROM_CALL(D_ZT_STR)
         ld       ix,lowest
         inc      de
         inc      de
         add      ix,de
         ld       (temp),ix
         ld       b,16
         ld       c,32
space_loop:
         ld       (ix),c
         inc      ix
         djnz     space_loop
         ld       ix,(temp)
         ld       b,0
enter_name_loop:
         call     GET_KEY
         cp       0
         jr       z,enter_name_loop
         cp       K_DEL
         jr       z,backup
         cp       K_ENTER
         jr       z,nomore
         ld       c,a
         ld       a,15
         cp       b
         jr       z,enter_name_loop
         ld       hl,chartable
         ld       de,(PROGRAM_ADDR)
         add      hl,de
         ld       e,c
         ld       d,0
         add      hl,de
         ld       a,(hl)
         ld       (ix),a
         ROM_CALL(TX_CHARPUT) 
         inc      b
         inc      ix
         jr       enter_name_loop
backup:  dec      b
         ld       a,255
         cp       b
         jr       z,too_far
         dec      ix
         ld       (ix),32
         ld       hl,$800d
         dec      (hl)
         ld       a,32
         ROM_CALL(TX_CHARPUT)
         dec      (hl)
         jr       enter_name_loop
too_far: inc      b
         jr       enter_name_loop
nomore:  ld       hl,lowest
         ld       de,(PROGRAM_ADDR)
         add      hl,de
         ld       de,(score)
         ld       (hl),e
         push     hl
         inc      hl
         ld       (hl),d
         pop      ix              ;sort hiscore table
         ld       b,6
sort_scores:
         ld       e,(ix)
         ld       d,(ix+1)
         ld       l,(ix-19)
         ld       h,(ix-18)
         call     CP_HL_DE
         ret      nc
         push     bc
         ld       b,19
         ld       d,0
exg_loop:ld       e,(ix)
         ld       c,(ix-19)
         ld       (ix),c
         ld       (ix-19),e
         inc      ix
         djnz     exg_loop
         ld       de,-38
         add      ix,de
         pop      bc
         djnz     sort_scores
         ret
score_t: .db      "-> FINAL SCORE :     "
         .db      "--> PRESS [ENTER] <--",0
saved:   inc      sp
         inc      sp
         xor      a
         or       a
         ret
 ; -------------- TITLE SCREEN ----------------------
display_ttl_scr:
         ROM_CALL(CLEARLCD)
         ld       ($800c),de
         ld       (score),de
         ld       hl,title
         ld       de,(PROGRAM_ADDR)
         add      hl,de
         ROM_CALL(D_ZT_STR)
         push     hl
         ld       hl,save
         ld       de,(PROGRAM_ADDR)
         add      hl,de
         ld       a,(hl)
         or       a
         jr       nz,saved
         pop      hl
         ld       ix,$800c
         inc      (ix)
         ROM_CALL(D_ZT_STR)
         inc      (ix)
         ROM_CALL(D_ZT_STR)
         ld       hl,scrltext
         add      hl,de
         ld       (scrlstart),hl
         ld       hl,$0806
         ld       ($8941),hl
intro_loop:
         ld       hl,$89c1
         ld       b,128
clrg:    ld       (hl),0
         inc      hl
         djnz     clrg
         ld       hl,(scrlpos)
         inc      hl
         ld       (scrlpos),hl
         ld       de,(scrl_end-scrltext)*8
         call     CP_HL_DE
         jr       nz,not_end_of_text
         ld       hl,0
         ld       (scrlpos),hl
not_end_of_text:
         ld       de,(scrlpos)
         ld       hl,(scrlstart)
         ld       b,3
fspl:    res      0,e
         srl      d
         jr       nc,no_ovfs
         set      0,e
no_ovfs: rrc      e
         djnz     fspl
         add      hl,de
         ld       b,15
         ld       a,(scrlpos)
         cpl
         and      7
         ld       e,a
scroll:  ld       a,(hl)
         inc      hl
         push     hl
         push     bc
         ld       hl,$8541
         push     de
         ld       de,8
         ld       b,a
scroll_draw:
         add      hl,de
         djnz     scroll_draw
         ld       b,8
         ld       ix,$8943
copy_char:
         ld       a,(hl)
         ld       (ix),a
         inc      ix
         inc      hl
         djnz     copy_char
         pop      de
         ld       b,e
         ld       c,56
         ld       ix,$8941
         push     de
         CALL_(drw_spr)
         pop      de
         ld       a,e
         add      a,8
         ld       e,a
         pop      bc
         pop      hl
         djnz     scroll
         ld       ix,$89c1
         ld       b,8
blocks__:ld       (ix),255
         ld       (ix+15),255
         push     bc
         ld       bc,16
         add      ix,bc
         pop      bc
         djnz     blocks__
         ld       hl,$89c1
         ld       de,$ff80
         ld       bc,128
         ldir
         call     GET_KEY
         or       a
         JUMP_Z(intro_loop)
         ret
title:   .db      "H Y P E R G A L A G A",0
         .db      "by Patrick A Davidson"
         .db      "  (ariwsi@juno.com)  ",0
         .db      "   Version 1.0.055"
         .db      0
scrltext:.db      "                 "
         .db      "WELCOME TO HYPERGALAGA!     "
         .db      "PRESS ANY KEY TO BEGIN!  "
         .db      "IN THE GAME, USE F1 "
         .db      "AND F2 TO SHOOT.  "
         .db      "PAUSE/UNPAUSE WITH ENTER.  "
         .db      "USE + AND - "
         .db      "TO ADJUST THE CONTRAST.  "
         .db      "TO SAVE THE GAME "
         .db      "AND EXIT, PRESS MORE.  "
         .db      "THIS GAME WAS "
         .db      "FINISHED ON 9-MAY-97.  "
         .db      "THE SOURCE CODE "
         .db      "IS 1,523 LINES LONG!  "
         .db      "TEXT RESTARTS..."
scrl_end:.db      "                  "
 ; -------------- THE ACTUAL GAME -------------------
restore: ld       (hl),0
         inc      hl
         ld       de,$8010
         ld       bc,100
         ldir
         ld       de,$80df
         ld       bc,160
         ldir
         jr       rest_pt
play_game:
         ld       ix,$800f
         ld       hl,save
         ld       de,(PROGRAM_ADDR)
         add      hl,de
         ld       a,(hl)
         or       a
         jr       nz,restore
         ld       (ix+3),64
         ld       (ix+4),40
         ld       (ix+86),16
rest_pt: ld       b,(ix+86)
         ld       hl,$fc70
lbl:     ld       (hl),255
         inc      hl
         djnz     lbl
game_loop:
         CALL_(clear_buffer)
         CALL_(move_your_ship)
         CALL_(shoot_f1)
         CALL_(shoot_f2)
         CALL_(do_bullets)
         CALL_(_enemies)
         CALL_(do_ebuls)
         CALL_(chg_contrast)
         ld       a,%00111111
         out      (1),a
         in       a,(1)
         bit      6,a
         ret      z
         bit      7,a
         ret      z
copybuffer:                        
         ld       hl,$86c1
         ld       de,$fc80
         ld       bc,896
         ldir
         CALL_(pause)
         ld       hl,(score)
         ld       de,20000
         call     CP_HL_DE
         jr       nz,game_loop
win:     ld       hl,65535
         ld       (score),hl
         ret
 ; -------------- SPRITE RENDERING ROUTINE ----------
drw_spr: ld       e,128             ;FindPixel NO MORE !!!!!!!!!!!!!!!
         push     bc
         ld       a,b
         and      7                 ;Calculate bit number
         jr       z,done
         ld       b,a
bit_loop:srl      e
         djnz     bit_loop
done:    pop      bc
         ld       a,e
         ld       (sprtemp),a
         ld       hl,$8641          ;Calculate byte number
         srl      b
         srl      b
         srl      b
         ld       a,b               ;A = x shift right (bytes)
         sla      c                 
         sla      c
         ld       b,c               
         sla      c
         sla      c                 ;C = 8 LSBs of Y offset              
         or       c                 ;A = 8 LSBs of offset
         ld       c,a               ;C = 8 LSBs of offset
         ld       a,b
         rlca
         rlca
         and      3
         ld       b,a               ;B = 2 MSBs of offset
         add      hl,bc             ;HL = address
         ld       d,(ix)            ;C is width
         inc      ix
         ld       b,(ix)            ;C is height
         inc      ix
oloop:   push     bc                ;Save # of rows
         push     hl                ;Save screen address
         ld       b,d               ;Load width
         ld       c,(ix)            ;Load one line of image
         inc      ix
         ld       a,(sprtemp)       ;Load pixel mask
iloop:   bit      7,c               ;Test leftmost pixel
         jr       z,noplot          ;See if a plot is needed
         ld       e,a               ;OR pixel with screen
         or       (hl)
         ld       (hl),a
         ld       a,e
noplot:  sla      c
         rrca
         jr       nc,notedge        ;Test if edge of byte reached
         inc      hl                ;Go to next byte
notedge: djnz     iloop
         pop      hl                ;Restore address
         ld       bc,16             ;Go to next line
         add      hl,bc
         pop      bc                ;Restore data
         djnz     oloop
         ret
 ; -------------- MOVE THE PLAYER'S SHIP ------------
move_your_ship:
         ld       ix,$800f
         inc      (ix+87)
         ld       a,%01111110
         out      (1),a
         in       a,(1)
         ld       b,a
         bit      0,b
         jr       z,go_down
         bit      3,b
         jr       z,go_up
lr_motion:
         bit      1,b
         jr       z,go_left
         bit      2,b
         jr       z,go_right
draw_ship:
         ld       b,(ix+3)
         ld       c,(ix+4)
         ld       ix,spr_your_ship
         ld       de,(PROGRAM_ADDR)
         add      ix,de
         ld       a,(invinc)
         or       a
         jr       z,normal
         ld       de,10
         add      ix,de
         dec      a
         ld       (invinc),a
normal:  JUMP_(drw_spr)
go_down: ld       a,(ix+4)
         cp       56
         jr       z,lr_motion
         inc      a
         ld       (ix+4),a
         jr       lr_motion
go_left: ld       a,(ix+3)
         or       a
         jr       z,draw_ship
         dec      a
         dec      a
         ld       (ix+3),a
         jr       draw_ship
go_right:ld       a,(ix+3)
         cp       120
         jr       z,draw_ship
         inc      a
         inc      a
         ld       (IX+3),a
         jr       draw_ship
go_up:   ld       a,(ix+4)
         cp       40
         jr       z,lr_motion
         dec      a
         ld       (ix+4),a
         jr       lr_motion
 ; -------------- SPRITES ---------------------------
spr_your_ship:
         .db      7,8
         .db      %00111000
         .db      %01000100
         .db      %10000010
         .db      %10000010
         .db      %10000010
         .db      %10111010
         .db      %11000110
         .db      %10000010
         .db      7,8
         .DB      %00111000
         .db      %01111100
         .db      %11111110
         .db      %11111110
         .db      %11111110
         .db      %11111110
         .db      %11000110
         .DB      %10000010
spr_bullet_1:
         .db      3,4
         .db      %01000000                  ; Standard enemy bullet
         .db      %11100000                  ; Hit point = (x+1,y+1)
         .db      %11100000
         .db      %11100000
spr_bullet_2:
         .db      3,3
         .db      %01000000
         .db      %11100000
         .db      %01000000
two_icon:.db      5,7
         .db      %01110000
         .db      %10001000
         .db      %00001000
         .db      %00010000
         .db      %00100000
         .db      %01000000
         .db      %11111000
spr_zero:.db      8,8
         .db      %10000001
         .db      %11000011
         .db      %11111111
         .db      %10000001
         .db      %10000001
         .db      %10000001
         .db      %01000010
         .db      %00111100
         .db      8,8
         .db      %11000011
         .db      %10100101
         .db      %10011001
         .db      %10000001
         .db      %10000001
         .db      %01000010
         .db      %00100100
         .db      %00011000
         .DB      8,8
         .db      %10000001
         .db      %10000001
         .db      %10000001
         .db      %11111111
         .db      %11111111
         .db      %01111110
         .db      %00111100
         .db      %00011000
         .db      8,9
         .db      %10000001
         .DB      %11000011
         .DB      %10100101
         .DB      %10011001
         .db      %10000001
         .DB      %10000001
         .db      %01000010
         .db      %00111100
         .db      %00011000
         .db      
enemy_boom:                                  ; enemy blowing up
         .db      8,6
         .db      %00000000
         .db      %00011100
         .DB      %00111110
         .DB      %01010110
         .DB      %00111000
         .DB      %00000000
         .db      8,6
         .db      %00110000
         .db      %01001110
         .DB      %10111110
         .DB      %01001111
         .DB      %00111000
         .DB      %00011010
         .db      8,6
         .db      %11110011
         .db      %01001110
         .DB      %10110101
         .DB      %01000101
         .DB      %00111110
         .DB      %11011010
         .db      8,6
         .db      %11110011
         .db      %01001110
         .DB      %10110101
         .DB      %01000101
         .DB      %00111110
         .DB      %11011010
         .db      8,6
         .db      %01000001
         .db      %00100110
         .DB      %00010101
         .DB      %01000100
         .DB      %00010010
         .DB      %10011010
         .db      8,6
         .db      %01000010
         .db      %00100000
         .DB      %00000001
         .DB      %01000100
         .DB      %00100010
         .DB      %10001010
         .db      8,6
         .db      %00001000
         .db      %11000010
         .DB      %00000000
         .db      %00100000
         .db      %00000001
         .db      %00110000
         .db      8,6
         .db      %00000100
         .DB      %00000000
         .DB      %01000000
         .DB      %00000000
         .db      %00000001
         .db      %00100100
boss_l:  .db      8,8
         .db      %10000000
         .db      %11000000
         .db      %10111111
         .db      %10000001
         .db      %10000001
         .db      %01000001
         .db      %00100001
         .db      %00011111
boss_r:  .db      8,8
         .db      %00000001
         .db      %00000011
         .db      %11111101
         .db      %10000001
         .db      %10000001
         .db      %10000010
         .db      %10000100
         .db      %11111000
spr_enemy_bullet:
         .db      2,2
         .db      %11000000
         .db      %11000000
spr_goodie:
         .db      8,8
         .db      %11111111
         .db      %10000001
         .db      %10111101
         .db      %10011001
         .db      %10011001
         .db      %10111101
         .db      %10000001
         .db      %11111111
mboss_l: .db      8,16
         .Db      %10000001
         .DB      %11000011
         .DB      %10100101
         .DB      %10011001
         .db      %10000001
         .db      %10000001
         .db      %10000001
         .db      %10000001
         .db      %10000001
         .db      %10000001
         .db      %10000001
         .db      %10000001
         .db      %10000001
         .db      %01000010
         .db      %00100100
         .db      %00011000
 ; -------------- SHOOT WITH F1 ---------------------
shoot_f1:ld       a,%00111111
         out      (1),a
         in       a,(1)
         bit      4,a
         jr       nz,no_f1
         ld       a,(f1data)
         or       a
         ret      z
         xor      a
         ld       (f1data),a
         and      15
         ret      nz
         ld       ix,bullets
         ld       b,10
         ld       de,8
seekbul: ld       a,(ix)
         or       a
         jr       z,do_f1_bul
         add      ix,de
         djnz     seekbul
         ret
do_f1_bul:
         ld       (ix),1
         ld       a,(x)
         add      a,2
         ld       (ix+1),a
         ld       a,(y)
         dec      a
         ld       (ix+2),a
         ret
no_f1:   ld       (f1data),a
         ret
 ; -------------- SHOOT WITH F2 ---------------------
shoot_f2:ld       a,(f2data)
         cp       31
         jr       z,full
         inc      a
full:    ld       (f2data),a
         cp       31
         ret      nz
         ld       b,123
         ld       c,57
         ld       ix,two_icon
         ld       de,(PROGRAM_ADDR)
         add      ix,de
         CALL_(drw_spr)
         in       a,(1)
         bit      3,a
         ret      nz
         ld       ix,bullets
         ld       c,-1
         ld       b,10
         ld       de,8
         CALL_(seekbul2)
         ld       ix,bullets
         ld       c,1
         ld       b,10
seekbul2:ld       a,(ix)
         or       a
         jr       z,do_f2_bul
         add      ix,de
         djnz     seekbul2
         ret
do_f2_bul:
         ld       (ix),2
         ld       a,(x)
         add      a,2
         ld       (ix+1),a
         ld       a,(y)
         dec      a
         ld       (ix+2),a
         ld       (ix+3),c
         xor      a
         ld       (f2data),a
         ret
 ; -------------- DRAW BULLETS ---------------------
do_bullets:
         ld       b,10
         ld       ix,bullets
dbl:     ld       a,(ix)
         push     ix
         push     bc
         cp       1
         jr       z,bul_1
         cp       2
         jr       z,bul_2
enddbl:  pop      bc
         pop      ix
         ld       de,8
         add      ix,de
         djnz     dbl
         ret
 ; -------------- DO A TYPE 2 BULLET ---------------
bul_2:   ld       e,(ix+2)
         dec      e
         ld       (ix+2),e
         ld       a,1
         set      0,e
         cp       e
         jr       z,bul_off
         ld       a,(ix+1)
         add      a,(ix+3)
         ld       (ix+1),a
         cp       1
         jr       z,bul_off
         cp       126
         jr       common_bullet
 ; -------------- REMOVE A BULLET ------------------
bul_off: ld       (ix),0
         jr       enddbl
 ; -------------- DO A TYPE 1 BULLET ---------------
bul_1:   ld       e,(ix+2)
         dec      e
         dec      e
         ld       (ix+2),e
         ld       a,1
         set      0,e
         cp       e
common_bullet:
         jr       z,bul_off
         ld       d,(ix+1)
         dec      d
         dec      e
         ld       iy,enemies
         ld       b,4
e_hit_loop:
         ld       a,(iy)
         or       a
         jr       z,nohit
         cp       -1
         jr       z,nohit
         ld       a,d
         sub      (iy+2)
         jr       c,nohit
         bit      6,(iy)
         ld       d,248
         jr       z,no_dbl
         res      3,a
         bit      0,(iy)
         jr       z,no_dbl
         ld       d,240
no_dbl:  and      d
         jr       nz,nohit
         ld       a,e
         sub      (iy+3)
         jr       c,nohit
         and      d
         jr       nz,nohit
         ld       (ix),0
         ld       a,(iy+1)
         dec      a
         ld       (iy+1),a
         bit      7,a
         JUMP_Z(enddbl)
         bit      6,(iy)
         CALL_NZ(bosshit)
         ld       (iy),-1
         LD       (IY+1),0
         SCORE(200)
         JUMP_(enddbl)
nohit:   push     de
         ld       de,8
         add      iy,de
         pop      de
         djnz     e_hit_loop
         ld       b,(ix+1)
         ld       c,(ix+2)
         ld       a,(ix)
         ld       ix,spr_bullet_1
         cp       1
         JR       z,first
         ld       ix,spr_bullet_2
first:   ld       de,(PROGRAM_ADDR)
         add      ix,de
         CALL_(drw_spr)
         JUMP_(enddbl)
 ; -------------- ENEMY THAT IS BLOWING UP ---------
eb:      push     ix
         pop      iy
         ld       c,(ix+1)
         res      0,c
         sla      c
         sla      c
         lD       b,0
         ld       ix,enemy_boom
         ld       de,(PROGRAM_ADDR)
         add      ix,de
         add      ix,bc
         ld       b,(iy+2)
         ld       c,(iy+3)
         CALL_(drw_spr)
         ld       a,(iy+1)
         inc      a
         ld       (iy+1),a
         cp       16
         jr       nz,edone
         ld       (iy),0
         jr       edone
 ; -------------- ENEMIES --------------------------
_enemies:CALL_(new_enemy)
         ld       ix,enemies
         ld       b,4
eloop:   ld       a,(ix)
         cp       1
         push     ix
         push     bc
         jr       z,e1
         CP       -1
         JR       Z,eb
         res      0,a
         cp       64
         JUMP_Z(eboss)
edone:   pop      bc
         pop      ix
         ld       de,8
         add      ix,de
         djnz     eloop
         ret
 ; -------------- DO TYPE 1 ENEMY ------------------
e1:      RAND
         and      7
         jr       nz,nochgpath
         RAND
         bit      0,a
         ld       (ix+4),1
         jr       z,down___
         ld       (ix+4),-1
down___  srl      a
         ld       hl,stuff
         ld       de,(PROGRAM_ADDR)
         add      hl,de
         ld       d,0
         and      15
         ld       e,a
         add      hl,de
         ld       a,(hl)
         ld       (ix+4),a
nochgpath:
         ld       d,120
         CALL_(emove)
         ld       ix,spr_zero
         ld       de,(PROGRAM_ADDR)
         add      ix,de
         ld       de,9
         ld       a,(iy+6)
         or       a
         jr       z,first_img
         push     bc
         ld       de,10
         ld       b,a
neil:    add      ix,de
         djnz     neil
         pop      bc
first_img:
         CALL_(drw_spr)
         ld       a,(timer)
         and      15
         JUMP_NZ(edone)
         RAND
         bit      0,a
         JUMP_Z(edone)
         ld       a,(iy+2)
         add      a,3
         ld       d,a
         ld       a,(iy+3)
         add      a,6
         ld       e,a
         CALL_(put_enemy_bul)
         JUMP_(edone)
 ; -------------- ENEMY MOVEMENT ROUTINE -------------
emove:   ld       a,(ix+2)
         and      254
         jr       nz,notleftside
         ld       (ix+4),1
         jr       notrightside
notleftside:
         cp       d
         jr       nz,notrightside
         ld       (ix+4),-1
notrightside:
         ld       a,(ix+3)
         cp       1
         jr       nz,not_at_top
         ld       (ix+5),1
         jr       not_at_bottom
not_at_top:
         cp       30
         jr       nz,not_at_bottom
         ld       (ix+5),-1
not_at_bottom:
         ld       a,(ix+2)
         add      a,(ix+4)
         ld       (ix+2),a
         ld       b,a
         ld       a,(ix+3)
         add      a,(ix+5)
         ld       (ix+3),a
         push     ix
         pop      iy
         ld       c,a
         ret
 ; -------------- DO A BOSS --------------------------
eboss:   RAND
         and      15
         jr       nz,bnochgpath
         RAND
         bit      0,a
         ld       (ix+4),1
         jr       z,bdown___
         ld       (ix+4),-1
bdown___ srl      a
         ld       hl,stuff
         ld       de,(PROGRAM_ADDR)
         add      hl,de
         ld       d,0
         and      15
         ld       e,a
         add      hl,de
         ld       a,(hl)
         ld       (ix+4),a
bnochgpath:
         ld       d,112
         CALL_(emove)
         ld       a,65
         cp       (ix)
         jr       z,megaboss
         ld       ix,boss_l
         ld       de,(PROGRAM_ADDR)
         add      ix,de
         push     ix
         push     bc
         CALL_(drw_spr)
         pop      bc
         pop      ix
         ld       A,B
         add      a,8
         ld       b,a
         ld       de,10
         add      ix,de
         CALL_(drw_spr)
         ld       a,(timer)
         and      15
         JUMP_NZ(edone)
         ld       d,(iy+2)
         ld       a,(iy+3)
         add      a,5
         ld       e,a
         CALL_(put_enemy_bul)
         ld       a,(iy+2)
         add      a,14
         ld       d,a
         ld       a,(iy+3)
         add      a,5
         ld       e,a
         CALL_(put_enemy_bul)
         JUMP_(edone)
 ; -------------- THE MEGA BOSS --------------------
megaboss:ld       ix,mboss_l
         ld       de,(PROGRAM_ADDR)
         add      ix,de
         push     bc
         push     ix
         CALL_(drw_spr)
         pop      ix
         pop      bc
         ld       a,b
         add      a,8
         ld       b,a
         CALL_(drw_spr)
         ld       a,(timer)
         and      15
         JUMP_NZ(edone)
         ld       d,(iy+2)
         ld       a,(iy+3)
         add      a,12
         ld       e,a
         CALL_(put_enemy_bul)
         ld       a,(iy+2)
         add      a,7
         ld       d,a
         ld       a,(iy+3)
         add      a,16
         ld       e,a
         CALL_(put_enemy_bul)
         ld       a,(iy+2)
         add      a,14
         ld       d,a
         ld       a,(iy+3)
         add      a,12
         ld       e,a
         CALL_(put_enemy_bul)
         JUMP_(edone)
 ; -------------- CREATE A NEW ENEMY ---------------
new_enemy:
         ld       a,(timer)
         cp       199
         ret      nz
         ld       ix,enemies
         ld       b,4
         ld       de,8
emloop:  ld       a,(ix)
         or       a
         jr       z,put_en
         add      ix,de
         djnz     emloop
         ret
put_en:  ld       a,(nexten)
         inc      a
         cp       65
         ret      z
         ld       (nexten),a
         ld       (ix),1                   ;Set up an enemy
         srl      a
         srl      a
         srl      a
         srl      a
         ld       (ix+6),a
         ld       (ix+1),a
         ld       a,(nexten)
         and      15
         jr       nz,not_boss
         ld       (ix),64
         ld       a,(ix+1)
         sla      a
         sla      a
         ld       (ix+1),a
         ld       a,(nexten)
         bit      6,a
         jr       z,not_boss
         ld       (ix),65
         ld       (ix+1),26
         ld       iy,$8346
         ld       hl,0
         ld       ($800c),hl
         ld       hl,ptd
         ld       de,(PROGRAM_ADDR)
         add      hl,de
         ROM_CALL(D_ZT_STR)
         ld       a,(lives)
         ld       b,a
         ld       hl,$fc70
lbl___   ld       (hl),255
         inc      hl
         djnz     lbl___
not_boss:
         ld       (ix+3),2
         RAND
         and      63
         add      a,31
         ld       (ix+2),a
         ld       (ix+4),0
         ld       (ix+5),1
         ret
stuff:   .db      -1,1,-2,2,0,0,1,-1,1,-1,1,-1,0,0,0,0
 ; -------------- PUT ENEMY BULLET AT (d,e) ----------
put_enemy_bul:
         push     de
         ld       ix,ebuls
         ld       b,16
         ld       de,8
pebfind: ld       a,(ix)
         or       a
         jr       z,pebfound
         add      ix,de
         djnz     pebfind
         pop      de
         ret      
pebfound:pop      de
         ld       (ix),1
         ld       (ix+1),d
         ld       (ix+2),e
         ld       (ix+3),0
         ld       a,(y)
         sub      e
         ld       b,a
         ld       a,(x)
         sub      d
         ret      z
         bit      7,a
         jr       z,right_es
         neg
         ld       e,a
         sla      b
         sub      b
         bit      7,a
         jr       z,ext_l
         ld       a,e
         srl      b
         sla      a
         sub      b
         bit      7,a
         ret      nz
         ld       (ix+3),-1
         ret
         sub      b
ext_l:   ld       (ix+3),-2
         ret    
right_es:ld       e,a
         sla      b
         sub      b
         bit      7,a
         jr       z,ext_r
         ld       a,e
         srl      b
         sla      a
         sub      b
         bit      7,a
         ret      nz
         ld       (ix+3),1
         ret
         sub      b
ext_r:   ld       (ix+3),2
         ret
 ; -------------- ENEMY BULLETS ------------------------
do_ebuls:ld       iy,ebuls
         ld       b,16
ebl:     ld       a,(iy)
         cp       1
         push     bc
         jr       nz,end_of_eb
         ld       a,(iy+2)
         inc      a
         ld       (iy+2),a
         ld       c,a
         cp       63
         jr       z,ebuloff
         ld       a,(iy+1)
         add      a,(iy+3)
         ld       (iy+1),a
         ld       b,a
         res      0,a
         cp       0
         jr       z,ebuloff
         cp       126
         jr       z,ebuloff
         ld       ix,spr_enemy_bullet
         ld       de,(PROGRAM_ADDR)
         add      ix,de
         CALL_(drw_spr)
         ld       ix,$800f
         ld       a,(iy+1)
         inc      a
         sub      (ix+3)
         and      248
         jr       nz,end_of_eb
         ld       a,(iy+2)
         inc      a
         sub      (ix+4)
         and      248
         jr       nz,end_of_eb
         ld       hl,$fc70
         ld       (iy),0
         ld       a,(cheat)
         or       a
         jr       nz,end_of_eb
         ld       a,(invinc)
         or       a
         jr       nz,invincible
         ld       a,(lives)
         dec      a
         ld       (lives),a
         or       l
         ld       l,a
         ld       (hl),0
         ld       a,(lives)
         or       a
         jr       z,lose
end_of_eb:
         pop      bc
         ld       de,8
         add      iy,de
         djnz     ebl
         ret
ebuloff: ld       (iy),0
         jr       end_of_eb
invincible:
         dec      a
         ld       (invinc),a
         jr       end_of_eb
lose:    inc      sp
         inc      sp
         inc      sp
         inc      sp
         ret
 ; -------------- CHANGE CONTRAST ------------------
chg_contrast:
         ld       ix,contrast
         ld       a,%01111101
         out      (1),a
         in       a,(1)
         BIT      1,A
         jr       z,plus
         bit      2,a
         jr       z,minus
         ld       (ix+1),0
         ret
plus:    ld       a,(ix+1)
         or       a
         ret      nz
         ld       a,(ix)
         inc      a
         cp       $20
         ret      z
         ld       (ix),a
         out      (2),a
         ld       (ix+1),1
         ret
minus:   ld       a,(ix+1)
         or       a
         ret      nz
         ld       a,(ix)
         or       a
         ret      z
         dec      a
         ld       (ix),a
         out      (2),a
         ld       (ix+1),1
         ret
 ; -------------- HIT A BOSS -----------------------
bosshit: SCORE(1800)
         push     ix
         ld       ix,goodx
         ld       a,(iy+2)
         add      a,4
         ld       (ix),a
         ld       a,(iy+3)
         ld       (ix+1),a
         ld       (ix+2),1
         pop      ix
         ret
 ; -------------- CLEAR THE BUFFER -----------------
clear_buffer:
         ld       hl,$86c1
         xor      a
         ld       b,112
clr_loop:ld       (hl),a
         inc      hl
         ld       (hl),a
         inc      hl
         ld       (hl),a
         inc      hl
         ld       (hl),a
         inc      hl
         ld       (hl),a
         inc      hl
         ld       (hl),a
         inc      hl
         ld       (hl),a
         inc      hl
         ld       (hl),a
         inc      hl
         add      ix,de
         djnz     clr_loop
 ; -------------- GOODIE ---------------------------
goodie:  ld       iy,goodx
         ld       a,(iy+2)
         or       a
         ret      z
         ld       a,(iy+1)
         inc      a
         cp       57
         jr       z,goodie_gone
         ld       (iy+1),a
         ld       c,a
         ld       b,(iy)
         ld       ix,spr_goodie
         ld       de,(PROGRAM_ADDR)
         add      ix,de
         CALL_(drw_spr)
         ld       a,(iy)
         add      a,8
         ld       hl,x
         sub      (hl)
         and      240
         ret      nz
         ld       a,(iy+1)
         add      a,8
         inc      hl
         sub      (hl)
         and      240
         ret      nz
         ld       a,255
         ld       (invinc),a
goodie_gone:
         ld       (iy+2),0
         ret

 ; ---------------------- HIGH SCORES -------------------------
hi_score_str:
         .db      "----> GALAGA 10 <----"
         .db      "  You have a hiscore!"
         .db      "Enter your name:     ",0
hstitle: .db      "= GALAGA HIGHSCORES =",0
hsdata:  .dw      17600
         .db      "Garrett Smith   ",0
         .dw      13000
         .db      "Garrett Smith   ",0
         .dw      13000
         .db      "Garrett Smith   ",0
         .dw      12400
         .db      "Garrett Smith   ",0
         .dw      11800
         .db      "Garrett Smith   ",0
         .dw      666
         .db      "Bill Gates      ",0
lowest   .dw      666
         .db      "Bill Gates      ",0
chartable:
         .db      "..........XTOJE."
         .db      ". WSNID!.ZVRMHC?"
         .db      ".YUQLGB#x~+PKFA|"
         .db      "@54321.~+......."
 ; -------------- PAUSE --------------------------------
pause:   ld       c,1
         ld       a,%01111101
         out      (c),a
         in       a,(c)
         bit      0,a
         jr       nz,no
         ld       a,($8641)
         or       a
         ret      nz
         ld       a,1
         ld       ($8641),a
         ld       ix,pawz
         ld       de,(PROGRAM_ADDR)
         add      ix,de
         ld       iy,$fd86
         ld       b,7
         ld       de,12
ppp:     push     bc
         ld       b,4
pppil:   ld       a,(ix)
         ld       (iy),a
         inc      iy
         inc      ix
         djnz     pppil
         pop      bc
         add      iy,de
         djnz     ppp
waitr:   in       a,(c)
         bit      0,a
         jr       z,waitr
waitpr:  CALL_(chg_contrast)
         in       a,(c)
         bit      0,a
         jr       nz,waitpr
         ret
no:      xor      a
         ld       ($8641),a
         ret
pawz:    .db      %01111011,%11010010,%11110111,%10111000
         .db      %01001010,%01010010,%10000100,%00100100
         .db      %01001010,%01010010,%10000100,%00100100
         .db      %01111011,%11010010,%11110111,%00100100
         .db      %01000010,%01010010,%00010100,%00100100
         .db      %01000010,%01010010,%00010100,%00100100
         .db      %01000010,%01011110,%11110111,%10111000
ptd:     .db      "PREPARE TO DIE !!!!!!"
save:    .db      0
         .ds      260
         .end
