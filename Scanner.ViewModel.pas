unit Scanner.ViewModel;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults,
  Scanner.Model;

type
  TSmallFileGroup = class(TDiskNode);

  TUnscannedSpace = class(TDiskNode);

  TFolderView = class
  public
    Nodes, RootNodes: TArray<TDiskNode>;
    Colors: TDictionary<TDiskNode, Integer>;
    SmallFiles: TSmallFileGroup;
    OtherUsed: TUnscannedSpace;
    destructor Destroy; override;
  end;

  // Borrows the scan tree; owns only cached arrays and synthetic nodes.
  // Clear all consumers, then Clear this cache BEFORE replacing/mutating the tree.
  TDiskViewModel = class
  private
    FFolderViews: TObjectDictionary<TDiskNode, TFolderView>;
    function FolderView(Node: TDiskNode): TFolderView;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function GetChildren(Node: TDiskNode; IncludeVolumeSpace: Boolean = False): TArray<TDiskNode>;
    function Fraction(Focus, Node: TDiskNode): Double;
    function ColorIndex(Focus, Node: TDiskNode): Integer;
  end;

function FormatDiskBytes(Value: UInt64): string;

function DiskNodeTitle(Node: TDiskNode): string;

function DiskFolderCount(Node: TDiskNode): UInt64;

implementation

uses
  FMX.Types;

constructor TDiskViewModel.Create;
begin
  inherited;
  FFolderViews := TObjectDictionary<TDiskNode, TFolderView>.Create([doOwnsValues]);
end;

destructor TDiskViewModel.Destroy;
begin
  FFolderViews.Free;
  inherited;
end;

procedure TDiskViewModel.Clear;
begin
  FFolderViews.Clear;
end;

function TDiskViewModel.GetChildren(Node: TDiskNode; IncludeVolumeSpace: Boolean): TArray<TDiskNode>;
begin
  Result := nil;
  if Node = nil then
    Exit;
  if IncludeVolumeSpace then
    Result := FolderView(Node).RootNodes
  else
    Result := FolderView(Node).Nodes;
end;

function TDiskViewModel.ColorIndex(Focus, Node: TDiskNode): Integer;
begin
  Result := 0;
  if (Focus = nil) or (Node = nil) then
    Exit;
  while (Node.Parent <> nil) and (Node.Parent <> Focus) do
    Node := Node.Parent;
  if not FolderView(Focus).Colors.TryGetValue(Node, Result) then
    Result := 0;
end;

destructor TFolderView.Destroy;
begin
  Colors.Free;
  SmallFiles.Free;
  OtherUsed.Free;
  inherited;
end;

function TDiskViewModel.Fraction(Focus, Node: TDiskNode): Double;
var
  Used: UInt64;
begin
  Result := 0;
  if (Focus = nil) or (Node = nil) then
    Exit;
  if Focus.IsVolume and (Focus.Capacity > 0) then
  begin
    Result := Node.Size / Focus.Capacity;
    Used := Focus.Capacity - Focus.FreeSpace;
    // Hard links can make the enumerated sum exceed actual Windows usage.
    if not Node.IsFree and not (Node is TUnscannedSpace) and (Focus.Size > Used) then
      Result := Result * (Used / Focus.Size);
  end
  else if Focus.Size > 0 then
    Result := Node.Size / Focus.Size;
end;

function TDiskViewModel.FolderView(Node: TDiskNode): TFolderView;
const
  MaxIndividualFiles = 128;
var
  Items: TArray<TDiskNode>;
  Kept, Small: TList<TDiskNode>;
  Child: TDiskNode;
  LargeFiles: Integer;
  Threshold: UInt64;
  Comparer: IComparer<TDiskNode>;
