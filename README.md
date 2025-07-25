# Hothey-Engineer
Do it better make it faster x11 You're my master.

**⚠️ Important Note for Current Release ⚠️**
This README provides instructions for the current version of Hotkey Engineer.
A comprehensive overhaul of the installation process, including full `systemd` integration and an automated `setup.py` script, is planned for the next major update. This README will be completely revised at that time.

This README was created with the help of an AI assistant to ensure clarity and provide detailed guidance.

-----

Hotkey Engineer is your personal automation hub for Linux (specifically optimized for **X11** desktop environments like Linux Mint). It's designed to bring the power of customizable hotkeys and script execution to your fingertips, allowing you to run your own Python scripts and external applications with ease.

If you've ever missed the seamless automation of tools like AutoHotkey on Windows, Hotkey Engineer provides a similar, yet even more powerful, experience by leveraging the full potential of Python. It's built for users who want to create, customize, and manage their desktop automation, turning complex tasks into simple hotkey presses.

## ✨ Features

  * **Custom Python Script Execution:** Define and run any of your Python scripts (or external applications) using custom hotkeys.
  * **User-Friendly Configuration:** All automation is managed through a clear and editable JSON configuration file, making it easy to understand and modify your setup.
  * **Flexible Hotkey Actions:** Configure hotkeys to either `run` a script once or `toggle` its execution (start/stop) for continuous tasks like auto-clickers.
  * **Integrated Application Launcher:** Beyond Python, easily launch any external application using hotkeys.
  * **Modular & Extensible:** Hotkey Engineer provides the framework; you provide the Python scripts\! This empowers you to build highly personalized automation workflows.
  * **Lightweight & Background Operation:** Hotkey Engineer runs as a background process, ready to respond to your commands.
  * **Linux Mint Optimized (X11):** While potentially adaptable, Hotkey Engineer is built and tested to provide a seamless "just works" experience on Linux Mint and other X11-based desktop environments.

## 🚀 Getting Started (Current Version)

### Prerequisites

  * **Linux Mint (or another X11-based Linux distribution)**
  * **Python 3.x**
  * **`pip`** (Python package installer)

**System Dependencies (Install these first\!):**

Before launching Hotkey Engineer, you need to install some core system libraries that it relies on. Open your terminal and run:

```bash
sudo apt-get update
sudo apt-get install python3-tk python3-dev scrot xclip xsel
/usr/bin/python3 -m pip install pynput pyautogui
```

### Installation & Launch

In this version, installation is simply about extracting the files and launching the main script. An automated `setup.py` will handle this more robustly in a future update.

