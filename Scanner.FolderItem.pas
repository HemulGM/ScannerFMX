unit Scanner.FolderItem;

interface

uses
  System.Classes, System.SysUtils, System.UITypes, System.Math, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Layouts, FMX.Objects, FMX.StdCtrls,
  FMX.Controls.Presentation, Scanner.Model;

type
  TFrameFolderItem = class(TFrame)
    LayoutContent: TLayout;
    SpeedButtonFolderItem: TSpeedButton;
    LayoutValuesSlot: TLayout;
    LabelPercent: TLabel;
    LabelSize: TLabel;
    LayoutGlyphSlot: TLayout;
    RectangleSwatch: TRectangle;
    PathItemIcon: TPath;
    LayoutText: TLayout;
    LabelTitle: TLabel;
    LayoutMeterSlot: TLayout;
    RectangleUsageTrack: TRectangle;
    RectangleUsageFill: TRectangle;
    RectangleSeparator: TRectangle;
    LayoutIconTemplates: TLayout;
    PathFolderIconTemplate: TPath;
    PathFileIconTemplate: TPath;
    procedure RectangleUsageTrackResize(Sender: TObject);
  private
    function GetNode: TDiskNode;
  public
    // Borrows Node until the owning list is cleared before a tree replacement.
    procedure BindNode(Node: TDiskNode; Fraction: Double; Color: TAlphaColor);
    procedure SetCategoryColor(Color: TAlphaColor);
    property Node: TDiskNode read GetNode;
  end;

implementation

uses
  Scanner.ViewModel, Scanner.Localization;

{$R *.fmx}

function TFrameFolderItem.GetNode: TDiskNode;
begin
  Result := TDiskNode(SpeedButtonFolderItem.TagObject);
end;

procedure TFrameFolderItem.BindNode(Node: TDiskNode; Fraction: Double; Color: TAlphaColor);
begin
  PreserveUserText(LabelTitle);
  SpeedButtonFolderItem.TagObject := Node;
  LabelTitle.Text := DiskNodeTitle(Node);
  LabelSize.Text := FormatDiskBytes(Node.Size);
  LabelPercent.Text := FormatFloat('0.#', Fraction * 100) + '%';
  if (Node is TSmallFileGroup) or Node.IsFree or (Node is TUnscannedSpace) then
    SpeedButtonFolderItem.Hint := LabelTitle.Text + ' · ' + LabelSize.Text
  else
    SpeedButtonFolderItem.Hint := Node.Path;
  if Node.IsFolder then
    PathItemIcon.Data.Assign(PathFolderIconTemplate.Data)
  else
    PathItemIcon.Data.Assign(PathFileIconTemplate.Data);
  RectangleUsageFill.TagFloat := EnsureRange(Fraction, 0.0, 1.0);
  SetCategoryColor(Color);
  RectangleUsageTrackResize(nil);
end;

procedure TFrameFolderItem.SetCategoryColor(Color: TAlphaColor);
begin
  RectangleSwatch.Fill.Color := Color;
  RectangleUsageFill.Fill.Color := Color;
end;

procedure TFrameFolderItem.RectangleUsageTrackResize(Sender: TObject);
begin
  if RectangleUsageFill <> nil then
    RectangleUsageFill.Width := RectangleUsageTrack.Width * RectangleUsageFill.TagFloat;
end;

end.

