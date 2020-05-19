{
   Rotation and morphing around 360 degrees. Integer math. As you can
   see, the dots all reach their destination at the same time. Thanks
   to Ryu/D+P+S for object generating code (some small modifications
   were made, though). This example needs a lot of optimizing. Don't
   steal code, use this to learn. Bye,

          - Vulture / Outlaw Triad -
}

Program Rotation3d;                   { Rotation & morphing 360 degrees }

Uses Crt;

Const VGA = $0a000;
      MaxPoints = 100;

Var Sine: Array[0..359] of Integer;   { Sine values for 360 degrees }
    X,Y,Z: Integer;                   { All integer math }
    Xt,Yt,Zt: Integer;
    Xsin,Xcos,
    Ysin,Ycos,
    Zsin,Zcos: Integer;
    Xangle,Yangle,Zangle: Integer;
    Loop1,Zoff: Integer;
    ScreenX, ScreenY: Integer;
    RealObj: Array[1..MaxPoints,1..3] of Integer;
    TempObj: Array[1..MaxPoints,1..3] of Integer;
    MorphData: Array[1..MaxPoints,1..3] of Integer;
    OldXY: Array[1..MaxPoints,1..2] of Integer;
    Key: Char;

Procedure VideoMode(Mode: Byte); Assembler;
Asm
  xor  ah,ah
  mov  al,Mode
  int  10h
End;

Procedure Putpixel(X,Y:Word; Color:byte; Where:Word); Assembler;
Asm
  mov ax,Where
  mov es,ax
  mov di,X
  mov ax,Y
  shl ax,6
  add di,ax
  shl ax,2
  add di,ax
  mov al,Color
  mov byte ptr es:[di],al
End;

Procedure WaitRetrace; Assembler;     { Waits for vertical retrace }
label l1, l2;
Asm
   mov  dx,3dah
l1:
   in   al,dx
   and  al,08h
   jnz  l1
l2:
   in   al,dx
   and  al,08h
   jz   l2
End;

Procedure CalcSine;                   { Guess what this does... ;-) }
Var I,Out: Integer;
    An: Real;
Begin
  For I := 0 to 359 Do                { 360 values }
  Begin
    An := I*(2*pi / 360);
    Out := Round(Sin(An)*256);
    Sine[I] := Out;                   { Save into array }
  End;
End;

Procedure CreateRandom;               { Creates a random object }
Var Loop1: Integer;
Begin
  For Loop1 := 1 to MaxPoints Do
  Begin
    RealObj[Loop1,1] := (Random(50)-25) shl 6;
    RealObj[Loop1,2] := (Random(60)-40) shl 6;
    RealObj[Loop1,3] := (Random(50)-25) shl 6;
  End;
End;

Procedure CreateRandom2;              { Creates a random object }
Var Loop1: Integer;
Begin
  For Loop1 := 1 to MaxPoints Do
  Begin
    TempObj[Loop1,1] := (Random(50)-25) shl 6;
    TempObj[Loop1,2] := (Random(60)-40) shl 6;
    TempObj[Loop1,3] := (Random(50)-25) shl 6;
  End;
End;

Procedure CreateBox;
Var a1,a2,a3,Loop1: Integer;
Begin
  a1:=-30;
  a2:=-30;
  a3:=-30;
  For Loop1 := 1 to MaxPoints do
  Begin
    TempObj[Loop1,1] := a1 shl 6;
    TempObj[Loop1,2] := a2 shl 6;
    TempObj[Loop1,3] := a3 shl 6;
    Inc(a1,10);
    If a1=20 then
    Begin
     a1:=-30;
     Inc(a2,10);
    End;

    If a2=20 then
    Begin
      a2:=-30;
      Inc(a3,10);
    End;
  End;
End;

Procedure CreateBall;
Var a2: Real;
    Loop1: Integer;
Begin
  a2 := 1;
  for Loop1 := 1 to MaxPoints do
  Begin
    TempObj[Loop1,1] := (Sine[Round(a2) mod 360]*50 div 256) shl 6;
    TempObj[Loop1,2] := (Sine[Round(a2+90) mod 360]*50 div 256) shl 6;
    TempObj[Loop1,3] := 0;
    a2 := a2 + 3.6;
  End;
End;

Procedure CreateCyl;
Var a2:real;
    Loop1,a1: Integer;
Begin
  a1 := -50;
  a2 := 0;
  For Loop1 := 1 to MaxPoints do
  Begin
    TempObj[Loop1,1] := (Sine[round(a2) mod 360]*20 div 256) shl 6;
    TempObj[Loop1,2] := (Sine[round(a2+90) mod 360]*20 div 256) shl 6;
    TempObj[Loop1,3] := a1 shl 6;
    If (Loop1 mod 10)=0 then
    Begin
      a2:=0;
      inc(a1,10);
    End;
   a2:=a2+360/10;
  End;
End;

