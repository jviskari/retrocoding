{
  Basic 3d engine. Rotates a closed cube around 256 degrees. By Vulture/OT
}

Program Rotations3d;

Uses Crt;                                { Used units (don't need much :-) }

Const VGA = $0a000;                      { VGA segment }
      MaxPolys = 6;

Type Virtual = Array [1..64000] of byte;
     VirtPtr = ^Virtual;                 { Pointer to virtual screen }
     PolyObject = Array[1..MaxPolys,1..4,1..3] of Integer;

Const Size = 70;
      Box: PolyObject =                  { Our object }
        (((-Size,-Size,Size),(-Size,Size,Size),(Size,Size,Size),(Size,-Size,Size)),
         ((-Size,-Size,-Size),(-Size,Size,-Size),(Size,Size,-Size),(Size,-Size,-Size)),
         ((-Size,-Size,-Size),(-Size,Size,-Size),(-Size,Size,Size),(-Size,-Size,Size)),
         ((Size,-Size,-Size),(Size,Size,-Size),(Size,Size,Size),(Size,-Size,Size)),
         ((Size,-Size,Size),(Size,-Size,-Size),(-Size,-Size,-Size),(-Size,-Size,Size)),
         ((Size,Size,Size),(Size,Size,-Size),(-Size,Size,-Size),(-Size,Size,Size)));

Var Virscr: VirtPtr;
    Vaddr: Word;                     { Segment value of virtual screen}
    Sine: Array[0..255] of Integer;  { Contains sine&cosine values }
    Points: PolyObject;              { Holds new x,y,z }
    AverageZ: Array[1..MaxPolys] of Integer;  { Average Z values of polygons }
    Order: Array[1..MaxPolys] of Integer; { Order in which to draw the polys }
    Xlist: Array[0..199,1..2] of Integer; { Start/End x values for polygon }
    X,Y,Z: Integer;                  { Variables for formula }
    Xt,Yt,Zt: Integer;               { Temporary variables for x,y,z }
    XAngle,YAngle,ZAngle: Byte;      { Angles to rotate around }
    Zoff: Integer;                   { Distance from viewer }
    XSin,XCos: Integer;              { Sine/cosine of angle to rotate around }
    YSin,YCos: Integer;
    ZSin,ZCos: Integer;
    Key: Byte;                       { To intercept a keypress }

(* =========================== MEMORY ROUTINES ============================ *)

Procedure SetUpVirtual;     { Set up memory needed for virtual screen }
Begin
  GetMem(VirScr,64000);
  Vaddr := Seg(VirScr^);
End;

Procedure ShutDown;         { Free memory used by virtual screen }
Begin
  FreeMem(VirScr,64000);
End;

(* =========================== GRAPHICS ROUTINES ========================== *)

Procedure VideoMode(Mode: Byte); Assembler;
Asm
  xor     ah,ah
  mov     al,Mode
  int     10h
End;

Procedure WaitRetrace; Assembler;
Asm
  mov     dx,3dah
@l1:
  in      al,dx
  and     al,08h
  jnz     @l1
@l2:
  in      al,dx
  and     al,08h
  jz      @l2
End;

Procedure ClearScreen(Color:Byte;Where:Word); Assembler;
Asm
  mov     ax,Where
  mov     es,ax           { ES points to VGA or vitual screen }
  xor     di,di           { Start at begin of screen }
  cld
  mov     al,Color        { Set color in ax }
  mov     ah,al
  mov     cx,32000        { Do the entire screen }
  rep     stosw           { Store the word in ax to es:[di] }
End;

Procedure FlipPage(source,dest:Word); Assembler;
Asm
  push    ds              { Save ds on stack }
  mov     ax,[Source]
  mov     ds,ax           { ds => source segment }
  xor     si,si           { ds:si => source }
  mov     ax,[Dest]
  mov     es,ax           { es => destination segment }
  xor     di,di           { es:di => destination }
  mov     cx,16000        { Screen size = 64 kbytes = 16000 dwords }
  db      66h
  rep     movsw           { Copy ds:si to es:di }
  pop     ds              { Restore ds }
End;

Procedure Hline(x1,x2,y:Word;Color:Byte;Where:Word); Assembler;
Asm
  mov     ax,Where
  mov     es,ax
  mov     ax,y
  mov     di,ax
  shl     ax,8
  shl     di,6
  add     di,ax
  add     di,x1

  mov     al,Color
  mov     ah,al
  mov     cx,x2
  sub     cx,x1
  shr     cx,1
  jnc     @Start
  stosb                   { Set extra byte if carry set }
@Start:
  rep     stosw           { Set all bytes }
End;

Procedure ScanEdge(X1,Y1,X2,Y2: Integer);        { By Denthor/Asphyxia }
Var Loop,X,Xstep,Temp: Integer;
Begin
  If Y1 = Y2 then Exit;
  If Y1 > Y2 then                         { y1 must be smaller than y2 }
  Begin
    Temp := Y1;
    Y1 := Y2;
    Y2 := Temp;
    Temp := X1;
    X1 := X2;
    X2 := Temp;
  End;
  Xstep := ((X2-X1) shl 8) div (Y2-Y1);   { Calculate gradient }
  X := X1 shl 8;                          { Starting x value }
  For Loop := Y1 to Y2 Do
  Begin
    If (X shr 8) < Xlist[Loop,1] then Xlist[Loop,1] := X shr 8;
    If (X shr 8) > Xlist[Loop,2] then Xlist[Loop,2] := X shr 8;
    Inc(X,Xstep);
  End;
End;

Procedure Draw_Polygon(X1,Y1,X2,Y2,X3,Y3,X4,Y4: Integer; Color: Byte; Where:Word);
Var MinY,MaxY,Loop: Integer;
Begin
  Asm                                     { Set minx/maxx to extremes }
     mov    si,offset Xlist
     mov    cx,200
@FillLoop:
     mov    ax,320                        { Minx = 320 }
     mov    ds:[si],ax
     inc    si
     inc    si
     xor    ax,ax                         { Maxx = 0 }
     mov    ds:[si],ax
     inc    si
     inc    si
     loop   @FillLoop
  End;
  miny:=y1;
  maxy:=y1;
  if y2<miny then miny:=y2;
  if y3<miny then miny:=y3;
  if y4<miny then miny:=y4;
  if y2>maxy then maxy:=y2;
  if y3>maxy then maxy:=y3;
  if y4>maxy then maxy:=y4;
  ScanEdge(X1,Y1,X2,Y2);
  ScanEdge(X2,Y2,X3,Y3);
  ScanEdge(X3,Y3,X4,Y4);
  ScanEdge(X4,Y4,X1,Y1);
  For Loop := MinY to MaxY Do
     HLine(Xlist[Loop,1],Xlist[Loop,2],Loop,Color,Where);
End;

(* ============================== 3D ROUTINES ============================= *)

Procedure CalculateSine;
Var I: Integer;
Begin
  For I := 0 to 255 Do Sine[I] := Round(Sin(I*(2*pi/256))*256);
End;

Procedure UpdateRotation(DeltaX,DeltaY,DeltaZ: Integer);
Begin
  XAngle := (Xangle+DeltaX) Mod 256;  { Add addition factors }
  YAngle := (Yangle+DeltaY) Mod 256;
  ZAngle := (Zangle+DeltaZ) Mod 256;

  Xsin := Sine[Xangle];               { Grab sine from sinetable }
  Xcos := Sine[(Xangle+64) Mod 256];  { Add 64 to get cosine (neat trick!) }
  Ysin := Sine[Yangle];
  Ycos := Sine[(Yangle+64) Mod 256];
  Zsin := Sine[Zangle];
  Zcos := Sine[(Zangle+64) Mod 256];
End;

Procedure GetOrgXYZ(Obj: PolyObject; Poly,Place: Integer);
Begin
  X := Obj[Poly,Place,1];    { Grabs our original x,y,z values }
  Y := Obj[Poly,Place,2];
  Z := Obj[Poly,PLace,3];
End;

Procedure RotatePoint; Assembler;  { Rotates a point around all axis }
Asm
{ Rotate around x-axis }
{ YT = Y * COS(xang) - Z * SIN(xang) / 256 }
{ ZT = Y * SIN(xang) + Z * COS(xang) / 256 }
{ Y = YT }
{ Z = ZT }
    pusha
    mov     ax,[Y]
    mov     bx,[XCos]
    imul    bx               { ax = Y * Cos(xang) }
    mov     bp,ax
    mov     ax,[Z]
    mov     bx,[XSin]
    imul    bx               { ax = Z * Sin(xang) }
    sub     bp,ax            { bp = Y * Cos(xang) - Z * Sin(xang) }
    sar     bp,8             { bp = Y * Cos(xang) - Z * Sin(xang) / 256 }
    mov     [Yt],bp

    mov     ax,[Y]
    mov     bx,[XSin]
    imul    bx               { ax = Y * Sin(xang) }
    mov     bp,ax
    mov     ax,[Z]
    mov     bx,[XCos]
    imul    bx               { ax = Z * Cos(xang) }
    add     bp,ax            { bp = Y * SIN(xang) + Z * COS(xang) }
    sar     bp,8             { bp = Y * SIN(xang) + Z * COS(xang) / 256 }
    mov     [Zt],bp

    mov     ax,[Yt]          { Switch values }
    mov     [Y],ax
    mov     ax,[Zt]
    mov     [Z],ax

{ Rotate around y-axis }
{ XT = X * COS(yang) - Z * SIN(yang) / 256 }
{ ZT = X * SIN(yang) + Z * COS(yang) / 256 }
{ X = XT }
{ Z = ZT }

    mov     ax,[X]
    mov     bx,[YCos]
    imul    bx               { ax = X * Cos(yang) }
    mov     bp,ax
    mov     ax,[Z]
    mov     bx,[YSin]
    imul    bx               { ax = Z * Sin(yang) }
    sub     bp,ax            { bp = X * Cos(yang) - Z * Sin(yang) }
    sar     bp,8             { bp = X * Cos(yang) - Z * Sin(yang) / 256 }
    mov     [Xt],bp

    mov     ax,[X]
    mov     bx,[YSin]
    imul    bx               { ax = X * Sin(yang) }
    mov     bp,ax
    mov     ax,[Z]
    mov     bx,[YCos]
    imul    bx               { ax = Z * Cos(yang) }
    add     bp,ax            { bp = X * SIN(yang) + Z * COS(yang) }
    sar     bp,8             { bp = X * SIN(yang) + Z * COS(yang) / 256 }
    mov     [Zt],bp

    mov     ax,[Xt]          { Switch values }
    mov     [X],ax
    mov     ax,[Zt]
    mov     [Z],ax

{ Rotate around z-axis }
{ XT = X * COS(zang) - Y * SIN(zang) / 256 }
{ YT = X * SIN(zang) + Y * COS(zang) / 256 }
{ X = XT }
{ Y = YT }

    mov     ax,[X]
    mov     bx,[ZCos]
    imul    bx               { ax = X * Cos(zang) }
    mov     bp,ax
    mov     ax,[Y]
    mov     bx,[ZSin]
    imul    bx               { ax = Y * Sin(zang) }
    sub     bp,ax            { bp = X * Cos(zang) - Y * Sin(zang) }
    sar     bp,8             { bp = X * Cos(zang) - Y * Sin(zang) / 256 }
    mov     [Xt],bp

    mov     ax,[X]
    mov     bx,[ZSin]
    imul    bx               { ax = X * Sin(zang) }
    mov     bp,ax
    mov     ax,[Y]
    mov     bx,[ZCos]
    imul    bx               { ax = Y * Cos(zang) }
    add     bp,ax            { bp = X * SIN(zang) + Y * COS(zang) }
    sar     bp,8             { bp = X * SIN(zang) + Y * COS(zang) / 256 }
    mov     [Yt],bp

    mov     ax,[Xt]          { Switch values }
    mov     [X],ax
    mov     ax,[Yt]
    mov     [Y],ax
    popa
End;

Procedure SortPolygons;                           { Sort polys on Z }
Var Loop1, Position, Temp: Integer;
Begin
  For Loop1 := 1 to MaxPolys Do Order[Loop1] := Loop1;  { Reset order }
  Position := 1;
  While Position < MaxPolys Do                    { Sort all polygons }
  Begin
    If AverageZ[Position] < AverageZ[Position+1] then
    Begin
      Temp := AverageZ[Position];                 { Swap Z values }
      AverageZ[Position] := AverageZ[Position+1];
      AverageZ[Position+1] := Temp;
      Temp := Order[Position];                    { Swap polygon draw order }
      Order[Position] := Order[Position+1];
      Order[Position+1] := Temp;
      Position := 0;                              { Reset counter }
    End;
    Position := Position + 1;                     { Compare next 2 values }
  End;
End;

Procedure RotateAllStuff(Obj: PolyObject; Where: Word; Mx,My: Integer);
Var Loop1,Loop2,Temp,Nr,
    X1,Y1,X2,Y2,X3,Y3,X4,Y4: Integer; { 4 points of polygon }
Begin

  For Loop1 := 1 to MaxPolys Do       { Rotate the polygons }
  Begin
    For Loop2 := 1 to 4 Do            { All 4 3d-points of polygon }
    Begin
      GetOrgXYZ(Obj,Loop1,Loop2);     { Get the original x,y,z values }
      RotatePoint;                    { Rotate the point around x,y,z }
      Points[Loop1,Loop2,1] := X;     { Save new x,y,z }
      Points[Loop1,Loop2,2] := Y;
      Points[Loop1,Loop2,3] := Z;
    End;
    AverageZ[Loop1] := Points[Loop1,1,3]+Points[Loop1,2,3]+Points[Loop1,3,3]+Points[Loop1,4,3];
  End;

  SortPolygons;                       { Sort the polygons on z values }

  For Loop1 := 1 to MaxPolys Do       { Draw the polygons }
  Begin
    Nr := Order[Loop1];               { # of polygon to draw }
    Temp := Points[Nr,1,3]-Zoff;
    X1 := ((Points[Nr,1,1] shl 8) div Temp) + Mx;
    Y1 := ((Points[Nr,1,2] shl 8) div Temp) + My;
    Temp := Points[Nr,2,3]-Zoff;
    X2 := ((Points[Nr,2,1] shl 8) div Temp) + Mx;
    Y2 := ((Points[Nr,2,2] shl 8) div Temp) + My;
    Temp := Points[Nr,3,3]-Zoff;
    X3 := ((Points[Nr,3,1] shl 8) div Temp) + Mx;
    Y3 := ((Points[Nr,3,2] shl 8) div Temp) + My;
    Temp := Points[Nr,4,3]-Zoff;
    X4 := ((Points[Nr,4,1] shl 8) div Temp) + Mx;
    Y4 := ((Points[Nr,4,2] shl 8) div Temp) + My;
    Draw_Polygon(X1,Y1,X2,Y2,X3,Y3,X4,Y4,Nr+20,Where);
  End;

End;

(* ============================= MAIN PROGRAM ============================= *)

Begin
  Randomize;
  SetupVirtual;             { Setup memory for virtual screen }
  CalculateSine;
  Xangle := Random(255);    { Set initial degrees }
  Yangle := Random(255);
  Zangle := Random(255);
  Zoff := -500;             { Distance from viewer }
  VideoMode($13);

  Repeat
    UpdateRotation(3,1,2);  { Set new angles and fetch (co)sine data }
    ClearScreen(0,Vaddr);   { Clear virtual page (slow method) }
    RotateAllStuff(Box,Vaddr,160,100);     { Do all good stuff }
    WaitRetrace;            { Wait for a vertical retrace }
    FlipPage(Vaddr,VGA);    { And let's show the stuff on screen }
    If Keypressed then Key := Ord(Readkey);   { Catch a keypress }
  Until Key = 27;           { Quit on escape }

  ShutDown;                 { Free memory }
  VideoMode($3);            { Warp back to textmode }
  Writeln('Ü  ÜÜ  ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ  ÜÜ  Ü');
  Writeln('                    - An Outlaw Triad Production (c) 1996 -');
  Writeln;
  Writeln('                             CodeùùùùùùùùùùVulture');
  Writeln;
  Writeln('                            -=ð Outlaw Triad Is ð=-');
  Writeln;
  Writeln('  Vulture/code þ Archangle/artist þ Troop/sysop þ Xplorer/artist þ Inopia/code');
  Writeln;
  Writeln('ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ');
End.
