Program Play_Rawfile;                   { By Vulture/Outlaw Triad }

Uses Crt, Dos;

Var F: File;                            { Various variables }
    Temp: Pointer;
    Freq,Data_Length: Word;
    Key: Char;
    Blaster_Reset: Word;                { SB variables }
    Blaster_Read: Word;
    Blaster_Write: Word;
    Blaster_Status: Word;
    Blaster_Data: Word;

Function Reset_Blaster(Base: Word): Boolean;
Begin
  Base := Base shl 4;

  Blaster_Reset := Base + $206;
  Blaster_Read := Base + $20A;
  Blaster_Write := Base + $20C;
  Blaster_Status := Base + $20C;
  Blaster_Data := Base + $20E;

  Port[Blaster_Reset] := 1;
  Delay(5);
  Port[Blaster_Reset] := 0;
  Delay(5);
  If (Port[Blaster_Data] AND 128 = 128) AND
     (Port[Blaster_Read] = $AA) then
     Reset_Blaster := True
  Else
     Reset_Blaster := False;
End;

Procedure Write_To_Blaster(Value: Byte); Assembler;
Asm
   mov    dx,Blaster_Status     { Setup port }

@NoWrite:
   in     al,dx                 { Read from port }
   and    al,10000000b
   jnz    @NoWrite              { Wait until bit 7 is clear }

   mov    dx,Blaster_Write
   mov    al,Value              { Write byte }
   out    dx,al
End;

Function Read_From_Blaster: Byte;
Begin
  While (Port[Blaster_Data] AND 128 = 0) Do;
  Read_From_Blaster := Port[Blaster_Read];
End;

Procedure Turn_Speaker_On;
Begin
  Write_To_Blaster($D1);
End;

Procedure Turn_Speaker_Off;
Begin
  Write_To_Blaster($D3);
End;

Procedure Stop_Dma;
Begin
  Write_To_Blaster($D0);
End;

Procedure PlaySample(Sound: Pointer; Size: Word; Frequency: Word);
Var Time_constant: Byte;
    Page, Offs: Word;
Begin
  Size := Size + 1;

  { Set up the DMA chip }
  Offs := Seg(sound^) shl 4 + Ofs(sound^);
  Page := (Seg(sound^) + Ofs(sound^) shr 4) shr 12;

  Asm                             { Program DMA channel 1 for output to SB }
    mov    dx,0ah
    mov    al,05h
    out    dx,al                  { Mask off DMA channel 1 }

    mov    dx,0ch
    mov    al,00h
    out    dx,al                  { Clear byte pointer F/F to lower byte }

    mov    dx,0bh
    mov    al,49h
    out    dx,al                  { Set transfer mode to DAC }

    mov    dx,02h
    mov    ax,Offs
    out    dx,al                  { Write LSB of base adress }
    mov    al,ah
    out    dx,al                  { Write MSB of base adress }

    mov    dx,83h
    mov    ax,Page
    out    dx,al                  { Write page number }

    mov    dx,03h
    mov    ax,Size
    out    dx,al                  { Write LSB of sample length }
    mov    al,ah
    out    dx,al                  { Write MSB of sample length }

    mov    dx,0ah
    mov    al,01h
    out    dx,al                  { Enable DMA channel 1 }
  End;

  { Set playback frequency }
  Time_constant := 256 - (1000000 div frequency);
  Write_To_Blaster($40);
  Write_To_Blaster(Time_constant);

  { Set playback type to 8-bit }
  Write_To_Blaster($14);
  Write_To_Blaster(Lo(size));
  Write_To_Blaster(Hi(size));
End;

Begin
  Writeln('Press 1 - 9 for different frequencies and escape to quit.');
  Writeln('Play the complete sample before resetting the frequency');
  Writeln('(pressing another key) or else your computer will hang!');

  If not Reset_Blaster(2) then           { Setup soundblaster }
  Begin
    Writeln('Incorrect base adress!');
    Halt(1);
  End;

  Turn_Speaker_On;                       { Guess what? :-) }

  Assign(F, 'playsmp.raw');              { Read file into memory }
  Reset(F,1);
  Data_Length := FileSize(F);
  Getmem(Temp, Data_Length);
  Blockread(F, Temp^, Data_length);
  Close(F);

  Repeat
    Key := Readkey;
    If (Ord(Key) > 48) AND (Ord(Key) < 58) then  { Allow keys 1 - 9 }
    Begin
      Case Key of                        { Determine frequency }
        '1': Freq := 10000;
        '2': Freq := 11000;
        '3': Freq := 12000;
        '4': Freq := 13000;
        '5': Freq := 14000;
        '6': Freq := 15000;
        '7': Freq := 16000;
        '8': Freq := 17000;
        '9': Freq := 18000;
      End;
    If Key <> #27 then PlaySample(Temp, Data_Length, Freq);
    End;
  Until Key = #27;

  ClrScr;
  Freemem(Temp, Data_Length);            { Finish program }
  Turn_Speaker_Off;
  Writeln('Ü  ÜÜ  ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ  ÜÜ  Ü');
  Writeln('                    - An Outlaw Triad Production (c) 1996 -');
  Writeln;
  Writeln('                             CodeùùùùùùùùùùVulture');
  Writeln;
  Writeln('                            -=ğ Outlaw Triad Is ğ=-');
  Writeln;
  Writeln('  Vulture(code) ş Dazl(artist) ş Troop(sysop) ş Xplorer(artist) ş Inopia(code) ');
  Writeln;
  Writeln('ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ');
End.
