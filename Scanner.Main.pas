unit Scanner.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Math,
  System.Generics.Collections, System.IniFiles, FMX.Types, FMX.Controls,
  FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts, FMX.Objects, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Menus, FMX.Ani, Scanner.Model,
  Scanner.ViewModel, Scanner.Chart, Scanner.DriveButton, Scanner.FolderItem,
  Scanner.Localization;

type
  TViewState = record
    Node: TDiskNode;
    Overview: Boolean;
  end;

  TViewPath = record
    Path: string;
    Overview: Boolean;
  end;

  TFormMain = class(TForm)
    RectangleFooterBackground: TRectangle;
    RectangleFooterSeparator: TRectangle;
    CircleStatusDot: TCircle;
    LayoutStatusDotSlot: TLayout;
    LabelStatus: TLabel;
    LabelFilesSummary: TLabel;
    LayoutFooter: TLayout;
    RectangleSidebarBackground: TRectangle;
    RectangleSidebarSeparator: TRectangle;
    LabelLocations: TLabel;
    PathSummaryIcon: TPath;
    LayoutSummaryGlyph: TLayout;
    LabelSummaryText: TLabel;
    SpeedButtonSummary: TSpeedButton;
    VertScrollBoxDrives: TVertScrollBox;
    LayoutDriveListSlot: TLayout;
    RectangleSidebarActionSeparator: TRectangle;
    PathChooseIcon: TPath;
    LayoutChooseGlyph: TLayout;
    LabelChooseText: TLabel;
    SpeedButtonChoose: TSpeedButton;
    PathThemeIcon: TPath;
    LayoutThemeGlyph: TLayout;
    LabelThemeText: TLabel;
    SpeedButtonTheme: TSpeedButton;
    PathSettingsIcon: TPath;
    LayoutSettingsGlyph: TLayout;
    LabelSettingsText: TLabel;
    SpeedButtonSettings: TSpeedButton;
    LayoutSidebarActions: TLayout;
    LayoutDriveSide: TLayout;
    RectangleToolbarSeparator: TRectangle;
    PathBackIcon: TPath;
    SpeedButtonBack: TSpeedButton;
    PathUpIcon: TPath;
    SpeedButtonUp: TSpeedButton;
    PathScanIcon: TPath;
    LayoutScanGlyph: TLayout;
    LabelScanText: TLabel;
    SpeedButtonScan: TSpeedButton;
    PathBrowseIcon: TPath;
    SpeedButtonBrowse: TSpeedButton;
    LabelPath: TLabel;
    RectangleBreadcrumbBorder: TRectangle;
    LayoutToolbar: TLayout;
    LabelPageTitle: TLabel;
    LabelPageSubtitle: TLabel;
    LabelUsedValueCaption: TLabel;
    LabelUsedValue: TLabel;
    LayoutUsedValueSlot: TLayout;
    LabelFreeValueCaption: TLabel;
    LabelFreeValue: TLabel;
    LayoutFreeValueSlot: TLayout;
    LabelTotalValueCaption: TLabel;
    LabelTotalValue: TLabel;
    LayoutTotalValueSlot: TLayout;
    RectangleUsageFill: TRectangle;
    RectangleUsageTrack: TRectangle;
    LabelUsagePercent: TLabel;
    LayoutUsageSlot: TLayout;
    LayoutStorageSummary: TLayout;
    LayoutHeader: TLayout;
    RectangleDetailSeparator: TRectangle;
    PathDetailIcon: TPath;
    LayoutDetailGlyph: TLayout;
    LabelDetailName: TLabel;
    LabelDetailSize: TLabel;
    LayoutDetailTitles: TLayout;
    LayoutDetailTop: TLayout;
    LabelDetailPercent: TLabel;
    LabelDetailPath: TLabel;
    PathOpenIcon: TPath;
    LayoutOpenGlyph: TLayout;
    LabelOpenText: TLabel;
    SpeedButtonOpen: TSpeedButton;
    LayoutDetailSection: TLayout;
    LabelPercentColumn: TLabel;
    LabelSizeColumn: TLabel;
    LabelNameColumn: TLabel;
    RectangleTableSeparator: TRectangle;
    LayoutTableHeader: TLayout;
    RectangleFolderPanelBackground: TRectangle;
    LabelFolderTitle: TLabel;
    RectangleFolderTitleSeparator: TRectangle;
    LayoutFolderPanelTitle: TLayout;
    VertScrollBoxFolders: TVertScrollBox;
    LabelEmpty: TLabel;
    LayoutFolderPanel: TLayout;
    LabelScan: TLabel;
    ProgressBarScan: TProgressBar;
    LayoutScanStatus: TLayout;
    LayoutChartViews: TLayout;
    PaintBoxChart: TPaintBox;
    LayoutChartColumn: TLayout;
    LayoutWorkspace: TLayout;
    LayoutMainContent: TLayout;
    LayoutBody: TLayout;
    MenuItemLanguage: TMenuItem;
    MenuItemLanguageRussian: TMenuItem;
    MenuItemLanguageEnglish: TMenuItem;
    MenuItemApps: TMenuItem;
    MenuItemTrash: TMenuItem;
    MenuItemAbout: TMenuItem;
    PopupMenuSettings: TPopupMenu;
    PathScanIconTemplate: TPath;
    PathStopIconTemplate: TPath;
    PathFolderIconTemplate: TPath;
    PathFileIconTemplate: TPath;
    PathSunIconTemplate: TPath;
    PathMoonIconTemplate: TPath;
    LayoutIconTemplates: TLayout;
    StyleBookDark: TStyleBook;
    StyleBookLight: TStyleBook;
    LangLanguages: TLang;
    TimerPoll: TTimer;
    PopupMenuNode: TPopupMenu;
    MenuItemHide: TMenuItem;
    MenuItemZoom: TMenuItem;
    MenuItemRescan: TMenuItem;
    MenuItemOpen: TMenuItem;
    MenuItemSeparator: TMenuItem;
    MenuItemRecycle: TMenuItem;
    MenuItemRemove: TMenuItem;
    PopupMenuDrive: TPopupMenu;
    MenuItemInclude: TMenuItem;
    MenuItemPhysical: TMenuItem;
    Rectangle1: TRectangle;
    procedure FormMainCreate(Sender: TObject);
    procedure FormMainDestroy(Sender: TObject);
    procedure FormMainKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    procedure PaintBoxChartPaint(Sender: TObject; Canvas: TCanvas);
    procedure PaintBoxChartMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure PaintBoxChartMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PaintBoxChartMouseLeave(Sender: TObject);
    procedure TimerPollTimer(Sender: TObject);
    procedure MenuItemIncludeClick(Sender: TObject);
    procedure MenuItemPhysicalClick(Sender: TObject);
    procedure SpeedButtonThemeClick(Sender: TObject);
    procedure SpeedButtonChooseClick(Sender: TObject);
    procedure SpeedButtonScanClick(Sender: TObject);
    procedure SpeedButtonSettingsClick(Sender: TObject);
    procedure SpeedButtonChartViewClick(Sender: TObject);
    procedure SpeedButtonOpenClick(Sender: TObject);
    procedure FormMainResize(Sender: TObject);
    procedure SpeedButtonFolderItemClick(Sender: TObject);
    procedure SpeedButtonFolderItemDblClick(Sender: TObject);
    procedure SpeedButtonFolderItemMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure SpeedButtonSummaryClick(Sender: TObject);
    procedure SpeedButtonBackClick(Sender: TObject);
    procedure SpeedButtonUpClick(Sender: TObject);
    procedure SpeedButtonBrowseClick(Sender: TObject);
    procedure MenuItemLanguageRussianClick(Sender: TObject);
    procedure MenuItemLanguageEnglishClick(Sender: TObject);
    procedure MenuItemAppsClick(Sender: TObject);
    procedure MenuItemTrashClick(Sender: TObject);
    procedure MenuItemAboutClick(Sender: TObject);
    procedure MenuItemHideClick(Sender: TObject);
    procedure MenuItemZoomClick(Sender: TObject);
    procedure MenuItemRescanClick(Sender: TObject);
    procedure MenuItemOpenClick(Sender: TObject);
    procedure MenuItemRecycleClick(Sender: TObject);
    procedure MenuItemRemoveClick(Sender: TObject);
  private
    FRoot, FFocus, FHover, FContext: TDiskNode;
    FWorker: TScanThread;
    FRetiredWorkers: TObjectList<TScanThread>;
    FHistory: TList<TViewState>;
    FViewData: TDiskViewModel;
    FChartView: TDiskChartView;
    FChartViewID: string;
    FHoverKind: TChartHitKind;
    FDrives, FScanPaths: TArray<string>;
    FIncluded: TDictionary<string, Boolean>;
    FDevices: TDictionary<string, Integer>;
    FDriveContext: string;
    FStartFolder, FPendingPath, FReplacePath, FViewPath: string;
    FHoverPoint: TPointF;
    FSkipped: Integer;
    FClosing, FRootIsSummary, FIncomingSummary: Boolean;
    FVolumeOverview, FPendingOverview, FViewOverview: Boolean;
    FIni: TMemIniFile;
    FDarkTheme: Boolean;
    FDesignReady: Boolean;
    FSelected: TDiskNode;
    FViewNodes: TArray<TDiskNode>;

    FBackground, FPanelColor, FTextColor, FMutedColor, FBorderColor: TAlphaColor;
    procedure ApplicationException(Sender: TObject; E: Exception);
    procedure ExecuteUICommand(Sender: TObject);
    procedure ExecuteNodeAction(Sender: TObject);
    procedure ExecuteSettingsAction(Sender: TObject);
    procedure SelectLanguage(const Language: string);
    function ThemeColor(const Role: string): TAlphaColor;
    function ChartContext: TChartContext;
    function ChartTheme: TChartTheme;
    function ViewFraction(Node: TDiskNode): Double;
    procedure ApplyTheme(Dark: Boolean);
    procedure ApplyThemeTo(ObjectRoot: TFmxObject);
    procedure UpdateDashboard;
    procedure ReleaseChildCapture(Container: TFmxObject);
    procedure ClearFolderRows;
    procedure BuildFolderRows;
    procedure UpdateSelection(Node: TDiskNode);
    procedure PopupNode(Node: TDiskNode; const ScreenPoint: TPointF);
    function NodeColor(Node: TDiskNode; Depth: Integer = 1): TAlphaColor;
    function FormatBytes(Value: UInt64): string;
    function NodeTitle(Node: TDiskNode): string;
    function FolderCount(Node: TDiskNode): UInt64;
    function RootNeedsZoom(Node: TDiskNode): Boolean;
    procedure StartScan(const Paths: TArray<string>; const FocusPath: string = ''; const ReplacePath: string = '');
    procedure CancelScan;
    procedure ReapWorkers;
    procedure UpdateScanStatus;
    procedure ShowNode(Node: TDiskNode);
    procedure UpdateButtons;
    procedure BuildDriveButtons;
    procedure BuildChartViewButtons;
    procedure UpdateChartViewButtons;
    procedure SpeedButtonDriveClick(Sender: TObject);
    procedure SpeedButtonDriveMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure ScanSummary;
    procedure Rescan(Node: TDiskNode);
    function FindPath(Node: TDiskNode; const Path: string): TDiskNode;
    procedure ChooseFolder;
    procedure SaveLog;
    procedure RemoveNode(Node: TDiskNode; Recycle: Boolean);
  public
    procedure SetChartView(const ID: string);
    procedure SetLanguage(const Language: string);
    property ChartViewID: string read FChartViewID;
    procedure DragOver(const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation); override;
    procedure DragDrop(const Data: TDragObject; const Point: TPointF); override;
  protected
    procedure FocusNode(Node: TDiskNode; Remember: Boolean = True; Overview: Boolean = False);
    procedure OpenTarget(const Target: string; const Parameters: string = '');
    procedure FileActionError(const Action, Target, Details: string); virtual;
  end;

