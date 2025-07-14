; -- ОБЯЗАТЕЛЬНЫЕ ИНКЛЮДЫ --
#pragma include __INCLUDE__ + ";" + ReadReg(HKLM, "Software\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 6_is1", "InstallLocation")
#pragma include __INCLUDE__ + ";" + "C:\Program Files (x86)\Inno Download Plugin"
#include <idp.iss>  ; Для загрузки файлов

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

// УДАЛЕНА НЕКОРРЕКТНАЯ ФУНКЦИЯ DirExists - ИСПОЛЬЗУЕМ ВСТРОЕННУЮ

procedure Unzip(ZipFile, TargetDir: string);
var
  Shell: Variant;
  ZipFolder: Variant;
  i: Integer;
begin
  try
    Shell := CreateOleObject('Shell.Application');
    if VarIsNull(Shell) then
      RaiseException('Не удалось создать объект Shell.Application');

    ZipFolder := Shell.NameSpace(ZipFile);
    if VarIsClear(ZipFolder) then
      RaiseException('Ошибка открытия ZIP архива: ' + ZipFile);

    // ИСПОЛЬЗУЕМ ВСТРОЕННУЮ ФУНКЦИЮ DirExists
    if not DirExists(TargetDir) then
      if not ForceDirectories(TargetDir) then
        RaiseException('Не удалось создать директорию: ' + TargetDir);

    for i := 0 to ZipFolder.Items.Count - 1 do
    begin
      Shell.NameSpace(TargetDir).CopyHere(ZipFolder.Items.Item(i), 4 + 16);
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

  try
    if not idpDownloadFile('https://filldor.ru/deltaRU/lang.zip', LangZipPath) then
      RaiseException('Ошибка загрузки файла lang.zip');

    if not idpDownloadFile('https://filldor.ru/deltaRU/scripts.zip', ScriptsZipPath) then
      RaiseException('Ошибка загрузки файла scripts.zip');

    Unzip(PatcherZipPath, ExpandConstant('{tmp}'));
    PatcherPath := ExpandConstant('{tmp}\DeltaPatcherCLI.exe');

    if FileExists(LangZipPath) then
      Unzip(LangZipPath, GamePath)
    else
      RaiseException('Файл lang.zip не найден');

    if FileExists(ScriptsZipPath) then
      Unzip(ScriptsZipPath, ExpandConstant('{tmp}\scripts'))
    else
      RaiseException('Файл scripts.zip не найден');

    if FileExists(PatcherPath) then
    begin
      // УБРАН AddQuotes - КАВЫЧКИ УЖЕ ФОРМИРУЮТСЯ В Format
      if Exec(
        PatcherPath,
        Format('--game "%s" --scripts "%s"', [
          GamePath,  // БЕЗ AddQuotes
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
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    DownloadAndExtractFiles;
end;