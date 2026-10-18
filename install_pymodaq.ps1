# =====================================================================
#  Installation de PyMoDAQ (Windows)
#  - crée un environnement virtuel (venv avec Python >= 3.10,
#    ou à défaut un environnement conda si conda est installé)
#  - installe pymodaq
#  - installe PySide6
#  - crée un raccourci "PyMoDAQ" sur le Bureau et dans le menu Démarrer
#
#  Usage :  double-cliquer sur install_pymodaq.bat
#      ou   powershell -ExecutionPolicy Bypass -File install_pymodaq.ps1 [-InstallDir C:\chemin] [-Conda]
#           -Conda : force l'utilisation de conda même si Python est présent
# =====================================================================
param(
    [string]$InstallDir    = (Join-Path $env:USERPROFILE "PyMoDAQ"),
    [string]$Command       = "pymodaq",   # "pymodaq" = Launcher (>= 5.2), ou "dashboard"
    [switch]$Conda,                       # force conda
    [string]$CondaPython   = "3.12"       # version de Python pour l'environnement conda
)

$ErrorActionPreference = "Stop"
$Venv   = Join-Path $InstallDir "venv"
$VenvPy = Join-Path $Venv "Scripts\python.exe"   # venv
$EnvPy  = Join-Path $Venv "python.exe"           # environnement conda (python.exe à la racine)

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

# Renvoie la commande Python (tableau) si une version >= 3.10 avec venv est disponible, sinon $null
function Find-Python {
    $candidates = @()
    if (Get-Command py -ErrorAction SilentlyContinue)     { $candidates += ,@("py", "-3") }
    if (Get-Command python -ErrorAction SilentlyContinue) { $candidates += ,@("python") }
    foreach ($c in $candidates) {
        try {
            $a = @($c | Select-Object -Skip 1)
            & $c[0] @a -c "import sys, venv, ensurepip; sys.exit(sys.version_info < (3, 10))" 2>$null
            if ($LASTEXITCODE -eq 0) { return ,$c }
        } catch { }   # ex. alias Microsoft Store sans Python réel
    }
    return $null
}

# Renvoie le chemin de conda s'il est installé, sinon $null
function Find-Conda {
    if ($env:CONDA_EXE -and (Test-Path $env:CONDA_EXE)) { return $env:CONDA_EXE }
    $cmd = Get-Command conda -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $roots = @($env:USERPROFILE, $env:LOCALAPPDATA, $env:ProgramData)
    $names = @("miniforge3", "miniconda3", "anaconda3", "mambaforge")
    foreach ($r in $roots) { foreach ($n in $names) {
        foreach ($rel in @("condabin\conda.bat", "Scripts\conda.exe")) {
            $p = Join-Path (Join-Path $r $n) $rel
            if (Test-Path $p) { return $p }
        }
    } }
    return $null
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

# --- 1. Choix de l'environnement : venv ou conda ----------------------
Step "Recherche de Python / conda"
$PyCmd    = if ($Conda) { $null } else { Find-Python }
$CondaExe = $null

if (Test-Path $EnvPy) {
    Write-Host "Environnement conda déjà présent dans $Venv, réutilisé."
    $Py = $EnvPy
}
elseif (Test-Path $VenvPy) {
    Write-Host "Environnement virtuel déjà présent dans $Venv, réutilisé."
    $Py = $VenvPy
}
elseif ($PyCmd) {
    $a = @($PyCmd | Select-Object -Skip 1)
    $ver = & $PyCmd[0] @a -c "import sys; print('%d.%d' % sys.version_info[:2])"
    Step "Python $ver trouvé : création de l'environnement virtuel dans $Venv"
    & $PyCmd[0] @a -m venv $Venv
    if ($LASTEXITCODE -ne 0) { throw "Échec de la création de l'environnement virtuel." }
    $Py = $VenvPy
}
else {
    $CondaExe = Find-Conda
    if (-not $CondaExe) {
        throw "Ni Python >= 3.10 ni conda n'ont été trouvés. Installez Python (https://www.python.org, cocher 'Add to PATH') ou Miniforge/Miniconda."
    }
    Step "Conda trouvé ($CondaExe) : création de l'environnement conda (Python $CondaPython) dans $Venv"
    & $CondaExe create -y -p $Venv "python=$CondaPython" pip -c conda-forge --override-channels
    if ($LASTEXITCODE -ne 0) { throw "Échec de la création de l'environnement conda." }
    $Py = $EnvPy
}

& $Py -m pip install --upgrade pip wheel setuptools
if ($LASTEXITCODE -ne 0) { throw "Échec de la mise à jour de pip." }

# --- 2. PyMoDAQ + PySide6 ---------------------------------------------
Step "Installation de pymodaq"
& $Py -m pip install pymodaq
if ($LASTEXITCODE -ne 0) { throw "Échec de l'installation de pymodaq." }

Step "Installation de PySide6"
& $Py -m pip install pyside6
if ($LASTEXITCODE -ne 0) { throw "Échec de l'installation de PySide6." }

# Avec venv comme avec conda, les exécutables pip sont dans Scripts\
$Exe = Join-Path $Venv "Scripts\$Command.exe"
if (-not (Test-Path $Exe)) { throw "La commande '$Command' est introuvable dans l'environnement ($Exe)." }

# --- 3. Icône fournie par le paquet pymodaq ---------------------------
$Icon = Join-Path $Venv "Lib\site-packages\pymodaq\icon.ico"
if (-not (Test-Path $Icon)) {
    Write-Warning "Icône introuvable ($Icon), icône par défaut utilisée."
    $Icon = $null
}

# --- 4. Raccourcis ----------------------------------------------------
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
