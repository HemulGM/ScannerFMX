unit Scanner.Chart.Icicle;

interface

uses
  System.SysUtils, System.Types, System.Math, Scanner.Model, Scanner.Chart,
  Scanner.Chart.Rectangles;

type
  TIcicleChartView = class(TRectangleChartView)
  private
    FRowHeight: Single;
    FMaxDepth: Integer;
    function VisibleDepth(Node: TDiskNode; Width: Single; Depth: Integer): Integer;
    procedure LayoutLevel(Node: TDiskNode; const Bounds: TRectF; Depth: Integer);
  protected
    procedure LayoutContent(const Bounds: TRectF); override;
  end;

implementation

function TIcicleChartView.VisibleDepth(Node: TDiskNode; Width: Single; Depth: Integer): Integer;
var
  Items: TArray<TDiskNode>;
  Total, Weight: Double;
begin
  Result := Depth;
  if Node.Hidden or not Node.IsFolder or (Depth >= FMaxDepth) or (Width < 0.5) then
    Exit;
  if Node = FContext.Focus then
    Items := FContext.Nodes
  else
    Items := FContext.Data.GetChildren(Node);
  Total := 0;
  for var Child in Items do
    if Child.Size > 0 then
      if Node = FContext.Focus then
        Total := Total + FContext.Data.Fraction(Node, Child)
      else if Node.Size > 0 then
        Total := Total + Child.Size / Node.Size;
  if Total <= 0 then
    Exit;
  for var Child in Items do
    if Child.Size > 0 then
    begin
      if Node = FContext.Focus then
        Weight := FContext.Data.Fraction(Node, Child) / Total
      else
        Weight := (Child.Size / Node.Size) / Total;
      if (Weight > 0) and (Width * Weight >= 0.5) then
        Result := Max(Result, VisibleDepth(Child, Width * Weight, Depth + 1));
    end;
end;

procedure TIcicleChartView.LayoutLevel(Node: TDiskNode; const Bounds: TRectF; Depth: Integer);
var
  Items: TArray<TDiskNode>;
  Tile: TRectangleChartTile;
  Total, Weight, Left, Right: Double;
begin
  if Node.Hidden or not Node.IsFolder or (Depth > FMaxDepth) or (Bounds.Width < 0.5) or (Bounds.Height <= 0) then
    Exit;
  if Node = FContext.Focus then
    Items := FContext.Nodes
  else
    Items := FContext.Data.GetChildren(Node);
  Total := 0;
  for var Child in Items do
    if Child.Size > 0 then
      if Node = FContext.Focus then
        Total := Total + FContext.Data.Fraction(Node, Child)
      else if Node.Size > 0 then
        Total := Total + Child.Size / Node.Size;
  if Total <= 0 then
    Exit;
  Left := Bounds.Left;
  for var Child in Items do
    if Child.Size > 0 then
    begin
      if Node = FContext.Focus then
        Weight := FContext.Data.Fraction(Node, Child) / Total
      else
        Weight := (Child.Size / Node.Size) / Total;
      if Weight <= 0 then
        Continue;
      Right := Min(Bounds.Right, Left + Bounds.Width * Weight);
      if Right - Left >= 0.5 then
      begin
        Tile := Default(TRectangleChartTile);
        Tile.Node := Child;
        Tile.Depth := Depth;
        Tile.Bounds := RectF(Left, Bounds.Top, Right, Min(Bounds.Bottom, Bounds.Top + FRowHeight));
        FTiles.Add(Tile);
        // Descendants stay directly below their parent, at the same horizontal scale.
        LayoutLevel(Child, RectF(Left, Tile.Bounds.Bottom, Right, Bounds.Bottom), Depth + 1);
      end;
      Left := Right;
    end;
end;

procedure TIcicleChartView.LayoutContent(const Bounds: TRectF);
var
  Depth: Integer;
begin
  // Keep rows readable; deeper levels can be reached by opening a folder.
  FMaxDepth := Max(1, Min(12, Trunc(Bounds.Height / 24)));
  Depth := Max(1, VisibleDepth(FContext.Focus, Bounds.Width, 0));
  FRowHeight := Min(72, Bounds.Height / Depth);
  LayoutLevel(FContext.Focus, Bounds, 1);
end;

initialization
  TChartViewRegistry.RegisterView('icicle', 'Icicle', TIcicleChartView);

end.

