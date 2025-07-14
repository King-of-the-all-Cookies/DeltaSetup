; -- ОБЯЗАТЕЛЬНЫЕ ИНКЛЮДЫ --
#pragma include __INCLUDE__ + ";" + ReadReg(HKLM, "Software\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 6_is1", "InstallLocation")
#pragma include __INCLUDE__ + ";" + "C:\Program Files (x86)\Inno Download Plugin"
#include <idp.iss> ; Для загрузки файлов

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

[Files]
Source: "DeltarunePatcherCLI.zip"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Code]
var
  GamePathPage: TInputDirWizardPage;
  ProgressPage: TOutputProgressWizardPage;

procedure InitializeWizard;
begin
  GamePathPage := CreateInputDirPage(
    wpWelcome,
    'Выберите папку с игрой DELTARUNE',
    'Где установлена игра?',
    'Выберите папку, содержащую DELTARUNE.exe и папки chapter1_windows, chapter2_windows и т.д.',
    False, ''
  );
  GamePathPage.Add('');

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

procedure Unzip(ZipFile, TargetDir: string);
var
  Shell: Variant;
  ZipFolder: Variant;
  i, TotalItems: Integer;
begin
  try
    Shell := CreateOleObject('Shell.Application');
    if VarIsNull(Shell) then
      RaiseException('Не удалось создать объект Shell.Application');
      
    ZipFolder := Shell.NameSpace(ZipFile);
    if VarIsClear(ZipFolder) then
      RaiseException('Ошибка открытия ZIP архива: ' + ZipFile);
      
    if not DirExists(TargetDir) then
      if not ForceDirectories(TargetDir) then
        RaiseException('Не удалось создать директорию: ' + TargetDir);

    TotalItems := ZipFolder.Items.Count;
    if TotalItems = 0 then
      RaiseException('ZIP архив пуст: ' + ZipFile);

    ProgressPage.SetText('Распаковка файлов...', 'Пожалуйста, подождите');

    for i := 0 to TotalItems - 1 do
    begin
      Shell.NameSpace(TargetDir).CopyHere(ZipFolder.Items.Item(i), 4 + 16);
      ProgressPage.SetProgress(i, TotalItems);
    end;
    Sleep(1000);
  except
    RaiseException('Ошибка при распаковке ZIP архива: ' + GetExceptionMessage);
  end;
end;

procedure DownloadAndExtractFiles;
var
  LangZipPath, ScriptsZipPath, PatcherZipPath: String;
  GamePath: String;
  PatcherPath: String;
  ResultCode: Integer;
begin
  LangZipPath := ExpandConstant('{tmp}\lang.zip');
  ScriptsZipPath := ExpandConstant('{tmp}\scripts.zip');
  PatcherZipPath := ExpandConstant('{tmp}\DeltarunePatcherCLI.zip');
  GamePath := GamePathPage.Values[0];

  ProgressPage.SetText('Загрузка файлов...', 'Пожалуйста, подождите');
  ProgressPage.Show;
  
  try
    try
      // Загрузка языковых файлов
      ProgressPage.SetText('Загрузка языковых файлов...', '');
      if not idpDownloadFile('https://filldor.ru/deltaRU/lang.zip', LangZipPath) then
        RaiseException('Ошибка загрузки файла lang.zip');
      ProgressPage.SetProgress(33, 100);

      // Загрузка скриптов патчера
      ProgressPage.SetText('Загрузка скриптов патчера...', '');
      if not idpDownloadFile('https://filldor.ru/deltaRU/scripts.zip', ScriptsZipPath) then
        RaiseException('Ошибка загрузки файла scripts.zip');
      ProgressPage.SetProgress(66, 100);

      // Распаковка патчера
      ProgressPage.SetText('Распаковка патчера...', '');
      Unzip(PatcherZipPath, ExpandConstant('{tmp}'));
      ProgressPage.SetProgress(100, 100);

      // Распаковка языковых файлов в папку игры
      PatcherPath := ExpandConstant('{tmp}\DeltaPatcherCLI.exe');
      if FileExists(LangZipPath) then
      begin
        ProgressPage.SetText('Распаковка языковых файлов...', '');
        Unzip(LangZipPath, GamePath);
      end
      else
        RaiseException('Файл lang.zip не найден');

      // Распаковка скриптов во временную папку
      if FileExists(ScriptsZipPath) then
      begin
        ProgressPage.SetText('Распаковка скриптов...', '');
        Unzip(ScriptsZipPath, ExpandConstant('{tmp}\scripts'));
      end
      else
        RaiseException('Файл scripts.zip не найден');

      // Применение патча
      if FileExists(PatcherPath) then
      begin
        ProgressPage.SetText('Применение патча...', 'Пожалуйста, подождите');
        if Exec(
          PatcherPath,
          Format('--game "%s" --scripts "%s"', [
            GamePath,
            ExpandConstant('{tmp}\scripts')
          ]),
          '', SW_HIDE, ewWaitUntilTerminated, ResultCode
        ) then
        begin
          if ResultCode <> 0 then
            MsgBox('Ошибка применения патча: ' + IntToStr(ResultCode), mbError, MB_OK);
        end
        else
          MsgBox('Не удалось запустить патчер', mbError, MB_OK);
      end
      else
        MsgBox('Файл патчера не найден', mbError, MB_OK);
    except
      MsgBox('Ошибка при установке: ' + GetExceptionMessage, mbError, MB_OK);
    end;
  finally
    // Гарантированное скрытие прогресс-страницы
    ProgressPage.Hide;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    DownloadAndExtractFiles;
end;