unit Scanner.Chart.Sunburst;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Math,
  System.Generics.Collections, FMX.Types, FMX.Graphics, Scanner.Model,
  Scanner.ViewModel, Scanner.Chart, Scanner.Localization;

type
  TChartSegment = record
    Node: TDiskNode;
    StartAngle, SweepAngle, InnerRadius, OuterRadius: Single;
    Color: TAlphaColor;
  end;

  TFreeSpaceLabelPlacement = (fslNone, fslSectorFull, fslSectorValue, fslAboveChart);

  TFreeSpaceLabel = record
    Node: TDiskNode;
    Text: string;
    Bounds: TRectF;
    Placement: TFreeSpaceLabelPlacement;
  end;

  TSunburstChartView = class(TDiskChartView)
  private
    FSegments: TList<TChartSegment>;
    FCenter: TPointF;
    FRadius, FCenterRadius: Single;
    FLevels: Integer;
    FPreviousAngles: TArray<Single>;
    FPaintedFocus: TDiskNode;
    FPaintedBounds: TRectF;
    FFreeSpaceLabel: TFreeSpaceLabel;
    function VisibleSegment(Node: TDiskNode; Sweep: Single): Boolean;
    function VisibleDepth(Node: TDiskNode; Level: Integer; Sweep: Single): Integer;
    procedure BuildChildren(Node: TDiskNode; Start, Sweep: Single; Depth: Integer);
    procedure BuildSegments(const Bounds: TRectF);
    procedure LayoutFreeSpaceLabel(Canvas: TCanvas);
    procedure PaintFreeSpaceLabel(Canvas: TCanvas);
    procedure DrawSector(Canvas: TCanvas; const Segment: TChartSegment; Highlight: Boolean = False);
  protected
    procedure DoPaint(Canvas: TCanvas; const Bounds: TRectF); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Reset; override;
    function HitTest(const Bounds: TRectF; const Context: TChartContext; X, Y: Single): TChartHit; override;
    property FreeSpaceLabel: TFreeSpaceLabel read FFreeSpaceLabel;
  end;

implementation

constructor TSunburstChartView.Create;
begin
  inherited;
  FSegments := TList<TChartSegment>.Create;
end;

destructor TSunburstChartView.Destroy;
begin
  FSegments.Free;
  inherited;
end;

procedure TSunburstChartView.Reset;
begin
  FSegments.Clear;
  FPaintedFocus := nil;
  FFreeSpaceLabel := Default(TFreeSpaceLabel);
end;

procedure TSunburstChartView.DrawSector(Canvas: TCanvas; const Segment: TChartSegment; Highlight: Boolean);
var
  Path: TPathData;
  i, Steps: Integer;
  A: Single;
  LabelPoint: TPointF;

  function P(R, Angle: Single): TPointF;
  begin
    Result := PointF(FCenter.X + R * Cos(DegToRad(Angle)), FCenter.Y + R * Sin(DegToRad(Angle)))
  end;

