unit Scanner.Chart.Rectangles;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Math,
  System.Generics.Collections, FMX.Types, FMX.Graphics, Scanner.Model,
  Scanner.ViewModel, Scanner.Chart;

type
  TRectangleChartTile = record
    Node: TDiskNode;
    Bounds, ContentBounds: TRectF;
    Depth: Integer;
    Color: TAlphaColor;
  end;

  TRectangleChartView = class abstract(TDiskChartView)
  private
    FPaintedFocus: TDiskNode;
    FPaintedBounds, FHeaderBounds: TRectF;
    procedure PaintTile(Canvas: TCanvas; const Tile: TRectangleChartTile; Outline: Boolean = False);
    function GetTiles: TArray<TRectangleChartTile>;
  protected
    FTiles: TList<TRectangleChartTile>;
    function TileTitleSuffix(Node: TDiskNode): string; virtual;
    procedure LayoutContent(const Bounds: TRectF); virtual; abstract;
    procedure DoPaint(Canvas: TCanvas; const Bounds: TRectF); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Reset; override;
    function HitTest(const Bounds: TRectF; const Context: TChartContext; X, Y: Single): TChartHit; override;
    property Tiles: TArray<TRectangleChartTile> read GetTiles;
    property HeaderBounds: TRectF read FHeaderBounds;
  end;

implementation

constructor TRectangleChartView.Create;
begin
  inherited;
  FTiles := TList<TRectangleChartTile>.Create;
end;

destructor TRectangleChartView.Destroy;
begin
  FTiles.Free;
  inherited;
end;

procedure TRectangleChartView.Reset;
begin
  FTiles.Clear;
  FPaintedFocus := nil;
  FHeaderBounds := TRectF.Empty;
end;

function TRectangleChartView.GetTiles: TArray<TRectangleChartTile>;
begin
  Result := FTiles.ToArray;
end;

function TRectangleChartView.TileTitleSuffix(Node: TDiskNode): string;
begin
  Result := '';
end;

procedure TRectangleChartView.PaintTile(Canvas: TCanvas; const Tile: TRectangleChartTile; Outline: Boolean);
var
  R, TextBounds: TRectF;
  Color: TAlphaColorRec;
  Background: TAlphaColorRec;
  Alpha, Luminance: Single;
  Title, Suffix: string;

  function Shorten(const Text: string; Width: Single): string;
  var
    Count: Integer;
  begin
    Result := Text;
    if Canvas.TextWidth(Result) <= Width then
      Exit;
    Count := Length(Text);
    while (Count > 0) and (Canvas.TextWidth(Copy(Text, 1, Count) + '…') > Width) do
      Dec(Count);
    if Count = 0 then
      Result := ''
    else
      Result := Copy(Text, 1, Count) + '…';
  end;

begin
  R := Tile.Bounds;
  R.Inflate(-0.5, -0.5);
  if R.IsEmpty then
    Exit;
  Canvas.Stroke.Kind := TBrushKind.Solid;
  if Outline then
  begin
    // Keep the complete outline inside the tile, clear of neighboring tiles.
    R.Inflate(-2.5, -2.5);
    if R.IsEmpty then
      Exit;
    Canvas.Stroke.Color := FContext.Theme.Background;
    Canvas.Stroke.Thickness := 5;
    Canvas.DrawRect(R, 0, 0, [], 1);
    Canvas.Stroke.Color := FContext.Theme.Text;
    Canvas.Stroke.Thickness := 2;
    Canvas.DrawRect(R, 0, 0, [], 1);
    Exit;
  end;
  Canvas.Fill.Color := Tile.Color;
  Canvas.FillRect(R, 0, 0, [], 1);
  Canvas.Stroke.Color := FContext.Theme.Background;
  Canvas.Stroke.Thickness := 1;
  Canvas.DrawRect(R, 0, 0, [], 1);
  if (R.Width < 28) or (R.Height < 18) then
    Exit;
  Color := TAlphaColorRec(Tile.Color);
  Background := TAlphaColorRec(FContext.Theme.Background);
  Alpha := Color.A / 255;
  Luminance := (0.2126 * Color.R + 0.7152 * Color.G + 0.0722 * Color.B) * Alpha +
    (0.2126 * Background.R + 0.7152 * Background.G + 0.0722 * Background.B) * (1 - Alpha);
  if Luminance > 145 then
    Canvas.Fill.Color := $FF152034
  else
    Canvas.Fill.Color := $FFFFFFFF;
  Canvas.Font.Family := 'Segoe UI';
  Canvas.Font.Size := 12;
  Canvas.Font.Style := [];
  if Tile.Node.IsFolder then
    Canvas.Font.Style := [TFontStyle.fsBold];
  TextBounds := R;
  TextBounds.Inflate(-5, -2);
  TextBounds.Bottom := Min(TextBounds.Bottom, TextBounds.Top + 19);
  Suffix := TileTitleSuffix(Tile.Node);
  if (Suffix <> '') and (Canvas.TextWidth(Suffix + '…') <= TextBounds.Width) then
    Title := Shorten(DiskNodeTitle(Tile.Node), TextBounds.Width - Canvas.TextWidth(Suffix)) + Suffix
  else
    Title := Shorten(DiskNodeTitle(Tile.Node) + Suffix, TextBounds.Width);
  if Title <> '' then
    Canvas.FillText(TextBounds, Title, False, 1, [], TTextAlign.Leading, TTextAlign.Center);
  if (Suffix = '') and Tile.ContentBounds.IsEmpty and (R.Height >= 40) then
  begin
    TextBounds.Offset(0, 19);
    Canvas.Font.Size := 11;
    Canvas.Font.Style := [];
    Title := Shorten(FormatDiskBytes(Tile.Node.Size), TextBounds.Width);
    if Title <> '' then
      Canvas.FillText(TextBounds, Title, False, 1, [], TTextAlign.Leading, TTextAlign.Center);
  end;
