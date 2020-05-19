{ Shows how a virtual screen works
  By Vulture / Outlaw Triad }

{$X+}

Program Virtuality;                       { Virtual screen program }

Uses Crt;                                 { Used units }

Type Virtual  = Array [1..64000] of byte; { The size of our Virtual Screen }
     VirPoint = ^Virtual;                 { Pointer to the virtual screen }

Const VGA = $A000;                        { VGA Segment }

Var Virscr: VirPoint;                     { The actual virtual screen }
    Vaddr : Word;                         { Segment of our virtual screen }

Procedure VideoMode(Mode: Byte); Assembler;  { Used to switch to gfxmode }
Asm
  mov  ah,00
  mov  al,Mode
  int  10h
End;

Procedure SetMemory;                      { Allocates memory }
Begin
  GetMem(VirScr,64000);
  Vaddr := Seg(Virscr^);
End;

Procedure FreeMemory;                     { Frees the memory }
Begin
  FreeMem(VirScr,64000);
End;

Procedure SetPixel(X,Y:Integer;Color:Byte;Where:Word); Assembler;
Asm                         { TP automatically pushes and pops ES }
  mov  ax,[Where]           { Move destination in AX }
  mov  es,ax                { es => points to VGA or virtual screen }
  mov  di,Y                 { Move Y into DI }
  mov  ax,Y                 { Move Y into AX }
  shl  di,8                 { DI := DI * 256 }
  shl  ax,6                 { AX := AX * 64 }
  add  di,ax                { DI := Y * 320 }
  mov  ax,X                 { Move X into AX }
  add  di,ax                { DI = X + (Y*320)   final location }
  mov  al,Color             { Set color }
  mov  byte ptr es:[di],al  { Place the dot }
End;

Procedure ClearScreen(Color:Byte;Where:Word); Assembler;
Asm
  mov  ax,Where             { Move destination in AX }
  mov  es,ax                { ES points to VGA or virtual screen }
  xor  di,di                { Start at begin of screen }
  cld                       { Clear direction flag }
  mov  al,Color             { Set color in AL }
  mov  ah,al                { And in ah }
  mov  cx,320*50            { Do the entire screen (using dwords!) }
  db   $66                  { We want to use dwords }
  rep  stosw                { Store the word in ax to es:[di] }
End;

Procedure FlipPage(source,dest:Word); Assembler; { Pretty fast! }
Asm
  push    ds                { Put DS on stack }
  mov     ax,[Dest]
  mov     es,ax             { es points to destination segment }
  mov     ax,[Source]
  mov     ds,ax             { ds points to source segment }
  xor     si,si             { Start at begin of source }
  xor     di,di             { Start at begin of destination }
  mov     cx,16000          { Screen size = 64 kbytes. Use dwords: needed 16000 }
  db      $66               { Use extended registers for speed (e.g eax) }
  rep     movsw             { Copy ds:si to es:di }
  pop     ds                { Recall DS from stack }
End;

Procedure PlotDots;
Var Loop1: Integer;
Begin
  For Loop1 := 1 to 5000 Do
    SetPixel(Random(320),Random(200),Random(256),Vaddr);
End;

Begin
  ClrScr;
  Writeln('In this program I will setup a virtual screen and fill it with');
  Writeln('random pixels. At first you won''t see anything on the screen.');
  Writeln('After a keypress the data is flipped to the VGA screen.');
  Writeln;
  Write('Press any key...');
  Readkey;
  RandoMize;                { Truly random }
  SetMemory;                { Get memory }
  ClearScreen(0,Vaddr);     { Clear the memory }
  VideoMode($13);           { Get in gfxmode 13h 320*200*256 }
  PlotDots;                 { Plot random dots on the virtual screen }
  Readkey;                  { Wait for a key }
  FlipPage(Vaddr,VGA);      { Flip it to the VGA }
  Readkey;                  { Wait for a key }
  VideoMode($3);            { And back to textmode }
  FreeMemory;               { Free memory }
  Writeln('‹  ‹‹  ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹  ‹‹  ‹');
  Writeln('                    - An Outlaw Triad Production (c) 1996 -');
  Writeln;
  Writeln('                             Code˘˘˘˘˘˘˘˘˘˘Vulture');
  Writeln;
  Writeln('                            -= Outlaw Triad Is =-');
  Writeln;
  Writeln('         Vulture(code) ˛ Dazl(artist) ˛ Troop(sysop) ˛ Xplorer(artist)');
  Writeln('‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹');
End.




{ Thanx must go to Denthor / Asphyxia for teaching me some usefull stuff }