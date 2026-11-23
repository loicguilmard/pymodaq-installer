# PyMoDAQ Installer

Automatic installation scripts for [PyMoDAQ](https://pymodaq.cnrs.fr/) on Windows and Linux.

With a single command, they:

1. create an isolated Python environment (**conda** if it is installed, otherwise **venv**);
2. install (or update) the latest version of `pymodaq` with the PySide6 Qt backend (`pymodaq\[pyside6]`);
3. create a **PyMoDAQ** icon on the Desktop and in the applications menu, which launches PyMoDAQ in this environment, with no manual activation.

## Contents

|File|Role|
|-|-|
|`install_pymodaq.exe`|Installer built from the ps1 file.|
|`install_pymodaq.bat`|Windows entry point (double-click): runs the PowerShell script.|
|`install_pymodaq.ps1`|Windows installation script.|
|`install_pymodaq.sh`|Linux installation script.|

## Requirements

Either:

* **conda** (Miniforge, Miniconda or Anaconda), prefered
* **Python ≥ 3.10** with the `venv` module

  * Windows: either with the [Python install manager](https://apps.microsoft.com/detail/9nq7512cxl7t) from the Microsoft Store or from the command line with `winget install Python.Python.3.13`
  * Debian/Ubuntu: `sudo apt install python3 python3-venv`

An Internet connection is required to download the packages.

## Installation

### Windows

Use the latest release of install_pymodaq.exe.

### Linux

```bash
bash install_pymodaq.sh [install_directory]
```

The script also creates the system configuration folder `/etc/.pymodaq` recommended by PyMoDAQ: you may be asked for your `sudo` password.

## How it works

### Choice of environment

1. If the environment already exists in the install directory, it is **reused**, and PyMoDAQ is updated in it (`pip install --upgrade`).
2. Otherwise, if **conda** is found, a **conda environment** is created (Python 3.14, `conda-forge` channel).
3. Otherwise, if **Python ≥ 3.10** with `venv` is available, a **venv** is created.
4. Otherwise, the script stops and tells you what to install.

Conda is looked up in the `CONDA_EXE` variable, the `PATH`, then the usual locations (`miniforge3`, `miniconda3`, `anaconda3`, `mambaforge` in the user folder, `%LOCALAPPDATA%`, `%ProgramData%` or `/opt`). It therefore does not need to be on the `PATH`.

### Locations

By default, everything is installed in `~/PyMoDAQ` (`%USERPROFILE%\PyMoDAQ` on Windows):

```
PyMoDAQ/
└── venv/          Python environment (venv or conda)
```

Shortcuts created:

|System|Desktop|Menu|
|-|-|-|
|Windows|`PyMoDAQ.lnk`|Start menu → `PyMoDAQ`|
|Linux|`PyMoDAQ.desktop`|`~/.local/share/applications/pymodaq.desktop`|

The icon used is `icon.ico` at the root of the `pymodaq` package installed in the environment.

## Options

### Windows

|Option|Default|Description|
|-|-|-|
|`-InstallDir <path>`|`%USERPROFILE%\PyMoDAQ`|Install directory.|
|`-Command <name>`|`pymodaq`|Command launched by the icon (`pymodaq` or `dashboard`).|
|`-NoConda`|—|Ignore conda and create a venv with Python.|
|`-CondaPython <ver>`|`3.14`|Python version of the conda environment.|

Example:

```bat
install_pymodaq.bat -InstallDir D:\PyMoDAQ -Command dashboard
```

#### Building the installer executable

From the GitHub project https://github.com/Hope-IT-Works/PS2EXE-GUI (git clone)
Copy install_pymodaq.ps1 and icon.ico in the src folder.

The following command builds the executable from the ps1 script:

```powershell
 powershell -NoProfile -ExecutionPolicy Bypass -File .\ps2exe.ps1 -inputFile .\install_pymodaq.ps1 -iconFile .\icon.ico -title "PyMoDAQ installer" -description "exe creating a virtual env, installing pymodaq and making a shortcut available" -company "CNRS" -product "PyMoDAQ"
```

### Linux

The install directory is passed as the first argument; the other settings are set with environment variables:

|Variable|Default|Description|
|-|-|-|
|`PYMODAQ_CMD`|`pymodaq`|Command launched by the icon (`pymodaq` or `dashboard`).|
|`PYMODAQ_NO_CONDA`|`0`|`1` to ignore conda and create a venv with Python.|
|`PYMODAQ_CONDA_PYTHON`|`3.14`|Python version of the conda environment.|

Example:

```bash
PYMODAQ_NO_CONDA=1 PYMODAQ_CMD=dashboard bash install_pymodaq.sh /opt/pymodaq
```

> `pymodaq` opens the **Launcher** (recommended since PyMoDAQ 5.2), from which you can reach the Dashboard and the other modules. `dashboard` opens the Dashboard directly.

## Using it without the icon

The modules can also be launched from the environment:

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

Instrument plugins are installed with the plugin manager (`python -m pymodaq_plugin_manager.manager`) or with `pip` in the same environment.

## Updating and uninstalling

* **Update**: run the script again; the existing environment is reused and `pymodaq` / PySide6 are updated to the latest version. The installed version is shown at the end of the installation.
* **Uninstall**: delete the install directory and the shortcuts listed above. PyMoDAQ's configuration files are in `~/.pymodaq` (and `/etc/.pymodaq` on Linux).

## Troubleshooting

|Problem|Solution|
|-|-|
|*Neither conda nor Python >= 3.10 was found*|Install Miniforge, or Python ≥ 3.10 (with `venv`).|
|Windows: the PowerShell script is blocked|Run it through `install_pymodaq.bat`, which bypasses the execution policy for this script only.|
|Windows: `python` opens the Microsoft Store|Install Python with the Python install manager from the Microsoft Store or `winget install Python.Python.3.13` (see *Requirements*), or disable the alias in *Settings → Apps → App execution aliases*.|
|Linux: Python is present but not used (no conda)|The `venv` module is missing: `sudo apt install python3-venv`.|
|Linux: the Desktop icon does not launch|Right-click → *Allow Launching*, or use the entry in the applications menu.|
|A version of PyMoDAQ or one of its dependencies fails to install with Python 3.14|PyMoDAQ officially supports Python 3.10 to 3.13: delete the `venv` folder and run again with `-CondaPython 3.13` / `PYMODAQ\_CONDA\_PYTHON=3.13`.|
|The default icon is shown|`icon.ico` was not found in the `pymodaq` package; the shortcut still works.|

## Links

* PyMoDAQ documentation: [https://pymodaq.cnrs.fr/](https://pymodaq.cnrs.fr/)
* Installation tips: [https://pymodaq.cnrs.fr/en/dev/user_folder/installation_tips.html](https://pymodaq.cnrs.fr/en/dev/user_folder/installation_tips.html)
* Source code: [https://github.com/PyMoDAQ](https://github.com/PyMoDAQ)

