@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   HandBrake Installation Automatique
echo ========================================
echo.

:: Configuration
set "ARCHIVE_PATH=\\cluster2019fs\install\_Programmes\Handbrake\Handbrake.7z"
set "INSTALL_DIR=C:\Program Files\HandBrake"
set "SEVENZIP_PATH=C:\Program Files\7-Zip\7z.exe"
set "TEMP_EXTRACT=%TEMP%\HandBrake_Install"

:: ========================================
:: Désinstallation de l'installation existante
:: ========================================
echo Vérification d'une installation HandBrake existante...

:: Vérifier s'il y a une installation existante
set "UNINSTALL_FOUND=0"
set "UNINSTALL_PATH="

:: 1. Chercher le désinstalleur officiel HandBrake
if exist "C:\Program Files\HandBrake\uninst.exe" (
    set "UNINSTALL_PATH=C:\Program Files\HandBrake\uninst.exe"
    set "UNINSTALL_FOUND=1"
    echo Installation HandBrake officielle détectée.
)

:: 2. Chercher notre désinstalleur custom
if exist "C:\Program Files\HandBrake\uninstall.bat" (
    set "UNINSTALL_PATH=C:\Program Files\HandBrake\uninstall.bat"
    set "UNINSTALL_FOUND=1"
    echo Installation HandBrake custom détectée.
)

:: 3. Vérifier dans le registre
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\HandBrake" >nul 2>&1
if %errorlevel% equ 0 (
    echo Installation HandBrake trouvée dans le registre.
    set "UNINSTALL_FOUND=1"

    :: Essayer de récupérer le chemin de désinstallation depuis le registre
    for /f "tokens=2*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\HandBrake" /v UninstallString 2^>nul') do (
        set "REG_UNINSTALL=%%B"
        if exist "!REG_UNINSTALL!" (
            set "UNINSTALL_PATH=!REG_UNINSTALL!"
        )
    )
)

:: Exécuter la désinstallation si trouvée
if %UNINSTALL_FOUND% equ 1 (
    echo.
    echo Désinstallation de l'installation existante...

    if not "%UNINSTALL_PATH%"=="" (
        if exist "%UNINSTALL_PATH%" (
            echo Exécution du désinstalleur: %UNINSTALL_PATH%

            :: Déterminer le type de désinstalleur
            echo %UNINSTALL_PATH% | find /i "uninst.exe" >nul
            if %errorlevel% equ 0 (
                :: Désinstalleur officiel NSIS - mode silencieux
                "%UNINSTALL_PATH%" /S
            ) else (
                :: Notre script batch custom
                call "%UNINSTALL_PATH%"
            )

            :: Attendre un peu pour que la désinstallation se termine
            timeout /t 3 /nobreak >nul
        )
    )

    :: Nettoyage manuel des restes
    echo Nettoyage des restes...

    :: Supprimer le dossier d'installation s'il existe encore
    if exist "%INSTALL_DIR%" (
        echo Suppression du dossier d'installation restant...
        rmdir /s /q "%INSTALL_DIR%" >nul 2>&1
    )

    :: Nettoyer le registre
    reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\HandBrake" /f >nul 2>&1

    :: Supprimer le raccourci bureau s'il existe
    if exist "%USERPROFILE%\Desktop\HandBrake.lnk" (
        del "%USERPROFILE%\Desktop\HandBrake.lnk" >nul 2>&1
    )

    :: Supprimer du menu démarrer (installation officielle)
    if exist "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\HandBrake" (
        rmdir /s /q "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\HandBrake" >nul 2>&1
    )

    echo Désinstallation terminée.
    echo.
) else (
    echo Aucune installation HandBrake existante détectée.
    echo.
)

:: Vérifier que l'archive existe
if not exist "%ARCHIVE_PATH%" (
    echo ERREUR: L'archive %ARCHIVE_PATH% n'existe pas.
    echo Veuillez d'abord exécuter create_portable.bat
    pause
    exit /b 1
)

:: Vérifier que 7-Zip est installé
if not exist "%SEVENZIP_PATH%" (
    echo ERREUR: 7-Zip n'est pas installé dans %SEVENZIP_PATH%
    echo Veuillez installer 7-Zip ou modifier le chemin dans le script.
    pause
    exit /b 1
)

echo Vérification des privilèges administrateur...

:: Vérifier si on a les droits admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo Ce script nécessite des privilèges administrateur pour:
    echo - Extraire dans C:\Program Files\HandBrake
    echo - Créer les entrées de registre système
    echo.
    echo Relancement avec privilèges administrateur...
    
    :: Relancer avec UAC
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b 0
)

