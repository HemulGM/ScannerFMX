unit Scanner.DriveButton;

interface

uses
  System.Classes, System.SysUtils, System.Types, System.Math, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Layouts, FMX.Objects, FMX.StdCtrls,
  FMX.Controls.Presentation;

type
  TFrameDriveButton = class(TFrame)
    LayoutContent: TLayout;
    SpeedButtonDrive: TSpeedButton;
    PathDriveIcon: TPath;
    LayoutText: TLayout;
    LabelTitle: TLabel;
    LayoutMeterSlot: TLayout;
    RectangleUsageTrack: TRectangle;
    RectangleUsageFill: TRectangle;
    LabelUsage: TLabel;
    procedure RectangleUsageTrackResize(Sender: TObject);
  public
    procedure LoadDrive(const Path: string);
    procedure SetDrive(const Path, Caption: string; TotalBytes, FreeBytes: UInt64);
  end;

implementation

uses
  Winapi.Windows, Scanner.ViewModel, Scanner.Localization;

{$R *.fmx}

procedure TFrameDriveButton.LoadDrive(const Path: string);
var
  Caption: string;
  VolumeName: array[0..MAX_PATH] of Char;
  MaxComponentLength, FileSystemFlags: DWORD;
  AvailableBytes, TotalBytes, FreeBytes: Int64;
begin
  Caption := Translate('Local disk');
  TotalBytes := 0;
  FreeBytes := 0;
  // Do not wake removable/remote devices just to populate the sidebar.
  if GetDriveType(PChar(Path)) = DRIVE_FIXED then
  begin
    FillChar(VolumeName, SizeOf(VolumeName), 0);
    if GetVolumeInformation(PChar(Path), VolumeName, Length(VolumeName), nil,
      MaxComponentLength, FileSystemFlags, nil, 0) then
      if VolumeName[0] <> #0 then
        Caption := string(VolumeName);
    GetDiskFreeSpaceEx(PChar(Path), AvailableBytes, TotalBytes, @FreeBytes);
  end;
  SetDrive(Path, Caption, UInt64(Max(Int64(0), TotalBytes)), UInt64(Max(Int64(0), FreeBytes)));
end;

procedure TFrameDriveButton.SetDrive(const Path, Caption: string; TotalBytes, FreeBytes: UInt64);
begin
  PreserveUserText(LabelTitle);
  SpeedButtonDrive.TagString := Path;
  SpeedButtonDrive.Hint := Path;
  LabelTitle.Text := Caption + ' (' + Copy(Path, 1, 2) + ')';
  RectangleUsageFill.TagFloat := 0;
  if TotalBytes > 0 then
  begin
    FreeBytes := Min(FreeBytes, TotalBytes);
    RectangleUsageFill.TagFloat := (TotalBytes - FreeBytes) / TotalBytes;
    LabelUsage.Text := Format(Translate('%s of %s'), [FormatDiskBytes(TotalBytes - FreeBytes), FormatDiskBytes(TotalBytes)]);
  end
  else
    LabelUsage.Text := Translate('Select to scan');
  RectangleUsageTrackResize(nil);
end;

procedure TFrameDriveButton.RectangleUsageTrackResize(Sender: TObject);
begin
  if RectangleUsageFill <> nil then
    RectangleUsageFill.Width := RectangleUsageTrack.Width * RectangleUsageFill.TagFloat;
end;

end.

