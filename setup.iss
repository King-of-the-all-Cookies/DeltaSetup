[Setup]
AppName=Русификатор DELTARUNE
AppVersion=1.1.1
AppPublisher=LazyDesman
DefaultDirName={autopf}\DELTARUNE Russian Patch
OutputBaseFilename=DeltaruneRussianPatcherSetup
Compression=lzma2/ultra64
SolidCompression=yes
SetupIconFile=icon.ico
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
DisableDirPage=yes
DisableWelcomePage=no
WizardSmallImageFile=logo.bmp
WizardImageFile=banner.bmp

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Files]
Source: "DeltarunePatcherCLI.7z"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Code]
const
  LangURL = 'https://github.com/Lazy-Desman/DeltaruneRus/raw/refs/heads/main/scripts.7z';
  LangURLMirror = 'https://filldor.ru/deltaRU/lang.7z';
  ScriptsURL = 'https://github.com/Lazy-Desman/DeltaruneRus/raw/refs/heads/main/scripts.7z';
  ScriptsURLMirror = 'https://filldor.ru/deltaRU/scripts.7z';
var
  InfoPage: TOutputMsgWizardPage;
  GamePathPage: TInputDirWizardPage;
  ProgressPage: TOutputProgressWizardPage;
  FinishedText: String;
  ForceClose: Boolean;

procedure CloseInstaller;
begin
  ForceClose := True;
  WizardForm.Close;
end;

procedure CancelButtonClick(CurPageID: Integer; var Cancel, Confirm: Boolean);
begin
  Confirm := not ForceClose;
end;

// Поиск DELTARUNE.exe
function FindGameExe(): String;
var
  i, j: Integer;
  Drive, FullPath: String;
  Paths: array[0..3] of String;
begin
  Paths[0] := '\Program Files (x86)\Steam\steamapps\common\DELTARUNE\DELTARUNE.exe';
  Paths[1] := '\Program Files (x86)\DELTARUNE\DELTARUNE.exe';
  Paths[2] := '\DELTARUNE\DELTARUNE.exe';
  Paths[3] := '\Program Files\DELTARUNE\DELTARUNE.exe';
  Result := '';
  for i := Ord('C') to Ord('Z') do
  begin
    Drive := Chr(i) + ':';
    for j := 0 to High(Paths) do
    begin
      FullPath := Drive + Paths[j];
      if FileExists(FullPath) then
      begin
        Result := FullPath;
        Exit;
      end;
    end;
  end;
end;

procedure InitializeWizard;
begin
  WizardForm.WelcomeLabel1.Caption := 'Добро пожаловать в мастер установки русификатора DELTARUNE';
  WizardForm.WelcomeLabel2.Caption := 'Этот мастер установит русификатор для игры DELTARUNE, подготовленный командой LazyDesman.';

  InfoPage := CreateOutputMsgPage(
    wpWelcome,
    'Описание установки',
    'Что будет установлено?',
    'Установка русификатора включает в себя:' + #13#10 +
    ' - Установка DelTranslate' + #13#10 +
    ' - Полный перевод Главы 1' + #13#10 +
    ' - Полный перевод Главы 2' + #13#10 +
    ' - Полный перевод Главы 3' + #13#10#13#10 +
    'Перевод будет применён поверх вашей текущей установки игры.' + #13#10 +
    'Все оригинальные файлы игры останутся нетронутыми.'
  );

  GamePathPage := CreateInputDirPage(
    InfoPage.ID,
    'Выберите папку DELTARUNE',
    'Где установлена игра?',
    'Выберите папку, содержащую DELTARUNE.exe и папки chapter1_windows, chapter2_windows и т.д.'#13#10 +
    'Обычно это выглядит так: "C:\Program Files (x86)\Steam\steamapps\common\DELTARUNE"',
    False, ''
  );
  GamePathPage.Add('');
  GamePathPage.Values[0] := 'C:\Program Files (x86)\Steam\steamapps\common\DELTARUNE';
  
  FinishedText := 'Русификатор DELTARUNE успешно установлен на ваш компьютер.' + #13#10 +
                  + #13#10 +
                  'Нажмите «Завершить», чтобы выйти из программы установки.';

  ProgressPage := CreateOutputProgressPage('Выполнение установки', 'Пожалуйста, подождите...');
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  FoundExe: String;
begin
  Result := True;
  if CurPageID = InfoPage.ID then
  begin
    FoundExe := FindGameExe();
    if FoundExe <> '' then
      GamePathPage.Values[0] := ExtractFilePath(FoundExe)
    else
      MsgBox('DELTARUNE.exe не найден в стандартных папках. Пожалуйста, укажите путь вручную.', mbInformation, MB_OK);
  end
  else if CurPageID = GamePathPage.ID then
  begin
    if not FileExists(AddBackslash(GamePathPage.Values[0]) + 'DELTARUNE.exe') then
    begin
      MsgBox('Не найден DELTARUNE.exe в указанной папке!', mbError, MB_OK);
      Result := False;
    end;
  end;
