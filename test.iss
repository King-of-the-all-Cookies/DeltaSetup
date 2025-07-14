; -- ОБЯЗАТЕЛЬНЫЕ ИНКЛЮДЫ --
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
; Разрешить отмену загрузки
CancelableInstall=yes

[Files]
Source: "DeltaPatcherCLI.zip"; DestDir: "{tmp}"; Flags: dontcopy

[Code]
var
  GamePathPage: TInputDirWizardPage;
  DownloadProgressPage: TOutputProgressWizardPage;

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
  
  // Инициализация IDP
  idpDownloadAfter(wpReady);
  
  // Создаем страницу прогресса для распаковки
  DownloadProgressPage := CreateOutputProgressPage('Установка русификатора', 'Пожалуйста, подождите...');
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
    // Добавляем файлы для загрузки
    idpAddFile('https://filldor.ru/deltaRU/lang.zip', ExpandConstant('{tmp}\lang.zip'));
    idpAddFile('https://filldor.ru/deltaRU/scripts.zip', ExpandConstant('{tmp}\scripts.zip'));
    
    // Показываем кнопку "Назад" на странице готовности
    WizardForm.BackButton.Visible := True;
  end;
end;

// Распаковка ZIP архива с прогрессом
procedure UnzipWithProgress(ZipFile, TargetDir: string);
var
  Shell: Variant;
  ZipFolder: Variant;
  ItemCount: Integer;
  i: Integer;
begin
  DownloadProgressPage.SetText('Распаковка архива...', '');
  DownloadProgressPage.Show;
  try
    Shell := CreateOleObject('Shell.Application');
    ZipFolder := Shell.NameSpace(ZipFile);
    if VarIsClear(ZipFolder) then
      RaiseException('Ошибка открытия ZIP архива: ' + ZipFile);
    
    ItemCount := ZipFolder.Items.Count;
    DownloadProgressPage.SetProgress(0, ItemCount);
    
    for i := 0 to ItemCount - 1 do
    begin
      DownloadProgressPage.SetText('Распаковка:', ZipFolder.Items.Item(i).Name);
      DownloadProgressPage.SetProgress(i + 1, ItemCount);
      Shell.NameSpace(TargetDir).CopyHere(ZipFolder.Items.Item(i), 16);
    end;
  finally
    DownloadProgressPage.Hide;
  end;
end;

// Извлекаем патчер из ZIP
procedure ExtractPatcher;
var
  ZipPath: string;
begin
  DownloadProgressPage.SetText('Подготовка патчера...', '');
  DownloadProgressPage.Show;
  try
    ZipPath := ExpandConstant('{tmp}\DeltaPatcherCLI.zip');
    ExtractTemporaryFile(ExtractFileName(ZipPath));
    UnzipWithProgress(ZipPath, ExpandConstant('{tmp}\DeltaPatcherCLI'));
  finally
    DownloadProgressPage.Hide;
  end;
end;

procedure ApplyPatch;
var
  LangZipPath, ScriptsZipPath: String;
  GamePath: String;
  PatcherPath: String;
  ResultCode: Integer;
begin
  LangZipPath := ExpandConstant('{tmp}\lang.zip');
  ScriptsZipPath := ExpandConstant('{tmp}\scripts.zip');
  GamePath := GamePathPage.Values[0];
  PatcherPath := ExpandConstant('{tmp}\DeltaPatcherCLI\DeltarunePatcherCLI.exe');
  
  try
    // Распаковка языковых файлов
    DownloadProgressPage.SetText('Установка языковых файлов...', '');
    DownloadProgressPage.Show;
    try
      if FileExists(LangZipPath) then
        UnzipWithProgress(LangZipPath, GamePath)
      else
        RaiseException('Файл lang.zip не найден');
    finally
      DownloadProgressPage.Hide;
    end;
    
    // Распаковка скриптов
    DownloadProgressPage.SetText('Подготовка скриптов...', '');
    DownloadProgressPage.Show;
    try
      if FileExists(ScriptsZipPath) then
        UnzipWithProgress(ScriptsZipPath, ExpandConstant('{tmp}\scripts'))
      else
        RaiseException('Файл scripts.zip не найден');
    finally
      DownloadProgressPage.Hide;
    end;
    
    // Запускаем патчер
    DownloadProgressPage.SetText('Применение патча...', 'Это может занять несколько минут');
    DownloadProgressPage.Show;
    try
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
    finally
      DownloadProgressPage.Hide;
    end;
  except
    MsgBox('Ошибка при установке: ' + GetExceptionMessage, mbError, MB_OK);
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
  begin
    try
      // Загружаем файлы
      if idpFilesCount > 0 then
      begin
        DownloadProgressPage.SetText('Загрузка файлов...', 'Пожалуйста, подождите');
        DownloadProgressPage.Show;
        try
          idpDownload;
        finally
          DownloadProgressPage.Hide;
        end;
        
        if idpDownloadErrors then
        begin
          MsgBox('Ошибка загрузки файлов', mbError, MB_OK);
          Abort;
        end;
      end;
      
      // Извлекаем патчер
      ExtractPatcher;
      
      // Применяем патч
      ApplyPatch;
    except
      MsgBox('Критическая ошибка: ' + GetExceptionMessage, mbError, MB_OK);
      Abort;
    end;
  end;
end;

procedure DeinitializeSetup();
begin
  // Принудительное удаление временных файлов
  DelTree(ExpandConstant('{tmp}\DeltaPatcherCLI'), True, True, True);
  DeleteFile(ExpandConstant('{tmp}\lang.zip'));
  DeleteFile(ExpandConstant('{tmp}\scripts.zip'));
  DeleteFile(ExpandConstant('{tmp}\DeltaPatcherCLI.zip'));
end;