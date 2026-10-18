#!/usr/bin/env bash
# =====================================================================
#  Installation de PyMoDAQ (Linux)
#  - crée un environnement virtuel
#  - installe les requirements (ou pymodaq si pas de requirements.txt)
#  - installe PySide6
#  - crée une icône "PyMoDAQ" (menu des applications + Bureau)
#
#  Usage :  bash install_pymodaq.sh [dossier_d_installation]
#  Variable optionnelle : PYMODAQ_CMD=dashboard  (par défaut : pymodaq = Launcher)
# =====================================================================
set -euo pipefail

INSTALL_DIR="${1:-$HOME/PyMoDAQ}"
CMD="${PYMODAQ_CMD:-pymodaq}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV="$INSTALL_DIR/venv"
VPY="$VENV/bin/python"

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

# --- 1. Python >= 3.10 ----------------------------------------------
step "Recherche de Python"
PY="$(command -v python3 || true)"
[ -n "$PY" ] || { echo "python3 introuvable (sudo apt install python3 python3-venv)"; exit 1; }
"$PY" -c 'import sys; sys.exit(sys.version_info < (3, 10))' \
  || { echo "PyMoDAQ nécessite Python >= 3.10 ($("$PY" --version) détecté)"; exit 1; }
"$PY" -c 'import venv, ensurepip' 2>/dev/null \
  || { echo "Module venv manquant : sudo apt install python3-venv"; exit 1; }
echo "$("$PY" --version) trouvé."

# --- 2. Environnement virtuel ---------------------------------------
step "Création de l'environnement virtuel dans $VENV"
mkdir -p "$INSTALL_DIR"
[ -x "$VPY" ] || "$PY" -m venv "$VENV"
"$VPY" -m pip install --upgrade pip wheel setuptools

# --- 3. Requirements + PySide6 --------------------------------------
if [ -f "$SCRIPT_DIR/requirements.txt" ]; then
  step "Installation des requirements ($SCRIPT_DIR/requirements.txt)"
  "$VPY" -m pip install -r "$SCRIPT_DIR/requirements.txt"
else
  step "Pas de requirements.txt : installation de pymodaq"
  "$VPY" -m pip install pymodaq
fi

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

# --- 4. Icône --------------------------------------------------------
step "Recherche d'une icône PyMoDAQ"
ICON="$("$VPY" - <<'EOF'
import sysconfig, pathlib
site = pathlib.Path(sysconfig.get_paths()["purelib"])
hits = [p for d in site.glob("pymodaq*") if d.is_dir()
          for ext in ("png", "svg", "ico")
          for p in d.rglob(f"*.{ext}") if "pymodaq" in p.name.lower()]
print(hits[0] if hits else "")
EOF
)"
[ -n "$ICON" ] || ICON="applications-science"
echo "Icône : $ICON"

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
