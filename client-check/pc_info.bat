@echo off
chcp 65001 > nul
REM Практическая работа 8 (Часть 1): Диагностика клиентского компьютера

set "REPORT=%~dp0pc_report.txt"

echo ==================================================
echo              ДИАГНОСТИКА КОМПЬЮТЕРА
echo ==================================================
echo ================================================== > "%REPORT%"
echo              ДИАГНОСТИКА КОМПЬЮТЕРА >> "%REPORT%"
echo ================================================== >> "%REPORT%"

REM --- 1. Операционная система ---
echo.
echo [Операционная система]
echo. >> "%REPORT%"
echo [Операционная система] >> "%REPORT%"
for /f "delims=" %%a in ('powershell -command "(Get-CimInstance Win32_OperatingSystem).Caption"') do (
    echo Название: %%a
    echo Название: %%a >> "%REPORT%"
)
for /f "delims=" %%a in ('powershell -command "(Get-CimInstance Win32_OperatingSystem).Version"') do (
    echo Версия: %%a
    echo Версия: %%a >> "%REPORT%"
)

REM --- 2. Процессор ---
echo.
echo [Процессор]
echo. >> "%REPORT%"
echo [Процессор] >> "%REPORT%"
for /f "delims=" %%a in ('powershell -command "(Get-CimInstance Win32_Processor).Name"') do (
    echo Модель: %%a
    echo Модель: %%a >> "%REPORT%"
)

REM --- 3. Оперативная память ---
echo.
echo [Оперативная память]
echo. >> "%REPORT%"
echo [Оперативная память] >> "%REPORT%"
for /f %%a in ('powershell -command "[math]::Round((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1MB)"') do set "total_ram=%%a"
for /f %%a in ('powershell -command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB)"') do set "free_ram=%%a"
echo Всего памяти: %total_ram% ГБ
echo Свободно памяти: %free_ram% ГБ
echo Всего памяти: %total_ram% ГБ >> "%REPORT%"
echo Свободно памяти: %free_ram% ГБ >> "%REPORT%"

REM --- 4. Свободное место на диске C ---
echo.
echo [Диск C]
echo. >> "%REPORT%"
echo [Диск C] >> "%REPORT%"
for /f %%a in ('powershell -command "[math]::Floor((Get-CimInstance Win32_LogicalDisk | Where-Object DeviceID -eq 'C:').Size / 1GB)"') do set "disk_size_gb=%%a"
for /f %%a in ('powershell -command "[math]::Floor((Get-CimInstance Win32_LogicalDisk | Where-Object DeviceID -eq 'C:').FreeSpace / 1GB)"') do set "disk_free_gb=%%a"
echo Общий размер: %disk_size_gb% ГБ
echo Свободно: %disk_free_gb% ГБ
echo Общий размер: %disk_size_gb% ГБ >> "%REPORT%"
echo Свободно: %disk_free_gb% ГБ >> "%REPORT%"


REM --- 5. Установленные программы ---
echo.
echo [Установленные программы]
echo Идет сбор списка программ...
echo. >> "%REPORT%"
echo [Установленные программы] >> "%REPORT%"

for /f "tokens=2*" %%a in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2^>nul ^| findstr "DisplayName"') do (
    echo - %%b
    echo - %%b >> "%REPORT%"
)
for /f "tokens=2*" %%a in ('reg query "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2^>nul ^| findstr "DisplayName"') do (
    echo - %%b
    echo - %%b >> "%REPORT%"
)

echo.
echo ==================================================
echo Отчет сохранен в файл: %REPORT%
pause
