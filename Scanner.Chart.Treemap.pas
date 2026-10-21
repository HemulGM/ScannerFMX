unit Scanner.Chart.Treemap;

interface

uses
  System.SysUtils, System.Types, System.Math, System.Generics.Collections,
  System.Generics.Defaults, Scanner.Model, Scanner.Chart,
  Scanner.Chart.Rectangles;

type
  TTreemapTile = TRectangleChartTile;

  TTreemapChartView = class(TRectangleChartView)
  private
    procedure LayoutChildren(Node: TDiskNode; const Bounds: TRectF; Depth: Integer);
    procedure AddTile(Node: TDiskNode; const Bounds: TRectF; Depth: Integer);
  protected
    function TileTitleSuffix(Node: TDiskNode): string; override;
    procedure LayoutContent(const Bounds: TRectF); override;
  end;

implementation

uses
  Scanner.ViewModel;

function TTreemapChartView.TileTitleSuffix(Node: TDiskNode): string;
begin
  if Node.IsFolder then
    Result := ' (' + FormatDiskBytes(Node.Size) + ')'
  else
    Result := '';
end;

procedure TTreemapChartView.AddTile(Node: TDiskNode; const Bounds: TRectF; Depth: Integer);
var
  Tile: TTreemapTile;
begin
  if (Bounds.Width <= 0) or (Bounds.Height <= 0) then
    Exit;
  Tile.Node := Node;
  Tile.Bounds := Bounds;
  Tile.Depth := Depth;
  Tile.Color := ChartNodeColor(FContext.Data, FContext.Focus, Node, Depth, FContext.Theme);
  if Node.Hidden then
    Tile.Color := FContext.Theme.Muted;
  Tile.ContentBounds := TRectF.Empty;
  // Preserve the folder's header as a click target; descendants occupy its body.
  if Node.IsFolder and not Node.Hidden and (Depth < 8) and
    (Bounds.Width >= 56) and (Bounds.Height >= 56) and (Node.Size > 0) then
  begin
    Tile.ContentBounds := Bounds;
    Tile.ContentBounds.Inflate(-3, -3);
    Tile.ContentBounds.Top := Tile.ContentBounds.Top + 22;
  end;
  FTiles.Add(Tile);
  if not Tile.ContentBounds.IsEmpty then
    LayoutChildren(Node, Tile.ContentBounds, Depth + 1);
end;

procedure TTreemapChartView.LayoutChildren(Node: TDiskNode; const Bounds: TRectF; Depth: Integer);
var
  Nodes: TArray<TDiskNode>;
  Items: TList<TDiskNode>;
  Areas: TArray<Double>;
  Remaining, TileBounds: TRectF;
  Total, Area, Sum, Side, Thickness, Offset, Weight: Double;
  First, Last, i: Integer;

  function Worst(Start, Finish: Integer; Edge: Double): Double;
  var
    SumArea, MinArea, MaxArea: Double;
  begin
    SumArea := 0;
    MinArea := MaxDouble;
    MaxArea := 0;
    for var j := Start to Finish do
    begin
      SumArea := SumArea + Areas[j];
      MinArea := Min(MinArea, Areas[j]);
      MaxArea := Max(MaxArea, Areas[j]);
    end;
    if (MinArea <= 0) or (SumArea <= 0) or (Edge <= 0) then
      Exit(MaxDouble);
    Result := Max(Sqr(Edge) * MaxArea / Sqr(SumArea), Sqr(SumArea) / (Sqr(Edge) * MinArea));
  end;

begin
  if Node.Hidden or (Bounds.Width <= 0) or (Bounds.Height <= 0) then
    Exit;
  if Node = FContext.Focus then
    Nodes := FContext.Nodes
  else
    Nodes := FContext.Data.GetChildren(Node);
  Items := TList<TDiskNode>.Create;
  try
    Total := 0;
    for var Child in Nodes do
      if Child.Size > 0 then
      begin
        if Node = FContext.Focus then
          Weight := FContext.Data.Fraction(Node, Child)
        else
          Weight := Child.Size / Node.Size;
        if Weight > 0 then
        begin
          Items.Add(Child);
          Total := Total + Weight;
        end;
      end;
    Items.Sort(TComparer<TDiskNode>.Construct(
      function(const Left, Right: TDiskNode): Integer
      var
        L, R: Double;
      begin
        if Node = FContext.Focus then
        begin
          L := FContext.Data.Fraction(Node, Left);
          R := FContext.Data.Fraction(Node, Right);
        end
        else
        begin
          L := Left.Size;
          R := Right.Size;
        end;
        if L > R then
          Result := -1
        else if L < R then
          Result := 1
        else
          Result := CompareText(Left.Name, Right.Name);
      end));
    if (Items.Count = 0) or (Total <= 0) then
      Exit;
    SetLength(Areas, Items.Count);
    Area := Bounds.Width * Bounds.Height;
    for i := 0 to Items.Count - 1 do
      if Node = FContext.Focus then
        Areas[i] := Area * FContext.Data.Fraction(Node, Items[i]) / Total
      else
        Areas[i] := Area * (Items[i].Size / Node.Size) / Total;
    // Squarified rows avoid the thin strips of a simple alternating split.
    // The view model already supplies a stable size order and grouped tiny files.
    Remaining := Bounds;
    First := 0;
    while First < Items.Count do
    begin
      Side := Min(Remaining.Width, Remaining.Height);
      if Side <= 0 then
        Break;
      Last := First;
      while (Last + 1 < Items.Count) and (Worst(First, Last + 1, Side) <= Worst(First, Last, Side)) do
        Inc(Last);
      Sum := 0;
      for i := First to Last do
        Sum := Sum + Areas[i];
      Thickness := Sum / Side;
      Offset := 0;
      for i := First to Last do
      begin
        if Remaining.Width >= Remaining.Height then
        begin
          TileBounds := RectF(Remaining.Left, Remaining.Top + Offset,
            Min(Remaining.Right, Remaining.Left + Thickness), Remaining.Top + Offset + Areas[i] / Thickness);
          if i = Last then
            TileBounds.Bottom := Remaining.Bottom;
        end
        else
        begin
          TileBounds := RectF(Remaining.Left + Offset, Remaining.Top,
            Remaining.Left + Offset + Areas[i] / Thickness, Min(Remaining.Bottom, Remaining.Top + Thickness));
          if i = Last then
            TileBounds.Right := Remaining.Right;
        end;
        AddTile(Items[i], TileBounds, Depth);
        Offset := Offset + Areas[i] / Thickness;
      end;
      if Remaining.Width >= Remaining.Height then
        Remaining.Left := Min(Remaining.Right, Remaining.Left + Thickness)
      else
        Remaining.Top := Min(Remaining.Bottom, Remaining.Top + Thickness);
      First := Last + 1;
    end;
  finally
    Items.Free
  end;
end;

procedure TTreemapChartView.LayoutContent(const Bounds: TRectF);
begin
  LayoutChildren(FContext.Focus, Bounds, 1);
end;

initialization
  TChartViewRegistry.RegisterView('treemap', 'Treemap', TTreemapChartView);

end.

