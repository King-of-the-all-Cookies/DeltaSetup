using System;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.CodeAnalysis.CSharp.Scripting;
using Microsoft.CodeAnalysis.Scripting;
using System.Reflection;
using UndertaleModLib;
using System.Runtime;

namespace DeltaPatcherCLI;

class Program
{
    private static ScriptOptions scriptOptions;

    static async Task Main(string[] args)
    {
        try
        {
            Console.WriteLine("DELTARUNE Russian Patcher CLI");
            Console.WriteLine("Version 1.1");
            Console.WriteLine("Developed by LazyDesman");
            Console.WriteLine("-----------------------------------");

            string gamePath = "";
            string scriptsPath = "";

            // парсим аргументы
            for (int i = 0; i < args.Length; i++)
            {
                if (args[i] == "--game" && i + 1 < args.Length)
                    gamePath = args[++i];
                else if (args[i] == "--scripts" && i + 1 < args.Length)
                    scriptsPath = args[++i];
            }

            // справка
            if (string.IsNullOrEmpty(gamePath) || string.IsNullOrEmpty(scriptsPath))
            {
                Console.WriteLine("Использование:");
                Console.WriteLine("DeltarunePatcherCLI.exe --game \"путь_к_игре\" --scripts \"путь_к_скриптам\"");
                Console.WriteLine();
                Console.WriteLine("Пример:");
                Console.WriteLine("DeltarunePatcherCLI.exe --game \"C:\\Games\\DELTARUNE\" --scripts \"C:\\Temp\\scripts\"");
                Environment.Exit(0);
            }

            // проверка дельты
            if (!ValidatePaths(gamePath, scriptsPath))
            {
                Console.WriteLine("Патч не может быть применён из-за ошибок в путях");
                Environment.Exit(1);
            }

            scriptOptions = ScriptOptions.Default
                            .AddImports("UndertaleModLib", "UndertaleModLib.Models", "UndertaleModLib.Decompiler",
                                        "UndertaleModLib.Scripting", "UndertaleModLib.Compiler",
                                        "System", "System.IO", "System.Collections.Generic",
                                        "System.Text.RegularExpressions")
                            .AddReferences(typeof(UndertaleObject).GetTypeInfo().Assembly,
                                           typeof(Program).GetTypeInfo().Assembly,
                                           typeof(System.Text.RegularExpressions.Regex).GetTypeInfo().Assembly,
                                           typeof(Underanalyzer.Decompiler.DecompileContext).Assembly);

            // применяем патч
            await ApplyChapterPatch(gamePath, scriptsPath, "Menu", "data.win");
            await ApplyChapterPatch(gamePath, scriptsPath, "Chapter1", @"chapter1_windows\data.win");
            await ApplyChapterPatch(gamePath, scriptsPath, "Chapter2", @"chapter2_windows\data.win");
            await ApplyChapterPatch(gamePath, scriptsPath, "Chapter3", @"chapter3_windows\data.win");

            Console.WriteLine("-----------------------------------");
            Console.WriteLine("Патч успешно применён!");
            Console.WriteLine("Теперь можно запускать игру с русским переводом");
            Environment.Exit(0);
        }
        catch (Exception ex)
        {
            Console.WriteLine("-----------------------------------");
            Console.WriteLine("КРИТИЧЕСКАЯ ОШИБКА:");
            Console.WriteLine(ex.Message);

            if (ex.InnerException != null)
            {
                Console.WriteLine("Inner exception:");
                Console.WriteLine(ex.InnerException.Message);
            }

            Console.WriteLine("-----------------------------------");
            Console.WriteLine("Детали ошибки сохранены в patcher-error.log");

            File.WriteAllText("patcher-error.log", $"[{DateTime.Now}] ERROR:\n{ex}");
            Environment.Exit(2);
        }
    }

    static bool ValidatePaths(string gamePath, string scriptsPath)
    {
        try
        {
            Console.WriteLine("Проверка путей...");
            Console.WriteLine($"- Папка игры: {gamePath}");
            Console.WriteLine($"- Папка скриптов: {scriptsPath}");

            // проверка существования папок
            if (!Directory.Exists(gamePath))
            {
                Console.WriteLine("ОШИБКА: Папка игры не найдена");
                return false;
            }

            if (!Directory.Exists(scriptsPath))
            {
                Console.WriteLine("ОШИБКА: Папка со скриптами не найдена");
                return false;
            }

            // проверка дельты 2
            if (!File.Exists(Path.Combine(gamePath, "DELTARUNE.exe")))
            {
                Console.WriteLine("ОШИБКА: DELTARUNE.exe не найден");
                return false;
            }

            Console.WriteLine("Все пути корректны");
            return true;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Ошибка при проверке путей: {ex.Message}");
            return false;
        }
    }