end;

procedure TRectangleChartView.DoPaint(Canvas: TCanvas; const Bounds: TRectF);
var
  Body, TextBounds: TRectF;
  Title: string;
  Tile: TRectangleChartTile;
begin
  if (Bounds.Width < 30) or (Bounds.Height < 50) then
  begin
    Reset;
    Exit;
  end;
  if (FPaintedFocus <> FContext.Focus) or (FPaintedBounds <> Bounds) then
  begin
    Reset;
    FPaintedFocus := FContext.Focus;
    FPaintedBounds := Bounds;
    FHeaderBounds := RectF(Bounds.Left + 4, Bounds.Top + 2, Bounds.Right - 4, Bounds.Top + 38);
    Body := RectF(Bounds.Left + 4, FHeaderBounds.Bottom + 3, Bounds.Right - 4, Bounds.Bottom - 4);
    LayoutContent(Body);
  end;
  Title := DiskNodeTitle(FContext.Focus);
  if FContext.Focus.ParentFolder <> nil then
    Title := Translate('Parent folder') + ' · ' + Title;
  Canvas.Font.Family := 'Segoe UI';
  Canvas.Font.Size := 13;
  Canvas.Font.Style := [];
  Canvas.Fill.Color := FContext.Theme.Text;
  TextBounds := FHeaderBounds;
  TextBounds.Inflate(-5, 0);
  Canvas.FillText(TextBounds, Title, False, 1, [], TTextAlign.Leading, TTextAlign.Center);
  Body := RectF(Bounds.Left + 4, FHeaderBounds.Bottom + 3, Bounds.Right - 4, Bounds.Bottom - 4);
  // Hover/selection paints reuse geometry; colors still follow the current theme.
  for var i := 0 to FTiles.Count - 1 do
  begin
    Tile := FTiles[i];
    Tile.Color := ChartNodeColor(FContext.Data, FContext.Focus, Tile.Node, Tile.Depth, FContext.Theme);
    if Tile.Node.Hidden then
      Tile.Color := FContext.Theme.Muted;
    FTiles[i] := Tile;
    PaintTile(Canvas, Tile);
  end;
  if FTiles.Count = 0 then
  begin
    Canvas.Fill.Color := FContext.Theme.Muted;
    Canvas.FillText(Body, Translate('Folder is empty'), False, 1, [], TTextAlign.Center, TTextAlign.Center);
  end;
  for Tile in FTiles do
    if (Tile.Node = FContext.Selected) or (Tile.Node = FContext.Hover) then
      PaintTile(Canvas, Tile, True);
end;

function TRectangleChartView.HitTest(const Bounds: TRectF; const Context: TChartContext; X, Y: Single): TChartHit;
begin
  Result := Default(TChartHit);
  if Context.Busy or (Context.Focus = nil) or (FPaintedFocus <> Context.Focus) or (FPaintedBounds <> Bounds) then
    Exit;
  if FHeaderBounds.Contains(PointF(X, Y)) then
  begin
    Result.Node := Context.Focus;
    if Context.Focus.ParentFolder <> nil then
      Result.Kind := chkParent
    else
      Result.Kind := chkNode;
    Exit;
  end;
  for var i := FTiles.Count - 1 downto 0 do
    if FTiles[i].Bounds.Contains(PointF(X, Y)) then
    begin
      Result.Kind := chkNode;
      Result.Node := FTiles[i].Node;
      Exit;
    end;
end;

end.