begin
  if Segment.SweepAngle < 0.02 then
    Exit;
  Path := TPathData.Create;
  try
    Steps := Max(2, Ceil(Segment.SweepAngle / 2));
    Path.MoveTo(P(Segment.OuterRadius, Segment.StartAngle));
    for i := 1 to Steps do
    begin
      A := Segment.StartAngle + Segment.SweepAngle * i / Steps;
      Path.LineTo(P(Segment.OuterRadius, A))
    end;
    for i := Steps downto 0 do
    begin
      A := Segment.StartAngle + Segment.SweepAngle * i / Steps;
      Path.LineTo(P(Segment.InnerRadius, A))
    end;
    Path.ClosePath;
    Canvas.Stroke.Kind := TBrushKind.Solid;
    if Highlight then
    begin
      // A contrasting halo separates the outline from every category color.
      // This pass never fills the sector or covers its descendants.
      Canvas.Stroke.Color := FContext.Theme.Background;
      Canvas.Stroke.Thickness := 6;
      Canvas.DrawPath(Path, 1);
      Canvas.Stroke.Color := FContext.Theme.Text;
      Canvas.Stroke.Thickness := 3;
    end
    else
    begin
      Canvas.Fill.Color := Segment.Color;
      Canvas.FillPath(Path, 1);
      Canvas.Stroke.Color := FContext.Theme.Background;
      Canvas.Stroke.Thickness := 0.8
    end;
    Canvas.DrawPath(Path, 1);
    if not Highlight and (Segment.Node is TSmallFileGroup) and
      (Segment.SweepAngle >= 50) and (Segment.OuterRadius - Segment.InnerRadius >= 44) then
    begin
      LabelPoint := P((Segment.InnerRadius + Segment.OuterRadius) / 2,
        Segment.StartAngle + Segment.SweepAngle / 2);
      Canvas.Fill.Color := FContext.Theme.Text;
      Canvas.Font.Family := 'Segoe UI';
      Canvas.Font.Style := [];
      Canvas.Font.Size := 13;
      Canvas.FillText(RectF(LabelPoint.X - 70, LabelPoint.Y - 20,
          LabelPoint.X + 70, LabelPoint.Y + 2), Translate('Small files'), False, 1, [], TTextAlign.Center);
      Canvas.Font.Size := 11;
      Canvas.FillText(RectF(LabelPoint.X - 70, LabelPoint.Y + 2,
          LabelPoint.X + 70, LabelPoint.Y + 20), FileCountText(Segment.Node.Files),
        False, 1, [], TTextAlign.Center);
    end;
  finally
    Path.Free
  end;
end;

function TSunburstChartView.VisibleSegment(Node: TDiskNode; Sweep: Single): Boolean;
begin
  // Scanner: angular cutoff = (Pi / 10) / window size step,
  // where the original outer radius is 42 + 11 * step.
  // Keep this relation continuous for the freely resizable FMX window.
  Result := (Node.Size > 0) and (DegToRad(Sweep) >= Pi / (10 * Max(1, (FRadius - 42) / 11)));
end;

function TSunburstChartView.VisibleDepth(Node: TDiskNode; Level: Integer; Sweep: Single): Integer;
var
  C: TDiskNode;
  Arc: Single;
  Items: TArray<TDiskNode>;
begin
  Result := Level;
  if (Level >= 18) or Node.Hidden or (Node.Children = nil) or
    ((Node.Size = 0) and not ((Node = FContext.Focus) and Node.IsVolume and (Node.Capacity > 0))) then
    Exit;
  if Node = FContext.Focus then
    Items := FContext.Nodes
  else
    Items := FContext.Data.GetChildren(Node);
  for C in Items do
  begin
    if Node = FContext.Focus then
      Arc := Sweep * FContext.Data.Fraction(FContext.Focus, C)
    else
      Arc := Sweep * (C.Size / Node.Size);
    if VisibleSegment(C, Arc) then
      Result := Max(Result, VisibleDepth(C, Level + 1, Arc));
  end;
end;

procedure TSunburstChartView.BuildChildren(Node: TDiskNode; Start, Sweep: Single; Depth: Integer);
var
  C: TDiskNode;
  Angle, Arc, R1, R2, Limit, PaintStart: Single;
  Segment: TChartSegment;
  Items: TArray<TDiskNode>;
begin
  if (Depth > 18) or Node.Hidden or (Node.Children = nil) or
    ((Node.Size = 0) and not ((Node = FContext.Focus) and Node.IsVolume and (Node.Capacity > 0))) then
    Exit;
  Limit := FRadius;
  R1 := FCenterRadius + (Depth - 1) * (Limit - FCenterRadius) / (FLevels - 1);
  R2 := Min(Limit, FCenterRadius + Depth * (Limit - FCenterRadius) / (FLevels - 1));
  if R2 <= R1 then
    Exit;
  if Depth = 1 then
    Items := FContext.Nodes
  else
    Items := FContext.Data.GetChildren(Node);
  Angle := Start;
  for C in Items do
  begin
    if Depth = 1 then
      Arc := Sweep * FContext.Data.Fraction(FContext.Focus, C)
    else
      Arc := Sweep * (C.Size / Node.Size);
    Arc := Min(Arc, Max(0, Start + Sweep - Angle));
    if VisibleSegment(C, Arc) or ((Depth = 1) and not C.IsFolder and (C.Size > 0)) then
    begin
      PaintStart := Angle;
      if (Depth < Length(FPreviousAngles)) and
        (DegToRad(Angle - FPreviousAngles[Depth]) * R1 < 1) then
        PaintStart := FPreviousAngles[Depth];
      Segment.Node := C;
      Segment.StartAngle := PaintStart;
      Segment.SweepAngle := Max(0, Angle + Arc - PaintStart);
      if Depth < Length(FPreviousAngles) then
        FPreviousAngles[Depth] := Angle + Arc;
      Segment.InnerRadius := R1;
      Segment.OuterRadius := R2;
      if C.IsFree or (C is TUnscannedSpace) then
        Segment.OuterRadius := FRadius;
      Segment.Color := ChartNodeColor(FContext.Data, FContext.Focus, C, Depth, FContext.Theme);
      if C.Hidden then
        Segment.Color := $FFE0E0E0;
      FSegments.Add(Segment);
      if C.IsFolder then
        BuildChildren(C, Angle, Arc, Depth + 1);
    end;
    Angle := Angle + Arc;
  end;