end;

function OnProgress(const ObjectName, FileName: String; const Progress, ProgressMax: Int64): Boolean;
begin
  ProgressPage.SetProgress(Progress, ProgressMax);
  Result := True;
end;

procedure DownloadToTempWithMirror(const TextHeader, MainURL, MirrorURL, FileName: String);
var
  FileSizeBytes: Integer;
  FileSizeStr: String;
  DownloadCallback: TOnDownloadProgress;
begin
  ProgressPage.SetText(TextHeader, '');
  
  try
    FileSizeBytes := DownloadTemporaryFileSize(MainURL);
  except
    FileSizeBytes := DownloadTemporaryFileSize(MirrorURL);
  end;
  
  if FileSizeBytes > 0 then
  begin
    DownloadCallback := @OnProgress;
    FileSizeStr := Format('%.2d', [FileSizeBytes / 1024 / 1024]) + ' МБ';
    ProgressPage.SetText(TextHeader, 'Размер файла: ' + FileSizeStr);
  end
  else
    DownloadCallback := nil;
  
  try
    DownloadTemporaryFile(MainURL, FileName, '', DownloadCallback);
  except
    DownloadTemporaryFile(MirrorURL, FileName, '', DownloadCallback);
  end;
end;

function DownloadAndExtractFiles(): Boolean;
var
  LangZipPath, ScriptsZipPath, PatcherZipPath, GamePath, PatcherPath: String;
  ResultCode: Integer;
begin
  LangZipPath := ExpandConstant('{tmp}\lang.7z');
  ScriptsZipPath := ExpandConstant('{tmp}\scripts.7z');
  PatcherZipPath := ExpandConstant('{tmp}\DeltarunePatcherCLI.7z');
  GamePath := GamePathPage.Values[0];

  ProgressPage.Show;
  try
    DownloadToTempWithMirror('Загрузка языковых файлов...', LangURL, LangURLMirror, 'lang.7z');
    DownloadToTempWithMirror('Загрузка скриптов...', ScriptsURL, ScriptsURLMirror, 'scripts.7z');
  except
    MsgBox('В процессе скачивания файлов произошла ошибка: ' + GetExceptionMessage(), mbError, MB_OK);
    Result := False;
    exit;
  end;
  
  try
    ProgressPage.SetText('Распаковка патчера...', '');
    Extract7ZipArchive(PatcherZipPath, ExpandConstant('{tmp}'), True, @OnProgress);

    ProgressPage.SetText('Распаковка языковых файлов...', '');
    Extract7ZipArchive(LangZipPath, GamePath, True, @OnProgress);

    ProgressPage.SetText('Распаковка скриптов...', '');
    Extract7ZipArchive(ScriptsZipPath, ExpandConstant('{tmp}\scripts'), True, @OnProgress);
    
    ProgressPage.SetText('Применение патча...', '');
    PatcherPath := ExpandConstant('{tmp}\DeltaPatcherCLI.exe');
    if Exec(PatcherPath, Format('--game "%s" --scripts "%s"', [GamePath, ExpandConstant('{tmp}\scripts')]), '', SW_SHOW, ewWaitUntilTerminated, ResultCode) then
    begin
      if ResultCode <> 0 then
      begin
        MsgBox('Ошибка применения патча: ' + IntToStr(ResultCode), mbError, MB_OK);
        Result := False;
        exit;
      end;
    end
    else
    begin
      MsgBox('Не удалось запустить патчер.', mbError, MB_OK);
      Result := False;
      exit;
    end;
  except
    MsgBox('В процессе установки произошла ошибка: ' + GetExceptionMessage(), mbError, MB_OK);
    Result := False;
    exit;
  finally
    ProgressPage.Hide;
  end;
  
  Result := True;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    if not DownloadAndExtractFiles() then
    begin
      FinishedText := 'Не удалось установить русификатор DELTARUNE из-за ошибки.' + #13#10 +
                      + #13#10 +
                      'Нажмите «Завершить», чтобы выйти из программы установки.';
    end;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
  begin
    WizardForm.FinishedHeadingLabel.Caption := 'Завершение установки русификатора DELTARUNE';
    WizardForm.FinishedLabel.Caption := FinishedText;
  end;
end;
