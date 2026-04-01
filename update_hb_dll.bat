@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   HandBrake hb.dll Auto-Updater
echo ========================================
echo.

:: Configuration
set "TARGET_DLL=win\CS\HandBrakeWPF\bin\Release\hb.dll"
set "TEMP_DIR=%TEMP%\HandBrake_HB_Update"
set "GITHUB_API=https://api.github.com/repos/HandBrake/HandBrake-snapshots/releases"
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

:: Vérifier que PowerShell est disponible
powershell -Command "Write-Host 'PowerShell OK'" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERREUR: PowerShell n'est pas disponible.
    echo.
    pause >nul
    exit /b 1
)

echo Recherche de la dernière version LibHB sur GitHub...
echo.

:: Nettoyer le dossier temporaire
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"

:: Créer un script PowerShell temporaire
echo $ErrorActionPreference = 'Stop' > "%TEMP_DIR%\github_api.ps1"
echo try { >> "%TEMP_DIR%\github_api.ps1"
echo     Write-Host 'Connexion à GitHub API...' >> "%TEMP_DIR%\github_api.ps1"
echo     $releases = Invoke-RestMethod -Uri '%GITHUB_API%' -Headers @{'User-Agent'='HandBrake-Updater'} >> "%TEMP_DIR%\github_api.ps1"
echo     Write-Host 'Recherche de LibHB-*-win-x86_64.zip...' >> "%TEMP_DIR%\github_api.ps1"
echo     $downloadUrl = $null >> "%TEMP_DIR%\github_api.ps1"
echo     foreach ($release in $releases) { >> "%TEMP_DIR%\github_api.ps1"
echo         foreach ($asset in $release.assets) { >> "%TEMP_DIR%\github_api.ps1"
echo             if ($asset.name -match 'LibHB-.*-win-x86_64\.zip') { >> "%TEMP_DIR%\github_api.ps1"
echo                 $downloadUrl = $asset.browser_download_url >> "%TEMP_DIR%\github_api.ps1"
echo                 $fileName = $asset.name >> "%TEMP_DIR%\github_api.ps1"
echo                 $releaseTag = $release.tag_name >> "%TEMP_DIR%\github_api.ps1"
echo                 Write-Host "Trouvé: $fileName" >> "%TEMP_DIR%\github_api.ps1"
echo                 Write-Host "Version: $releaseTag" >> "%TEMP_DIR%\github_api.ps1"
echo                 Write-Host "URL: $downloadUrl" >> "%TEMP_DIR%\github_api.ps1"
echo                 break >> "%TEMP_DIR%\github_api.ps1"
echo             } >> "%TEMP_DIR%\github_api.ps1"
echo         } >> "%TEMP_DIR%\github_api.ps1"
echo         if ($downloadUrl) { break } >> "%TEMP_DIR%\github_api.ps1"
echo     } >> "%TEMP_DIR%\github_api.ps1"
echo     if (-not $downloadUrl) { >> "%TEMP_DIR%\github_api.ps1"
echo         Write-Host 'ERREUR: Aucun fichier LibHB-*-win-x86_64.zip trouvé' >> "%TEMP_DIR%\github_api.ps1"
echo         exit 1 >> "%TEMP_DIR%\github_api.ps1"
echo     } >> "%TEMP_DIR%\github_api.ps1"
echo     $downloadUrl ^| Out-File -FilePath '%TEMP_DIR%\download_url.txt' -Encoding ASCII >> "%TEMP_DIR%\github_api.ps1"
echo     $fileName ^| Out-File -FilePath '%TEMP_DIR%\filename.txt' -Encoding ASCII >> "%TEMP_DIR%\github_api.ps1"
echo     $releaseTag ^| Out-File -FilePath '%TEMP_DIR%\version.txt' -Encoding ASCII >> "%TEMP_DIR%\github_api.ps1"
echo     Write-Host 'Informations sauvegardées.' >> "%TEMP_DIR%\github_api.ps1"
echo } catch { >> "%TEMP_DIR%\github_api.ps1"
echo     Write-Host "ERREUR lors de la récupération des informations GitHub: $($_.Exception.Message)" >> "%TEMP_DIR%\github_api.ps1"
echo     exit 1 >> "%TEMP_DIR%\github_api.ps1"
echo } >> "%TEMP_DIR%\github_api.ps1"

:: Exécuter le script PowerShell
powershell -ExecutionPolicy Bypass -File "%TEMP_DIR%\github_api.ps1"

if %errorlevel% neq 0 (
    echo.
    echo Échec de la récupération des informations GitHub.
    echo Vérifiez votre connexion internet.
    echo.
    pause
    exit /b 1
)

