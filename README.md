# Hothey-Engineer
Do it better make it faster x11 You're my master.

**The AutoHotkey Equivalent You've Been Waiting For on Linux**

Are you a former Windows AutoHotkey user looking for a powerful, flexible, and truly extensible automation solution on Linux? Look no further. **HotKey Engineer** is designed to fill that void, offering unparalleled control over your X11 desktop environment. Built with Python, it allows users to create custom actions, run scripts, launch applications, and orchestrate complex workflows with simple keyboard shortcuts. HotKey Engineer offers immense extensibility, enabling you to integrate any Python script as a module, launch applications written in various languages, and even manage system-level tasks with precision.

## Features

  * **Powerful Hotkey Automation:** Define custom keyboard shortcuts to trigger any configured action, from simple commands to complex multi-step workflows.
  * **Deep Customization:** Unlike other Linux hotkey tools, HotKey Engineer aims to provide the same level of control and flexibility you'd expect from AutoHotkey on Windows.
  * **Modular & Extensible:** Easily integrate custom Python scripts as modules, transforming existing code or new ideas into powerful automations.
  * **Seamless System Integration:** Designed for reliable operation as a Systemd user service (via the setup script), ensuring your automations run consistently without manual intervention.
  * **Lightweight & Efficient:** Python-powered for flexibility without unnecessary resource consumption.
  * **User-Friendly Configuration:** Intuitive JSON configuration for defining and managing your hotkey actions.

## Compatibility

  * **Developed For:** X11 Desktop Environments (e.g., Cinnamon, GNOME, KDE Plasma, XFCE).
  * **Tested On:** Linux Mint.
  * **Other Distributions:** While designed for X11, functionality on other Linux distributions is not guaranteed and may require manual adjustments.

## Getting Started

HotKey Engineer offers two primary ways to run: as a convenient system service managed by a setup script, or manually for direct control.

### Option 1: Install as a System Service (Recommended for Linux Mint Users)

The `setup.sh` script is designed to install HotKey Engineer as a system service, allowing it to run automatically in the background without needing to manually start it after every boot. This setup is specifically configured for Linux Mint.

#### Purpose

This script streamlines the installation by presenting an interactive menu for installation or uninstallation. For installation, it automatically moves HotKey Engineer files from your current directory (e.g., `Downloads` or where you extracted the zip) to a designated system-wide location, configures the main Python script to run automatically as an operating system service (using `systemd`), and starts the service immediately. For uninstallation, it removes these system files and undoes all customizations. The script also provides helpful messages and can update existing HotKey Engineer files.

#### Installation & Uninstallation Steps

1.  **Download HotKey Engineer:**
    Download the latest `Hotkey-Engineer.zip` file from the file from the GitHub Releases page or Gitlab.
    *(Replace `YourUsername/hotkey-engineer/releases` with the actual path to your releases page)*

2.  **Extract the Files:**
    Navigate to your `Downloads` directory (or wherever you saved the zip) and extract the contents. This will create a folder like `Hotkey-Engineer-main` (or similar).

3.  **Navigate to the Extracted Directory:**
    Open your terminal and go to the directory where you've extracted the files.

    ```bash
    cd ~/Downloads/Hotkey-Engineer-main/ # Or whatever your extracted folder is named
    ```

4.  **Customize Your `config.json`:**
    **Before running the installation script, it is crucial to customize your `config.json` file\!** Open the `config.json` file in your preferred text editor and add or modify your desired hotkey actions and settings. Refer to the "Configuration File Breakdown" section below for details on each field.

5.  **Make the Script Executable:**
    Before you can run the script, you need to give it permission to execute.

    ```bash
    chmod +x setup.sh
    ```

6.  **Run the Setup Script with `sudo`:**
    Execute the script using `sudo`. This is **required** because the script sets up a system-level `systemd` user service to allow the Python script to run automatically and manages files in system-level directories. While the `setup.sh` script requires `sudo`, the main `Hotkey-Engineer.py` Python script itself does ***not*** run with `sudo` privileges.

    ```bash
    sudo ./setup.sh
    ```

7.  **Follow the On-Screen Prompts:**
    Once executed, the script will present you with an interactive menu in the terminal:

      * To **install**, type `1` and press `Enter`. The script will automatically move the necessary files, set up the `systemd` service, and start the HotKey Engineer service. You don't need to reboot.
      * To **uninstall**, type `2` and press `Enter`. The script will remove the `systemd` configuration, delete the files from the custom directory, and revert any system customizations.

### Option 2: Run Manually (Without System Service)

If you prefer not to install HotKey Engineer as a system service or are using an operating system other than Linux Mint, you can run the main Python script manually.

1.  **Download HotKey Engineer:**
    Download the latest `Hotkey-Engineer.zip` file from the GitHub Releases page or Gitlab

2.  **Extract the Files:**
    Extract the contents of the zip file to a convenient directory of your choice.

3.  **Navigate to the Extracted Directory:**
    Open your terminal and go to the directory where you've extracted the files.

    ```bash
    cd /path/to/your/Hotkey-Engineer-folder/ # e.g., cd ~/Documents/Hotkey-Engineer-main/
    ```

4.  **Customize Your `config.json`:**
    **Before running the script manually, customize your `config.json` file\!** Open `config.json` in your preferred text editor and define your hotkey actions. Refer to the "Configuration File Breakdown" section below for details.

5.  **Run the Application:**
    Execute the main Python script directly using Python:

    ```bash
    python3 Hotkey-Engineer.py
    ```

      * The application will run as long as the terminal window remains open. To stop it, close the terminal or press `Ctrl+C` in the terminal.

-----

