[Setup]
AppName=Русификатор DELTARUNE
AppVersion=1.2.2
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

[Messages]
ExitSetupMessage=Установка не завершена. Если вы выйдете, русификатор не будет установлен.%n%nВы сможете завершить установку, запустив программу установки позже.%n%nВыйти из программы установки?

[Files]
Source: "DeltarunePatcherCLI.7z"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Code]
const
  LangURL = 'https://github.com/Lazy-Desman/DeltaruneRus/releases/download/latest/lang.7z';
  LangURLMirror = 'https://filldor.ru/deltaRU/lang.7z';
  ScriptsURL = 'https://github.com/Lazy-Desman/DeltaruneRus/releases/download/latest/scripts.7z';
  ScriptsURLMirror = 'https://filldor.ru/deltaRU/scripts.7z';
var
  InfoPage: TOutputMsgWizardPage;
  GamePathPage: TInputDirWizardPage;
  ProgressPage: TOutputProgressWizardPage;
  
  FinishedText: String;
  ForceClose: Boolean;
  ExistingDrives: TArrayOfString;

procedure CloseInstaller;
begin
  ForceClose := True;
  WizardForm.Close;
end;

procedure CancelButtonClick(CurPageID: Integer; var Cancel, Confirm: Boolean);
begin
  Confirm := not ForceClose;
end;

procedure InitExistingDrives;
var
  DriveLetter: Char;
  i, DriveCount: Integer;
begin
  for i := Ord('C') to Ord('Z') do
  begin
    DriveLetter := Chr(i);
    if DirExists(DriveLetter + ':\') then
    begin
      DriveCount := GetArrayLength(ExistingDrives);
      SetArrayLength(ExistingDrives, DriveCount + 1);
      ExistingDrives[DriveCount] := DriveLetter + ':';
    end;
  end;
end;

// Поиск DELTARUNE.exe
function FindGameExe(): String;
var
  GameExeLocations: array[0..3] of String;
  DrivePrefix, Location, FullPath: String;
  i, j: Integer;
begin
  GameExeLocations[0] := '\Program Files (x86)\Steam\steamapps\common\DELTARUNE\DELTARUNE.exe';
  GameExeLocations[1] := '\Program Files (x86)\DELTARUNE\DELTARUNE.exe';
  GameExeLocations[2] := '\DELTARUNE\DELTARUNE.exe';
  GameExeLocations[3] := '\Program Files\DELTARUNE\DELTARUNE.exe';

  // Steam Deck
  Result := 'Z:\home\deck\.local\share\Steam\steamapps\common\DELTARUNE\DELTARUNE.exe';
  if (FileExists(Result)) then
  begin
    Exit;
  end
  else
  begin
    Result := ExpandConstant('Z:\home\{username}\.local\share\Steam\steamapps\common\DELTARUNE\DELTARUNE.exe');
    if (FileExists(Result)) then
      Exit;
  end;
  
  Result := '';
  
  // Windows ПК
  for i := 0 to High(ExistingDrives) do
  begin
    DrivePrefix := ExistingDrives[i];
    
    for j := 0 to High(GameExeLocations) do
    begin
      FullPath := DrivePrefix + GameExeLocations[j];
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
    'Выберите папку, содержащую "DELTARUNE.exe" и папки "chapter1_windows" ... "chapter4_windows".'#13#10 +
    'Обычно это выглядит так: "C:\Program Files (x86)\Steam\steamapps\common\DELTARUNE"',
    False, ''
  );
  GamePathPage.Add('');
  GamePathPage.Values[0] := ExpandConstant('{sd}\Program Files (x86)\Steam\steamapps\common\DELTARUNE');
  
  FinishedText := 'Русификатор DELTARUNE успешно установлен на ваш компьютер.' + #13#10 +
                  + #13#10 +
                  'Нажмите «Завершить», чтобы выйти из программы установки.';

  ProgressPage := CreateOutputProgressPage('Выполнение установки', 'Пожалуйста, подождите...');
  
  InitExistingDrives;
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
      MsgBox('"DELTARUNE.exe" не найден в стандартных папках. Пожалуйста, укажите путь вручную.', mbInformation, MB_OK);
  end
  else if CurPageID = GamePathPage.ID then
  begin
    if not FileExists(AddBackslash(GamePathPage.Values[0]) + 'DELTARUNE.exe') then
    begin
      MsgBox('Не найден "DELTARUNE.exe" в указанной папке!', mbError, MB_OK);
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

function HandlePatcherError(GamePath: String): Boolean;
var
  LogPath, FirstLogLine: String;
  LogText: AnsiString;
  LineEndPos: Integer;
begin
  if GamePath[Length(GamePath)] = '\' then
    LogPath := GamePath + 'deltapatcher-log.txt'
  else
    LogPath := GamePath + '\deltapatcher-log.txt';
  
  if FileExists(LogPath) then
  begin
    if LoadStringFromFile(LogPath, LogText) then
    begin
      LineEndPos := Pos(#13#10, LogText);
      if (LineEndPos > 0) and (LineEndPos < 512) then
      begin
        FirstLogLine := Copy(LogText, 1, LineEndPos - 1);
        
        MsgBox('Ошибка применения патча: ' + FirstLogLine + #13#10 +
               'Лог установщика сохранён в файл "' + LogPath + '".', mbError, MB_OK);
        Result := True;
        Exit;
      end;
    end;
  end;
  
  Result := False;
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
    Exit;
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
        if not HandlePatcherError(GamePath) then
          MsgBox('Ошибка применения патча, код ошибки: ' + IntToStr(ResultCode) + '.', mbError, MB_OK);
        
        Result := False;
        Exit;
      end;
    end
    else
    begin
      MsgBox('Не удалось запустить патчер.', mbError, MB_OK);
      Result := False;
      Exit;
    end;
  except
    MsgBox('В процессе установки произошла ошибка: ' + GetExceptionMessage(), mbError, MB_OK);
    Result := False;
    Exit;
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