begin
  if FFolderViews.TryGetValue(Node, Result) then
    Exit;
  Result := TFolderView.Create;
  Kept := TList<TDiskNode>.Create;
  Small := TList<TDiskNode>.Create;
  try
    try
      if Node.Children <> nil then
        Items := Node.Children.ToArray;
      Comparer := TComparer<TDiskNode>.Construct(
        function(const Left, Right: TDiskNode): Integer
        begin
          if Left.Size > Right.Size then
            Result := -1
          else if Left.Size < Right.Size then
            Result := 1
          else
            Result := CompareText(Left.Name, Right.Name);
        end);
      TArray.Sort<TDiskNode>(Items, Comparer);
    // Below 0.1% a file occupies less than 0.36 degrees of this folder.
    // Bound the number of file controls even for thousands of equal sizes.
      Threshold := Node.Size div 1000;
      LargeFiles := 0;
      for Child in Items do
        if Child.IsFolder or Child.Hidden then
          Kept.Add(Child)
        else if (Child.Size > 0) and (Child.Size >= Threshold) and
          (LargeFiles < MaxIndividualFiles) then
        begin
          Kept.Add(Child);
          Inc(LargeFiles);
        end
        else
          Small.Add(Child);
      if Small.Count > 1 then
      begin
        Result.SmallFiles := TSmallFileGroup.Create('', 'Small files', Node, False);
        for Child in Small do
        begin
          Inc(Result.SmallFiles.Size, Child.Size);
          Inc(Result.SmallFiles.LogicalSize, Child.LogicalSize);
          Inc(Result.SmallFiles.Files, Child.Files);
        end;
        Kept.Add(Result.SmallFiles);
      end
      else if Small.Count = 1 then
        Kept.Add(Small[0]);
      Result.Nodes := Kept.ToArray;
      TArray.Sort<TDiskNode>(Result.Nodes, Comparer);
      if Node.IsVolume and (Node.Capacity > 0) and
        (Node.Capacity - Node.FreeSpace > Node.Size) then
      begin
        Result.OtherUsed := TUnscannedSpace.Create('', 'System and inaccessible data', Node, False);
        Result.OtherUsed.Size := Node.Capacity - Node.FreeSpace - Node.Size;
      end;
      Result.RootNodes := Copy(Result.Nodes);
      if Result.OtherUsed <> nil then
        Result.RootNodes := Result.RootNodes + [TDiskNode(Result.OtherUsed)];
      if Node.IsVolume and (Node.Capacity > 0) and (Node.FreeArea <> nil) and (Node.FreeSpace > 0) then
        Result.RootNodes := Result.RootNodes + [Node.FreeArea];
      Result.Colors := TDictionary<TDiskNode, Integer>.Create;
      for var i := 0 to High(Result.RootNodes) do
        Result.Colors.Add(Result.RootNodes[i], i);
      FFolderViews.Add(Node, Result);
    except
      Result.Free;
      raise;
    end;
  finally
    Small.Free;
    Kept.Free;
  end;
end;

function FormatDiskBytes(Value: UInt64): string;
const
  Units: array[0..4] of string = ('B', 'KB', 'MB', 'GB', 'TB');
var
  N: Double;
  i: Integer;
begin
  N := Value;
  i := 0;
  while (N >= 1024) and (i < High(Units)) do
  begin
    N := N / 1024;
    Inc(i);
  end;
  if (i = 0) or (N >= 100) then
    Result := FormatFloat('0', N)
  else
    Result := FormatFloat('0.#', N);
  Result := Result + ' ' + Translate(Units[i]);
end;

function DiskNodeTitle(Node: TDiskNode): string;
begin
  if Node = nil then
    Exit(Translate('This PC'));
  if Node is TSmallFileGroup then
    Exit(Format(Translate('Small files (%s)'), [FormatFloat('#,##0', Node.Files)]));
  if Node is TUnscannedSpace then
    Exit(Translate('System and inaccessible data'));
  if Node.IsFree then
    Exit(Translate('Free'));
  if Node.IsUsed then
    Exit(Translate('Used space'));
  if Node.Path = '' then
    Exit(Translate('This PC'));
  if Node.IsVolume then
    Exit(Format(Translate('Local disk (%s)'), [ExtractFileDrive(Node.Path)]));
  Result := ExtractFileName(ExcludeTrailingPathDelimiter(Node.Path));
  if Result = '' then
    Result := Node.Name;
end;

function DiskFolderCount(Node: TDiskNode): UInt64;
var
  Child: TDiskNode;
begin
  Result := 0;
  if (Node = nil) or (Node.Children = nil) then
    Exit;
  for Child in Node.Children do
    if Child.IsFolder then
      Inc(Result, 1 + DiskFolderCount(Child));
end;

end.