**Important Note for Users on File Paths:**
When specifying the `"path"` for your actions in the `config.json`, please ensure you provide the **exact and correct absolute file path** to your Python script. Your Python modules can reside **anywhere on your Linux system**; they do not need to be within the HotKey Engineer project directory.

## Configuration File Breakdown

HotKey Engineer uses a `config.json` file to define your hotkey actions and global settings. Below is a breakdown of the structure and what each field represents.

```json
    {
      "name": "Python script",
      "path": "/home/username/backup.py",
      "args": [],
      "enabled": true,
      "run_on_startup": false,
      "run_hotkey": true,
      "hotkey": ["<ctrl>", "<alt>", "b"],
      "hotkey_action": "run",
      "needs_gui": false,
      "description": "Executes a custom Python script for backups."
    }
  ],
  "global_settings": {
    "log_directory": "/var/log/hotkey-engineer"
  }
}
```

### `actions` Array

This is an array of objects, where each object represents a distinct hotkey action or automated task.

  * `name` (string):
      * **Purpose:** A human-readable identifier for your action. This name is primarily used for logging by HotKey Engineer, allowing you to easily identify which module is active or if one malfunctions. You can put any descriptive name here.
      * **Example:** `"Open Terminal"`, `"Run Bitwarden Unlocker"`, `"Daily System Update"`
  * `path` (string):
      * **Purpose:** The absolute path to the **Python script** that this action will run.
      * **Example:** `"/home/username/scripts/open_calculator.py"`, `"/opt/some_utility/bitwarden_unlock.py"`
  * `args` (array of strings):
      * **Purpose:** A list of command-line arguments to pass to the `path` Python script when it runs. Each argument should be a separate string in the array.
      * **Example:** `["--profile", "default"]`, `["--force", "-v"]`
  * `enabled` (boolean):
      * **Purpose:** If `true`, the action is active and can be triggered. If `false`, the action is disabled and will be ignored by HotKey Engineer.
      * **Example:** `true` (active), `false` (disabled)
  * `run_on_startup` (boolean):
      * **Purpose:** If `true`, this action will be executed automatically when HotKey Engineer starts (e.g., upon system boot if configured as a Systemd service).
      * **Example:** `true` (run on startup), `false` (don't run on startup)
  * `run_hotkey` (boolean):
      * **Purpose:** If `true`, this action is enabled to be triggered by the specified `hotkey` combination. If `false`, the `hotkey` field is ignored, and the action can only be triggered on startup (if `run_on_startup` is `true`).
      * **Example:** `true` (hotkey enabled), `false` (hotkey disabled)
  * `hotkey` (array of strings):
      * **Purpose:** Defines the keyboard shortcut that triggers this action. This is an array where each element represents a key in the combination.
      * **Format:** Use `<mod_key>` for modifier keys (`<ctrl>`, `<alt>`, `<shift>`, `<super>`) and the key itself (e.g., `"x"`, `"f1"`, `"enter"`).
      * **Example:** `["<ctrl>", "<alt>", "x"]` (Ctrl+Alt+X), `["<super>", "e"]` (Super+E), `["<shift>", "<insert>"]` (Shift+Insert)
      * *Note: `<super>` typically refers to the Windows key.*
  * `hotkey_action` (string):
      * **Purpose:** Specifies how the hotkey should behave.
      * **Value:** Currently, `"run"` is the primary action, meaning the `path` executable/script will be executed. Future versions may introduce other actions (e.g., `toggle`, `stop`).
      * **Example:** `"run"`
  * `needs_gui` (boolean):
      * **Purpose:** If `true`, indicates that the action requires access to the graphical desktop environment (e.g., to open a browser, display a notification, or simulate keyboard/mouse input). This helps HotKey Engineer manage background processes correctly.
      * **Example:** `true` (requires GUI), `false` (runs in background without GUI interaction)
  * `description` (string):
      * **Purpose:** A brief, optional explanation of what the action does. Useful for documentation and remembering the purpose of complex actions.
      * **Example:** `"Opens a new Firefox window in incognito mode."`

### `global_settings` Object

Contains settings that apply to the entire HotKey Engineer instance.

  * `log_directory` (string):
      * **Purpose:** The absolute path to the directory where HotKey Engineer will store its log files. This helps with debugging and monitoring.
      * **Example:** `"/var/log/hotkey-engineer"`, `"/home/username/.local/share/hotkey-engineer/logs"`

## Developer Notes on Script Execution

HotKey Engineer's core module execution mechanism is built around **Python scripts**. For developers creating custom modules:

  * **All Modules Must Be Python Files:** Any script you intend for HotKey Engineer to directly run via its `path` configuration must be a valid Python (`.py`) file.
  * **Module Location Flexibility:** Your Python modules can be located anywhere on your Linux system. Just ensure the `path` in the `config.json` points to their correct absolute location.
  * **External Command Execution:** If your module needs to execute commands or applications written in other languages (e.g., Bash scripts, Java applications, compiled C++ programs), your Python module should act as a wrapper. Use Python's `subprocess` module to call and manage these external processes. This allows HotKey Engineer to maintain its Python-centric core while still enabling you to leverage other tools.

## Planned Features

  * **Dedicated Language Interpreters (Work in Progress):** Future updates will explore integrating a Python-based "interpreter" module that will enable HotKey Engineer to directly run scripts written in other languages (e.g., Bash, JavaScript) as native modules, without requiring a separate Python wrapper script for each. This will further enhance flexibility for developers.

## Stay Updated

Join our Discord server to connect with the community, get support, and stay up-to-date on future iterations of HotKey Engineer and my other development projects\!

**[Join Our Discord Server\!](https://discord.gg/UfyYCRK4jR)**

## Contribution

We welcome contributions to HotKey Engineer\! Please feel free to open issues or submit pull requests.

-----
