{******************************************************************************}
{                       CnPack For Delphi/C++Builder                           }
{                     �й����Լ��Ŀ���Դ�������������                         }
{                   (C)Copyright 2001-2015 CnPack ������                       }
{                   ------------------------------------                       }
{                                                                              }
{            ���������ǿ�Դ���������������������� CnPack �ķ���Э������        }
{        �ĺ����·�����һ����                                                }
{                                                                              }
{            ������һ��������Ŀ����ϣ�������ã���û���κε���������û��        }
{        �ʺ��ض�Ŀ�Ķ������ĵ���������ϸ���������� CnPack ����Э�顣        }
{                                                                              }
{            ��Ӧ���Ѿ��Ϳ�����һ���յ�һ�� CnPack ����Э��ĸ��������        }
{        ��û�У��ɷ������ǵ���վ��                                            }
{                                                                              }
{            ��վ��ַ��http://www.cnpack.org                                   }
{            �����ʼ���master@cnpack.org                                       }
{                                                                              }
{******************************************************************************}

unit CnCodeGenerators;
{* |<PRE>
================================================================================
* �������ƣ�CnPack �����ʽ��ר��
* ��Ԫ���ƣ���ʽ��������������� CnCodeGenerators
* ��Ԫ���ߣ�CnPack������
* ��    ע���õ�Ԫʵ���˴����ʽ������Ĳ���������
* ����ƽ̨��Win2003 + Delphi 5.0
* ���ݲ��ԣ�not test yet
* �� �� ����not test hell
* ��Ԫ��ʶ��$Id$
* �޸ļ�¼��2007-10-13 V1.0
*               ���뻻�еĲ������ô������������ơ�
*           2003-12-16 V0.1
*               �������򵥵Ĵ��������д���Լ����������
================================================================================
|</PRE>}

interface

{$I CnPack.inc}

uses
  Classes, SysUtils;

type
  TCnCodeWrapMode = (cwmNone, cwmSimple, cwmAdvanced);
  {* ���뻻�е����ã����Զ����У��򵥵ĳ����ͻ��У��߼����У�����֪����ɶ;-(��}

  TCnCodeGenerator = class
  private
    FCode: TStrings;
    FLock: Word;
    FColumnPos: Integer;
    FCodeWrapMode: TCnCodeWrapMode;
    FPrevStr: string;
    FPrevRow: Integer;
    FPrevColumn: Integer;
    FOnAfterWrite: TNotifyEvent;
    function GetCurIndentSpace: Integer;
    function GetLockedCount: Word;
    function GetPrevColumn: Integer;
    function GetPrevRow: Integer;
    function GetCurrColumn: Integer;
    function GetCurrRow: Integer;
  protected
    procedure DoAfterWrite; virtual;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Reset;
    procedure Write(S: string; BeforeSpaceCount:Word = 0;
      AfterSpaceCount: Word = 0);
    procedure InternalWriteln;
    procedure Writeln;
    function SourcePos: Word;
    {* ���һ�й��������������δʹ��}
    procedure SaveToStream(Stream: TStream);
    procedure SaveToFile(FileName: string);
    procedure SaveToStrings(AStrings: TStrings);

    function CopyPartOut(StartRow, StartColumn, EndRow, EndColumn: Integer): string;
    {* �������ָ����ֹλ�ø������ݳ���������ֱ��ʹ�� Row/Column �������}

    procedure LockOutput;
    procedure UnLockOutput;

    procedure ClearOutputLock;
    {* ֱ�ӽ������������}

    property LockedCount: Word read GetLockedCount;
    {* �������}
    property ColumnPos: Integer read FColumnPos;
    {* ��ǰ���ĺ���λ�ã����ڻ���}
    property CurIndentSpace: Integer read GetCurIndentSpace;
    {* ��ǰ����ǰ��Ŀո���}
    property CodeWrapMode: TCnCodeWrapMode read FCodeWrapMode write FCodeWrapMode;
    {* ���뻻�е�����}

    property PrevRow: Integer read GetPrevRow;
    {* һ�� Write �ɹ���д֮ǰ�Ĺ���кţ�0 ��ʼ��
      ������ʵ�������������Ϊ Write ��������д�س����з�}
    property PrevColumn: Integer read GetPrevColumn;
    {* һ�� Write �ɹ���д֮ǰ�Ĺ���кţ�0 ��ʼ}
    property CurrRow: Integer read GetCurrRow;
    {* һ�� Write �ɹ���д֮��Ĺ���кţ�0 ��ʼ��
      ������ʵ�������������Ϊ Write ��������д�س����з�}
    property CurrColumn: Integer read GetCurrColumn;
    {* һ�� Write �ɹ���д֮��Ĺ���кţ�0 ��ʼ}

    property OnAfterWrite: TNotifyEvent read FOnAfterWrite write FOnAfterWrite;
    {* д����һ�γɹ��󱻵���}
  end;

implementation

{ TCnCodeGenerator }

uses
  CnCodeFormatRules {$IFDEF DEBUG}, CnDebug {$ENDIF};

const
  CRLF = #13#10;

procedure TCnCodeGenerator.ClearOutputLock;
begin
  FLock := 0;
end;

function TCnCodeGenerator.CopyPartOut(StartRow, StartColumn, EndRow,
  EndColumn: Integer): string;
var
  I: Integer;
begin
  Result := '';
  if EndRow > FCode.Count - 1 then
    EndRow := FCode.Count - 1;
    
  if EndRow < StartRow then Exit;
  if (EndRow = StartRow) and (EndColumn < StartColumn) then Exit;

  Inc(StartColumn);
  Inc(EndColumn); // Column ���� 0 ��ʼ�����ַ����±��� 1 ��ʼ�����Զ�Ҫ��һ

  if EndRow = StartRow then
    Result := Copy(FCode[StartRow], StartColumn, EndColumn - StartColumn)
  else
  begin
    for I := StartRow to EndRow do
    begin
      if I = StartRow then
        Result := Result + Copy(FCode[StartRow], StartColumn, MaxInt) + CRLF
      else if I = EndRow then
        Result := Result + Copy(FCode[EndRow], 1, EndColumn)
      else
        Result := Result + FCode[I] + CRLF;
    end;
  end;
end;

constructor TCnCodeGenerator.Create;
begin
  FCode := TStringList.Create;
  FLock := 0;
end;

destructor TCnCodeGenerator.Destroy;
begin
  FCode.Free;
  inherited;
end;

procedure TCnCodeGenerator.DoAfterWrite;
begin
  if Assigned(FOnAfterWrite) then
    FOnAfterWrite(Self);
end;

function TCnCodeGenerator.GetCurIndentSpace: Integer;
var
  I, Len: Integer;
begin
  Result := 0;
  if FCode.Count > 0 then
  begin
    Len := Length(FCode[FCode.Count - 1]);
    if Len > 0 then
    begin
      for I := 1 to Len do
        if FCode[FCode.Count - 1][I] in [' ', #09] then
          Inc(Result)
        else
          Exit;
    end;
  end;
end;

function TCnCodeGenerator.GetCurrColumn: Integer;
begin
  Result := FColumnPos;
end;

function TCnCodeGenerator.GetCurrRow: Integer;
begin
  Result := FCode.Count - 1;
end;

function TCnCodeGenerator.GetLockedCount: Word;
begin
  Result := FLock;
end;

function TCnCodeGenerator.GetPrevColumn: Integer;
begin
  Result := FPrevColumn;
end;

function TCnCodeGenerator.GetPrevRow: Integer;
begin
  Result := FPrevRow;
end;

procedure TCnCodeGenerator.InternalWriteln;
begin
  if FLock <> 0 then Exit;

  FCode[FCode.Count - 1] := TrimRight(FCode[FCode.Count - 1]);
  FCode.Add('');

  FColumnPos := 0;
end;

procedure TCnCodeGenerator.LockOutput;
begin
  Inc(FLock);
end;

procedure TCnCodeGenerator.Reset;
begin
  FCode.Clear;
end;

procedure TCnCodeGenerator.SaveToFile(FileName: String);
begin
  FCode.SaveToFile(FileName);
end;

procedure TCnCodeGenerator.SaveToStream(Stream: TStream);
begin
  FCode.SaveToStream(Stream);
end;

procedure TCnCodeGenerator.SaveToStrings(AStrings: TStrings);
begin
  AStrings.Assign(FCode);
end;

function TCnCodeGenerator.SourcePos: Word;
begin
  Result := Length(FCode[FCode.Count - 1]);
end;

procedure TCnCodeGenerator.UnLockOutput;
begin
  Dec(FLock);
end;

procedure TCnCodeGenerator.Write(S: string; BeforeSpaceCount,
  AfterSpaceCount: Word);
var
  Str: string;
  Len: Integer;
begin
  if FLock <> 0 then Exit;
  
  if FCode.Count = 0 then
    FCode.Add('');

  Str := Format('%s%s%s', [StringOfChar(' ', BeforeSpaceCount), S,
    StringOfChar(' ', AfterSpaceCount)]);
  Len := Length(Str);

  FPrevRow := FCode.Count - 1;
  
  if CodeWrapMode = cwmNone then
  begin
    // ���Զ�����ʱ���账��
  end
  else if CodeWrapMode = cwmSimple then // �򵥻��У��ж��Ƿ񳬳�����
  begin
    if (FPrevStr <> '.') and // Dot in unitname should not new line.
     (((FColumnPos <= CnPascalCodeForRule.WrapWidth) and
      (FColumnPos + Len > CnPascalCodeForRule.WrapWidth)) or
      (FColumnPos > CnPascalCodeForRule.WrapWidth)) then
    begin
      Str := StringOfChar(' ', CurIndentSpace) + Str; // ����ԭ�е�����
      InternalWriteln;
    end;
  end
  else if CodeWrapMode = cwmAdvanced then // TODO: ��δ����
  begin

  end;

  FCode[FCode.Count - 1] :=
    Format('%s%s', [FCode[FCode.Count - 1], Str]);

  FPrevColumn := FColumnPos;
  FColumnPos := Length(FCode[FCode.Count - 1]);
  FPrevStr := S;

  DoAfterWrite;
{$IFDEF DEBUG}
  CnDebugger.LogFmt('String Wrote from %d %d to %d %d: %s', [FPrevRow, FPrevColumn,
    GetCurrRow, GetCurrColumn, Str]);
  CnDebugger.LogMsg(CopyPartOut(FPrevRow, FPrevColumn, GetCurrRow, GetCurrColumn));
{$ENDIF}
end;

procedure TCnCodeGenerator.Writeln;
begin
  if FLock <> 0 then Exit;

  // Write(S, BeforeSpaceCount, AfterSpaceCount);
  // delete trailing blanks
  FCode[FCode.Count - 1] := TrimRight(FCode[FCode.Count - 1]);
  FPrevRow := FCode.Count - 1;

  FCode.Add('');

  FPrevColumn := FColumnPos;
  FColumnPos := 0;
  
  DoAfterWrite;
{$IFDEF DEBUG}
  CnDebugger.LogFmt('NewLine Wrote from %d %d to %d %d', [FPrevRow, FPrevColumn,
    GetCurrRow, GetCurrColumn]);
{$ENDIF}
end;

end.