var
  FormMain: TFormMain;

implementation

uses
  System.IOUtils, Winapi.Windows, Winapi.ShellAPI, Winapi.Dwmapi,
  FMX.Platform.Win, Scanner.Dialog;

{$R *.fmx}

function TFormMain.ViewFraction(Node: TDiskNode): Double;
begin
  Result := FViewData.Fraction(FFocus, Node);
end;

procedure TFormMain.FormMainCreate(Sender: TObject);
var
  P, DefaultLanguage: string;
  i: Integer;
  Item: TMenuItem;
begin
  if (GetUserDefaultUILanguage and $3FF) = $19 then
    DefaultLanguage := 'ru'
  else
    DefaultLanguage := 'en';
  Application.OnException := ApplicationException;
  FIni := TMemIniFile.Create(TPath.Combine(TPath.GetHomePath, 'ScannerFMX.ini'), TEncoding.UTF8);
  SetLanguage(FIni.ReadString('Appearance', 'Language', DefaultLanguage));
  FRetiredWorkers := TObjectList<TScanThread>.Create(True);
  FHistory := TList<TViewState>.Create;
  FViewData := TDiskViewModel.Create;
  SetChartView('sunburst');
  FIncluded := TDictionary<string, Boolean>.Create;
  FDevices := TDictionary<string, Integer>.Create;
  FDrives := AvailableDrives;
  for P in FDrives do
  begin
    FIncluded.Add(P, FIni.ReadBool('Summary', P, GetDriveType(PChar(P)) = DRIVE_FIXED));
    FDevices.Add(P, FIni.ReadInteger('PhysicalDevice', P, 0));
  end;
  for i := 0 to 7 do
  begin
    Item := TMenuItem.Create(Self);
    Item.Text := i.ToString;
    Item.Tag := i;
    Item.StyleLookup := 'menudevice' + i.ToString + 'style';
    Item.RadioItem := True;
    Item.GroupIndex := 1;
    Item.OnClick := MenuItemPhysicalClick;
    MenuItemPhysical.AddObject(Item);
  end;
  FDesignReady := True;
  ApplyTheme(FIni.ReadBool('Appearance', 'DarkTheme', True));
  BuildDriveButtons;
  BuildChartViewButtons;
  ProgressBarScan.Max := 128;
  FStartFolder := '';
  if ParamCount > 0 then
    FStartFolder := ExpandFileName(ParamStr(1));
  if FStartFolder <> '' then
    StartScan([FStartFolder], FStartFolder)
  else
    ScanSummary;
end;

procedure TFormMain.FormMainDestroy(Sender: TObject);
var
  Worker: TScanThread;
begin
  FClosing := True;
  Application.OnException := nil;
  FSelected := nil;
  TimerPoll.Enabled := False;
  CancelScan;
  for Worker in FRetiredWorkers do
    Worker.RequestCancel;
  FRetiredWorkers.Free;
  FChartView.Free;
  FViewData.Free;
  FRoot.Free;
  FHistory.Free;
  FIncluded.Free;
  FDevices.Free;
  FIni.Free;
end;

procedure TFormMain.CancelScan;
begin
  if FWorker <> nil then
  begin
    FWorker.RequestCancel;
    if not FWorker.StartRequested then
      FWorker.Start;
    FRetiredWorkers.Add(FWorker);
    FWorker := nil;
  end;
  LayoutScanStatus.Visible := False;
  if not FClosing then
    UpdateButtons;
  if not FClosing then
    PaintBoxChart.Repaint;
  if not FClosing then
    TimerPoll.Enabled := True;
end;

procedure TFormMain.ReapWorkers;
var
  i: Integer;
begin
  for i := FRetiredWorkers.Count - 1 downto 0 do
    if FRetiredWorkers[i].Finished then
      FRetiredWorkers.Delete(i)
    else
      FRetiredWorkers[i].RequestCancel;
end;

procedure TFormMain.StartScan(const Paths: TArray<string>; const FocusPath, ReplacePath: string);
var
  IDs: TArray<Integer>;
  i: Integer;
  Volumes: TArray<string>;
  Ancestor: TDiskNode;