echo Privilèges administrateur confirmés.
echo.

:: Nettoyer le dossier temporaire
if exist "%TEMP_EXTRACT%" rmdir /s /q "%TEMP_EXTRACT%"
mkdir "%TEMP_EXTRACT%"

echo Extraction de l'archive...
"%SEVENZIP_PATH%" x "%ARCHIVE_PATH%" -o"%TEMP_EXTRACT%" -y

if %errorlevel% neq 0 (
    echo ERREUR: Échec de l'extraction de l'archive.
    pause
    exit /b 1
)

:: Trouver le dossier HandBrake extrait
set "SOURCE_FOLDER="
for /d %%i in ("%TEMP_EXTRACT%\*") do (
    if exist "%%i\HandBrake.exe" (
        set "SOURCE_FOLDER=%%i"
        goto :found_folder
    )
)

:found_folder
if "%SOURCE_FOLDER%"=="" (
    echo ERREUR: Impossible de trouver le dossier HandBrake dans l'archive.
    pause
    exit /b 1
)

echo Installation dans %INSTALL_DIR%...

:: Supprimer l'ancienne installation si elle existe
if exist "%INSTALL_DIR%" (
    echo Suppression de l'ancienne installation...
    rmdir /s /q "%INSTALL_DIR%"
)

:: Créer le dossier d'installation
mkdir "%INSTALL_DIR%"

:: Copier tous les fichiers
xcopy "%SOURCE_FOLDER%\*" "%INSTALL_DIR%\" /e /i /y /q

if %errorlevel% neq 0 (
    echo ERREUR: Échec de la copie des fichiers.
    pause
    exit /b 1
)

echo Installation terminée.
echo.

:: Nettoyer le dossier temporaire
rmdir /s /q "%TEMP_EXTRACT%"

echo Création du raccourci sur le bureau...

:: Revenir en mode utilisateur pour créer le raccourci
:: Utiliser PowerShell pour créer le raccourci en tant qu'utilisateur actuel
powershell -Command "& {$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\HandBrake.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\HandBrake.exe'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.Description = 'HandBrake Video Transcoder'; $Shortcut.Save()}"

echo.
echo Enregistrement dans le registre...

:: Ajouter HandBrake dans la liste des programmes installés
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\HandBrake" /v "DisplayName" /t REG_SZ /d "HandBrake" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\HandBrake" /v "DisplayVersion" /t REG_SZ /d "1.9.0 Custom" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\HandBrake" /v "Publisher" /t REG_SZ /d "HandBrake Team" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\HandBrake" /v "InstallLocation" /t REG_SZ /d "%INSTALL_DIR%" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\HandBrake" /v "DisplayIcon" /t REG_SZ /d "%INSTALL_DIR%\HandBrake.exe" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\HandBrake" /v "UninstallString" /t REG_SZ /d "%INSTALL_DIR%\uninstall.bat" /f >nul

:: Ajouter au PATH système (optionnel)
echo Ajout au PATH système...
for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do set "CURRENT_PATH=%%B"
echo !CURRENT_PATH! | find /i "%INSTALL_DIR%" >nul
if %errorlevel% neq 0 (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH /t REG_EXPAND_SZ /d "!CURRENT_PATH!;%INSTALL_DIR%" /f >nul
    echo HandBrake ajouté au PATH système.
)

:: Créer un script de désinstallation
echo @echo off > "%INSTALL_DIR%\uninstall.bat"
echo echo Désinstallation de HandBrake... >> "%INSTALL_DIR%\uninstall.bat"
echo rmdir /s /q "%INSTALL_DIR%" >> "%INSTALL_DIR%\uninstall.bat"
echo reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\HandBrake" /f ^>nul 2^>^&1 >> "%INSTALL_DIR%\uninstall.bat"
echo del "%%USERPROFILE%%\Desktop\HandBrake.lnk" ^>nul 2^>^&1 >> "%INSTALL_DIR%\uninstall.bat"
echo echo HandBrake désinstallé. >> "%INSTALL_DIR%\uninstall.bat"
echo pause >> "%INSTALL_DIR%\uninstall.bat"

echo.
echo ========================================
echo   INSTALLATION TERMINÉE !
echo ========================================
echo.
echo HandBrake a été installé dans: %INSTALL_DIR%
echo Raccourci créé sur le bureau: HandBrake.lnk
echo Enregistré dans le registre Windows
echo.
echo Vous pouvez maintenant utiliser HandBrake !
echo.
echo Appuyez sur une touche pour continuer...
pause >nul
exit /b 0
