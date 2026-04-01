@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   HandBrake Portable Package Creator
echo ========================================
echo.

:: Configuration
set "SOURCE_DIR=win\CS\HandBrakeWPF\bin\Release"
set "TEMP_DIR=HandBrake_temp"
set "FINAL_DIR=HandBrake"
set "ARCHIVE_PATH=\\cluster2019fs\install\_Programmes\Handbrake\Handbrake.7z"
set "SEVENZIP_PATH=C:\Program Files\7-Zip\7z.exe"

:: Vérifier que 7-Zip est installé
if not exist "%SEVENZIP_PATH%" (
    echo ERREUR: 7-Zip n'est pas installé dans %SEVENZIP_PATH%
    echo Veuillez installer 7-Zip ou modifier le chemin dans le script.
    echo.
    echo Appuyez sur une touche pour quitter...
    pause >nul
    exit /b 1
)

:: Vérifier que le dossier source existe
if not exist "%SOURCE_DIR%" (
    echo ERREUR: Le dossier source %SOURCE_DIR% n'existe pas.
    echo Veuillez compiler HandBrake en mode Release d'abord.
    echo.
    echo Appuyez sur une touche pour quitter...
    pause >nul
    exit /b 1
)

:: Nettoyer les anciens dossiers temporaires
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
if exist "%FINAL_DIR%" rmdir /s /q "%FINAL_DIR%"

echo Création du package portable...
echo.

:: Créer le dossier temporaire
mkdir "%TEMP_DIR%"

:: Copier les fichiers essentiels
echo Copie des fichiers essentiels...

:: Fichiers principaux (comme la version officielle)
copy "%SOURCE_DIR%\HandBrake.exe" "%TEMP_DIR%\" >nul
copy "%SOURCE_DIR%\HandBrake.dll" "%TEMP_DIR%\" >nul
copy "%SOURCE_DIR%\HandBrake.Worker.exe" "%TEMP_DIR%\" >nul
copy "%SOURCE_DIR%\HandBrake.Worker.dll" "%TEMP_DIR%\" >nul
copy "%SOURCE_DIR%\hb.dll" "%TEMP_DIR%\" >nul

:: Fichiers de configuration
copy "%SOURCE_DIR%\HandBrake.deps.json" "%TEMP_DIR%\" >nul
copy "%SOURCE_DIR%\HandBrake.runtimeconfig.json" "%TEMP_DIR%\" >nul
copy "%SOURCE_DIR%\HandBrake.Worker.deps.json" "%TEMP_DIR%\" >nul
copy "%SOURCE_DIR%\HandBrake.Worker.runtimeconfig.json" "%TEMP_DIR%\" >nul

:: Dépendances essentielles
copy "%SOURCE_DIR%\HandBrake.App.Core.dll" "%TEMP_DIR%\" >nul
copy "%SOURCE_DIR%\HandBrake.Interop.dll" "%TEMP_DIR%\" >nul

:: Dépendances tierces nécessaires (seulement les essentielles)
copy "%SOURCE_DIR%\Autofac.dll" "%TEMP_DIR%\" >nul
copy "%SOURCE_DIR%\Microsoft.Xaml.Behaviors.dll" "%TEMP_DIR%\" >nul
copy "%SOURCE_DIR%\System.Drawing.Common.dll" "%TEMP_DIR%\" >nul
copy "%SOURCE_DIR%\System.Management.dll" "%TEMP_DIR%\" >nul

