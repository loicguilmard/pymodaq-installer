# =====================================================================
#  Installation de PyMoDAQ (Windows)
#  - crée un environnement virtuel
#  - installe les requirements (ou pymodaq si pas de requirements.txt)
#  - installe PySide6
#  - crée un raccourci "PyMoDAQ" sur le Bureau et dans le menu Démarrer
#
#  Usage :  double-cliquer sur install_pymodaq.bat
#      ou   powershell -ExecutionPolicy Bypass -File install_pymodaq.ps1 [-InstallDir C:\chemin]
# =====================================================================
param(
    [string]$InstallDir = (Join-Path $env:USERPROFILE "PyMoDAQ"),
    [string]$Command    = "pymodaq"   # "pymodaq" = Launcher (>= 5.2), ou "dashboard"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Venv      = Join-Path $InstallDir "venv"
$VenvPy    = Join-Path $Venv "Scripts\python.exe"

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

# --- 1. Trouver Python (>= 3.10) ------------------------------------
Step "Recherche de Python"
$PyCmd = $null
if (Get-Command py -ErrorAction SilentlyContinue)         { $PyCmd = @("py", "-3") }
elseif (Get-Command python -ErrorAction SilentlyContinue) { $PyCmd = @("python") }
else { throw "Python est introuvable. Installez-le depuis https://www.python.org (cocher 'Add to PATH')." }

$exe  = $PyCmd[0]
$args0 = @($PyCmd | Select-Object -Skip 1)
$ver = & $exe @args0 -c "import sys; print('%d.%d' % sys.version_info[:2])"
if ([version]$ver -lt [version]"3.10") { throw "Python $ver détecté : PyMoDAQ nécessite Python 3.10 ou plus." }
Write-Host "Python $ver trouvé."

# --- 2. Environnement virtuel ---------------------------------------
Step "Création de l'environnement virtuel dans $Venv"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
if (-not (Test-Path $VenvPy)) { & $exe @args0 -m venv $Venv }
else { Write-Host "Environnement déjà présent, réutilisé." }

& $VenvPy -m pip install --upgrade pip wheel setuptools
if ($LASTEXITCODE -ne 0) { throw "Échec de la mise à jour de pip." }

# --- 3. Requirements + PySide6 --------------------------------------
$Req = Join-Path $ScriptDir "requirements.txt"
if (Test-Path $Req) {
    Step "Installation des requirements ($Req)"
    & $VenvPy -m pip install -r $Req
} else {
    Step "Pas de requirements.txt : installation de pymodaq"
    & $VenvPy -m pip install pymodaq
}
if ($LASTEXITCODE -ne 0) { throw "Échec de l'installation des dépendances." }

Step "Installation de PySide6"
& $VenvPy -m pip install pyside6
if ($LASTEXITCODE -ne 0) { throw "Échec de l'installation de PySide6." }

$Exe = Join-Path $Venv "Scripts\$Command.exe"
if (-not (Test-Path $Exe)) { throw "La commande '$Command' est introuvable dans l'environnement ($Exe)." }

# --- 4. Icône : on cherche un .ico fourni par les paquets pymodaq ----
#Step "Recherche d'une icône PyMoDAQ"
#$findIcon = @'
#import sysconfig, pathlib
#site = pathlib.Path(sysconfig.get_paths()["purelib"])
#hits = [p for d in site.glob("pymodaq*") if d.is_dir()
#          for p in d.rglob("*.ico") if "pymodaq" in p.name.lower()]
#print(hits[0] if hits else "")
#'@
#$Icon = (& $VenvPy -c $findIcon).Trim()
#if ($Icon) { Write-Host "Icône : $Icon" } else { Write-Host "Aucune icône trouvée, icône par défaut #utilisée." }

# --- 5. Raccourcis ---------------------------------------------------
Step "Création des raccourcis"
$Shell = New-Object -ComObject WScript.Shell
$targets = @(
    (Join-Path ([Environment]::GetFolderPath("Desktop")) "PyMoDAQ.lnk"),
    (Join-Path ([Environment]::GetFolderPath("Programs")) "PyMoDAQ.lnk")
)
foreach ($lnkPath in $targets) {
    $lnk = $Shell.CreateShortcut($lnkPath)
    $lnk.TargetPath       = $Exe
    $lnk.WorkingDirectory = $InstallDir
    $lnk.Description      = "Lancer PyMoDAQ"
    if ($Icon) { $lnk.IconLocation = "$Icon,0" }
    $lnk.Save()
    Write-Host "  $lnkPath"
}

Write-Host "`nInstallation terminée. Lancez PyMoDAQ depuis l'icône du Bureau." -ForegroundColor Green
