unit Scanner.Dialog;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, FMX.Types,
  FMX.Controls, FMX.Forms, FMX.Layouts, FMX.Objects, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Graphics;

type
  TScannerDialogKind = (sdkInformation, sdkError, sdkConfirmation);

  TFormDialog = class(TForm)
    RectangleBackground: TRectangle;
    LayoutContent: TLayout;
    LayoutHeader: TLayout;
    LayoutIcon: TLayout;
    PathDialogIcon: TPath;
    LabelHeading: TLabel;
    LayoutFooter: TLayout;
    LayoutButtons: TLayout;
    ButtonAccept: TButton;
    ButtonReject: TButton;
    VertScrollBoxMessage: TVertScrollBox;
    TextMessage: TText;
    LayoutIconTemplates: TLayout;
    PathInformationTemplate: TPath;
    PathErrorTemplate: TPath;
  private
    function ThemeColor(const Role: string; Fallback: TAlphaColor): TAlphaColor;
    procedure ApplyNativeTheme;
  protected
    procedure CreateHandle; override;
    procedure DoShow; override;
  public
    procedure Configure(ParentForm: TCommonCustomForm; const Title, MessageText: string; Kind: TScannerDialogKind);
  end;

function ShowScannerDialog(ParentForm: TCommonCustomForm; const Title, MessageText: string; Kind: TScannerDialogKind = sdkInformation): TModalResult;

procedure ShowScannerException(ParentForm: TCommonCustomForm; E: Exception);

implementation

uses
  System.Math, Winapi.Windows, Winapi.Dwmapi, FMX.Platform.Win, FMX.TextLayout,
  Scanner.Localization;

{$R *.fmx}

function TFormDialog.ThemeColor(const Role: string; Fallback: TAlphaColor): TAlphaColor;
var
  Resource: TFmxObject;
begin
  Result := Fallback;
  if StyleBook = nil then
    Exit;
  Resource := StyleBook.Style.FindStyleResource('color.' + Role);
  if Resource is TColorObject then
    Result := TColorObject(Resource).Color;
end;

procedure TFormDialog.ApplyNativeTheme;
var
  DarkCaption: BOOL;
  Native: COLORREF;
  Window: HWND;

  function RGBColor(Value: TAlphaColor): COLORREF;
  var
    Components: TAlphaColorRec;
  begin
    Components := TAlphaColorRec(Value);
    Result := RGB(Components.R, Components.G, Components.B);
  end;

begin
  if (csDesigning in ComponentState) or not IsHandleAllocated then
    Exit;
  Window := FormToHWND(Self);
  DarkCaption := TAlphaColorRec(ThemeColor('surface', $FF1B1F26)).R < 128;
  DwmSetWindowAttribute(Window, DWMWA_USE_IMMERSIVE_DARK_MODE, @DarkCaption, SizeOf(DarkCaption));
  Native := RGBColor(ThemeColor('sidebar', $FF171B22));
  DwmSetWindowAttribute(Window, DWMWA_CAPTION_COLOR, @Native, SizeOf(Native));
  Native := RGBColor(ThemeColor('text', $FFEDF1F7));
  DwmSetWindowAttribute(Window, DWMWA_TEXT_COLOR, @Native, SizeOf(Native));
  Native := RGBColor(ThemeColor('border', $FF343C48));
  DwmSetWindowAttribute(Window, DWMWA_BORDER_COLOR, @Native, SizeOf(Native));
  RedrawWindow(Window, nil, 0, RDW_FRAME or RDW_INVALIDATE);
end;

procedure TFormDialog.CreateHandle;
begin
  inherited;
  // Modal presentation can replace the HWND created during Configure.
  ApplyNativeTheme;
end;

procedure TFormDialog.DoShow;
begin
  inherited;
  ApplyNativeTheme;
end;

procedure TFormDialog.Configure(ParentForm: TCommonCustomForm; const Title, MessageText: string; Kind: TScannerDialogKind);
var
  TextLayout: TTextLayout;
  DarkCaption: BOOL;
begin
  if ParentForm <> nil then
    StyleBook := ParentForm.StyleBook;
  Caption := Title;
  PreserveUserText(LabelHeading);
  LabelHeading.Text := Title;
  TextMessage.Text := MessageText;
  VertScrollBoxMessage.AniCalculations.Animation := True;
  LabelHeading.TextSettings.FontColor := ThemeColor('text', $FFEDF1F7);
  TextMessage.TextSettings.FontColor := ThemeColor('text', $FFEDF1F7);
  RectangleBackground.Fill.Color := ThemeColor('surface', $FF1B1F26);
  Fill.Color := RectangleBackground.Fill.Color;
  PathDialogIcon.Data.Assign(PathInformationTemplate.Data);
  PathDialogIcon.Fill.Color := ThemeColor('accent', $FF329AFF);
  DarkCaption := TAlphaColorRec(RectangleBackground.Fill.Color).R < 128;
  if Kind = sdkError then
  begin
    PathDialogIcon.Data.Assign(PathErrorTemplate.Data);
    if DarkCaption then
      PathDialogIcon.Fill.Color := $FFFF8585
    else
      PathDialogIcon.Fill.Color := $FFC94242;
  end;
  ButtonReject.Visible := Kind = sdkConfirmation;
  ButtonAccept.Text := Translate('OK');
  ButtonAccept.ModalResult := mrOk;
  ButtonAccept.Default := True;
  ButtonAccept.Cancel := True;
  if Kind = sdkConfirmation then
  begin
    ButtonAccept.Text := Translate('Yes');
    ButtonAccept.ModalResult := mrYes;
    ButtonAccept.Default := False;
    ButtonAccept.Cancel := False;
    ButtonReject.Text := Translate('No');
    ButtonReject.ModalResult := mrNo;
    ButtonReject.Default := True;
    ButtonReject.Cancel := True;
  end;
  TextLayout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    TextLayout.BeginUpdate;
    try
      TextLayout.Font.Assign(TextMessage.TextSettings.Font);
      TextLayout.WordWrap := True;
      TextLayout.MaxSize := PointF(ClientWidth - LayoutContent.Padding.Left - LayoutContent.Padding.Right - 16, MaxSingle);
      TextLayout.Text := MessageText;
    finally
      TextLayout.EndUpdate
    end;
    TextMessage.Height := Max(24, Ceil(TextLayout.TextHeight) + 6);
  finally
    TextLayout.Free
  end;
  ClientHeight := Round(LayoutContent.Padding.Top + LayoutContent.Padding.Bottom + LayoutHeader.Height +
    LayoutFooter.Height + Min(340, Max(60, TextMessage.Height)));
  ApplyNativeTheme;
end;

function ShowScannerDialog(ParentForm: TCommonCustomForm; const Title, MessageText: string; Kind: TScannerDialogKind): TModalResult;
begin
  var Dialog := TFormDialog.Create(ParentForm);
  try
    Dialog.Configure(ParentForm, Title, MessageText, Kind);
    Result := Dialog.ShowModal;
  finally
    Dialog.Free;
  end;
end;

var
  ShowingException: Boolean;

procedure ShowScannerException(ParentForm: TCommonCustomForm; E: Exception);
begin
  if (E is EAbort) or ShowingException then
    Exit;
  ShowingException := True;
  try
    ShowScannerDialog(ParentForm, Translate('Unexpected error'), E.ClassName + sLineBreak + E.Message, sdkError);
  finally
    ShowingException := False
  end;
end;

end.

