# CLAUDE.md

Guidance for working on this repository.

## What this project is

Installer scripts for [PyMoDAQ](https://pymodaq.cnrs.fr/) (a Python/Qt data-acquisition app). Each script:

1. creates an isolated Python environment in `<InstallDir>/venv` (default `~/PyMoDAQ`),
2. `pip install --upgrade "pymodaq[pyside6]"` (latest pymodaq + PySide6), then prints the installed version,
3. creates a desktop + app-menu shortcut that runs the environment's `pymodaq` executable directly (no activation).

| File | Role |
|------|------|
| `install_pymodaq.ps1` | Windows installer (PowerShell). |
| `install_pymodaq.bat` | Thin wrapper: runs the `.ps1` with `-ExecutionPolicy Bypass`, forwards `%*`, then `pause`. Keep it that way — no logic here. |
| `install_pymodaq.sh` | Linux installer (bash). |
| `README.md` | User documentation, in French. |

There is no build, no package, no test suite.

## Design decisions (keep them unless asked)

- **Environment choice order**: reuse an existing env in `<InstallDir>/venv` → **conda if found** → venv with Python ≥ 3.10 (and `venv`/`ensurepip` importable) → fail with an explanatory message.
  - Opt-out of conda: `-NoConda` (Windows) / `PYMODAQ_NO_CONDA=1` (Linux).
  - Conda Python version: `-CondaPython` / `PYMODAQ_CONDA_PYTHON` (default `3.14`). Note: PyMoDAQ's classifiers only go up to 3.13 (`requires-python = ">=3.10"`), so 3.14 is allowed but not officially listed; 3.13 is the fallback advice in the README.
- **Conda envs are created by prefix** (`conda create -y -p <InstallDir>/venv ...`), not by name, and always with `-c conda-forge --override-channels` (avoids the Anaconda `defaults` channel ToS prompt). Packages are then installed with the env's `pip`, never `conda install`.
- **Conda detection** checks `CONDA_EXE`, then `PATH`, then usual install dirs (`miniforge3`, `miniconda3`, `anaconda3`, `mambaforge` under the user profile / `%LOCALAPPDATA%` / `%ProgramData%` on Windows, `$HOME` / `/opt` on Linux). Conda is often not on `PATH` on Windows.
- **Install `pymodaq` directly** from PyPI. Do not reintroduce a `requirements.txt` lookup.
- **Always `--upgrade`.** Without it, re-running on a reused env leaves the old pymodaq in place ("Requirement already satisfied") — this is why users got stuck on 5.3.7 after 5.3.8+ came out.
- **Install PySide6 through the extra** (`pymodaq[pyside6]`), not a bare `pip install pyside6`: the extra carries PyMoDAQ's own exclusions (e.g. `pyside6!=6.12.0`, which aborts on `Signal(bool).emit(True)`).
- **Icon**: use `icon.ico` at the root of the installed `pymodaq` package — no searching. If it is missing, warn and fall back to a default icon; never fail on it.
  - Windows: `<venv>\Lib\site-packages\pymodaq\icon.ico`
  - Linux: ask the env's Python for `sysconfig.get_paths()["purelib"]` (path contains `pythonX.Y`), then `/pymodaq/icon.ico`.
- **Launched command** defaults to `pymodaq` (the Launcher, preferred since PyMoDAQ 5.2); `dashboard` is the alternative (`-Command` / `PYMODAQ_CMD`).
- **Linux only**: create `/etc/.pymodaq` with `sudo` (recommended by PyMoDAQ docs); failure is non-fatal.

## Environment layouts to keep in mind

| | venv | conda env |
|---|---|---|
| Windows Python | `venv\Scripts\python.exe` | `venv\python.exe` |
| Windows entry points | `venv\Scripts\pymodaq.exe` | `venv\Scripts\pymodaq.exe` |
| Windows site-packages | `venv\Lib\site-packages` | `venv\Lib\site-packages` |
| Linux Python / entry points | `venv/bin/` | `venv/bin/` |

The `.ps1` therefore tracks two interpreter paths (`$VenvPy`, `$EnvPy`); the `.sh` only needs `venv/bin/python`.

## Conventions

- **Keep the Windows and Linux scripts in parity.** Any behaviour change goes into both `.ps1` and `.sh`, and into `README.md` (sections *Fonctionnement*, *Options*, *Dépannage*).
- **All user-facing text is in French** (script messages, comments, README). Code identifiers stay in English.
- Scripts are idempotent: re-running reuses the environment and re-installs/updates packages and shortcuts.
- PowerShell: `$ErrorActionPreference = "Stop"`, and check `$LASTEXITCODE` after every native command (`pip`, `conda`, `python -m venv`) and `throw` a French message on failure.
- Bash: `set -euo pipefail`; helper functions that may find nothing must be called as `$(fn || true)`.
- Progress messages go through the `Step` / `step` helpers.
- Options: named parameters on Windows (`param(...)`), install dir as `$1` + `PYMODAQ_*` env vars on Linux.

## Checking changes

No conda or Windows here by default, so at minimum:

```bash
bash -n install_pymodaq.sh
shellcheck -S warning install_pymodaq.sh          # if available
pwsh -NoProfile -Command '$e=$null; [void][System.Management.Automation.Language.Parser]::ParseFile("install_pymodaq.ps1",[ref]$null,[ref]$e); $e'   # if pwsh is available
```

A real install test needs network access to PyPI (and conda-forge for the conda path). Branches not exercised locally (conda path, Windows script) should be called out as untested when reporting changes.
