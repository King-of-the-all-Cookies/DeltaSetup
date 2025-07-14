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
  WelcomePage: TWizardPage;
  GamePathPage: TInputDirWizardPage;
  ProgressPage: TOutputProgressWizardPage;

procedure InitializeWizard;
begin
  // Костыль: создаем дублированную приветственную страницу
  WelcomePage := CreateCustomPage(wpWelcome, 
    'Добро пожаловать в мастер установки русификатора DELTARUNE', 
    'Этот мастер установит русификатор для игры DELTARUNE, подготовленный командой LazyDesman.');

  // Создаем элементы для дублированной страницы
  with TNewStaticText.Create(WelcomePage) do
  begin
    Parent := WelcomePage.Surface;
    Caption := 'Внимание: Убедитесь, что игра DELTARUNE установлена на вашем компьютере.';
    Left := ScaleX(0);
    Top := ScaleY(60);
    Width := WelcomePage.SurfaceWidth;
    Height := ScaleY(20);
  end;

  with TNewStaticText.Create(WelcomePage) do
  begin
    Parent := WelcomePage.Surface;
    Caption := 'Этот установщик выполнит следующие действия:';
    Left := ScaleX(0);
    Top := ScaleY(100);
    Width := WelcomePage.SurfaceWidth;
    Height := ScaleY(20);
  end;

  with TNewStaticText.Create(WelcomePage) do
  begin
    Parent := WelcomePage.Surface;
    Caption := '1. Установит DelTranslate';
    Left := ScaleX(20);
    Top := ScaleY(130);
    Width := WelcomePage.SurfaceWidth;
    Height := ScaleY(20);
  end;

  with TNewStaticText.Create(WelcomePage) do
  begin
    Parent := WelcomePage.Surface;
    Caption := '2. Установит перевод для 1, 2 и 3 главы';
    Left := ScaleX(20);
    Top := ScaleY(150);
    Width := WelcomePage.SurfaceWidth;
    Height := ScaleY(20);
  end;

  // Создание страницы выбора пути
  GamePathPage := CreateInputDirPage(
    WelcomePage.ID,
    'Выберите папку DELTARUNE',
    'Где установлена игра?',
    'Выберите папку, содержащую DELTARUNE.exe и папки chapter1_windows, chapter2_windows и т.д.',
    False, ''
  );
  GamePathPage.Add('');

  // Создание страницы прогресса
  ProgressPage := CreateOutputProgressPage('Выполнение установки', 'Пожалуйста, подождите, пока выполняется установка...');

  // Изменение текста на странице завершения
  WizardForm.FinishedHeadingLabel.Caption := 'Завершение установки русификатора DELTARUNE';
  WizardForm.FinishedLabel.Caption := 'Русификатор DELTARUNE был успешно установлен поверх вашей копии игры.' + #13#10#13#10 +
    'Нажмите "Завершить", чтобы выйти из программы установки.';
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