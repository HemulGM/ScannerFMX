unit Scanner.Localization;

interface

uses
  System.SysUtils, FMX.Controls;

procedure SetUILanguage(const Language: string);

function FileCountText(Count: UInt64): string;

function FolderCountText(Count: UInt64): string;

procedure PreserveUserText(Control: TStyledControl);

implementation

uses
  FMX.Types;

type
  TStyledControlAccess = class(TStyledControl);

var
  Russian: Boolean;

procedure SetUILanguage(const Language: string);
begin
  Russian := SameText(Language, 'ru');
end;

function CountText(Count: UInt64; const One, Few, Many: string): string;
var
  Source: string;
begin
  Source := Many;
  if Russian then
  begin
    if not (Count mod 100 in [11..14]) then
      case Count mod 10 of
        1:
          Source := One;
        2..4:
          Source := Few;
      end;
  end
  else if Count = 1 then
    Source := One;
  Result := Format(Translate(Source), [FormatFloat('#,##0', Count)]);
end;

function FileCountText(Count: UInt64): string;
begin
  Result := CountText(Count, '%s file', '%s files (few)', '%s files');
end;

function FolderCountText(Count: UInt64): string;
begin
  Result := CountText(Count, '%s folder', '%s folders (few)', '%s folders');
end;

procedure PreserveUserText(Control: TStyledControl);
begin
  // File names, volume labels and paths must not be translated by FMX scenes.
  TStyledControlAccess(Control).AutoTranslate := False;
end;

end.

