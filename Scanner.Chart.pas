unit Scanner.Chart;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Math,
  System.Math.Vectors, System.Generics.Collections, FMX.Graphics, FMX.Types,
  Scanner.Model, Scanner.ViewModel, Scanner.Localization;

type
  TChartHitKind = (chkNone, chkNode, chkParent);

  TChartHit = record
    Kind: TChartHitKind;
    Node: TDiskNode;
  end;

  TChartTheme = record
    Background, Text, Muted, Border, Elevated, FreeSpace, SmallFiles: TAlphaColor;
  end;

  // Immutable snapshot for one paint/hit test. Nodes are borrowed from Data.
  TChartContext = record
    Data: TDiskViewModel;
    Focus, Hover, Selected: TDiskNode;
    Nodes: TArray<TDiskNode>;
    HoverPoint: TPointF;
    HoverKind: TChartHitKind;
    Theme: TChartTheme;
    Busy: Boolean;
  end;

  TDiskChartView = class abstract
  private
    procedure PaintTooltip(Canvas: TCanvas; const Bounds: TRectF);
  protected
    FContext: TChartContext;
    procedure DoPaint(Canvas: TCanvas; const Bounds: TRectF); virtual; abstract;
  public
    constructor Create; virtual;
    procedure Paint(Canvas: TCanvas; const Bounds: TRectF; const Context: TChartContext);
    // Reset must release any borrowed nodes before the scan tree changes.
    procedure Reset; virtual; abstract;
    function HitTest(const Bounds: TRectF; const Context: TChartContext; X, Y: Single): TChartHit; virtual; abstract;
  end;

  TDiskChartViewClass = class of TDiskChartView;

  TChartViewInfo = record
    ID, Title: string;
    ViewClass: TDiskChartViewClass;
  end;

  TChartViewRegistry = class
  private
    class var
      FViews: TList<TChartViewInfo>;
    class constructor Create;
    class destructor Destroy;
  public
    class procedure RegisterView(const ID, Title: string; ViewClass: TDiskChartViewClass);
    class function CreateView(const ID: string): TDiskChartView;
    class function Views: TArray<TChartViewInfo>;
  end;

function ChartNodeColor(Data: TDiskViewModel; Focus, Node: TDiskNode; Depth: Integer; const Theme: TChartTheme): TAlphaColor;

implementation

class constructor TChartViewRegistry.Create;
begin
  FViews := TList<TChartViewInfo>.Create;
end;

class destructor TChartViewRegistry.Destroy;
begin
  FViews.Free;
end;

class procedure TChartViewRegistry.RegisterView(const ID, Title: string; ViewClass: TDiskChartViewClass);
var
  Info: TChartViewInfo;
begin
  if (Trim(ID) = '') or (ViewClass = nil) then
    raise EArgumentException.Create('Chart view requires an ID and a class');
  for Info in FViews do
    if SameText(Info.ID, ID) then
      raise EArgumentException.Create('Duplicate chart view: ' + ID);
  Info.ID := ID;
  Info.Title := Title;
  Info.ViewClass := ViewClass;
  FViews.Add(Info);
end;

class function TChartViewRegistry.CreateView(const ID: string): TDiskChartView;
var
  Info: TChartViewInfo;
begin
  for Info in FViews do
    if SameText(Info.ID, ID) then
      Exit(Info.ViewClass.Create);
  raise EArgumentException.Create('Unknown chart view: ' + ID);
end;

class function TChartViewRegistry.Views: TArray<TChartViewInfo>;
begin
  Result := FViews.ToArray;
  for var i := 0 to High(Result) do
    Result[i].Title := Translate(Result[i].Title);
end;

constructor TDiskChartView.Create;
begin
  inherited;
end;

procedure TDiskChartView.Paint(Canvas: TCanvas; const Bounds: TRectF; const Context: TChartContext);
var
  State: TCanvasSaveState;
  Title: string;
begin
  FContext := Context;
  State := Canvas.SaveState;
  try
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := Context.Theme.Background;
    Canvas.FillRect(Bounds, 0, 0, [], 1);
    if Context.Busy or (Context.Focus = nil) then
    begin
      Reset;
      Canvas.Font.Family := 'Segoe UI';
      Canvas.Font.Size := 15;
      Canvas.Fill.Color := Context.Theme.Muted;
      Title := Translate('Select a drive or folder');
      if Context.Busy then
        Title := Translate('Analyzing contents…');
      Canvas.FillText(Bounds, Title, False, 1, [], TTextAlign.Center, TTextAlign.Center);
    end
    else
    begin
      DoPaint(Canvas, Bounds);
      PaintTooltip(Canvas, Bounds);
    end;
  finally
    Canvas.RestoreState(State);
    FContext := Default(TChartContext);
  end;
end;

function Palette(Index: Integer): TPoint3D;
const
  Colors: array[0..5] of TAlphaColor = ($FF329AFF, $FF2BB8B9, $FFFFA04F, $FFA37CEB, $FFFFC84C, $FF8E9BAD);
