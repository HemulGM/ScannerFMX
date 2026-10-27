unit Scanner.Model;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs,
  Winapi.Windows;

type
  TVolumeSpace = record
    Path: string;
    Capacity, FreeSpace: UInt64;
  end;

  TDiskNode = class
  private
    FPathPart: string;
    FParent: TDiskNode;
    FIsFolder: Boolean;
    function GetPath: string;
    procedure SetParent(Value: TDiskNode);
    procedure SetIsFolder(Value: Boolean);
  public
    Name: string;
    Children: TObjectList<TDiskNode>;
    Size, LogicalSize, Files, Capacity, FreeSpace: UInt64;
    IsVolume, IsFree, IsUsed, Hidden, Unreadable: Boolean;
    UsedArea, FreeArea: TDiskNode;
    property Path: string read GetPath;
    property Parent: TDiskNode read FParent write SetParent;
    property IsFolder: Boolean read FIsFolder write SetIsFolder;
    function DisplayBytes: UInt64;
    constructor Create(const APath, AName: string; AParent: TDiskNode = nil; AIsFolder: Boolean = True);
    destructor Destroy; override;
    function ParentFolder: TDiskNode;
    procedure Recalculate;
    procedure ApplyVolumeSpace(Total, FreeBytes: UInt64);
  end;

  TNodeValues = record
    Size, LogicalSize, Files, Capacity, FreeSpace: UInt64;
    Unreadable: Boolean;
    procedure Apply(Node: TDiskNode);
    function Matches(Node: TDiskNode): Boolean;
  end;

  // A rescan borrows the displayed tree read-only. Changes become visible only
  // when the UI thread calls TakeRoot; cancellation discards this journal.
  TScanChange = class
    Node: TDiskNode;
    Name: string;
    Values: TNodeValues;
    Children: TObjectList<TDiskNode>;
    destructor Destroy; override;
  end;

  TScanThread = class(TThread)
  private
    FRoot, FSourceRoot: TDiskNode;
    FCreatedNodes: TObjectList<TDiskNode>;
    FChanges: TObjectList<TScanChange>;
    FPaths: TArray<string>;
    FDeviceIDs: TArray<Integer>;
    FRefreshVolumes: TArray<string>;
    FVolumeSpaces: TArray<TVolumeSpace>;
    FTotalFiles: UInt64;
    FProcessedBytes, FExpectedBytes: UInt64;
    FGroupProgress: Integer;
    FCounting: Boolean;
    FLock: TCriticalSection;
    FCurrent, FError: string;
    FVisited: UInt64;
    FSkipped: Integer;
    FDone: Integer;
    FStartRequested: Boolean;
    // A sub-scan reports progress and takes thread slots from the thread that owns the volume.
    FOwner: TScanThread;
    FFreeSlots: Integer;
    FSubNode: TDiskNode;
    FSubPath, FSubName: string;
    FSubCluster: UInt64;
    FSubDepth: Integer;
    FSubExisting: Boolean;
    FSubValues: TNodeValues;
    constructor CreateSub(Owner: TScanThread; Node: TDiskNode; const Path, Name: string; Cluster: UInt64; Depth: Integer; Existing: Boolean);
    function Cancelled: Boolean;
    function NewNode(const Path, Name: string; Parent: TDiskNode; IsFolder: Boolean): TDiskNode;
    function FindSource(const Path: string): TDiskNode;
    procedure StageNode(Node: TDiskNode; const Name: string; const Values: TNodeValues; Children: TObjectList<TDiskNode>; Existing: Boolean);
    procedure CommitChanges;
    procedure AdoptChanges(Worker: TScanThread);
    procedure DiscardResult;
    procedure PrepareProgress;
    procedure ScanGroups;
    function ScanDirectory(Node: TDiskNode; const DirectoryPath: string; Cluster: UInt64; Depth: Integer; Existing: Boolean): TNodeValues;
    function ScanVolume(Node: TDiskNode; Existing: Boolean): TNodeValues;
  protected
    procedure Execute; override;
  public
    constructor Create(const Paths: TArray<string>; const DeviceIDs: TArray<Integer> = nil; const RefreshVolumes: TArray<string> = nil; SourceRoot: TDiskNode = nil);
    destructor Destroy; override;
    procedure Start; reintroduce;
    property StartRequested: Boolean read FStartRequested;
    function TakeRoot: TDiskNode;
    procedure RequestCancel;
    procedure Progress(out Current: string; out Visited: UInt64; out Skipped: Integer); overload;
    procedure Progress(out Current: string; out Visited: UInt64; out Skipped: Integer; out Total: UInt64; out Counting: Boolean); overload;
    property VolumeSpaces: TArray<TVolumeSpace> read FVolumeSpaces;
    procedure ProgressBytes(out Processed, Expected: UInt64);
    function ProgressPosition: Integer;
    function Done: Boolean;
    property Error: string read FError;
  end;

function DisplaySize(Value: UInt64): string; overload;

function DisplaySize(Value, Reference: UInt64): string; overload;

function LongPath(const Path: string): string;

