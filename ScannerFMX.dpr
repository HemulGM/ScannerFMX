program ScannerFMX;

uses
  System.StartUpCopy, System.SysUtils,
  FMX.Forms,
  Scanner.Main in 'Scanner.Main.pas' {FormMain},
  Scanner.Model in 'Scanner.Model.pas',
  Scanner.ViewModel in 'Scanner.ViewModel.pas',
  Scanner.Chart in 'Scanner.Chart.pas',
  Scanner.Chart.Sunburst in 'Scanner.Chart.Sunburst.pas',
  Scanner.Chart.Rectangles in 'Scanner.Chart.Rectangles.pas',
  Scanner.Chart.Treemap in 'Scanner.Chart.Treemap.pas',
  Scanner.Chart.Icicle in 'Scanner.Chart.Icicle.pas',
  Scanner.DriveButton in 'Scanner.DriveButton.pas' {FrameDriveButton: TFrame},
  Scanner.FolderItem in 'Scanner.FolderItem.pas' {FrameFolderItem: TFrame},
  Scanner.Localization in 'Scanner.Localization.pas',
  Scanner.Dialog in 'Scanner.Dialog.pas' {FormDialog};

{$R *.res}

begin
  try
    Application.Initialize;
    Application.CreateForm(TFormMain, FormMain);
    Application.Run;
  except
    on E: Exception do
      ShowScannerException(Application.MainForm, E);
  end;
end.