var
  C: TAlphaColor;
begin
  C := Colors[Index mod Length(Colors)];
  Result := Point3D((C shr 16) and $FF, (C shr 8) and $FF, C and $FF);
end;

function ChartNodeColor(Data: TDiskViewModel; Focus, Node: TDiskNode; Depth: Integer; const Theme: TChartTheme): TAlphaColor;
var
  Index, R, G, B: Integer;
  Base: TPoint3D;
  Mix: Single;
begin
  if Node.IsFree then
    Exit(Theme.FreeSpace);
  if Node is TUnscannedSpace then
    Exit(Theme.Muted);
  if Node is TSmallFileGroup then
    Exit(Theme.SmallFiles);
  Index := Data.ColorIndex(Focus, Node);
  Base := Palette(Index);
  Mix := Min(0.55, Max(0, Depth - 1) * 0.14);
  R := Round(Base.X + (255 - Base.X) * Mix);
  G := Round(Base.Y + (255 - Base.Y) * Mix);
  B := Round(Base.Z + (255 - Base.Z) * Mix);
  Result := $FF000000 or (Cardinal(R) shl 16) or (Cardinal(G) shl 8) or Cardinal(B);
end;

procedure TDiskChartView.PaintTooltip(Canvas: TCanvas; const Bounds: TRectF);
const
  Padding = 8;
  Gap = 12;
var
  NameText, SizeText: string;
  R, TextR: TRectF;
  W, H, LineHeight, X, Y: Single;
  State: TCanvasSaveState;
begin
  if FContext.Hover = nil then
    Exit;
  NameText := FContext.Hover.Name;
  if (FContext.Hover is TSmallFileGroup) or (FContext.Hover is TUnscannedSpace) then
    NameText := DiskNodeTitle(FContext.Hover);
  if FContext.Hover.IsFree then
    NameText := Translate('Free')
  else if FContext.Hover.IsUsed then
    NameText := Translate('Used space')
  else if (FContext.Hover.Path = '') and not (FContext.Hover is TSmallFileGroup) and not (FContext.Hover is TUnscannedSpace) then
    NameText := Translate('This PC');
  SizeText := FormatDiskBytes(FContext.Hover.DisplayBytes);
  if FContext.Hover is TSmallFileGroup then
    SizeText := SizeText + ' · ' + FileCountText(FContext.Hover.Files);
  if FContext.Focus <> nil then
    SizeText := SizeText + ' · ' + FormatFloat('0.#', 100 * FContext.Data.Fraction(FContext.Focus, FContext.Hover)) + '%';
  if (FContext.HoverKind = chkParent) and (FContext.Focus <> nil) and (FContext.Focus.ParentFolder <> nil) then
  begin
    NameText := Translate('Parent folder');
    SizeText := DiskNodeTitle(FContext.Focus.ParentFolder);
  end;
  State := Canvas.SaveState;
  try
    Canvas.Font.Family := 'Segoe UI';
    Canvas.Font.Size := 14;
    Canvas.Font.Style := [];
    LineHeight := Ceil(Max(Canvas.TextHeight(NameText), Canvas.TextHeight(SizeText)));
    W := Min(Max(Canvas.TextWidth(NameText), Canvas.TextWidth(SizeText)) + 2 * Padding,
      Bounds.Width - 2 * Padding);
    H := 2 * LineHeight + 2 * Padding;
    X := FContext.HoverPoint.X + Gap;
    Y := FContext.HoverPoint.Y + Gap;
    if X + W > Bounds.Right - Padding then
      X := FContext.HoverPoint.X - Gap - W;
    if Y + H > Bounds.Bottom - Padding then
      Y := FContext.HoverPoint.Y - Gap - H;
    X := EnsureRange(X, Bounds.Left + Padding, Max(Bounds.Left + Padding, Bounds.Right - Padding - W));
    Y := EnsureRange(Y, Bounds.Top + Padding, Max(Bounds.Top + Padding, Bounds.Bottom - Padding - H));
    R := RectF(X, Y, X + W, Y + H);
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.Fill.Color := FContext.Theme.Elevated;
    Canvas.FillRect(R, 4, 4, [], 1);
    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.Stroke.Color := FContext.Theme.Border;
    Canvas.Stroke.Thickness := 1;
    Canvas.DrawRect(R, 4, 4, [], 1);
    Canvas.Fill.Color := FContext.Theme.Text;
    TextR := RectF(R.Left + Padding, R.Top + Padding, R.Right - Padding,
      R.Top + Padding + LineHeight);
    Canvas.FillText(TextR, NameText, False, 1, [], TTextAlign.Leading, TTextAlign.Center);
    TextR.Offset(0, LineHeight);
    Canvas.FillText(TextR, SizeText, False, 1, [], TTextAlign.Leading, TTextAlign.Center);
  finally
    Canvas.RestoreState(State);
  end;
end;

end.

