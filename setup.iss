#pragma include __INCLUDE__ + ";" + ReadReg(HKLM, "Software\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 6_is1", "InstallLocation")
#pragma include __INCLUDE__ + ";" + "C:\Program Files (x86)\Inno Download Plugin"
#include <idp.iss>

[Setup]
AppName=Русификатор DELTARUNE
AppVersion=1.0
AppPublisher=LazyDesman
DefaultDirName={autopf}\DELTARUNE Russian Patch
OutputBaseFilename=DeltaruneRussianPatcherSetup
Compression=lzma2
SolidCompression=yes
SetupIconFile=icon.ico
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
DisableDirPage=yes
WizardSmallImageFile=logo.bmp
WizardImageFile=banner.bmp

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Files]
Source: "DeltarunePatcherCLI.zip"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Code]
var
  InfoPage: TOutputMsgWizardPage;
  GamePathPage: TInputDirWizardPage;
  ProgressPage: TOutputProgressWizardPage;

procedure InitializeWizard;
begin
  // Кастомизация приветственной страницы
  WizardForm.WelcomeLabel1.Caption := 'Добро пожаловать в мастер установки русификатора DELTARUNE';
  WizardForm.WelcomeLabel2.Caption := 'Этот мастер установит русификатор для игры DELTARUNE, подготовленный командой LazyDesman.';

  // Создание информационной страницы
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

  // Создание страницы выбора пути
  GamePathPage := CreateInputDirPage(
    InfoPage.ID,
    'Выберите папку DELTARUNE',
    'Где установлена игра?',
    'Выберите папку, содержащую DELTARUNE.exe и папки chapter1_windows, chapter2_windows и т.д.'#13#10 +
    'Обычно это выглядит так: "C:\Program Files (x86)\Steam\steamapps\common\DELTARUNE"',
    False, ''
  );
  GamePathPage.Add('');

  // Кастомизация страницы завершения
  WizardForm.FinishedHeadingLabel.Caption := 'Завершение установки русификатора DELTARUNE';


  // Создание страницы прогресса
  ProgressPage := CreateOutputProgressPage('Выполнение установки', 'Пожалуйста, подождите, пока выполняется установка...');
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID = GamePathPage.ID then
  begin
    if not FileExists(AddBackslash(GamePathPage.Values[0]) + 'DELTARUNE.exe') then
    begin
      MsgBox('Не найден DELTARUNE.exe в указанной папке!', mbError, MB_OK);
      Result := False;
    end;
  end;
end;

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

procedure Unzip(ZipFile, TargetDir: string);
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
    Shell.NameSpace(TargetDir).CopyHere(ZipFolder.Items.Item(i), 4 + 16);

  Sleep(500);
end;

procedure DownloadAndExtractFiles;
var
  LangZipPath, ScriptsZipPath, PatcherZipPath, GamePath, PatcherPath: String;
  ResultCode: Integer;
begin
  LangZipPath := ExpandConstant('{tmp}\lang.zip');
  ScriptsZipPath := ExpandConstant('{tmp}\scripts.zip');
  PatcherZipPath := ExpandConstant('{tmp}\DeltarunePatcherCLI.zip');
  GamePath := GamePathPage.Values[0];

  ProgressPage.Show;
  try
    ProgressPage.SetText('Загрузка языковых файлов...', '');
    if not idpDownloadFile('https://filldor.ru/deltaRU/lang.zip', LangZipPath) then
      RaiseException('Ошибка загрузки lang.zip');

    ProgressPage.SetText('Загрузка скриптов...', '');
    if not idpDownloadFile('https://filldor.ru/deltaRU/scripts.zip', ScriptsZipPath) then
      RaiseException('Ошибка загрузки scripts.zip');

    ProgressPage.SetText('Распаковка патчера...', '');
    Unzip(PatcherZipPath, ExpandConstant('{tmp}'));

    ProgressPage.SetText('Распаковка языковых файлов...', '');
    Unzip(LangZipPath, GamePath);

    ProgressPage.SetText('Распаковка скриптов...', '');
    Unzip(ScriptsZipPath, ExpandConstant('{tmp}\scripts'));

    ProgressPage.SetText('Применение патча...', '');
    PatcherPath := ExpandConstant('{tmp}\DeltaPatcherCLI.exe');
    if Exec(PatcherPath, Format('--game "%s" --scripts "%s"', [GamePath, ExpandConstant('{tmp}\scripts')]), '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    begin
      if ResultCode <> 0 then
        MsgBox('Ошибка применения патча: ' + IntToStr(ResultCode), mbError, MB_OK);
    end
    else
      MsgBox('Не удалось запустить патчер', mbError, MB_OK);

  finally
    ProgressPage.Hide;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    DownloadAndExtractFiles;
end;