end;

procedure TSunburstChartView.BuildSegments(const Bounds: TRectF);
begin
  FSegments.Clear;
  FCenter := Bounds.CenterPoint;
  FRadius := Min(Bounds.Width, Bounds.Height) / 2 - 10;
  FCenterRadius := FRadius * 0.30;
  if FRadius < 20 then
    Exit;
  FLevels := Min(5, Max(2, VisibleDepth(FContext.Focus, 0, 360) + 1));
  SetLength(FPreviousAngles, 20);
  for var i := 0 to High(FPreviousAngles) do
    FPreviousAngles[i] := -90;
  BuildChildren(FContext.Focus, -90, 360, 1);
end;

procedure TSunburstChartView.LayoutFreeSpaceLabel(Canvas: TCanvas);
const
  Gap = 4;
  Positions: array[0..16] of Single = (0.5, 0.55, 0.45, 0.6, 0.4, 0.65, 0.35,
    0.7, 0.3, 0.75, 0.25, 0.8, 0.2, 0.85, 0.15, 0.9, 0.1);
  Angles: array[0..4] of Single = (0.5, 0.4, 0.6, 0.3, 0.7);
var
  Segment: TChartSegment;
  ValueText, FullText: string;
  W, H, Radius, Angle: Single;
  Center: TPointF;
  R: TRectF;

  function ContainsPoint(const Point: TPointF): Boolean;
  var
    D, A: Single;
  begin
    D := Hypot(Point.X - FCenter.X, Point.Y - FCenter.Y);
    A := RadToDeg(ArcTan2(Point.Y - FCenter.Y, Point.X - FCenter.X)) - Segment.StartAngle;
    while A < 0 do
      A := A + 360;
    while A >= 360 do
      A := A - 360;
    Result := (D <= Segment.OuterRadius - Gap) and
      ((Segment.SweepAngle >= 359.99) or (A <= Segment.SweepAngle));
  end;

  function Fits(const Rect: TRectF): Boolean;
  var
    Nearest: TPointF;
  begin
    Nearest := PointF(EnsureRange(FCenter.X, Rect.Left, Rect.Right),
      EnsureRange(FCenter.Y, Rect.Top, Rect.Bottom));
    if Hypot(Nearest.X - FCenter.X, Nearest.Y - FCenter.Y) < Segment.InnerRadius + Gap then
      Exit(False);
    // Test the padded text rectangle against both radial boundaries and arcs.
    for var i := 0 to 8 do
    begin
      if not ContainsPoint(PointF(Rect.Left + Rect.Width * i / 8, Rect.Top)) or
        not ContainsPoint(PointF(Rect.Left + Rect.Width * i / 8, Rect.Bottom)) or
        not ContainsPoint(PointF(Rect.Left, Rect.Top + Rect.Height * i / 8)) or
        not ContainsPoint(PointF(Rect.Right, Rect.Top + Rect.Height * i / 8)) then
        Exit(False);
    end;
    Result := True;
  end;

  function TryText(const Text: string; Placement: TFreeSpaceLabelPlacement): Boolean;
  begin
    W := Ceil(Canvas.TextWidth(Text)) + 2 * Gap;
    H := Ceil(Canvas.TextHeight(Text)) + 2 * Gap;
    for var AnglePosition in Angles do
    begin
      Angle := DegToRad(Segment.StartAngle + Segment.SweepAngle * AnglePosition);
      for var Position in Positions do
      begin
        Radius := Segment.InnerRadius + (Segment.OuterRadius - Segment.InnerRadius) * Position;
        Center := PointF(FCenter.X + Radius * Cos(Angle), FCenter.Y + Radius * Sin(Angle));
        R := RectF(Center.X - W / 2, Center.Y - H / 2, Center.X + W / 2, Center.Y + H / 2);
        if Fits(R) then
        begin
          FFreeSpaceLabel.Text := Text;
          FFreeSpaceLabel.Bounds := R;
          FFreeSpaceLabel.Placement := Placement;
          Exit(True);
        end;
      end;
    end;
    Result := False;
  end;

