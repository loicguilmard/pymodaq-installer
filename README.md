# Installateur PyMoDAQ

Scripts d'installation automatique de [PyMoDAQ](https://pymodaq.cnrs.fr/) pour Windows et Linux qui :

1. créent un environnement Python isolé (**conda** s'il est installé, sinon **venv**) ;
2. installent `pymodaq` et le backend Qt `pyside6` ;
3. créent une icône **PyMoDAQ** sur le Bureau et dans le menu des applications, qui lance PyMoDAQ dans cet environnement, sans activation manuelle.

## Contenu

| Fichier               | Rôle                                                                   |
|-----------------------|------------------------------------------------------------------------|
| `install_pymodaq.bat` | Point d'entrée Windows (double-clic) : lance le script PowerShell.     |
| `install_pymodaq.ps1` | Script d'installation Windows.                                         |
| `install_pymodaq.sh`  | Script d'installation Linux.                                           |

## Prérequis

L'un des deux suffit :

- **conda** (Miniforge, Miniconda ou Anaconda), utilisé en priorité
- **Python ≥ 3.10** avec le module `venv`
  - Windows : [python.org](https://www.python.org/downloads/), en cochant *Add python.exe to PATH*
  - Debian/Ubuntu : `sudo apt install python3 python3-venv`

Une connexion Internet est nécessaire pour télécharger les paquets.

## Installation

### Windows

Gardez `install_pymodaq.bat` et `install_pymodaq.ps1` dans le même dossier, puis double-cliquez sur **`install_pymodaq.bat`**.

Ou depuis une console :

```bat
install_pymodaq.bat [options]
```

### Linux (Not tested)

```bash
bash install_pymodaq.sh [dossier_d_installation]
```

Le script crée aussi le dossier de configuration système `/etc/.pymodaq` recommandé par PyMoDAQ : le mot de passe `sudo` peut être demandé.

## Fonctionnement

### Choix de l'environnement

1. Si l'environnement existe déjà dans le dossier d'installation, il est **réutilisé** (relancer le script met donc PyMoDAQ à jour).
2. Sinon, si **conda** est trouvé, un **environnement conda** est créé (Python 3.12, canal `conda-forge`).
3. Sinon, si **Python ≥ 3.10** avec `venv` est disponible, un **venv** est créé.
4. Sinon, le script s'arrête en indiquant quoi installer.

Conda est recherché dans la variable `CONDA_EXE`, le `PATH`, puis les emplacements habituels (`miniforge3`, `miniconda3`, `anaconda3`, `mambaforge` dans le dossier utilisateur, `%LOCALAPPDATA%`, `%ProgramData%` ou `/opt`). Il n'a donc pas besoin d'être dans le `PATH`.

### Emplacements

Par défaut, tout est installé dans `~/PyMoDAQ` (`%USERPROFILE%\PyMoDAQ` sous Windows) :

```
PyMoDAQ/
└── venv/          environnement Python (venv ou conda)
```

Raccourcis créés :

| Système | Bureau                  | Menu                                              |
|---------|-------------------------|---------------------------------------------------|
| Windows | `PyMoDAQ.lnk`           | Menu Démarrer → `PyMoDAQ`                         |
| Linux   | `PyMoDAQ.desktop`       | `~/.local/share/applications/pymodaq.desktop`     |

L'icône utilisée est `icon.ico` à la racine du paquet `pymodaq` installé dans l'environnement.

## Options

### Windows

| Option                  | Défaut                 | Description                                              |
|-------------------------|------------------------|----------------------------------------------------------|
| `-InstallDir <chemin>`  | `%USERPROFILE%\PyMoDAQ`| Dossier d'installation.                                  |
| `-Command <nom>`        | `pymodaq`              | Commande lancée par l'icône (`pymodaq` ou `dashboard`).  |
| `-NoConda`              | —                      | Ignorer conda et créer un venv avec Python.              |
| `-CondaPython <ver>`    | `3.12`                 | Version de Python de l'environnement conda.              |

Exemple :

```bat
install_pymodaq.bat -InstallDir D:\PyMoDAQ -Command dashboard
```

### Linux

Le dossier d'installation se passe en premier argument ; les autres réglages par variables d'environnement :

| Variable               | Défaut    | Description                                              |
|------------------------|-----------|----------------------------------------------------------|
| `PYMODAQ_CMD`          | `pymodaq` | Commande lancée par l'icône (`pymodaq` ou `dashboard`).  |
| `PYMODAQ_NO_CONDA`     | `0`       | `1` pour ignorer conda et créer un venv avec Python.     |
| `PYMODAQ_CONDA_PYTHON` | `3.12`    | Version de Python de l'environnement conda.              |

Exemple :

```bash
PYMODAQ_NO_CONDA=1 PYMODAQ_CMD=dashboard bash install_pymodaq.sh /opt/pymodaq
```

> `pymodaq` ouvre le **Launcher** (recommandé depuis PyMoDAQ 5.2), d'où l'on accède au Dashboard et aux autres modules. `dashboard` ouvre directement le Dashboard.

## Utilisation sans l'icône

Les modules peuvent aussi être lancés depuis l'environnement :

```bash
# Linux
~/PyMoDAQ/venv/bin/pymodaq
~/PyMoDAQ/venv/bin/python -m pymodaq.dashboard
```

```bat
:: Windows
%USERPROFILE%\PyMoDAQ\venv\Scripts\pymodaq.exe
%USERPROFILE%\PyMoDAQ\venv\Scripts\python.exe -m pymodaq.dashboard
```

Les plugins d'instruments s'installent avec le gestionnaire de plugins (`python -m pymodaq_plugin_manager.manager`) ou avec `pip` dans le même environnement.

## Mise à jour et désinstallation

- **Mettre à jour** : relancer le script ; l'environnement existant est réutilisé.
- **Désinstaller** : supprimer le dossier d'installation et les raccourcis listés ci-dessus. Les fichiers de configuration de PyMoDAQ se trouvent dans `~/.pymodaq` (et `/etc/.pymodaq` sous Linux).

## Dépannage

| Problème | Solution |
|----------|----------|
| *Ni conda ni Python >= 3.10 n'ont été trouvés* | Installer Miniforge, ou Python ≥ 3.10 (avec `venv`). |
| Windows : le script PowerShell est bloqué | Lancer via `install_pymodaq.bat`, qui contourne la politique d'exécution pour ce script uniquement. |
| Windows : `python` ouvre le Microsoft Store | Installer Python depuis python.org, ou désactiver l'alias dans *Paramètres → Applications → Alias d'exécution*. |
| Linux : Python présent mais non retenu (sans conda) | Le module `venv` manque : `sudo apt install python3-venv`. |
| Linux : l'icône du Bureau ne se lance pas | Clic droit → *Autoriser l'exécution*, ou utiliser l'entrée du menu des applications. |
| L'icône par défaut s'affiche | `icon.ico` n'a pas été trouvé dans le paquet `pymodaq` ; le raccourci fonctionne quand même. |

## Liens

- Documentation PyMoDAQ : <https://pymodaq.cnrs.fr/>
- Conseils d'installation : <https://pymodaq.cnrs.fr/en/dev/user_folder/installation_tips.html>
- Code source : <https://github.com/PyMoDAQ>
