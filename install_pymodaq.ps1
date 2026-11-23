# =====================================================================
#  Installation de PyMoDAQ (Windows)
#  - crée un environnement : conda si conda est installé,
#    sinon un venv avec Python >= 3.10
#  - installe ou met à jour pymodaq et PySide6 (pymodaq[pyside6])
#  - crée un raccourci "PyMoDAQ" sur le Bureau et dans le menu Démarrer
#
#  Usage :  double-cliquer sur install_pymodaq.exe (généré par PS2EXE) ou install_pymodaq.bat
#      ou   powershell -ExecutionPolicy Bypass -File install_pymodaq.ps1 [-InstallDir C:\chemin] [-NoConda]
#           -NoConda : ignore conda et utilise un venv avec Python
# =====================================================================
param(
    [string]$InstallDir    = (Join-Path $env:USERPROFILE "PyMoDAQ"),
    [string]$Command       = "pymodaq",   # "pymodaq" = Launcher (>= 5.2), ou "dashboard"
    [switch]$NoConda,                     # ignore conda, utilise un venv
    [string]$CondaPython   = "3.14"       # version de Python pour l'environnement conda
)

$ErrorActionPreference = "Continue"
$Venv   = Join-Path $InstallDir "PmD-auto-install"
$VenvPy = Join-Path $Venv "Scripts\python.exe"   # venv
$EnvPy  = Join-Path $Venv "python.exe"           # environnement conda (python.exe à la racine)

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

# Ajout d'une pause si c'est un exe
$IsExe = [Diagnostics.Process]::GetCurrentProcess().ProcessName -notin @("powershell", "pwsh")
function Wait-Close {
    if ($IsExe) { Write-Host ""; Read-Host "Appuyez sur Entrée pour fermer cette fenêtre" | Out-Null }
}

# Toute erreur non gérée : message lisible, pause, puis sortie en échec
trap {
    Write-Host "`nL'installation a échoué :" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Wait-Close
    exit 1
}

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

# Désactive l'avertissement « A newer version of conda exists » s'il est actif

function Disable-CondaUpdateNotice($conda) {
    try {
        $cfg = (& $conda config --show notify_outdated_conda) -join "`n"
        if ($cfg -match 'notify_outdated_conda:\s*True') {
            Write-Host "Désactivation de l'avertissement de mise à jour de conda (notify_outdated_conda = false)."
            & $conda config --set notify_outdated_conda false
            if ($LASTEXITCODE -ne 0) { Write-Warning "Impossible de modifier notify_outdated_conda." }
        }
    } catch {
        Write-Warning "Impossible de lire la configuration de conda : $($_.Exception.Message)"
    }
}

New-Item -ItemType Directory -Force -Path $InstallDir -ErrorAction Stop | Out-Null

# --- 1. Choix de l'environnement : conda, sinon venv ------------------
Step "Recherche de conda / Python"
$CondaExe = if ($NoConda) { $null } else { Find-Conda }

if (Test-Path $EnvPy) {
    Write-Host "Environnement conda déjà présent dans $Venv, réutilisé."
    $Py = $EnvPy
}
elseif (Test-Path $VenvPy) {
    Write-Host "Environnement virtuel déjà présent dans $Venv, réutilisé."
    $Py = $VenvPy
}
elseif ($CondaExe) {
    Step "Conda trouvé ($CondaExe) : création de l'environnement conda (Python $CondaPython) dans $Venv"
    Disable-CondaUpdateNotice $CondaExe
    & $CondaExe create -y -p $Venv "python=$CondaPython" pip -c conda-forge --override-channels
    if ($LASTEXITCODE -ne 0) { throw "Échec de la création de l'environnement conda." }
    $Py = $EnvPy
}
else {
    $PyCmd = Find-Python
    if (-not $PyCmd) {
        throw "Ni conda ni Python >= 3.10 n'ont été trouvés. Installez Miniforge/Miniconda ou Python (https://www.python.org, cocher 'Add to PATH')."
    }
    $a = @($PyCmd | Select-Object -Skip 1)
    $ver = & $PyCmd[0] @a -c "import sys; print('%d.%d' % sys.version_info[:2])"
    Step "Conda absent, Python $ver trouvé : création de l'environnement virtuel dans $Venv"
    & $PyCmd[0] @a -m venv $Venv
    if ($LASTEXITCODE -ne 0) { throw "Échec de la création de l'environnement virtuel." }
    $Py = $VenvPy
}

# --- Activation de l'environnement (pour ce processus uniquement) -------
# Équivalent de "activate" : les dossiers de l'environnement passent en tête du PATH,
# ce qui évite les erreurs « script ... is not on PATH » de pip.
# Fait à la main plutôt qu'avec Activate.ps1 : marche pour venv et conda,
# sans dépendre de la politique d'exécution PowerShell.
Step "Activation de l'environnement $Venv"
if ($Py -eq $EnvPy) {
    # Environnement conda : mêmes dossiers que "conda activate"
    $envPaths = @($Venv,
                  (Join-Path $Venv "Library\mingw-w64\bin"),
                  (Join-Path $Venv "Library\usr\bin"),
                  (Join-Path $Venv "Library\bin"),
                  (Join-Path $Venv "Scripts"),
                  (Join-Path $Venv "bin"))
    $env:CONDA_PREFIX = $Venv
} else {
    $envPaths = @(Join-Path $Venv "Scripts")
    $env:VIRTUAL_ENV = $Venv
}
$env:PATH = ($envPaths -join ";") + ";" + $env:PATH

# --no-warn-script-location : évite les avertissements « not on PATH » pour les exécutables du venv
& $Py -m pip install --upgrade --no-warn-script-location pip wheel setuptools
if ($LASTEXITCODE -ne 0) { Write-Warning "Échec de la mise à jour de pip : l'installation continue avec la version actuelle." }

# --- 2. PyMoDAQ + PySide6 ---------------------------------------------

Step "Installation de pymodaq et PySide6"
& $Py -m pip install --upgrade --no-warn-script-location "pymodaq[pyside6]"
if ($LASTEXITCODE -ne 0) { throw "Échec de l'installation de pymodaq / PySide6." }
$PmdVer = & $Py -c "import importlib.metadata as m; print(m.version('pymodaq'))"
Write-Host "pymodaq $PmdVer installé."

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
    try {
        $lnk = $Shell.CreateShortcut($lnkPath)
        $lnk.TargetPath       = $Exe
        $lnk.WorkingDirectory = $InstallDir
        $lnk.Description      = "Lancer PyMoDAQ"
        if ($Icon) { $lnk.IconLocation = "$Icon,0" }
        $lnk.Save()
        Write-Host "  $lnkPath"
    } catch {
        Write-Warning "Raccourci non créé ($lnkPath) : $($_.Exception.Message)"
    }
}

Write-Host "`nInstallation terminée. Lancez PyMoDAQ depuis l'icône du Bureau." -ForegroundColor Green
Wait-Close