function AvailableDrives: TArray<string>;

implementation

uses
  System.Math, System.Generics.Defaults;

constructor TDiskNode.Create(const APath, AName: string; AParent: TDiskNode; AIsFolder: Boolean);
begin
  inherited Create;
  Name := AName;
  FParent := AParent;
  if (APath <> '') and (AParent <> nil) and (AParent.FPathPart <> '') then
  begin
    // Share the name string's storage for ordinary entries, including files.
    FPathPart := ExtractFileName(ExcludeTrailingPathDelimiter(APath));
    if FPathPart = Name then
      FPathPart := Name;
  end
  else
    FPathPart := APath;
  IsFolder := AIsFolder;
end;

function TDiskNode.GetPath: string;
var
  Node: TDiskNode;
  Count, Offset, PartLength: Integer;
begin
  if FPathPart = '' then
    Exit('');
  if (FParent = nil) or (FParent.FPathPart = '') then
    Exit(FPathPart);
  // Allocate once, rather than constructing a temporary string per ancestor.
  Count := 0;
  Node := Self;
  while (Node <> nil) and (Node.FPathPart <> '') do
  begin
    Inc(Count, Length(Node.FPathPart));
    if (Node.FParent <> nil) and (Node.FParent.FPathPart <> '') and
      not IsPathDelimiter(Node.FParent.FPathPart, Length(Node.FParent.FPathPart)) then
      Inc(Count);
    Node := Node.FParent;
  end;
  SetLength(Result, Count);
  Offset := Count;
  Node := Self;
  while (Node <> nil) and (Node.FPathPart <> '') do
  begin
    PartLength := Length(Node.FPathPart);
    Dec(Offset, PartLength);
    Move(PChar(Node.FPathPart)^, (PChar(Result) + Offset)^, PartLength * SizeOf(Char));
    if (Node.FParent <> nil) and (Node.FParent.FPathPart <> '') and
      not IsPathDelimiter(Node.FParent.FPathPart, Length(Node.FParent.FPathPart)) then
    begin
      Dec(Offset);
      Result[Offset + 1] := PathDelim
    end;
    Node := Node.FParent;
  end;
end;

procedure TDiskNode.SetParent(Value: TDiskNode);
begin
  if FParent = Value then
    Exit;
  if FPathPart <> '' then
    if (Value = nil) or (Value.FPathPart = '') then
      FPathPart := Path
    else if (FParent = nil) or (FParent.FPathPart = '') then
    begin
      FPathPart := ExtractFileName(ExcludeTrailingPathDelimiter(FPathPart));
      if FPathPart = Name then
        FPathPart := Name;
    end;
  FParent := Value;
end;

procedure TDiskNode.SetIsFolder(Value: Boolean);
begin
  if FIsFolder = Value then
    Exit;
  FIsFolder := Value;
  if Value then
    Children := TObjectList<TDiskNode>.Create(True)
  else
    FreeAndNil(Children);
end;

destructor TDiskNode.Destroy;
begin
  UsedArea.Free;
  FreeArea.Free;
  Children.Free;
  inherited;
end;

function TDiskNode.ParentFolder: TDiskNode;
begin
  Result := nil;
  if IsVolume or (Parent = nil) then
    Exit;
  if Parent.Path <> '' then
    Result := Parent;
end;

procedure TDiskNode.Recalculate;
var
  C: TDiskNode;
begin
  Size := 0;
  LogicalSize := 0;
  Files := 0;
  if not IsVolume then
  begin
    Capacity := 0;
    FreeSpace := 0
  end;
  if Children = nil then
    Exit;
  for C in Children do
  begin
    Inc(Size, C.Size);
    Inc(LogicalSize, C.LogicalSize);
    Inc(Files, C.Files);
    if not IsVolume then
    begin
      Inc(Capacity, C.Capacity);
      Inc(FreeSpace, C.FreeSpace)
    end;
  end;
end;

function TDiskNode.DisplayBytes: UInt64;
begin
  // The summary reports Windows capacity; a zoomed disk reports enumerated files.
  if (Path = '') and (Parent = nil) and (Capacity > 0) then
    Result := Capacity
  else
    Result := Size;
end;

procedure TDiskNode.ApplyVolumeSpace(Total, FreeBytes: UInt64);
begin
  if not IsVolume then
    Exit;
  Capacity := Total;
  FreeSpace := Min(Total, FreeBytes);
  if UsedArea = nil then
  begin
    UsedArea := TDiskNode.Create('', 'Used on ' + Path, Self, False);
    UsedArea.IsFolder := False;
    UsedArea.IsUsed := True;
    FreeArea := TDiskNode.Create('', 'Free on ' + Path, Self, False);
    FreeArea.IsFolder := False;
    FreeArea.IsFree := True;
  end;
  // Space indicators belong to the summary center, never to the file tree.
  UsedArea.Size := Capacity - FreeSpace;
  FreeArea.Size := FreeSpace;
  Recalculate;
  UsedArea.Files := Files;
end;

