#pragma include __INCLUDE__ + ";" + ReadReg(HKLM, "Software\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 6_is1", "InstallLocation")
#pragma include __INCLUDE__ + ";" + "C:\Program Files (x86)\Inno Download Plugin"
#include <idp.iss>

[Setup]
AppName=Русификатор DELTARUNE
AppVersion=1.1.0
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
var
  InfoPage: TOutputMsgWizardPage;
  GamePathPage: TInputDirWizardPage;
  ProgressPage: TOutputProgressWizardPage;

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

  WizardForm.FinishedHeadingLabel.Caption := 'Завершение установки русификатора DELTARUNE';

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

// --- ПРОГРЕСС загрузки через IDP ---
procedure ProgressCallback(URL, FileName: String; FileSize, BytesDownloaded, ElapsedTime, EstimatedRemainingTime: Integer);
var
  SpeedKB, RemainingSec: Integer;
begin
  if FileSize > 0 then
    ProgressPage.SetProgress(BytesDownloaded, FileSize);

  if ElapsedTime > 0 then
    SpeedKB := (BytesDownloaded div 1024) * 1000 div ElapsedTime
  else
    SpeedKB := 0;

  RemainingSec := EstimatedRemainingTime div 1000;

  ProgressPage.SetText(
    'Загружено: ' + IntToStr(BytesDownloaded div 1024) + ' КБ из ' + IntToStr(FileSize div 1024) + ' КБ',
    'Скорость: ' + IntToStr(SpeedKB) + ' КБ/с | Осталось: ' + IntToStr(RemainingSec) + ' сек'
  );
end;

// Скачивание с двух зеркал
function DownloadWithMirror(URL1, URL2, Dest: String): Boolean;
begin
  Result := idpDownloadFile(URL1, Dest);
  if not Result then
    Result := idpDownloadFile(URL2, Dest);
end;


// Распаковка с эмуляцией прогресса
procedure UnzipWithFakeProgress(ZipFile, TargetDir: string);
var
  Shell, ZipFolder: Variant;
  i, TotalItems: Integer;
begin
  Shell := CreateOleObject('Shell.Application');
  ZipFolder := Shell.NameSpace(ZipFile);

  if not DirExists(TargetDir) then
    ForceDirectories(TargetDir);

  TotalItems := ZipFolder.Items.Count;
  for i := 0 to TotalItems - 1 do
  begin
    ProgressPage.SetProgress(i, TotalItems);
    ProgressPage.SetText('Распаковка: ' + ZipFolder.Items.Item(i).Name, '');
    Shell.NameSpace(TargetDir).CopyHere(ZipFolder.Items.Item(i), 4 + 16);
  end;

  ProgressPage.SetProgress(TotalItems, TotalItems);
end;

function OnExtractionProgress(const ArchiveName, FileName: String; const Progress, ProgressMax: Int64): Boolean;
begin
  ProgressPage.SetProgress(Progress, ProgressMax);
  Result := True;
end;

procedure DownloadAndExtractFiles;
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
    ProgressPage.SetText('Загрузка языковых файлов...', '');
    if not DownloadWithMirror('https://github.com/Lazy-Desman/DeltaruneRus/raw/refs/heads/main/lang.7z', 'https://filldor.ru/deltaRU/lang.7z', LangZipPath) then
      RaiseException('Ошибка загрузки lang.zip');

    ProgressPage.SetText('Загрузка скриптов...', '');
    if not DownloadWithMirror('https://github.com/Lazy-Desman/DeltaruneRus/raw/refs/heads/main/scripts.7z', 'https://filldor.ru/deltaRU/scripts.7z', ScriptsZipPath) then
      RaiseException('Ошибка загрузки scripts.zip');

    ProgressPage.SetText('Распаковка патчера...', '');
    Extract7ZipArchive(PatcherZipPath, ExpandConstant('{tmp}'), True, @OnExtractionProgress);

    ProgressPage.SetText('Распаковка языковых файлов...', '');
    Extract7ZipArchive(LangZipPath, GamePath, True, @OnExtractionProgress);

    ProgressPage.SetText('Распаковка скриптов...', '');
    Extract7ZipArchive(ScriptsZipPath, ExpandConstant('{tmp}\scripts'), True, @OnExtractionProgress);

    ProgressPage.SetText('Применение патча...', '');
    PatcherPath := ExpandConstant('{tmp}\DeltaPatcherCLI.exe');
    if Exec(PatcherPath, Format('--game "%s" --scripts "%s"', [GamePath, ExpandConstant('{tmp}\scripts')]), '', SW_SHOW, ewWaitUntilTerminated, ResultCode) then
    begin
      if ResultCode <> 0 then
        MsgBox('Ошибка применения патча: ' + IntToStr(ResultCode), mbError, MB_OK);
    end
    else
      MsgBox('Не удалось запустить патчер', mbError, MB_OK);
  except
    MsgBox('В процессе установки произошла ошибка: ' + GetExceptionMessage(), mbError, MB_OK);
  finally
    ProgressPage.Hide;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    DownloadAndExtractFiles;
end;
