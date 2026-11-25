@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion
REM Практическая работа 8 (Часть 2): Аудит ПО клиентского компьютера

set "REPORT=%~dp0pc_report.txt"
set "TMP_APPS=%TEMP%\apps_list_raw.txt"
set "SORTED_APPS=%TEMP%\apps_list_clean.txt"

REM Очистка файла отчета перед началом работы
type nul > "%REPORT%"

call :log "=================================================="
call :log "        ОТЧЕТ АУДИТА КЛИЕНТСКОГО КОМПЬЮТЕРА"
call :log "Дата и время формирования: %DATE% %TIME:~0,5%"
call :log "=================================================="
call :log ""

REM --- Блок 1: Сбор сведений об ОС с защитой от пустых значений ---
echo [Этап 1/4] Сбор сведений об операционной системе...
call :log "[1. Операционная система]"
set "os_name="
set "os_ver="
for /f "delims=" %%a in ('powershell -command "(Get-CimInstance Win32_OperatingSystem).Caption" 2^>nul') do set "os_name=%%a"
for /f "delims=" %%a in ('powershell -command "(Get-CimInstance Win32_OperatingSystem).Version" 2^>nul') do set "os_ver=%%a"

if defined os_name (
    call :log "Система: !os_name! (Версия: !os_ver!)"
) else (
    call :log "Система: Не удалось получить сведения об ОС"
)
call :log ""

REM --- Блок 2: Сбор сведений об ОЗУ и диске C ---
echo [Этап 2/4] Проверка аппаратных ресурсов...
call :log "[2. Аппаратные ресурсы]"
set "total_ram="
set "free_ram="
for /f %%a in ('powershell -command "[math]::Round((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1MB)" 2^>nul') do set "total_ram=%%a"
for /f %%a in ('powershell -command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB)" 2^>nul') do set "free_ram=%%a"

if defined total_ram (
    call :log "Оперативная память: Всего !total_ram! ГБ / Свободно !free_ram! ГБ"
) else (
    call :log "Оперативная память: Данные недоступны"
)

set "disk_free_gb="
for /f %%a in ('powershell -command "[math]::Floor((Get-CimInstance Win32_LogicalDisk | Where-Object DeviceID -eq 'C:').FreeSpace / 1GB)" 2^>nul') do set "disk_free_gb=%%a"
if defined disk_free_gb (
    call :log "Диск C: Свободно !disk_free_gb! ГБ"
) else (
    call :log "Диск C: Данные недоступны"
)
call :log ""

REM --- Блок 3: Выгрузка списка программ из обеих веток реестра ---
echo [Этап 3/4] Опрос реестра установленных программ (подождите)...
type nul > "%TMP_APPS%"

for /f "tokens=2*" %%a in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2^>nul ^| findstr "DisplayName"') do (
    echo %%b>> "%TMP_APPS%"
)
for /f "tokens=2*" %%a in ('reg query "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /v DisplayName 2^>nul ^| findstr "DisplayName"') do (
    echo %%b>> "%TMP_APPS%"
)

REM Сортировка и удаление дубликатов
powershell -command "Get-Content '%TMP_APPS%' | Sort-Object -Unique | Set-Content '%SORTED_APPS%' -Encoding UTF8"

REM --- Блок 4: Анализ базового офисного ПО ---
echo [Этап 4/4] Анализ установленного ПО и формирование рекомендаций...
call :log "[3. Проверка базового офисного ПО]"
set /a checked_count=5
set /a rec_count=0

findstr /i "Office LibreOffice OpenOffice МойОфис" "%SORTED_APPS%" >nul
if !errorlevel! equ 0 (
    call :log "[OK] Офисный пакет: установлен"
) else (
    call :log "[!] Рекомендация: Не обнаружен офисный пакет. Рекомендуется установить LibreOffice или МойОфис."
    set /a rec_count+=1
)