function LongPath(const Path: string): string;
begin
  if Path.StartsWith('\\?\') then
    Exit(Path);
  if Path.StartsWith('\\') then
    Result := '\\?\UNC\' + Copy(Path, 3, MaxInt)
  else
    Result := '\\?\' + ExpandFileName(Path);
end;

function DisplaySize(Value: UInt64): string;
begin
  Result := DisplaySize(Value, Value);
end;

function DisplaySize(Value, Reference: UInt64): string;
const
  Units: array[0..4] of string = ('Bytes', 'KByte', 'MByte', 'GByte', 'TByte');
var
  N, Scale: Double;
  I: Integer;
begin
  Scale := 1;
  I := 0;
  while (Reference / Scale >= 10000) and (I < High(Units)) do
  begin
    Scale := Scale * 1024;
    Inc(I)
  end;
  N := Value / Scale;
  if I = 0 then
    Result := UIntToStr(Value)
  else if N >= 100 then
    Result := FormatFloat('0', N)
  else if N >= 10 then
    Result := FormatFloat('0.0', N)
  else if N >= 1 then
    Result := FormatFloat('0.00', N)
  else
    Result := FormatFloat('0.000', N);
  Result := Result + ' ' + Units[I];
end;

function AvailableDrives: TArray<string>;
var
  Mask: DWORD;
  I: Integer;
  L: TList<string>;
begin
  L := TList<string>.Create;
  try
    Mask := GetLogicalDrives;
    for I := 0 to 25 do
      if (Mask and (DWORD(1) shl I)) <> 0 then
        L.Add(Char(Ord('A') + I) + ':\');
    Result := L.ToArray;
  finally
    L.Free
  end;
end;

constructor TScanThread.Create(const Paths: TArray<string>; const DeviceIDs: TArray<Integer>; const RefreshVolumes: TArray<string>; SourceRoot: TDiskNode);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FSourceRoot := SourceRoot;
  FCreatedNodes := TObjectList<TDiskNode>.Create(True);
  FChanges := TObjectList<TScanChange>.Create(True);
  FPaths := Copy(Paths);
  FDeviceIDs := Copy(DeviceIDs);
  FRefreshVolumes := Copy(RefreshVolumes);
  FCounting := False;
  FGroupProgress := -1;
  FLock := TCriticalSection.Create;
  FOwner := Self;
end;

constructor TScanThread.CreateSub(Owner: TScanThread; Node: TDiskNode; const Path, Name: string; Cluster: UInt64; Depth: Integer; Existing: Boolean);
begin
  Create(nil, nil, nil, Owner.FSourceRoot);
  FOwner := Owner;
  FSubNode := Node;
  FSubPath := Path;
  FSubName := Name;
  FSubCluster := Cluster;
  FSubDepth := Depth;
  FSubExisting := Existing;
end;

function TScanThread.Cancelled: Boolean;
begin
  Result := Terminated or FOwner.Terminated;
end;

const
  // Only folders this close to the scan root are handed to other threads, so
  // thread creation stays negligible next to the enumeration it parallelizes.
  ParallelDepth = 6;
  FIND_FIRST_EX_LARGE_FETCH = 2; // Missing from Winapi.Windows.

function ParallelSlots(const Path: string): Integer;
const
  IOCTL_STORAGE_QUERY_PROPERTY = $2D1400;
  StorageDeviceSeekPenaltyProperty = 7;
var
  Drive: string;
  H: THandle;
  Query: array[0..2] of DWORD;
  Penalty: record
    Version, Size: DWORD;
    IncursSeekPenalty: Boolean;
  end;
  Returned: DWORD;
begin
  Result := Max(0, TThread.ProcessorCount - 1);
  Drive := ExtractFileDrive(Path);
  if GetDriveType(PChar(IncludeTrailingPathDelimiter(Drive))) = DRIVE_REMOTE then
    Exit;
  // Parallel enumeration makes rotating disks seek; unknown devices stay sequential too.
  H := CreateFile(PChar('\\.\' + Drive), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
  if H = INVALID_HANDLE_VALUE then
    Exit(0);
  try
    Query[0] := StorageDeviceSeekPenaltyProperty;
    Query[1] := 0; // PropertyStandardQuery
    Query[2] := 0;
    if not DeviceIoControl(H, IOCTL_STORAGE_QUERY_PROPERTY, @Query, SizeOf(Query),
      @Penalty, SizeOf(Penalty), Returned, nil) or Penalty.IncursSeekPenalty then
      Result := 0;
  finally
    CloseHandle(H)
  end;
end;

destructor TScanThread.Destroy;
begin
  RequestCancel;
  if not FStartRequested then
    Start;
  WaitFor;
  FChanges.Free;
  FCreatedNodes.Free;
  FRoot.Free;
  FLock.Free;
  inherited;
end;

function TScanThread.Done: Boolean;
begin
  Result := (TInterlocked.CompareExchange(FDone, 0, 0) <> 0) or Finished;
end;

procedure TScanThread.Start;
begin
  // TThread.Started becomes true inside ThreadProc, after Start returns. Keep
  // our own launch state so immediate cancellation cannot resume it twice.
  if FStartRequested then
    Exit;
  FStartRequested := True;
  inherited Start;
end;

function TScanThread.TakeRoot: TDiskNode;
begin
  Result := nil;
  if FRoot = nil then
    Exit;
  if (FSourceRoot <> nil) and (Terminated or (FError <> '')) then
    Exit;
  if FSourceRoot <> nil then
    CommitChanges;
  Result := FRoot;
  FRoot := nil;
end;

procedure TScanThread.RequestCancel;
begin
  Terminate;
  CancelSynchronousIo(Handle);
end;

procedure TScanThread.Progress(out Current: string; out Visited: UInt64; out Skipped: Integer);
var
  Total: UInt64;
  Counting: Boolean;
begin
  Progress(Current, Visited, Skipped, Total, Counting)
end;

procedure TScanThread.Progress(out Current: string; out Visited: UInt64; out Skipped: Integer; out Total: UInt64; out Counting: Boolean);
begin
  FLock.Enter;
  try
    Current := FCurrent;
    Visited := FVisited;
    Skipped := FSkipped;
    Total := FTotalFiles;
    Counting := FCounting;
  finally
    FLock.Leave
  end;
end;

procedure TScanThread.ProgressBytes(out Processed, Expected: UInt64);
begin
  FLock.Enter;
  try
    Processed := FProcessedBytes;
    Expected := FExpectedBytes;
  finally
    FLock.Leave
  end;
end;

function TScanThread.ProgressPosition: Integer;
begin
  if Done then
    Exit(128);
  FLock.Enter;
  try
    if FGroupProgress >= 0 then
      Result := FGroupProgress
    else if FExpectedBytes = 0 then
      Result := 0
    else
      Result := Min(127, Trunc(128 * (FProcessedBytes / FExpectedBytes)));
  finally
    FLock.Leave
  end;
end;

procedure TScanThread.PrepareProgress;
var
  P: string;
  Available, Total, FreeBytes: Int64;
  Expected: UInt64;
begin
  Expected := 0;
  for P in FPaths do
  begin
    if Terminated then
      Exit;
    if SameText(IncludeTrailingPathDelimiter(P), ExtractFileDrive(P) + '\') and
      (GetDriveType(PChar(P)) <> DRIVE_REMOTE) then
      if GetDiskFreeSpaceEx(PChar(P), Available, Total, @FreeBytes) then
        Inc(Expected, UInt64(Max(Int64(0), Total - FreeBytes)));
  end;
  FLock.Enter;
  try
    FExpectedBytes := Expected;
  finally
    FLock.Leave
  end;
end;

procedure TNodeValues.Apply(Node: TDiskNode);
begin
  Node.Size := Size;
  Node.LogicalSize := LogicalSize;
  Node.Files := Files;
  Node.Capacity := Capacity;
  Node.FreeSpace := FreeSpace;
  Node.Unreadable := Unreadable;
  Node.Hidden := False;
  if Node.IsVolume then
    Node.ApplyVolumeSpace(Capacity, FreeSpace);
end;

function TNodeValues.Matches(Node: TDiskNode): Boolean;
begin
  Result := (Size = Node.Size) and (LogicalSize = Node.LogicalSize) and
    (Files = Node.Files) and (Capacity = Node.Capacity) and
    (FreeSpace = Node.FreeSpace) and (Unreadable = Node.Unreadable) and not Node.Hidden;
end;

destructor TScanChange.Destroy;
begin
  Children.Free; // Journal lists never own the borrowed or newly created nodes.
  inherited;
end;

function FindChild(Children: TObjectList<TDiskNode>; const Name: string): TDiskNode;
var
  L, R, M, Order, I: Integer;
begin
  Result := nil;
  if Children = nil then
    Exit;
  L := 0;
  R := Children.Count - 1;
  while L <= R do
  begin
    M := L + (R - L) div 2;
    Order := CompareText(Children[M].Name, Name);
    if Order = 0 then
    begin
      // Exact names also handle Windows directories with case sensitivity
      // enabled. A case-only rename is treated as removal plus addition.
      I := M;
      while (I >= 0) and (CompareText(Children[I].Name, Name) = 0) do
      begin
        if Children[I].Name = Name then
          Exit(Children[I]);
        Dec(I);
      end;
      I := M + 1;
      while (I < Children.Count) and (CompareText(Children[I].Name, Name) = 0) do
      begin
        if Children[I].Name = Name then
          Exit(Children[I]);
        Inc(I);
      end;
      Exit;
    end;
    if Order < 0 then
      L := M + 1
    else
      R := M - 1;
  end;
end;

function TScanThread.FindSource(const Path: string): TDiskNode;

  function Find(Node: TDiskNode): TDiskNode;
  var
    Child: TDiskNode;
    NodePath: string;
  begin
    Result := nil;
    if Node = nil then
      Exit;
    NodePath := Node.Path;
    if Node.IsFolder and SameText(ExcludeTrailingPathDelimiter(NodePath),
      ExcludeTrailingPathDelimiter(Path)) then
      Exit(Node);
    if not Node.IsFolder or ((NodePath <> '') and
      not Path.StartsWith(IncludeTrailingPathDelimiter(NodePath), True)) then
      Exit;
    for Child in Node.Children do
      if Child.IsFolder then
      begin
        Result := Find(Child);
        if Result <> nil then
          Exit
      end;
  end;

begin
  Result := Find(FSourceRoot);
end;

function TScanThread.NewNode(const Path, Name: string; Parent: TDiskNode; IsFolder: Boolean): TDiskNode;
begin
  Result := TDiskNode.Create(Path, Name, Parent, IsFolder);
  if FSourceRoot <> nil then
  begin
    if Result.Children <> nil then
      Result.Children.OwnsObjects := False;
    try
      FCreatedNodes.Add(Result);
    except
      Result.Free;
      raise
    end;
  end;
end;

procedure TScanThread.StageNode(Node: TDiskNode; const Name: string; const Values: TNodeValues; Children: TObjectList<TDiskNode>; Existing: Boolean);
var
  Change: TScanChange;
  I: Integer;
  SameChildren: Boolean;
begin
  if not Existing then
  begin
    Values.Apply(Node);
    Exit;
  end;
  if Children <> nil then
  begin
    SameChildren := Children.Count = Node.Children.Count;
    if SameChildren then
      for I := 0 to Children.Count - 1 do
        if Children[I] <> Node.Children[I] then
        begin
          SameChildren := False;
          Break
        end;
    if SameChildren then
      FreeAndNil(Children);
  end;
  if (Children = nil) and Values.Matches(Node) and (Name = Node.Name) then
    Exit;
  try
    Change := TScanChange.Create;
  except
    Children.Free;
    raise
  end;
  try
    Change.Children := Children;
    Change.Node := Node;
    Change.Name := Name;
    Change.Values := Values;
    FChanges.Add(Change);
  except
    Change.Free;
    raise
  end;
end;

procedure TScanThread.CommitChanges;
var
  Node, OldChild: TDiskNode;
  Change: TScanChange;
  OldChildren: TObjectList<TDiskNode>;
begin
  // Called on the UI thread after all readers have finished and UI references
  // have been converted to paths. Detach retained roots before retiring FSourceRoot.
  for Node in FRoot.Children do
    if Node.Parent <> FRoot then
    begin
      if Node.Parent <> nil then
        Node.Parent.Children.Extract(Node);
      Node.Parent := FRoot;
    end;
  for Change in FChanges do
  begin
    Node := Change.Node;
    if Change.Children <> nil then
    begin
      OldChildren := Node.Children;
      OldChildren.OwnsObjects := False;
      for OldChild in OldChildren do
        if FindChild(Change.Children, OldChild.Name) <> OldChild then
          OldChild.Free;
      Node.Children := Change.Children;
      Change.Children := nil;
      Node.Children.OwnsObjects := True;
      OldChildren.Free;
    end;
    if (Node.Name <> Change.Name) and (Node.Parent <> nil) and
      (Node.Parent.FPathPart <> '') then
      Node.FPathPart := Change.Name;
    Node.Name := Change.Name;
    Change.Values.Apply(Node);
  end;
  for Node in FCreatedNodes do
    if Node.Children <> nil then
      Node.Children.OwnsObjects := True;
  FCreatedNodes.OwnsObjects := False;
  FCreatedNodes.Clear;
  FRoot.Children.OwnsObjects := True;
  FChanges.Clear;
end;

procedure TScanThread.AdoptChanges(Worker: TScanThread);
begin
  FChanges.AddRange(Worker.FChanges);
  Worker.FChanges.OwnsObjects := False;
  Worker.FChanges.Clear;
  FCreatedNodes.AddRange(Worker.FCreatedNodes);
  Worker.FCreatedNodes.OwnsObjects := False;
  Worker.FCreatedNodes.Clear;
end;

procedure TScanThread.DiscardResult;
begin
  FChanges.Clear;
  FCreatedNodes.Clear;
  FreeAndNil(FRoot);
end;

function TScanThread.ScanDirectory(Node: TDiskNode; const DirectoryPath: string; Cluster: UInt64; Depth: Integer; Existing: Boolean): TNodeValues;
var
  Data: TWin32FindData;
  Search: THandle;
  Child: TDiskNode;
  ItemPath, ItemName, Prefix: string;
  N, Physical: UInt64;
  Hi, Lo: DWORD;
  List, PendingList: TObjectList<TDiskNode>;
  ChildValues: TNodeValues;
  ChildExists, IsFolder: Boolean;
  Subs: TObjectList<TScanThread>;
  Sub: TScanThread;
  Visited, Bytes: UInt64;

  function TakeSlot: Boolean;
  begin
    Result := TInterlocked.Decrement(FOwner.FFreeSlots) >= 0;
    if not Result then
      TInterlocked.Increment(FOwner.FFreeSlots);
  end;

begin
  Result := Default(TNodeValues);
  if Node.IsVolume then
  begin
    Result.Capacity := Node.Capacity;
    Result.FreeSpace := Node.FreeSpace
  end;
  if Cancelled then
    Exit;
  Subs := nil;
  List := Node.Children;
  if Existing then
    List := TObjectList<TDiskNode>.Create(False);
  try
    if Depth > 512 then
      Result.Unreadable := True
    else
    begin
      FOwner.FLock.Enter;
      try
        FOwner.FCurrent := DirectoryPath;
      finally
        FOwner.FLock.Leave
      end;
      Prefix := IncludeTrailingPathDelimiter(DirectoryPath);
      // Basic info skips 8.3 names; large fetch reads more entries per call.
      Search := FindFirstFileEx(PChar(IncludeTrailingPathDelimiter(LongPath(DirectoryPath)) + '*'),
        FindExInfoBasic, @Data, FindExSearchNameMatch, nil, FIND_FIRST_EX_LARGE_FETCH);
      if Search = INVALID_HANDLE_VALUE then
      begin
        Result.Unreadable := True;
        FOwner.FLock.Enter;
        try
          Inc(FOwner.FSkipped);
        finally
          FOwner.FLock.Leave
        end;
      end
      else
      try
        Visited := 0;
        Bytes := 0;
        repeat
          if Cancelled then
            Exit;
          ItemName := Data.cFileName;
          if (ItemName = '.') or (ItemName = '..') then
            Continue;
          IsFolder := (Data.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) <> 0;
          Child := nil;
          if Existing then
            Child := FindChild(Node.Children, ItemName);
          if (Child <> nil) and (Child.IsFolder <> IsFolder) then
            Child := nil;
          ChildExists := Child <> nil;
          // Only a recursion frame or compressed-file query needs a full path.
          if IsFolder or
            ((Data.dwFileAttributes and (FILE_ATTRIBUTE_COMPRESSED or FILE_ATTRIBUTE_SPARSE_FILE)) <> 0) then
            ItemPath := Prefix + ItemName;
          if not ChildExists then
            Child := NewNode(ItemName, ItemName, Node, IsFolder);
          try
            List.Add(Child);
          except
            if FSourceRoot = nil then
              Child.Free;
            raise;
          end;
          ChildValues := Default(TNodeValues);
          if IsFolder then
          begin
            // Never follow junctions or symbolic directory links.
            if (Data.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT) = 0 then
            begin
              if (Depth < ParallelDepth) and TakeSlot then
              begin
                // The subtree is joined, and its values added, after this listing ends.
                try
                  Sub := TScanThread.CreateSub(FOwner, Child, ItemPath, ItemName, Cluster, Depth + 1, ChildExists);
                except
                  TInterlocked.Increment(FOwner.FFreeSlots);
                  raise;
                end;
                if Subs = nil then
                  Subs := TObjectList<TScanThread>.Create(True);
                try
                  Subs.Add(Sub);
                except
                  Sub.Free; // Runs cancelled and returns the slot.
                  raise;
                end;
                Sub.Start;
                Continue;
              end;
              ChildValues := ScanDirectory(Child, ItemPath, Cluster, Depth + 1, ChildExists)
            end
            else
            begin
              PendingList := nil;
              if ChildExists then
                PendingList := TObjectList<TDiskNode>.Create(False);
              StageNode(Child, ItemName, ChildValues, PendingList, ChildExists);
            end;
            if ChildExists and (Child.Name <> ItemName) then
              StageNode(Child, ItemName, ChildValues, nil, True);
          end
          else
          begin
            N := (UInt64(Data.nFileSizeHigh) shl 32) or Data.nFileSizeLow;
            Physical := N;
            if (Data.dwFileAttributes and (FILE_ATTRIBUTE_COMPRESSED or FILE_ATTRIBUTE_SPARSE_FILE)) <> 0 then
            begin
              Hi := 0;
              SetLastError(NO_ERROR);
              Lo := GetCompressedFileSize(PChar(LongPath(ItemPath)), @Hi);
              if (Lo <> INVALID_FILE_SIZE) or (GetLastError = NO_ERROR) then
                Physical := (UInt64(Hi) shl 32) or Lo;
            end;
            if Physical > 0 then
              Physical := ((Physical + Cluster - 1) div Cluster) * Cluster;
            ChildValues.Size := Physical;
            ChildValues.LogicalSize := N;
            ChildValues.Files := 1;
            StageNode(Child, ItemName, ChildValues, nil, ChildExists);
            Inc(Visited);
            Inc(Bytes, Physical);
          end;
          Inc(Result.Size, ChildValues.Size);
          Inc(Result.LogicalSize, ChildValues.LogicalSize);
          Inc(Result.Files, ChildValues.Files);
        until not FindNextFile(Search, Data);
        // One lock per folder: several threads may report to the same owner.
        FOwner.FLock.Enter;
        try
          Inc(FOwner.FVisited, Visited);
          Inc(FOwner.FTotalFiles, Visited);
          Inc(FOwner.FProcessedBytes, Bytes);
        finally
          FOwner.FLock.Leave
        end;
      finally
        Winapi.Windows.FindClose(Search)
      end;
    end;
    if Subs <> nil then
      for Sub in Subs do
      begin
        while WaitForSingleObject(Sub.Handle, 20) = WAIT_TIMEOUT do
          if Cancelled then
            Sub.RequestCancel;
        if Cancelled then
          Exit;
        if Sub.FError <> '' then
          raise Exception.Create(Sub.FError);
        AdoptChanges(Sub);
        ChildValues := Sub.FSubValues;
        if Sub.FSubExisting and (Sub.FSubNode.Name <> Sub.FSubName) then
          StageNode(Sub.FSubNode, Sub.FSubName, ChildValues, nil, True);
        Inc(Result.Size, ChildValues.Size);
        Inc(Result.LogicalSize, ChildValues.LogicalSize);
        Inc(Result.Files, ChildValues.Files);
      end;
    List.Sort(TComparer<TDiskNode>.Construct(
      function(const L, R: TDiskNode): Integer
      begin
        Result := CompareText(L.Name, R.Name)
      end));
    if Existing then
    begin
      // Transfer the temporary list to the journal, or discard it if unchanged.
      PendingList := List;
      List := nil;
      StageNode(Node, Node.Name, Result, PendingList, True);
    end
    else
      StageNode(Node, Node.Name, Result, nil, False);
  finally
    Subs.Free; // Cancels and waits for sub-scans left behind by an early exit.
    if Existing then
      List.Free;
  end;
end;

function TScanThread.ScanVolume(Node: TDiskNode; Existing: Boolean): TNodeValues;
var
  Sectors, Bytes, FreeClusters, Clusters: DWORD;
  Available, Total, FreeBytes: Int64;
  Cluster: UInt64;
  P, Name: string;
  VolName: array[0..MAX_PATH] of Char;
begin
  P := Node.Path;
  if Existing then
    Name := Node.Name
  else
    Name := P;
  Cluster := 4096;
  if GetDiskFreeSpace(PChar(ExtractFileDrive(P) + '\'), Sectors, Bytes, FreeClusters, Clusters) then
    Cluster := UInt64(Sectors) * Bytes;
  if Cluster = 0 then
    Cluster := 4096;
  if not Existing then
    Node.IsVolume := SameText(IncludeTrailingPathDelimiter(P), ExtractFileDrive(P) + '\');
  if Node.IsVolume then
    if GetVolumeInformation(PChar(P), VolName, Length(VolName), nil, Sectors, Bytes, nil, 0) then
      if VolName[0] <> #0 then
        Name := P + '  ' + string(VolName);
  FFreeSlots := ParallelSlots(P);
  Result := ScanDirectory(Node, P, Cluster, 0, Existing);
  if Terminated then
    Exit;
  if Node.IsVolume and (GetDriveType(PChar(P)) <> DRIVE_REMOTE) then
  begin
    Available := 0;
    Total := 0;
    FreeBytes := 0;
    if GetDiskFreeSpaceEx(PChar(P), Available, Total, @FreeBytes) then
    begin
      Result.Capacity := Total;
      Result.FreeSpace := FreeBytes
    end;
  end;
  StageNode(Node, Name, Result, nil, Existing);
  if not Existing then
    Node.Name := Name;
end;

procedure TScanThread.ScanGroups;
var
  Groups: TObjectDictionary<Integer, TList<string>>;
  Workers: TObjectList<TScanThread>;
  Entry: TPair<Integer, TList<string>>;
  Worker: TScanThread;
  List: TList<string>;
  I, Skipped, SkippedTotal: Integer;
  Position: Integer;
  P, Current: string;
  Count, Total, Expected, ExpectedTotal, ProcessedBytes, ExpectedBytes, ProcessedSum, ExpectedSum: UInt64;
  AllDone, Counting, AnyCounting: Boolean;
  Nodes: TObjectDictionary<string, TDiskNode>;
  Child, GroupRoot: TDiskNode;
begin
  Groups := TObjectDictionary<Integer, TList<string>>.Create([doOwnsValues]);
  Workers := TObjectList<TScanThread>.Create(True);
  if FSourceRoot = nil then
    Nodes := TObjectDictionary<string, TDiskNode>.Create([doOwnsValues])
  else
    Nodes := TObjectDictionary<string, TDiskNode>.Create;
  try
    for I := 0 to High(FPaths) do
    begin
      if not Groups.TryGetValue(FDeviceIDs[I], List) then
      begin
        List := TList<string>.Create;
        Groups.Add(FDeviceIDs[I], List)
      end;
      List.Add(FPaths[I]);
    end;
    for Entry in Groups do
    begin
      Worker := TScanThread.Create(Entry.Value.ToArray, nil, nil, FSourceRoot);
      Workers.Add(Worker);
      Worker.Start;
    end;
    repeat
      AllDone := True;
      Total := 0;
      ExpectedTotal := 0;
      ProcessedSum := 0;
      ExpectedSum := 0;
      Position := 128;
      AnyCounting := False;
      SkippedTotal := 0;
      Current := '';
      for Worker in Workers do
      begin
        if Terminated then
          Worker.RequestCancel;
        if not Worker.Done then
          AllDone := False;
        Worker.Progress(P, Count, Skipped, Expected, Counting);
        Worker.ProgressBytes(ProcessedBytes, ExpectedBytes);
        Position := Min(Position, Worker.ProgressPosition);
        Inc(ProcessedSum, ProcessedBytes);
        Inc(ExpectedSum, ExpectedBytes);
        Inc(ExpectedTotal, Expected);
        AnyCounting := AnyCounting or Counting;
        Inc(Total, Count);
        Inc(SkippedTotal, Skipped);
        if (Current = '') and not Worker.Done then
          Current := P;
      end;
      FLock.Enter;
      try
        FCurrent := Current;
        FVisited := Total;
        FSkipped := SkippedTotal;
        FTotalFiles := ExpectedTotal;
        FCounting := AnyCounting;
        FProcessedBytes := ProcessedSum;
        FExpectedBytes := ExpectedSum;
        FGroupProgress := Position;
      finally
        FLock.Leave
      end;
      if not AllDone then
        TThread.Sleep(10);
    until AllDone;
    if Terminated then
      Exit;
    for Worker in Workers do
    begin
      Worker.WaitFor;
      if Worker.Error <> '' then
        FError := Worker.Error;
      // Do not publish child journals from a background coordinator.
      GroupRoot := Worker.FRoot;
      Worker.FRoot := nil;
      AdoptChanges(Worker);
      if GroupRoot = nil then
        Continue;
      try
        Inc(FRoot.Size, GroupRoot.Size);
        Inc(FRoot.Files, GroupRoot.Files);
        Inc(FRoot.LogicalSize, GroupRoot.LogicalSize);
        Inc(FRoot.Capacity, GroupRoot.Capacity);
        Inc(FRoot.FreeSpace, GroupRoot.FreeSpace);
        while GroupRoot.Children.Count > 0 do
        begin
          Child := GroupRoot.Children.Extract(GroupRoot.Children[0]);
          Nodes.Add(Child.Path, Child);
          if Child.Parent = GroupRoot then
            Child.Parent := FRoot;
        end;
      finally
        GroupRoot.Free
      end;
    end;
    // Restore drive order independently of worker completion order.
    for P in FPaths do
      if Nodes.TryGetValue(P, Child) then
      begin
        Nodes.ExtractPair(P);
        if FSourceRoot = nil then
          Child.Parent := FRoot;
        FRoot.Children.Add(Child);
      end;
  finally
    for Worker in Workers do
      Worker.RequestCancel;
    Workers.Free;
    Nodes.Free;
    Groups.Free;
  end;
end;

procedure TScanThread.Execute;
var
  P: string;
  N: TDiskNode;
  Space: TVolumeSpace;
  Available, Total, FreeBytes: Int64;
  Values: TNodeValues;
  Existing: Boolean;
begin
  try
    try
      if Terminated then
        Exit;
      if FOwner <> Self then
      begin
        FSubValues := ScanDirectory(FSubNode, FSubPath, FSubCluster, FSubDepth, FSubExisting);
        Exit;
      end;
      FRoot := TDiskNode.Create('', 'Summary');
      if FSourceRoot <> nil then
        FRoot.Children.OwnsObjects := False;
      if (Length(FDeviceIDs) = Length(FPaths)) and (Length(FPaths) > 1) then
      begin
        ScanGroups;
        Exit
      end;
      PrepareProgress;
      if Terminated then
        Exit;
      for P in FPaths do
      begin
        if Terminated then
          Break;
        N := FindSource(P);
        Existing := N <> nil;
        if not Existing then
          N := NewNode(P, P, FRoot, True);
        try
          FRoot.Children.Add(N);
        except
          if (FSourceRoot = nil) and not Existing then
            N.Free;
          raise;
        end;
        Values := ScanVolume(N, Existing);
        Inc(FRoot.Size, Values.Size);
        Inc(FRoot.Files, Values.Files);
        Inc(FRoot.LogicalSize, Values.LogicalSize);
        Inc(FRoot.Capacity, Values.Capacity);
        Inc(FRoot.FreeSpace, Values.FreeSpace);
      end;
      if not Terminated then
        for P in FRefreshVolumes do
        begin
          Available := 0;
          Total := 0;
          FreeBytes := 0;
          if GetDiskFreeSpaceEx(PChar(P), Available, Total, @FreeBytes) then
          begin
            Space.Path := P;
            Space.Capacity := Total;
            Space.FreeSpace := FreeBytes;
            FVolumeSpaces := FVolumeSpaces + [Space];
          end;
        end;
    except
      on E: Exception do
        FError := E.Message
    end;
  finally
    // Clean cancelled partial trees on the worker, rather than blocking the UI
    // timer while its retired-worker list is being reaped.
    if Terminated or ((FSourceRoot <> nil) and (FError <> '')) then
      DiscardResult;
    if FOwner <> Self then
      TInterlocked.Increment(FOwner.FFreeSlots);
    TInterlocked.Exchange(FDone, 1);
  end;
end;

end.

