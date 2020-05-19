{
   A polygon routine by Outlaw Triad. This procedure needs to be optimized
   quite a bit. Try to implement fixed point math to remove the real type
   values. Also, you could try to implement clipping. Use assembler to gain
   speed. Read "polygon.doc" for additional info on these routines.

   The sorting routine in this program divers from the one described in the
   documentation file. Shouldn't be too hard to understand, though...

   Code by Vulture/Outlaw Triad
}

Program Triangle_Filler;

Uses Crt;

Const Vga = $0a000;             { Vga segment }

Procedure VideoMode(Mode: Byte); Assembler;
Asm
    xor     ah,ah
    mov     al,Mode             { Load vgamode }
    int     10h
End;

Procedure WaitRetrace; Assembler;
Asm
    mov     dx,3dah
@Vrt:
    in      al,dx
    test    al,1000b
    jnz     @Vrt
@NoVrt:
    in      al,dx
    test    al,1000b
    jz      @NoVrt
End;

Procedure Hline(x1,x2,y:Word;Color:Byte;Where:Word); Assembler;
Asm
    mov   ax,Where
    mov   es,ax
    mov   ax,y                  { Calculate exact vga position }
    mov   di,ax
    shl   ax,8
    shl   di,6
    add   di,ax
    add   di,x1

    mov   al,Color              { Set color }
    mov   ah,al
    mov   cx,x2
    sub   cx,x1
    shr   cx,1
    jnc   @Start_Fill
    stosb                       { Plot extra pixel (odd # pixels) }
@Start_Fill:
    rep   stosw                 { Plot all remaining pixels (even # pixels) }
End;

Procedure Triangle_Fill(x1,y1,x2,y2,x3,y3: Integer; Color: Byte);
Var Temp, Loop1: Integer;
    StartX, EndX,
    LeftX, RightX: Real;
Begin

  { Sort on y-values }

  If y1 > y3 then                  { y3 must be the largest y-value }
  Begin
    Temp := y3;
    y3 := y1;
    y1 := Temp;
    Temp := x3;
    x3 := x1;
    x1 := Temp;
  End;
  If y1 > y2 then                  { y1 must be the smallest y-value }
  Begin
    Temp := y2;
    y2 := y1;
    y1 := Temp;
    Temp := x2;
    x2 := x1;
    x1 := Temp;
  End;
  If y2 > y3 then                  { y2 must be the middle value }
  Begin
    Temp := y2;
    y2 := y3;
    y3 := Temp;
    Temp := x2;
    x2 := x3;
    x3 := Temp;
  End;

  If (y3-y1) <> 0 then LeftX :=  (x3-x1) / (y3-y1) else LeftX := 0;
  If (y2-y1) <> 0 then RightX := (x2-x1) / (y2-y1) else RightX := 0;

  StartX := x1;
  If (y1-y2) <> 0 then EndX := StartX else EndX := x2;
  For Loop1 := y1 to y2 Do         { Draw first half of triangle }
  Begin
    If StartX < EndX then
      Hline(Round(StartX), Round(EndX), Loop1, Color, Vga)
    Else
      Hline(Round(EndX), Round(StartX), Loop1, Color, Vga);
    StartX := StartX + RightX;
    EndX := EndX + LeftX;
  End;

  If (y3-y2) <> 0 then RightX := (x3-x2) / (y3-y2) else RightX := 0;

  Startx := x2;
  For Loop1 := y2+1 to y3 Do       { Draw second half of triangle }
  Begin
    If StartX < EndX then
      Hline(Round(StartX), Round(EndX), Loop1, Color, Vga)
    Else
      Hline(Round(EndX), Round(StartX), Loop1, Color, Vga);
    StartX := StartX + RightX;
    EndX := EndX + LeftX;
  End;
End;

Begin
  Randomize;
  VideoMode($13);
  Repeat
    Triangle_Fill(Random(320),Random(200),Random(320),Random(200),Random(320),Random(200),Random(255));
  Until Keypressed;
  VideoMode($3);
  Writeln('Ü  ÜÜ  ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ  ÜÜ  Ü');
  Writeln('                    - An Outlaw Triad Production (c) 1996 -');
  Writeln;
  Writeln('                             CodeùùùùùùùùùùVulture');
  Writeln('                             TextùùùùùùùùùùInopia');
  Writeln;
  Writeln('                            -=ð Outlaw Triad Is ð=-');
  Writeln;
  Writeln('  Vulture/code þ Archangle/artist þ Troop/sysop þ Xplorer/artist þ Inopia/code');
  Writeln;
  Writeln('ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ');
End.