1.  **Download the latest release:**
    Download the latest release archive (e.g., `Hotkey-Engineer-vX.Y.Z.zip`) from our official GitHub or GitLab page.

      * **[Download from GitHub](https://github.com/Eniti-Codes/Hothey-Engineer)**
      * **[Download from GitLab]()**

2.  **Extract the archive:**
    Locate the downloaded `.zip` file. You can extract it using your file manager or a utility like 7-Zip.
    For example, open your terminal, navigate to your `Downloads` directory, and extract:

    ```bash
    cd ~/Downloads
    # If 7-zip is installed:
    7z x Hotkey-Engineer-vX.Y.Z.zip
    # OR using the default unzip utility:
    unzip Hotkey-Engineer-vX.Y.Z.zip
    ```

    This will create a folder like `Hotkey-Engineer-vX.Y.Z`.

3.  **Launch Hotkey Engineer:**
    Navigate into the extracted directory. From here, you will manually launch the main script:

    ```bash
    cd Hotkey-Engineer-vX.Y.Z
    python3 main.py # Or whatever your primary entry script is named
    ```

    Hotkey Engineer will now be running in the background, listening for your hotkeys.

    *Note: For this version, you will need to manually launch Hotkey Engineer each time you want to use it or configure it for automatic startup via your desktop environment's settings. Full `systemd --user` integration for automatic startup will be added in the next update.*

## ⚙️ Configuration

Hotkey Engineer is configured via the `config.json` file located in the directory where you extracted the application files (e.g., `~/Downloads/Hotkey-Engineer-vX.Y.Z/config.json`).

You can open this file with any text editor to add or modify your custom scripts and settings.

### Understanding `config.json`

The `config.json` contains a `scripts` array and `global_settings`. Each object in the `scripts` array represents a script or application you want Hotkey Engineer to manage.

Here's the structure and explanation of each field:

```json
{
  "scripts": [
    {
      "name": "My Auto Clicker",                  // Required: A descriptive name for your script.
      "path": "/home/user/my_scripts/autoclicker.py", // Required: Full path to your Python script or external application executable.
      "args": ["--mode", "fast"],                 // Optional: A list of command-line arguments to pass to the script/app.
      "enabled": true,                            // Boolean: Set to 'true' to enable this script, 'false' to disable.
      "run_on_startup": false,                    // Boolean: If 'true', script runs when Hotkey Engineer starts.
      "run_hotkey": true,                         // Boolean: If 'true', hotkey triggers this script.
      "hotkey": ["<ctrl>", "<alt>", "a"],         // Array: List of keys for the hotkey (e.g., ["<ctrl>", "<alt>", "z"]). Modifiers: <ctrl>, <alt>, <shift>, <super> (Windows/Meta key).
      "hotkey_action": "toggle",                  // String: "toggle" (start/stop) or "run" (execute once).
      "needs_gui": false,                         // Boolean: If 'true', Hotkey Engineer will try to ensure a graphical session is available before running (important for some UI apps).
      "is_external_app": false,                   // Boolean: Set to 'true' if 'path' points to a non-Python executable (e.g., `/usr/bin/firefox`). If 'false', Python is assumed.
      "description": "A simple auto clicker script." // Optional: A brief description of what this script does.
    },
    // ... more script definitions
  ],
  "global_settings": {
    "log_directory": "/home/user/hotkey_engineer_logs" // Optional: Specify a custom directory for Hotkey Engineer's logs. Defaults to ~/.local/share/hotkey-engineer/logs.
  }
}
```

**Hotkey Key Codes:**

  * **Modifiers:** `<ctrl>`, `<alt>`, `<shift>`, `<super>` (the Windows/Meta key).
  * **Regular Keys:** Most standard keys can be used (e.g., `a`, `b`, `1`, `2`, `f1`, `space`, `enter`, `esc`, `delete`, `tab`, etc.).
  * **Special Keys:** Consult the `pynput` library documentation for a full list of supported key names if you need less common ones.

## ✍️ Creating Your Own Python Scripts

The real power of Hotkey Engineer lies in your ability to write custom Python scripts\! Here are some common Python libraries you might find useful for your automation needs:

  * **`pynput`**: For listening to and controlling keyboard and mouse. Ideal for auto-clickers, complex key sequences, and hotkey listeners within your modules.
  * **`PyAutoGUI`**: For GUI automation, including moving the mouse, clicking, typing, and taking screenshots. Great for automating interactions with applications that don't have an API.
  * **`subprocess`**: For running external shell commands or other programs from within your Python script.
  * **`os` / `shutil`**: For interacting with the file system (creating, deleting, moving files/directories).
  * **`requests`**: For making HTTP requests, perfect for interacting with web APIs or downloading data.
  * **`json`**: For working with JSON data, which is useful for configuration or interacting with web services.

These libraries can be installed into your Hotkey Engineer's Python environment using `pip` (e.g., by navigating to the Hotkey Engineer directory, activating its virtual environment, and running `pip install pynput`).

## ⚠️ Important Security Warning for Third-Party Modules

Hotkey Engineer is incredibly powerful because it allows you to run any Python script you provide. However, with great power comes great responsibility, especially concerning scripts obtained from external sources.

**Please exercise extreme caution when adding modules from third-party or untrusted sources.**

  * **Code Execution Risk:** Any Python script you configure Hotkey Engineer to run will execute with your user permissions. A malicious script could potentially harm your system, steal data, or download unwanted software.
  * **Understanding Imports:** Be aware that powerful Python modules, if imported by a third-party script, can grant it significant control over your system:
      * **`os` module:** Allows the script to interact with the operating system, including file system operations (creating, deleting, modifying files), changing directories, and running shell commands.
      * **`subprocess` module:** Enables the script to execute external commands and programs, potentially including system utilities or even `sudo` requests (which would prompt *you* for your password).
      * **`sys` module:** Provides access to system-specific parameters and functions, including the ability to exit the program or manipulate Python's import path.
  * **Vetting External Modules:**
      * **Manual Review:** If possible, always review the source code of any third-party module before running it. Look for suspicious imports or commands.
      * **Automated Analysis:** Consider running untrusted scripts through AI-powered code analysis tools.
      * **Isolated Environments:** For maximum safety, test untrusted modules in a disposable virtual environment or a dedicated virtual machine before integrating them into your main Hotkey Engineer setup.

Your security is paramount. Hotkey Engineer cannot prevent malicious code from executing if you instruct it to run an untrusted script.

-----