:: Dépendances optionnelles (copier seulement si elles existent et sont nécessaires)
if exist "%SOURCE_DIR%\GongSolutions.WPF.DragDrop.dll" copy "%SOURCE_DIR%\GongSolutions.WPF.DragDrop.dll" "%TEMP_DIR%\" >nul
if exist "%SOURCE_DIR%\Microsoft.Toolkit.Uwp.Notifications.dll" copy "%SOURCE_DIR%\Microsoft.Toolkit.Uwp.Notifications.dll" "%TEMP_DIR%\" >nul
if exist "%SOURCE_DIR%\Microsoft.Win32.SystemEvents.dll" copy "%SOURCE_DIR%\Microsoft.Win32.SystemEvents.dll" "%TEMP_DIR%\" >nul
if exist "%SOURCE_DIR%\Microsoft.Windows.SDK.NET.dll" copy "%SOURCE_DIR%\Microsoft.Windows.SDK.NET.dll" "%TEMP_DIR%\" >nul
if exist "%SOURCE_DIR%\System.CodeDom.dll" copy "%SOURCE_DIR%\System.CodeDom.dll" "%TEMP_DIR%\" >nul
if exist "%SOURCE_DIR%\System.Private.Windows.Core.dll" copy "%SOURCE_DIR%\System.Private.Windows.Core.dll" "%TEMP_DIR%\" >nul
if exist "%SOURCE_DIR%\WinRT.Runtime.dll" copy "%SOURCE_DIR%\WinRT.Runtime.dll" "%TEMP_DIR%\" >nul

:: Template pour version portable
if exist "%SOURCE_DIR%\portable.ini.template" (
    copy "%SOURCE_DIR%\portable.ini.template" "%TEMP_DIR%\" >nul
)

:: Copier les traductions (dossiers de langues)
echo Copie des traductions...
for /d %%i in ("%SOURCE_DIR%\*") do (
    set "folder=%%~nxi"
    if exist "%%i\HandBrake.resources.dll" (
        mkdir "%TEMP_DIR%\!folder!" 2>nul
        copy "%%i\HandBrake.resources.dll" "%TEMP_DIR%\!folder!\" >nul
    )
)

:: Copier le dossier runtimes si nécessaire
if exist "%SOURCE_DIR%\runtimes" (
    echo Copie des runtimes...
    xcopy "%SOURCE_DIR%\runtimes" "%TEMP_DIR%\runtimes" /e /i /q >nul
)

:: Renommer le dossier final
ren "%TEMP_DIR%" "%FINAL_DIR%"

echo.
echo Fichiers copiés dans le dossier %FINAL_DIR%:
dir "%FINAL_DIR%" /b

echo.
echo Création de l'archive 7z...

:: Créer le répertoire de destination s'il n'existe pas
for %%F in ("%ARCHIVE_PATH%") do set "DEST_DIR=%%~dpF"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

:: Supprimer l'ancienne archive si elle existe
if exist "%ARCHIVE_PATH%" del "%ARCHIVE_PATH%"

:: Créer l'archive avec compression maximale et multithreading
echo Compression en cours...
"%SEVENZIP_PATH%" a -t7z -mx=9 -mmt=on "%ARCHIVE_PATH%" "%FINAL_DIR%\*"

if errorlevel 1 (
    echo.
    echo ERREUR: Échec de la création de l'archive.
    echo Vérifiez que 7-Zip est installé et que le chemin réseau est accessible.
    echo.
    pause
    exit /b 1
)

:: Copier le script d'installation à côté de l'archive
echo Copie du script d'installation...
for %%F in ("%ARCHIVE_PATH%") do set "DEST_DIR=%%~dpF"
if exist "install_handbrake.bat" (
    copy "install_handbrake.bat" "%DEST_DIR%install_handbrake.bat" >nul
    if errorlevel 1 (
        echo ATTENTION: Impossible de copier install_handbrake.bat vers le réseau.
    ) else (
        echo Script d'installation copié: %DEST_DIR%install_handbrake.bat
    )
) else (
    echo ATTENTION: install_handbrake.bat non trouvé dans le répertoire courant.
)

echo.
echo ========================================
echo   SUCCÈS !
echo ========================================
echo Archive créée: %ARCHIVE_PATH%
echo Script d'installation: %DEST_DIR%install_handbrake.bat
echo Taille de l'archive:
for %%F in ("%ARCHIVE_PATH%") do echo   %%~zF octets
echo.
echo Nettoyage du dossier temporaire...
if exist "%FINAL_DIR%" (
    rmdir /s /q "%FINAL_DIR%"
    echo Dossier temporaire %FINAL_DIR% supprimé.
) else (
    echo Dossier temporaire déjà supprimé.
)
echo.
echo Package portable créé avec succès !
echo.
pause