findstr /i "7-Zip WinRAR WinZip" "%SORTED_APPS%" >nul
if !errorlevel! equ 0 (
    call :log "[OK] Архиватор: установлен"
) else (
    call :log "[!] Рекомендация: Не обнаружен архиватор. Для работы с вложениями в почте рекомендуется установить 7-Zip или WinRAR."
    set /a rec_count+=1
)

findstr /i "Acrobat Foxit SumatraPDF" "%SORTED_APPS%" >nul
if !errorlevel! equ 0 (
    call :log "[OK] Программа для чтения PDF: установлена"
) else (
    call :log "[!] Рекомендация: Не обнаружен специализированный PDF-ридер (рекомендуется SumatraPDF или Acrobat Reader)."
    set /a rec_count+=1
)

findstr /i "Chrome Firefox Яндекс Opera" "%SORTED_APPS%" >nul
if !errorlevel! equ 0 (
    call :log "[OK] Дополнительный браузер: установлен"
) else (
    call :log "[!] Инфо: Сторонний браузер не найден (присутствует системный компонент Microsoft Edge)."
)

findstr /i "Kaspersky ESET Dr.Web Avast" "%SORTED_APPS%" >nul
if !errorlevel! equ 0 (
    call :log "[OK] Сторонний антивирус: обнаружен"
) else (
    call :log "[OK] Антивирус: используется встроенный Защитник Windows (Windows Defender)."
)
call :log ""

REM --- Блок 5: Поиск нецелевого (излишнего) ПО ---
call :log "[4. Проверка на наличие нецелевого ПО (подлежит проверке администратором)]"
call :log "Примечание: Вывод ниже является рекомендацией к проверке, а не указанием к удалению."

set "found_games="
for /f "delims=" %%g in ('findstr /i "Steam Epic GOG Origin Ubisoft Battle.net Riot game gaming" "%SORTED_APPS%"') do (
    call :log "  - [Игровое ПО]: %%g"
    set "found_games=1"
    set /a rec_count+=1
)
if not defined found_games call :log "  - [Игровое ПО]: не обнаружено"

set "found_torrent="
for /f "delims=" %%t in ('findstr /i "torrent uTorrent BitTorrent qBittorrent Vuze" "%SORTED_APPS%"') do (
    call :log "  - [Торрент-клиенты]: %%t"
    set "found_torrent=1"
    set /a rec_count+=1
)
if not defined found_torrent call :log "  - [Торрент-клиенты]: не обнаружено"

set "found_msg="
for /f "delims=" %%m in ('findstr /i "Discord Telegram WhatsApp Viber Skype" "%SORTED_APPS%"') do (
    call :log "  - [Мессенджеры (проверить согласование)]: %%m"
    set "found_msg=1"
    set /a rec_count+=1
)
if not defined found_msg call :log "  - [Мессенджеры]: не обнаружено"

set "found_media="
for /f "delims=" %%e in ('findstr /i "Wallpaper OBS Soundpad" "%SORTED_APPS%"') do (
    call :log "  - [Развлечения и стриминг]: %%e"
    set "found_media=1"
    set /a rec_count+=1
)
if not defined found_media call :log "  - [Развлечения и стриминг]: не обнаружено"

REM --- Итоги и очистка ---
call :log ""
call :log "=================================================="
call :log "ИТОГ ПРОВЕРКИ:"
call :log "Проверено категорий базового ПО: !checked_count!"
call :log "Сформировано рекомендаций / пунктов для проверки: !rec_count!"
call :log "Полный путь к отчету: %REPORT%"
call :log "=================================================="

if exist "%TMP_APPS%" del /q "%TMP_APPS%"
if exist "%SORTED_APPS%" del /q "%SORTED_APPS%"

echo.
pause
exit /b

REM ==================================================
REM Подпрограмма :log для вывода в консоль и файл
REM ==================================================
:log
if "%~1"=="" (
    echo(
    echo(>> "%REPORT%"
) else (
    echo %~1
    echo %~1>> "%REPORT%"
)
exit /b