begin
  CancelScan;
  FSelected := nil;
  FViewNodes := nil;
  ClearFolderRows;
  FIncomingSummary := False;
  FReplacePath := ReplacePath;
  FViewPath := '';
  FViewOverview := FVolumeOverview;
  if FFocus <> nil then
    FViewPath := FFocus.Path;
  if ReplacePath = '' then
    FScanPaths := Copy(Paths);
  FPendingPath := FocusPath;
  FPendingOverview := (ReplacePath = '') and (Length(Paths) = 1) and
    SameText(IncludeTrailingPathDelimiter(FocusPath), ExtractFileDrive(FocusPath) + '\');
  if ReplacePath <> '' then
    FPendingOverview := FViewOverview;
  FHover := nil;
  FHoverKind := chkNone;
  FContext := nil;
  LayoutScanStatus.Visible := True;
  LabelScan.Text := Translate('Scanning…');
  ProgressBarScan.Value := 0;
  ProgressBarScan.Visible := True;
  SetLength(IDs, Length(Paths));
  for i := 0 to High(Paths) do
    if not FDevices.TryGetValue(Paths[i], IDs[i]) then
      IDs[i] := 0;
  Volumes := nil;
  if ReplacePath <> '' then
  begin
    Ancestor := FindPath(FRoot, ReplacePath);
    while Ancestor <> nil do
    begin
      if Ancestor.IsVolume and (Ancestor.Capacity > 0) then
        Volumes := Volumes + [Ancestor.Path];
      Ancestor := Ancestor.Parent;
    end;
  end;
  FWorker := TScanThread.Create(Paths, IDs, Volumes, FRoot);
  // Do not overlap a new allocation pass with cancellation/cleanup of the old
  // pass. The timer starts this suspended worker when retired readers are gone.
  ReapWorkers;
  if FRetiredWorkers.Count = 0 then
    FWorker.Start;
  TimerPoll.Enabled := True;
  UpdateButtons;
  UpdateScanStatus;
  PaintBoxChart.Repaint;
end;

procedure TFormMain.ScanSummary;
var
  Paths: TList<string>;
  P: string;
begin
  Paths := TList<string>.Create;
  try
    for P in FDrives do
      if FIncluded[P] then
        Paths.Add(P);
    StartScan(Paths.ToArray);
    FIncomingSummary := True;
    UpdateButtons;
  finally
    Paths.Free
  end;
end;

function TFormMain.FindPath(Node: TDiskNode; const Path: string): TDiskNode;
var
  C: TDiskNode;
begin
  Result := nil;
  if Node = nil then
    Exit;
  if SameText(ExcludeTrailingPathDelimiter(Node.Path), ExcludeTrailingPathDelimiter(Path)) then
    Exit(Node);
  if Node.Children = nil then
    Exit;
  for C in Node.Children do
    if C.IsFolder and ((C.Path = '') or Path.StartsWith(IncludeTrailingPathDelimiter(C.Path), True) or
      SameText(ExcludeTrailingPathDelimiter(C.Path), ExcludeTrailingPathDelimiter(Path))) then
    begin
      Result := FindPath(C, Path);
      if Result <> nil then
        Exit
    end;
end;

procedure TFormMain.TimerPollTimer(Sender: TObject);
var
  Current: string;
  Visited, Total: UInt64;
  Counting: Boolean;
  Spaces: TArray<TVolumeSpace>;
  Space: TVolumeSpace;
  NewRoot, Target, Parent, Replacement, C: TDiskNode;
  ErrorText: string;
  Index: Integer;
  SavedHistory: TList<TViewPath>;
  SavedView: TViewPath;
  View: TViewState;
begin
  ReapWorkers;
  if FWorker = nil then
    Exit;
  if not FWorker.StartRequested then
  begin
    if FRetiredWorkers.Count = 0 then
      FWorker.Start;
    Exit;
  end;
  if not FWorker.Done then
  begin
    FWorker.Progress(Current, Visited, FSkipped, Total, Counting);
    ProgressBarScan.Value := FWorker.ProgressPosition;
    UpdateScanStatus;
    Exit;
  end;
  if FRetiredWorkers.Count <> 0 then
    Exit;
  FWorker.WaitFor;
  ErrorText := FWorker.Error;
  Spaces := FWorker.VolumeSpaces;
  SavedHistory := TList<TViewPath>.Create;
  try
    for View in FHistory do
    begin
      SavedView.Path := View.Node.Path;
      SavedView.Overview := View.Overview;
      SavedHistory.Add(SavedView)
    end;
    FHistory.Clear;
    FChartView.Reset;
    FFocus := nil;
    FHover := nil;
    FHoverKind := chkNone;
    FContext := nil;
    FSelected := nil;
    FViewNodes := nil;
    ClearFolderRows;
    FViewData.Clear;
    Target := nil;
    if FReplacePath <> '' then
      Target := FindPath(FRoot, FReplacePath);
    Parent := nil;
    Index := -1;
    if Target <> nil then
      Parent := Target.Parent;
    if Parent <> nil then
      Index := Parent.Children.IndexOf(Target);
    // TakeRoot commits the journal and may detach a reused target from its old
    // parent. Capture UI paths and the insertion position before that happens.
    NewRoot := FWorker.TakeRoot;
    FreeAndNil(FWorker);
    if NewRoot = nil then
    begin
      // Failed rescans leave the previous complete result intact.
      FPendingPath := FViewPath;
      FPendingOverview := FViewOverview;
      for SavedView in SavedHistory do
      begin
        C := FindPath(FRoot, SavedView.Path);
        if C <> nil then
        begin
          View.Node := C;
          View.Overview := SavedView.Overview;
          FHistory.Add(View)
        end;
      end;
    end
    else if (Parent <> nil) and (NewRoot.Children.Count = 1) then
    begin
      Replacement := NewRoot.Children.Extract(NewRoot.Children[0]);
      Replacement.Parent := Parent;
      if Replacement = Target then
        Parent.Children.Insert(Index, Replacement)
      else
        Parent.Children[Index] := Replacement;
      while Parent <> nil do
      begin
        Parent.Recalculate;
        Parent := Parent.Parent;
      end;
      NewRoot.Free;
      FPendingPath := FViewPath;
      FPendingOverview := FViewOverview;
      for SavedView in SavedHistory do
      begin
        C := FindPath(FRoot, SavedView.Path);
        if C <> nil then
        begin
          View.Node := C;
          View.Overview := SavedView.Overview;
          FHistory.Add(View)
        end;
      end;
    end
    else
    begin
      FRoot.Free;
      FRoot := NewRoot;
      FRootIsSummary := FIncomingSummary
    end;
  finally
    SavedHistory.Free
  end;
  for Space in Spaces do
  begin
    Target := FindPath(FRoot, Space.Path);
    if Target <> nil then
    begin
      Target.ApplyVolumeSpace(Space.Capacity, Space.FreeSpace);
      Parent := Target.Parent;
      while Parent <> nil do
      begin
        Parent.Recalculate;
        Parent := Parent.Parent
      end;
    end;
  end;
  ProgressBarScan.Value := ProgressBarScan.Max;
  LayoutScanStatus.Visible := False;
  if FPendingPath <> '' then
    FFocus := FindPath(FRoot, FPendingPath);
  if FFocus = nil then
    if not FRootIsSummary and (FRoot <> nil) and (FRoot.Children.Count = 1) then
      FFocus := FRoot.Children[0]
    else
      FFocus := FRoot;
  FVolumeOverview := (FFocus <> nil) and FFocus.IsVolume and FPendingOverview;
  ShowNode(nil);
  UpdateButtons;
  PaintBoxChart.Repaint;
  if ErrorText <> '' then
    ShowScannerDialog(Self, Translate('Scan error'), ErrorText, sdkError);
end;

procedure TFormMain.ShowNode(Node: TDiskNode);
begin
  if Node = nil then
    Node := FSelected;
  if Node = nil then
    Node := FFocus;
  UpdateSelection(Node);
end;

function TFormMain.RootNeedsZoom(Node: TDiskNode): Boolean;
var
  Sectors, Bytes, FreeClusters, Clusters: DWORD;
  Cluster: UInt64;
begin
  Result := False;
  if (Node = nil) or not Node.IsVolume or (Node.UsedArea = nil) then
    Exit;
  Cluster := 4096;
  if GetDiskFreeSpace(PChar(Node.Path), Sectors, Bytes, FreeClusters, Clusters) then
    Cluster := UInt64(Sectors) * Bytes;
  // Original Scanner only expands the disk root when less than about 2/3
  // of Windows usage could be enumerated (with an eight-cluster tolerance).
  Result := Node.Size + 8.0 * Cluster < Node.UsedArea.Size * (2.0 / 3.0);
end;

procedure TFormMain.FocusNode(Node: TDiskNode; Remember, Overview: Boolean);
var
  View: TViewState;
begin
  if (Node = FRoot) and not FRootIsSummary and (FRoot <> nil) and (FRoot.Children.Count = 1) then
    Node := FRoot.Children[0];
  if (Node <> nil) and Node.IsUsed then
  begin
    if (FFocus = FRoot) and FRootIsSummary then
      Exit;
    Node := Node.Parent;
    Overview := not RootNeedsZoom(Node);
  end;
  if (Node = nil) or not Node.IsFolder then
    Exit;
  Overview := Overview and Node.IsVolume and (Node.Capacity > 0);
  if Remember and (FFocus <> nil) and ((FFocus <> Node) or (FVolumeOverview <> Overview)) then
  begin
    View.Node := FFocus;
    View.Overview := FVolumeOverview;
    FHistory.Add(View)
  end;
  CancelScan;
  FFocus := Node;
  FSelected := nil;
  FVolumeOverview := Overview;
  FHover := nil;
  FHoverKind := chkNone;
  FChartView.Reset;
  ShowNode(nil);
  UpdateButtons;
  PaintBoxChart.Repaint;
end;

procedure TFormMain.UpdateScanStatus;
var
  Current: string;
  Visited, Total: UInt64;
  Skipped: Integer;
  Counting: Boolean;
begin
  LayoutScanStatus.Visible := FWorker <> nil;
  if FWorker = nil then
    Exit;
  FWorker.Progress(Current, Visited, Skipped, Total, Counting);
  LabelScan.Text := Current;
  if Counting then
    LabelStatus.Text := Translate('Counting files…')
  else
    LabelStatus.Text := Translate('Scanning…  Esc — stop');
  LabelFilesSummary.Text := FileCountText(Visited);
end;

procedure TFormMain.UpdateButtons;
var
  ActivePath, Drive: string;
  Item: TFmxObject;
begin
  SpeedButtonBack.Enabled := (FHistory <> nil) and (FHistory.Count > 0);
  SpeedButtonUp.Enabled := (FFocus <> nil) and (FFocus.ParentFolder <> nil);
  ActivePath := '';
  if FWorker <> nil then
    ActivePath := FPendingPath
  else if FFocus <> nil then
    ActivePath := FFocus.Path;
  Drive := ExtractFileDrive(ActivePath);
  if Drive <> '' then
    Drive := IncludeTrailingPathDelimiter(Drive);
  for Item in VertScrollBoxDrives.Content.Children do
    if Item is TFrameDriveButton then
      TFrameDriveButton(Item).SpeedButtonDrive.IsPressed := (Drive <> '') and
        SameText(TFrameDriveButton(Item).SpeedButtonDrive.TagString, Drive);
  SpeedButtonSummary.IsPressed := ActivePath = '';
  if FWorker <> nil then
  begin
    SpeedButtonScan.Hint := Translate('Stop scanning (Esc)');
    PathScanIcon.Data.Assign(PathStopIconTemplate.Data);
    LabelScanText.Text := Translate('Stop')
  end
  else
  begin
    SpeedButtonScan.Hint := Translate('Rescan folder (F5)');
    PathScanIcon.Data.Assign(PathScanIconTemplate.Data);
    LabelScanText.Text := Translate('Scan');
  end;
  UpdateDashboard;
end;

procedure TFormMain.BuildDriveButtons;
var
  DriveButton: TFrameDriveButton;
  Item: TFmxObject;
  i: Integer;
begin
  ReleaseChildCapture(VertScrollBoxDrives.Content);
  while VertScrollBoxDrives.Content.ChildrenCount > 0 do
  begin
    Item := VertScrollBoxDrives.Content.Children[0];
    if Item is TFrameDriveButton then
    begin
      DriveButton := TFrameDriveButton(Item);
      DriveButton.SpeedButtonDrive.OnClick := nil;
      DriveButton.SpeedButtonDrive.OnMouseDown := nil;
      DriveButton.SpeedButtonDrive.OnDblClick := nil;
      DriveButton.SpeedButtonDrive.TagString := '';
    end;
    Item.Release;
  end;
  for i := 0 to High(FDrives) do
  begin
    DriveButton := TFrameDriveButton.Create(Self);
    DriveButton.Name := '';
    DriveButton.Parent := VertScrollBoxDrives;
    DriveButton.Position.Y := i * DriveButton.Height;
    DriveButton.LoadDrive(FDrives[i]);
    DriveButton.SpeedButtonDrive.OnClick := SpeedButtonDriveClick;
    DriveButton.SpeedButtonDrive.OnMouseDown := SpeedButtonDriveMouseDown;
  end;
  ApplyThemeTo(VertScrollBoxDrives.Content);
  FormMainResize(nil);
end;

procedure TFormMain.SpeedButtonDriveClick(Sender: TObject);
var
  P: string;
begin
  P := TControl(Sender).TagString;
  // Original drive buttons start a fresh scan even when the summary is cached.
  StartScan([P], P);
end;

procedure TFormMain.SpeedButtonDriveMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  i: Integer;
  Point: TPointF;
begin
  if Button <> TMouseButton.mbRight then
    Exit;
  FDriveContext := TControl(Sender).TagString;
  MenuItemInclude.IsChecked := FIncluded[FDriveContext];
  for i := 0 to MenuItemPhysical.ItemsCount - 1 do
    MenuItemPhysical.Items[i].IsChecked := MenuItemPhysical.Items[i].Tag = FDevices[FDriveContext];
  Point := TControl(Sender).LocalToScreen(PointF(X, Y));
  PopupMenuDrive.Popup(Point.X, Point.Y);
end;

procedure TFormMain.MenuItemIncludeClick(Sender: TObject);
begin
  if FDriveContext = '' then
    Exit;
  FIncluded[FDriveContext] := not FIncluded[FDriveContext];
  FIni.WriteBool('Summary', FDriveContext, FIncluded[FDriveContext]);
  FIni.UpdateFile;
  ScanSummary;
end;

procedure TFormMain.MenuItemPhysicalClick(Sender: TObject);
begin
  if FDriveContext = '' then
    Exit;
  FDevices[FDriveContext] := TMenuItem(Sender).Tag;
  FIni.WriteInteger('PhysicalDevice', FDriveContext, TMenuItem(Sender).Tag);
  FIni.UpdateFile;
end;

procedure TFormMain.PaintBoxChartPaint(Sender: TObject; Canvas: TCanvas);
begin
  if FChartView <> nil then
    FChartView.Paint(Canvas, PaintBoxChart.LocalRect, ChartContext);
end;

procedure TFormMain.PaintBoxChartMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  N: TDiskNode;
  Hit: TChartHit;
begin
  FHoverPoint := PointF(X, Y);
  Hit := FChartView.HitTest(PaintBoxChart.LocalRect, ChartContext, X, Y);
  N := Hit.Node;
  if (N = FHover) and (Hit.Kind = FHoverKind) then
  begin
    if N <> nil then
      PaintBoxChart.Repaint;
    Exit;
  end;
  FHover := N;
  FHoverKind := Hit.Kind;
  if N <> nil then
    ShowNode(N)
  else
    ShowNode(nil);
  if (N <> nil) and (((N.IsFolder or N.IsUsed) and (N <> FFocus)) or
    (Hit.Kind = chkParent)) then
    PaintBoxChart.Cursor := crHandPoint
  else
    PaintBoxChart.Cursor := crDefault;
  PaintBoxChart.Repaint;
end;

procedure TFormMain.PaintBoxChartMouseLeave(Sender: TObject);
begin
  FHover := nil;
  FHoverKind := chkNone;
  if FWorker = nil then
    ShowNode(nil);
  PaintBoxChart.Repaint
end;

procedure TFormMain.PaintBoxChartMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  N: TDiskNode;
  Hit: TChartHit;
  Item: TFmxObject;
begin
  if (FWorker <> nil) or (FFocus = nil) then
    Exit;
  Hit := FChartView.HitTest(PaintBoxChart.LocalRect, ChartContext, X, Y);
  if (Button = TMouseButton.mbLeft) and (Hit.Kind = chkParent) then
  begin
    SpeedButtonUpClick(SpeedButtonUp);
    Exit;
  end;
  N := Hit.Node;
  if (N = nil) or (FWorker <> nil) then
    Exit;
  if Button = TMouseButton.mbLeft then
  begin
    if N.IsFolder then
    begin
      if N <> FFocus then
        FocusNode(N);
    end
    else
    begin
      FSelected := N;
      UpdateSelection(N);
      if VertScrollBoxFolders.Content.ChildrenCount > 0 then
        for Item in VertScrollBoxFolders.Content.Children do
          if Item is TFrameFolderItem then
            TFrameFolderItem(Item).SpeedButtonFolderItem.IsPressed := TFrameFolderItem(Item).Node = N;
      PaintBoxChart.Repaint;
    end;
  end
  else if Button = TMouseButton.mbRight then
    PopupNode(N, PaintBoxChart.LocalToScreen(PointF(X, Y)));
end;

procedure TFormMain.Rescan(Node: TDiskNode);
begin
  if Node = nil then
  begin
    ScanSummary;
    Exit
  end;
  if Node.Path = '' then
    ScanSummary
  else
    StartScan([Node.Path], Node.Path, Node.Path);
end;

procedure TFormMain.ApplicationException(Sender: TObject; E: Exception);
begin
  ShowScannerException(Self, E);
end;

procedure TFormMain.ExecuteUICommand(Sender: TObject);
var
  View: TViewState;
  Op: Integer;
  Status: HRESULT;
  SavedFocus: string;
  SavedOverview: Boolean;
begin
  Op := TFmxObject(Sender).Tag;
  case Op of
    1:
      OpenTarget('control.exe', 'appwiz.cpl');
    2:
      if ShowScannerDialog(Self, Translate('Empty Recycle Bin'), Translate('Permanently empty the Recycle Bin?'), sdkConfirmation) = mrYes then
      begin
        Status := SHEmptyRecycleBin(FormToHWND(Self), nil, SHERB_NOCONFIRMATION or SHERB_NOPROGRESSUI);
        if Succeeded(Status) then
        begin
          if FRootIsSummary then
          begin
            SavedFocus := '';
            if FFocus <> nil then
              SavedFocus := FFocus.Path;
            SavedOverview := FVolumeOverview;
            ScanSummary;
            FPendingPath := SavedFocus;
            FPendingOverview := SavedOverview;
          end
          else
            Rescan(FFocus);
        end
        else if (Status <> HRESULT($800704C7)) and (Status <> E_ABORT) then
          FileActionError(Translate('Empty Recycle Bin'), '', SysErrorMessage(Status and $FFFF) + ' (0x' + IntToHex(Cardinal(Status), 8) + ')');
      end;
    3:
      if (FFocus <> nil) and (FFocus.ParentFolder <> nil) then
        FocusNode(FFocus.ParentFolder, True, FFocus.ParentFolder.IsVolume and not RootNeedsZoom(FFocus.ParentFolder));
    4:
      if FHistory.Count > 0 then
      begin
        View := FHistory.Last;
        FHistory.Delete(FHistory.Count - 1);
        FocusNode(View.Node, False, View.Overview)
      end;
    5:
      Rescan(FFocus);
    8:
      if FRootIsSummary and (FRoot <> nil) and ((FFocus <> FRoot) or (FWorker <> nil)) then
        FocusNode(FRoot)
      else
        ScanSummary;
  end;
end;

procedure TFormMain.ExecuteNodeAction(Sender: TObject);
begin
  if FContext = nil then
    Exit;
  case TMenuItem(Sender).Tag of
    1:
      begin
        FContext.Hidden := not FContext.Hidden;
        FChartView.Reset;
        BuildFolderRows;
        PaintBoxChart.Repaint
      end;
    2:
      FocusNode(FContext);
    3:
      Rescan(FContext);
    4:
      if FContext.Path <> '' then
        OpenTarget(FContext.Path);
    5:
      RemoveNode(FContext, True);
    6:
      RemoveNode(FContext, False);
  end;
end;

procedure TFormMain.RemoveNode(Node: TDiskNode; Recycle: Boolean);
var
  Operation: TSHFileOpStruct;
  FromPath, Question, ParentPath, Details: string;
  Status: Integer;
begin
  if (Node = nil) or (Node.Path = '') or Node.IsVolume then
    Exit;
  if Recycle then
    Question := Translate('Move to the Recycle Bin?')
  else
    Question := Translate('Permanently remove?');
  if ShowScannerDialog(Self, Translate('Confirm action'), Question + sLineBreak + Node.Path, sdkConfirmation) <> mrYes then
    Exit;
  ParentPath := ExtractFileDir(Node.Path);
  FromPath := Node.Path + #0 + #0;
  FillChar(Operation, SizeOf(Operation), 0);
  Operation.Wnd := FormToHWND(Self);
  Operation.wFunc := FO_DELETE;
  Operation.pFrom := PChar(FromPath);
  Operation.fFlags := FOF_NOCONFIRMATION or FOF_NOERRORUI;
  if Recycle then
    Operation.fFlags := Operation.fFlags or FOF_ALLOWUNDO;
  Status := SHFileOperation(Operation);
  if Operation.fAnyOperationsAborted or (Status = ERROR_CANCELLED) or (Status = $75) then
    Exit;
  if Status = 0 then
    Rescan(FindPath(FRoot, ParentPath))
  else
  begin
    case Status of
      $71:
        Details := Translate('Source and destination are the same.');
      $74:
        Details := Translate('A root directory cannot be removed.');
      $78:
        Details := Translate('Access denied.');
      $79:
        Details := Translate('The path is too long for this operation.');
    else
      Details := SysErrorMessage(Status);
    end;
    FileActionError(Question, Node.Path, Details + ' (' + IntToStr(Status) + ')');
  end;
end;

procedure TFormMain.FileActionError(const Action, Target, Details: string);
begin
  ShowScannerDialog(Self, Action, Trim(Target + sLineBreak + Details), sdkError);
end;

procedure TFormMain.OpenTarget(const Target, Parameters: string);
var
  Info: TShellExecuteInfo;
  ErrorCode: DWORD;
begin
  FillChar(Info, SizeOf(Info), 0);
  Info.cbSize := SizeOf(Info);
  Info.fMask := SEE_MASK_FLAG_NO_UI;
  Info.Wnd := FormToHWND(Self);
  Info.lpVerb := 'open';
  Info.lpFile := PChar(Target);
  if Parameters <> '' then
    Info.lpParameters := PChar(Parameters);
  Info.nShow := SW_SHOWNORMAL;
  if not ShellExecuteEx(@Info) then
  begin
    ErrorCode := GetLastError;
    if ErrorCode <> ERROR_CANCELLED then
      FileActionError(Translate('Could not open'), Target, SysErrorMessage(ErrorCode));
  end;
end;

procedure TFormMain.ChooseFolder;
var
  Folder: string;
begin
  Folder := FStartFolder;
  if SelectDirectory(Translate('Select folder'), '', Folder) then
  begin
    FStartFolder := Folder;
    StartScan([Folder], Folder)
  end;
end;

function DroppedFolder(const Data: TDragObject): string;
var
  P: string;
begin
  // shortcut: only the first dropped folder is scanned, files are ignored.
  for P in Data.Files do
    if TDirectory.Exists(P) then
      Exit(P);
  Result := '';
end;

// The form, not the control under the cursor, accepts folders dropped from Explorer.
procedure TFormMain.DragOver(const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation);
begin
  inherited;
  if DroppedFolder(Data) <> '' then
    Operation := TDragOperation.Copy;
end;

procedure TFormMain.DragDrop(const Data: TDragObject; const Point: TPointF);
var
  Folder: string;
begin
  inherited;
  Folder := DroppedFolder(Data);
  if Folder = '' then
    Exit;
  FStartFolder := Folder;
  StartScan([Folder], Folder);
end;

procedure TFormMain.SaveLog;
var
  Log: TStringList;
  P, Current: string;
  Count: UInt64;
  Skipped: Integer;
begin
  Log := TStringList.Create;
  try
    Log.Add('Scanner FMX - ' + DateTimeToStr(Now));
    if FWorker <> nil then
    begin
      FWorker.Progress(Current, Count, Skipped);
      Log.Add(Current);
      Log.Add(Format(Translate('Files: %s'), [UIntToStr(Count)]));
      Log.Add(Format(Translate('Skipped: %s'), [Skipped.ToString]))
    end;
    for P in FScanPaths do
      Log.Add(Format(Translate('Scan: %s'), [P]));
    if FFocus <> nil then
    begin
      Log.Add(Format(Translate('Focus: %s'), [FFocus.Path]));
      Log.Add(Format(Translate('Allocated: %s'), [UIntToStr(FFocus.Size)]));
      Log.Add(Format(Translate('Files: %s'), [UIntToStr(FFocus.Files)]))
    end;
    Log.SaveToFile(TPath.Combine(TPath.GetDocumentsPath, 'Scanner.log'), TEncoding.UTF8);
    ShowScannerDialog(Self, Translate('Log saved'), TPath.Combine(TPath.GetDocumentsPath, 'Scanner.log'));
  finally
    Log.Free
  end;
end;

procedure TFormMain.FormMainKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  if (ssCtrl in Shift) and (Key = Ord('O')) then
  begin
    ChooseFolder;
    Key := 0
  end
  else if Key = vkF5 then
  begin
    Rescan(FFocus);
    Key := 0
  end
  else if (Key = vkBack) or ((ssAlt in Shift) and (Key = vkLeft)) then
  begin
    SpeedButtonBackClick(SpeedButtonBack);
    Key := 0
  end
  else if (ssAlt in Shift) and (Key = vkUp) then
  begin
    SpeedButtonUpClick(SpeedButtonUp);
    Key := 0
  end
  else if Key = vkEscape then
  begin
    CancelScan;
    LayoutScanStatus.Visible := False;
    ShowNode(nil);
    LabelStatus.Text := Translate('Scan stopped')
  end
  else if UpCase(KeyChar) = 'L' then
    SaveLog;
end;

function TFormMain.ThemeColor(const Role: string): TAlphaColor;
var
  Resource: TFmxObject;
  Book: TStyleBook;
begin
  Book := StyleBookLight;
  if FDarkTheme then
    Book := StyleBookDark;
  Resource := Book.Style.FindStyleResource('color.' + Role);
  if not (Resource is TColorObject) then
    raise EInvalidOperation.Create('Missing theme color: ' + Role);
  Result := TColorObject(Resource).Color;
end;

procedure TFormMain.ApplyThemeTo(ObjectRoot: TFmxObject);
var
  Child: TFmxObject;
  Role: string;
  Color: TAlphaColor;
begin
  if (ObjectRoot is TFrameFolderItem) and (TFrameFolderItem(ObjectRoot).Node <> nil) then
    TFrameFolderItem(ObjectRoot).SetCategoryColor(NodeColor(TFrameFolderItem(ObjectRoot).Node));
  Role := ObjectRoot.TagString;
  if (Role = '') and ObjectRoot.StyleName.StartsWith('theme.') then
    Role := Copy(ObjectRoot.StyleName, 7, MaxInt);
  if (Role = 'icon') or (Role = 'text') then
    Role := 'text';
  if (Role = 'surface') or (Role = 'sidebar') or (Role = 'panel') or
    (Role = 'elevated') or (Role = 'border') or (Role = 'text') or
    (Role = 'muted') or (Role = 'track') or (Role = 'selected') or
    (Role = 'accent') or (Role = 'teal') or (Role = 'green') then
  begin
    Color := ThemeColor(Role);
    if ObjectRoot is TShape then
      TShape(ObjectRoot).Fill.Color := Color
    else if ObjectRoot is TLabel then
      TLabel(ObjectRoot).TextSettings.FontColor := Color;
    if (ObjectRoot is TRectangle) and (TRectangle(ObjectRoot).Stroke.Kind <> TBrushKind.None) then
      TRectangle(ObjectRoot).Stroke.Color := FBorderColor;
  end;
  if ObjectRoot.ChildrenCount > 0 then
    for Child in ObjectRoot.Children do
      if not (Child is TStyleBook) then
        ApplyThemeTo(Child);
end;

procedure TFormMain.ApplyTheme(Dark: Boolean);
var
  DarkCaption: BOOL;
  CaptionColor, CaptionTextColor, BorderColor: COLORREF;
  Window: HWND;

  function NativeColor(Color: TAlphaColor): COLORREF;
  begin
    Result := RGB(TAlphaColorRec(Color).R, TAlphaColorRec(Color).G, TAlphaColorRec(Color).B);
  end;

begin
  FDarkTheme := Dark;
  if Dark then
    StyleBook := StyleBookDark
  else
    StyleBook := StyleBookLight;
  FBackground := ThemeColor('surface');
  FPanelColor := ThemeColor('panel');
  FTextColor := ThemeColor('text');
  FMutedColor := ThemeColor('muted');
  FBorderColor := ThemeColor('border');
  Fill.Color := FBackground;
  Fill.Kind := TBrushKind.Solid;
  DarkCaption := Dark;
  Window := FormToHWND(Self);
  // Windows 10 supports the immersive title bar; Windows 11 also accepts colors.
  // Older versions ignore unsupported DWM attributes and keep the native frame.
  DwmSetWindowAttribute(Window, DWMWA_USE_IMMERSIVE_DARK_MODE, @DarkCaption, SizeOf(DarkCaption));
  CaptionColor := NativeColor(ThemeColor('sidebar'));
  CaptionTextColor := NativeColor(FTextColor);
  BorderColor := NativeColor(FBorderColor);
  DwmSetWindowAttribute(Window, DWMWA_CAPTION_COLOR, @CaptionColor, SizeOf(CaptionColor));
  DwmSetWindowAttribute(Window, DWMWA_TEXT_COLOR, @CaptionTextColor, SizeOf(CaptionTextColor));
  DwmSetWindowAttribute(Window, DWMWA_BORDER_COLOR, @BorderColor, SizeOf(BorderColor));
  ApplyThemeTo(Self);
  LabelScanText.TextSettings.FontColor := TAlphaColors.White;
  PathScanIcon.Fill.Color := TAlphaColors.White;
  if Dark then
  begin
    LabelThemeText.Text := Translate('Light theme');
    PathThemeIcon.Data.Assign(PathSunIconTemplate.Data);
  end
  else
  begin
    LabelThemeText.Text := Translate('Dark theme');
    PathThemeIcon.Data.Assign(PathMoonIconTemplate.Data);
  end;
  SpeedButtonTheme.Hint := LabelThemeText.Text;
  PaintBoxChart.Repaint;
end;

procedure TFormMain.SpeedButtonThemeClick(Sender: TObject);
begin
  ApplyTheme(not FDarkTheme);
  FIni.WriteBool('Appearance', 'DarkTheme', FDarkTheme);
  FIni.UpdateFile;
end;

function TFormMain.FormatBytes(Value: UInt64): string;
begin
  Result := FormatDiskBytes(Value);
end;

function TFormMain.NodeTitle(Node: TDiskNode): string;
begin
  Result := DiskNodeTitle(Node);
end;

function TFormMain.FolderCount(Node: TDiskNode): UInt64;
begin
  Result := DiskFolderCount(Node);
end;

function TFormMain.NodeColor(Node: TDiskNode; Depth: Integer): TAlphaColor;
begin
  Result := ChartNodeColor(FViewData, FFocus, Node, Depth, ChartTheme);
end;

function TFormMain.ChartContext: TChartContext;
begin
  Result := Default(TChartContext);
  Result.Data := FViewData;
  Result.Focus := FFocus;
  Result.Hover := FHover;
  Result.Selected := FSelected;
  Result.Nodes := FViewNodes;
  Result.HoverPoint := FHoverPoint;
  Result.HoverKind := FHoverKind;
  Result.Busy := FWorker <> nil;
  Result.Theme := ChartTheme;
end;

function TFormMain.ChartTheme: TChartTheme;
begin
  Result.Background := FBackground;
  Result.Text := FTextColor;
  Result.Muted := FMutedColor;
  Result.Border := FBorderColor;
  Result.Elevated := ThemeColor('elevated');
  if FDarkTheme then
  begin
    Result.FreeSpace := $22286D53;
    Result.SmallFiles := $FF65758B;
  end
  else
  begin
    Result.FreeSpace := $22BFE5CF;
    Result.SmallFiles := $FF94A4BA;
  end;
end;

procedure TFormMain.SetChartView(const ID: string);
var
  NewView: TDiskChartView;
begin
  if SameText(ID, FChartViewID) then
    Exit;
  NewView := TChartViewRegistry.CreateView(ID);
  FChartView.Free;
  FChartView := NewView;
  FChartViewID := ID;
  UpdateChartViewButtons;
  FHover := nil;
  FHoverKind := chkNone;
  PaintBoxChart.Cursor := crDefault;
  if FDesignReady then
    ShowNode(nil);
  PaintBoxChart.Repaint;
end;

procedure TFormMain.UpdateDashboard;
var
  N: TDiskNode;
  Capacity, FreeBytes: UInt64;
  AvailableBytes, TotalBytes, VolumeFreeBytes: Int64;
  VolumePath: string;
begin
  if FClosing then
    Exit;
  if FWorker <> nil then
  begin
    LabelEmpty.Visible := True;
    LabelEmpty.Text := Translate('Scanning…');
    SpeedButtonOpen.Enabled := False;
    LabelPageSubtitle.Text := Translate('Scanning files and folders');
    if FPendingPath <> '' then
    begin
      LabelPath.Text := Translate('This PC') + '  ›  ' + FPendingPath;
      LabelPageTitle.Text := FPendingPath;
    end;
    UpdateScanStatus;
    Exit;
  end;
  LabelPageTitle.Text := NodeTitle(FFocus);
  LabelPath.Text := Translate('This PC');
  if (FFocus <> nil) and (FFocus.Path <> '') then
    LabelPath.Text := LabelPath.Text + '  ›  ' + FFocus.Path;
  LabelPageSubtitle.Text := Translate('Scan results');
  if FSkipped > 0 then
    LabelPageSubtitle.Text := LabelPageSubtitle.Text + ' · ' + Format(Translate('Unavailable: %s'), [IntToStr(FSkipped)]);
  Capacity := 0;
  FreeBytes := 0;
  N := FFocus;
  if N <> nil then
  begin
    LabelUsedValue.Text := FormatBytes(N.Size);
    LabelFilesSummary.Text := Format(Translate('%s · %s'), [FileCountText(N.Files), FolderCountText(FolderCount(N))]);
    while (N.Parent <> nil) and not N.IsVolume do
      N := N.Parent;
    Capacity := N.Capacity;
    FreeBytes := N.FreeSpace;
  end
  else
  begin
    LabelUsedValue.Text := '—';
    LabelFilesSummary.Text := '';
  end;
  if (Capacity = 0) and (FFocus <> nil) then
  begin
    VolumePath := IncludeTrailingPathDelimiter(ExtractFileDrive(FFocus.Path));
    if (Length(VolumePath) = 3) and (GetDriveType(PChar(VolumePath)) = DRIVE_FIXED) then
      if GetDiskFreeSpaceEx(PChar(VolumePath), AvailableBytes, TotalBytes, @VolumeFreeBytes) then
      begin
        Capacity := TotalBytes;
        FreeBytes := VolumeFreeBytes;
      end;
  end;
  if Capacity > 0 then
  begin
    // Windows volume usage also includes filesystem metadata and inaccessible files.
    LabelUsedValue.Text := FormatBytes(Capacity - FreeBytes);
    LabelFreeValue.Text := FormatBytes(FreeBytes);
    LabelTotalValue.Text := FormatBytes(Capacity);
    RectangleUsageFill.TagFloat := (Capacity - FreeBytes) / Capacity;
    LabelUsagePercent.Text := Format(Translate('%s%% used'), [FormatFloat('0', RectangleUsageFill.TagFloat * 100)]);
  end
  else
  begin
    LabelFreeValue.Text := '—';
    LabelTotalValue.Text := '—';
    RectangleUsageFill.TagFloat := 0;
    LabelUsagePercent.Text := Translate('File size');
  end;
  LabelStatus.Text := Translate('Scan complete');
  if FFocus = nil then
    LabelStatus.Text := Translate('Select a drive or folder');
  FViewNodes := FViewData.GetChildren(FFocus, True);
  BuildFolderRows;
  ShowNode(nil);
  FormMainResize(nil);
end;

procedure TFormMain.ReleaseChildCapture(Container: TFmxObject);
begin
  // Clear both FMX's captured control and the native HWND capture before
  // detaching its subtree. FreeNotification only clears the FMX reference.
  if (Captured <> nil) and Container.IsChild(Captured.GetObject) then
    SetCaptured(nil);
end;

procedure TFormMain.ClearFolderRows;
var
  Item: TFmxObject;
  Row: TFrameFolderItem;
begin
  // FMX calls Click after OnDblClick and then continues MouseDown.
  // Detach rows now, but destroy them after the current event dispatch.
  ReleaseChildCapture(VertScrollBoxFolders.Content);
  while VertScrollBoxFolders.Content.ChildrenCount > 0 do
  begin
    Item := VertScrollBoxFolders.Content.Children[0];
    if Item is TFrameFolderItem then
    begin
      Row := TFrameFolderItem(Item);
      Row.SpeedButtonFolderItem.OnClick := nil;
      Row.SpeedButtonFolderItem.OnDblClick := nil;
      Row.SpeedButtonFolderItem.OnMouseDown := nil;
      Row.SpeedButtonFolderItem.TagObject := nil;
    end;
    Item.Release;
  end;
end;

procedure TFormMain.BuildFolderRows;
var
  N: TDiskNode;
  Row: TFrameFolderItem;
  Index: Integer;
begin
  VertScrollBoxFolders.BeginUpdate;
  try
    ClearFolderRows;
    Index := 0;
    if (FFocus <> nil) and (FWorker = nil) and (FFocus.Children <> nil) then
      for N in FViewNodes do
      begin
        if N.Hidden then
          Continue;
        Row := TFrameFolderItem.Create(Self);
        Row.Name := '';
        Row.Parent := VertScrollBoxFolders;
        Row.Position.Y := Index * 62;
        Row.BindNode(N, ViewFraction(N), NodeColor(N));
        Row.SpeedButtonFolderItem.IsPressed := N = FSelected;
        Row.SpeedButtonFolderItem.OnClick := SpeedButtonFolderItemClick;
        Row.SpeedButtonFolderItem.OnDblClick := SpeedButtonFolderItemDblClick;
        Row.SpeedButtonFolderItem.OnMouseDown := SpeedButtonFolderItemMouseDown;
        Inc(Index);
      end;
    LabelEmpty.Visible := Index = 0;
    LabelEmpty.Text := Translate('Folder is empty');
    if FWorker <> nil then
      LabelEmpty.Text := Translate('Scanning…')
    else if FFocus = nil then
      LabelEmpty.Text := Translate('Select a drive or folder');
    ApplyThemeTo(VertScrollBoxFolders.Content);
  finally
    VertScrollBoxFolders.EndUpdate;
  end;
end;

procedure TFormMain.UpdateSelection(Node: TDiskNode);
begin
  SpeedButtonOpen.Enabled := (Node <> nil) and ((Node.Path <> '') or (Node is TSmallFileGroup)) and not Node.IsFree;
  LabelDetailName.Text := NodeTitle(Node);
  LabelDetailPath.Text := '';
  LabelDetailSize.Text := '—';
  LabelDetailPercent.Text := '';
  if Node = nil then
    Exit;
  if Node.IsFolder then
    PathDetailIcon.Data.Assign(PathFolderIconTemplate.Data)
  else
    PathDetailIcon.Data.Assign(PathFileIconTemplate.Data);
  LabelDetailSize.Text := FormatBytes(Node.DisplayBytes);
  LabelDetailPath.Text := Node.Path;
  if Node is TSmallFileGroup then
  begin
    LabelDetailPath.Text := Node.Parent.Path;
    LabelDetailPercent.Text := FileCountText(Node.Files);
  end;
  LabelDetailPath.Hint := LabelDetailPath.Text;
  LabelDetailPath.ShowHint := True;
  if FFocus <> nil then
    if Node is TSmallFileGroup then
      LabelDetailPercent.Text := LabelDetailPercent.Text + ' · ' + FormatFloat('0.#', 100 * ViewFraction(Node)) + '%'
    else if FFocus.IsVolume and (FFocus.Capacity > 0) then
      LabelDetailPercent.Text := Format(Translate('%s%% of disk capacity'), [FormatFloat('0.#', 100 * ViewFraction(Node))])
    else
      LabelDetailPercent.Text := Format(Translate('%s%% of file size'), [FormatFloat('0.#', 100 * ViewFraction(Node))]);
end;

procedure TFormMain.SpeedButtonFolderItemClick(Sender: TObject);
var
  Item: TFmxObject;
begin
  FSelected := TDiskNode(TFmxObject(Sender).TagObject);
  for Item in VertScrollBoxFolders.Content.Children do
    if Item is TFrameFolderItem then
      TFrameFolderItem(Item).SpeedButtonFolderItem.IsPressed := TFrameFolderItem(Item).Node = FSelected;
  FHover := nil;
  FHoverKind := chkNone;
  UpdateSelection(FSelected);
  PaintBoxChart.Repaint;
end;

procedure TFormMain.SpeedButtonFolderItemDblClick(Sender: TObject);
var
  Node: TDiskNode;
begin
  Node := TDiskNode(TFmxObject(Sender).TagObject);
  if (Node = nil) or (FWorker <> nil) then
    Exit;
  if (Node is TSmallFileGroup) or Node.IsFree or (Node is TUnscannedSpace) then
    Exit;
  if Node.IsFolder then
    FocusNode(Node);
end;

procedure TFormMain.PopupNode(Node: TDiskNode; const ScreenPoint: TPointF);
begin
  if (Node = nil) or (Node is TSmallFileGroup) or (Node is TUnscannedSpace) or Node.IsFree or (FWorker <> nil) then
    Exit;
  if Node.IsUsed then
    Node := Node.Parent;
  FContext := Node;
  MenuItemHide.Text := Translate('Hide');
  MenuItemHide.StyleLookup := 'menuhidestyle';
  if Node.Hidden then
  begin
    MenuItemHide.Text := Translate('Show');
    MenuItemHide.StyleLookup := 'menushowstyle';
  end;
  MenuItemHide.Enabled := Node.IsFolder;
  MenuItemZoom.Enabled := Node.IsFolder and (Node <> FFocus);
  MenuItemRescan.Enabled := Node.IsFolder;
  MenuItemOpen.Enabled := Node.Path <> '';
  MenuItemRecycle.Enabled := (Node.Path <> '') and not Node.IsVolume;
  MenuItemRemove.Enabled := MenuItemRecycle.Enabled;
  PopupMenuNode.Popup(ScreenPoint.X, ScreenPoint.Y);
end;

procedure TFormMain.SpeedButtonFolderItemMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Button = TMouseButton.mbRight then
  begin
    SpeedButtonFolderItemClick(Sender);
    PopupNode(FSelected, TControl(Sender).LocalToScreen(PointF(X, Y)));
  end;
end;

procedure TFormMain.FormMainResize(Sender: TObject);
begin
  if not FDesignReady or FClosing then
    Exit;
  RectangleUsageFill.Width := RectangleUsageTrack.Width * RectangleUsageFill.TagFloat;
  RectangleUsageFill.XRadius := RectangleUsageTrack.XRadius;
  RectangleUsageFill.YRadius := RectangleUsageTrack.YRadius;
  PaintBoxChart.Repaint;
end;

procedure TFormMain.SpeedButtonChooseClick(Sender: TObject);
begin
  ChooseFolder;
end;

procedure TFormMain.SpeedButtonScanClick(Sender: TObject);
begin
  if FWorker <> nil then
  begin
    CancelScan;
    LabelStatus.Text := Translate('Scan stopped');
  end
  else
    Rescan(FFocus);
end;

procedure TFormMain.SpeedButtonOpenClick(Sender: TObject);
var
  Node: TDiskNode;
begin
  Node := FSelected;
  if Node = nil then
    Node := FFocus;
  if Node is TSmallFileGroup then
    Node := Node.Parent;
  if (Node = nil) or (Node.Path = '') then
    Exit;
  if Node.IsFolder then
    OpenTarget(Node.Path)
  else
    OpenTarget('explorer.exe', '/select,"' + Node.Path + '"');
end;

procedure TFormMain.SpeedButtonSettingsClick(Sender: TObject);
begin
  var P := SpeedButtonSettings.LocalToScreen(PointF(0, 0));
  PopupMenuSettings.Popup(P.X, P.Y);
end;

procedure TFormMain.ExecuteSettingsAction(Sender: TObject);
begin
  case TFmxObject(Sender).Tag of
    21:
      ShowScannerDialog(Self, Translate('About Scanner'), 'Scanner FMX' + sLineBreak + Translate('Disk space analyzer') + sLineBreak +
        Translate('Based on Scanner 2.13 · Steffen Gerlach'));
  else
    ExecuteUICommand(Sender);
  end;
end;

procedure TFormMain.SpeedButtonSummaryClick(Sender: TObject);
begin
  ExecuteUICommand(Sender);
end;

procedure TFormMain.SpeedButtonBackClick(Sender: TObject);
begin
  ExecuteUICommand(Sender);
end;

procedure TFormMain.SpeedButtonUpClick(Sender: TObject);
begin
  ExecuteUICommand(Sender);
end;

procedure TFormMain.SpeedButtonBrowseClick(Sender: TObject);
begin
  ChooseFolder;
end;

procedure TFormMain.SelectLanguage(const Language: string);
begin
  SetLanguage(Language);
  FIni.WriteString('Appearance', 'Language', LangLanguages.Lang);
  FIni.UpdateFile;
end;

procedure TFormMain.MenuItemLanguageRussianClick(Sender: TObject);
begin
  SelectLanguage('ru');
end;

procedure TFormMain.MenuItemLanguageEnglishClick(Sender: TObject);
begin
  SelectLanguage('en');
end;

procedure TFormMain.MenuItemAppsClick(Sender: TObject);
begin
  ExecuteSettingsAction(Sender);
end;

procedure TFormMain.MenuItemTrashClick(Sender: TObject);
begin
  ExecuteSettingsAction(Sender);
end;

procedure TFormMain.MenuItemAboutClick(Sender: TObject);
begin
  ExecuteSettingsAction(Sender);
end;

procedure TFormMain.MenuItemHideClick(Sender: TObject);
begin
  ExecuteNodeAction(Sender);
end;

procedure TFormMain.MenuItemZoomClick(Sender: TObject);
begin
  ExecuteNodeAction(Sender);
end;

procedure TFormMain.MenuItemRescanClick(Sender: TObject);
begin
  ExecuteNodeAction(Sender);
end;

procedure TFormMain.MenuItemOpenClick(Sender: TObject);
begin
  ExecuteNodeAction(Sender);
end;

procedure TFormMain.MenuItemRecycleClick(Sender: TObject);
begin
  ExecuteNodeAction(Sender);
end;

procedure TFormMain.MenuItemRemoveClick(Sender: TObject);
begin
  ExecuteNodeAction(Sender);
end;

procedure TFormMain.SetLanguage(const Language: string);
var
  Code: string;
begin
  Code := 'en';
  if SameText(Language, 'ru') then
    Code := 'ru';
  PreserveUserText(LabelPageTitle);
  PreserveUserText(LabelPath);
  PreserveUserText(LabelDetailName);
  PreserveUserText(LabelDetailPath);
  PreserveUserText(LabelScan);
  SetUILanguage(Code);
  LangLanguages.Lang := Code;
  MenuItemLanguage.Text := Translate('Language');
  MenuItemLanguageRussian.Text := Translate('Russian');
  MenuItemLanguageEnglish.Text := Translate('English');
  MenuItemLanguageRussian.IsChecked := Code = 'ru';
  MenuItemLanguageEnglish.IsChecked := Code = 'en';
  MenuItemApps.Text := Translate('Programs and Features');
  MenuItemTrash.Text := Translate('Empty Recycle Bin…');
  MenuItemAbout.Text := Translate('About Scanner');
  SpeedButtonUp.Hint := Translate('Parent folder (Alt+Up)');
  SpeedButtonBack.Hint := Translate('Back (Alt+Left)');
  MenuItemInclude.Text := Translate('Include in summary');
  MenuItemPhysical.Text := Translate('Physical device ID');
  MenuItemZoom.Text := Translate('Zoom');
  MenuItemRescan.Text := Translate('Rescan');
  MenuItemOpen.Text := Translate('Open');
  MenuItemRecycle.Text := Translate('Recycle');
  MenuItemRemove.Text := Translate('Remove');
  if not FDesignReady then
  begin
    LabelDetailName.Text := Translate('Select a folder');
    Exit;
  end;
  FHover := nil;
  FHoverKind := chkNone;
  BuildDriveButtons;
  BuildChartViewButtons;
  ApplyTheme(FDarkTheme);
  UpdateButtons;
end;

procedure TFormMain.BuildChartViewButtons;
var
  Button: TSpeedButton;
  LabelTitle: TLabel;
  Index: Integer;
  Suffix: string;
  StartWord: Boolean;
  Item: TFmxObject;
begin
  ReleaseChildCapture(LayoutChartViews);
  while LayoutChartViews.ChildrenCount > 0 do
  begin
    Item := LayoutChartViews.Children[0];
    if Item is TSpeedButton then
    begin
      Button := TSpeedButton(Item);
      Button.OnClick := nil;
      Button.OnDblClick := nil;
      Button.OnMouseDown := nil;
      Button.TagString := '';
    end;
    // Released buttons still belong to LayoutChartViews until destruction.
    // Free their component names before creating the replacement buttons.
    Item.Name := '';
    Item.Release;
  end;
  Index := 0;
  for var Info in TChartViewRegistry.Views do
  begin
    Button := TSpeedButton.Create(LayoutChartViews);
    Suffix := '';
    StartWord := True;
    for var C in Info.ID do
      if CharInSet(C, ['a'..'z', 'A'..'Z', '0'..'9']) then
      begin
        if StartWord then
          Suffix := Suffix + UpCase(C)
        else
          Suffix := Suffix + C;
        StartWord := False;
      end
      else
        StartWord := True;
    if Suffix = '' then
      Suffix := 'Custom';
    while LayoutChartViews.FindComponent('SpeedButtonChartView' + Suffix) <> nil do
      Suffix := Suffix + Index.ToString;
    Button.Name := 'SpeedButtonChartView' + Suffix;
    Button.Text := '';
    Button.Parent := LayoutChartViews;
    Button.Align := TAlignLayout.Left;
    Button.Width := Min(180, Max(72, Length(Info.Title) * 7 + 24));
    Button.Position.X := Index * 180;
    Button.Margins.Right := 6;
    Button.StyleLookup := 'sidebutton';
    Button.StaysPressed := True;
    Button.TagString := Info.ID;
    Button.Hint := Info.Title;
    Button.ShowHint := True;
    Button.OnClick := SpeedButtonChartViewClick;
    LabelTitle := TLabel.Create(Button);
    LabelTitle.Name := 'LabelTitle';
    LabelTitle.Parent := Button;
    LabelTitle.Align := TAlignLayout.Client;
    LabelTitle.HitTest := False;
    LabelTitle.StyledSettings := [];
    LabelTitle.TagString := 'text';
    LabelTitle.TextSettings.Font.Size := 12;
    LabelTitle.TextSettings.HorzAlign := TTextAlign.Center;
    LabelTitle.TextSettings.WordWrap := False;
    LabelTitle.TextSettings.Trimming := TTextTrimming.Character;
    LabelTitle.Text := Info.Title;
    Inc(Index);
  end;
  ApplyThemeTo(LayoutChartViews);
  UpdateChartViewButtons;
end;

procedure TFormMain.UpdateChartViewButtons;
begin
  if LayoutChartViews.ChildrenCount = 0 then
    Exit;
  for var Item in LayoutChartViews.Children do
    if Item is TSpeedButton then
      TSpeedButton(Item).IsPressed := SameText(Item.TagString, FChartViewID);
end;

procedure TFormMain.SpeedButtonChartViewClick(Sender: TObject);
begin
  SetChartView(TControl(Sender).TagString);
end;

end.