begin
  FFreeSpaceLabel := Default(TFreeSpaceLabel);
  Canvas.Font.Family := 'Segoe UI';
  Canvas.Font.Size := 13;
  Canvas.Font.Style := [];
  for Segment in FSegments do
    if Segment.Node.IsFree then
    begin
      FFreeSpaceLabel.Node := Segment.Node;
      ValueText := FormatDiskBytes(Segment.Node.Size);
      FullText := Format(Translate('Free %s'), [ValueText]);
      if TryText(FullText, fslSectorFull) or TryText(ValueText, fslSectorValue) then
        Exit;
      FFreeSpaceLabel.Text := FullText;
      FFreeSpaceLabel.Placement := fslAboveChart;
      Exit;
    end;
end;

procedure TSunburstChartView.PaintFreeSpaceLabel(Canvas: TCanvas);
begin
  if FFreeSpaceLabel.Placement = fslNone then
    Exit;
  Canvas.Font.Family := 'Segoe UI';
  Canvas.Font.Size := 13;
  Canvas.Font.Style := [];
  Canvas.Fill.Color := FContext.Theme.Text;
  Canvas.FillText(FFreeSpaceLabel.Bounds, FFreeSpaceLabel.Text, False, 1, [],
    TTextAlign.Center, TTextAlign.Center);
end;

procedure TSunburstChartView.DoPaint(Canvas: TCanvas; const Bounds: TRectF);
var
  CenterR, TextR: TRectF;
  Title, NumberText: string;
  Segment: TChartSegment;
  DiagramBounds: TRectF;
  CaptionHeight, CaptionWidth: Single;
