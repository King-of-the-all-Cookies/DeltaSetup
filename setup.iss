[Setup]
AppName=Русификатор DELTARUNE
AppVersion=1.4.0
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
// SetupLogging=True

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
  
  DeltaruneExe = 'DELTARUNE.exe';
var
  InfoPage: TOutputMsgWizardPage;
  GamePathPage: TInputDirWizardPage;
  ProgressPage: TOutputProgressWizardPage;
  
  FinishedText: String;
  ForceClose: Boolean;
  ExistingDrives: TArrayOfString;

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

// Находится ли в папке полная версия DELTARUNE
function CheckDeltaruneLoc(DirPath: String): Boolean;
begin
  Result := FileExists(DirPath + DeltaruneExe);
  if Result then
    Result := FileExists(AddBackslash(DirPath) + 'chapter4_windows\data.win');
end;

// Поиск папки DELTARUNE
function FindGameLocation(): String;
var
  GameLocations: array[0..3] of String;
  DrivePrefix, Location: String;
  i, j: Integer;
begin
  GameLocations[0] := '\Program Files (x86)\Steam\steamapps\common\DELTARUNE\';
  GameLocations[1] := '\Program Files (x86)\DELTARUNE\';
  GameLocations[2] := '\DELTARUNE\';
  GameLocations[3] := '\Program Files\DELTARUNE\';

  // Steam Deck
  Result := 'Z:\home\deck\.local\share\Steam\steamapps\common\DELTARUNE\';
  if CheckDeltaruneLoc(Result) then
  begin
    Exit;
  end
  else
  begin
    Result := ExpandConstant('Z:\home\{username}\.local\share\Steam\steamapps\common\DELTARUNE\');
    if CheckDeltaruneLoc(Result) then
      Exit;
  end;
  
  Result := '';
  
  // Windows ПК
  for i := 0 to High(ExistingDrives) do
  begin
    DrivePrefix := ExistingDrives[i];
    
    for j := 0 to High(GameLocations) do
    begin
      Location := DrivePrefix + GameLocations[j];
      if CheckDeltaruneLoc(Location) then
      begin
        Result := Location;
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
  FoundGameLoc: String;
begin
  Result := True;
  
  if CurPageID = InfoPage.ID then
  begin
    FoundGameLoc := FindGameLocation();
    if FoundGameLoc = '' then
    begin
      MsgBox('DELTARUNE (главы 1-4) не найден в стандартных папках. Пожалуйста, укажите путь вручную.', mbInformation, MB_OK);
      Exit;
    end;
  end
  else if CurPageID = GamePathPage.ID then
  begin
    if not FileExists(AddBackslash(GamePathPage.Values[0]) + DeltaruneExe) then
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
        
        MsgBox('Ошибка применения патча: ' + FirstLogLine + #13#10
               + #13#10 +
               'Лог установщика сохранён в файл "' + LogPath + '".', mbError, MB_OK);
        Result := True;
        Exit;
      end;
    end;
  end;
  
  Result := False;
end;

procedure HandleExtractionError(const ArchiveName, DestDir: String; ExceptionMsg: String);
var
  MsgParts: TArrayOfString;
  Handled: Boolean;
  (*LogPath, ErrorCodeStr: String;
  LogText: AnsiString;
  CodePos, CodeStart, CodeEnd: Integer;*)
begin
  Handled := False;

  MsgParts := StringSplit(ExceptionMsg, [': '], stAll);
  if Length(MsgParts) = 2 then
  begin
    if MsgParts[1] = '1' then
    begin
      ExceptionMsg := Format('Не удалось распаковать архив "%s" из-за неизвестной ошибки.', [ArchiveName]) + #1310 +
                      'Путь распаковки - ' + DestDir;
      Handled := True;
    end
    else
      if MsgParts[1] = '11' then
      begin
        // TODO: extract actual error code from setup log
        (*
        LogPath := ExpandConstant('{log}');
        if LoadStringFromLockedFile(LogPath, LogText) then
        begin
          CodePos := RPos('System error code: ', LogText); // `RPos()` doesn't exist
          if CodePos > 0 then
          begin
            // Move to the start of the code
            CodeStart := CodePos + Length(SearchStr);
            // Find the end of the code (first non-digit)
            CodeEnd := CodeStart;
            while (CodeEnd <= Length(LogContents)) and (LogContents[CodeEnd] in ['0'..'9']) do
              Inc(CodeEnd);
            TempStr := Copy(LogContents, CodeStart, CodeEnd - CodeStart);
            // Convert to integer if possible
            try
              Result := StrToInt(TempStr);
            except
              // Leave as -1 if conversion fails
            end;
          end;
        end;
        *)
        
        ExceptionMsg := Format('Не удалось распаковать архив "%s" - нет доступа к файлу(-ам), возможно, он(и) занят(ы) другим процессом.', [ArchiveName]) + #13#10 +
                        + #13#10 +
                        'Если у папки с игрой стоит атрибут "Только для чтения", тогда уберите его (не забудьте "Применить") и попробуйте снова.';
        Handled := True;
      end;
  end;
  
  if not Handled then
    RaiseException(ExceptionMsg);
  
  MsgBox(ExceptionMsg, mbCriticalError, MB_OK);
  RaiseException('empty');
end;

procedure ExtractArchive(const ArchiveFilePath, DestDir: String);
begin
  if not FileExists(ArchiveFilePath) then
    RaiseException('Файл архива не найден, путь - ' + ArchiveFilePath);
  
  try
    Extract7ZipArchive(ArchiveFilePath, DestDir, True, @OnProgress);
  except
    HandleExtractionError(ExtractFileName(ArchiveFilePath), DestDir, GetExceptionMessage());
  end;
end;

function DownloadAndExtractFiles(): Boolean;
var
  LangZipPath, ScriptsZipPath, PatcherZipPath, GamePath, PatcherPath, ExceptionMsg: String;
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
    ExtractArchive(PatcherZipPath, ExpandConstant('{tmp}'));

    ProgressPage.SetText('Распаковка языковых файлов...', '');
    ExtractArchive(LangZipPath, GamePath);

    ProgressPage.SetText('Распаковка скриптов...', '');
    ExtractArchive(ScriptsZipPath, ExpandConstant('{tmp}\scripts'));
    
    ProgressPage.SetText('Применение патча...', '');
    PatcherPath := ExpandConstant('{tmp}\DeltaPatcherCLI.exe');
    if Exec(PatcherPath, Format('--game "%s" --scripts "%s"', [GamePath, ExpandConstant('{tmp}\scripts')]), '', SW_SHOW, ewWaitUntilTerminated, ResultCode) then
    begin
      if ResultCode <> 0 then
      begin
        if not HandlePatcherError(GamePath) then
          MsgBox('Ошибка применения патча, код ошибки: ' + IntToStr(ResultCode) + '.', mbCriticalError, MB_OK);
        
        Result := False;
        Exit;
      end;
    end
    else
    begin
      MsgBox('Не удалось запустить патчер.', mbCriticalError, MB_OK);
      Result := False;
      Exit;
    end;
  except
    ExceptionMsg := GetExceptionMessage();
    if ExceptionMsg <> 'empty' then
      MsgBox('В процессе установки произошла ошибка: ' + #13#10 + GetExceptionMessage(), mbCriticalError, MB_OK);
    
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

procedure CloseInstaller;
begin
  ForceClose := True;
  WizardForm.Close;
end;

procedure CancelButtonClick(CurPageID: Integer; var Cancel, Confirm: Boolean);
begin
  Confirm := not ForceClose;
end;