Procedure DoAngles(DeltaX,DeltaY,DeltaZ: Integer); { Increase rotation angles }
Begin
  Xangle := (Xangle+DeltaX) mod 360;
  Yangle := (Yangle+DeltaY) mod 360;
  Zangle := (Zangle+DeltaZ) mod 360;
End;

Procedure GetSinCos;                  { Gets sine & cosine of angles }
Begin
  Xsin := Sine[Xangle];
  Xcos := Sine[(Xangle+90) mod 360];  { Add 90 to get cosine value }
  Ysin := Sine[Yangle];
  Ycos := Sine[(Yangle+90) mod 360];
  Zsin := Sine[Zangle];
  Zcos := Sine[(Zangle+90) mod 360];
End;

Procedure RotateXYZ(Current: Integer);
Begin
{ Get original x,y,z values }
  X := RealObj[Current,1] div 64;
  Y := RealObj[Current,2] div 64;
  Z := RealObj[Current,3] div 64;

{ Rotate around x-axis }
  YT := (Y * Xcos - Z * Xsin) div 256;
  ZT := (Y * Xsin + Z * Xcos) div 256;
  Y := Yt;
  Z := Zt;

{ Rotate around y-axis }
  XT := (X * Ycos - Z * Ysin) div 256;
  ZT := (X * Ysin + Z * Ycos) div 256;
  X := Xt;
  Z := Zt;

{ Rotate around z-axis }
  XT := (X * Zcos - Y * Zsin) div 256;
  YT := (X * Zsin + Y * Zcos) div 256;
  X := Xt;
  Y := Yt;
End;

Procedure CalcVgaPos;                 { Calculate vga position }
Begin
  ScreenX := (X shl 8) div (Z+Zoff)+160;
  ScreenY := (Y shl 8) div (Z+Zoff)+100;
End;

Procedure DoAllPoints;
Var Loop1: Integer;
Begin
  If KeyPressed then Exit;
  DoAngles(2,2,0);                    { Update rotation angles }
  GetSinCos;
  For Loop1 := 1 to MaxPoints Do
  Begin
    RotateXYZ(Loop1);                 { Rotate point }
    CalcVgaPos;                       { Calculate screenposition }
    OldXY[Loop1,1] := ScreenX;        { Store vga x,y }
    OldXY[Loop1,2] := ScreenY;
    PutPixel(OldXY[Loop1,1], OldXY[Loop1,2], 34, VGA);
  End;
  WaitRetrace;
  For Loop1 := 1 to MaxPoints Do
     PutPixel(OldXY[Loop1,1], OldXY[Loop1,2], 0, VGA);
End;

Procedure RealMorph;
Var Loop1, Loop2: Integer;
Begin
  For Loop1 := 1 to MaxPoints Do
  Begin
    MorphData[Loop1,1] := (RealObj[Loop1,1] - TempObj[Loop1,1]) div 64;
    MorphData[Loop1,2] := (RealObj[Loop1,2] - TempObj[Loop1,2]) div 64;
    MorphData[Loop1,3] := (RealObj[Loop1,3] - TempObj[Loop1,3]) div 64;
  End;
  For Loop1 := 1 to 64 Do
  Begin
    For Loop2 := 1 to MaxPoints Do
    Begin
      Dec(RealObj[Loop2,1],MorphData[Loop2,1]);
      Dec(RealObj[Loop2,2],MorphData[Loop2,2]);
      Dec(RealObj[Loop2,3],MorphData[Loop2,3]);
    End;
    DoAllPoints;
 End;
End;

Begin
  RandoMize;
  CalcSine;                           { Create sine chart }
  Xangle := 0;                        { Starting angles }
  Yangle := 0;
  Zangle := 0;
  Zoff := 250;                        { Distance from viewer }
  Loop1 := 1;
  CreateRandom;
  VideoMode($13);
  Repeat
    For Loop1 := 1 to 150 Do DoAllPoints;
    CreateBox;
    RealMorph;
    For Loop1 := 1 to 150 Do DoAllPoints;
    CreateCyl;
    RealMorph;
    For Loop1 := 1 to 150 Do DoAllPoints;
    CreateBall;
    RealMorph;
    For Loop1 := 1 to 150 Do DoAllPoints;
    CreateRandom2;
    RealMorph;
  Until KeyPressed;
  VideoMode($3);
  Writeln('‹  ‹‹  ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹  ‹‹  ‹');
  Writeln;
  Writeln('                    - An Outlaw Triad Production (c) 1996 -');
  Writeln;
  Writeln('                             Code˘˘˘˘˘˘˘˘˘˘Vulture');
  Writeln;
  Writeln('                            -= Outlaw Triad Is =-');
  Writeln;
  Writeln(' Vulture(code) ˛ Dazl(artist) ˛ Troop(sysop) ˛ Xplorer(artist) ˛ Inopia(coder)');
  Writeln;
  Writeln('‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹');
End.