:: Lire les informations sauvegardées
if not exist "%TEMP_DIR%\download_url.txt" (
    echo ERREUR: URL de téléchargement non trouvée.
    pause
    exit /b 1
)

set /p DOWNLOAD_URL=<"%TEMP_DIR%\download_url.txt"
set /p FILENAME=<"%TEMP_DIR%\filename.txt"
set /p VERSION=<"%TEMP_DIR%\version.txt"

echo.
echo ========================================
echo   Téléchargement
echo ========================================
echo Version: %VERSION%
echo Fichier: %FILENAME%
echo.

:: Télécharger le fichier
echo Téléchargement en cours...

:: Créer un script PowerShell pour le téléchargement
echo $ErrorActionPreference = 'Stop' > "%TEMP_DIR%\download.ps1"
echo try { >> "%TEMP_DIR%\download.ps1"
echo     $ProgressPreference = 'SilentlyContinue' >> "%TEMP_DIR%\download.ps1"
echo     Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TEMP_DIR%\%FILENAME%' -UserAgent 'HandBrake-Updater' >> "%TEMP_DIR%\download.ps1"
echo     Write-Host 'Téléchargement terminé.' >> "%TEMP_DIR%\download.ps1"
echo } catch { >> "%TEMP_DIR%\download.ps1"
echo     Write-Host "ERREUR lors du téléchargement: $($_.Exception.Message)" >> "%TEMP_DIR%\download.ps1"
echo     exit 1 >> "%TEMP_DIR%\download.ps1"
echo } >> "%TEMP_DIR%\download.ps1"

powershell -ExecutionPolicy Bypass -File "%TEMP_DIR%\download.ps1"

if %errorlevel% neq 0 (
    echo.
    echo Échec du téléchargement.
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   Extraction et Installation
echo ========================================
echo.

:: Vérifier que le fichier a été téléchargé
if not exist "%TEMP_DIR%\%FILENAME%" (
    echo ERREUR: Le fichier téléchargé n'existe pas.
    pause
    exit /b 1
)

echo Extraction de l'archive...
"%SEVENZIP_PATH%" x "%TEMP_DIR%\%FILENAME%" -o"%TEMP_DIR%\extracted" -y >nul 2>&1

if %errorlevel% neq 0 (
    echo ERREUR: Échec de l'extraction de l'archive.
    pause
    exit /b 1
)

:: Chercher hb.dll dans l'archive extraite
echo Recherche de hb.dll...
set "HB_DLL_FOUND="
for /r "%TEMP_DIR%\extracted" %%f in (hb.dll) do (
    set "HB_DLL_FOUND=%%f"
    goto :found_dll
)

:found_dll
if "%HB_DLL_FOUND%"=="" (
    echo ERREUR: hb.dll non trouvé dans l'archive.
    echo Contenu de l'archive:
    dir "%TEMP_DIR%\extracted" /s /b
    echo.
    pause
    exit /b 1
)

echo hb.dll trouvé: %HB_DLL_FOUND%

:: Sauvegarder l'ancienne version
if exist "%TARGET_DLL%" (
    echo Sauvegarde de l'ancienne version...
    copy "%TARGET_DLL%" "%TARGET_DLL%.backup" >nul
    echo Ancienne version sauvegardée: %TARGET_DLL%.backup
)

:: Copier la nouvelle version
echo Installation de la nouvelle version...
copy "%HB_DLL_FOUND%" "%TARGET_DLL%" >nul

if %errorlevel% neq 0 (
    echo ERREUR: Échec de la copie de hb.dll.
    if exist "%TARGET_DLL%.backup" (
        echo Restauration de l'ancienne version...
        copy "%TARGET_DLL%.backup" "%TARGET_DLL%" >nul
    )
    pause
    exit /b 1
)

:: Vérifier la nouvelle version
echo.
echo Vérification de la nouvelle version...
if exist "%TARGET_DLL%" (
    for %%F in ("%TARGET_DLL%") do (
        echo Taille: %%~zF octets
        echo Date: %%~tF
    )
) else (
    echo ERREUR: Le fichier cible n'existe pas après la copie.
    pause
    exit /b 1
)

:: Nettoyage
echo.
echo Nettoyage des fichiers temporaires...
rmdir /s /q "%TEMP_DIR%"

echo.
echo ========================================
echo   SUCCÈS !
echo ========================================
echo hb.dll mis à jour vers la version %VERSION%
echo Fichier: %TARGET_DLL%
echo.
echo IMPORTANT: Recompilez HandBrake pour utiliser la nouvelle version.
echo.
echo Appuyez sur une touche pour continuer...
pause >nul
