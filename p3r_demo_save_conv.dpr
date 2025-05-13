program p3r_demo_save_conv;

{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Windows, System.SysUtils, System.Classes;

{$SETPEFLAGS IMAGE_FILE_RELOCS_STRIPPED}

function DecryptByte(Data, Key: Byte): Byte;
var
  B: Byte;
begin
  B := Data xor Key;
  Result := ((B shr 4) and 3) or ((B and 3) shl 4) or (B and $CC);
end;

function EncryptByte(Data, Key: Byte): Byte;
begin
  Result := ((((Data shr 4) and 3) or ((Data and 3) shl 4) or (Data and $CC)) xor Key);
end;

procedure DecryptEncryptMemoryStream(MemoryStreamIn: TMemoryStream; MemSize: Int64; Encrypt: Boolean);
const
  SaveKey: array[0..30] of Byte = ($61,$65,$35,$7A,$65,$69,$74,$61,$69,$78,$31,
  $6A,$6F,$6F,$77,$6F,$6F,$4E,$67,$69,$65,$33,$66,$61,$68,$50,$35,$4F,$68,$70,
  $68);
var
  Buff: TBytes;
  i, KeyIdx: Integer;
begin
  SetLength(Buff, MemSize);
  MemoryStreamIn.Position := 0;
  MemoryStreamIn.ReadBuffer(Buff[0], MemSize);
  KeyIdx := 0;
  if (Encrypt = False) then for i:=0 to MemSize-1 do begin
    if (KeyIdx = 31) then KeyIdx := 0;
    Buff[i] := DecryptByte(Buff[i], SaveKey[KeyIdx]);
    KeyIdx := KeyIdx + 1;
  end else for i:=0 to MemSize-1 do begin
    if (KeyIdx = 31) then KeyIdx := 0;
    Buff[i] := EncryptByte(Buff[i], SaveKey[KeyIdx]);
    KeyIdx := KeyIdx + 1;
  end;
  MemoryStreamIn.Position := 0;
  MemoryStreamIn.WriteBuffer(Buff[0], MemSize);
end;

procedure Main;
type
  TData = packed record
    UInt641, UInt642, UInt643: UInt64;
  end;
const
  DemoFlagBlock: array[0..48] of Byte = ($0D,$00,$00,$00,$53,$61,$76,$65,$44,
  $61,$74,$61,$41,$72,$65,$61,$00,$0F,$00,$00,$00,$55,$49,$6E,$74,$33,$32,$50,
  $72,$6F,$70,$65,$72,$74,$79,$00,$04,$00,$00,$00,$19,$03,$00,$00,$00,$01,$00,
  $00,$00);
var
  Data: TData;
  MemoryStream1, MemoryStream2: TMemoryStream;
  Magic: LongWord;
  MemPos, MemSize: Int64;
begin
  MemoryStream1:=TMemoryStream.Create;
  try
    MemoryStream1.LoadFromFile(ParamStr(1));
    MemSize := MemoryStream1.Size;
    if (MemSize < 4) then begin Writeln('Input file is not a valid "PERSONA 3 Reload" save file.'); Readln; exit end;
    MemoryStream1.ReadBuffer(Magic, 4);
    if (Magic = $0B650015) then DecryptEncryptMemoryStream(MemoryStream1, MemSize, False);
    MemPos := 0;
    while (MemPos+$18 <= MemSize) do begin
      MemoryStream1.Position := MemPos;
      MemoryStream1.ReadBuffer(Data, $18);
      if (Data.UInt641 = $72503233746E4955) then
        if (Data.UInt642 = $40079747265706F) then
          if (Data.UInt643 = $319000000) then break;
      MemPos := MemPos + 1;
    end;

    if (MemPos+$18 <= MemSize) then begin
      MemoryStream1.Position := MemPos + $18;
      MemoryStream1.WriteBuffer(DemoFlagBlock[45], 1);
      if (Magic = $0B650015) then DecryptEncryptMemoryStream(MemoryStream1, MemSize, True);
      if (ParamCount > 1) then MemoryStream1.SaveToFile(ParamStr(2)) else MemoryStream1.SaveToFile(ParamStr(1));
      Writeln('File converted successfully!');
    end else begin
      MemPos := 0;
      while (MemPos+$18 <= MemSize) do begin
        MemoryStream1.Position := MemPos;
        MemoryStream1.ReadBuffer(Data, $18);
        if (Data.UInt641 = $6174614465766153) then
          if (Data.UInt642 = $F0061657241) then
            if (Data.UInt643 = $503233746E495500) then break;
        MemPos := MemPos + 1;
      end;
      if (MemPos+$18 > MemSize) then begin Writeln('Input file is not a valid "PERSONA 3 Reload" save file.'); Readln; exit end;
      MemoryStream2:=TMemoryStream.Create;
      try
        MemoryStream1.Position := 0;
        MemoryStream2.CopyFrom(MemoryStream1, MemPos-4);
        MemoryStream2.WriteBuffer(DemoFlagBlock[0], $31);
        MemoryStream2.CopyFrom(MemoryStream1, MemSize-MemPos+4);
        if (Magic = $0B650015) then DecryptEncryptMemoryStream(MemoryStream2, MemoryStream2.Size, True);
        if (ParamCount > 1) then MemoryStream2.SaveToFile(ParamStr(2)) else MemoryStream2.SaveToFile(ParamStr(1));
        Writeln('File converted successfully!');
      finally MemoryStream2.Free end;
    end;
  finally MemoryStream1.Free end;
end;

begin
  try
    Writeln('PERSONA 3 Reload Demo Save Converter v1.0 by RikuKH3');
    Writeln('----------------------------------------------------');
    if (ParamCount = 0) then begin Writeln('Usage: '+ExtractFileName(ParamStr(0))+' <input save file> [output save file]'); Readln; exit end;
    Main;
  except on E: Exception do begin Writeln(E.Message); Readln end end;
end.

