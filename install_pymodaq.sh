#!/usr/bin/env bash
# =====================================================================
#  Installation de PyMoDAQ (Linux)
#  - crée un environnement virtuel (venv avec Python >= 3.10,
#    ou à défaut un environnement conda si conda est installé)
#  - installe pymodaq
#  - installe PySide6
#  - crée une icône "PyMoDAQ" (menu des applications + Bureau)
#
#  Usage :  bash install_pymodaq.sh [dossier_d_installation]
#  Variables optionnelles :
#    PYMODAQ_CMD=dashboard        (par défaut : pymodaq = Launcher)
#    PYMODAQ_CONDA=1              (forcer conda)
#    PYMODAQ_CONDA_PYTHON=3.12    (version de Python de l'environnement conda)
# =====================================================================
set -euo pipefail

INSTALL_DIR="${1:-$HOME/PyMoDAQ}"
CMD="${PYMODAQ_CMD:-pymodaq}"
USE_CONDA="${PYMODAQ_CONDA:-0}"          # 1 = forcer conda même si Python est présent
CONDA_PYTHON="${PYMODAQ_CONDA_PYTHON:-3.12}"
VENV="$INSTALL_DIR/venv"
VPY="$VENV/bin/python"

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

# Python >= 3.10 avec venv disponible ?
find_python() {
  local p
  p="$(command -v python3 || true)"
  [ -n "$p" ] && "$p" -c 'import sys, venv, ensurepip; sys.exit(sys.version_info < (3, 10))' 2>/dev/null \
    && echo "$p"
}

# conda installé ?
find_conda() {
  if [ -n "${CONDA_EXE:-}" ] && [ -x "$CONDA_EXE" ]; then echo "$CONDA_EXE"; return; fi
  if command -v conda >/dev/null 2>&1; then command -v conda; return; fi
  local d
  for d in miniforge3 miniconda3 anaconda3 mambaforge; do
    for base in "$HOME" /opt; do
      [ -x "$base/$d/bin/conda" ] && { echo "$base/$d/bin/conda"; return; }
    done
  done
}

# --- 1. Environnement : venv ou, à défaut, conda ----------------------
step "Recherche de Python / conda"
mkdir -p "$INSTALL_DIR"

if [ -x "$VPY" ]; then
  echo "Environnement déjà présent dans $VENV, réutilisé."
else
  PY=""
  [ "$USE_CONDA" = 1 ] || PY="$(find_python || true)"
  if [ -n "$PY" ]; then
    step "$("$PY" --version) trouvé : création de l'environnement virtuel dans $VENV"
    "$PY" -m venv "$VENV"
  else
    CONDA="$(find_conda || true)"
    if [ -z "$CONDA" ]; then
      echo "Ni Python >= 3.10 (avec venv) ni conda n'ont été trouvés."
      echo "Installez python3 et python3-venv (ex. sudo apt install python3 python3-venv) ou Miniforge."
      exit 1
    fi
    step "Conda trouvé ($CONDA) : création de l'environnement conda (Python $CONDA_PYTHON) dans $VENV"
    "$CONDA" create -y -p "$VENV" "python=$CONDA_PYTHON" pip -c conda-forge --override-channels
  fi
fi

"$VPY" -m pip install --upgrade pip wheel setuptools

# --- 2. PyMoDAQ + PySide6 -------------------------------------------
step "Installation de pymodaq"
"$VPY" -m pip install pymodaq

step "Installation de PySide6"
"$VPY" -m pip install pyside6

EXE="$VENV/bin/$CMD"
[ -x "$EXE" ] || { echo "Commande '$CMD' introuvable dans l'environnement ($EXE)"; exit 1; }

# Dossier de configuration système attendu par PyMoDAQ (non bloquant)
if [ ! -d /etc/.pymodaq ]; then
  step "Création de /etc/.pymodaq (mot de passe sudo demandé)"
  sudo mkdir -p /etc/.pymodaq && sudo chmod uo+rw /etc/.pymodaq \
    || echo "Impossible de créer /etc/.pymodaq, à faire manuellement."
fi

# --- 4. Icône fournie par le paquet pymodaq ---------------------------
SITE="$("$VPY" -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')"
ICON="$SITE/pymodaq/icon.ico"
if [ ! -f "$ICON" ]; then
  echo "Icône introuvable ($ICON), icône par défaut utilisée."
  ICON="applications-science"
fi

# --- 5. Lanceur .desktop ---------------------------------------------
step "Création de l'icône de lancement"
APPS="$HOME/.local/share/applications"
mkdir -p "$APPS"
DESKTOP_FILE="$APPS/pymodaq.desktop"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=PyMoDAQ
Comment=Lancer PyMoDAQ
Exec="$EXE"
Path=$INSTALL_DIR
Icon=$ICON
Terminal=false
Categories=Science;Education;
EOF
chmod +x "$DESKTOP_FILE"
echo "  $DESKTOP_FILE"

DESK_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
if [ -d "$DESK_DIR" ]; then
  cp "$DESKTOP_FILE" "$DESK_DIR/PyMoDAQ.desktop"
  chmod +x "$DESK_DIR/PyMoDAQ.desktop"
  gio set "$DESK_DIR/PyMoDAQ.desktop" metadata::trusted true 2>/dev/null || true
  echo "  $DESK_DIR/PyMoDAQ.desktop"
fi
command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" || true

printf '\n\033[1;32mInstallation terminée. Lancez PyMoDAQ depuis le menu ou le Bureau.\033[0m\n'