begin
  Reset;
  BuildSegments(Bounds);
  if FRadius < 20 then
    Exit;
  FPaintedFocus := FContext.Focus;
  FPaintedBounds := Bounds;
  LayoutFreeSpaceLabel(Canvas);
  if FFreeSpaceLabel.Placement = fslAboveChart then
  begin
    CaptionHeight := Ceil(Canvas.TextHeight(FFreeSpaceLabel.Text)) + 8;
    CaptionWidth := Min(Bounds.Width, Ceil(Canvas.TextWidth(FFreeSpaceLabel.Text)) + 8);
    DiagramBounds := Bounds;
    DiagramBounds.Top := DiagramBounds.Top + CaptionHeight;
    BuildSegments(DiagramBounds);
    FFreeSpaceLabel.Bounds := RectF(Bounds.CenterPoint.X - CaptionWidth / 2, Bounds.Top,
      Bounds.CenterPoint.X + CaptionWidth / 2, Bounds.Top + CaptionHeight);
  end;
  if FRadius < 20 then
  begin
    PaintFreeSpaceLabel(Canvas);
    Exit;
  end;
  if FRadius < 20 then
  begin
    PaintFreeSpaceLabel(Canvas);
    Exit;
  end;
  for Segment in FSegments do
    DrawSector(Canvas, Segment);
  CenterR := RectF(FCenter.X - FCenterRadius, FCenter.Y - FCenterRadius,
    FCenter.X + FCenterRadius, FCenter.Y + FCenterRadius);
  Canvas.Fill.Color := FContext.Theme.Background;
  Canvas.FillEllipse(CenterR, 1);
  Canvas.Fill.Color := FContext.Theme.Text;
  Canvas.Font.Family := 'Segoe UI';
  Canvas.Font.Size := 14;
  Canvas.Font.Style := [];
  Title := DiskNodeTitle(FContext.Focus);
  if FContext.Focus.IsVolume then
    Title := Format(Translate('Disk %s'), [ExtractFileDrive(FContext.Focus.Path)]);
  TextR := RectF(CenterR.Left + 6, FCenter.Y - 36, CenterR.Right - 6, FCenter.Y - 12);
  Canvas.FillText(TextR, Title, False, 1, [], TTextAlign.Center, TTextAlign.Center);
  if FContext.Focus.IsVolume and (FContext.Focus.Capacity > 0) then
    NumberText := FormatDiskBytes(FContext.Focus.Capacity)
  else
    NumberText := FormatDiskBytes(FContext.Focus.Size);
  Canvas.Font.Size := Min(28, FCenterRadius / 3.1);
  Canvas.Font.Style := [TFontStyle.fsBold];
  TextR := RectF(CenterR.Left + 4, FCenter.Y - 12, CenterR.Right - 4, FCenter.Y + 25);
  Canvas.FillText(TextR, NumberText, False, 1, [], TTextAlign.Center, TTextAlign.Center);
  Canvas.Font.Size := 13;
  Canvas.Font.Style := [];
  Canvas.Fill.Color := FContext.Theme.Muted;
  TextR := RectF(CenterR.Left + 4, FCenter.Y + 27, CenterR.Right - 4, FCenter.Y + 47);
  if FContext.Focus.IsVolume and (FContext.Focus.Capacity > 0) then
    Title := Translate('total')
  else
    Title := Translate('in files');
  Canvas.FillText(TextR, Title, False, 1, [], TTextAlign.Center, TTextAlign.Center);
  // Draw complete outlines after all sectors and the center. Later siblings
  // and child rings can no longer erase either radial edge or either arc.
  if FContext.Selected <> nil then
    for Segment in FSegments do
      if Segment.Node = FContext.Selected then
        DrawSector(Canvas, Segment, True);
  if (FContext.Hover <> nil) and (FContext.Hover <> FContext.Selected) then
    for Segment in FSegments do
      if Segment.Node = FContext.Hover then
        DrawSector(Canvas, Segment, True);
  PaintFreeSpaceLabel(Canvas);
end;

function TSunburstChartView.HitTest(const Bounds: TRectF; const Context: TChartContext; X, Y: Single): TChartHit;
var
  D, A, Radius: Single;
  Center: TPointF;
  S: TChartSegment;
  i: Integer;
begin
  Result := Default(TChartHit);
  if Context.Busy or (Context.Focus = nil) then
    Exit;
  Center := Bounds.CenterPoint;
  Radius := Min(Bounds.Width, Bounds.Height) / 2 - 10;
  if (FPaintedFocus = Context.Focus) and (FPaintedBounds = Bounds) then
  begin
    Center := FCenter;
    Radius := FRadius;
    if (FFreeSpaceLabel.Placement = fslAboveChart) and FFreeSpaceLabel.Bounds.Contains(PointF(X, Y)) then
    begin
      Result.Kind := chkNode;
      Result.Node := FFreeSpaceLabel.Node;
      Exit;
    end;
  end;
  if Radius < 20 then
    Exit;
  D := Hypot(X - Center.X, Y - Center.Y);
  if D > Radius then
    Exit;
  if D <= Radius * 0.30 then
  begin
    Result.Node := Context.Focus;
    if Context.Focus.ParentFolder <> nil then
      Result.Kind := chkParent
    else
      Result.Kind := chkNode;
    Exit;
  end;
  // Never hit stale sectors after a focus change or before repainting a resize.
  if (FPaintedFocus <> Context.Focus) or (FPaintedBounds <> Bounds) then
    Exit;
  A := RadToDeg(ArcTan2(Y - Center.Y, X - Center.X));
  if A < -90 then
    A := A + 360;
  for i := FSegments.Count - 1 downto 0 do
  begin
    S := FSegments[i];
    if (D >= S.InnerRadius) and (D <= S.OuterRadius) and
      (A >= S.StartAngle) and (A <= S.StartAngle + S.SweepAngle) then
    begin
      Result.Kind := chkNode;
      Result.Node := S.Node;
      Exit;
    end;
  end;
end;

initialization
  TChartViewRegistry.RegisterView('sunburst', 'Sunburst chart', TSunburstChartView);

end.

