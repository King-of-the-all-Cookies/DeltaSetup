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
; Запрещаем создание папки приложения - нам она не нужна
DisableDirPage=yes

[Files]
; Патчер в архиве
Source: "DeltarunePatcherCLI.zip"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Code]
var
  GamePathPage: TInputDirWizardPage;
  DownloadPage: TDownloadWizardPage;

procedure InitializeWizard;
begin
  // Страница выбора пути к игре
  GamePathPage := CreateInputDirPage(
    wpWelcome,
    'Выберите папку с игрой DELTARUNE',
    'Где установлена игра?',
    'Выберите папку, содержащую DELTARUNE.exe и папки chapter1_windows, chapter2_windows и т.д.',
    False, ''
  );
  GamePathPage.Add('');

  // Инициализация страницы загрузки
  DownloadPage := CreateDownloadPage(SetupMessage(msgWizardPreparing), SetupMessage(msgPreparingDesc), nil);
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;

  if CurPageID = GamePathPage.ID then
  begin
    // Проверка пути
    if not FileExists(AddBackslash(GamePathPage.Values[0]) + 'DELTARUNE.exe') then
    begin
      MsgBox('Не найден DELTARUNE.exe в указанной папке!', mbError, MB_OK);
      Result := False;
    end;
  end
  else if CurPageID = wpReady then
  begin
    // Настройка загрузки
    DownloadPage.Clear;
    DownloadPage.Add('https://filldor.ru/deltaRU/lang.zip', 'lang.zip', '');
    DownloadPage.Add('https://filldor.ru/deltaRU/scripts.zip', 'scripts.zip', '');

    try
      DownloadPage.Show;
      DownloadPage.Download;
    except
      Result := False;
      MsgBox('Ошибка при загрузке файлов: ' + GetExceptionMessage, mbError, MB_OK);
    end;
  end;
end;

// Распаковка ZIP архива
procedure Unzip(ZipFile, TargetDir: string);
var
  Shell: Variant;
  ZipFolder: Variant;
begin
  Shell := CreateOleObject('Shell.Application');
  ZipFolder := Shell.NameSpace(ZipFile);
  if VarIsClear(ZipFolder) then
    RaiseException('Ошибка открытия ZIP архива: ' + ZipFile);

  Shell.NameSpace(TargetDir).CopyHere(ZipFolder.Items, 16);
end;

procedure ExtractAndApplyResources;
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
    // Распаковка патчера
    Unzip(PatcherZipPath, ExpandConstant('{tmp}'));
    PatcherPath := ExpandConstant('{tmp}\DeltarunePatcherCLI.exe');

    // Распаковка языковых файлов прямо в папку игры
    if FileExists(LangZipPath) then
    begin
      Unzip(LangZipPath, GamePath);
    end
    else
    begin
      RaiseException('Файл lang.zip не найден');
    end;

    // Распаковка скриптов во временную папку
    if FileExists(ScriptsZipPath) then
    begin
      Unzip(ScriptsZipPath, ExpandConstant('{tmp}\scripts'));
    end
    else
    begin
      RaiseException('Файл scripts.zip не найден');
    end;

    // Запускаем патчер
    if FileExists(PatcherPath) then
    begin
      if Exec(
        PatcherPath,
        Format('--game="%s" --scripts="%s"', [
          AddQuotes(GamePath),
          AddQuotes(ExpandConstant('{tmp}\scripts'))
        ]),
        '', SW_HIDE, ewWaitUntilTerminated, ResultCode
      ) then
      begin
        if ResultCode <> 0 then
          MsgBox('Ошибка применения патча: ' + IntToStr(ResultCode), mbError, MB_OK);
      end
      else
      begin
        MsgBox('Не удалось запустить патчер', mbError, MB_OK);
      end;
    end
    else
    begin
      MsgBox('Файл патчера не найден', mbError, MB_OK);
    end;
  except
    MsgBox('Ошибка при установке: ' + GetExceptionMessage, mbError, MB_OK);
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  // Всё делаем на последнем шаге
  if CurStep = ssPostInstall then
  begin
    ExtractAndApplyResources;
  end;
end;
