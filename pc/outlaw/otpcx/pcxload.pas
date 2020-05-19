Program LoadPcx;                        { PCX Decoder by Vulture / OT }

Uses Crt;                               { Used units }

Procedure VideoMode(Mode: Byte); ASSEMBLER;  { Used to switch to gfx modes }
Asm
   mov  ah,00
   mov  al,Mode
   int  10h
End;

Procedure SetColor(Color,R,G,B: Byte); ASSEMBLER; { Sets RGB values of color }
Asm
   mov    dx,3C8h
   mov    al,[Color]
   out    dx,al
   inc    dx
   mov    al,[R]
   out    dx,al
   mov    al,[G]
   out    dx,al
   mov    al,[B]
   out    dx,al
End;

Procedure DecodePcx(S:String);          { Decodes a pcx file to VGA }
Var PcxPointer, Loop1: Word;            { Various variables }
    Temp1, Temp2: Byte;                 { The bytes to read }
    VgaPos: Integer;                    { Position on the screen (lineair) }
    F: File;                            { File ;-) }
    Colors: Array[0..767] of Byte;      { Array for all RGB values }
Begin

  Assign(F,S);                          { Name of file }
  Reset(F,1);                           { Open the PCX }

  Seek(F,FileSize(F)-768);              { Palette data starts here }
  BlockRead(F,Colors,768);              { Read all RGB values at once }
  For Loop1 := 0 to 255 Do              { Set all colors }
  Begin
    SetColor(Loop1,Colors[Loop1*3] shr 2,Colors[Loop1*3+1] shr 2,Colors[Loop1*3+2] shr 2);
  End;

  PcxPointer := 129;                    { Ignore header }
  VgaPos := 0;                          { Start of VGA segment }
  Seek(F,128);

  While (PcxPointer <= (FileSize(F)-128-768)) Do { No header & palette data }
  Begin
    BlockRead(F,Temp1,1);               { Read a byte from .pcx (from disk) }
    Inc(PcxPointer);
    If ((Temp1 AND 192) = 192) then
    Begin                               { Compressed }
      BlockRead(F,Temp2,1);             { Read the next byte }
      Inc(PcxPointer);
      For Loop1 := 1 to (Temp1 AND 63) Do     { Set loop counter }
      Begin
        Asm
          mov   ax,$0a000
          mov   es,ax
          mov   di,VgaPos
          mov   al,Temp2
          mov   byte ptr es:[di],al
        End;
        Inc(VgaPos);
      End;
    End
    Else
    Begin                               { No compression, plot byte }
      Asm
        mov   ax,$0a000
        mov   es,ax
        mov   di,VgaPos
        mov   al,Temp1
        mov   byte ptr es:[di],al
      End;
      Inc(VgaPos);
    End;
  End;
  Close(F);                             { Close the file }
End;

Begin
  VideoMode($13);
  DecodePcx('PcxLoad.pcx');
  Readkey;
  VideoMode($3);
  Writeln('Ü  ÜÜ  ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ  ÜÜ  Ü');
  Writeln('                    - An Outlaw Triad Production (c) 1996 -');
  Writeln;
  Writeln('                             CodeùùùùùùùùùùVulture');
  Writeln('                             GfxùùùùùùùùùùùùùXotic');
  Writeln;
  Writeln('                            -=ð Outlaw Triad Is ð=-');
  Writeln;
  Writeln('  Vulture(code) þ Dazl(artist) þ Troop(sysop) þ Xplorer(artist) þ Inopia(code) ');
  Writeln;
  Writeln('ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ');
End.


{
  Note:

  You can speed up this decoder quite a bit by using more assembler code
  and by reading the entire pcxdata into memory. In this example we read
  the pcx byte per byte from disk while you should read all data at once
  and decode the pcx from memory.

       - Vulture / Outlaw Triad -
}