    static async Task ApplyChapterPatch(string gamePath, string scriptsPath, string chapter, string dataWin)
    {
        try
        {
            string dataWinPath = Path.Combine(gamePath, dataWin);
            string scriptPath = Path.Combine(scriptsPath, chapter, "Fix.csx");

            Console.WriteLine();
            Console.WriteLine($"===== ПАТЧИНГ ГЛАВЫ: {chapter.ToUpper()} =====");
            Console.WriteLine($"- Файл игры: {dataWinPath}");
            Console.WriteLine($"- Скрипт патча: {scriptPath}");

            // проверка игры
            if (!File.Exists(dataWinPath))
            {
                throw new FileNotFoundException($"Файл игры не найден: {dataWinPath}");
            }

            if (!File.Exists(scriptPath))
            {
                throw new FileNotFoundException($"Скрипт патча не найдена: {scriptPath}");
            }

            // бэкапы
            string backupPath = dataWinPath + ".backup";
            if (File.Exists(backupPath))
            {
                Console.WriteLine("- Восстановление из предыдущей резервной копии...");
                File.Copy(backupPath, dataWinPath, true);
            }
            else
            {
                Console.WriteLine("- Создание резервной копии...");
                File.Copy(dataWinPath, backupPath, true);
            }

            // читаем и модим
            Console.WriteLine("- Чтение data.win...");
            UndertaleData data;
            using (var fileStream = File.OpenRead(dataWinPath))
            {
                data = UndertaleIO.Read(fileStream);
            }

            Console.WriteLine("- Применение скрипта...");
            var script = File.ReadAllText(scriptPath);

            ScriptGlobals scriptGlobals = new()
            {
                Data = data,
                FilePath = dataWinPath,
                ScriptPath = scriptPath
            };

            // Говорим компилятору (при trimming) что все методы (включая getter'ы) используются
            object prop = scriptGlobals.Data;
            prop = scriptGlobals.FilePath;
            prop = scriptGlobals.ScriptPath;
            scriptGlobals.ScriptMessage(null, true);
            scriptGlobals.SyncBinding(null, true);
            scriptGlobals.SetProgressBar(null, null, -1, -1);
            scriptGlobals.UpdateProgressValue(-1);
            scriptGlobals.IncrementProgress();
            scriptGlobals.GetProgress();

            await CSharpScript.RunAsync(script, scriptOptions, globals: scriptGlobals);

            Console.WriteLine("- Сохранение изменений...");
            using (var fileStream = File.Create(dataWinPath))
            {
                UndertaleIO.Write(fileStream, data);
            }

            // Очистка остаточных данных в памяти
            scriptGlobals.Data = null;
            data.Dispose();

            GCSettings.LargeObjectHeapCompactionMode = GCLargeObjectHeapCompactionMode.CompactOnce;
            GC.Collect();
            GC.WaitForPendingFinalizers();

            Console.WriteLine($"- Глава {chapter} успешно пропатчена!");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"!!! ОШИБКА ПРИ ПАТЧИНГЕ ГЛАВЫ {chapter}:");
            Console.WriteLine(ex.Message);

            if (ex.InnerException != null)
            {
                Console.WriteLine("Inner exception:");
                Console.WriteLine(ex.InnerException.Message);
            }

            throw;
        }
    }
}

// передаём данные в скрипты
public class ScriptGlobals
{
    public UndertaleData Data { get; set; }
    public string FilePath { get; set; }
    public string ScriptPath { get; set; }

    public void SyncBinding(string resourceType, bool enable)
    {
        // There is no GUI with WPF bindings
    }

    public void ScriptMessage(string message, bool dummy = false)
    {
        if (!dummy)
            Console.WriteLine(message);
    }

    // TODO?
    public void SetProgressBar(string message, string status, double currentValue, double maxValue) { }
    public void UpdateProgressValue(double currentValue) { }
    public void IncrementProgress() { }
    public int GetProgress() => -1;
}