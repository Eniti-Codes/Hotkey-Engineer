# Hotkey-Engineer
# PROJECT MIGRATION NOTICE
**Hotkey Engineer has moved.** All active development and future updates have been migrated to platforms that better align with our commitment to independent, open-source software.

### The New Hubs:
* **Primary Home** [CodeBerg](https://codeberg.org/Eniti-Codes).
* **Secondary Mirror** [GitLab](https://gitlab.com/Eniti-Codes). 

### Important Release Info:
* **GitHub is now a static mirror.** The code currently here is preserved for legacy use. 
* **Stable v1.0.2 and all future versions will NOT be released on GitHub.**
* **Exclusive Projects:** Several of my other public projects (and future secrets) are hosted exclusively on Codeberg and GitLab. Explore the profiles there to see what else is in the works.
---

**The AutoHotkey Equivalent You've Been Waiting For on Linux**

Are you a former Windows AutoHotkey user looking for a powerful, flexible, and truly extensible automation solution on Linux? Look no further. **HotKey Engineer** is designed to fill that void, offering unparalleled control over your X11 desktop environment. Built with Python, it allows users to create custom actions, run scripts, launch applications, and orchestrate complex workflows with simple keyboard shortcuts. HotKey Engineer offers immense extensibility, enabling you to integrate any Python script as a module, launch applications written in various languages, and even manage system-level tasks with precision.

## Features
   * **GUI Configuration:** (Hotkey: Ctrl + Alt + ]): Configuration is managed via the built-in Config-Editor User Interface (UI). The UI is immediately functional post-installation, eliminating the need for manual JSON file editing.
   * **Maximum Flexibility and Customization:** The only required components for core functionality are the `Hotkey-Engineer.py`, and the `config.json`. Everything else—including the GUI, official modules, and specialized scripts—is optional, providing maximum flexibility for your specific use case.
   * **Modular & Extensible (Official Modules Available):** Easily integrate custom Python scripts as modules. Official Modules Available at [GitHub](https://github.com/Eniti-Codes/Hotkey-Engineer-Plugins), [GitLab](https://gitlab.com/Eniti-Codes/Hotkey-Engineer-Plugins), [CodeBerg](https://codeberg.org/Eniti-Codes/Hotkey-Engineer-Plugins).
  * **Powerful Hotkey Automation:** Define custom keyboard shortcuts to trigger any configured action, from simple commands to complex multi-step workflows.
  * **Modular & Extensible:** Easily integrate custom Python scripts as modules, transforming existing code or new ideas into powerful automations.
  * **Seamless System Integration:** Designed for reliable operation as a Systemd user service (via the setup script), ensuring your automations run consistently without manual intervention.
  * **Lightweight & Efficient:** Python-powered for flexibility without unnecessary resource consumption.

## Compatibility

  * **Developed For:** X11 Desktop Environments (e.g., Cinnamon, GNOME, KDE Plasma, XFCE).
  * **Tested On:** Linux Mint.
  * **Other Distributions:** While designed for X11, functionality on other Linux distributions is not guaranteed and may require manual adjustments.
  * **Xwayland Support:** The application is built to be compatible with Wayland through the Xwayland compatibility layer, and this is the intended path for official support. However, this functionality is currently untested. We encourage users to test it and report their experience on GitHub to help us improve.

## Getting Started

HotKey Engineer offers two primary ways to run: as a convenient system service managed by a setup script, or manually for direct control.

### Option 1: Install as a System Service (Recommended for Linux Mint Users)

The `setup.sh` script is designed to install HotKey Engineer as a system service, allowing it to run automatically in the background without needing to manually start it after every boot. This setup is specifically configured for Linux Mint.

#### Installation & Uninstallation Steps

1.  **Download HotKey Engineer:**
    Download the latest `Hotkey-Engineer.zip` file from the file from the Releases page

2.  **Navigate to the Extracted Directory:**
    Open your terminal and go to the directory where you've extracted the files.

    ```bash
    cd ~/Downloads/Hotkey-Engineer/
    ```

3.  **Make the Script Executable:**
    Before you can run the script, you need to give it permission to execute.

    ```bash
    chmod +x Setup.sh
    ```

6.  **Run the Setup Script:**
    Execute the script using `./Setup.sh`

    ```bash
    ./Setup.sh
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
    cd ~/Downloads/Hotkey-Engineer/
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
  "scripts": [
    {
      "name": "Your Python Script Name",
      "path": "/home/username/example.py",
      "args": [], #A list of command-line arguments to pass to the path Python script when it runs. Each argument should be a separate string in the array. Example:["--profile", "default"], ["--force", "-v"]
      "enabled": true, #If `true`, the action is active and can be triggered. If `false`, the action is disabled and will be ignored by HotKey Engineer.
      "run_on_startup": false, #If `true`, this action will be executed automatically when HotKey Engineer starts (e.g., upon system boot of HotKey Engineer)
      "run_hotkey": true,
      "hotkey": ["<ctrl>", "<alt>", "b"], # Purpose: Defines the keyboard shortcut. Example: `["<ctrl>", "<alt>", "x"]` (Ctrl+Alt+X), `["<super>", "e"]` (Super+E), `["<shift>", "<insert>"]` (Shift+Insert) and Note: `<super>` typically refers to the Windows key.
      "hotkey_action": "run", #Purpose: Specifies how the hotkey should behave. Like how Run makes it. Run without being able to be turned off by the script and toggle is a toggle. It will turn it on and off via the script.
      "needs_gui": false, #Purpose: If `true`, indicates that the action requires access to the graphical desktop environment (e.g., display a notification, or simulate keyboard/mouse input).
      "description": "Executes a custom Python script for backups."
    }
  ],
  "global_settings": {
    "log_directory": "/var/log/hotkey-engineer" #Purpose: To make a log directory for users not so tech Sabby if left blank, it will just go to the normal Linux way for logging.
  }
}
```

## Developer Notes on Script Execution

HotKey Engineer's core module execution mechanism is built around **Python scripts**. For developers creating custom modules:

  * **All Modules Must Be Python Files:** Any script you intend for HotKey Engineer to directly run via its `path` configuration must be a valid Python (`.py`) file.
  * **Module Location Flexibility:** Your Python modules can be located anywhere on your Linux system. Just ensure the `path` in the `config.json` points to their correct absolute location.
  * **External Command Execution:** If your module needs to execute commands or applications written in other languages (e.g., Bash scripts, Java applications, compiled C++ programs), your Python module should act as a wrapper. Use Python's `subprocess` module to call and manage these external processes. This allows HotKey Engineer to maintain its Python-centric core while still enabling you to leverage other tools.

## Planned Features

  * **Simplified Installation:** The final release will be distributed as a double-clickable .deb package, providing a seamless, one-click installation experience for Linux Mint users.
    
  * **Future-Proofing:** We'll ensure the tool is compatible with xWayland to support both current and future Linux display environments.

  * **Dedicated Language Interpreters (On Hold):** Future iteration will explore integrating a Python-based "interpreter" module that will enable HotKey Engineer to directly run scripts written in other languages (e.g., Bash, JavaScript) As a translation layer for Hotkey Engineer due to lack of knowledge on how to bypass virtual environment permission barriers, it is being put on hold. And the solutions that I came up with only work on very very Pacific hardware Thanks for your understanding.

## Stay Updated

Join our Discord server to connect with the community, get support, and stay up-to-date on future iterations of HotKey Engineer and my other development projects\!

**[Join Our Discord Server\!](https://discord.gg/UfyYCRK4jR)**

## Contribution

We welcome contributions to HotKey Engineer\! Please feel free to open issues or submit pull requests.

-----
